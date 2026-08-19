local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);
local Asset = require( ReplicatedStorage.Packages.Asset )
local Maid = require( ReplicatedStorage.Packages.Maid )

local Remotes = ReplicatedStorage.BuildTools.Remotes;

local SoundPointer = 0;

-------------------------------------------------------------------------

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(255, 42, 42)
DerivedBlock.icon = "7203392850"
DerivedBlock.description = "Plays a custom sound"
DerivedBlock.order = 4;
DerivedBlock.properties = {
	AssetId = {
		Order = 10,
		Default = "8595980577",
		AssetType = Enum.AssetType.Audio,
		Described = true;
	};
	Volume = {
		Described = true;
		Order = 20,
		Default = 1,
		Format = {
			Type = "Slider",
			Range = NumberRange.new(0, 2);
			Increment = 0.025;
		};
	};
	PlaybackSpeed = {
		Order = 30,
		Default = 1,
		Format = {
			Type = "Slider",
			Range = NumberRange.new(0, 2);
			Increment = 0.025;
		};
	};
	PlaybackRollOff = {
		Order = 50,
		Default = NumberRange.new(10, 150),
	};
	RollOffMode = {
		Order = 55,
		Default = Enum.RollOffMode.Inverse,
	};
	PlaybackRegion = {
		Order = 60;
		Default = NumberRange.new(0, 60000);
	};
	Looped = {
		Order = 65;
		Default = false;
	};
	Cancellable = {
		Order = 70;
		Default = false;
	};
	Targeting = {
		Order = 120,
		Default = "Default",
		IsBranchTargeting = true;
		ValueList = { "Default", "User", "Target" };
	};
};

function DerivedBlock.new(...)
	local self = setmetatable(BaseBlock.new(...), DerivedBlock);

	self.sounds = {};
	
	return self;
end;

-------------------------------------------------------------------------

function DerivedBlock:cancel(forceful)
	if self.values.Cancellable or forceful then
		self:stop_sounds();
	end
end;

function DerivedBlock:stop_sounds()
	for _, maid in self.sounds do
		maid:destroy()
	end;
	
	table.clear(self.sounds);
end;

function DerivedBlock:initialise_cache(cache: Configuration)
	local data = self:get_values();
	
	self.cache_sound = Instance.new("Sound");
	self.cache_sound.Name = self:get_internal_name();
	self.cache_sound.SoundId = Asset.get_rbx_asset(data.AssetId);
	self.cache_sound.Volume = data.Volume;
	self.cache_sound.RollOffMaxDistance = data.PlaybackRollOff.Max;
	self.cache_sound.RollOffMinDistance = data.PlaybackRollOff.Min;
	self.cache_sound.PlaybackSpeed = data.PlaybackSpeed * self.sequence_skill:get_speed_multiplier();
	self.cache_sound.PlaybackRegionsEnabled = true;
	self.cache_sound.PlaybackRegion = data.PlaybackRegion;
	self.cache_sound.RollOffMode = data.RollOffMode;
	self.cache_sound.Looped = data.Looped;
	self.cache_sound.Parent = cache;
end

function DerivedBlock:activate(sequencer, combat)
	self.cache_sound.PlaybackSpeed = self.values.PlaybackSpeed * self.sequence_skill:get_speed_multiplier();
	
	SoundPointer = (SoundPointer + 1) % (2 ^ 32);
	
	local root_part = combat.LuaCharacter.RootPart;
	local sound_start = tick();
	local current_id = SoundPointer;
	
	Remotes.Effects.SpawnSound:FireAllClients(self.cache_sound, root_part, current_id)
	
	local sound_maid = Maid.light();
	
	sound_maid:add(Players.PlayerAdded:Connect(function(player)
		Remotes.Effects.SpawnSound:FireClient(player, self.cache_sound, root_part, current_id, (tick() - sound_start) % self.cache_sound.TimeLength)
	end));
	
	sound_maid:add(function()
		Remotes.Effects.RemoveSound:FireAllClients(current_id);
	end);
	
	if not self.cache_sound.Looped then
		sound_maid:add(task.delay(self.cache_sound.TimeLength + 2, function()
			self.sounds[current_id] = nil;
			sound_maid:destroy();
		end))
	end
	
	self.sounds[current_id] = sound_maid;
end

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;