local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local LocalPlayerGui = LocalPlayer.PlayerGui

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Client.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Global.Ultimate.Chara.Default

---------------------------------------------------------------------

local CameraShake = require( ReplicatedStorage.Client.Replication.Global.CameraShake )
local RunCameraRig = require( ReplicatedStorage.Client.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Client.Replication.Global.Yuki_FOV )

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )
local Job = require( ReplicatedStorage.Shared.Utilities.Job )

local AttributeListener = require( ReplicatedStorage.Client.Replication.Global.AttributeListener )

local TekrinnDialogue = require( ReplicatedStorage.Client.TekrinnDialogue )

---------------------------------------------------------------------

local Pat_Theme = require( ReplicatedStorage.Client.Replication.VFX.Chara.Pat_Theme )

return {
	OnUltimateStart = function(Model : Model, SkipIntro : boolean)
		local IsMainPlayer = (LocalPlayer.Character == Model)
		local Auras = require(ReplicatedStorage.Effects.Characters.Chara.Aura.Script)(Model)
		
		if SkipIntro then
			--local PlayAlt = math.random(1, 2) == 1

			--local Theme = Instance.new("Sound")
			--Theme.Name = "Chara_Theme"
			--Theme.SoundId = PlayAlt and "rbxassetid://98450691438882" or "rbxassetid://74426750731046"
			--Theme.Volume = 0
			--Theme.Looped = true
			--Theme.SoundGroup = SoundService.UltimateMusic
			--Theme.Parent = (IsMainPlayer and workspace or Model.Torso)
			--Theme:Play()

			--TweenService:Create(Theme, TweenInfo.new(0.25),
			--	{Volume = 0.75}
			--):Play()

			--local MainJob = AttributeListener.new(Model, "Ultimate", function()
			--	TweenService:Create(Theme, TweenInfo.new(0.5),
			--		{Volume = 0}
			--	):Play()

			--	task.delay(1, Theme.Destroy, Theme)
			--end)

			--local Listener = AttributeListener.GetReplicationFromSource(Model)

			--if Listener then
			--	MainJob:Task(Listener:GetAttributeChangedSignal("Ultimate_Mute"):Connect(function()
			--		TweenService:Create(Theme, TweenInfo.new(0.2),
			--			{Volume = Listener:GetAttribute("Ultimate_Mute") and 0 or 0.75}
			--		):Play()
			--	end))
			--end
			
			task.spawn(Pat_Theme, IsMainPlayer, math.random(1, 2) == 1, Model)
		end
		
		AttributeListener.new(Model, "Ultimate", function()
			for _, Aura in Auras do
				Aura.Enabled = false
			end
			
			task.delay(2, function()
				for _, Aura in Auras do
					Aura:Destroy()
				end
			end)
		end)
	end,
	
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Start)
		if (Retrieved == nil) then return end

		local RootPart = Retrieved.RootPart
		local Animation, AnimationJob = Retrieved.Animation, Retrieved.Job

		local TransitionJob = Job.Extend(AnimationJob)

		local IsMainPlayer = (LocalPlayer.Character == Model)
		
		local function CreateTaskDelay(Frame : number, Callback : () -> ())
			local Time = (Frame / 60)
			AnimationJob:Task(task.delay(Time, Callback))
		end

		task.spawn(Pat_Theme, IsMainPlayer, false, Model)
		
		EffectUtility.AddSFX(script.SFX, IsMainPlayer and workspace or Model.Torso, 0.5)
		
		do -- vfx

			local Heart = script.Heart:Clone()
			Heart.Weld.Part0 = Model.Torso
			Heart.Parent = Model

			AnimationJob:Task(Heart)

			local PlayerHighlight
			local HeartHighlight

			CreateTaskDelay(110, function() -- eye
				EffectUtility.Arc.CloneAndEmit(script.Assets.eye, Model.Head)
			end)

			CreateTaskDelay(896, function() -- torso
				local Torso = script.Assets.torso:Clone()
				Torso.Parent = Model.Torso
				EffectUtility.Arc.ToggleAttachment(Torso, true)

				TransitionJob:Task(function()
					EffectUtility.Arc.ToggleAttachment(Torso, false)
					task.delay(2, Torso.Destroy, Torso)
				end)
			end)

			CreateTaskDelay(1051, function()
				local Head = script.Assets.aura:Clone()
				Head.Parent = workspace.Visuals

				EffectUtility.Weld(Head, Model.Head)
				EffectUtility.Arc.ToggleAttachment(Head, true)

				TransitionJob:Task(function()
					EffectUtility.Arc.ToggleAttachment(Head, false)
					task.delay(2, Head.Destroy, Head)
				end)
			end)

			AnimationJob:Task(Animation:GetMarkerReachedSignal("transition"):Once(function()
				TransitionJob:Destroy()
			end))

			AnimationJob:Task(Animation:GetMarkerReachedSignal("heart_outline"):Connect(function()
				HeartHighlight = Instance.new("Highlight")
				HeartHighlight.FillColor = Color3.new(1, 0, 0)
				HeartHighlight.OutlineColor = Color3.new(1, 1, 1)
				HeartHighlight.OutlineTransparency = 1
				HeartHighlight.FillTransparency = 1
				HeartHighlight.Parent = Heart

				TweenService:Create(HeartHighlight, TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
					{OutlineTransparency = 0}
				):Play()
			end))

			AnimationJob:Task(Animation:GetMarkerReachedSignal("heart_fill"):Connect(function()
				TweenService:Create(HeartHighlight, TweenInfo.new(0.18333333333333332, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
					{FillTransparency = 0}
				):Play()
			end))
			
			AnimationJob:Task(Animation:GetMarkerReachedSignal("player_outline"):Connect(function()
				PlayerHighlight = Instance.new("Highlight")
				PlayerHighlight.FillTransparency = 1
				PlayerHighlight.OutlineTransparency = 1
				PlayerHighlight.OutlineColor = Color3.new(1, 1, 1)
				PlayerHighlight.Parent = Model

				TweenService:Create(PlayerHighlight, TweenInfo.new(0.6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
					{OutlineTransparency = 0}
				):Play()
			end))

			AnimationJob:Task(Animation:GetMarkerReachedSignal("highlights_fade"):Connect(function()
				local Info = TweenInfo.new(0.7, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

				local HeartTween = TweenService:Create(HeartHighlight, Info, {OutlineTransparency = 1, FillTransparency = 1})
				local PlayerTween = TweenService:Create(PlayerHighlight, Info, {OutlineTransparency = 1})

				HeartTween:Play()
				PlayerTween:Play()

				HeartTween.Completed:Once(function()
					HeartHighlight:Destroy()
				end)

				PlayerTween.Completed:Once(function()
					PlayerHighlight:Destroy()
				end)
			end))
		end
		
		if IsMainPlayer then
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
			LocalPlayerGui.Statistics.Enabled = false

			task.spawn(function()
				local IconModule = require(ReplicatedStorage.Packages.Icon)
				IconModule.setTopbarEnabled(false)
			end)
		
			TransitionJob:Task(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
				LocalPlayerGui.Statistics.Enabled = true

				task.spawn(function()
					local IconModule = require(ReplicatedStorage.Packages.Icon)
					IconModule.setTopbarEnabled(true)
				end)
			end)
			
			LocalPlayer:SetAttribute("CannotCameraShake", true)
			
			AnimationJob:Task(function()
				LocalPlayer:SetAttribute("CannotCameraShake", nil)
			end)

			local Camera = script.Camera:Clone()
			EffectUtility.Weld(Camera, RootPart)
			Camera.Parent = workspace.Visuals
			TransitionJob:Task(Camera)
			
			local CameraDisabled = false

			local CameraAnimation : AnimationTrack = Camera.Humanoid.Animator:LoadAnimation(Animations.Camera)
			CameraAnimation:Play(0)

			TransitionJob:Task(Yuki_FOV.AnimateWithMoonFile(ReplicatedStorage.FOVFiles["Awake"]))
			
			TransitionJob:Task(RunCameraRig(RootPart, Camera, nil, {
				--DontSupportCutsceneSetting = true,
				DontSaveCameraPosition = true,
				DontDoTransition = true,
				
			}, function(Value)
				CameraDisabled = not Value

				if not CameraDisabled then
					EffectUtility.Arc.EmitAttachment(Camera.camera["1"])
				end
			end))

			TransitionJob:Task(CameraAnimation.Stopped:Connect(function()
				Camera:Destroy()
			end))
			
			local ScreenCover = script.ScreenCover:Clone()
			ScreenCover.Enabled = true
			ScreenCover.Frame.BackgroundTransparency = 0
			ScreenCover.Parent = LocalPlayer.PlayerGui
			
			TransitionJob:Task(function()
				if (ScreenCover and ScreenCover.Parent ~= nil) then
					local Info = TweenInfo.new(1.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
					
					TweenService:Create(ScreenCover.Frame, Info,
						{BackgroundTransparency = 1}
					):Play()

					task.delay(Info.Time, ScreenCover.Destroy, ScreenCover)
				end
			end)

			AnimationJob:Task(task.delay(0.1, function()
				TweenService:Create(ScreenCover.Frame, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{BackgroundTransparency = 1}
				):Play()
			end))
			
			AnimationJob:Task(Animation:GetMarkerReachedSignal("end"):Once(function()
				CameraAnimation:AdjustSpeed(0)

				task.wait(0.5)

				for Index = 1, 2 do
					ScreenCover.Frame.BackgroundTransparency = 0

					task.wait(4 / 60)

					ScreenCover.Frame.BackgroundTransparency = 1

					task.wait(3 / 60)
				end

				ScreenCover.Frame.BackgroundTransparency = 0
			end))
			
			AnimationJob:Task(Animation:GetMarkerReachedSignal("screen_cover"):Connect(function(Parameter : string)
				if (Parameter == "true") then
					TweenService:Create(ScreenCover.Frame, TweenInfo.new(0.18333333333333332, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
						{BackgroundTransparency = 0}
					):Play()

				elseif (Parameter == "false") then
					
					if not CameraDisabled then
						Camera.letterboxbot.Transparency = 0
						Camera.letterboxtop.Transparency = 0
					end
					
					ScreenCover.Frame.BackgroundTransparency = 1
				end
			end))
			
			CreateTaskDelay(166, function() -- smack
				if CameraDisabled then return end
				
				EffectUtility.Arc.EmitAttachment(Camera.camera["2"])
			end)

			CreateTaskDelay(563, function() -- static
				if CameraDisabled then return end
				
				EffectUtility.Arc.EmitAttachment(Camera.camera["3"])
			end)
			
			do -- dialogue
				local Image = "85316557846229"
				local ExtraImageSize = UDim2.fromOffset(15, 15)

				local Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
					ColorSequenceKeypoint.new(0.25, Color3.fromRGB(181, 53, 53)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(109, 32, 32)),
					ColorSequenceKeypoint.new(0.75, Color3.fromRGB(181, 53, 53)),
					ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))
				})


				do
					-- SINCE WHEN WERE YOU THE ONE IN CONTROL?

					CreateTaskDelay(212, function()
						TekrinnDialogue.Speak(Model, 

							{
								Text = "Since,",
								Image = Image,
								ExtraImageSize = UDim2.fromOffset(15, 15),
								TextStrokeColor = Color3.new(0, 0, 0),
								Color = Color,
								Shake = {
									Lifetime = 0.5,
									Enabled = true,
									Intensity = 1.5,
								},
								HigherUp = true,
								TypeSpeed = 0.05,
							}, 

							{
								StrokeColor = Color3.new(0, 0, 0),
								Color = Color,
							}, 

							3
						)
					end)

					CreateTaskDelay(247, function()
						TekrinnDialogue.Speak(Model, 

							{
								Text = "WHEN",
								Image = Image,
								ExtraImageSize = UDim2.fromOffset(15, 15),
								TextStrokeColor = Color3.new(0, 0, 0),
								Color = Color,
								Shake = {
									Lifetime = 0.5,
									Enabled = true,
									Intensity = 1.5,
								},
								HigherUp = true,
								TypeSpeed = 0.05,
							}, 

							{
								StrokeColor = Color3.new(0, 0, 0),
								Color = Color,
							}, 

							3
						)
					end)

					CreateTaskDelay(282, function()
						TekrinnDialogue.Speak(Model, 

							{
								Text = "Were you the one in control??",
								Image = Image,
								ExtraImageSize = UDim2.fromOffset(15, 15),
								TextStrokeColor = Color3.new(0, 0, 0),
								Color = Color,
								Shake = {
									Lifetime = 0.5,
									Enabled = true,
									Intensity = 1.5,
								},
								HigherUp = true,
								TypeSpeed = 0.05,
							}, 

							{
								StrokeColor = Color3.new(0, 0, 0),
								Color = Color,
							}, 

							3
						)
					end)
				end

				CreateTaskDelay(912, function()
					TekrinnDialogue.Speak(Model, 

						{
							Text = "Now, partner.",
							Image = Image,
							ExtraImageSize = UDim2.fromOffset(15, 15),
							TextStrokeColor = Color3.new(0, 0, 0),
							Color = Color,
							Shake = {
								Lifetime = 0.5,
								Enabled = true,
								Intensity = 1.5,
							},
							HigherUp = true,
							TypeSpeed = 0.065,
						}, 

						{
							StrokeColor = Color3.new(0, 0, 0),
							Color = Color,
						}, 

						1.5
					)
				end)

				CreateTaskDelay(1120, function()
					TekrinnDialogue.Speak(Model, 

						{
							Text = "Let us send this world back into the abyss.",
							Image = Image,
							ExtraImageSize = UDim2.fromOffset(15, 15),
							TextStrokeColor = Color3.new(0, 0, 0),
							Color = Color,
							Shake = {
								Lifetime = 0.5,
								Enabled = true,
								Intensity = 1.5,
							},
							HigherUp = true,
							TypeSpeed = 0.065,
						}, 

						{
							StrokeColor = Color3.new(0, 0, 0),
							Color = Color,
						}, 

						5
					)
				end)
			end
		end
	end,
}