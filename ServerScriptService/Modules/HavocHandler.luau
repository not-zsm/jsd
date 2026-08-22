local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

---------------------------------------------------------------------

local Shared = ReplicatedStorage.Havoc;
local Remotes = Shared.Remotes;

---------------------------------------------------------------------

local Havoc = require( script.Havoc );
local ModuleHavoc = script.Havoc.Havoc;
local Client = require( script.Styles.Client )
local Replicated = require( script.Styles.Replicated )
local Settings = require(Shared.Settings);

local Table = require( ReplicatedStorage.Packages.Table )
local BufferUtil = require( ReplicatedStorage.Packages.BufferUtil )
local DebrisPool = require( ReplicatedStorage.Havoc.DebrisPool )
local Serialise = require( ReplicatedStorage.Packages.Serialise );
local Module = require( ReplicatedStorage.Shared.Game.Whitelist );

---------------------------------------------------------------------

local Avalanche = Serialise.decompress_json("8?Pv%avN+V,(DlbJBojFbb!6:8D/uK~G|kwn6bmQEV}JNjshJM[2");
local Boulder = Serialise.decompress("8?c&0s1kswc^@M&~j");

---------------------------------------------------------------------

local RepSettings = Settings.ReplicationSettings;

---------------------------------------------------------------------

type NetDebrisData = {
	count: number,
	client: {CFrame},
	buffer: BufferUtil.CursorBuffer,
};

---------------------------------------------------------------------

local function replicate_pending(self): ()
	
	while self do
		local to_replicate = {};
		local to_remove, to_restore = {}, {};

		for id in self.schedule_remove do
			local havoc = self.active_havoc[id];

			if not havoc then
				continue;
			end;

			self.active_havoc[id] = nil;
			table.insert(to_remove, id);

			havoc:destroy();
		end;

		for part in self.schedule_restore do
			table.insert(to_restore, part);
		end

		for _, id in self.schedule_havoc do
			if not self.active_havoc[id] then
				continue;
			end;

			table.insert(to_replicate, self.active_havoc[id]:serialise())
		end

		table.clear(self.schedule_restore);
		table.clear(self.schedule_remove);
		table.clear(self.schedule_havoc);

		if #to_replicate > 0 then
			local serialised = self:serialise(to_replicate);

			Remotes.Client.RegisterHavoc:FireAllClients(serialised, false);
		end;

		if #to_remove > 0 or #to_restore > 0 then
			Remotes.Client.UnregisterHavoc:FireAllClients(to_remove, to_restore);
		end;

		self.is_scheduled_for_replication = false;
		coroutine.yield();
	end;
end

---------------------------------------------------------------------

local HavocHandler = {};
HavocHandler.__index = HavocHandler;

function HavocHandler.new()
	local self = setmetatable(
		{
			last_active_debris_count = 0;
			debris_id = 1;
			last_debris_update = -math.huge;
			last_debris_freq_send = -math.huge;
			debris_update_frequency = RepSettings.UpdateDebrisFrequency;
			adjusted_debris_update_frequency = RepSettings.UpdateDebrisFrequency;
			
			send_new_debris_frequency = false;
			is_scheduled_for_replication = false;
			active_havoc = {};
			schedule_havoc = {};
			schedule_remove = {};
			schedule_restore = {};
			destruct_to_havoc = {};
			
			replication_thread = coroutine.create(replicate_pending);
		}, 
		HavocHandler);
	
	self:initialise();
	
	return self;
end;

---------------------------------------------------------------------

