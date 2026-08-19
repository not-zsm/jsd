local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent.Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Outputs signal when powered to exactly its threshold.";
TagModifier.icon = 126259718770958;
TagModifier.color = Color3.fromRGB(127, 130, 172)
TagModifier.section = 7;
TagModifier.use_prompt = false;
TagModifier.properties = {
	Output = {
		Default = nil;
		Type = Type.Instance();
	};
	Threshold = {
		Default = 2;
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	return self;
end

function TagModifier:is_actively_powered()
	return InstanceModifier.is_actively_powered(self) and self:get_number_of_active_powers() == self.attributes:get("Threshold");
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;