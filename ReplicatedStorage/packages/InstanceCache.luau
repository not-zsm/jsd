--!strict

local Debris = game:GetService("Debris")

-----------------------------------------------------------------------

type PositionModifier = (any, Vector3) -> ();

export type ClassInstanceCache<P> = {
	__index: ClassInstanceCache<P>;

	new: (warm_startup_count: number?, constructor: (() -> (P)) | string | Instance) -> InstanceCache<P>;
	add: (self: InstanceCache<P>, amount: number?) -> ();
	get: (self: InstanceCache<P>) -> P;
	release: (self: InstanceCache<P>, instance: P, no_reparent: boolean?) -> ();
	destroy: (self: InstanceCache<P>) -> ();
};

export type InstanceCache<P> = typeof(setmetatable({} :: {
	constructor: () -> P;
	cache: {[P]: boolean};
	reset_position: PositionModifier?;
	
	cleanup_release: (P) -> ();
	cleanup_get: (P) -> ();
	
	limit: boolean?;
	
}, {} :: ClassInstanceCache<P>));

-----------------------------------------------------------------------

local OUTSIDE_RENDER_DISTANCE = Vector3.new(0, 1e7, 0);
local DUMMY_FUNCTION = function() end;

-----------------------------------------------------------------------

local function assert_warn<T>(value: T, error_message: string?): T
	if not value then
		warn(error_message);
	end
	
	return value;
end;

local function get_position_modifier(base: Instance): PositionModifier?
	if base:IsA("BasePart") then
		return function(instance: BasePart, position: Vector3)
			instance.CFrame = CFrame.new(position);
		end;
		
	elseif base:IsA("Attachment") then
		return function(instance: Attachment, position: Vector3)
			instance.WorldCFrame = CFrame.new(position);
		end;
	end
	
	return nil;
end

-----------------------------------------------------------------------

local InstanceCache = {} :: ClassInstanceCache<Instance>
InstanceCache.__index = InstanceCache;

function InstanceCache.new(warm_startup_count, constructor)
	assert(constructor, "No constructor function or instance classname was provided");
	
	if typeof(constructor) == "string" then
		local str = constructor;

		constructor = function()
			return Instance.new(str)
		end
		
	elseif typeof(constructor) == "Instance" then
		local clones = constructor;
		
		constructor = function()
			return clones:Clone();
		end
	end
	
	assert(typeof(constructor) == "function");
	
	local base = constructor();
	
	assert(typeof(base) == "Instance", "Constructor does not return an Instance");
	
	local self = setmetatable({}, InstanceCache);
	
	self.constructor = constructor;
	self.cleanup_release = DUMMY_FUNCTION;
	self.cleanup_get = DUMMY_FUNCTION;
	self.cache = {};
	self.reset_position = get_position_modifier(base);
	
	self:add(warm_startup_count)
	
	base:Destroy();
	
	return self;
end;

function InstanceCache:add(amount)
	for count = 1, amount or 0 do
		self.cache[self.constructor()] = true;
	end
end

function InstanceCache:get()
	local instance = next(self.cache);
	
	if not instance and not self.limit then
		return self.constructor();
		
	elseif instance then
		task.defer(self.cleanup_get, instance);
		
		self.cache[instance] = nil;
		return instance;
	end
	
	return nil :: any;
end

function InstanceCache:release(instance, no_reparent)
	assert(typeof(instance) == "Instance", "Argument is not an instance");
	
	self.cleanup_release(instance);
	self.cache[instance] = true;
	
	if self.reset_position then
		task.defer(self.reset_position, instance, OUTSIDE_RENDER_DISTANCE);
		
	elseif not no_reparent then
		instance.Parent = nil;
	end;
end

function InstanceCache:destroy()
	for instance in pairs(self.cache) do
		instance:Destroy()
	end
	
	table.clear(self.cache);
	table.clear(self :: any);
	setmetatable(self :: any, nil);
end

table.freeze(InstanceCache);

return InstanceCache;