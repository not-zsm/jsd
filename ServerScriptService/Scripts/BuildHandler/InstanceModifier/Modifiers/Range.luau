local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Unpacker = require( "../../Unpacker" );
local ModifierUtil = require( "../ModifierUtil" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Outputs a signal when players are in-range.";
TagModifier.icon = 14572998285;
TagModifier.color = Color3.fromRGB(255, 124, 242)
TagModifier.section = 8;
TagModifier.use_prompt = false;
TagModifier.signal_generator = true;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	Active = {
		Default = true;
	};
	Range = {
		Default = NumberRange.new(25);
	};
	Output = {
		Default = nil;
		Type = Type.Instance();
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	local range = self.attributes:get("Range");
	
	if typeof( range ) == "number" then
		self.attributes:set("Range", NumberRange.new(range));
	end;
	
	self.short_powered = true;
	
	return self;
end

function TagModifier.attribute_updates:Active(value, was_init)
	if value then
		self.signal_generator = true;
	else
		self.signal_generator = false;
	end
	
	self:set_always_active(value);
end

local function pulse_interval(self)
	local any_active = false;

	self.active_signal:clear();
	
	local position = self:get_position();
	local range = ModifierUtil.normal_range(self.attributes:get("Range"));
	
	for _, humanoid in ModifierUtil.get_player_humanoids(position, range) do
		if humanoid then
			self.active_signal:add_humanoid(humanoid);
			any_active = true;
		end;
	end;
	
	self:set_powering(any_active);
end

function TagModifier:on_active_changed()
	self:set_powering(false);
	
	if not self.active then 
		return;
	end;
	
	self.active_maid:add(task.spawn(function()
		while self.active do
			pcall(pulse_interval, self);
			task.wait(0.1);
		end
	end))
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;