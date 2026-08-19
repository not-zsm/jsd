local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Transmits if the chance succeeds.";
TagModifier.icon = 87856882069750;
TagModifier.color = Color3.fromRGB(0, 255, 234)
TagModifier.section = 1;
TagModifier.use_prompt = false;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	Chance = {
		Order = 1,
		Default = 50;
	};
	SignalBased = {
		Order = 3,
		Default = false;
	};
	PickWeight = {
		Order = 4,
		Default = false;
	};
	PickThreshold = {
		Order = 5,
		Default = nil;
		Type = Type.number();
	};
	Output = {
		Order = 2,
		Default = nil,
		Type = Type.Instance()
	};
};

local function check_chance(self): boolean
	return math.random() <= self.attributes:get("Chance") / 100;
end;

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	self.carry_pulse = true;
	
	return self;
end

function TagModifier.attribute_updates:PickWeight(value, was_init)
	if was_init then return end;

	if value then
		self.attributes:set("PickThreshold", 1);
	else
		self.attributes:remove("PickThreshold");
	end
end

function TagModifier:get_pulse_targets_of(object, chain)
	if not self.attributes:get("PickWeight") then
		return InstanceModifier.get_pulse_targets_of(self, object, chain);
	end;
	
	local list = object:GetChildren();
	local total_weight = 0;
	local pick_me = {};
	
	for _, child in list do
		local modifiers = self.get_modifiers(child);
		
		if not modifiers then continue end;
		
		local weight = 0;
		local is_weighted = false;
		local targets = {};
		
		for _, modifier in modifiers do
			table.insert(targets, modifier);
			
			if modifier.name == "weight" then
				is_weighted = true;
				weight += modifier.attributes:get("Weight") or 1;
			end;
		end
		
		if not is_weighted then
			weight = 1;
		end;
		
		total_weight += weight;
		table.insert(pick_me, {weight = weight, targets = targets});
	end
	
	local targets = {};
	local current_picks = 0;
	local picks_threshold = self.attributes:get("PickThreshold") or 1;	
	
	while current_picks < picks_threshold and #pick_me ~= 0 do
		
		local pick_me_weight = total_weight;
		local chance = math.random() * total_weight;
		local has_picked = false;
		
		for index, weight_target in pick_me do
			pick_me_weight -= weight_target.weight;

			if pick_me_weight <= chance then
				current_picks += 1;
				total_weight -= weight_target.weight;
				has_picked = true;
				
				table.move(weight_target.targets, 1, #weight_target.targets, #targets + 1, targets);
				table.remove(pick_me, index);
				
				break;
			end;
		end;
		
		if not has_picked then
			-- Breaks the loop.
			current_picks = picks_threshold;
		end;
	end;
	
	return targets;
end

function TagModifier:pulse(signal)
	if self.attributes:get("SignalBased") or not check_chance(self) then
		return;
	end;
	
	InstanceModifier.pulse(self, signal);
end;

function TagModifier:on_powered_changed()
	if self.powered then
		self:set_powering(self.attributes:get("SignalBased") and check_chance(self))
	else
		self:set_powering(false)
	end
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;