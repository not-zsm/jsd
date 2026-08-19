local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local FOV = {
	Immune = false
}

local CurrentTween : Tween

local CurrentCamera = workspace.CurrentCamera

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local function Cancel()
	if (CurrentTween ~= nil) then
		CurrentTween:Cancel()
		CurrentTween = nil
	end
end

type EasingInfo = {time : number?, easingStyle : Enum.EasingStyle?, easingDirection : Enum.EasingDirection?, repeatCount : number?, reverses : boolean?, delayTime : number?}

function FOV.Tween(Target : number?, Info : EasingInfo?, CancelPrevious : boolean?) : ()
	if FOV.Immune then return end
	
	--Cancel()
	
	if CancelPrevious then
		Cancel()
	end
	
	CurrentTween = TweenService:Create(CurrentCamera, TweenInfo.new(table.unpack(Info)), {FieldOfView = Target or 70})
	CurrentTween:Play()
	
	CurrentTween.Completed:Once(function()
		if CurrentTween then
			CurrentTween:Destroy()
			CurrentTween = nil
		end
	end)
end

function FOV.Set(Target : number)
	if FOV.Immune then return end
	
	Cancel()
	CurrentCamera.FieldOfView = Target
end

function FOV.Reset()
	if FOV.Immune then return end
	
	Cancel()
	CurrentCamera.FieldOfView = 70
end

local FrameDuration = 1 / 60

function FOV.AnimateWithMoonFile(Folder : Folder, DontResetFOV : boolean?, AdditionalFOV : number?)
	FOV.Immune = true
	AdditionalFOV = AdditionalFOV or 0

	--local Elapsed = 0;
	
	local Connection : RBXScriptConnection
	local Cleaned = false
	local Paused = false
	
	--local TempTable = {};
	--local RenderName = tostring(TempTable)

	local function Clean()
		if Cleaned then return end
		
		Cleaned = true
		Connection:Disconnect()
		--pcall(RunService.UnbindFromRenderStep, RunService, RenderName)

		FOV.Immune = false
		
		if not DontResetFOV then
			FOV.Tween(70, {0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out})
		end
	end

	local StartTime = os.clock()
	local LastItem = #Folder:GetChildren()

	--RunService:BindToRenderStep(RenderName, Utility.ShiftlockRenderPriority, function(Delta)
	Connection = RunService.PreRender:Connect(function()
		if Paused then return end

		--local Elapsed = (os.clock() - StartTime)
		--local FOVFrame = math.ceil(Elapsed / FrameDuration)
		
		local FOVFrame = math.ceil((os.clock() - StartTime) / (1/60))

		if FOVFrame >= LastItem then
			return Clean()
		end
		
		CurrentCamera.FieldOfView = Folder[FOVFrame].Value + AdditionalFOV
	end)
	
	CurrentCamera.FieldOfView = Folder["0"].Value + AdditionalFOV;
	
	return Clean, function(Value : boolean)
		Paused = Value
	end
end

return FOV