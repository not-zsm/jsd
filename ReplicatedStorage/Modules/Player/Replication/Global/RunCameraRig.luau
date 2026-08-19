local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

---------------------------------------------------------------------------------

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

---------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

---------------------------------------------------------------------------------

local CurrentRunner = nil

return function(BoundTo : BasePart, Rig : Model, Offset : CFrame, Settings : {}, OnToggled : () -> ())
	if CurrentRunner then
		CurrentRunner()
		CurrentRunner = nil
	end
	
	Settings = Settings or {}
	Offset = Offset or CFrame.identity

	local Enabled = true
	local PreviousZoom = 0
	local PreviousCameraCFrame = CurrentCamera.CFrame
	
	local Connection : RBXScriptConnection = nil

	local AttachTo : ObjectValue = Rig:FindFirstChild("AttachTo")
	local Attach : BasePart = AttachTo and AttachTo.Value or Rig:FindFirstChild("camera")
	
	local NewJob = Job.new()
	
	if not Settings.DontDeleteRigOnClean then
		NewJob:Task(Rig)
	end
	
	if Settings.AttachToListen and AttachTo then
		NewJob:Task(AttachTo:GetPropertyChangedSignal("Value"):Connect(function()
			Attach = AttachTo.Value
		end))
	end

	local LerpValue = Instance.new("NumberValue")
	NewJob:Task(LerpValue)

	local function DisconnectRunner()
		if Connection and Connection.Connected then
			Connection:Disconnect()
		end
		
		--pcall(RunService.UnbindFromRenderStep, RunService, "CutsceneCamera")
		CurrentRunner = nil
	end

	local Cleaned = false

	local function Clean()
		if Cleaned then return end
		Cleaned = true

		DisconnectRunner()
		NewJob:Destroy()

		if not Settings.DontSaveCameraPosition and Enabled then
			CurrentCamera.CFrame = PreviousCameraCFrame
		end

		if LocalPlayer.Character then
			local Humanoid : Humanoid? = LocalPlayer.Character:FindFirstChild("Humanoid")
			
			if Humanoid then
				CurrentCamera.CameraSubject = Humanoid
			end
		end
	
		LocalPlayer.CameraMinZoomDistance = 0.5
		CurrentCamera.CameraType = Enum.CameraType.Custom
		
		LocalPlayer:SetAttribute("InCameraAnimation", nil)
	end

	local function OnDisabledSetting()
		DisconnectRunner()
		
		if not Settings.DontSaveCameraPosition then
			CurrentCamera.CFrame = PreviousCameraCFrame
		end

		LocalPlayer.CameraMinZoomDistance = 0.5
		CurrentCamera.CameraType = Enum.CameraType.Custom
	end
	
	local function OnEnabledSetting()
		LocalPlayer.CameraMinZoomDistance = 2
		
		if LocalPlayer.Character then
			for _, Part : BasePart in LocalPlayer.Character:GetDescendants() do
				if Part:IsA("BasePart") then
					Part.LocalTransparencyModifier = 0
				end
			end
		end
		
		PreviousCameraCFrame = CurrentCamera.CFrame
		CurrentCamera.CameraType = Enum.CameraType.Scriptable

		if not Settings.DontDoTransition then
			LerpValue.Value = 0

			TweenService:Create(LerpValue, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{Value = 1}
			):Play()
		end

		LocalPlayer:SetAttribute("InCameraAnimation", true)
		
		--RunService:BindToRenderStep("CutsceneCamera", Utility.ShiftlockRenderPriority, function()
		Connection = RunService.PreRender:Connect(function()
			if (LocalPlayer.Character == nil or Rig.Parent == nil) then
				return Clean()
			end
			
			if (Attach == nil) then
				warn("BOI THERES NO ATTACH!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
			end
			
			if BoundTo then
				Rig:PivotTo(BoundTo.CFrame * Offset)
			end

			if not Settings.DontDoTransition then
				CurrentCamera.CFrame = PreviousCameraCFrame:Lerp(Attach.CFrame, LerpValue.Value)
			else
				CurrentCamera.CFrame = Attach.CFrame
			end
		end)
	end

	local OriginalTransparencies = {}

	for _, Item in ipairs(Rig:GetDescendants()) do
		if Item:IsA("BasePart") then
			OriginalTransparencies[Item] = Item.Transparency
		end
	end

	local function Update()
		if Cleaned then return end
		
		Enabled = LocalPlayer:GetAttribute("Cutscenes") and not LocalPlayer:GetAttribute("InFreecam")
		
		if Enabled then
			OnEnabledSetting()
		else
			OnDisabledSetting()
		end
		
		if OnToggled then
			task.spawn(OnToggled, Enabled)
		end
		
		for Item, OriginalTransparency in OriginalTransparencies do
			if OriginalTransparency == 0 then
				Item.Transparency = (Enabled and 0 or 1)
			end
		end
	end

	if not Settings.DontSupportCutsceneSetting then
		NewJob:Task(LocalPlayer:GetAttributeChangedSignal("Cutscenes"):Connect(Update))
		Update()
	else
		OnEnabledSetting()
	end
	
	CurrentRunner = Clean

	return Clean
end