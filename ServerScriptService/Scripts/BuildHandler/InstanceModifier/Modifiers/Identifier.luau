local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Unpacker = require( "../../Unpacker" );
local Table = require( Unpacker.Packages.Table );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Used with splitters to connect multiple modifiers.";
TagModifier.icon = 13577838989;
TagModifier.color = Color3.fromRGB(255, 255, 255)
TagModifier.section = 6;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	InputId = {
		Default = "1"
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	return self;
end

function TagModifier.attribute_updates:InputId(value, was_init)
	if not self.old_id then
		self.old_id = value;
	end
	
	local old_id = self.old_id;
	local id_map = self.instance_id_map;
	
	Table.nest_remove(id_map, old_id, self);
	Table.nest_add(id_map, value, self);
	
	self.old_id = value;
end

function TagModifier:destroy()
	Table.nest_remove(self.instance_id_map, self.old_id, self);
	InstanceModifier.destroy(self);
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;