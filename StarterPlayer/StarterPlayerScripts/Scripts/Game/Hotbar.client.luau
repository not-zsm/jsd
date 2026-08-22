local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local HotbarModule = require(script.HotbarModule)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local HotbarGui = script.Hotbar:Clone()
HotbarGui.Parent = PlayerGui
local Hotbar = HotbarModule.new(HotbarGui)

Hotbar:LoadTools()