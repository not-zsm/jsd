local TweenService = game:GetService("TweenService")

type Params = {
	Duration: number;
	DecalTween: number;
	MeshTween: string;
	PartTween: string;
}

local function getTweenData(obj: Instance, duration: number, prefix: string, defaultStyle: Enum.EasingStyle)
	local Params: Params = obj:GetAttribute(prefix .. "_TweenParams")    

	local DefaultParams = {
		{ "TweenStyle", defaultStyle },
		{ "TweenDirection", Enum.EasingDirection.Out },
	}

	local Values = {} :: {
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
					Values[Key] = Enum[Key][Value]
				end)

				if not Success then
					Values[Key] = Default
				end
			end
		end
	else
		for _, Param in DefaultParams do
			local Key = Param[1]
			local Default = Param[2]

			Values[Key] = Default
		end
	end

	return TweenInfo.new(duration, Values.TweenStyle, Values.TweenDirection)
end

local replicatedStorage = game:GetService("ReplicatedStorage")

local MeshVFX = {}
MeshVFX.DefaultStorage = replicatedStorage.modules.effect.assets.Parts.MeshVFX

function MeshVFX.Create(MeshModel : Model, StartPosition : (CFrame | Vector3), GoalOffsetFromStartPosition : (CFrame | Vector3))
	local MeshModelClone = MeshModel:Clone()
	
	local Start : BasePart = MeshModelClone:FindFirstChild("Start")
	local Goal : BasePart = MeshModelClone:FindFirstChild("End")
	
	if not Goal or not Start then
		return warn("nah uh no start or goal")
	end

	if typeof(StartPosition) == "Vector3" and typeof(GoalOffsetFromStartPosition) == "Vector3" then
		Start.Position = StartPosition

		if GoalOffsetFromStartPosition then
			Goal.Position = Start.Position + GoalOffsetFromStartPosition
		else
			Goal.Position = Start.Position
		end
		
	elseif typeof(StartPosition) == "CFrame" and typeof(GoalOffsetFromStartPosition) == "CFrame" then
		Start.CFrame = StartPosition

		if GoalOffsetFromStartPosition then
			Goal.CFrame = Start.CFrame * GoalOffsetFromStartPosition
		else
			Goal.CFrame = Start.CFrame
		end
	end
	
	local StartTransparency = tonumber(MeshModelClone:GetAttribute("StartTransparency")) or 0

	if Start:IsA("MeshPart") then
		Start.Transparency = StartTransparency
		
	elseif Start:IsA("BasePart")  then
		if Start:FindFirstChildOfClass("Decal") then
			Start.Transparency = 1
		end
	end

	MeshModelClone.Parent = workspace.Visuals
	
	local Duration = tonumber(MeshModelClone:GetAttribute("Duration")) or 0.1

	if Start:FindFirstChildOfClass("Decal") then
		TweenService:Create(Start, getTweenData(MeshModelClone, Duration, "Part", Enum.EasingStyle.Cubic), { Size = Goal.Size, CFrame = Goal.CFrame}):Play()
	else
		TweenService:Create(Start, getTweenData(MeshModelClone, Duration, "Part", Enum.EasingStyle.Cubic), { Size = Goal.Size, CFrame = Goal.CFrame, Transparency = 1 }):Play()
	end

	local Mesh = Start:FindFirstChildOfClass("SpecialMesh")
	local GoalMesh = Goal:FindFirstChildOfClass("SpecialMesh")   

	if Mesh and GoalMesh then
		TweenService:Create(Mesh, getTweenData(MeshModelClone, Duration, "Mesh", Enum.EasingStyle.Sine), { Scale = GoalMesh.Scale }):Play()
	end

	local Decal = Start:FindFirstChildOfClass("Decal")
	local GoalDecal = Goal:FindFirstChildOfClass("Decal")

	if Decal and GoalDecal then
		Decal.Transparency = 0
		TweenService:Create(Decal, getTweenData(MeshModelClone, Duration, "Decal", Enum.EasingStyle.Cubic), { Transparency = GoalDecal.Transparency, Color3 = GoalDecal.Color3 }):Play()
	end

	task.delay(Duration, MeshModelClone.Destroy, MeshModelClone)
	
	return Start, Goal
end

return MeshVFX