local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )
local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

function VFX.Hit(RootPart : BasePart)
	local Offset = CFrame.new(0, -3, 0) * CFrame.Angles(0, math.rad(-180), 0)
	
	local Camera = script.Camera:Clone()
	Camera:PivotTo(RootPart.CFrame * Offset)
	Camera.Parent = workspace.Visuals
	
	local CameraEffect = script.FinishingHitEffect:Clone()
	EffectUtility.Weld(CameraEffect, RootPart, CFrame.new(0, 0, -5.389))
	CameraEffect.Parent = workspace.Visuals
	EffectUtility.Emit(CameraEffect)

	local Animation = Camera.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Reigen["SALT PUAAANNCH"].Camera)
	Animation:Play(0)
	
	local Clean = RunCameraRig(RootPart, Camera, Offset)
	
	AttributeListener.new(RootPart, "SaltPunchFinisherCamera", function()
		CameraEffect:Destroy()
		Clean()
		
		Yuki_FOV.Reset()
	end)
	
	local ColorCorr = Instance.new("ColorCorrectionEffect")
	ColorCorr.Parent = Lighting
	task.delay(5, ColorCorr.Destroy, ColorCorr)
	
	local ColorT_Info = TweenInfo.new(.1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)

	TweenService:Create(ColorCorr, ColorT_Info, {Brightness = 2}):Play()
	TweenService:Create(ColorCorr, ColorT_Info, {Saturation = 2}):Play()
	TweenService:Create(ColorCorr, ColorT_Info, {Contrast = 2}):Play()
	TweenService:Create(ColorCorr, ColorT_Info, {TintColor = Color3.fromRGB(0, 0, 0)}):Play()
	task.wait(.055)

	TweenService:Create(ColorCorr, ColorT_Info, {Brightness = -2}):Play()
	TweenService:Create(ColorCorr, ColorT_Info, {Contrast = -10}):Play()
	TweenService:Create(ColorCorr, ColorT_Info, {Saturation = -1}):Play()
	TweenService:Create(ColorCorr, ColorT_Info, {TintColor = Color3.fromRGB(255, 255, 255)}):Play()
	task.wait(.045)

	TweenService:Create(ColorCorr, ColorT_Info, {Brightness = 0}):Play()
	TweenService:Create(ColorCorr, ColorT_Info, {Contrast = 15}):Play()
	TweenService:Create(ColorCorr, ColorT_Info, {Saturation = -2}):Play()
	TweenService:Create(ColorCorr, ColorT_Info, {TintColor = Color3.fromRGB(0, 0, 0)}):Play()
	task.wait(.055)

	TweenService:Create(ColorCorr, ColorT_Info, {Brightness = 2}):Play()
	TweenService:Create(ColorCorr, ColorT_Info, {Contrast = 10}):Play()
	TweenService:Create(ColorCorr, ColorT_Info, {Saturation = -1}):Play()
	TweenService:Create(ColorCorr, ColorT_Info, {TintColor = Color3.fromRGB(255, 255, 255)}):Play()
	task.wait(.055)

	ColorT_Info = TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	TweenService:Create(ColorCorr, ColorT_Info, {TintColor = Color3.fromRGB(255, 255, 255)}):Play()
	TweenService:Create(ColorCorr, ColorT_Info, {Brightness = 0}):Play()
	TweenService:Create(ColorCorr, ColorT_Info, {Contrast = 0}):Play()
	TweenService:Create(ColorCorr, ColorT_Info, {Saturation = 0}):Play()
end

return VFX
