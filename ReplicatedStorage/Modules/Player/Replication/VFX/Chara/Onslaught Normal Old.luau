local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CharaAssets = ReplicatedStorage.Effects.Characters.Chara

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )
	
function VFX.Start(RootPart : BasePart)
	local Knife : Model = RootPart.Parent:FindFirstChild("Knife")

	if (Knife ~= nil) then
		Knife.Handle.BladeAttachment.Trail.Enabled = true

		AttributeListener.new(RootPart, "OnslaughtNormal", function()
			if (Knife ~= nil and Knife.Parent ~= nil) then
				Knife.Handle.BladeAttachment.Trail.Enabled = false
			end
		end)
	end
end

function VFX.Swing(RootPart : BasePart)
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 20 then
		CameraShake(1, 10, 0.01, 0.2, Vector3.one * 0.8, Vector3.one * 0.25)
	end
	
	EffectUtility.CloneAndEmit(script.Assets.swing, RootPart)
end

function VFX.Stab(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.stab, RootPart)
end

function VFX.StabHit(VictimRootPart : BasePart)
	if LocalPlayer:DistanceFromCharacter(VictimRootPart.Position) < 20 then
		CameraShake(1.5, 15, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.25)
		Vignette(Color3.fromRGB(255, 0, 0), 0.5, 0.25)
	end

	Blood.BloodRaysWithoutPreset(VictimRootPart, {
		Amount = Vector2.new(4, 6),
		Face = Enum.NormalId.Front,
		PoolSize = 1.5
	})
end

function VFX.Smack(VictimTorso : BasePart)
	EffectUtility.EmitEffects(CharaAssets.Hit, VictimTorso)
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

function VFX.SlashHit(VictimRootPart : BasePart)
	Blood.BloodRaysWithoutPreset(VictimRootPart, {
		Amount = Vector2.new(4, 6),
		Face = Enum.NormalId.Front,
		PoolSize = 1.5
	})

	local Effect = CharaAssets.Assets.slashed:Clone()
	Effect.CFrame = CFrame.new(0.35, 0, -0.3) * CFrame.Angles(0, 0, math.rad(-90))
	Effect.Parent = VictimRootPart
	EffectUtility.Emit(Effect)
end

function VFX.Slam(RootPart : BasePart)
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 20 then
		CameraShake(1.75, 17.5, 0.01, 0.35, Vector3.one * 0.8, Vector3.one * 0.25)
		Vignette(Color3.fromRGB(255, 0, 0), 0.35, 0.25)
	end

	EffectUtility.CloneAndEmit(script.Assets.slam, RootPart)
end

return VFX