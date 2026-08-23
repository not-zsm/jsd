local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local CameraShaker = require( ReplicatedStorage.modules.shared.Utilities.CameraShaker )

local Shaker = CameraShaker.new(Enum.RenderPriority.Camera.Value + 10, function(ShakeCFrame : CFrame)
	CurrentCamera.CFrame *= ShakeCFrame
end)

local CannotCameraShake = false

Player:GetAttributeChangedSignal("CannotCameraShake"):Connect(function()
	CannotCameraShake = Player:GetAttribute("CannotCameraShake")
end)

Shaker:Start()

return function(Intensity : number, Speed : number, FadeIn : number, FadeOut : number, PosInfluence : Vector3, RotInfluence : Vector3?)
	if (CannotCameraShake or Player:GetAttribute("Camera_Shake") == 0) then 
		return
	end

	return Shaker:Fire(Intensity, Speed, FadeIn, FadeOut, PosInfluence, RotInfluence)
end
