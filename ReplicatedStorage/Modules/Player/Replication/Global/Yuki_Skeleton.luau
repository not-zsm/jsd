local TweenService = game:GetService("TweenService")

return function(Part : Part, Duration : number?, FlashTime : number?)
	local SkeletonPart = script.Skeleton:FindFirstChild(Part.Name)
	if (SkeletonPart == nil) then return end
	
	FlashTime = FlashTime or 0.3
	Duration = Duration or 0.4

	Part.Transparency = 0.5

	local Skeleton = SkeletonPart:Clone()
	
	local Weld = Instance.new("Weld")
	Weld.Part0 = Part
	Weld.Part1 = Skeleton
	
	Weld.Parent = Skeleton
	Skeleton.Parent = workspace.Visuals

	local Highlight = Instance.new("Highlight")
	Highlight.FillColor = Color3.fromRGB(255, 0, 0)
	Highlight.OutlineTransparency = 1
	Highlight.Parent = Skeleton

	local Tween = TweenService:Create(Highlight, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, (Duration/FlashTime), true), {
		FillTransparency = 0
	})

	Tween:Play()

	task.delay(Duration, function()
		Tween:Cancel()
		
		local EndTween = TweenService:Create(Highlight, TweenInfo.new(FlashTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			FillTransparency = 1,
		})

		EndTween:Play()

		EndTween.Completed:Wait()

		Part.Transparency = 0
		Skeleton:Destroy()
	end)
end