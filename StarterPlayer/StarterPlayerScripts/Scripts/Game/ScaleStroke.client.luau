local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIStrokeAdjuster = require( ReplicatedStorage.Shared.Utilities.UIStrokeAdjuster )

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

UIStrokeAdjuster:TagScreenGui(PlayerGui:WaitForChild("Gifting", 100))
UIStrokeAdjuster:TagScreenGui(PlayerGui:WaitForChild("Settings", 100))
UIStrokeAdjuster:TagScreenGui(PlayerGui:WaitForChild("Information", 100))