--!nocheck

local replicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require( replicatedStorage.Packages.Signal )

export type SliceInfo = {coordinate: CFrame, size: Vector3};

export type SlicePartMap = {[BasePart]: {SliceInfo}};

export type PartMap = {[BasePart]: boolean};

export type HavocParameters = {
	origin: CFrame;
	radius: number;
	size: Vector3;
	block_size: number;
	shape: "Sphere" | "Box";
	overlap: OverlapParams;
	greedy_meshing: boolean;
	greedy_batch_size: number;
	greedy_opportunistic_batch_size: number;
};

export type DestructInfo = {
	thread: thread?,
	properties: {[number]: any},
	part: BasePart,
	source: any,
	unit: Instance?
};

export type DestructUnitInfo = {
	parts: {[BasePart]: boolean}, 
	thread: thread?
};

export type MakeCraterInfo = {
	parent: Instance?,
};

export type MakeDebrisInfo = {
	scale: number?,
	velocity: Vector3?,
	velocity_duration: number?,
	velocity_power: number?,
	parent: Instance?,
	create_part_callback: ((part: BasePart, base: BasePart, slice: SliceInfo) -> ())?
};

export type DestructParameters = {
	indefinite: boolean?;
	crater: MakeCraterInfo?,
	debris: MakeDebrisInfo?,
};

