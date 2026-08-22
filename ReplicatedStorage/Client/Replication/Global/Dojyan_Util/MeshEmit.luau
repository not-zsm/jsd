local TweenService = game:GetService("TweenService")

local function getTweenData(Object: Instance, Duration: number, Prefix: string, DefaultStyle: Enum.EasingStyle)
	
	local Params: Params = Object:GetAttribute(Prefix .. "_TweenParams")    

	local DefaultParams = {
		
		{ "TweenStyle", DefaultStyle},
		{ "TweenDirection", Enum.EasingDirection.Out},
		
	}

	local Values = { } :: {
		
		TweenStyle: Enum.EasingStyle,
		TweenDirection: Enum.EasingDirection,
		
	}

	if typeof(Params) == "string" then

		local Matches = { Params:match("(%a+),(%a+)") }
		
		for Index = 1, 2 do

			local Value = Matches[Index]
			local Param = DefaultParams[Index]

			local Key = Param[1]
			local Default = Param[2]

			if not Value then
				Values[Key] = Default
			else
				local Success = pcall(function()
					Values[Key] = Default.EnumType[Value]
				end)

				if not Success then
					Values[Key] = Default
				end
				
				Index += 1
				
			end
		end
		
	else
		
		for _, Params in DefaultParams do

			local Key = Params[1]
			local Default = Params[2]

			Values[Key] = Default

		end
	end

	return TweenInfo.new(Duration, Values.TweenStyle, Values.TweenDirection)
	
end

return function(Object: BasePart, ToggleTransparency: boolean, ToggleFlipbook, IDS, Speed)

	local Goal = Object.Parent:FindFirstChild("End")

	if not Goal then
		warn("Goal is not defined.")
		return
	end

	local Clone = Object:Clone()

	local StartTransparency = tonumber(Object.Parent:GetAttribute("StartTransparency")) or 0

	if Clone:IsA("MeshPart") then
		Clone.Transparency = StartTransparency
	elseif Clone:IsA("BasePart")  then
		if Clone:FindFirstChildOfClass("Decal") then
			Clone.Transparency = 1
		end
	end

	local Duration = tonumber(Object.Parent:GetAttribute("Duration")) or .1

	if Clone:FindFirstChildOfClass("Decal") then
		
		TweenService:Create(Clone, getTweenData(Object.Parent, Duration, "Part", Enum.EasingStyle.Cubic), {Size = Goal.Size, CFrame = Goal.CFrame}):Play()
	
	else
		
		TweenService:Create(Clone, getTweenData(Object.Parent, Duration, "Part", Enum.EasingStyle.Cubic), {Size = Goal.Size, CFrame = Goal.CFrame, Color = Goal.Color}):Play()

		if ToggleTransparency then
			TweenService:Create(Clone, getTweenData(Object.Parent, Duration, "Part", Enum.EasingStyle.Cubic), {Transparency = 1}):Play()
		else
			Object.Parent:GetAttribute("StartTransparency")
		end
		
	end

	local Mesh = Clone:FindFirstChildOfClass("SpecialMesh")
	local GoalMesh = Goal:FindFirstChildOfClass("SpecialMesh")   

	if Mesh and GoalMesh then
		TweenService:Create(Mesh, getTweenData(Object.Parent, Duration, "Mesh", Enum.EasingStyle.Sine), {Scale = GoalMesh.Scale}):Play()
	end

	local Decal = Clone:FindFirstChildOfClass("Decal")
	local GoalDecal = Goal:FindFirstChildOfClass("Decal")

	if Decal and GoalDecal then
		
		Decal.Transparency = StartTransparency
		TweenService:Create(Decal, getTweenData(Object.Parent, Duration, "Decal", Enum.EasingStyle.Cubic), {Color3 = GoalDecal.Color3}):Play()
		
		if ToggleTransparency then
			TweenService:Create(Decal, getTweenData(Object.Parent, Duration, "Decal", Enum.EasingStyle.Cubic), {Transparency = 1}):Play()
		else
			Object.Parent:GetAttribute("StartTransparency")
		end
		
		if ToggleFlipbook then

			for _, Search in ipairs(Clone:GetDescendants()) do
				if Search:IsA("Decal") then

					task.spawn(function()
						for i = 1, #IDS do
							Search.Texture = IDS[i]
							task.wait(Speed)
						end

					end)

				end
			end

		end
		
	end


	Clone.Parent = workspace.Visuals

	task.delay(Duration, Clone.Destroy, Clone)
	
	return Duration
	
end


