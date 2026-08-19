local MeshVFX = {}

local TweenService = game:GetService("TweenService")

local function GetTweenData(Model : Model,  Prefix : string, Duration : number, DefaultStyle : string)
	local Params = Model:GetAttribute(Prefix .. "_TweenParams")

	if (Params == nil) then
		return TweenInfo.new(Duration, Enum.EasingStyle[DefaultStyle or "Cubic"], Enum.EasingDirection.Out)
	end

	local Split = string.split(Params, ",")

	return TweenInfo.new(Duration, Enum.EasingStyle[Split[1]], Enum.EasingDirection[Split[2]])
end

return function (Model : BasePart, EnableTransparency : boolean?)
	local Start = Model:FindFirstChild("Start")
	local End = Model:FindFirstChild("End")
	assert(Start or End, "Model does not have a start or an end.")

	local Clone = Start:Clone()

	local StartTransparency = tonumber(Model:GetAttribute("StartTransparency")) or 0

	if Clone:IsA("MeshPart") then
		Clone.Transparency = StartTransparency

	elseif Clone:IsA("BasePart")  then
		if Clone:FindFirstChildOfClass("Decal") then
			Clone.Transparency = 1
		end
	end

	Clone.Archivable = false
	Clone.Parent = workspace.Terrain

	local Duration = tonumber(Model:GetAttribute("Duration")) or 0.1
	local Decal =  Clone:FindFirstChildOfClass("Decal")

	local PartTweenData = GetTweenData(Model, "Part", Duration)

	if Decal then
		TweenService:Create(Clone, PartTweenData, {
			Size = End.Size, 
			CFrame = End.CFrame
		}):Play()
	else
		TweenService:Create(Clone, PartTweenData, {
			Size = End.Size, 
			CFrame = End.CFrame, 
			Color = End.Color
		}):Play()

		if EnableTransparency then
			TweenService:Create(Clone, PartTweenData, {Transparency = 1}):Play()
		end
	end

	local Mesh = Clone:FindFirstChildOfClass("SpecialMesh")
	local GoalMesh = End:FindFirstChildOfClass("SpecialMesh")

	if Mesh and GoalMesh then
		TweenService:Create(Mesh, GetTweenData(Model, "Mesh", Duration, "Sine"), {
			Scale = GoalMesh.Scale
		}):Play()
	end

	local EndDecal = End:FindFirstChildOfClass("Decal")

	if Decal and EndDecal then
		local DecalTweenData = GetTweenData(Model, "Decal", Duration)
		Decal.Transparency = StartTransparency

		TweenService:Create(Decal, DecalTweenData, {
			Color3 = EndDecal.Color3,
		}):Play()

		if EnableTransparency then
			TweenService:Create(Decal, DecalTweenData, {Transparency = 1}):Play()
		end
	end

	task.delay(Duration, Clone.Destroy, Clone)
end