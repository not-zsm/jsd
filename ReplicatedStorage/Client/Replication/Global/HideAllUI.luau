local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local LocalPlayerGui = LocalPlayer.PlayerGui

return function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	LocalPlayerGui.Statistics.Enabled = false

	task.spawn(function()
		local IconModule = require(ReplicatedStorage.Packages.Icon)
		IconModule.setTopbarEnabled(false)
	end)

	return function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		LocalPlayerGui.Statistics.Enabled = true

		task.spawn(function()
			local IconModule = require(ReplicatedStorage.Packages.Icon)
			IconModule.setTopbarEnabled(true)
		end)
	end
end
