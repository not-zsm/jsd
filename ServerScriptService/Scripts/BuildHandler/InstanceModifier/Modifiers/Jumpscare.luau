local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Scares players with an image and sound";
TagModifier.needs_gamepass = "TrapsPack1";
TagModifier.icon = 12125924907;
TagModifier.color = Color3.fromRGB(255, 28, 28)
TagModifier.section = 5;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	Image = {
		Order = 1,
		Default = "11242716421";
		AssetType = Enum.AssetType.Decal;
	};
	Sound = {
		Order = 2,
		Default = "4933141916",
		AssetType = Enum.AssetType.Audio;
	};
	Duration = {
		Order = 3,
		Default = 0.5;
	};
	FadeOut = {
		Order = 5,
		Default = 0.25;
	};
	Lasting = {
		Order = 6,
		Default = 1;
	};
	Volume = {
		Order = 4,
		Default = 3;
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
		local player = combat:get_player();
		
		if player then
			Unpacker.Remotes.Effects.SpawnScreen:FireClient(player, {
				image = data.Image, 
				fade_out = data.FadeOut,
				duration = data.Duration,
				lasting = data.Lasting,
				volume = data.Volume,
				sound_id = tostring(data.Sound)
			})
		end
	end;
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;