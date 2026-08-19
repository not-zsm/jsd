local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Enables or disables any modifiers on pulse.";
TagModifier.icon = 17546229322;
TagModifier.color = Color3.fromRGB(255, 70, 37)
TagModifier.section = 1;
TagModifier.use_prompt = false;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	Value = {
		Default = false;
	};
	Output = {
		Default = nil;
		Type = Type.Instance();
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	self:set_powering( false );
	
	return self;
end

function TagModifier:pulse(signal)
	local state = self.attributes:get("Value") or false;
	
	for _, modifier in self:get_pulse_targets() do
		if modifier.attributes:get("Enabled") ~= nil then
			modifier.attributes:set("Enabled", state);
			
		elseif modifier.name == "flipflop" then
			modifier.always_active = not state;
			modifier:pulse(signal);
		end;
	end
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;