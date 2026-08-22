local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local AnimationRetriever = require( ReplicatedStorage.Client.Replication.VFX.AnimationRetriever )

return {
	Result = function(WinnerCharacter : Model, LoserCharacter : Model)
		if LocalPlayer.Character == WinnerCharacter then
			EffectUtility.EmitEffects(script.Win, WinnerCharacter.HumanoidRootPart)
			
		elseif LocalPlayer.Character == LoserCharacter then
			EffectUtility.EmitEffects(script.Lose, LoserCharacter.HumanoidRootPart)
		end
		
		local Highlight = Instance.new("Highlight")
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.FillColor = Color3.fromRGB(60, 255, 0)
		Highlight.FillTransparency = 0.7
		Highlight.OutlineTransparency = 1
		Highlight.OutlineColor = Color3.new(1, 1, 1)
		Highlight.Adornee = WinnerCharacter
		Highlight.Enabled = true
		Highlight.Parent = workspace.Visuals

		TweenService:Create(Highlight, TweenInfo.new(0.5), {FillTransparency = 1}):Play()
		task.delay(0.5, function()
			Highlight:Destroy()
		end)
	end,
}
