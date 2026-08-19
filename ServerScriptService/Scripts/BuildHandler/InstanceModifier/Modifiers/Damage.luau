local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent.Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Take an amount of damage ";
TagModifier.icon = 79791826459299;
TagModifier.color = Color3.fromRGB(255, 92, 92)
TagModifier.section = 3;
TagModifier.use_prompt = false;
TagModifier.properties = {
	Debounce = {
		Default = 1;
	};
	Value = {
		Default = 20;
	};
	Effects = {
		Default = true;
	};
	Stun = {
		Default = 0;
	};
	EffectType = {
		Default = "Damage";
		ValueList = "Effects";
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	
	return self;
end

function TagModifier:pulse(signal)
	local data = self.attributes:all();
	
	for _, combat in signal:get_combats() do
		combat:damage_by_builder(data.Value);
		
		if data.Effects then
			combat:spawn_effects_by_builder(data.EffectType);
		end
		
		if data.Stun > 0 then
			combat:stun_by_builder(data.Stun);
		end
	end;
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;