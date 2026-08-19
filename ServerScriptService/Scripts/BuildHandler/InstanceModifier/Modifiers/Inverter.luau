local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Inverses the signal that is powered into it.";
TagModifier.icon = 133377674379917;
TagModifier.color = Color3.fromRGB(127, 130, 172)
TagModifier.section = 7;
TagModifier.use_prompt = false;
TagModifier.properties = {
	Output = {
		Default = nil;
		Type = Type.Instance();
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self:set_powering(false);
	task.defer(function() self.active = true; end)
	
	return self;
end

function TagModifier:set_powering(value: boolean)
	InstanceModifier.set_powering(self, not value);
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;