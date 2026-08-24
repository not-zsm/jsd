local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

--[[
	The background blur jjk's menus open behind.

	The job owns the effect and its tween, so closing the menu takes the blur
	with it and a second menu opened on top of the first doesn't stack one.
--]]
return function(Job, Time : number, Size : number)
	if not Job then return end
	if Lighting:FindFirstChildOfClass("BlurEffect") then return end

	local Blur = Instance.new("BlurEffect")
	Blur.Size = 0
	Blur.Parent = Lighting
	Job:Task(Blur)

	local Tween = TweenService:Create(
		Blur,
		TweenInfo.new(Time + 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Size }
	)

	Job:Task(Tween)
	Tween:Play()
end
