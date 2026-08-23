local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GeometryService = game:GetService("GeometryService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Instances = require( ReplicatedStorage.Packages.Instances )

-------------------------------------------------------------------------------------------

Instances.get_folder_tree(workspace, RunService:IsServer(), {
	Havoc = {
		Static = {};
		Dynamic = {};
	};
})

local Havocs = workspace.Havoc;

local HavocStatic = Havocs.Static;
local HavocDynamic = Havocs.Dynamic;

-- These are also created on the client for convienence (they wont hold servers objects still)
local HavocStaticServer = Instance.new("Camera", Havocs);
HavocStaticServer.Name = "StaticServer";

local HavocDynamicServer = Instance.new("Camera", Havocs);
HavocDynamicServer.Name = "DynamicServer";

local MapModel = workspace.Map.Model;
local AlternativeHavocs = MapModel:FindFirstChild("Havocs") or HavocStatic;

-------------------------------------------------------------------------------------------

local weak_keys, weak_values do
	local keys = table.freeze {__mode = "k"};

	function weak_keys(tbl)
		return setmetatable(tbl, keys)
	end;

	local values = table.freeze {__mode = "v"};

	function weak_values(tbl)
		return setmetatable(tbl, values)
	end
end;

-------------------------------------------------------------------------------------------

local Mesh = require( script.Mesh )
local Spatial = require( script.Spatial )
local Types = require( script.Types )

local PartCache = require( ReplicatedStorage.Havoc.PartCache );
local Settings = require( ReplicatedStorage.Havoc.Settings );
local Signal = require( ReplicatedStorage.Packages.Signal );
local DebrisPool = require( ReplicatedStorage.Havoc.DebrisPool )

-------------------------------------------------------------------------------------------

type SliceInfo = Types.SliceInfo;
type SlicePartMap = Types.SlicePartMap;
type HavocParameters = Types.HavocParameters;
type DestructInfo = Types.DestructInfo;
type DestructUnitInfo = Types.DestructUnitInfo;
type MakeDebrisInfo = Types.MakeDebrisInfo;
type MakeCraterInfo = Types.MakeCraterInfo;
type PartMap = Types.PartMap;
export type Destruction = Types.Destruction;

-------------------------------------------------------------------------------------------

local Destruction = {} :: Types.ClassDestruction
Destruction.__index = Destruction;
Destruction.destructs = weak_keys{};
Destruction.associations = weak_values{};
Destruction.timer_units = weak_keys{};
Destruction.folder = Havocs;
Destruction.settings = Settings;
Destruction.on_restore = Signal.new() :: Signal.Signal<BasePart>;
Destruction.on_destruct = Signal.new() :: Signal.Signal<BasePart>;

-------------------------------------------------------------------------------------------

local CachePart = Instance.new("Part");
CachePart.TopSurface = Enum.SurfaceType.Smooth;
CachePart.Anchored = true;

local Parts = PartCache.new(CachePart);
Parts:expand(100);

local Rnd = Random.new();

-- Reduces memory usage for saving properties of parts during destruction
local PartDestructionIndexer = {};

for _, properties in Settings.SetPropertiesOfDestructedPart do
	for key, value in properties do
		table.insert(PartDestructionIndexer, key);
	end;
end;

table.sort(PartDestructionIndexer);

-------------------------------------------------------------------------------------------

local HavocTagList = {};

if Settings.TagToHavoc then
	CollectionService:GetInstanceAddedSignal(Settings.TagToHavoc):Connect(function(item)
		table.insert(HavocTagList, item);
	end);

	CollectionService:GetInstanceRemovedSignal(Settings.TagToHavoc):Connect(function(item)
		local index = table.find(HavocTagList, item);

		if index then
			HavocTagList[index], HavocTagList[#HavocTagList] = HavocTagList[#HavocTagList], nil;
		end;
	end);
end;

-------------------------------------------------------------------------------------------

@native local function can_subdivide_part(smallest: number, largest: number, threshold: number, size: Vector3): boolean
	if smallest == size.X then 
		smallest = math.min(size.Y, size.Z)
	elseif smallest == size.Y then
		smallest = math.min(size.X, size.Z)
	else
		smallest = math.min(size.X, size.Y)
	end

	return largest >= threshold * smallest 
	--Returns true if part is rectangular. 
	--Part is rectangular if the largest axis is at least 1.5x bigger than the smallest axis
end

@native local function slice_part_in_half(coordinate: CFrame, size: Vector3): (SliceInfo, SliceInfo)
	local vector_direction: Vector3;
	local size_x, size_y, size_z = size.X, size.Y, size.Z;
	local max_axis = math.max(size_x, size_y, size_z);

	if max_axis == size_x then
		size_x *= 0.5;
		vector_direction = Vector3.xAxis;

	elseif max_axis == size_y then
		size_y *= 0.5;
		vector_direction = Vector3.yAxis;
	else
		size_z *= 0.5;
		vector_direction = Vector3.zAxis;
	end

	local slice_size = Vector3.new(size_x, size_y, size_z);
	local half_size_part = slice_size * 0.5;

	return
		{coordinate = coordinate + coordinate:VectorToWorldSpace(half_size_part *  vector_direction), size = slice_size},
		{coordinate = coordinate + coordinate:VectorToWorldSpace(half_size_part * -vector_direction), size = slice_size};
end

@native local function slice_part_subdivide(coordinate: CFrame, slice_size: Vector3, vertices: {Vector3}, destination: {SliceInfo}): ()
	local half_size_part = slice_size * 0.5;

	for index, vector_direction in vertices do
		table.insert(destination, {
			coordinate = coordinate + coordinate:VectorToWorldSpace(half_size_part *  vector_direction), 
			size = slice_size
		});
	end;
end

@native local function slice(
	slice_info: SliceInfo, 
	divided_cubes: {SliceInfo}, 
	intersecting_cubes: {SliceInfo}, 
	parameters: HavocParameters,
	in_spatial_query: (slice_info: SliceInfo) -> boolean
): ()
	local stack: {SliceInfo} = { slice_info };
	local block_size: number = parameters.block_size;
	local part_list: {SliceInfo} = table.create(8);
	
	-- Keeps slicing until there is nothing more to slice.
	while #stack ~= 0 do
		local current = table.remove(stack);
		local size = current.size;
		
		local largest = math.max(size.X, size.Y, size.Z);
		
		if largest > block_size then
			table.clear(part_list);
			
			local smallest = math.min(size.X, size.Y, size.Z);

			if Settings.UseSimpleSubdivde or can_subdivide_part(smallest, largest, Settings.SubdivideRectangleThreshold, size) then
				local part1, part2 = slice_part_in_half(current.coordinate, size);
				
				table.insert(part_list, part1);
				table.insert(part_list, part2);
				
			elseif smallest * Settings.SubdivideRectangleThreshold <= largest then
				if smallest == size.X then
					slice_part_subdivide(current.coordinate, Vector3.new(size.X, size.Y * 0.5, size.Z * 0.5), Spatial.vertices_x, part_list);
					
				elseif smallest == size.Y then
					slice_part_subdivide(current.coordinate, Vector3.new(size.X * 0.5, size.Y, size.Z * 0.5), Spatial.vertices_y, part_list);

				else
					slice_part_subdivide(current.coordinate, Vector3.new(size.X * 0.5, size.Y * 0.5, size.Z), Spatial.vertices_z, part_list);
				end;
			else
				slice_part_subdivide(current.coordinate, Vector3.new(size.X, size.Y, size.Z) * 0.5, Spatial.vertices, part_list);
			end

			for _, slice in part_list do
				if in_spatial_query(slice) then
					table.insert(stack, slice);
				else
					table.insert(divided_cubes, slice);
				end;
			end;
		else
			table.insert(intersecting_cubes, current);
		end;
	end;
end

@native local function block_slice(slice_info: SliceInfo, divided_cubes: {SliceInfo}, intersecting_cubes: {SliceInfo}, parameters: HavocParameters): ()
	local origin = parameters.origin;
	local size = parameters.size :: Vector3;

	local function is_touching_wrapper(test_slice_info: SliceInfo)
		return Spatial.is_touching(test_slice_info.coordinate, test_slice_info.size, origin, size);
	end;

	return slice(slice_info, divided_cubes, intersecting_cubes, parameters, is_touching_wrapper)
end

@native local function sphere_slice(slice_info: SliceInfo, divided_cubes: {SliceInfo}, intersecting_cubes: {SliceInfo}, parameters: HavocParameters): ()
	local centre = parameters.origin.Position;
	local radius = parameters.radius :: number;

	local function in_radius_wrapper(test_slice_info: SliceInfo)
		return Spatial.in_radius(test_slice_info.coordinate, test_slice_info.size, centre, radius);
	end;

	return slice(slice_info, divided_cubes, intersecting_cubes, parameters, in_radius_wrapper)
end

@native local function cylinder_slice(slice_info: SliceInfo, divided_cubes: {SliceInfo}, intersecting_cubes: {SliceInfo}, parameters: HavocParameters): ()
	local centre = parameters.origin;
	local radius = parameters.radius :: number;
	local size = (parameters.size :: Vector3).Y;

	local function is_touching_cylinder_wrapper(test_slice_info: SliceInfo)
		return Spatial.is_touching_cylinder(test_slice_info.coordinate, test_slice_info.size, centre, size, radius);
	end;

	return slice(slice_info, divided_cubes, intersecting_cubes, parameters, is_touching_cylinder_wrapper)
end;

local function is_debris(part: BasePart): boolean
	return part.Parent == HavocDynamic or part.Parent == HavocDynamicServer;
end;

local slice_method_for_shape = { Box = block_slice, Sphere = sphere_slice, Cylinder = cylinder_slice };

local get_part: (base: BasePart, slice: SliceInfo) -> BasePart;
local release_part: (part: BasePart) -> ();
local is_destructed: (part: BasePart) -> boolean;
local set_destructed: (part: BasePart, value: boolean?) -> ();

if Settings.UseAttributeDestructed then
	@native function is_destructed(part: BasePart): boolean
		return part:GetAttribute(Settings.AttributeDestructed);
	end
	
	@native function set_destructed(part: BasePart, value: boolean): ()
		part:SetAttribute(Settings.AttributeDestructed, value);
	end;
else
	@native function is_destructed(part: BasePart): boolean
		if Destruction.destructs[part] then
			return true;
		end;

		return false;
	end;
	
	function set_destructed(part: BasePart, value: boolean): ()
		return;
	end
end;

if Settings.UsePartCache then
	function get_part(base: BasePart, slice: SliceInfo): BasePart
		local part = Parts:get(slice.coordinate);
		
		return part;
	end;

	function release_part(part: BasePart): ()
		Destruction.associations[part] = nil;
		
		if part:IsDescendantOf(workspace) then
			for _, joint in part:GetJoints() do
				joint:Destroy();
			end;
		end;
		
		if part.ClassName == "Part" then
			part:ClearAllChildren();
			Parts:give(part);
		else
			part:Destroy();
		end
	end;
else
	function get_part(base: BasePart, slice: SliceInfo): BasePart
		local part = Instance.fromExisting(base);
		part.CFrame = slice.coordinate;
		
		set_destructed(part, nil);

		if Settings.TagToHavoc then
			part:RemoveTag(Settings.TagToHavoc);
		end

		return part;
	end;

	function release_part(part: BasePart): ()
		Destruction.associations[part] = nil;
		part:Destroy();
	end;
end;

-------------------------------------------------------------------------------------------

Destruction.get_part_destructed = is_destructed;
Destruction.set_part_destructed = is_destructed;

@native function Destruction.create_slices(part_map: SlicePartMap, create_part_callback: (sliced_part: BasePart, info: SliceInfo) -> (BasePart)): {BasePart}
	debug.profilebegin("Create Slices");

	local parts_made: {BasePart} = {};

	for part, cube_list in part_map do
		local associated = Destruction.associations[part]; -- Only rubble will appear in here
		local top_part = associated or part;

		local part_index_start = #parts_made + 1;
		local part_index_end = part_index_start - 1;

		for index, info in cube_list do
			local cube = create_part_callback(part, info);

			if cube then
				if part_map[cube] then
					-- If this somehow happens message me
					warn("Bad Release: Part returned exists within the SlicePartMap. Disable PartCache for quick fix.")
				end

				part_index_end += 1;
				parts_made[part_index_end] = cube;

				Destruction.associations[cube] = top_part;
			end;
		end;
	end;

	debug.profileend();

	return parts_made;
end

function Destruction.rollback_properties(part: BasePart, property_map: {any}): ()
	for index, value in property_map do
		part[PartDestructionIndexer[index]] = value;
	end;
end;

function Destruction.complete_overlap(overlap: OverlapParams): OverlapParams
	local new_filter = table.clone(HavocTagList);
	local descendants = overlap.FilterDescendantsInstances;

	-- Merges the 'descendants' table into the 'tagged' table
	table.move(descendants, 1, #descendants, #new_filter + 1, new_filter);
	
	local new_params = OverlapParams.new();
	new_params.FilterDescendantsInstances = new_filter;
	new_params.FilterType = Enum.RaycastFilterType.Include;
	new_params.CollisionGroup = overlap.CollisionGroup;
	new_params.MaxParts = overlap.MaxParts;
	new_params.Tolerance = overlap.Tolerance;
	new_params.RespectCanCollide = overlap.RespectCanCollide;
	new_params.BruteForceAllSlow = overlap.BruteForceAllSlow;
	
	return new_params;
end;

do
	local QueryCylinderOffset = CFrame.Angles(0, 0, math.rad(90));
	local QueryCylinder = Instance.new("Part");
	QueryCylinder.Shape = Enum.PartType.Cylinder;
	QueryCylinder.CanQuery = false;
	QueryCylinder.Anchored = true;
	QueryCylinder.CanCollide = false;
	QueryCylinder.Transparency = 1;
	
	function Destruction.spatial_query(parameters: HavocParameters): ({BasePart}, OverlapParams)
		local parts: {BasePart};
		local overlap = parameters.overlap or Settings.DefaultBreakOverlap;

		if parameters.auto_overlap and Settings.TagToHavoc then
			if overlap.FilterType ~= Enum.RaycastFilterType.Include then
				warn(`The provided OverlapParams.FilterType is not set to Include, Instances with tag '{Settings.TagToHavoc}' will not be considered.`)
			else
				overlap = Destruction.complete_overlap(overlap);
			end;
		end;

		if parameters.shape == "Sphere" then
			parts = workspace:GetPartBoundsInRadius(parameters.origin.Position, parameters.radius, overlap);

		elseif parameters.shape == "Box" then
			parts = workspace:GetPartBoundsInBox(parameters.origin, parameters.size, overlap);

		elseif parameters.shape == "Cylinder" then
			local size = parameters.size :: Vector3;

			if not parameters.radius then
				parameters.radius = math.min(size.Y, size.Z) * 0.5;
			end

			local radius = (parameters.radius :: number) * 2;

			QueryCylinder.CFrame = parameters.origin * QueryCylinderOffset;
			QueryCylinder.Size = Vector3.new(size.X, radius, radius);

			parts = workspace:GetPartsInPart(QueryCylinder, overlap);
		end;
		
		return parts, overlap;
	end
end

do
	local QueryCylinderOffset = CFrame.Angles(0, 0, math.rad(90));
	local QueryCylinder = Instance.new("Part");
	QueryCylinder.Shape = Enum.PartType.Cylinder;
	QueryCylinder.CanQuery = false;
	QueryCylinder.Anchored = true;
	QueryCylinder.CanCollide = false;
	QueryCylinder.Transparency = 1;

	function Destruction.havoc(parameters: HavocParameters): (SlicePartMap, SlicePartMap, PartMap)
		assert(parameters, "No parameters were passed");
		
		debug.profilebegin("Havoc");
		debug.profilebegin("Bounding");
		
		for key, value in Settings.DefaultParameters do
			if (parameters[key] == nil) then
				parameters[key] = value;
			end;
		end;
		
		local parts, overlap = Destruction.spatial_query(parameters);
		local slice_method = slice_method_for_shape[parameters.shape];

		assert(slice_method, "Shape is invalid");

		local divided_cubes: SlicePartMap = {};
		local intersecting_cubes: SlicePartMap = {};
		local reset_destruction_parts: PartMap = {};

		debug.profileend();
		debug.profilebegin("Slicing");

		for index, part in parts do
			local top_part = Destruction.associations[part] or part;
			local top_destruct = Destruction.destructs[top_part];

			if top_destruct then
				reset_destruction_parts[top_part] = top_destruct;
			end;

			if not ( part.ClassName == "Part" and part.Shape == Enum.PartType.Block and not is_destructed(part) ) then
				continue;
			end;

			local divided = {};
			local intersecting = {};
			
			if part.Transparency ~= 1 then
				local slice = {coordinate = part.CFrame, size = part.Size};

				slice_method(slice, divided, intersecting, parameters);
				
				if parameters.greedy_meshing then
					local batch_size = parameters.greedy_batch_size;

					-- Do greedy meshing all in one batch if performance allows it.
					if (#divided < parameters.greedy_opportunistic_batch_size) then
						batch_size = math.huge;
					end;

					divided = Mesh.greedy_mesh_slices(divided, batch_size, 1);
				end;
			end;
			
			divided_cubes[part] = divided;
			
			-- Don't greedy mesh the intersecting, we always want the same size cubes.
			intersecting_cubes[part] = intersecting;
		end;

		debug.profileend();
		debug.profileend();
		
		return divided_cubes, intersecting_cubes, reset_destruction_parts
	end
end;

function Destruction.release_part(part: BasePart?): ()
	if not part then return end;

	if not Destruction.associations[part] then
		release_part(part);
	else
		part:Destroy();
		warn("Part was destroyed because it could not be released as it is currently being used");
	end
end

local DummyTable: any = {};

function Destruction.get_part(base: BasePart?, slice: SliceInfo?): BasePart
	return get_part(base or CachePart, slice or DummyTable);
end

function Destruction.restore_destructed(part: BasePart): ()
	local destruct_info = Destruction.destructs[part];

	if destruct_info and destruct_info.source then
		destruct_info.source:restore_destruct(destruct_info);
	end
end

function Destruction.create(parameters: HavocParameters?): Destruction
	local self = setmetatable(
		{

		}, 
		Destruction);

	if not parameters then
		parameters = Settings.DefaultParameters;
	end;

	assert(parameters, "No paramers exist");

	for key, value in Settings.DefaultParameters do
		self[key] = if parameters[key] ~= nil then parameters[key] else value;
	end;

	return self;
end

function Destruction.get_parameters(self: Destruction): HavocParameters
	local parameters = table.clone(Settings.DefaultParameters);

	for key, value in Settings.DefaultParameters do
		parameters[key] = self[key];
	end;

	return parameters;
end

function Destruction.query(self: Destruction): (SlicePartMap, SlicePartMap, PartMap)
	local divided, intersecting, timers = Destruction.havoc(self);

	self._divided = divided;
	self._intersecting = intersecting;
	self._timers = timers;

	return divided, intersecting, timers;
end

function Destruction.destruct_using_query(self: Destruction, parameters: Types.DestructParameters): ({BasePart}, {BasePart}, {BasePart})
	assert(self._divided, "No query was made");
	
	if not parameters then
		parameters = {} :: any;
	end;
	
	if not parameters.crater then
		parameters.crater = {};
	end

	local crater_parts, debris_parts;

	if parameters.crater then
		crater_parts = self:create_crater(parameters.crater);
	end;

	if parameters.debris then
		self:push_debris(parameters.debris);
		
		debris_parts = self:create_debris(parameters.debris);
	end;

	local destructed = self:create_destruction(parameters);

	return destructed, crater_parts or {}, debris_parts or {};
end

function Destruction.destruct(self: Destruction, parameters: Types.DestructParameters): ({BasePart}, {BasePart}, {BasePart})
	self:query();
	return self:destruct_using_query(parameters);
end

function Destruction.get_query_destructed(self: Destruction): {BasePart}
	local parts = {};

	for part in self._timers do
		table.insert(parts, part);
	end;

	for part in self._divided do
		if not Destruction.associations[part] then
			table.insert(parts, part);
		end;
	end;

	return parts;
end

function Destruction.restore_destruct(self: Destruction, destruct: DestructInfo): ()
	local part = destruct.part;
	assert(part, "Destruct has no part?");

	for index, value in destruct.properties do
		if typeof(index) == "Instance" then
			index.Transparency = value;
		else
			part[PartDestructionIndexer[index]] = value;
		end;
	end;
	
	table.clear(destruct.properties);
	
	set_destructed(part, nil);
	Destruction.destructs[part] = nil;

	self:stop_destructed_timer(destruct)

	for sibling, top_part in Destruction.associations do
		-- Parts may be no longer associated with the restored part.
		if top_part ~= part then 
			continue;
		end;
		
		release_part(sibling);
	end;

	Destruction.on_restore:Fire(part);
end

function Destruction.stop_destructed_timer(self: Destruction, destruct: DestructInfo): ()
	if destruct.unit then
		local unit = Destruction.timer_units[destruct.unit];

		if unit then
			if unit.thread and coroutine.status(unit.thread) == "suspended" then
				task.cancel(unit.thread);
			end;

			unit.thread = nil;
		end;
	else
		if destruct.thread and coroutine.status(destruct.thread) == "suspended" then
			task.cancel(destruct.thread);
		end;

		destruct.thread = nil;
	end
end

function Destruction.start_destructed_timer(self: Destruction, destruct: DestructInfo): ()
	if self.permanent then 
		return;
	end;

	self:stop_destructed_timer(destruct);

	if destruct.unit then
		local unit = Destruction.timer_units[destruct.unit];

		if not unit then
			unit = { parts = {}, thread = nil };
			Destruction.timer_units[destruct.unit] = unit;
		end;

		unit.parts[destruct.part] = true;

		unit.thread = task.delay(Settings.TimeToReset, function()
			Destruction.timer_units[destruct.unit] = nil;

			for part in unit.parts do
				Destruction.restore_destructed(part);
			end;
		end)
	else
		destruct.thread = task.delay(Settings.TimeToReset, Destruction.restore_destruct, self, destruct);
	end;
end;

function Destruction.get_ancestor_unit(instance: Instance): Instance?
	if Settings.WholeUnitType == "Parent" then
		return instance.Parent;

	elseif Settings.WholeUnitType == "AncestorModel" then
		return instance:FindFirstAncestorWhichIsA("Model");

	elseif Settings.WholeUnitType == "AncestorTagged" then
		local instance: Instance? = instance.Parent;

		while instance and not instance:HasTag("AncestorUnit") do
			instance = instance.Parent;
		end

		return instance;
	end;

	return nil;
end;

local function set_properties_defer(part, destruct_info)
	-- If the part is restored within the same frame, dont set the properties.
	if Destruction.destructs[part] ~= destruct_info then
		return;
	end;

	for property, value in Settings.SetPropertiesOfDestructedPart.Deferred do
		part[property] = value;
	end;
end;

function Destruction.set_destructed(self: Destruction, part: BasePart): ()
	if Destruction.destructs[part] then
		return;
	end;

	local destruct_info: DestructInfo = {
		thread = nil, 
		properties = {},
		part = part,
		source = self,
		unit = if Settings.DestructAsWholeUnit then Destruction.get_ancestor_unit(part) else nil;
	};

	self:start_destructed_timer(destruct_info);
	Destruction.destructs[part] = destruct_info;

	for index, property in PartDestructionIndexer do
		destruct_info.properties[index] = part[property] :: any;
	end;
	
	for _, decal in part:GetChildren() do
		if decal:IsA("Decal") then
			destruct_info.properties[decal] = decal.Transparency;
			decal.Transparency = 1;
		end;
	end;
	
	set_destructed(part, true);

	-- Stuff like CanQuery needs to be here
	for property, value in Settings.SetPropertiesOfDestructedPart.Immediate do
		part[property] = value;
	end;

	if #Settings.SetPropertiesOfDestructedPart.Deferred ~= 0 then
		task.defer(set_properties_defer, part, destruct_info);
	end;

	Destruction.on_destruct:Fire(part);
end;

function Destruction.create_hole(self: Destruction): ()
	for part, cube_list in self._divided do
		-- Only deletes parts classified as rubble, parts not made by destruction are made invisible elseplace.
		if Destruction.associations[part] then
			release_part(part);
		end
	end;
end

function Destruction.create_destruction(self: Destruction, parameters: Types.DestructParameters): {BasePart}
	debug.profilebegin("Set Destructed")

	local destructed: {BasePart} = {};

	for part, cube_list in self._divided do
		local associated = Destruction.associations[part];

		-- Ignores rubble
		if not associated and not Destruction.destructs[part] then
			self:set_destructed(part);
			table.insert(destructed, part);
		end;
	end;
	
	if not parameters.indefinite then
		-- Resets the destruction timer on the original destructed part from the re-destructed parts
		for part, destruct in self._timers do
			self:start_destructed_timer(destruct);
		end;
	end;
	
	if parameters.indefinite then
		for _, part in destructed do
			self:stop_destructed_timer( Destruction.destructs[part] );
		end;
	end;
	
	self:create_hole();

	-- Allows using destruction multiple times in the same frame with PartCache enabled.
	-- Prevents the 'Bad Release' warning
	if Settings.UsePartCache then
		PartCache.update_cframes();
	end;

	debug.profileend();

	return destructed;
end

function Destruction.get_material_volumes(self: Destruction): {{part: BasePart, material: Enum.Material, origin: CFrame, size: Vector3}}
	assert(self._divided, "No query was made, could not get material volumes.");
	debug.profilebegin("Get Material Volumes");
	
	local materials = {};

	for base_part, slices in self._intersecting do
		if not materials[base_part.Material] then
			materials[base_part.Material] = {part = base_part, volume = {slices}};
		else
			table.insert(materials[base_part.Material].volume, slices);
		end
	end;
	
	local volumes = {};
	
	for material, base in materials do
		local origin, size = Spatial.get_bounding_box(base.volume, CFrame.identity);
		
		table.insert(volumes, {
			part = base.part,
			material = material,
			origin = origin,
			size = size,
		});
	end;
	
	return volumes;
end;

function Destruction.get_part_material_volumes(self: Destruction, parts: {BasePart}): {{material: Enum.Material, origin: CFrame, size: Vector3}}
	local materials = {};

	for _, part in parts do
		if not materials[part.Material] then
			materials[part.Material] = {_parts = {part}, material = part.Material, origin = CFrame.identity, size = Vector3.zero};
		else
			table.insert(materials[part.Material]._parts, part);
		end;
	end;

	local volumes = {};

	for material, base in materials do
		local origin, size = Spatial.get_parts_bounding_box(base._parts, CFrame.identity);
		
		table.insert(volumes, {
			part = base._parts[math.random(#base._parts)];
			material = material,
			origin = origin,
			size = size,
		});
	end;

	return volumes;
end;

function Destruction.is_destructable(instance: Instance): boolean
	assert(instance, "No Instance");
	
	if instance.Parent == HavocStatic or instance:IsDescendantOf(AlternativeHavocs) then
		return true;
	end;
	
	local current_instance = instance;
	
	while current_instance and current_instance.Parent ~= workspace do
		if current_instance:HasTag(Settings.TagToHavoc) then
			return true;
		end;
		
		current_instance = current_instance.Parent;
	end;
	
	return false;
end;

-------------------------------------------------------------------------

local FloatingOverlap = OverlapParams.new();
FloatingOverlap.FilterDescendantsInstances = { MapModel, HavocStatic, workspace.Builds };
FloatingOverlap.FilterType = Enum.RaycastFilterType.Include;
FloatingOverlap.RespectCanCollide = true;

local DisturbOverlap = OverlapParams.new();
DisturbOverlap.FilterDescendantsInstances = { AlternativeHavocs, HavocStatic, workspace.Builds };
DisturbOverlap.FilterType = Enum.RaycastFilterType.Include;
DisturbOverlap.RespectCanCollide = true;

function Destruction.collapse_whole_structure(self: Destruction, weld_assembly: {BasePart}, part_list: {BasePart}?): {BasePart}
	debug.profilebegin("Collapsing Islands");

	-- Non local chunk (Undisturbed part) was collapsed, must pre-pass otherwise you'll weld to stale references
	for index, part in ipairs(weld_assembly) do
		if part.Parent ~= HavocStatic and not Destruction.associations[part] then
			local new_part = Instance.fromExisting(part);
			new_part:RemoveTag(Settings.TagToHavoc);
			new_part.Parent = HavocStatic;

			Destruction.associations[new_part] = part;
			Destruction.set_destructed(self, part);

			weld_assembly[index] = new_part;
			
			if part_list then
				table.insert(part_list, part);
			end;
		end;
	end;
	
	for index, part in weld_assembly do
		for _, joint in part:GetChildren() do
			if joint:IsA("WeldConstraint") then
				joint:Destroy();
			end;
		end;

		for next_index = index + 1, #weld_assembly do
			local next_part = weld_assembly[next_index];

			local weld = Instance.new("WeldConstraint");
			weld.Part0 = part;
			weld.Part1 = next_part;
			weld.Parent = part;
		end;

		part.Anchored = false;

		if part:CanSetNetworkOwnership() then
			part:SetNetworkOwner(nil);
		end;
	end;

	debug.profileend();
	
	if RunService:IsStudio() then
		ReplicatedStorage.Havoc.Remotes.Replicated.CollapseStructure:FireAllClients(weld_assembly[1]);
	end
	
	return weld_assembly;
end

-- Very cool feature, but is very resource intensive, so use sparingly!
function Destruction.seperate_floating_islands(self: Destruction, part_list: {BasePart}, visited: {BasePart}, cascaded: boolean?)
	local tolerence = 0.1;
	local disturb_distance = 10;

	if not visited then
		visited = {};
	end;

	local to_visit: {BasePart} = table.clone(part_list);
	local weld_assembly: {BasePart} = table.create(#part_list);
	local assembly_anchored = false;

	local floating_overlap = Destruction.complete_overlap(FloatingOverlap);

	debug.profilebegin("Flooding Parts");

	while #to_visit > 0 do
		local part = table.remove(to_visit);
		local size = part.Size;
		
		visited[part] = true;

		-- Only insert parts that are not sitting in cache
		if part.Anchored and not Parts.parts[part] then
			table.insert(weld_assembly, part);
		end;

		local touching = workspace:GetPartBoundsInBox(part.CFrame, part.Size + Vector3.one * tolerence, floating_overlap);

		for _, touched_part in touching do
			local size = touched_part.Size;
		
			if visited[touched_part] or not touched_part.Anchored then
				continue;
			end;

			local breakable = Destruction.is_destructable(touched_part);

			if not breakable then
				assembly_anchored = true;
				
				-- If its detected to not be islanded we no longer need to flood anymore
				for _, part in to_visit do visited[part] = true end;
				for _, part in touching do visited[part] = true end;
				
				table.clear(to_visit)
				break;
			end
			
			if not is_destructed(touched_part) and breakable then
				visited[touched_part] = true;
				table.insert(to_visit, touched_part);
			end;
		end;
	end;

	debug.profileend();
	
	if not assembly_anchored and #weld_assembly ~= 0 then
		
		self:collapse_whole_structure(weld_assembly, part_list);
		
	elseif not cascaded then
		-- This mostly fixes the skipped islands issue, but uses even more resources.
		task.wait(1 / 60);

		local origin = self.origin;
		local size = Vector3.one;

		local disturb_overlap = Destruction.complete_overlap(DisturbOverlap);
		local touching = workspace:GetPartBoundsInBox(origin, size + Vector3.one * disturb_distance, disturb_overlap);

		for _, touched_part in touching do
			if visited[touched_part] or not Destruction.is_destructable(touched_part) then
				continue;
			end;

			visited[touched_part] = true;
			Destruction.seperate_floating_islands(self, { touched_part }, { [touched_part] = true }, true);
		end;
	end;
end;

--function Destruction.seperate_floating_islands(self: Destruction, part_list: {BasePart}, visited: {BasePart}, cascaded: boolean?)
--	local tolerence = 0.1;
--	local disturb_distance = 10;
	
--	if not visited then
--		visited = {};
--	end;
	
--	local to_visit: {BasePart} = table.clone(part_list);
--	local weld_assembly: {BasePart} = table.create(#part_list);
--	local assembly_anchored = false;
	
--	local floating_overlap = Destruction.complete_overlap(FloatingOverlap);
	
--	debug.profilebegin("Flooding Parts");
	
--	local visit_count = 0;
	
--	while #to_visit > 0 do --and visit_count < 256 do
--		local part = table.remove(to_visit);
--		local size = part.Size;
		
--		visit_count += 1;
--		visited[part] = true;
		
--		if part.Anchored and ( part.Parent ~= HavocStatic or not Parts.parts[part] ) then
--			table.insert(weld_assembly, part);
--		end;
		
--		local touching = workspace:GetPartBoundsInBox(part.CFrame, part.Size + Vector3.one * tolerence, floating_overlap);
		
--		for _, touched_part in touching do
--			local size = touched_part.Size;
			
--			if visited[touched_part] or not touched_part.Anchored then
--				continue;
--			end;
			
--			local in_statics = touched_part.Parent == HavocStatic;
--			local in_breakables = touched_part:IsDescendantOf(AlternatveHavocs) or touched_part:IsDescendantOf(workspace.Builds);
			
--			if not ( in_statics or in_breakables ) then
--				assembly_anchored = true;
--			end;
			
--			if not is_destructed(touched_part) and ( in_statics or in_breakables ) then
--				visited[touched_part] = true;
--				table.insert(to_visit, touched_part);
--			end;
--		end;
--	end;
	
--	debug.profileend();
--	debug.profilebegin("Seperating Islands");
	
--	if not assembly_anchored and #weld_assembly ~= 0 then
--		warn("floating island detect")
--		-- Non local chunk (Undisturbed part) was collapsed, must pre-pass otherwise you'll weld to stale references
--		for index, part in ipairs(weld_assembly) do
--			if part.Parent ~= HavocStatic and not Destruction.associations[part] then
--				local new_part = Instance.fromExisting(part);
--				new_part:RemoveTag(Settings.TagToHavoc);
--				new_part.Parent = HavocStatic;
				
--				Destruction.associations[new_part] = part;
--				Destruction.set_destructed(self, part);
				
--				weld_assembly[index] = new_part;
--				table.insert(part_list, part);
--			end;
--		end;
		
--		for index, part in weld_assembly do
--			for _, joint in part:GetChildren() do
--				if joint:IsA("WeldConstraint") then
--					joint:Destroy();
--				end;
--			end;

--			for next_index = index + 1, #weld_assembly do
--				local next_part = weld_assembly[next_index];
				
--				local weld = Instance.new("WeldConstraint");
--				weld.Part0 = part;
--				weld.Part1 = next_part;
--				weld.Parent = part;
--			end;
			
--			part.Anchored = false;
			
--			if part:CanSetNetworkOwnership() then
--				part:SetNetworkOwner(nil);
--			end;
--		end;
--	end;
	
--	debug.profileend();
	
--	-- This mostly fixes the skipped islands issue, but is also resource intensive.
--	if not cascaded then
--		task.wait();
		
--		local origin = self.origin;
--		local size = Vector3.one;
		
--		local disturb_overlap = Destruction.complete_overlap(DisturbOverlap);
--		local touching = workspace:GetPartBoundsInBox(origin, size + Vector3.one * disturb_distance, disturb_overlap);

--		for _, touched_part in touching do
--			if visited[touched_part] then
--				continue;
--			end;
			
--			visited[touched_part] = true;
--			Destruction.seperate_floating_islands(self, { touched_part }, visited, true);
--		end;
--	end;
--end;

local function apply_debris_velocity(parts, info): ()
	local velocity_duration = info.velocity_duration or 0.1;
	local velocity_power = info.velocity_power or 20;
	
	for _, part in parts do
		DebrisPool.set_sleep(part, false);
		
		local velocity = Vector3.zero;
		local angular_velocity = Vector3.zero;

		if typeof(info.velocity) == "function" then
			velocity, angular_velocity = info.velocity(part);
		else
			velocity, angular_velocity = info.velocity, info.angular_velocity;
		end;
		
		if not angular_velocity then
			angular_velocity = Rnd:NextUnitVector() * velocity_power * 0.5
		end;
		
		if not velocity then
			velocity = Rnd:NextUnitVector() * velocity_power;
		end

		part.AssemblyLinearVelocity = velocity;
		part.AssemblyAngularVelocity = angular_velocity;
		
		if velocity_duration > 0 then
			local body_velocity = Instance.new("BodyVelocity");
			body_velocity.P = 3_000;
			body_velocity.MaxForce = Vector3.one * 8_000;
			body_velocity.Velocity = velocity;
			body_velocity.Parent = part;

			task.delay(velocity_duration, body_velocity.Destroy, body_velocity)
		end;
	end;
end;

function Destruction.push_debris(self: Destruction, info: MakeDebrisInfo?): ()
	local parameters = self:get_parameters();
	parameters.overlap = Settings.DefaultDebrisOverlap;
	parameters.auto_overlap = false;
	
	for key, value in info do
		if parameters[key] ~= nil then
			parameters[key] = value;
		end;
	end;
	
	local parts, overlap = Destruction.spatial_query(parameters);
	
	if info then
		apply_debris_velocity(parts, info);
	end;
	
	self._pushed_debris = parts;
end;

function Destruction.create_crater(self: Destruction, info: MakeCraterInfo?): {BasePart}
	debug.profilebegin("Create Crater");
	assert(self._divided, "No query was made");

	if not info then info = {}; end;
	assert(info);
	
	local parts = Destruction.create_slices(self._divided, function(base: BasePart, slice: SliceInfo)
		local cube = get_part(base, slice);
		cube.TopSurface = base.TopSurface;
		cube.BottomSurface = base.BottomSurface;
		cube.Material = base.Material;
		cube.MaterialVariant = base.MaterialVariant;
		cube.Transparency = base.Transparency;
		cube.Color = base.Color;
		cube.CollisionGroup = base.CollisionGroup;
		cube.Anchored = base.Anchored; -- was true, now same as base for physical seperation feature
		cube.Shape = Enum.PartType.Block;
		cube.CanQuery = true;
		cube.CanCollide = true;
		cube.AssemblyLinearVelocity = Vector3.zero;
		cube.AssemblyAngularVelocity = Vector3.zero;
		cube.Size = slice.size;
		
		return cube;
	end)
	
	if self.seperate_islands then
		task.defer(Destruction.seperate_floating_islands, self, parts);
	end;
	
	if info.parent then
		for _, part in parts do
			if part.Parent == info.parent then
				continue;
			end;
			
			part.Parent = info.parent;
		end;
	end;
	
	debug.profileend();

	return parts;
end;

function Destruction.create_debris(self: Destruction, info: MakeDebrisInfo?): {BasePart}
	debug.profilebegin("Create Debris");
	assert(self._intersecting, "No query was made");

	if not info then info = {}; end;
	assert(info);

	local scale = info.scale or 1;

	local physical_properties = PhysicalProperties.new(Enum.Material.Plastic);
	
	local parts = Destruction.create_slices(self._intersecting, function(base: BasePart, slice: SliceInfo)
		local cube = get_part(base, slice);
		cube.TopSurface = base.TopSurface;
		cube.BottomSurface = base.BottomSurface;
		cube.Material = base.Material;
		cube.MaterialVariant = base.MaterialVariant;
		cube.CustomPhysicalProperties = physical_properties;
		cube.Shape = Enum.PartType.Block;
		cube.Size = slice.size * scale;
		cube.Anchored = false;
		cube.Massless = true;
		cube.CanQuery = false;
		cube.CanCollide = true;
		cube.Transparency = base.Transparency;
		cube.AssemblyAngularVelocity = Vector3.zero;
		cube.Color = base.Color;
		
		local modifier = Instance.new("PathfindingModifier", cube);
		modifier.PassThrough = true;
		
		if base:GetAttribute("NoCollideDebris") then
			cube.CollisionGroup = "NoPlayerCollision";
			cube:SetAttribute("NoCollideDebris", nil);
		else
			cube.CollisionGroup = "HavocDebree";
		end
		
		if info.create_part_callback then
			info.create_part_callback(cube, base, slice)
		end;
		
		return cube;
	end);
	
	apply_debris_velocity(parts, info);
	
	if info.parent then
		for _, part in parts do
			if part.Parent == info.parent then
				continue;
			end;
			
			part.Parent = info.parent;
		end;
	end;

	debug.profileend();

	return parts;
end;

-------------------------------------------------------------------------------------------

return Destruction;