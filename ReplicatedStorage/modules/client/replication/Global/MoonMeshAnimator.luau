local TweenService = game:GetService("TweenService")

local MeshAnimator = {}

local ConvertedStyleNames = {
	["Expo"] = "Exponential"
}

local function GetEase(Value)
	return ConvertedStyleNames[Value] or Value
end

function MeshAnimator.new(CF : CFrame, Folder : Folder)
	local CFrameFolder : Folder = Folder:FindFirstChild("CFrame")
	local SizeFolder : Folder = Folder:FindFirstChild("Size")
	local TransparencyFolder : Folder = Folder:FindFirstChild("Transparency")
	
	local CFrameStartFolder : Folder = CFrameFolder:FindFirstChild("Start")
	local CFrameEndFolder : Folder = CFrameFolder:FindFirstChild("End")
	
	local SizeStartFolder : Folder = SizeFolder:FindFirstChild("Start")
	local SizeEndFolder : Folder = SizeFolder:FindFirstChild("End")
	
	local TransparencyStartFolder : Folder = TransparencyFolder:FindFirstChild("Start")
	local TransparencyEndFolder : Folder = TransparencyFolder:FindFirstChild("End")
	
	local CFrameStartValue = CFrameStartFolder.Frame.Value
	local CFrameEndValue = CFrameEndFolder.Frame.Value
	
	local SizeStartValue = SizeStartFolder.Frame.Value
	local SizeEndValue = SizeEndFolder.Frame.Value
	
	local TransparencyStartValue = TransparencyStartFolder.Frame.Value
	local TransparencyEndValue = TransparencyEndFolder.Frame.Value
	
	local CFrameTime = (CFrameEndValue - CFrameStartValue) / 60
	local SizeTime = (SizeEndValue - SizeStartValue) / 60
	local TransparencyTime = (TransparencyEndValue - TransparencyStartValue) / 60
	
	local CFrameEasing : Folder = CFrameStartFolder.Eases["0"]
	local SizeEasing : Folder = SizeStartFolder.Eases["0"]
	local TransparencyEasing : Folder = TransparencyStartFolder.Eases["0"]
	
	local Mesh = Folder:FindFirstChildOfClass("MeshPart"):Clone()
	Mesh.CFrame = CF * CFrameStartFolder.Values["0"].Value
	Mesh.Size = SizeStartFolder.Values["0"].Value
	Mesh.Transparency = TransparencyStartFolder.Values["0"].Value
	
	local CFrameTween = TweenService:Create(Mesh, TweenInfo.new(CFrameTime, Enum.EasingStyle[GetEase(CFrameEasing.Type.Value)], Enum.EasingDirection[CFrameEasing.Params.Direction.Value]), {
		CFrame = CF * CFrameEndFolder.Values["0"].Value
	})
	
	local SizeTween = TweenService:Create(Mesh, TweenInfo.new(SizeTime, Enum.EasingStyle[GetEase(SizeEasing.Type.Value)], Enum.EasingDirection[CFrameEasing.Params.Direction.Value]), {
		Size = SizeEndFolder.Values["0"].Value
	})

	local TransparencyTween = TweenService:Create(Mesh, TweenInfo.new(TransparencyTime, Enum.EasingStyle[GetEase(SizeEasing.Type.Value)], Enum.EasingDirection[CFrameEasing.Params.Direction.Value]), {
		Transparency = TransparencyEndFolder.Values["0"].Value
	})
	
	Mesh.Parent = workspace.Visuals

	CFrameTween:Play()
	SizeTween:Play()
	TransparencyTween:Play()
end

return MeshAnimator
