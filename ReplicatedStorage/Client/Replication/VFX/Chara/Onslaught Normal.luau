local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CharaAssets = ReplicatedStorage.Effects.Characters.Chara

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Client.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Client.Replication.Global.Vignette )

local Blood = require( ReplicatedStorage.Client.Replication.Global.Blood )

local RockHandler = require( ReplicatedStorage.Client.Replication.Global.RockHandler )
local Smoke = require( ReplicatedStorage.Client.Replication.Global.Smoke )

local AnimationRetriever = require( ReplicatedStorage.Client.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Chara["Onslaught"]

local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )

local function Hit_SFX(Name : string, Torso : BasePart)
	local SFX = script.SFX.Hits:FindFirstChild(Name)
	
	if SFX then
		EffectUtility.AddSFX(SFX, Torso)
	else
		warn("no sfx", Name)
	end
end

function VFX.Windup(Model : Model)
	local Retrieved = AnimationRetriever.new(Model, Animations.NormalWindup)
	if (Retrieved == nil) then return end

	local Torso = Retrieved.Torso
	local RootPart = Retrieved.RootPart

	local MainJob = Retrieved.Job
	local Animation = Retrieved.Animation

	local Knife : Model = RootPart.Parent:FindFirstChild("Knife")

	if (Knife ~= nil) then
		Knife.Handle.BladeAttachment.Trail.Enabled = true

		MainJob:Task(function()
			if (Knife.Parent ~= nil) then
				Knife.Handle.BladeAttachment.Trail.Enabled = false
			end
		end)
	end

	MainJob:Task(Animation:GetMarkerReachedSignal("hit"):Once(function()
		if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 20 then
			CameraShake(1, 10, 0.01, 0.2, Vector3.one * 0.8, Vector3.one * 0.25)
		end

		EffectUtility.CloneAndEmit(script.Assets.swing, RootPart)
	end))

	MainJob:Task(EffectUtility.AddSFX(script.SFX.Windup, Torso, 0.25))
end

function VFX.Hit(Model : Model, VictimModel : Model)
	local Retrieved = AnimationRetriever.new(Model, Animations.NormalHit)
	if (Retrieved == nil) then return end

	local Torso = Retrieved.Torso
	local RootPart = Retrieved.RootPart

	local MainJob = Retrieved.Job
	local Animation = Retrieved.Animation

	MainJob:Task(EffectUtility.AddSFX(script.SFX.Whooshes, Torso, 0.25))
end

function VFX.Stab(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.stab, RootPart)
end

function VFX.StabHit(VictimRootPart : BasePart, SFX : string)
	if LocalPlayer:DistanceFromCharacter(VictimRootPart.Position) < 20 then
		CameraShake(1.5, 15, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.25)
		Vignette(Color3.fromRGB(255, 0, 0), 0.5, 0.25)
	end

	Blood.BloodRaysWithoutPreset(VictimRootPart, {
		Amount = Vector2.new(4, 6),
		Face = Enum.NormalId.Front,
		PoolSize = 1.5
	})
	
	Hit_SFX(SFX, VictimRootPart)
end

function VFX.Smack(VictimTorso : BasePart, SFX : string)
	EffectUtility.EmitEffects(CharaAssets.Hit, VictimTorso)
	Hit_SFX(SFX, VictimTorso)
end

function VFX.Kick(RootPart : BasePart)
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 20 then
		CameraShake(1.5, 15, 0.01, 0.2, Vector3.one * 0.8, Vector3.one * 0.25)
	end

	EffectUtility.CloneAndEmit(script.Assets.kick, RootPart)
end

function VFX.KickSwing(RootPart : BasePart, Type : number)
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 20 then
		CameraShake(1, 10, 0.01, 0.2, Vector3.one * 0.8, Vector3.one * 0.25)
	end

	EffectUtility.CloneAndEmit(script.Assets[`kickswing{Type}`], RootPart)
end

function VFX.Slash(RootPart : BasePart, Type : number)
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 20 then
		CameraShake(1.5, 15, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.25)
		Vignette(Color3.fromRGB(255, 0, 0), 0.5, 0.25)
	end

	EffectUtility.CloneAndEmit(script.Assets[`slash{Type}`], RootPart)
end

function VFX.SlashHit(VictimRootPart : BasePart, SFX : string)
	Blood.BloodRaysWithoutPreset(VictimRootPart, {
		Amount = Vector2.new(4, 6),
		Face = Enum.NormalId.Front,
		PoolSize = 1.5
	})

	local Effect = CharaAssets.Assets.slashed:Clone()
	Effect.CFrame = CFrame.new(0.35, 0, -0.3) * CFrame.Angles(0, 0, math.rad(-90))
	Effect.Parent = VictimRootPart
	EffectUtility.Emit(Effect)
	
	Hit_SFX(SFX, VictimRootPart)
end

function VFX.Slam(RootPart : BasePart)
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 20 then
		CameraShake(1.75, 17.5, 0.01, 0.35, Vector3.one * 0.8, Vector3.one * 0.25)
		Vignette(Color3.fromRGB(255, 0, 0), 0.35, 0.25)
	end

	EffectUtility.CloneAndEmit(script.Assets.slam, RootPart)
end

return VFX