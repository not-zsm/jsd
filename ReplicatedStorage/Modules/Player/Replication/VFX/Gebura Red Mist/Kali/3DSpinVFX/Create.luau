local RunService = game:GetService("RunService")

local function GetFrames(Folder : Folder) : {number}
	local Frames = {}

	for _, Frame in Folder:GetChildren() do
		local FrameTime = tonumber(Frame.Name)

		if not FrameTime then 
			continue
		end

		table.insert(Frames, FrameTime)
	end

	table.sort(Frames)

	return Frames
end

local function GetValue(Folder : Folder, Frame : number)
	local Exsits = Folder:FindFirstChild(`{Frame}`)
	return if Exsits then Exsits.Value else nil
end

local function GetSurrounding(Frames : {number}, CurrentFrame : number)
	local Lower, Upper

	for Index = 1, #Frames do
		if Frames[Index] <= CurrentFrame then
			Lower = Frames[Index]
		elseif Frames[Index] >= CurrentFrame then
			Upper = Frames[Index]
			break
		end
	end

	return Lower, Upper
end

local function Interpolate(Folder : Folder, Frames : {number}, CurrentFrame : number)
	local LowerFrame, UpperFrame = GetSurrounding(Frames, CurrentFrame)

	if not (LowerFrame and UpperFrame) then 
		return
	elseif LowerFrame and not UpperFrame then
		return GetValue(Folder, LowerFrame)
	elseif UpperFrame and not LowerFrame then
		return GetValue(Folder, UpperFrame)
	elseif LowerFrame == UpperFrame then 
		return GetValue(Folder, LowerFrame) 
	end

	local CurrentValue = GetValue(Folder, LowerFrame)
	local TargetValue = GetValue(Folder, UpperFrame)
	local Alpha = (CurrentFrame - LowerFrame) / (UpperFrame - LowerFrame)

	if typeof(CurrentValue) == "CFrame" then
		return CurrentValue:Lerp(TargetValue, Alpha)
	elseif typeof(CurrentValue) == "Vector3" then
		return CurrentValue:Lerp(TargetValue, Alpha)
	elseif typeof(CurrentValue) == "number" then
		return CurrentValue + ((TargetValue - CurrentValue) * Alpha)
	end
end

local CFrameFolder = script.Parent.Settings:FindFirstChild("CFrame")
local SizeFolder = script.Parent.Settings:FindFirstChild("Size")
local TransparencyFolder = script.Parent.Settings:FindFirstChild("Transparency")

local CFrameFrames = if CFrameFolder then GetFrames(CFrameFolder) else {}
local SizeFrames = if SizeFolder then GetFrames(SizeFolder) else {}
local TransparencyFrames = if TransparencyFolder then GetFrames(TransparencyFolder) else {}

local MinimumFrame = math.huge
local MaxFrame = -math.huge

for _, Frame in {CFrameFrames, SizeFrames, TransparencyFrames} do
	if #Frame <= 0 then
		continue
	end

	MinimumFrame = math.min(MinimumFrame, Frame[1])
	MaxFrame = math.max(MaxFrame, Frame[#Frame])
end

return function(RootPart : BasePart)
	local Mesh = script.Parent.Mesh:Clone()
	Mesh.Parent = workspace.Visuals
	local StartTime = os.clock()
	
	local Connection
	
	Connection = RunService.PreRender:Connect(function()
		local Elapsed = (os.clock() - StartTime) * 60
		local CurrentFrame = MinimumFrame + Elapsed
		
		if CurrentFrame > MaxFrame then 
			Connection:Disconnect() return
		end

		local NewCFrame = Interpolate(CFrameFolder, CFrameFrames, CurrentFrame)
		local NewSize = Interpolate(SizeFolder, SizeFrames, CurrentFrame)
		local NewTransparency = Interpolate(TransparencyFolder, TransparencyFrames, CurrentFrame)
		
		if NewCFrame then 
			Mesh.CFrame = RootPart.CFrame * NewCFrame
		end
		
		if NewSize then 
			Mesh.Size = NewSize
		end
		
		if NewTransparency then 
			Mesh.Transparency = NewTransparency
		end
	end)
	
	return Mesh, Connection
end