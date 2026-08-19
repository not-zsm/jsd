local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Used with Random modifier's 'Pick Weight' property to assign weights.";
TagModifier.icon = 9855704751;
TagModifier.color = Color3.fromRGB(255, 255, 255)
TagModifier.section = 2;
TagModifier.attribute_updates = {};
--TagModifier.signal_generator = true;
TagModifier.properties = {
	Weight = {
		Default = 1;
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	
	return self;
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;