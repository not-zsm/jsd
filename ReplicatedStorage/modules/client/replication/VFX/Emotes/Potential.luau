local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local AnimationRetriever = require(replicatedStorage.modules.client.replication.VFX.AnimationRetriever)
local CameraShake = require(replicatedStorage.modules.client.replication.Global.CameraShake)
local Yuki_FOV = require(replicatedStorage.modules.client.replication.Global.Yuki_FOV)

return {
	Start = function(Reference : Configuration, IsCrashout : boolean?)
		if (Reference == nil or Reference.Parent == nil) then return end
		
		Yuki_FOV.Tween(80, {0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out}, true)
		
		local Vignette = script.Vignette:Clone()
		Vignette.Parent = LocalPlayer:WaitForChild("PlayerGui")
		
		TweenService:Create(Vignette.Image, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
			Size = UDim2.fromScale(1.45, 1.45),
			ImageTransparency = 0.5,
		}):Play()
		
		local LoopingShake = CameraShake(1, 3, 0.1, 0, vector.create(0.35, 0.35, 0.35))
		
		local function CleanShake()
			if LoopingShake then
				LoopingShake:StartFadeOut(0.2)
			end
		end
		
		local ColorCorrection
		
		if IsCrashout then
			ColorCorrection = Instance.new("ColorCorrectionEffect")
			ColorCorrection.Parent = Lighting
			
			TweenService:Create(ColorCorrection, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Saturation = -1.1,
				Contrast = 1,
			}):Play()
		end
		
		Reference.Destroying:Once(function()
			if IsCrashout then
				TweenService:Create(ColorCorrection, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
					Saturation = 0,
					Contrast = 0,
				}):Play()

				task.delay(0.25, ColorCorrection.Destroy, ColorCorrection)
			end
			
			CleanShake()
			
			Yuki_FOV.Tween(70, {0.15, Enum.EasingStyle.Circular, Enum.EasingDirection.Out}, true)
			
			TweenService:Create(Vignette.Image, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Size = UDim2.fromScale(1.75, 1.75),
				ImageTransparency = 1,
			}):Play()
			
			task.delay(0.25, Vignette.Destroy, Vignette)
		end)
	end,
}