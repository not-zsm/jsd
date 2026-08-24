local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local LocalPlayerGui = LocalPlayer.PlayerGui

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local Animations = replicatedStorage.animations.Attacks.chara.Reset

local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )

local Yuki_FOV = require( replicatedStorage.modules.client.replication.Global.Yuki_FOV )
local RunCameraRig = require( replicatedStorage.modules.client.replication.Global.RunCameraRig )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local Job = require( replicatedStorage.modules.shared.Utilities.Job )

local TekrinnDialogue = require( replicatedStorage.modules.effect.tekrinnDialogue )

return {
	MiniExplosion = function(Position : Vector3)
		if LocalPlayer:DistanceFromCharacter(Position) <= 100 then
			CameraShake(3, 30, 0.01, 1.5, Vector3.one, Vector3.one * 0.5)
			Vignette(Color3.fromRGB(255, 0, 0), 0.5, 1)
		end

		local Attach = Instance.new("Attachment")
		Attach.WorldPosition = Position
		Attach.Parent = workspace.Terrain
		task.delay(6, Attach.Destroy, Attach)

		EffectUtility.AddSFX(script.SFX.Explosion.First, Attach)

		local VFX = script.Explosion.Enable:Clone()
		VFX:PivotTo(CFrame.new(Position) + Vector3.new(0, 10, 0))
		VFX.Parent = workspace.Visuals
		EffectUtility.ToggleForTime(VFX, true)
		task.delay(3, VFX.Destroy, VFX)
	end,
	
	Explosion = function(Position : Vector3)
		if LocalPlayer:DistanceFromCharacter(Position) <= 100 then
			CameraShake(6, 60, 0.01, 2, Vector3.one, Vector3.one * 0.5)
			Vignette(Color3.fromRGB(255, 0, 0), 0.5, 1)
		end
		
		local Attach = Instance.new("Attachment")
		Attach.WorldPosition = Position
		Attach.Parent = workspace.Terrain
		task.delay(6, Attach.Destroy, Attach)
		
		EffectUtility.AddSFX(script.SFX.Explosion.Second, Attach)
		EffectUtility.AddSFX(script.SFX.Explosion.Second_2, Attach)
		
		local VFX = script.Explosion.Boom:Clone()
		VFX:PivotTo(CFrame.new(Position) + Vector3.new(0, 10, 0))
		VFX.Parent = workspace.Visuals
		EffectUtility.Emit(VFX)
	end,
	
	Counter = function(Model : Model)
		local SFX = script.SFX.Main:Clone()
		SFX.Parent = workspace
		
		local MainJob = Job.new()
		MainJob:Task(SFX)
		
		local CF = CFrame.new(-20000, 0, 0)
		
		local Sky = script.Sky:Clone()
		Sky.Parent = Lighting
		MainJob:Task(Sky)
		
		do
			local Properties = {
				"Ambient",
				"Brightness",
				"ClockTime",
				"ColorShift_Top",
				"ColorShift_Bottom",
				"OutdoorAmbient",
			}
			
			local Previous = {}
			
			for _, Property in ipairs(Properties) do
				Previous[Property] = Lighting[Property]
			end
			
			Lighting.Ambient = Color3.fromRGB(70, 70, 70)
			Lighting.Brightness = 4.9
			Lighting.ClockTime = 14.5
			Lighting.ColorShift_Top = Color3.new(0, 0, 0)
			Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
			Lighting.OutdoorAmbient = Color3.fromRGB(197, 127, 127)
		
			MainJob:Task(function()
				for Property, Value in pairs(Previous) do
					Lighting[Property] = Value
				end
			end)
		end
		
		local Box = script.BlackBox:Clone()
		Box.CFrame = CF
		Box.Parent = workspace.Visuals
		MainJob:Task(Box)
		
		local ScreenCover = script.ScreenCover:Clone()
		ScreenCover.Enabled = true
		ScreenCover.Frame.BackgroundTransparency = 0
		ScreenCover.Parent = LocalPlayer.PlayerGui
		MainJob:Task(ScreenCover)

		local Videos = script.Videos:Clone()
		Videos.Name = "CharaVideos"
		Videos.Parent = LocalPlayerGui
		MainJob:Task(Videos)
		
		local Chara = script.chara:Clone()
		Chara:PivotTo(CF)
		Chara.Parent = workspace.Visuals
		MainJob:Task(Chara)
		
		local CharaHumanoid = Chara:WaitForChild("Humanoid")
		local CharaAnimator = CharaHumanoid:WaitForChild("Animator")
		local CharaAnimation = CharaAnimator:LoadAnimation(Animations.Start)

		SFX:Play()

		if not SFX.IsLoaded then
			SFX.Loaded:Wait()
		end
		
		TweenService:Create(ScreenCover.Frame, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1}
		):Play()
		
		local function CreateTaskDelay(Frame : number, Callback : () -> ())
			local Time = (Frame / 60)
			MainJob:Task(task.delay(Time, Callback))
		end

		do
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
			LocalPlayerGui.Statistics.Enabled = false

			task.spawn(function()
				local IconModule = require(replicatedStorage.Packages.Icon)
				IconModule.setTopbarEnabled(false)
			end)

			MainJob:Task(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
				LocalPlayerGui.Statistics.Enabled = true

				task.spawn(function()
					local IconModule = require(replicatedStorage.Packages.Icon)
					IconModule.setTopbarEnabled(true)
				end)
			end)
			
			LocalPlayer:SetAttribute("CannotCameraShake", true)

			MainJob:Task(function()
				LocalPlayer:SetAttribute("CannotCameraShake", nil)
			end)
			
			CreateTaskDelay(710, function()
				LocalPlayer:SetAttribute("CannotCameraShake", nil)
			end)

			local Camera = script.Camera:Clone()
			Camera:PivotTo(Chara:GetPivot() - Vector3.yAxis * 3)
			Camera.Parent = workspace.Visuals

			MainJob:Task(Camera)

			MainJob:Task(RunCameraRig(CharaHumanoid.RootPart, Camera, CFrame.new(0, -3, 0), 
				{DontDoTransition = true, DontSupportCutsceneSetting = true})
			)

			MainJob:Task(Yuki_FOV.AnimateWithMoonFile(script.FOV))
			Camera.Humanoid.Animator:LoadAnimation(Animations.Camera):Play(0)
		end
	
		do
			local Image = "85316557846229"
			local ExtraImageSize = UDim2.fromOffset(15, 15)

			local Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
				ColorSequenceKeypoint.new(0.25, Color3.fromRGB(181, 53, 53)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(109, 32, 32)),
				ColorSequenceKeypoint.new(0.75, Color3.fromRGB(181, 53, 53)),
				ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))
			})

			local DialogueOwner = Instance.new("Configuration")
			DialogueOwner.Name = "chara"
			MainJob:Task(DialogueOwner)

			local function Dialogue(Text : string, Duration : number)
				TekrinnDialogue.Speak(DialogueOwner, 

					{
						Text = Text,
						Image = Image,
						ExtraImageSize = UDim2.fromOffset(15, 15),
						TextStrokeColor = Color3.new(0, 0, 0),
						Color = Color,
						Shake = {
							Lifetime = 0.5,
							Enabled = true,
							Intensity = 1.5,
						},
						--HigherUp = true,
						TypeSpeed = 0.05,
					}, 

					{
						StrokeColor = Color3.new(0, 0, 0),
						Color = Color,
					}, 

					Duration
				)
			end

			Dialogue("You know what we have to do...", 5)

			CreateTaskDelay(160, function()
				Dialogue("Partner.?", 2)
			end)

			CreateTaskDelay(284, function()
				Dialogue("It was fun while it lasted.", 2)
			end)
		end
		
		MainJob:Task(CharaAnimation:GetMarkerReachedSignal("end"):Connect(function()
			Videos.Frame.BackgroundTransparency = 0
		end))
		
		CreateTaskDelay(561, function()
			Chara.Head.Face.Decal.Transparency = 1
			Chara.scaryface.Transparency = 0
		end)

		CreateTaskDelay(640, function()
			Videos.Frame.Slash.Visible = true
			Videos.Frame.Slash:Play()

			Videos.Frame.Slash.Ended:Once(function()
				Videos.Frame.Slash.Visible = false
			end)
		end)
		
		CreateTaskDelay(710, function()
			Videos.Frame.Slash.Visible = false
			Videos.Frame.Slash:Pause()

			Videos.Frame["999"].Visible = true
			Videos.Frame["999"]:Play()

			Videos.Frame["999"].Ended:Once(function()
				Videos.Frame["999"].Visible = false
			end)
		end)
		
		CharaAnimation:Play(0)

		task.wait(780 / 60)
		
		MainJob:Destroy()
	end,
	
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end
		
		local Job = Retrieved.Job
		local Animation = Retrieved.Animation
		
		local Highlight = Instance.new("Highlight")
		Highlight.OutlineColor = Color3.new(1, 0, 0)
		Highlight.OutlineTransparency = 0
		Highlight.FillTransparency = 1
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.Parent = Model
		
		Job:Task(Highlight)
		
		Job:Task(Animation:GetMarkerReachedSignal("counter"):Connect(function(Parameter : string)
			if (Parameter == "false") then
				Highlight.OutlineTransparency = 1
			end
		end))
		
		--Job:Task(Animation:GetMarkerReachedSignal("counter"):Connect(function(Parameter : string)
		--	if (Parameter == "true") then
		--		TweenService:Create(Highlight, TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		--			{OutlineTransparency = 0}
		--		):Play()
				
		--		do
		--			TweenService:Create(Highlight, TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, 0, true),
		--				{FillTransparency = 0}
		--			):Play()
		--		end
		--	else
		--		TweenService:Create(Highlight, TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
		--			{OutlineTransparency = 1}
		--		):Play()
		--	end
		--end))
	end,
}