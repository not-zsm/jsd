local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Bubble = require( ReplicatedStorage.Modules.Player.Replication.Global.Bubble )

function VFX.Start(RootPart : BasePart)
	EffectUtility.EmitEffects(script.Startup, RootPart)
end

function VFX.Teleport(Torso : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(Torso.Position)

	if Distance <= 25 then
		CameraShake(1, 10, 0.1, 0.35)
	end

	if Distance <= 125 then
		EffectUtility.EmitEffects(script.Teleport, Torso)

		local Effect = script.Smudge:Clone()
		Effect.Parent = Torso
		Effect:Emit(15)
	end
end

function VFX.Push(RootPart : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if Distance <= 25 then
		local Shake = CameraShake(1, 7.5, 0.1, 0)

		if Shake then
			task.delay(1.1, function()
				Shake:StartFadeOut(0.2)
			end)
		end
	end

	if Distance <= 125 then
		EffectUtility.EmitEffects(script.Hit, RootPart)

		for _, Effect in {script.HitEffect.Hit, script.HitEffect.Sustained} do
			local NewEffect = Effect:Clone()
			NewEffect.CFrame = CFrame.new(1, 0, -3.3) * CFrame.Angles(0, math.pi, 0)
			NewEffect.Parent = RootPart
			EffectUtility.Emit(NewEffect)
		end
	end
end

function VFX.Throw(RootPart : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if Distance <= 25 then
		CameraShake(2, 25, 0.1, 0.3)
	end

	if Distance <= 125 then
		local Effect = script.HitEffect.FinalHit:Clone()
		Effect.WorldCFrame = RootPart.CFrame * CFrame.new(1, 0, -3.3) * CFrame.Angles(0, math.pi, 0)
		Effect.Parent = workspace.Terrain
		EffectUtility.Emit(Effect)

		Bubble(RootPart.Position, 6, Vector3.one * 5, Vector3.one * 40, 0.4)
	end
end

return VFX