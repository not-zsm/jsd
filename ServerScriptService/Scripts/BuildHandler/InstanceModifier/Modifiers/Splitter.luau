local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Duplicates a signal into modifiers of an ID";
TagModifier.icon = 11882607348;
TagModifier.color = Color3.fromRGB(236, 130, 255)
TagModifier.section = 6;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	Pulsate = {
		Default = true;
	};
	ByName = {
		Default = false;
	};
	OutputId = {
		Default = "1"
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.carry_pulse = true;
	
	return self;
end

function TagModifier:get_pulse_targets_of(object, chain)
	if not chain then chain = {}; end;
	chain[self] = true;

	local targets = {};
	local output_id = self.attributes:get("OutputId");
	local list: {any};
	
	if self.attributes:get("ByName") then
		list = InstanceModifier.get_name_modifiers(output_id);
	else
		list = {};
		
		local id_modifiers = InstanceModifier.get_id_modifiers(output_id);
		
		for _, modifier in id_modifiers do
			local others = InstanceModifier.get_modifiers(modifier.object);
			
			for _, modifier2 in others do
				table.insert(list, modifier2);
			end
		end
	end
	
	for _, modifier in list do
		if chain[modifier] then continue end;
		
		table.insert(targets, modifier);
	end
	
	return targets;
end

function TagModifier.attribute_updates:Pulsate(value)
	self.carry_pulse = value;
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;