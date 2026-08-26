local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )

local LoopAnim = nil

return {
	Start = function(Character : Model)
		local Retrieved = AnimationRetriever.new(Character, replicatedStorage.ass.emotes.Write.Loop)
		if (Retrieved == nil) then return end

		local Job = Retrieved.Job

		local WriteUI = script.GUI:Clone()
		WriteUI.Parent = PlayerGui
		WriteUI.Enabled = true
		
		local TextBox = WriteUI.Write.TextBox
		
		Job:Task(TextBox.FocusLost:Connect(function(EnterPressed)
			if EnterPressed then
				network.finishWriting.send(TextBox.Text)
				
				TextBox.Text = ""
				TextBox:ReleaseFocus()
				
				Job:Destroy()
			end
		end))
		
		Job:Task(WriteUI)
	end,
}
