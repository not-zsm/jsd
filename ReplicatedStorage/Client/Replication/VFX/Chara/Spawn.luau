local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

local AnimationRetriever = require( ReplicatedStorage.Client.Replication.VFX.AnimationRetriever )
local AnimationObject = ReplicatedStorage.Animations.CharacterSpawnAnimations.Chara.Spawn

local Yuki_FOV = require( ReplicatedStorage.Client.Replication.Global.Yuki_FOV )
local CameraShake = require( ReplicatedStorage.Client.Replication.Global.CameraShake )

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local ArcVFX = EffectUtility.Arc -- 💖

local Assets = script.Assets

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, AnimationObject)
		if (Retrieved == nil) then return end
		
		local Animation = Retrieved.Animation
		local Job = Retrieved.Job
	
		local IsMainPlayer = (LocalPlayer.Character == Model)
		
		if IsMainPlayer then
			local ColorCorrection = Instance.new("ColorCorrectionEffect")
			ColorCorrection.TintColor = Color3.fromRGB(91, 91, 91)
			ColorCorrection.Parent = Lighting
	
			TweenService:Create(ColorCorrection, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{TintColor = Color3.fromRGB(255, 255, 255)}
			):Play()
			
			task.delay(0.5, ColorCorrection.Destroy, ColorCorrection)
			
			CameraShake(0.75, 12.5, 0.01, 0.4, Vector3.one * 0.8, Vector3.one * 0.3)

			Yuki_FOV.Set(50)
			Yuki_FOV.Tween(70, {1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
		end
		
		Job:Task(EffectUtility.AddSFX(script.SFX, Retrieved.Torso, 0.3))
		
		ArcVFX.CloneAndEmit(Assets.spawn, Retrieved.RootPart)
		
		Job:Task(Animation:GetMarkerReachedSignal("point"):Connect(function()
			local Knife = Model:FindFirstChild("Knife") -- safer

			if Knife then
				ArcVFX.CloneAndEmit(Assets.knife_point, Knife.BladeInner)
				
				if IsMainPlayer then
					CameraShake(0.5, 2, 0.01, 0.7, Vector3.one * 0.8, Vector3.one * 0.3)

					Yuki_FOV.Set(65)
					Yuki_FOV.Tween(70, {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
				end
			end
		end))
	end,
}