local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Presets = require(script.Presets)

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local FXScreen = PlayerGui:WaitForChild("FXScreen")

return function(PresetName : string, Small : boolean)
	if Player:GetAttribute("Epileptic_Mode") then return end
	
	local Preset = Presets[PresetName]
	if (Preset == nil) then return end

	if Small then
		FXScreen.SmallPulse.ImageColor3 = Preset.Color
		FXScreen.SmallPulse.ImageTransparency = Preset.StartTransparency

		TweenService:Create(FXScreen.SmallPulse, TweenInfo.new(Preset.FadeTime or 1), 
			{ImageTransparency = 1}
		):Play()
	else
		FXScreen.Pulse.ImageColor3 = Preset.Color
		FXScreen.Pulse.ImageTransparency = Preset.StartTransparency

		TweenService:Create(FXScreen.Pulse, TweenInfo.new(Preset.FadeTime or 1), 
			{ImageTransparency = 1}
		):Play()
	end
end