local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

return {
	HighlightEffect = function(Object : Object, FillColor : Color3, Duration : Number)
		local Highlight = Instance.new("Highlight")
		Highlight.OutlineTransparency = 1
		Highlight.FillTransparency = 0.7
		Highlight.FillColor = FillColor
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.Adornee = Object
		Highlight.Parent = workspace.Visuals

		TweenService:Create(Highlight, TweenInfo.new(Duration), {FillTransparency = 1}):Play()
		
		task.delay(Duration, function()
			Highlight:Destroy()
		end)
	end,
}
