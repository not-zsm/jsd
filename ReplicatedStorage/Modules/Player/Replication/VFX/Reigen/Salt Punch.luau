local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

function VFX.Start(RootPart : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	if (Distance <= 100) then
		EffectUtility.EmitEffects(script.Dash, workspace.Terrain, RootPart.CFrame * CFrame.new(0, 0, -1.5))
		EffectUtility.EmitEffects(script.DashDust, workspace.Terrain, RootPart.CFrame * CFrame.new(0, -3, -1.5))

		local SaltArm = script.Arm.SaltParticle:Clone()
		SaltArm.Parent = RootPart.Parent["Right Arm"]
		EffectUtility.Emit(SaltArm)
	end
end

function VFX.Hit(RootPart : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if (Distance <= 100) then
		EffectUtility.EmitEffects(script.Hit, workspace.Terrain, RootPart.CFrame * CFrame.new(0, 0, -4))
	end
end

function VFX.Punch(RootPart : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if (Distance <= 100) then
		EffectUtility.EmitEffects(script.Punch, workspace.Terrain, RootPart.CFrame * CFrame.new(0, 0, -4))
	end
end

return VFX
