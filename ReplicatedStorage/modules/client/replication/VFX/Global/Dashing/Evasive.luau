local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )

local VFX = {}

function VFX.Start(RootPart : BasePart, EvasiveIFramesTime : number)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
	local MainPlayer = Players:GetPlayerFromCharacter(RootPart.Parent)

	if (Players.LocalPlayer ~= MainPlayer and Distance < 100) then
		EffectUtility.EmitEffects(script.Effects, RootPart)
	end

	if (LocalPlayer:GetAttribute("Evasive_IFrame_Highlight") and Distance < 100) then
		local Highlight = Instance.new("Highlight")
		Highlight.OutlineTransparency = 1
		Highlight.FillTransparency = 1
		Highlight.FillColor = Color3.new(1, 1, 1)
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.Parent = RootPart.Parent

		TweenService:Create(Highlight, TweenInfo.new(0.25),
			{FillTransparency = 0.3}
		):Play()

		task.delay(EvasiveIFramesTime, function()
			TweenService:Create(Highlight, TweenInfo.new(0.25),
				{FillTransparency = 1}
			):Play()

			task.delay(0.25, Highlight.Destroy, Highlight)
		end)
	end
end

return VFX

