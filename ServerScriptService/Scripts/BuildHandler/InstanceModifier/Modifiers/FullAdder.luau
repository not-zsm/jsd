local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Adds three inputs.";
TagModifier.icon = 85628588208044;
TagModifier.color = Color3.fromRGB(140, 143, 190)
TagModifier.section = 7;
TagModifier.use_prompt = false;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	Sum = {
		Default = nil;
		Type = Type.Instance();
	};
	Carry = {
		Default = nil;
		Type = Type.Instance();
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	return self;
end;

local function merge_targets(self, name: string, chain, targets)
	local new_targets = self:get_pulse_targets_of(self.attributes:get(name) or self.object, chain);

	table.move(new_targets, 1, #new_targets, #targets + 1, targets);
end

function TagModifier:get_pulse_targets(chain)
	local powers = self:get_number_of_active_powers();
	local maxed = powers >= 3;
	local targets = {};
	
	if maxed or powers == 1 then
		merge_targets(self, "Sum", chain, targets);
	end;
	
	if maxed or powers == 2 then
		merge_targets(self, "Carry", chain, targets);
	end;
	
	return targets;
end;

function TagModifier:update_powered()
	InstanceModifier.update_powered(self);
	self:update_powering_source();
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;