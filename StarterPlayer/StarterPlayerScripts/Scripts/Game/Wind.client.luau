local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local WindShake = require( ReplicatedStorage.Shared.Utilities.WindShake )

WindShake:Init({
	MatchWorkspaceWind = true
})

if not LocalPlayer:GetAttribute("Foliage_Wind") then
	WindShake:Pause()
end

LocalPlayer:GetAttributeChangedSignal("Foliage_Wind"):Connect(function()
	if LocalPlayer:GetAttribute("Foliage_Wind") then
		WindShake:Resume()
	else
		WindShake:Pause()
	end
end)