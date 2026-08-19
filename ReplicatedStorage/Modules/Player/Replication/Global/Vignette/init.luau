local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Presets = require(script.Presets)

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local FXScreen = PlayerGui:WaitForChild("FXScreen")

return function(Color : Color3, StartTransparency : number, FadeTime : number, Smaller : boolean)
	if Player:GetAttribute("Epileptic_Mode") then return end
	
	local Effect = Smaller and FXScreen.SmallPulse or FXScreen.Pulse

	Effect.ImageColor3 = Color
	Effect.ImageTransparency = StartTransparency

	TweenService:Create(Effect, TweenInfo.new(FadeTime or 1), 
		{ImageTransparency = 1}
	):Play()
end