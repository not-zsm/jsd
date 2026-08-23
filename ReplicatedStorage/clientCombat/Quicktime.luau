local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local UserInputService = game:GetService("UserInputService")
local contextActionService = game:GetService("ContextActionService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "QuicktimeUI"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer.PlayerGui

local EventService = require(replicatedStorage.modules.shared.Utilities.EventService)
local Job = require(replicatedStorage.modules.shared.Utilities.Job)

local SFX = script.SFX

type object = {
	Job : Job.object,

	StartTime : number,

	StartRange : number,
	EndRange : number,

	UI : typeof(script.PromptHolder),
	Button : typeof(script.PromptHolder.BG),

	Key : Enum.KeyCode,
	OnPressed : EventService.object,

	Active : boolean,
}

local FadeProps = {
	Frame = "BackgroundTransparency",
	ImageLabel = "ImageTransparency",
	TextLabel = "TextTransparency",
	UIStroke = "Transparency",
	ImageButton = "BackgroundTransparency"
}

local QTEID = 0

local QuicktimeHandler = {}
QuicktimeHandler.__index = QuicktimeHandler

function QuicktimeHandler.new(Key : Enum.KeyCode, ControllerKey : Enum.KeyCode, Range : NumberRange): object & typeof(object)
	local self = setmetatable({}, QuicktimeHandler) :: object & typeof(object)

	self.Job = Job.new()

	self.StartTime = time()

	self.StartRange = Range.Min
	self.StopRange = Range.Max

	self.UI = script.PromptHolder:Clone()
	
	self.Job:Task(function()
		task.delay(1, self.UI.Destroy, self.UI)
	end)
	
	self.Button = self.UI.BG

	self.Key = Key
	self.ControllerKey = ControllerKey
	
	self.OnPressed = self.Job:Task(EventService.new())

	self.Active = true

	self.OnPressed:Connect(function()
		if not self.Active then return end

		if self.IndicatorTween then
			self.IndicatorTween:Cancel()
			self.IndicatorTween = nil
		end

		do
			self.IsInRange = self:InRange()

			if self.IsInRange then
				self:Complete()
			else
				self:Fail()
			end

			network.quicktimeInput.send(self.IsInRange)
		end
	end)

	self.Job:Task(task.delay(Range.Max, function()
		if not self.IsInRange then
			self:Fail()
		end
	end))

	self.UI.Position = UDim2.fromScale(
		Random.new():NextNumber(0.2, 0.8),
		Random.new():NextNumber(0.2, 0.8)
	)

	self:FadeUI_In()
	self:Bind()
	
	return self
end

function QuicktimeHandler.Complete(self : object)
	TweenService:Create(self.Button, TweenInfo.new(0.15), 
		{BackgroundColor3 = Color3.new(0.0784314, 0.454902, 0.172549)}
	):Play()

	SoundService:PlayLocalSound(SFX.Complete)

	self:BlinkUI(0.15, 0.2)
	self:FadeUI_Out(0.5)
end

function QuicktimeHandler.Fail(self : object)
	TweenService:Create(self.Button, TweenInfo.new(0.075, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), 
		{BackgroundColor3 = Color3.new(0.533333, 0.105882, 0.113725)}
	):Play()

	SoundService:PlayLocalSound(SFX.Fail)

	self:FadeUI_Out(0.2)
end

function QuicktimeHandler.BlinkUI(self : object, Size : number, Fade : number)
	local OriginalSize = self.Button.Size
	self.Button.Size += UDim2.fromScale(Size, Size)

	TweenService:Create(self.Button, TweenInfo.new(Fade, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), 
		{Size = OriginalSize}
	):Play()
end

function QuicktimeHandler.ConvertKeyForComfortableName(self : object)
	local Key = self.Key
	local Name = ""

	if Key == Enum.UserInputType.MouseButton1 then
		Name = "M1"

	elseif Key == Enum.UserInputType.MouseButton2 then
		Name = "M2"
	else
		Name = Key.Name
	end

	return Name
end

function QuicktimeHandler.FadeUI_In(self : object)
	if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
		self.Button.Key.Text = self.ControllerKey.Name:sub(7)
	else
		self.Button.Key.Text = self:ConvertKeyForComfortableName()
	end
	
	self.UI.Parent = ScreenGui

	for _, Object in ipairs(self.UI:GetDescendants()) do
		local HasClassProps = FadeProps[Object.ClassName]

		if HasClassProps then
			TweenService:Create(Object, TweenInfo.new(0.3), 
				{[HasClassProps] = 0}
			):Play()
		end
	end
	
	SoundService:PlayLocalSound(SFX.Appear)

	self:BlinkUI(0.3, 0.15)

	self.IndicatorTween = TweenService:Create(self.UI.Indicator, TweenInfo.new(self.StartRange * 1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), 
		{ Size = UDim2.fromScale(1.35, 1.35) }
	)

	self.IndicatorTween:Play()
end

function QuicktimeHandler.FadeUI_Out(self : object, Time : number)
	Time = Time or 0.3
	
	self.Active = false

	for _, Object in ipairs(self.UI:GetDescendants()) do
		local HasClassProps = FadeProps[Object.ClassName]

		if HasClassProps then
			TweenService:Create(Object, TweenInfo.new(Time), 
				{[HasClassProps] = 1}
			):Play()
		end
	end
	
	self:Destroy()
end

function QuicktimeHandler.InRange(self : object) : boolean
	local Elapsed = (time() - self.StartTime)

	return 
		(Elapsed >= self.StartRange) and
		(Elapsed <= self.StopRange)
end

function QuicktimeHandler.Bind(self : object)
	if not UserInputService.TouchEnabled then
		QTEID += 1

		local ID = tostring(QTEID)

		contextActionService:BindActionAtPriority(ID, function(_, State : Enum.UserInputState)
			if State == Enum.UserInputState.Begin then
				self.OnPressed:Fire()
			end
			
			return Enum.ContextActionResult.Pass
			
		end, false, -QTEID, self.Key, self.ControllerKey)

		self.Job:Task(function()
			contextActionService:UnbindAction(ID)
		end)
	else
		self.Button.MouseButton1Down:Connect(function()
			self.OnPressed:Fire()
			self.Button.Active = false
		end)
	end
end

function QuicktimeHandler.Destroy(self : object)
	self.Job:Destroy()
end

network.quicktime.listen(function(data)
	QuicktimeHandler.new(
		Enum.KeyCode[data.key],
		Enum.KeyCode[data.controllerKey] or Enum.UserInputType[data.controllerKey],
		NumberRange.new(data.rangeMin, data.rangeMax)
	)
end)

return QuicktimeHandler