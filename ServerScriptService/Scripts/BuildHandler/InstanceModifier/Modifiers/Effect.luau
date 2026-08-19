local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );
local Instances = require( Unpacker.Packages.Instances );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Add visual effects";
TagModifier.icon = 13518130183;
TagModifier.color = Color3.fromRGB(119, 255, 169)
TagModifier.section = 2;
TagModifier.use_prompt = true;
TagModifier.short_powered = true;
TagModifier.properties = {
	EffectType = {
		Order = 1,
		Default = "Heal";
		ValueList = "Effects";
	};
	PlayerSide = {
		Order = 2,
		Default = false;
	};
	Scale = {
		Order = 3,
		Default = 1,
	};
	Volume = {
		Order = 4,
		Default = 1
	};
	Recolor = {
		Order = 5;
		Default = false;
		Shows = { "Color" };
	};
	Color = {
		Order = 6,
		Hidden = true;
		Default = Color3.new(1, 1, 1);
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	
	return self;
end

function TagModifier:pulse(signal)
	local data = self.attributes:all();
	local parameters = { Scale = data.Scale, Volume = data.Volume, Tint = if data.Recolor then data.Color else nil };
	
	local vfx = ReplicatedStorage.Modules.Player.Replication.VFX;
	local effects = ReplicatedStorage.BuildTools.Effects;
	local effect = Instances.find_directory(effects, data.EffectType, "/") or Instances.find_directory(vfx, data.EffectType, "/");
	
	if not effect then
		return warn("Unable to find effect:", data.EffectType);
	end;
	
	if data.PlayerSide then
		for _, combat in signal:get_combats() do
			combat:spawn_effects_by_builder(effect, parameters);
		end;
	else
		self.build_handler:spawn_effects(effect, self.part, parameters)
	end
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;