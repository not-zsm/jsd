local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local MoonMeshAnimator = require( ReplicatedStorage.Modules.Player.Replication.Global.MoonMeshAnimator )

local VFXAssets = script.VFX
local AssetsPart = VFXAssets.Assets

local Colors = {
	Color3.fromRGB(162, 85, 255),
	Color3.fromRGB(105, 185, 255),
	Color3.fromRGB(90, 255, 115),
	Color3.fromRGB(146, 113, 255),
}

function VFX.Grab(RootPart : BasePart)
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25 then
		CameraShake(2, 25, 0.05, 0.35, Vector3.one * 0.8)
		Vignette(Colors[math.random(1, #Colors)], 0.35, 0.15)
		
		Yuki_FOV.Tween(85, {0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
		
		task.delay(0.4, function()
			Yuki_FOV.Tween(70, {0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.In})
		end)
	end

	EffectUtility.CloneAndEmit(AssetsPart.grab, RootPart)
end

function VFX.Throw(ThrowCF : CFrame)
	if LocalPlayer:DistanceFromCharacter(ThrowCF.Position) <= 25 then
		CameraShake(3, 50, 0.025, 0.4, Vector3.one * 0.8)
		Vignette(Colors[math.random(1, #Colors)], 0.35, 0.15)
		
		Yuki_FOV.Tween(93.5, {0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})

		task.delay(0.55, function()
			Yuki_FOV.Tween(70, {0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.In})
		end)
	end

	local Effect = VFXAssets.throw:Clone()
	Effect:PivotTo(ThrowCF * Effect:GetPivot())
	Effect.Parent = workspace.Visuals
	EffectUtility.Emit(Effect)
	
	MoonMeshAnimator.new(ThrowCF, script.Meshes.M1)
	MoonMeshAnimator.new(ThrowCF, script.Meshes.M2)
end

return VFX