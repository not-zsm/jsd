local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )
local Vignette = require( ReplicatedStorage.Client.Replication.Global.Vignette )

local Job = require( ReplicatedStorage.Shared.Utilities.Job )

local LocalPlayer = Players.LocalPlayer

local Assets = script.Parent

return function(Model : Model, RemoteHandler : RemoteEvent, Key : Enum.KeyCode, MainJob : Job.object, Settings : {})
	local Settings = Settings or {}

	local UI = Assets.QTE.UI:Clone()
	
	if Settings.UI_Size then
		UI.Bar.Size = Settings.UI_Size
	end
	
	UI.Parent = LocalPlayer.PlayerGui

	do
		TweenService:Create(UI.Bar, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ImageTransparency = 0, BackgroundTransparency = 0}
		):Play()

		TweenService:Create(UI.Bar.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{Transparency = 0}
		):Play()

		TweenService:Create(UI.Bar.Line, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{BackgroundTransparency = 0}
		):Play()

		TweenService:Create(UI.Bar.Line.UIStroke, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{Transparency = 0}
		):Play()
	end
	
	local AttackTime = Settings.AttackTime or Utility.Seed:NextNumber(0.7, 1)
	local MinRange = Settings.MinRange or (AttackTime / 2.2)
	local MaxRange = Settings.MaxRange or (AttackTime / 1.8)

	local Start = time()

	local LineTween = TweenService:Create(UI.Bar.Line, TweenInfo.new(AttackTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{Position = UDim2.fromScale(1, 0.489)}
	)

	local function InRange() : boolean
		local Elapsed = (time() - Start)

		return 
			(Elapsed > MinRange) and
			(Elapsed < MaxRange)
	end

	local InputJob = Job.Extend(MainJob)
	
	UI.Destroying:Once(function()
		InputJob:Destroy()
	end)

	local function Trigger()
		InputJob:Destroy()
		LineTween:Pause()
		
		if (UI == nil or UI.Parent == nil) then 
			return
		end

		local WasInRange = InRange()

		if WasInRange then
			TweenService:Create(UI.Bar, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true),
				{Size = UI.Bar.Size + UDim2.fromScale(0.0085, 0.0085)}
			):Play()

			Vignette(Color3.fromRGB(0, 255, 0), 0.75, 0.15)
			SoundService:PlayLocalSound(Assets.QTE.UI_SFX.Success)

			UI.Bar.Line.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		else
			Vignette(Color3.fromRGB(255, 0, 0), 0.75, 0.15)
			SoundService:PlayLocalSound(Assets.QTE.UI_SFX.Miss)

			UI.Bar.Line.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		end

		UI.Bar.Line.Size += UDim2.fromScale(0.01, 0.1)

		TweenService:Create(UI.Bar.Line, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{BackgroundTransparency = 1, Size = UDim2.fromScale(0, 0)}
		):Play()

		TweenService:Create(UI.Bar.Line.UIStroke, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{Transparency = 1}
		):Play()

		if Settings.RemoteFire then
			task.spawn(Settings.RemoteFire, WasInRange)
		else
			RemoteHandler:FireServer(WasInRange)
		end
	end

	InputJob:Task(UserInputService.InputBegan:Connect(function(Input)
		if (Input.KeyCode == Utility.KeyboardToControllerInputs[Key]) or (Input.KeyCode == Key) then
			Trigger()
		end
	end))

	InputJob:Task(UI.Bar.Hitbox.MouseButton1Click:Connect(Trigger))

	LineTween:Play()
	
	local function Clean_UI()
		if (UI == nil or UI.Parent == nil) then
			return
		end
		
		local GoTween = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

		TweenService:Create(UI.Bar, GoTween, {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
		TweenService:Create(UI.Bar.UIStroke, GoTween, {Transparency = 1}):Play()
		TweenService:Create(UI.Bar.Line, GoTween, {BackgroundTransparency = 1}):Play()
		TweenService:Create(UI.Bar.Line.UIStroke, GoTween, {Transparency = 1}):Play()

		task.delay(GoTween.Time, UI.Destroy, UI)
	end

	MainJob:Task(Clean_UI)

	SoundService:PlayLocalSound(Assets.QTE.UI_SFX.Appear)
	
	return Clean_UI
end