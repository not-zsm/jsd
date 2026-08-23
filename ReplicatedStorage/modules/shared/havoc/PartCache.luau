--[[
	Simplified PartCache implementation with no parenting
]]

-------------------------------------------------------------------------------------------

-- The amount of parts that are created when there are no more available free parts.
local ALLOCATE_EXPAND_AMOUNT = 40;

-- Recommended to be further than 100,000,000 studs away, otherwise you will lose alot of performance.
-- Something to do with the instance clustering thinking it can still render the parts?
local DISTANT_CFRAME = CFrame.new(0, 1e8, 0);

-------------------------------------------------------------------------------------------

local Existing_Cache = workspace:FindFirstChild("PartCache")
local PartCacheTemp

if Existing_Cache then
	PartCacheTemp = Existing_Cache
else
	PartCacheTemp = Instance.new("Folder");
	PartCacheTemp.Name = "PartCache";
	PartCacheTemp.Parent = workspace;
end

local to_cframe: {[BasePart]: CFrame} = {};
local _cframes: {CFrame} = {};
local _parts: {BasePart} = {};
local bulk_sceduled = false;

@native local function update_bulk_cframe()
	local do_cycle = false;
	
	for part, coordinate in to_cframe do
		do_cycle = true;
		table.insert(_parts, part);
		table.insert(_cframes, coordinate);
	end;
	
	table.clear(to_cframe);
	
	if do_cycle then
		workspace:BulkMoveTo(_parts, _cframes, Enum.BulkMoveMode.FireCFrameChanged);
	end;
	
	table.clear(_parts);
	table.clear(_cframes);
end

local update_bulk_cframe_thread = coroutine.create(function()
	while to_cframe do
		update_bulk_cframe();
		bulk_sceduled = false;
		coroutine.yield();
	end;
end)

-------------------------------------------------------------------------------------------

export type ClassPartCache = {
	__index: ClassPartCache;
	
	folder: typeof(PartCacheTemp);
	
	new: (base: BasePart) -> PartCache;
	is_destroyed: (instance: Instance) -> boolean;
	update_cframes: () -> ();
	cframe_to: (part: BasePart, cframe: CFrame) -> ();
	expand: (self: PartCache, amount: number) -> ();
	get: (self: PartCache, coordinate: CFrame?) -> BasePart;
	give: (self: PartCache, part: BasePart) -> ();
};

export type PartCache = typeof(setmetatable({} :: {
	
	base: BasePart,
	parts: {[BasePart]: boolean},
	free_parts: {BasePart};
	
}, {} :: ClassPartCache));

-------------------------------------------------------------------------------------------

local PartCache = {} :: ClassPartCache;
PartCache.__index = PartCache;

function PartCache.new(base: BasePart): PartCache
	local self = setmetatable(
		{
			base = base;
			parts = {};
			free_parts = {};
		}, 
		PartCache);
	
	return self;
end;

local function parent_to_itself(instance: Instance): ()
	instance.Parent = instance;
end;

function PartCache.is_destroyed(instance: Instance): boolean
	if instance.Parent then
		return false;
	end;
	
	local success, result = pcall(parent_to_itself, instance);
	
	if string.match(result, "locked") ~= nil then
		return true;
	end;
	
	return false;
end

function PartCache.update_cframes()
	update_bulk_cframe();
end

@native function PartCache.cframe_to(part: BasePart, cframe: CFrame): ()
	to_cframe[part] = cframe;
	
	if not bulk_sceduled then
		bulk_sceduled = true;
		task.defer(update_bulk_cframe_thread);
	end;
end

-------------------------------------------------------------------------------------------

@native function PartCache:expand(amount: number): ()
	local parts = table.create(amount);
	
	for index = 1, amount do
		local clone = Instance.fromExisting(self.base);
		clone.Anchored = true;
		clone.Size = Vector3.zero;
		clone.CFrame = DISTANT_CFRAME;
		clone.Parent = PartCacheTemp;
		
		self.parts[clone] = true;
		table.insert(parts, clone);
	end;
	
	table.move(parts, 1, amount, #self.free_parts + 1, self.free_parts);
end

@native function PartCache:get(coordinate: CFrame?): BasePart
	if not self.free_parts[1] then
		self:expand(ALLOCATE_EXPAND_AMOUNT);
	end;
	
	local part = table.remove(self.free_parts);
	assert(part, "No part exists in the free parts.")
	
	self.parts[part] = nil;
	
	if coordinate then
		PartCache.cframe_to(part, coordinate);
	end
	
	return part;
end

@native function PartCache:give(part: BasePart): ()
	if self.parts[part] or PartCache.is_destroyed(part) then
		return;
	end;
	
	self.parts[part] = true;
	table.insert(self.free_parts, part);
	
	part.Anchored = true;
	part.CollisionGroup = "NoCollision";
	--part.Size = Vector3.zero;
	
	PartCache.cframe_to(part, DISTANT_CFRAME);
end

-------------------------------------------------------------------------------------------

table.freeze(PartCache);

return PartCache;