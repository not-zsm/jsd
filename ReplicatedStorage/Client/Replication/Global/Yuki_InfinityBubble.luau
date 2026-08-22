local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

return function(Attach : BasePart?, Duration : number?, EndSize : Vector3?, LifeTime : number?, Offset : CFrame) : typeof(script.Bubble)
	local Bubble = script.Bubble:Clone()
	Bubble.CFrame = Attach.CFrame * (Offset or CFrame.identity)

	local WeldLike = RunService.PostSimulation:Connect(function() -- weld gives weird behavior to jumping so i have no choice
		Bubble.CFrame = Attach.CFrame * (Offset or CFrame.identity)
	end)

	Bubble.Destroying:Once(function()
		if WeldLike.Connected then
			WeldLike:Disconnect()
		end
	end)
	
	local RequiredHighlight = Instance.new("Highlight")
	RequiredHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	RequiredHighlight.FillTransparency = 1
	RequiredHighlight.OutlineTransparency = 1
	RequiredHighlight.Enabled = false
	RequiredHighlight.Parent = Bubble

	Bubble.Parent = workspace.Visuals

	TweenService:Create(Bubble, TweenInfo.new(Duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Transparency = 1, 
		Size = EndSize
	}):Play()

	if LifeTime then
		task.delay(LifeTime, Bubble.Destroy, Bubble)
	end
	
	return Bubble
end
