--- ToolHotbar, was a LocalScript under StarterPlayerScripts. Body unchanged.
return {
	Name = "ToolHotbar",
	Priority = 100,
	Async = true,

	Start = function()
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
	end,
}
