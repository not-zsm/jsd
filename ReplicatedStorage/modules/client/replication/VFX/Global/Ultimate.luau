local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local VFX = {}

function VFX.Reached(Model : Model) -- fires to guy who ulted
	local Highlight = Instance.new("Highlight")
	Highlight.FillTransparency = 1
	Highlight.OutlineTransparency = 1
	Highlight.FillColor = Color3.new(1, 1, 1)
	Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	Highlight.Parent = Model
	
	TweenService:Create(Highlight, TweenInfo.new(0.2),
		{FillTransparency = 0.5}
	):Play()
	
	task.delay(0.5, function()
		TweenService:Create(Highlight, TweenInfo.new(0.5),
			{FillTransparency = 1}
		):Play()
		
		task.delay(0.5, Highlight.Destroy, Highlight)
	end)
end

return VFX

