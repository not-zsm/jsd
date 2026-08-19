
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

----------------------------------------------------------------------------------------

local Maid = require( ReplicatedStorage.Packages.Maid )
local Instances = require( ReplicatedStorage.Packages.Instances )
local Debounce = require( ReplicatedStorage.Packages.Debounce )

----------------------------------------------------------------------------------------

export type ClassInstanceToucher = {
	__index: ClassInstanceToucher;

	new: (modifier: any, part: BasePart, callback: (humanoid: Humanoid, touched: boolean) -> ()) -> ();
	initialise: (self: InstanceToucher) -> ();
	start_touch: (self: InstanceToucher, other_part: BasePart) -> ();
	end_touch: (self: InstanceToucher, other_part: BasePart) -> ();
	end_touch_with_humanoid: (self: InstanceToucher, humanoid: Humanoid) -> ();
	change_touch_value: (self: InstanceToucher, humanoid: Humanoid, value: number) -> ();
	revalidate_touches: (self: InstanceToucher) -> ();
	destroy: (self: InstanceToucher) -> ();
};

export type InstanceToucher = typeof(setmetatable({} :: {
	maid: Maid.Maid;
	modifier: any;
	part: BasePart;
	touch_callback: (humanoid: Humanoid, touched: boolean) -> ();
	
	revalidate_touches_by_object: () -> ();
	
	active_touched: {[Humanoid]: {value: number, connection: RBXScriptConnection}};
	parts_touched: {[BasePart]: Humanoid};
	humanoids_to_remove: {[Humanoid]: boolean};
	debounce: Debounce.Debounce;
	
}, {} :: ClassInstanceToucher));

----------------------------------------------------------------------------------------

local InstanceToucher = {} :: ClassInstanceToucher;
InstanceToucher.__index = InstanceToucher;

function InstanceToucher.new(modifier, part: BasePart, callback)
	local maid = Maid.new();

	local self = setmetatable(
		{
			maid = maid;
			modifier = modifier;
			part = part;
			touch_callback = callback;

			active_touched = {};
			parts_touched = {};
			humanoids_to_remove = {};
			debounce = maid:add(Debounce.new());
		},
		InstanceToucher);
	
	function self.revalidate_touches_by_object()
		self:revalidate_touches();
	end
	
	self:initialise();

	return self;
end;

----------------------------------------------------------------------------------------

function InstanceToucher:initialise(): ()

	self.maid:add(self.part.Touched:Connect(function(other_part)
		self:start_touch(other_part);
	end))

	self.maid:add(self.part.TouchEnded:Connect(function(other_part)
		self:end_touch(other_part);
	end))
end;

function InstanceToucher:start_touch(other_part: BasePart): ()
	local humanoid = Instances.get_ancestor_humanoid(other_part);

	if humanoid and not self.debounce:has(humanoid) then
		self.parts_touched[other_part] = humanoid;

		self:revalidate_touches();
		self:change_touch_value(humanoid, 1);
	end;
end;

function InstanceToucher:end_touch(other_part: BasePart): ()
	local humanoid = self.parts_touched[other_part];

	if humanoid then
		self.parts_touched[other_part] = nil;

		self:revalidate_touches();
		self:change_touch_value(humanoid, -1);
	end
end;

function InstanceToucher:end_touch_with_humanoid(humanoid: Humanoid): ()
	local active_touched = self.active_touched[humanoid];

	if active_touched then
		if active_touched.connection.Connected then
			active_touched.connection:Disconnect();
		end;
		
		table.clear(active_touched);
		self.active_touched[humanoid] = nil;
	end;
end

function InstanceToucher:change_touch_value(humanoid: Humanoid, value: number): ()
	if not humanoid.RootPart then
		return warn("No RootPart exists to be touched.");
	end;
	
	local active_touched = self.active_touched[humanoid];
	
	if not active_touched then
		active_touched = {value = 0, connection = humanoid.RootPart.AncestryChanged:Once(self.revalidate_touches_by_object)};
		self.active_touched[humanoid] = active_touched;
	end;
	
	local last_value = active_touched.value;
	local new_value = math.max(0, last_value + value);
	
	if (new_value ~= last_value) then
		active_touched.value = new_value
		
		if (new_value == 0) then
			self.debounce:add(humanoid, self.modifier.attributes:get("Debounce") or 0);
			self.touch_callback(humanoid, false);
			self:end_touch_with_humanoid(humanoid);
			
		elseif (last_value == 0) then
			self.touch_callback(humanoid, true);
		end;
	end;
end;

-- Ends touches from humanoids that are no longer valid.
function InstanceToucher:revalidate_touches(): ()
	table.clear(self.humanoids_to_remove);
	
	local parts_to_remove = false;
	
	for humanoid, touch in self.active_touched do
		if humanoid.RootPart and humanoid.RootPart:IsDescendantOf(workspace) then
			continue;
		end;
		
		parts_to_remove = true;
		
		self.humanoids_to_remove[humanoid] = true;
		self:change_touch_value(humanoid, -math.huge);
	end;
	
	if parts_to_remove then
		for part, humanoid in self.parts_touched do
			if self.humanoids_to_remove[humanoid] ~= nil then
				self.parts_touched[part] = nil;
			end;
		end;

		table.clear(self.humanoids_to_remove);
	end;
end;

function InstanceToucher:destroy(): ()
	self.maid:destroy();

	for humanoid, touch in self.active_touched do
		self:change_touch_value(humanoid, -math.huge);
	end;

	table.clear(self.active_touched);
	table.clear(self.parts_touched);
	table.clear(self.humanoids_to_remove);
	table.clear(self);
end;

-----------------------------------------------------------------------

table.freeze(InstanceToucher);

return InstanceToucher;