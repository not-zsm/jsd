local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Bubble = require( ReplicatedStorage.Modules.Player.Replication.Global.Bubble )
local SuperTween = require( ReplicatedStorage.Modules.Player.Replication.Global.SuperTween )
local Gust = require( ReplicatedStorage.Modules.Player.Replication.Global.AnimatedMesh.Gust )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local function VFXOnPart(Directory : string, Type : string, Part : BasePart)
	local Effect = script[Directory][Type]:Clone()
	Effect.Parent = Part
	EffectUtility.Emit(Effect)
end

function VFX.Start(RootPart : BasePart)
	EffectUtility.EmitEffects(script.ChargingEffect, RootPart)
	EffectUtility.EmitEffects(script.SFX, RootPart)
end

function VFX.Explode(RootPart : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if Distance <= 30 then
		local Shake = CameraShake(2.75, 30, 0.1, 0, Vector3.one * 0.8, Vector3.one * 0.55)
		
		if Shake then
			task.delay(4, function()
				Shake:StartFadeOut(1)
			end)
		end
	end
	
	EffectUtility.EmitEffects(script.Laugh, RootPart)
	EffectUtility.EmitEffects(script.Wind, RootPart)
	EffectUtility.EmitEffects(script.Body, RootPart)
	EffectUtility.EmitEffects(script.Ground, RootPart)
	
	local Laughs = script.Laughs:Clone()
	Laughs.Position = RootPart.Position
	Laughs.Parent = workspace.Visuals
	Laughs["Ha.."]:Emit(2)
	Laughs["Ha.."].Enabled = true
	
	task.delay(6.5, function()
		Laughs["Ha.."].Enabled = false
		task.delay(1, Laughs.Destroy, Laughs)
	end)
	
	Bubble(RootPart, 8, Vector3.new(5,5,5), Vector3.new(100,100,100), 0.5)
	
	Gust.GroundWind({cf = RootPart.CFrame, xn = 5, forlop= 14, wait_ = 0.3, colr = BrickColor.new("White")})
	
	if Players:GetPlayerFromCharacter(RootPart.Parent) == Players.LocalPlayer then
		Yuki_FOV.Tween(90, {4, Enum.EasingStyle.Back})
	end
end

function VFX.Charge(RootPart : BasePart, Arm : BasePart)
	VFXOnPart("LeftArm", "1", RootPart.Parent["Left Arm"])
	
	local WindAbsorptionClone = script.WindAbsorptionHolder.WindAbsorptionAgain:Clone()
	WindAbsorptionClone.Parent = RootPart
	
	EffectUtility.Emit(WindAbsorptionClone)
	
	if Players:GetPlayerFromCharacter(RootPart.Parent) == Players.LocalPlayer then
		Yuki_FOV.Tween(45, {0.5})
	end

	for i, particleEmitter in pairs(WindAbsorptionClone:GetChildren()) do
		local currentSize = particleEmitter.Size
		local newKeypoints = {}

		for i, keypoint in ipairs(currentSize.Keypoints) do
			local newTime = keypoint.Time
			local newValue = 0
			local newEnvelope = 0

			table.insert(newKeypoints, NumberSequenceKeypoint.new(newTime, newValue, newEnvelope))
		end

		local newSizeSequence = NumberSequence.new(newKeypoints)
		local newTween = SuperTween.new(particleEmitter, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = newSizeSequence}
		)

		newTween:Play()
	end
end

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

function VFX.MainExplosion(RootPart : BasePart)
	if Players:GetPlayerFromCharacter(RootPart.Parent) == Players.LocalPlayer then
		Yuki_FOV.Tween(70, {0.75, Enum.EasingStyle.Back})
	end
	
	EffectUtility.EmitEffects(script.Explosion, RootPart)
	EffectUtility.EmitEffects(script.ExplosionShine, RootPart)
	
	Bubble(RootPart.Parent["Left Arm"].Position, 6, Vector3.new(5,5,5), Vector3.new(100,100,100), 0.5)
	
	Gust.GroundWind({cf = RootPart.CFrame, xn = 4, colr = BrickColor.new("White"), tim = 0.7})
	
	local Position = RootPart.Position
	local Direction = Vector3.yAxis * -10
	
	coroutine.wrap(RockHandler.Crater)(Position, Direction, {
		Amount = 15,
		Distance = 17.5,

		LookAt = { -- Where the rocks face towards (y axis)
			Min = 45,
			Max = -45
		},

		Exposure = {
			Min = 0.3,
			Max = 0.5
		},

		BaseZ = 1.5,
		SizeMultiplier = 1.5,
	})

	coroutine.wrap(RockHandler.Crater)(Position, Direction, {
		Amount = 20,
		Distance = 20,
		
		LookAt = { -- Where the rocks face towards (y axis)
			Min = 50,
			Max = -50
		},
		
		SizeMultiplier = 2,
	})
end

return VFX