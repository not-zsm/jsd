local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Creates an active signal only if enabled.";
TagModifier.icon = 137601480983962;
TagModifier.color = Color3.fromRGB(153, 255, 69)
TagModifier.section = 1;
TagModifier.use_prompt = false;
TagModifier.signal_generator = true;
TagModifier.properties = {
	Enabled = {
		Default = true
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

function TagModifier:update()
	InstanceModifier.update(self);
	
	self:set_always_active( self.attributes:get("Enabled") )
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;