local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);
local Remotes = ReplicatedStorage.BuildTools.Remotes

-------------------------------------------------------------------------
--Intensity, Speed, FadeIn, FadeOut, PosInfluence, RotInfluence

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(255, 190, 146)
DerivedBlock.icon = "16060788318"
DerivedBlock.description = "Adds a camera shake around you"
DerivedBlock.order = 31;
DerivedBlock.properties = {
	ExcludeMyself = {
		Order = -20;
		Default = false;
	};
	EmitOffset = {
		Order = -10,
		Default = Vector3.zero;
	};
	PositionInfluence = {
		Order = 0,
		Default = Vector3.one;
	};
	RotationInfluence = {
		Order = 5,
		Default = Vector3.zero;
	};
	Range = {
		Order = 10,
		Default = 5;
	};
	Intensity = {
		Described = true;
		Order = 20,
		Default = 3,
	};
	Speed = {
		Described = true;
		Order = 30,
		Default = 15,
	};
	FadeIn = {
		Order = 40,
		Default = 0.1,
	};
	FadeOut = {
		Order = 50,
		Default = 1,
	};
};

function DerivedBlock.new(...)
	local self = setmetatable(BaseBlock.new(...), DerivedBlock);
	
	return self;
end;

-------------------------------------------------------------------------

function DerivedBlock:initialise_cache(cache: Configuration)
	local data = self:get_values();
	data.ExcludeMyself = nil;
	data.EmitOffset = nil;

	self.cache_setting = Instance.new("Configuration");
	self.cache_setting.Name = self:get_internal_name();

	for attribute, value in data do
		self.cache_setting:SetAttribute(attribute, value);
	end

	self.cache_setting.Parent = cache;
end

function DerivedBlock:activate(sequencer, combat)
	local data = self.data;
	
	local function camera_shake(lua_player)
		if not lua_player.IsNPC then
			Remotes.Effects.CameraShake:FireClient(lua_player.Player, self.cache_setting);
		end;
	end;
	
	if not self.values.ExcludeMyself then
		camera_shake(combat.LuaPlayer);
	end;
	
	local Hitbox = combat.Hitbox:Create(true)
	Hitbox.Adornee = combat:GetSimulatedRoot();
	Hitbox.Params.Size = data.Range.Value;
	Hitbox.Params.Offset = CFrame.new(data.EmitOffset.Value);
	Hitbox.Events.OnLuaPlayerHit:Connect(camera_shake);

	Hitbox:Detect();
	Hitbox:Destroy();
end;

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;