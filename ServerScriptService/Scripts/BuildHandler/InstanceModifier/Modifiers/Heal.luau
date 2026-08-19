local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Heal an amount of health";
TagModifier.icon = 18416638478;
TagModifier.color = Color3.fromRGB(159, 255, 137)
TagModifier.section = 3;
TagModifier.use_prompt = true;
TagModifier.properties = {
	Debounce = {
		Default = 1;
	};
	Value = {
		Default = 20;
	};
	Prompt = {
		Default = true;
	};
	Effects = {
		Default = true;
	};
	EffectType = {
		Default = "Heal";
		ValueList = "Effects";
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	
	return self;
end

function TagModifier:prompt_set()
	self.prompt.Enabled = self.attributes:get("Prompt");
	self.prompt.ActionText = "Heal";
	self.prompt.ObjectText = `+{self.attributes:get("Value")}`
end

function TagModifier:pulse(signal)
	local data = self.attributes:all();
	
	for _, combat in signal:get_combats() do
		combat:heal_by_builder( math.max(0, data.Value) );
		
		if data.Effects then
			combat:spawn_effects_by_builder(data.EffectType);
		end;
	end;
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;