export type ClassDestruction = {
	__index: ClassDestruction;

	destructs: {[BasePart]: DestructInfo};
	associations: {[BasePart]: BasePart};
	timer_units: {[Instance]: DestructUnitInfo};
	folder: Instance;
	settings: typeof(require("./Settings")),
	on_restore: Signal.Signal<BasePart>;
	on_destruct: Signal.Signal<BasePart>;
	
	--[[
		Copies the aesthetic properties from <strong>base</strong> and sets them on <strong>onto</strong>,
		Not recommend unless you need to destruct a large variety of parts with super different properties, it is better to cherry-pick the properties that are important (Material, Color, Transparency, Etc)
		(This increases overhead enough that cloning will actually be faster than using ObjectCache)
	]]
	copy_properties: typeof(function(base: Part, onto: Part): () end);
	
	--[[
		A method to that will automatically iterate over your <strong>SlicePartMap</strong> to create parts.
	]]
	create_slices: typeof(function(part_map: SlicePartMap, create_part_callback: (sliced_part: BasePart, info: SliceInfo) -> (BasePart)): {BasePart} end);
	
	--[[
		Copies the overlap params and inserts all havoc tagged instances.
	]]
	complete_overlap: typeof(function(overlap: OverlapParams): OverlapParams end);
	
	--[[
		Sets the properties of the given part to the property array.
	]]
	rollback_properties: typeof(function(part: BasePart, property_map: {any}): () end);
	
	--[[
		Getter method which returns the volumes of two <strong>SlicePartMap</strong>.
		This function does <strong>not</strong> destroy or create parts on its own.
		
		@Returns
		   • The <strong>divided</strong> parts not in within the given bounds, this table can be used to create the overall shape of the crater of destruction.
		   • The <strong>intersecting</strong> parts within the given bounds, this table gives all the cubes that fill the crater, and can be non anchored.
		   • The parts that are destructed which are affected (should have their timers reset).
		   
		@Parameters
		   • origin - The CFrame centre of the destruction.
		   • radius - (Spheres only) The radius of the sphere of destruction.
		   • size - (Box only) The size of the block of destruction.
		   • block_size - The size of the voxels created.
		   • shape - The shape of destruction
		   • overlap - (Optional) The overlap pertaining to what can be voxelized
		   • greedy_meshing - (Optional) Whether to use greedy meshing, Not recommended if your destruction is very large (>30 radius)
		   • mesh_threshold - (Optional) The maximum number of slices before greedy meshing is aborted. (Recommend 250)
	]]
	havoc: typeof(function(parameters: HavocParameters): (SlicePartMap, SlicePartMap, PartMap) end);
	
	--[[
		Gives the part back to the cache - ready to use for destruction.
	]]
	release_part: typeof(function(part: BasePart?): () end);
	
	--[[
		Gets a part - ready to use for destruction.
		
		@parameters
			• base - (Optional) The base part that the part bases off, does nothing if PartCache is enabled.
			• slice - (Optional) The SliceInfo, if used, the part will be efficiently bulk cframed to the given slice coordinate the next defer resumption.
	]]
	get_part: typeof(function(base: BasePart?, slice: SliceInfo?): BasePart end);
	
	restore_destructed: (part: BasePart) -> ();
	create: (parameters: HavocParameters?) -> Destruction;
	get_parameters: (self: Destruction) -> HavocParameters;
	query: (self: Destruction) -> (SlicePartMap, SlicePartMap, PartMap);
	
	--[[
		Equivalent to <code>Destruction:destruct()</code> without re-query.
	]]
	destruct_using_query: typeof(function(self: Destruction, parameters: DestructParameters): ({BasePart}, {BasePart}, {BasePart}) end);
	
	--[[
		Destructs using the parameters of the object.
		
		@Returns
			• The parts that were destructed
			• The parts that make up the crater
			• The parts that are debris (If debris_parameters was passed)
		
		This is an all emcompassing function that does the following:
			• Queries using Destruction.havoc
			• Creates the crater using the passed <strong>crater_parameters</strong>
			• (Optionally) Creates the debris using the passed <strong>debris_parameters</strong>
			• Sets the affected parts to be destructed
			• Creates the hole by deleting affected parts of a crater.
	]]
	destruct: typeof(function(self: Destruction, parameters: DestructParameters): ({BasePart}, {BasePart}, {BasePart}) end);
	
	get_query_destructed: (self: Destruction, part: BasePart) -> {BasePart};
	restore_destruct: (self: Destruction, destruct: DestructInfo) -> ();
	stop_destructed_timer: (self: Destruction, destruct: DestructInfo) -> ();
	start_destructed_timer: (self: Destruction, destruct: DestructInfo) -> ();
	
	get_material_volumes: typeof(function(self: Destruction): {{part: BasePart, material: Enum.Material, origin: CFrame, size: Vector3}} end);
	
	get_part_material_volumes: typeof(function(self: Destruction, parts: {BasePart}): {{material: Enum.Material, origin: CFrame, size: Vector3}} end);
	
	seperate_floating_islands: typeof(function(self: Destruction, part_list: {BasePart}, visited: {BasePart}, cascaded: boolean?) end);
	
	--[[
		Gets the first ancestor unit of a given instance.
	]]
	get_ancestor_unit: typeof(function(instance: Instance): Instance? end);
	
	--[[
		Gets whether the given instance can be destructed. This method can return true for non-part instances if the destruct tag (TagToHavoc) is applied on the given instance.
	]]
	is_destructable: typeof(function(instance: Instance?): boolean end);
	
	set_destructed: (self: Destruction, part: BasePart) -> ();
	
	--[[
		Deletes the parts that make the crater. Does not need to be called if <code>'create_destruction'</code> was called.
		This should be called <strong>after</strong> any operations on divided or intersecting are made (create_crater/create_debris),
		otherwise with PartCache enabled will cause problems.
	]]
	create_hole: typeof(function(self: Destruction): () end);
	
	--[[
		Finialises the destruction made of craters and debris.
		Destructs parts that should be destructed and hides them. Resets timers of any affected parts that are already destructed.
	]]
	create_destruction: typeof(function(self: Destruction): {BasePart} end);
	
	--[[
		Creates the shape of the crater from the provided divided <strong>SlicePartMap</strong>
	]]
	create_crater: typeof(function(self: Destruction, info: MakeCraterInfo?): {BasePart} end);
	
	--[[
		Fills in the debris of the crater from the provided intersecting <strong>SlicePartMap</strong>
	]]
	create_debris: typeof(function(self: Destruction, info: MakeDebrisInfo?): {BasePart} end);
};

export type Destruction = typeof(setmetatable({} :: {
	_divided: SlicePartMap,
	_intersecting: SlicePartMap,
	_timers: SlicePartMap,
	permanent: boolean?,

}, {} :: ClassDestruction));

return {};