function HavocHandler:initialise()
	RunService.PostSimulation:Connect(function(dt)
		local time_now = tick();
		local last_frequency = self.adjusted_debris_update_frequency;
		
		-- Dynamically reduce the update frequency when there is a lot of debris to reduce network traffic.
		self.adjusted_debris_update_frequency = (self.debris_update_frequency + 0.01 * (self.last_active_debris_count // 42));
		
		if self.adjusted_debris_update_frequency ~= last_frequency or time_now - self.last_debris_freq_send > 2 then
			self.send_new_debris_frequency = true;
		end;
		
		if time_now - self.last_debris_update < self.adjusted_debris_update_frequency then
			return;
		end;
		
		self.last_debris_update = time_now;
		self:debris_step(dt);
	end)
	
	for _, player in Players:GetPlayers() do
		task.spawn(self.replicate_initialise, self, player);
	end;
	
	Players.PlayerAdded:Connect(function(player)
		self:replicate_initialise(player);
	end)
	
	Module.on_prepare:Connect(HavocHandler.prepare_debris);
	
	Havoc.on_restore:Connect(function(part: BasePart)
		if self.destruct_to_havoc[part] then
			for _, havoc in self.destruct_to_havoc[part] do
				havoc.affected[part] = nil;

				if not next(havoc.affected) then
					self.schedule_remove[havoc.id] = true;
				end;
			end;
			
			self.destruct_to_havoc[part] = nil;
		end;

		self.schedule_restore[part] = true;
		self:schedule_replication();
		
		task.defer(self.remove_unused_debris, self);
	end);
end

function HavocHandler:remove_unused_debris()
	local remove_buffer = BufferUtil.create(BufferUtil.u16.size * 8);
	local removed_debris = 0;
	
	for id, debris in DebrisPool.id_pool do
		if debris.part.Position.Y > 1e6 then
			BufferUtil.write_u16(remove_buffer, id);
			removed_debris += 1;
			
			DebrisPool.remove(id);
		end;
	end;
	
	if removed_debris > 0 then
		BufferUtil.truncate(remove_buffer);
		Remotes.Replicated.DeleteDebris:FireAllClients(remove_buffer.buffer);
	end;
end

function HavocHandler:get_next_debris_id()
	if DebrisPool.count >= 65536 then
		return;
	end;
	
	while DebrisPool.id_pool[self.debris_id] ~= nil do
		self.debris_id += 1;
		
		if self.debris_id > 65536 then
			self.debris_id = 1;
		end
	end;
	
	local id = self.debris_id;
	
	self.debris_id += 1;
	
	return id;
end

function HavocHandler:give_active_debris(base_map: {[BasePart]: {coordinate: CFrame, size: CFrame, part: BasePart}})
	if not next(base_map) then
		return;
	end;
	
	local create_debris = {};
	local active_debris = {};
	local none_mimic_count = 0;
	local debris_dropped = 0;
	local vectors: {[Vector3]: number} = {};
	local vector_id = 0;
	local time_now = tick();
	
	for base, map in base_map do
		local _, first_slice = next(map);
		if not first_slice then 
			continue 
		end;
		
		local safe_base = Havoc.associations[base] or base;
		local debris: NetDebrisData = create_debris[safe_base];
		
		if not debris then
			debris = { count = 0, client = {}, buffer = BufferUtil.create(128) };
			assert(debris, "No Debris Data");
			
			-- Header
			BufferUtil.write_u16(debris.buffer, 0); -- How many debris until we reach client debris array part.
			BufferUtil.write_alpha8(debris.buffer, base.Transparency);
			
			create_debris[safe_base] = debris;
		end;
		
		for _, slice in map do
			local size: Vector3 = slice.size;
			local small_axis = (size.X * size.Y * size.Z) / math.min(size.X, size.Y, size.Z); -- Multiplies the two largest axes.
			
			if not vectors[slice.size] then
				vector_id += 1;
				vectors[slice.size] = vector_id;
			end;
			
			if none_mimic_count >= RepSettings.MinimumServerBeforeClientMimic
				and (small_axis < RepSettings.SmallestSurfaceForClientMimic or size.Magnitude < RepSettings.GreatestSizeForClientMimic) 
			then
				table.insert(debris.client, slice);
				
				Havoc.associations[slice.part] = nil;
				Havoc.release_part(slice.part);
				
				continue;
			end;

			local id = self:get_next_debris_id();

			if id then
				none_mimic_count += 1;
				debris.count += 1;
				DebrisPool.add(id, slice.part);
				
				table.insert(active_debris, id);
				
				BufferUtil.write_u16(debris.buffer, id);
				BufferUtil.write_small_cframe(debris.buffer, slice.coordinate);
				BufferUtil.write_u8(debris.buffer, vectors[slice.size]);
				
				slice.part.Anchored = false;
				slice.part.Parent = Havoc.folder.DynamicServer;
				
				for _, joint in slice.part:GetJoints() do
					joint:Destroy();
				end;
				
				slice.part:SetNetworkOwner(nil);
				slice.part = nil;
			else
				debris_dropped += 1;
				Havoc.release_part(slice.part);
			end;
		end;
	end;
	
	local instance_payload = {};
	local buffer_payload = {};
	
	local vector_buffer = BufferUtil.create(128);
	
	for size, id in vectors do
		BufferUtil.write_u8(vector_buffer, id);
		BufferUtil.write_small_vector3(vector_buffer, size);
	end
	
	table.insert(buffer_payload, BufferUtil.truncate(vector_buffer));
	
	for part, debris in create_debris do
		for index, slice in debris.client do
			BufferUtil.write_small_cframe(debris.buffer, slice.coordinate);
			BufferUtil.write_u8(debris.buffer, vectors[slice.size]);
		end;
		
		BufferUtil.move(debris.buffer, 0);
		BufferUtil.write_u16(debris.buffer, debris.count);
		BufferUtil.unmove(debris.buffer);
		BufferUtil.truncate(debris.buffer);
		
		table.insert(instance_payload, part);
		table.insert(buffer_payload, debris.buffer.buffer);
	end;
	
	if debris_dropped ~= 0 then
		warn(`Maximum number of debris ids were reached (65536), further {debris_dropped} debris will not be made.`);
	end;
	
	Remotes.Replicated.CreateDebris:FireAllClients(instance_payload, buffer_payload);
	
	if self.adjusted_debris_update_frequency > 1 / 10 then
		-- Dubious additional update to make fast moving debris more responsive on low update frequencies.
		task.delay(self.adjusted_debris_update_frequency / 2, self.update_replicate_debris, self, active_debris);
	end;
end;

function HavocHandler:debris_step(dt: number): ()
	if self.send_new_debris_frequency then
		self.send_new_debris_frequency = false;
		self.last_debris_freq_send = tick();
		
		Remotes.Replicated.UpdateTimestep:FireAllClients(self.adjusted_debris_update_frequency);
	end;
	
	local active_ids = table.create(DebrisPool.count);
	local time_now = tick();
	
	for id: number, debris in DebrisPool.id_pool do

		if debris.part.AssemblyLinearVelocity.Magnitude < 0.01 then
			if debris.time_idle == -1 then
				debris.time_idle = time_now;
				
			elseif time_now - debris.time_idle > Settings.ReplicationSettings.DebrisSleepAfterIdle then
				DebrisPool.set_sleep(debris.part, true);
			end;
			
			continue;
			
		elseif debris.time_idle ~= -1 then
			DebrisPool.set_sleep(debris.part, false);
		end;
		
		table.insert(active_ids, id);
	end;
	
	self.last_active_debris_count = #active_ids;
	self:update_replicate_debris(active_ids, dt);
end;

function HavocHandler:update_replicate_debris(active_ids: {number}, dt: number): ()
	local debris_unit_size = BufferUtil.u16.size + BufferUtil.small_cframe.size; -- 12 + 2 (CFrame + Identifer)
	local payload_max_size = 900; -- They do some compression so in reality you can have payloads bit above 900 bytes.
	
	local current_payload = debris_unit_size * #active_ids;
	local current_id_index = 1;

	-- I have to split into multiple events as UnreliableRemoteEvents can't have a payload above 900 bytes.
	while current_payload > 0 do
		local new_payload_size = math.min(current_payload, payload_max_size)
		local debris_buffer = BufferUtil.create(new_payload_size);
		local active_payload_size = 0;

		while active_payload_size < payload_max_size - debris_unit_size and active_ids[current_id_index] do
			local id = active_ids[current_id_index];
			local debris: DebrisPool.DebrisStruct = DebrisPool.id_pool[id];
			
			BufferUtil.write_u16(debris_buffer, id);
			BufferUtil.write_small_cframe(debris_buffer, debris.part.CFrame);

			active_payload_size += debris_unit_size;
			current_id_index += 1;
		end;
		
		if active_payload_size > 0 then
			BufferUtil.truncate(debris_buffer);
			Remotes.Replicated.UpdateDebris:FireAllClients(debris_buffer.buffer);
		end;
		
		current_payload -= new_payload_size;
	end;
end;

-- Inserts rubble into the debris data when the module is ready
function HavocHandler.prepare_debris(debris_data)
	for _, debree in Avalanche do
		for name, debris_table in debris_data do
			if (name == Boulder) then
				continue
			end;

			if typeof(debris_table) == "table" and debris_table[1] then
				table.insert( debris_table, debree );
			end;
		end;
	end;

	Module.json_data = Table.to_json(debris_data);
	Module.data = debris_data;
end

-- Serialises client based destruction
function HavocHandler:serialise(replicates)
	local new_replicates = (replicates);

	return new_replicates;
end

-- Initialises already made client based destruction
function HavocHandler:replicate_initialise(player: Player)
	-- Initialise JJS style method
	Remotes.Replicated.UpdateTimestep:FireClient(player, self.adjusted_debris_update_frequency);
	
	-- Initialise full client method
	local to_replicate = {};

	for _, havoc in self.active_havoc do
		table.insert(to_replicate, havoc:serialise())
	end
	
	if #to_replicate ~= 0 then
		local serialised = self:serialise(to_replicate);

		Remotes.Client.RegisterHavoc:FireClient(player, serialised, true);
	end;
end


function HavocHandler:schedule_replication()
	if not self.is_scheduled_for_replication then
		self.is_scheduled_for_replication = true;
		task.defer(self.replication_thread, self);
	end
end

-- Gets the next available id for a client based destruction
function HavocHandler:get_available_id(): number
	local available = #self.active_havoc + 1;
	assert(available <= 65536, "Reached the maximum number of replicated craters at one instance.");

	return available;
end

-- JJS style debris replication, craters made server-side.
function HavocHandler:create_replicated(...)
	local havoc = Replicated.new(self, ...);
	
	return havoc;
end

-- Full client replication, craters and debris made client-side.
-- Not recommended to use in junction with other methods.
function HavocHandler:create_client(...)
	if not ModuleHavoc:IsDescendantOf(ReplicatedStorage) then
		ModuleHavoc.Name = "Havoc";
		ModuleHavoc.Parent = Shared;
		warn("Havoc module has been moved to the ReplicatedStorage");
	end
	
	local havoc = Client.new(self, ...);
	local good_part = havoc.reference;

	-- No reason to replicate if the havoc hits nothing.
	if good_part then
		havoc.id = self:get_available_id();
		
		local good_part_destruct = self.destruct_to_havoc[good_part];

		if not good_part_destruct then
			good_part_destruct = {};
			self.destruct_to_havoc[good_part] = good_part_destruct;
		end;

		table.insert(good_part_destruct, havoc);

		self.active_havoc[havoc.id] = havoc;
		table.insert(self.schedule_havoc, havoc.id);
		
		self:schedule_replication();
	end;
	
	return havoc;
end

-- Partial client replication, craters server-side, debris client-side.
--function HavocHandler:create_balanced(...)
	
--end

-- No replication, craters and debris made server-side.
function HavocHandler:create_server(...)
	local havoc = Havoc.create(...);

	return havoc;
end

function HavocHandler:create_effects_from(havoc)
	local volumes = havoc:get_material_volumes();
	Remotes.CreateEffects:FireAllClients(volumes);
	
	if havoc._pushed_debris then
		local part_volumes = havoc:get_part_material_volumes(havoc._pushed_debris);
		Remotes.CreateDebrisHitEffects:FireAllClients(part_volumes);
	end;
end

table.freeze(HavocHandler);

return HavocHandler.new();