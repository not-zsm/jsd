local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );
local Asset = require( Unpacker.Packages.Asset )

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Plays a sound";
TagModifier.icon = 93979319272954;
TagModifier.color = Color3.fromRGB(255, 46, 46)
TagModifier.section = 3;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	AssetId = {
		Order = 10;
		Default = "154147007",
		AssetType = Enum.AssetType.Audio;
	};
	Volume = {
		Order = 20;
		Default = 1;
	};
	Pitch = {
		Order = 30;
		Default = 1;
	};
	Looped = {
		Order = 40;
		Default = false
	};
	Reference = {
		Order = 50;
		Default = nil;
		Type = Type.Instance();
		Hides = { "AssetId", "Volume", "Pitch" };
	};
};

local function update_volume(self)
	self.sound_ref.SoundId = Asset.get_rbx_asset( self.attributes:get("AssetId") );
	self.sound_ref.Volume = self.attributes:get("Volume");
	self.sound_ref.PlaybackSpeed = self.attributes:get("Pitch");
end

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	
	self.sound_ref = self.maid:add(Instance.new("Sound"));
	self.sound_ref.Archivable = false;
	
	self.using_sound = self.sound_ref;
	
	return self;
end

function TagModifier.attribute_updates:Looped(value, was_init)
	self:on_active_changed();
end

function TagModifier.attribute_updates:Volume(value)
	update_volume(self);
end;

function TagModifier.attribute_updates:Pitch(value)
	update_volume(self);
end

function TagModifier:on_active_changed()
	if self.attributes:get("Looped") then
		self.using_sound.Looped = true;
		
		if not self.active then
			self.using_sound:Stop();
		else
			self.using_sound:Play();
		end
	else
		self.using_sound.Looped = false;
	end
end

function TagModifier.attribute_updates:Reference(reference)
	if not reference then
		self.sound_ref.Parent = self.part;
		self.using_sound = self.sound_ref;
	else
		self.sound_ref.Parent = nil;
		self.using_sound = reference;
	end
end

function TagModifier.attribute_updates:AssetId(asset_id)
	update_volume(self);
	
	if self.using_sound.IsPlaying then
		self.using_sound:Play();
	end;
end

function TagModifier:pulse(signal)
	update_volume(self);
	self.using_sound:Play();
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;