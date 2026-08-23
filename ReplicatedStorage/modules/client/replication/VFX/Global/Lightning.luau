local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer

local RockHandler = require( ReplicatedStorage.modules.client.replication.Global.RockHandler )
local EffectUtility = require( ReplicatedStorage.modules.client.replication.EffectUtility )

local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )
local ScreenPulse = require( ReplicatedStorage.modules.client.replication.Global.ScreenPulse )

local CameraShake = require( ReplicatedStorage.modules.client.replication.Global.CameraShake )
local VFX = {}

function VFX.Strike(RaycastPosition : Vector3, RaycastColor : Color3)
	local DistanceFromStrike = Player:DistanceFromCharacter(RaycastPosition)
	
	local Strike = script.Strike:Clone()
	Strike.Position = RaycastPosition
	Strike.Orientation = RockHandler.GenerateRandomOrientation()
	
	local Distance = (Vector3.yAxis * -10)
	
	coroutine.wrap(RockHandler.Crater)(RaycastPosition, Distance, {
		Rocks = 10,
		Distance = 8.5,	

		LookAt = { -- Where the rocks face towards (y axis)
			Min = -3,
			Max = -3
		},

		Exposure = {
			Min = 0.4,
			Max = 0.6
		},
		
		SizeMagnitude = 1
	})

	coroutine.wrap(RockHandler.Crater)(RaycastPosition, Distance, {
		Rocks = 20,
		Distance = 15,	
		SizeMagnitude = 1.75
	})

	coroutine.wrap(RockHandler.Rockst)(RaycastPosition, Distance, {
		Size = {0.75, 1.5},
		Count = 6,
		Velocity = 25,
	})
	
	EffectUtility.CraterSmoke("Big", {Position = RaycastPosition, Normal = Vector3.new(0, 1, 0), Instance = {Color = RaycastColor}})
	
	if (DistanceFromStrike < 47.5) then
		CameraShake(30, 200, 0.1, 0.75, Vector3.one * 0.8)
		
		local ColorCorrection = Instance.new("ColorCorrectionEffect")
		ColorCorrection.Brightness = 10
		ColorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
		
		TweenService:Create(ColorCorrection, TweenInfo.new(0.75), {
			Brightness = 0
		}):Play()
		
		task.delay(0.8, ColorCorrection.Destroy, ColorCorrection)
		
	elseif (DistanceFromStrike < 200) then
		CameraShake(2, 25, 0.1, 0.4, Vector3.one * 0.8)
	end
	
	Strike.Parent = workspace.Visuals
	EffectUtility.Emit(Strike)
	
	local Sound = script.Sound:Clone()
	Sound.Parent = Strike
	Sound:Play()
	task.delay(10, Sound.Destroy, Sound)
end

return VFX