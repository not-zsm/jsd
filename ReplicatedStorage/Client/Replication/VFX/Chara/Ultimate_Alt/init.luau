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
local Animations = ReplicatedStorage.Animations.Attacks.Global.Ultimate.Chara.Alt

---------------------------------------------------------------------

local CameraShake = require( ReplicatedStorage.Client.Replication.Global.CameraShake )
local RunCameraRig = require( ReplicatedStorage.Client.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Client.Replication.Global.Yuki_FOV )

local VelocityUtil = require( ReplicatedStorage.Shared.Game.Velocity.VelocityUtil )

local CharacterTransparency = require( ReplicatedStorage.Client.Replication.Global.CharacterTransparency )

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local ArcVFX = EffectUtility.Arc -- 💖

local VFXUtil = require( script.quickutil )

local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )
local Job = require( ReplicatedStorage.Shared.Utilities.Job )

local AttributeListener = require( ReplicatedStorage.Client.Replication.Global.AttributeListener )

local TekrinnDialogue = require( ReplicatedStorage.Client.TekrinnDialogue )

---------------------------------------------------------------------

local Pat_Theme = require( ReplicatedStorage.Client.Replication.VFX.Chara.Pat_Theme )

return {
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

		--task.spawn(function()
		--	local Theme = Instance.new("Sound")
		--	Theme.Name = "Chara_Theme"
		--	Theme.PlaybackRegionsEnabled = true
		--	Theme.PlaybackRegion = NumberRange.new(0.1, 60000)
		--	Theme.SoundId = "rbxassetid://113613695330573"
		--	Theme.Volume = 0
		--	Theme.Looped = true
		--	Theme.SoundGroup = SoundService.UltimateMusic
		--	Theme.Parent = (IsMainPlayer and workspace or Retrieved.Torso)
		--	Theme:Play()
			
		--	TweenService:Create(Theme, TweenInfo.new(0.25),
		--		{Volume = 0.75}
		--	):Play()
			
		--	local ThemeJob = AttributeListener.new(Model, "Ultimate", function()
		--		TweenService:Create(Theme, TweenInfo.new(0.5),
		--			{Volume = 0}
		--		):Play()

		--		task.delay(1, Theme.Destroy, Theme)
		--	end)

		--	local Listener = AttributeListener.GetReplicationFromSource(Model)

		--	if Listener then
		--		ThemeJob:Task(Listener:GetAttributeChangedSignal("Ultimate_Mute"):Connect(function()
		--			TweenService:Create(Theme, TweenInfo.new(0.2),
		--				{Volume = Listener:GetAttribute("Ultimate_Mute") and 0 or 0.75}
		--			):Play()
		--		end))
		--	end
		--end)
		
		task.spawn(Pat_Theme, IsMainPlayer, true, Model)
		
		task.delay(0.15, EffectUtility.AddSFX, script.SFX, IsMainPlayer and workspace or Model.Torso, 0.5)

		--task.spawn(function()
		--	while not AnimationJob.Destroyed do
		--		for _, Item in ipairs(Model:GetDescendants()) do
		--			if (Item:IsA("BasePart") and not Item:HasTag("RagdollCollider") and Item.Name ~= "HumanoidRootPart") or Item:IsA("Decal") then
		--				Item.Transparency = 0
		--			end
		--		end

		--		task.wait(0.1)
		--	end
		--end)
		
		CharacterTransparency(Model, 0)
		
		do -- vfx

			local Heart = script.Heart:Clone()
			Heart.Weld.Part0 = Model.HumanoidRootPart
			Heart.Parent = Model

			AnimationJob:Task(Heart)

			local PlayerHighlight
			local HeartHighlight

			local Spin1 = script.Assets.spin1:Clone()
			local Spin2 = script.Assets.spin2:Clone()
			local GroundSpin = script.Assets.groundspin:Clone()
			local Flare = script.Assets.flare:Clone()

			Spin1.Parent, Spin2.Parent, GroundSpin.Parent, Flare.Parent = workspace.Visuals, workspace.Visuals, workspace.Visuals, workspace.Visuals

			AnimationJob:Task(Spin1)
			AnimationJob:Task(Spin2)
			AnimationJob:Task(GroundSpin)

			AnimationJob:Task(function()
				VFXUtil:interact(Flare, "ParticleEmitter", "Enabled", false)
				task.delay(2, Flare.Destroy, Flare)
			end)

			AnimationJob:Task(Animation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
				if Parameter == "flare" then
					EffectUtility.Weld(Flare, Model.Head)
					VFXUtil:interact(Flare, "ParticleEmitter", "Enabled", true)

				elseif Parameter == "spin1" then
					EffectUtility.Weld(Spin1, Retrieved.Torso)
					EffectUtility.Weld(GroundSpin, Retrieved.Torso)

					VFXUtil:interact(Spin1, "ParticleEmitter", "Enabled", true)
					VFXUtil:interact(GroundSpin, "ParticleEmitter", "Enabled", true)

				elseif Parameter == "spin2" then
					VFXUtil:interact(Spin1, "ParticleEmitter", "Enabled", false)
					VFXUtil:interact(GroundSpin, "ParticleEmitter", "Enabled", false)
					VFXUtil:interact(Spin2, "ParticleEmitter", "Enabled", true)
				else
					if Parameter == "Ye" then
						VFXUtil:interact(Spin2, "ParticleEmitter", "Enabled", false)
					end

					local Effect = script.Assets:FindFirstChild(Parameter)

					if Effect then
						local NewEffect = Effect:Clone()
						NewEffect:PivotTo(RootPart.CFrame * Effect.CFrame)
						NewEffect.Parent = workspace.Visuals
						VFXUtil:emit(NewEffect)
					end
				end
			end))

			AnimationJob:Task(Animation:GetMarkerReachedSignal("heart_highlight"):Connect(function(Parameter : string)
				if Parameter == "true" then
					HeartHighlight = Instance.new("Highlight")
					HeartHighlight.FillColor = Color3.new(1, 0, 0)
					HeartHighlight.OutlineColor = Color3.new(1, 1, 1)
					HeartHighlight.OutlineTransparency = 1
					HeartHighlight.FillTransparency = 1
					HeartHighlight.Parent = Heart

					TweenService:Create(HeartHighlight, TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
						{FillTransparency = 0.111}
					):Play()
				else
					TweenService:Create(HeartHighlight, TweenInfo.new(0.08333333333333333, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
						{FillTransparency = 1}
					):Play()
				end
			end))

			AnimationJob:Task(Animation:GetMarkerReachedSignal("player_highlight"):Connect(function(Parameter : string)
				if Parameter == "true" then
					PlayerHighlight = Instance.new("Highlight")
					PlayerHighlight.FillTransparency = 1
					PlayerHighlight.OutlineTransparency = 1
					PlayerHighlight.OutlineColor = Color3.new(1, 1, 1)
					PlayerHighlight.Parent = Model

					TweenService:Create(PlayerHighlight, TweenInfo.new(0.16666666666666666, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
						{OutlineTransparency = 0}
					):Play()
				else
					TweenService:Create(PlayerHighlight, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
						{OutlineTransparency = 1}
					):Play()
				end
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
			
			do
				local Multiply = -50

				local Velocity = VelocityUtil.Create(RootPart, "I'mmm baaaaacckk!")
				Velocity.MaxForce = Vector3.new(1, 0, 1) * 100000
				Velocity.Parent = RootPart

				Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
					Velocity.Velocity = RootPart.CFrame.LookVector * Multiply
					
					if (Multiply < 0) then
						Multiply = math.clamp(Multiply + (Delta * 60) * 0.35, -65, 0)
					else
						return Velocity:Destroy()
					end
				end)

				AnimationJob:Task(Velocity)
			end

			local Camera = script.Camera:Clone()
			Camera.Parent = workspace.Visuals
			TransitionJob:Task(Camera)

			local CameraAnimation : AnimationTrack = Camera.Humanoid.Animator:LoadAnimation(Animations.Camera)
			
			EffectUtility.Weld(Camera, RootPart)
			CameraAnimation:Play(0)

			TransitionJob:Task(RunCameraRig(RootPart, Camera, nil, {
				--DontSupportCutsceneSetting = true,
				--DontSaveCameraPosition = true,
				DontDoTransition = true
			}))

			TransitionJob:Task(CameraAnimation.Stopped:Connect(function()
				Camera:Destroy()
			end))
			
			TransitionJob:Task(Animation:GetMarkerReachedSignal("pause"):Connect(function()
				CameraAnimation:AdjustSpeed(0)
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

				CreateTaskDelay(375, function()
					TekrinnDialogue.Speak(Model, 

						{
							Text = "Imm...",
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

						4
					)
				end)

				CreateTaskDelay(425, function()
					TekrinnDialogue.Speak(Model, 

						{
							Text = "Baaaaaaacck!~",
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

						2
					)

					task.wait(1.25)

					TweenService:Create(ScreenCover.Frame, TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
						{BackgroundTransparency = 0}
					):Play()
				end)
			end
		end
	end,
}