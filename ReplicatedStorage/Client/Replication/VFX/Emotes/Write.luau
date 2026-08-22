local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local AnimationRetriever = require( ReplicatedStorage.Client.Replication.VFX.AnimationRetriever )

local LoopAnim = nil

return {
	Start = function(Character : Model)
		local Retrieved = AnimationRetriever.new(Character, ReplicatedStorage.Animations.Emotes.Write.Loop)
		if (Retrieved == nil) then return end

		local Job = Retrieved.Job

		local WriteUI = script.GUI:Clone()
		WriteUI.Parent = PlayerGui
		WriteUI.Enabled = true
		
		local TextBox = WriteUI.Write.TextBox
		
		Job:Task(TextBox.FocusLost:Connect(function(EnterPressed)
			if EnterPressed then
				ReplicatedStorage.Remotes.Emotes.FinishWriting:FireServer(TextBox.Text)
				
				TextBox.Text = ""
				TextBox:ReleaseFocus()
				
				Job:Destroy()
			end
		end))
		
		Job:Task(WriteUI)
	end,
}
