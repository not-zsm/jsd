local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Maid = require( ReplicatedStorage.Packages.Maid )
local Stylus = require( ReplicatedStorage.Packages.Stylus )

local JoinRankedLobby = {}

local UIOpen = false

function JoinRankedLobby:Join()
	if UIOpen == true then return end
	
	UIOpen = true
	local ScreenGui = script.JoinConfirmation:Clone()
	local Buttons = ScreenGui.Body.Body.Buttons
	ScreenGui.Parent = LocalPlayer.PlayerGui

	Stylus:tween_blur(15, "Confirm")
	local WarningMaid = Maid.new()

	local function Close()
		UIOpen = false
		ScreenGui:Destroy()
		WarningMaid:destroy()

		Stylus:tween_blur(0, "Confirm")
	end

	WarningMaid:add(Buttons.Confirm.MouseButton1Click:Connect(function()
		Close()
		
		ReplicatedStorage.Remotes.JoinRankedLobby:FireServer()
	end))

	WarningMaid:add(Buttons.Deny.MouseButton1Click:Connect(function()
		Close()
	end))
end


return JoinRankedLobby
