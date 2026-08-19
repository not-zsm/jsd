--[[
	serialiser by billguy
	
	Serialises an Instance into a Lua table, preserving tags, attributes, and instance references.
	Uses a dictionary lookup compression method with Base91 encoding.
	Compression ratio and compression speed are acceptable.
	
	N̶o̶w̶ s̶u̶p̶p̶o̶r̶t̶s̶ u̶s̶i̶n̶g̶ L̶Z̶W̶ c̶o̶m̶p̶r̶e̶s̶s̶i̶o̶n̶ f̶o̶r̶ m̶u̶c̶h̶ b̶i̶g̶g̶e̶r̶ g̶a̶i̶n̶s̶ 😍 	
	I̶ w̶a̶s̶ u̶s̶i̶n̶g̶ Z̶l̶i̶b̶ D̶E̶F̶L̶A̶T̶E̶ b̶e̶f̶o̶r̶e̶, b̶u̶t̶ t̶h̶a̶t̶ m̶o̶d̶u̶l̶e̶ i̶s̶ 3̶.5̶k̶ l̶i̶n̶e̶s̶ l̶o̶n̶g̶, w̶h̶i̶l̶e̶ L̶Z̶W̶ i̶s̶ o̶n̶l̶y̶ 2̶5̶0̶ l̶i̶n̶e̶s̶ l̶o̶n̶g̶ -̶ I̶ d̶o̶n̶t̶ k̶n̶o̶w̶ i̶f̶ t̶h̶a̶t̶'l̶l̶ a̶f̶f̶e̶c̶t̶ s̶e̶r̶v̶e̶r̶ l̶o̶a̶d̶i̶n̶g̶ t̶i̶m̶e̶s̶. 	
	L̶Z̶W̶ a̶l̶s̶o̶ p̶e̶r̶f̶o̶r̶m̶s̶ a̶b̶o̶u̶t̶ a̶s̶ w̶e̶l̶l̶ a̶s̶ Z̶l̶i̶b̶'s̶ l̶e̶v̶e̶l̶ 3̶ c̶o̶m̶p̶r̶e̶s̶s̶i̶o̶n̶ w̶i̶t̶h̶ c̶o̶m̶p̶a̶r̶a̶b̶l̶e̶ c̶o̶m̶p̶r̶e̶s̶s̶i̶o̶n̶ r̶a̶t̶i̶o̶ a̶n̶d̶ w̶o̶r̶k̶ t̶i̶m̶e̶.
	
	I̶'m̶ b̶a̶c̶k̶ t̶o̶ u̶s̶i̶n̶g̶ L̶i̶b̶D̶e̶f̶l̶a̶t̶e̶ Z̶l̶i̶b̶ C̶o̶m̶p̶r̶e̶s̶s̶, m̶a̶d̶e̶ i̶t̶ s̶o̶ i̶t̶ o̶n̶l̶y̶ r̶e̶q̶u̶i̶r̶e̶s̶ L̶i̶b̶D̶e̶f̶l̶a̶t̶e̶ m̶o̶d̶u̶l̶e̶ w̶h̶e̶n̶ i̶t̶s̶ n̶e̶e̶d̶e̶d̶, s̶o̶ i̶t̶ d̶o̶e̶s̶n̶'t̶ a̶f̶f̶e̶c̶t̶ s̶e̶r̶v̶e̶r̶ l̶o̶a̶d̶i̶n̶g̶.
	
	Its so over for me... I didn't know that buffer.tostring() uses Roblox's internal Zstd compression which is so much faster and has ratios alike to level 3 Zlib compression.
	LibDeflate is kept for backwards compatibility.
	
	Also now has iterators you can pass through the Serialise and Deserialise parameters, allows you to track progress.
	
	Notes:
	- Tags prefixed with '_TEMP' are not serialised.
	- Instances tagged with 'InstanceModifier', will have an additional '_InterestId' attribute added if a UserId is passed into SerialiserParameters.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")

local Unpacker = require( "./Unpacker" );
local Base91 = require( script.Base91 )
local Reidentify = require( script.Reidentify )

local BufferUtil = require( ReplicatedStorage.Packages.BufferUtil )

local Table = require( Unpacker.Packages.Table )
local Instances = require( Unpacker.Packages.Instances )
local PropertiesUtil =  require( Unpacker.Shared.Data.Properties.Utility );

local InstanceAssets = Unpacker.Shared.Assets.Build.Insert;
local InstanceInventory = Unpacker.Shared.Assets.Build.Inventory;

-----------------------------------------------------------------------------

export type Dict = {[string]: any}

export type SerialiserParameters = {
	PreferZstd: boolean,
	
	CompressionLevel: number,
	ConsiderOnlyTopLevel: boolean,
	UserId: number?; -- Player associated with (Optional)

	InstanceIterator: (token_map: TokenMap, instance: Instance, step: number, max_step: number) -> (),
	PropertyIterator: (token_map: TokenMap, instance: Instance, step: number, max_step: number) -> (),
	CompressIterator: (step: number, max_step: number) -> (),
};

export type DeserialiserParameters = {
	Unpack: boolean; -- Whether to unpack ONLY if what is being deserialised had 'instance' parameter passed as a list.
	UserId: number?; -- Player associated with (Optional)

	InstanceIterator: (token_map: TokenMap, instance: Instance, step: number, max_step: number) -> (),
	PropertyIterator: (token_map: TokenMap, instance: Instance, step: number, max_step: number) -> (),
	DecompressIterator: (step: number, max_step: number) -> (),
};

export type TokenMap = {
	Count: number, 
	InstanceCount: number,
	PropertyCount: number,
	MaxInstanceCount: number,
	MaxPropertyCount: number,
	Tokens: {[string]: string};
	Keys: {[string]: string};
	InstanceMap: {[Instance]: any};
	Serial: any;
	Parameters: SerialiserParameters,
	TopLevelChildren: {Instance}?,
};

export type StringDecompressParameters = { machine: ("Zlib" | "Zstd")?, iterator: (() -> ())? }
export type StringCompressParameters = { machine: ("Zlib" | "Zstd")?, level: number?, iterator: (() -> ())? }

-----------------------------------------------------------------------------

-- Changing the order may corrupt existing data, append new types on the end.
local SerialisableDataTypes = {
	"CFrame",
	"Vector3",
	"Vector2",
	"Color3",
	"EnumItem",
	"ColorSequence",
	"Instance",
	"string",
	"boolean",
	"number",
	"NumberSequence",
	"NumberRange",
	"BrickColor",
	"UDim2",
};

local InstanceCacheServices = {Lighting = true, Teams = true};
local ClassExcludeList = {TouchTransmitter = true};
local SerialisableDataTypesMap = Table.hashmap(SerialisableDataTypes)

-- The more 0s used, the higher the precision of serialised numbers, but larger the serialised output size is.
local StoredNumberPrecision = 1e-5;
local ServerFrameInSeconds = 1 / 60;

local MeshPartAwaitingThreads = {};

-----------------------------------------------------------------------------

local DefaultSerialiserParamters = {
	PreferZstd = true; --[[
		Whether Zstd will be used as the compression method (equivalent to Zlib compression level 4, but much faster), if it fails, it will either: 
			1. Use Zlib compression.
			2. Fail serialisation if the former is false.
	--]]
	
	CompressionLevel = 7; -- Zlib compression level. The higher, the more compressed the text becomes at the cost of performance.
	ConsiderOnlyTopLevel = true; -- If you pass a list of instances through .serialise, if this is true it will make sure to not serialise instances that are a descendant of an instance already in the list.

	-- Default (1,000) to prevent Serialiser from locking up CPU resource.
	InstanceIterator = function(token_map, instance, step, max_step) 
		if step % 2_000 == 0 then
			task.wait(ServerFrameInSeconds);
		end
	end,

	-- Default (500) to prevent Serialiser from locking up CPU resource.
	PropertyIterator = function(token_map, instance, step, max_step) 
		if step % 1_000 == 0 then
			task.wait(ServerFrameInSeconds);
		end
	end,

	-- Default (65,000) to prevent Serialiser from locking up CPU resource.
	-- Called each time a Deflate iterates over a block.
	CompressIterator = function(step, max_step) 
		task.wait(ServerFrameInSeconds);
	end
};

local DefaultSerialiserIndex = table.freeze{
	__index = DefaultSerialiserParamters
}

local DefaultDeserialiserParamters = {
	Unpack = true;

	-- Default (1,000) to prevent Serialiser from locking up CPU resource.
	InstanceIterator = function(token_map, instance, step, max_step) 
		if step % 2_500 == 0 then
			task.wait(ServerFrameInSeconds);
		end
	end,

	-- Default (500) to prevent Serialiser from locking up CPU resource.
	PropertyIterator = function(token_map, instance, step, max_step) 
		if step % 1_250 == 0 then
			task.wait(ServerFrameInSeconds);
		end
	end,

	-- Default (70,000) to prevent Serialiser from locking up CPU resource.
	-- Called each time an Inflate iterates over a block.
	DecompressIterator = function(step, max_step) 
		task.wait(ServerFrameInSeconds);
	end,
};

local DefaultDeserialiserIndex = table.freeze{
	__index = DefaultDeserialiserParamters
}

-----------------------------------------------------------------------------

local Serialiser = {};
Serialiser.MeshPartCache = {};
Serialiser.InstanceCache = {};
Serialiser.InventoryMap = {};

-----------------------------------------------------------------------------

local function get_property(instance: Instance, property: string): any
	return instance[property];
end

local function set_property(instance: Instance, property: string, value: any): ()
	instance[property] = value;
end

@native local function sn(value: number): number
	return (value // StoredNumberPrecision) * StoredNumberPrecision;
end

@native local function sns(...: number): ...number
	local numbers = {...};

	for index, number in numbers do
		numbers[index] = sn(number);
	end;

	return unpack(numbers);
end

local function get_instance_cached(class_name: string): Instance
	local cached_instance = Serialiser.InstanceCache[class_name];

	if not cached_instance then
		if InstanceCacheServices[class_name] then
			return game:GetService(class_name);
		end;
		
		local success, instance = pcall(Instance.new, class_name);

		if success then
			cached_instance = instance;
		else
			cached_instance = InstanceAssets[class_name];
		end

		Serialiser.InstanceCache[class_name] = cached_instance;
	end;

	return cached_instance;
end

local function get_instance_property(class_name: string, property: string): any
	return get_instance_cached(class_name)[property];
end

local function create_instance(class_name: string)
	return get_instance_cached(class_name):Clone();
end

@native local function get_child_map(instance: Instance, token_map: TokenMap, store_result: any)
	local map = token_map.InstanceMap[instance];

	if map and map.Parent and map.Parent.Children then
		table.insert(store_result, table.find(map.Parent.Children, map));

		get_child_map(map.Parent.Instance, token_map, store_result);
	end

	return store_result;
end

@native local function from_child_map(child_map, token_map): Instance?
	local serial = token_map.Serial;
	local instance: Instance? = serial.Instance;

	for index = #child_map, 1, -1 do
		local child = child_map[index];
		local next_serial = serial[token_map.Tokens.Children][child];

		instance = next_serial.Instance;
		serial = next_serial;
	end

	return instance;
end

@native local function to_rgb(value: number): (number)
	return math.round(value * 255);
end

-- Generic data type deserialiser (DataStore compliant).
@native local function generic_deserialise_value(data_type: string, value: any, context: any): any
	if data_type == "CFrame" then
		return CFrame.new(value[1], value[2], value[3]) * CFrame.fromEulerAnglesXYZ(value[4], value[5], value[6]);

	elseif data_type == "Vector3" then
		return Vector3.new(unpack(value));

	elseif data_type == "Vector2" then
		return Vector2.new(unpack(value));

	elseif data_type == "Color3" then
		-- 4th value specifies color format
		local v1, v2, v3, format = unpack(value);

		if format == 1 then
			return Color3.fromRGB(v1, v2, v3);
		else
			-- Use HSV (Old format with FP skew)
			return Color3.fromHSV(v1, v2, v3);
		end

	elseif data_type == "BrickColor" then
		return BrickColor.new(value);

	elseif data_type == "UDim2" then
		return UDim2.new(unpack(value));

	elseif data_type == "NumberRange" then
		return NumberRange.new(unpack(value));

	elseif data_type == "EnumItem" then

		-- Needs additional context (An Enum) for EnumItem to be deserialised.
		assert(context, "No context (Enum) was provided for EnumType, could not deserialise value.");

		if typeof(context) == "EnumItem" then
			return (context :: any).EnumType:FromValue(value);

		elseif typeof(context) == "Enum" then
			return (context :: any):FromValue(value);
		else
			return (Enum[context] :: any):FromValue(value);
		end

	elseif data_type == "ColorSequence" then
		local keypoints = {};

		for index, keypoint in value :: {number} do
			local keytime, v1, v2, v3, format = unpack(keypoint);
			local color: Color3;

			if format == 1 then
				color = Color3.fromRGB(v1, v2, v3);
			else
				-- Use HSV (Old format with FP skew)
				color = Color3.fromHSV(v1, v2, v3);
			end

			keypoints[index] = ColorSequenceKeypoint.new(keytime, color);
		end

		return ColorSequence.new(keypoints);

	elseif data_type == "NumberSequence" then
		local keypoints = {};

		for index, keypoint in value :: {number} do
			keypoints[index] = NumberSequenceKeypoint.new(unpack(keypoint));
		end

		return NumberSequence.new(keypoints);
		
	else--if data_type == "string" then
		return value;
	end;
end;

-- Generic data type serialiser (DataStore compliant).
@native local function generic_serialise_value(data_type: string, value: any): any
	if data_type == "CFrame" then
		return {sn(value.X), sn(value.Y), sn(value.Z), sns(value:ToEulerAnglesXYZ())};

	elseif data_type == "Vector3" then
		return {sn(value.X), sn(value.Y), sn(value.Z)};

	elseif data_type == "Vector2" then
		return {sn(value.X), sn(value.Y)};

	elseif data_type == "Color3" then
		return {to_rgb(value.R), to_rgb(value.G), to_rgb(value.B), 1};

	elseif data_type == "BrickColor" then
		return value.Number;

	elseif data_type == "UDim2" then
		return {sn(value.X.Scale), sn(value.X.Offset), sn(value.Y.Scale), sn(value.Y.Offset)};

	elseif data_type == "NumberRange" then
		return {sn(value.Min), sn(value.Max)};

	elseif data_type == "EnumItem" then
		return value.Value, tostring(value.EnumType);

	elseif data_type == "ColorSequence" then
		local keypoints = {};

		for index, keypoint in value.Keypoints :: {ColorSequenceKeypoint} do
			local color = keypoint.Value;
			keypoints[index] = {keypoint.Time, to_rgb(color.R), to_rgb(color.G), to_rgb(color.B), 1}
		end

		return keypoints;

	elseif data_type == "NumberSequence" then
		local keypoints = {};

		for index, keypoint in value.Keypoints :: {NumberSequenceKeypoint} do
			keypoints[index] = {keypoint.Time, sn(keypoint.Value), sn(keypoint.Envelope)}
		end

		return keypoints;
	else
		return value;
	end
end

@native local function get_serial_value(token_map: TokenMap, data_type: string, value: any, context: any): any

	if data_type == "Instance" or data_type == "nil" then
		return from_child_map(value, token_map);

	elseif data_type == "string" then
		return token_map.Keys[value] or value;

	else
		return generic_deserialise_value(data_type, value, context);
	end;
end;

@native local function to_serial_value(token_map: TokenMap, data_type: string, value: any): any

	if data_type == "Instance" or typeof(value) == "Instance" then
		local map  = token_map.InstanceMap[value];

		if map then
			return get_child_map(value, token_map, {});
		else
			return nil;
		end

	else
		return generic_serialise_value(data_type, value);
	end
end

local function get_serial_value_instanced(token_map: TokenMap, class: string, property: string, value: any): any
	local context = get_instance_cached(class)[property];
	local _type = typeof(context);

	return get_serial_value(token_map, _type, value, context);
end

local function compress(value: number): string
	return Base91.encode_value(value) 
end

local function make_token(item: string, token_map: TokenMap): ()
	if not token_map.Tokens[item] then
		token_map.Count += 1;
		token_map.Tokens[item] = compress(token_map.Count);
	end
end

@native local function tokenify_string(value: string, token_map: TokenMap): string
	make_token(value, token_map);
	return token_map.Tokens[value];
end

--Tokenises a given <code>serial</code> table with the token map.
@native local function tokenify_index(serial: Dict, token_map: TokenMap)
	local new_serial = {};

	for key, value in serial do
		if typeof(key) == "string" then
			make_token(key, token_map);
			new_serial[token_map.Tokens[key]] = value;
		else
			new_serial[key] = value;
		end
	end

	return new_serial;
end

@native local function tokenify_value(serial: Dict, token_map: TokenMap)
	local new_serial = {};

	for key, value in serial do
		if typeof(value) == "string" then
			make_token(value, token_map);
			new_serial[key] = token_map.Tokens[value];
		else
			new_serial[key] = value;
		end
	end

	return new_serial;
end

@native local function tokenify_pairs(serial: Dict, token_map: TokenMap)
	local new_serial = {};
	local new_key, new_value;

	for key, value in serial do
		new_key, new_value = key, value;

		if typeof(value) == "string" then
			make_token(value, token_map);
			new_value = token_map.Tokens[value];
		end;

		if typeof(key) == "string" then
			make_token(key, token_map);
			new_key = token_map.Tokens[key];
		end;

		new_serial[new_key] = new_value;
	end

	return new_serial;
end

local function to_serial_value_instanced(token_map: TokenMap, class: string, property: string, value: any): any
	local context = get_instance_cached(class)[property];
	local _type = typeof(context);

	return to_serial_value(token_map, _type, value);
end

@native local function encode_value_block(token_map: TokenMap, value): {any}
	local serial_code = SerialisableDataTypesMap[typeof(value)];

	if not serial_code then
		error(`Value is not serialisable because type {typeof(value)} is unsupported`);
	end;

	local new_value, extra_dat_str = to_serial_value(token_map, typeof(value), value)

	if typeof(new_value) == "string" then
		new_value = tokenify_string(value, token_map);
	end;

	-- Currently only used for EnumItem
	if typeof(extra_dat_str) == "string" then
		extra_dat_str = tokenify_string(extra_dat_str, token_map);
	end;

	return {serial_code, new_value, extra_dat_str};
end

@native local function decode_value_block(token_map: TokenMap, value: {number}): any
	local _type = SerialisableDataTypes[value[1]];

	if _type then
		local context = value[3];

		if typeof(context) == "string" and token_map.Keys[context] then
			context = token_map.Keys[context];
		end

		local new_value = get_serial_value(token_map, _type, value[2], context);

		return new_value;
	end;

	return nil;
end;

--[[
	Gives a cached MeshPart to be cloned (Do not use directly), creating one if it doesn't exist yet.
]]
--local function get_mesh_part_sourced(mesh_id: string, collision_fidelity: Enum.CollisionFidelity?, yielding: boolean?): MeshPart?
--	local cached = Serialiser.MeshPartCache[mesh_id];

--	if cached and cached[collision_fidelity] then
--		return cached[collision_fidelity];
--	end

--	local await_mesh = MeshPartAwaitingThreads[mesh_id]

--	if await_mesh and await_mesh[collision_fidelity] then
--		if not yielding then return nil; end;

--		local await_part = await_mesh[collision_fidelity];


--		table.insert(await_part.threads, coroutine.running());
--		coroutine.yield();

--		-- It tried loading the MeshId with the given CollisionFidelity and failed too many times, abort future loading.
--		if await_part.failures >= 5 then
--			if not await_part.aborted then
--				await_part.aborted = tick();
--			end;

--			return nil;
--		end;

--		-- Check cache again
--		cached = Serialiser.MeshPartCache[mesh_id];

--		if cached and cached[collision_fidelity] then
--			return cached[collision_fidelity];
--		end
--	end;

--	if not await_mesh then 
--		await_mesh = {};
--		MeshPartAwaitingThreads[mesh_id] = await_mesh;
--	end;

--	if not await_mesh[collision_fidelity] then 
--		await_mesh[collision_fidelity] = { failures = 0, threads = {} }; 
--	end;

--	local await_part = await_mesh[collision_fidelity];

--	-- Do NOT call task.cancel on this thread, otherwise
--	-- you might cause other threads waiting for the same MeshPart to never return.
--	local success, source_mesh_part = pcall(
--		InsertService.CreateMeshPartAsync, InsertService, 
--		mesh_id, 
--		collision_fidelity, 
--		Enum.RenderFidelity.Automatic
--	);

--	local result_mesh_part = nil;

--	if success then
--		result_mesh_part = source_mesh_part;

--		if not Serialiser.MeshPartCache[mesh_id] then
--			Serialiser.MeshPartCache[mesh_id] = {};
--		end;

--		Serialiser.MeshPartCache[mesh_id][collision_fidelity] = source_mesh_part;
--		await_mesh[collision_fidelity] = nil;

--		for _, thread in await_part.threads do
--			task.spawn(thread);
--		end;

--		table.clear(await_part.threads);
--	else
--		local next_thread = table.remove(await_part.threads);

--		if next_thread then
--			-- Let another thread retry loading the same MeshPart.
--			task.spawn(next_thread);
--		else
--			await_mesh[collision_fidelity] = nil;
--		end;
--	end;

--	if not next( await_mesh ) then
--		MeshPartAwaitingThreads[mesh_id] = nil;
--	end;

--	return result_mesh_part;
--end;

--[[
	Gives a cached MeshPart to be cloned (Do not use directly), creating one if it doesn't exist yet.
]]
local function get_mesh_part_sourced(mesh_id: string, collision_fidelity: Enum.CollisionFidelity?, yielding: boolean?): MeshPart?
	
	if MeshPartAwaitingThreads[mesh_id] and MeshPartAwaitingThreads[mesh_id][collision_fidelity] then
		if not yielding then return nil; end;
		
		table.insert(MeshPartAwaitingThreads[mesh_id][collision_fidelity], coroutine.running());
		coroutine.yield();
	end;

	local cached = Serialiser.MeshPartCache[mesh_id];

	if cached and cached[collision_fidelity] then
		return cached[collision_fidelity];
	end

	if not MeshPartAwaitingThreads[mesh_id] then MeshPartAwaitingThreads[mesh_id] = {}; end;
	if not MeshPartAwaitingThreads[mesh_id][collision_fidelity] then MeshPartAwaitingThreads[mesh_id][collision_fidelity] = {}; end;
	
	local threads = MeshPartAwaitingThreads[mesh_id][collision_fidelity];
	
	-- Do NOT call task.cancel on this thread, otherwise
	-- you might cause other threads waiting for the same MeshPart to never return.
	local success, source_mesh_part = pcall(
		InsertService.CreateMeshPartAsync, InsertService, 
		mesh_id, 
		collision_fidelity, 
		Enum.RenderFidelity.Automatic
	);
	
	local result_mesh_part = nil;
	
	if success then
		result_mesh_part = source_mesh_part;
		
		if not Serialiser.MeshPartCache[mesh_id] then
			Serialiser.MeshPartCache[mesh_id] = {};
		end;

		Serialiser.MeshPartCache[mesh_id][collision_fidelity] = source_mesh_part;
		
		if MeshPartAwaitingThreads[mesh_id] then
			MeshPartAwaitingThreads[mesh_id][collision_fidelity] = nil;
		end;
		
		for _, thread in threads do
			task.spawn(thread);
		end;
		
		table.clear(threads);
	else
		local next_thread = table.remove(threads);
		
		if next_thread then
			-- Let another thread retry loading the same MeshPart.
			task.spawn(next_thread);
			
		elseif MeshPartAwaitingThreads[mesh_id] then
			MeshPartAwaitingThreads[mesh_id][collision_fidelity] = nil;
		end;
	end;
	
	if MeshPartAwaitingThreads[mesh_id] and not next( MeshPartAwaitingThreads[mesh_id] ) then
		MeshPartAwaitingThreads[mesh_id] = nil;
	end;
	
	return result_mesh_part;
end;

local function child_serialise(instance: Instance, token_map: TokenMap, parent: any)
	if not instance.Archivable or ClassExcludeList[instance.ClassName] then
		return nil;
	end;

	local serial = {
		Instance = instance;
		Parent = parent;
		Class = tokenify_string(instance.ClassName, token_map);
		Children = {};
		Attributes = {};
		Tags = {};
	};

	if instance.ClassName == "MeshPart" then
		serial.MeshId = tokenify_string((instance :: MeshPart).MeshId, token_map);
		-- CollisionFidelity is handled manually, so we can just store the id
		serial.CollisionFidelity = (instance :: MeshPart).CollisionFidelity.Value;
	end

	token_map.InstanceMap[instance] = serial;
	token_map.InstanceCount += 1;

	token_map.Parameters.InstanceIterator(
		token_map, instance, 
		token_map.InstanceCount, token_map.MaxInstanceCount);

	local children: {Instance};

	-- To be able to have a list of instances be parented under a folder for unpacking
	if token_map.TopLevelChildren then
		children = token_map.TopLevelChildren;
		token_map.TopLevelChildren = nil;
	else
		children = instance:GetChildren();
	end;

	for _, child in children do
		local serialised = child_serialise(child, token_map, serial);

		if serialised then
			table.insert(serial.Children, serialised);
		end;
	end

	return serial;
end

local function properties_serialise(serial, token_map)
	local instance: Instance = serial.Instance;

	token_map.PropertyCount += 1;
	token_map.Parameters.PropertyIterator(
		token_map, instance, 
		token_map.PropertyCount, token_map.MaxPropertyCount);

	if serial.Children then
		for _, child in serial.Children do
			properties_serialise(child, token_map);
		end;
	end;

	local tags = instance:GetTags();
	local attributes = instance:GetAttributes();
	local base_instance = if attributes.AssetLink then Serialiser.InventoryMap[attributes.AssetLink] else nil;

	if token_map.Parameters.UserId and table.find(tags, "InstanceModifier") then
		attributes._InterestId = token_map.Parameters.UserId;
	end;

	for attribute, value in attributes do
		local success, block = pcall(encode_value_block, token_map, value);

		if success then
			serial.Attributes[attribute] = block;
		else
			warn(block);
		end;
	end

	for _, tag in tags do
		if string.sub(tag, 1, 5) == "_TEMP" then
			continue;
		end;

		table.insert(serial.Tags, tag);
	end;
	
	local class_name = instance.ClassName;
	local redundancy = InstanceCacheServices[class_name] ~= nil;
	
	for property, property_value in PropertiesUtil.get_properties_of(instance) do
		if property == "Parent" then continue end;
		if not redundancy and Serialiser.is_property_default(instance, property, base_instance) then continue end;
		
		if not SerialisableDataTypesMap[typeof(property_value)] then 
			warn(`Property '{property}' is not serialisable because type {typeof(property_value)} is unsupported`);
			continue;
		end;

		local success, value = pcall(to_serial_value_instanced, token_map, class_name, property, property_value)

		if success then
			if typeof(value) == "string" then
				serial[property] = tokenify_string(value, token_map);
			else
				serial[property] = value;
			end
		end;
	end;
end

local function token_serialise(serial, token_map)
	if serial.Children then
		local new_children = {};

		for index, child in serial.Children do
			new_children[index] = token_serialise(child, token_map);
		end;

		serial.Children = new_children;
	end

	if not next(serial.Children) then
		serial.Children = nil;
	end

	if not next(serial.Tags) then
		serial.Tags = nil;
	else
		serial.Tags = tokenify_value(serial.Tags, token_map);
	end

	if not next(serial.Attributes) then
		serial.Attributes = nil;
	else
		serial.Attributes = tokenify_index(serial.Attributes, token_map);
	end;

	return tokenify_index(serial, token_map);
end

local function finalise_serial(serial, token_map: TokenMap)
	if token_map.Tokens.Parent then
		serial[token_map.Tokens.Parent] = nil;
	end

	if token_map.Tokens.Instance then
		serial[token_map.Tokens.Instance] = nil;
	end;

	if serial[token_map.Tokens.Children] then
		for _, child in pairs( serial[token_map.Tokens.Children] ) do
			finalise_serial(child, token_map);
		end
	end;
end

local function get_meshpart_info(serialised: any, token_map: any): (string, Enum.CollisionFidelity)
	local mesh_id = token_map.Keys[serialised[token_map.Tokens.MeshId]];
	local collision_fidelity = Enum.CollisionFidelity:FromValue(serialised[token_map.Tokens.CollisionFidelity]);

	return mesh_id, collision_fidelity;
end;

local function get_asset_link_instance(attributes, token_map): Instance?
	-- Asset Link for MeshParts and other non-serialisable instances (MeshPart and UnionOperation)
	if not attributes then
		return;
	end;

	local link_id = attributes[token_map.Tokens.AssetLink];

	if link_id then
		return Serialiser.InventoryMap[link_id[2]];
	end;

	return nil;
end

-- Spawns threads for all CreateMeshPartAsync calls to speed up loading.
local function deserialise_prepass(serialised: any, token_map: any): ()
	local class = token_map.Keys[serialised[token_map.Tokens.Class]];

	if class then
		local children = serialised[token_map.Tokens.Children];
		local attributes = serialised[token_map.Tokens.Attributes];
		local asset_instance = get_asset_link_instance(attributes, token_map);

		if not asset_instance and class == "MeshPart" then
			local mesh_id, collision_fidelity = get_meshpart_info(serialised, token_map);

			-- A lot of CreateMeshPartAsync calls, but Roblox throttle the calls and put them in a queue, so its fine.
			task.spawn(get_mesh_part_sourced, mesh_id, collision_fidelity, false);
		end;

		if children then
			for _, child in children do
				deserialise_prepass(child, token_map)
			end;
		end;
	end;
end

local function child_deserialise(serialised: any, token_map: any): any
	local class = token_map.Keys[serialised[token_map.Tokens.Class]];
	local success: boolean = false;
	local instance: Instance;

	if class then
		local children = serialised[token_map.Tokens.Children];
		local attributes = serialised[token_map.Tokens.Attributes];
		local asset_instance = get_asset_link_instance(attributes, token_map);

		if asset_instance then
			success, instance = true, asset_instance:Clone();
		end

		if not success and class == "MeshPart" then
			local mesh_id, collision_fidelity = get_meshpart_info(serialised, token_map);
			local mesh_part = Serialiser.create_mesh_part(mesh_id, nil, collision_fidelity);

			if mesh_part then
				success, instance = true, mesh_part;
			end;
		end;

		if not success then
			success, instance = pcall(create_instance, class);
		end;
		
		if not success then
			success = true;
			instance = Instance.new("Configuration");
			
			token_map.NonInstantiable[instance] = {};
		end;
		
		if success then
			token_map.InstanceCount += 1;
			token_map.InstanceMap[instance] = serialised;
			
			serialised.Instance = instance;

			token_map.Parameters.InstanceIterator(
				token_map, instance, 
				token_map.InstanceCount, token_map.MaxInstanceCount);

			if children then
				for _, child in children do
					local child_instance = child_deserialise(child, token_map)

					if child_instance then
						child_instance.Parent = instance;
					end;	
				end;
			end;

			return instance;
		end;
	end;

	warn("Error Instance:", instance);

	return nil;
end

local function properties_deserialise(serialised: any, token_map: TokenMap)
	local class = token_map.Keys[serialised[token_map.Tokens.Class]];
	local attributes = serialised[token_map.Tokens.Attributes];
	local tags = serialised[token_map.Tokens.Tags];
	local children = serialised[token_map.Tokens.Children];
	local instance = serialised.Instance :: Instance;

	if not instance then
		return warn("No Instance: could not deserialise properties.");
	end;

	token_map.PropertyCount += 1;
	token_map.Parameters.PropertyIterator(
		token_map, instance,
		token_map.PropertyCount, token_map.MaxPropertyCount
	);

	if children then
		for _, child in children do
			properties_deserialise(child, token_map);
		end;
	end;
	
	if token_map.NonInstantiable[instance] then 
		for key, value in pairs(serialised) do
			local property = token_map.Keys[key];
			
			if property == "Parent" then continue end;
			local success, value = pcall(get_serial_value_instanced, token_map, class, property, value);

			if success then
				token_map.NonInstantiable[instance][property] = value;
			end;
		end
	else
		for key, value in pairs(serialised) do
			local property = token_map.Keys[key];

			if property == "Parent" then continue end;
			local success, value = pcall(get_serial_value_instanced, token_map, class, property, value);

			if success then
				pcall(set_property, instance, property, value);
			end;
		end
	end
	
	if attributes then
		for key, value in attributes do
			local success, new_value = pcall(decode_value_block, token_map, value);

			if success then
				pcall(instance.SetAttribute, instance, token_map.Keys[key], new_value);
			end;
		end
	end;

	if tags then
		for _, token in tags do
			local tag = token_map.Keys[token];

			if tag then
				pcall(instance.AddTag, instance, tag);
			end;
		end;
	end;
end

local function cleanup_for_departure(serialised, token_map)
	token_map.Parameters = nil :: any;
	token_map.Serial = nil :: any;
	token_map.InstanceMap = nil :: any;
	token_map.Keys = nil :: any;
	token_map.TopLevelChildren = nil :: any;
	serialised.Parameters = nil :: any;
	serialised.Serial = nil :: any;
	serialised.InstanceMap = nil :: any;
	serialised.Keys = nil :: any;
	serialised.MaxInstanceCount = nil :: any;
	serialised.MaxPropertyCount = nil :: any;
	serialised.TopLevelChildren = nil :: any;
end

local function finalise_deserialise(deserial, token_map)
	deserial.Instance = nil;

	if deserial[token_map.Tokens.Children] then
		for _, child in pairs( deserial[token_map.Tokens.Children] ) do
			finalise_deserialise(child, token_map);
		end
	end
end

local function count_serialised_instances(serialised, token_map, counter: {value: number}): number
	counter.value += 1;

	local children = serialised[token_map.Tokens.Children];

	if children then
		for _, child in children do
			count_serialised_instances(child, token_map, counter)
		end;
	end;

	return counter.value;
end

-----------------------------------------------------------------------------------------

-- Must be ran once in the game before and serialisation happens.
function Serialiser.compile()
	for _, instance in Reidentify.get_inventory_asset_links(InstanceInventory) do
		local id = instance:GetAttribute("AssetLink");

		if id then
			Serialiser.InventoryMap[id] = instance;
		end;
	end

	return Serialiser.InventoryMap;
end

-- To always remind the developer of their horrific wrongdoings
function Serialiser.error_check_inventory()
	local to_identify, current_id = Reidentify.identify_inventory(InstanceInventory);

	for _, instance in to_identify do
		-- MeshParts serialise on their own so no need to notify.
		if instance:IsA("MeshPart") then
			continue;
		end;
		
		warn(`Instance '{instance}' is missing an AssetLink attribute, this will cause the serialiser to fail instancing this {instance.ClassName}! Use the provided 'link_inventory' function in the command line to fix!`)
	end;
end

--Returns whether the given instance's property is default
function Serialiser.is_property_default(instance: Instance, property: string, base_instance: Instance?): boolean
	local success, value = pcall(get_property, instance, property);

	if not success then 
		return true; 
	end;

	if base_instance then
		local success, value2 = pcall(get_property, base_instance, property);

		return (value == value2);
	else
		local success, value2 = pcall(get_instance_property, instance.ClassName, property);

		if not success then 
			return true;
		end;

		return (value == value2);
	end
end


-- Creates a new MeshPart instance with the specified MeshId, TextureID, and CollisionFidelity.
-- This method caches the MeshPart so that future calls with the same 'mesh_id' and 'collision_fidelity' give a new MeshPart immediately.
function Serialiser.create_mesh_part(mesh_id: string, texture_id: string?, collision_fidelity: Enum.CollisionFidelity?): MeshPart?
	if not collision_fidelity then
		collision_fidelity = Enum.CollisionFidelity.Default;
	end;

	local cached = get_mesh_part_sourced(mesh_id, collision_fidelity, true);

	if cached then
		local mesh_part = Instance.fromExisting(cached);

		if texture_id then
			mesh_part.TextureID = texture_id;
		end;

		return mesh_part;
	end;

	return nil;
end;


--Serialises an Instance and returns its table serialisation.
--@returns Serialised data (table or string)
--@returns Fairly accurate estimate of the data size, in bytes.
function Serialiser.serialise(instance: Instance | {Instance}, parameters: (Dict & SerialiserParameters)?): (any, number)
	if not parameters then
		parameters = {} :: any;
	end;

	assert(parameters);
	setmetatable(parameters :: any, DefaultSerialiserIndex);

	local instance_to_serialise: Instance;
	local top_level_children: {Instance}?;
	local max_instances: number = 0;

	if typeof(instance) == "Instance" then
		instance_to_serialise = instance;
		max_instances = #instance_to_serialise:GetDescendants();

	elseif typeof(instance) == "table" then

		if parameters.ConsiderOnlyTopLevel then
			local bad_instances: {[Instance]: boolean} = {};

			-- We shouldn't serialise
			for _, ins1 in instance do
				for _, ins2 in instance do
					if ins2:IsDescendantOf(ins1) then
						bad_instances[ins2] = true;
					end;
				end;
			end;

			local safe_descendant = table.create(#instance);

			for _, ins in instance do
				if not bad_instances[ins] then
					table.insert(safe_descendant, ins);
				end;
			end;

			instance = safe_descendant;
		end;

		for _, ins in instance do
			max_instances += #ins:GetDescendants();
		end;

		-- Temporary Instance to bind all the instances together
		instance_to_serialise = Instance.new("Folder");
		instance_to_serialise.Name = "Objects";

		-- Way to make it so you dont need to parent while serialising
		top_level_children = instance;
	else
		error(`Unsupported type {typeof(instance)} for paramter 'instance'`);
	end

	local max_instances = #instance_to_serialise:GetDescendants();

	local token_map = {
		Tokens = {}, 
		InstanceMap = {};
		Keys = {};
		Count = 0,
		InstanceCount = 0,
		PropertyCount = 0,
		MaxInstanceCount = max_instances;
		MaxPropertyCount = max_instances;
		Parameters = parameters;
		TopLevelChildren = top_level_children;
		UnpackTopLevel = if top_level_children then true else nil;
	};

	local serial_tree = child_serialise(instance_to_serialise, token_map);
	properties_serialise(serial_tree, token_map);

	local serialised = token_serialise(serial_tree, token_map);
	serialised["0"] = token_map;

	finalise_serial(serialised, token_map);
	cleanup_for_departure(serialised, token_map);

	local json = HttpService:JSONEncode(serialised);
	local machine = "Zlib"
	
	if parameters.PreferZstd then
		machine = nil;
	end;
	
	local compressed = Serialiser.compress(json, { 
		machine = machine, 
		level = parameters.CompressionLevel, 
		iterator = parameters.CompressIterator 
	})
	
	assert(compressed, "[Serialiser]: Nothing was compressed.");

	return compressed, #compressed
end;

--Deserialises a serial table and returns its Instance and a list of instances that could not be instantiated.
function Serialiser.deserialise(serialised: any, parameters: (Dict & DeserialiserParameters)?): ({Instance}, {[Instance]: {[string]: any}})
	if not parameters then
		parameters = {} :: any;
	end;

	assert(parameters);
	setmetatable(parameters :: any, DefaultDeserialiserIndex);

	if typeof(serialised) == "string" then
		local decompressed = Serialiser.decompress(serialised, { iterator = parameters.DecompressIterator });
		
		serialised = HttpService:JSONDecode(decompressed);
	end;

	local token_reverse_map = table.clone(serialised["0"]);
	local instance_count: number = token_reverse_map.InstanceCount;

	-- If serialised doesn't contain InstanceCount
	if not instance_count then
		instance_count = count_serialised_instances(serialised, token_reverse_map, {value = 0});
	end;

	token_reverse_map.Parameters = parameters;
	token_reverse_map.Serial = serialised;
	token_reverse_map.MaxInstanceCount = instance_count;
	token_reverse_map.MaxPropertyCount = token_reverse_map.PropertyCount or instance_count;
	token_reverse_map.InstanceCount = 0;
	token_reverse_map.PropertyCount = 0;
	token_reverse_map.InstanceMap = {};
	token_reverse_map.NonInstantiable = {};
	token_reverse_map.Keys = Table.hashmap(token_reverse_map.Tokens);

	deserialise_prepass(serialised, token_reverse_map);

	local instance, err = child_deserialise(serialised, token_reverse_map);
	properties_deserialise(serialised, token_reverse_map);
	finalise_deserialise(serialised, token_reverse_map);
	cleanup_for_departure(serialised, token_reverse_map);

	if parameters.Unpack and serialised["0"].UnpackTopLevel then
		local children = instance:GetChildren();
		local instance_list = table.create(#children);

		for _, child in children do
			table.insert(instance_list, child);
		end;

		return instance_list;
	end

	return {instance}, token_reverse_map.NonInstantiable;
end

-- General compress function with support for using Zlib compression. If a machine is not specified then it will use Zstd by default.
function Serialiser.compress(text: string, parameters: StringCompressParameters): string
	if not parameters then parameters = {} end;
	
	if not parameters.machine then
		parameters.machine = "Zstd";
		
		local success, compressed = pcall(Serialiser.compress, text, parameters);
		
		if success then
			return compressed;
		else
			warn(compressed);
			parameters.machine = "Zlib";
			
			return Serialiser.compress(text, parameters);
		end;
	end;
	
	if parameters.machine == "Zlib" then
		local LibDeflate = require(script.LibDeflate);
		
		local compress_parameters = {level = parameters.level, writer_step = parameters.iterator};
		local success, compressed = pcall(LibDeflate.Zlib.Compress, text, compress_parameters)

		if not success then
			error(`[Serialiser]: Zlib compress failed: {compressed}`);
		end
		
		local success, encoded = pcall(Base91.encode_string, compressed);
		
		if not success then
			error(`[Serialiser]: Base91 encoding failed: {encoded}`);
		end;
		
		return encoded;
		
	elseif parameters.machine == "Zstd" then
		local success, compressed = pcall(BufferUtil.compress, text);
		
		if not success then
			error(`[Serialiser]: Zstd compress failed: {compressed}`);
		end;
		
		return compressed;
	end;
	
	error(`[Serialiser]: compress failed: invalid machine used ({parameters.machine})`);
end;

-- General decompress function with support for Zlib. If a machine is not specified then it will decide the compression type based on the given text.
function Serialiser.decompress(text: string, parameters: StringDecompressParameters?): string
	if not parameters then parameters = {} end;
	
	if not parameters.machine then
		if #text > 1 and string.byte(text, 1) == 56 and string.byte(text, 2) == 63 then
			parameters.machine = "Zlib";
		else
			parameters.machine = "Zstd";
		end;
	end;
	
	if parameters.machine == "Zlib" then
		-- Assume that Zlib compress was used for serialised.

		local LibDeflate = require(script.LibDeflate);
		
		local success, decoded = pcall(Base91.decode_string, text);
		
		if not success then
			error(`[Serialiser]: Base91 decoding failed: {decoded}`)
		end;
		
		local decompress_parameters = {reader_iterator = parameters.iterator};
		local success, decompressed = pcall(LibDeflate.Zlib.Decompress, decoded, decompress_parameters);
		
		if not success then
			error(`[Serialiser]: Zlib decompress failed: {decompressed}`);
		end;
		
		return decompressed;
		
	elseif parameters.machine == "Zstd" then
		-- Assume that Internal Zstd was used for serialised.

		local success, decompressed = pcall(BufferUtil.decompress, text);

		if not success then
			error(`[Serialiser]: Zstd decompress failed: {decompressed}`);
		end;
		
		return decompressed;
	end;
	
	error(`[Serialiser]: decompress failed: invalid machine used ({parameters.machine})`);
end;

function Serialiser.compress_json(text: string, parameters: StringCompressParameters?): string
	local success, json = pcall(HttpService.JSONEncode, HttpService, text);
	
	if success then
		return Serialiser.compress(json, parameters);
	end;
	
	return "";
end

function Serialiser.decompress_json(text: string, parameters: StringDecompressParameters?): any
	local decompress = Serialiser.decompress(text, parameters);
	local success, raw_table = pcall(HttpService.JSONDecode, HttpService, decompress);
	
	if success then
		return raw_table
	end;
	
	return {};
end

-- Copies the properties of the given instance and returns a table of format <strong>{Property = Value}</strong>.
function Serialiser.clone_properties(instance: Instance): {[string]: any}
	local properties = {};

	for property in PropertiesUtil.get_properties(instance) do
		local success, value = pcall(get_property, instance, property);

		if success then
			properties[property] = value;
		end;
	end;

	return properties;
end

-- Applies the properties on a given instance.
function Serialiser.apply_properties(instance: Instance, properties: {[string]: any}): ()
	for name, value in properties do
		pcall(set_property, instance, name, value);
	end;
end;

function Serialiser.get_default_property(class_name: string, property: string): any
	return get_instance_property(class_name, property);
end;

Serialiser.serialise_value = generic_serialise_value;
Serialiser.deserialise_value = generic_deserialise_value;

return Serialiser;