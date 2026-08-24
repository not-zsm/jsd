local VFX = {};

local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local MeshVFX = require( replicatedStorage.modules.client.replication.Global.MeshVFX )

local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )

local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )

local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )

local Assets = script.VFX

function VFX.Slash(RootPart : BasePart, Count : number)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	if Distance < 100 then 
		local Slash : typeof(Assets.Slash1.Slash) = Assets[`Slash{Count}`]:Clone()
		EffectUtility.Weld(Slash, RootPart, CFrame.new(0, 0, -0.5) * CFrame.Angles(0, 0, math.rad(180)))
		Slash.Parent = workspace.Visuals
		EffectUtility.Emit(Slash)
	end

	if (Distance <= 15) then
		CameraShake(1, 10, 0.01, 0.25, Vector3.one * 0.8)
		Vignette(Color3.fromRGB(66, 183, 255), 0.6, 0.2)
	end
end

function VFX.SlashHit(VictimRootPart : BasePart, Count : number)
	local Distance = LocalPlayer:DistanceFromCharacter(VictimRootPart.Position)

	if Distance < 100 then
		local HitSFX : Sound = script.HitSFX[Count]:Clone()
		HitSFX.Parent = VictimRootPart
		HitSFX:Play()
		task.delay(2, HitSFX.Destroy, HitSFX)

		if LocalPlayer:GetAttribute("Blood") then
			local Hit = script.Parent.Hit.SmallerBlood:Clone()
			Hit.WorldCFrame = VictimRootPart.CFrame * RockHandler.GenerateRandomOrientation(true)
			Hit.Parent = workspace.Terrain
			EffectUtility.Emit(Hit)
		end
	
		Blood.BloodRaysWithoutPreset(VictimRootPart, {
			Amount = Vector2.new(3, 5),
			Spread = Vector2.new(45, 45),
			Face = Enum.NormalId.Front,
			PoolSize = 0.85,
		})
	end

	if (Distance <= 20) then
		CameraShake(1.5, 35, 0.01, 0.2, Vector3.one * 0.8, Vector3.one * 0.5)
	end
end

return VFX