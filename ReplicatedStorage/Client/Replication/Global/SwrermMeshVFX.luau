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

function MeshVFX.Emit(Model : BasePart)
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
	Clone.Parent = workspace.Visuals

	local Duration = tonumber(Model:GetAttribute("Duration")) or 0.1
	local Decal =  Clone:FindFirstChildOfClass("Decal")
	local DecalStartTransparency = tonumber(Model:GetAttribute("Decal_StartTransparency")) or StartTransparency

	if Decal then
		TweenService:Create(Clone, GetTweenData(Model, "Part", Duration), {
			Size = End.Size, 
			CFrame = End.CFrame
		}):Play()
	else
		TweenService:Create(Clone, GetTweenData(Model, "Part", Duration), {
			Size = End.Size, 
			CFrame = End.CFrame, 
			Transparency = 1
		}):Play()
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
		Decal.Transparency = DecalStartTransparency

		TweenService:Create(Decal, GetTweenData(Model, "Decal", Duration), {
			Transparency = EndDecal.Transparency, 
			Color3 = EndDecal.Color3
		}):Play()
	end

	task.delay(Duration, Clone.Destroy, Clone)
end

return MeshVFX
