local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Repeats input active signals or pulses.";
TagModifier.icon = 7037175219;
TagModifier.color = Color3.fromRGB(255, 188, 71)
TagModifier.section = 1;
TagModifier.use_prompt = false;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	Neutral = {
		Default = false;
	};
	ConvertToPulse = {
		Default = false;
	};
	Output = {
		Default = nil;
		Type = Type.Instance();
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.pulse_on_powered = false;
	
	if self.attributes:get("CarryPulse") ~= nil then
		self.attributes:rename("CarryPulse", "Pulsate");
	end;
	
	--if self.attributes:get("ConvertToPulse") ~= nil then
	--	self.attributes:rename("ConvertToPulse", "Pulsate");
	--end;
	
	return self;
end

function TagModifier.attribute_updates:ConvertToPulse(value, was_init)
	self.pulse_on_powered = value;
	self.carry_pulse = value;
end;

function TagModifier.attribute_updates:Neutral(value, was_init)
	self.neutral_signal = value;
end;

function TagModifier:set_powering(value: boolean)
	if not self.carry_pulse then
		return InstanceModifier.set_powering(self, value);
	end;
end;

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;