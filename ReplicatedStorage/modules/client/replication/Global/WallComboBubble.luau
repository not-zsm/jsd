local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")


return function(Torso : BasePart?, Startup : number?, Duration : number?, EndSize : Vector3?, LifeTime : number?) : typeof(script.Bubble)
	local Bubble = script.Bubble:Clone()
	Bubble.CFrame = Torso.CFrame

	local WeldLike = RunService.PostSimulation:Connect(function() -- weld gives weird behavior to jumping so i have no choice
		Bubble.CFrame = Torso.CFrame
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

	TweenService:Create(Bubble, TweenInfo.new(Startup, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Transparency = 0.75, 
		Size = EndSize
	}):Play()

	task.delay(Duration, function()
		TweenService:Create(Bubble, TweenInfo.new(LifeTime, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut), {
			Transparency = 0.9, 
			Size = EndSize
		}):Play()

		task.delay(LifeTime, Bubble.Destroy, Bubble)
	end)

	return Bubble
end
