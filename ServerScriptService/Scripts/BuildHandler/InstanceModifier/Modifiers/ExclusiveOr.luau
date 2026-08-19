local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Outputs signal if powered by exclusively one, or an odd number.";
TagModifier.icon = 90923289915370;
TagModifier.color = Color3.fromRGB(127, 130, 172)
TagModifier.section = 7;
TagModifier.use_prompt = false;
TagModifier.properties = {
	Threshold = {
		Default = 2;
	};
	Output = {
		Default = nil;
		Type = Type.Instance();
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	return self;
end

function TagModifier:is_actively_powered()
	return InstanceModifier.is_actively_powered(self) and self:get_number_of_active_powers() % self.attributes:get("Threshold") == 1;
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;