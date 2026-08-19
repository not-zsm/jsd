local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local CurrentCamera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local VFX = {}

local Assets = script.Assets

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

function VFX.Start(Model : Model, HitboxRange : number)
	if (Model == nil) then return end
	
	Model:SetAttribute("MuteUltimate", true)
	
	local Player = Players:GetPlayerFromCharacter(Model)
	local Humanoid = Model:WaitForChild(`Humanoid`) :: Humanoid
	local RootPart = Humanoid.RootPart or Model:WaitForChild(`HumanoidRootPart`) :: BasePart
	local Animator = Humanoid:FindFirstChildOfClass(`Animator`) :: Animator

	local Track = Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Gojo["Maximum Output - Purple"].User)
	Track:Play();
	
	local NewJob = Job.new()

	local function Fart()
		do -- Purple
			local Purple = Assets.RedBlue:Clone()
			Purple:PivotTo(RootPart.CFrame)
			Purple.Parent = workspace.Visuals

			EffectUtility.Weld(Purple, RootPart)
			NewJob:Task(Purple)

			local PurpleTrack = Purple.Controller.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Gojo["Maximum Output - Purple"].Purple)
			PurpleTrack:Play()

			Track:GetMarkerReachedSignal("Throw"):Once(function()
				Purple.Blue.Transparency = 0
				EffectUtility.Toggle(Purple.Blue, true)
			end)

			Track:GetMarkerReachedSignal("Shoot"):Once(function()
				Purple.Red.Transparency = 0
				EffectUtility.Toggle(Purple.Red, true)
			end)

			Track:GetMarkerReachedSignal("Slam"):Once(function()
				Purple:Destroy()
			end)
		end

		local SFXDelay = 0.3

		do -- CHARACTER VFX
			local RightArm : BasePart = Model:FindFirstChild("Right Arm")

			local BlueArm = Assets["Right Arm"]["1"]:Clone()
			local BlueEffect2 = Assets["Right Arm"]["2"]
			local BlueEffect3 = Assets["Right Arm"]["3"]

			local MiniPurpleEffect = Assets["HumanoidRootPart"]["11"]:Clone()
			local PurpleEffect = Assets["HumanoidRootPart"]["p2"]:Clone()

			Track:GetMarkerReachedSignal("RightArmVFXStage1"):Once(function()
				EffectUtility.EmitEffects(BlueEffect2, RightArm, nil, BlueEffect2.CFrame)

				BlueArm.Parent = RightArm
				EffectUtility.Toggle(BlueArm, true)
				
				NewJob:Task(BlueArm)
			end)

			Track:GetMarkerReachedSignal("Throw"):Once(function()
				EffectUtility.EmitEffects(BlueEffect3, RightArm, nil, BlueEffect3.CFrame)

				EffectUtility.Toggle(BlueArm, false)
				task.delay(1, BlueArm.Destroy, BlueArm)
			end)

			Track:GetMarkerReachedSignal("Shoot"):Once(function()
				EffectUtility.EmitEffects(Assets["HumanoidRootPart"]["2"], RootPart, nil, Assets["HumanoidRootPart"]["2"].CFrame)
			end)

			Track:GetMarkerReachedSignal("RedRootEnable"):Once(function()
				MiniPurpleEffect.Parent = RootPart
				EffectUtility.Toggle(MiniPurpleEffect, true)
				NewJob:Task(MiniPurpleEffect)
			end)

			Track:GetMarkerReachedSignal("Slam"):Once(function()
				EffectUtility.EmitEffects(Assets["HumanoidRootPart"]["p1"], RootPart, nil, Assets["HumanoidRootPart"]["p1"].CFrame)

				EffectUtility.Toggle(MiniPurpleEffect, false)
				task.delay(2, MiniPurpleEffect.Destroy, MiniPurpleEffect)

				PurpleEffect.Parent = RootPart
				EffectUtility.Toggle(PurpleEffect, true)
				NewJob:Task(PurpleEffect)
			end)

			Track:GetMarkerReachedSignal("Boom"):Once(function()
				EffectUtility.Toggle(PurpleEffect, false)
				task.delay(2, PurpleEffect.Destroy, PurpleEffect)

				EffectUtility.EmitEffects(Assets["HumanoidRootPart"]["p3"], RootPart, nil, Assets["HumanoidRootPart"]["p3"].CFrame)

				local Direction = Vector3.yAxis * -25

				coroutine.wrap(RockHandler.Crater)(RootPart.Position, Direction, {
					Amount = 137,
					Distance = HitboxRange - 5,

					LookAt = { -- Where the rocks face towards (y axis)
						Min = -350,
						Max = -350
					},

					Exposure = {
						Min = 0.6,
						Max = 0.8
					},

					BaseX = 5,
					SizeMultiplier = 3,
				})

				coroutine.wrap(RockHandler.Crater)(RootPart.Position, Direction, {
					Amount = 155,
					Distance = HitboxRange - 2,

					LookAt = { -- Where the rocks face towards (y axis)
						Min = -500,
						Max = 500
					},

					Exposure = {
						Min = 0.6,
						Max = 0.8
					},

					BaseX = 3,
					SizeMultiplier = 4,
				})

				coroutine.wrap(RockHandler.Crater)(RootPart.Position, Direction, {
					Amount = 150,
					Distance = HitboxRange,

					LookAt = { -- Where the rocks face towards (y axis)
						Min = -500,
						Max = 500
					},

					Exposure = {
						Min = 0.5,
						Max = 0.7
					},

					BaseX = 5,
					SizeMultiplier = 3.5,
				})
			end)
		end

		do -- CAMERA SHAKE
			Track:GetMarkerReachedSignal("Throw"):Once(function()
				if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 100 then
					CameraShake(2.5, 25, 0.1, 0.35)
				end
			end)

			Track:GetMarkerReachedSignal("Shoot"):Once(function()
				if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 100 then
					CameraShake(2.5, 25, 0.2, 0.35)
				end
			end)

			Track:GetMarkerReachedSignal("Boom"):Once(function()
				if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= HitboxRange then
					local Shake = CameraShake(3.5, 35, 0.2, 0)

					if Shake then
						task.delay(1.5, Shake.StartFadeOut, Shake, 0.5)
					end
				end
			end)
		end

		do -- color correction effect
			local CC = Instance.new("ColorCorrectionEffect")
			CC.Parent = Lighting

			if LocalPlayer == Players:GetPlayerFromCharacter(Model) then
				Track:GetMarkerReachedSignal("CCTheFirst"):Once(function()
					TweenService:Create(CC, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
						{Brightness = -5}
					):Play()
				end)

				Track:GetMarkerReachedSignal("RoomThing"):Once(function()
					TweenService:Create(CC, TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
						{Brightness = 0}
					):Play()
				end)
			end

			Track:GetMarkerReachedSignal("Boom"):Once(function()
				Track:Stop(2)

				if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= HitboxRange and not LocalPlayer:GetAttribute("Epileptic_Mode") then
					TweenService:Create(CC, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
						{Brightness = 5}
					):Play()

					task.wait(1.5) 

					TweenService:Create(CC, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
						{Brightness = 0}
					):Play()

					task.wait(0.65)
				end

				CC:Destroy()
			end)
		end

		if LocalPlayer == Players:GetPlayerFromCharacter(Model) then
			task.delay(SFXDelay, SoundService.PlayLocalSound, SoundService, Assets.SFX)
			SoundService:PlayLocalSound(Assets.Theme)

			local Offset = CFrame.new(0, -3, 0) * CFrame.Angles(0, math.pi, 0)	
			local CameraPaused = false

			local CamRig = ReplicatedStorage.Effects["Camera's"].MJJBA:Clone()
			CamRig:PivotTo(RootPart.CFrame * Offset)
			CamRig.Parent = workspace.Visuals

			EffectUtility.Weld(CamRig, RootPart, Offset)
			NewJob:Task(CamRig)

			CurrentCamera.CameraType = Enum.CameraType.Scriptable
			
			RunService:BindToRenderStep("cartidroppedchatfwweh", Enum.RenderPriority.Camera.Value + 3, function()
				if not CameraPaused then
					CurrentCamera.CFrame = CamRig.camera.CFrame
				end
			end)
			
			NewJob:Task(function()
				RunService:UnbindFromRenderStep("cartidroppedchatfwweh")
			end)

			local ImpactFrames : Frame = LocalPlayer.PlayerGui.ImpactFrames.GojoMaxPurple
			EffectUtility.ToggleImpactFrames(ImpactFrames, true)

			CamRig.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Gojo["Maximum Output - Purple"].Camera):Play(0)

			do -- IMPACT FRAMES
				for _, Stage in {"Shoot", "Slam", "Boom"} do
					Track:GetMarkerReachedSignal(Stage):Once(function()
						EffectUtility.ToggleImpactFrames(ImpactFrames, false)

						local FrameStage : Frame = LocalPlayer.PlayerGui.ImpactFrames.GojoMaxPurple[Stage]

						for _, Frame : ImageLabel in ipairs(FrameStage:GetDescendants()) do
							if Frame:IsA("ImageLabel") then
								Frame.Visible = true
							end
						end

						for Index = 1, #FrameStage:GetChildren(), 1 do
							task.wait(0.025)

							local Frame : ImageLabel = FrameStage[Index]
							Frame.Visible = false
						end
					end)
				end
			end

			do -- room thing
				local BlackBox = Assets.BLACKBOXCUTSCENE1:Clone()

				Track:GetMarkerReachedSignal("RoomThing"):Once(function()
					CameraPaused = true
					BlackBox.Parent = workspace.Terrain

					Yuki_FOV.Tween(50, {6})

					RunService:BindToRenderStep("BlackBox", Enum.RenderPriority.Camera.Value + 3, function()
						CurrentCamera.CFrame = BlackBox.CamPoint.CFrame
					end)

					TweenService:Create(BlackBox.Blue,
						TweenInfo.new(2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
						{CFrame = BlackBox.MoveBalls.CFrame}
					):Play()

					TweenService:Create(BlackBox.Red,
						TweenInfo.new(2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
						{CFrame = BlackBox.MoveBalls.CFrame}
					):Play()
				end)

				Track:GetMarkerReachedSignal("Slam"):Once(function()
					EffectUtility.Emit(BlackBox["MoveToo"], true)

					EffectUtility.Toggle(BlackBox.Red, false)
					EffectUtility.Toggle(BlackBox.Blue, false)

					BlackBox.Red.Transparency = 1
					BlackBox.Blue.Transparency = 1

					task.wait(0.25)

					RunService:UnbindFromRenderStep("BlackBox")
					BlackBox:Destroy()

					Yuki_FOV.Reset()
					CameraPaused = false
				end)
			end

			NewJob:Task(function()
				RunService:UnbindFromRenderStep("CutsceneCamera")
				CurrentCamera.CameraType = Enum.CameraType.Custom
				CamRig:Destroy()
			end)
		else
			task.delay(SFXDelay, function()
				local SFX = Assets.SFX:Clone()
				SFX.Parent = RootPart

				if not SFX.IsLoaded then
					SFX.Loaded:Once(function()
						SFX:Play()
						task.delay(SFX.TimeLength, SFX.Destroy, SFX)
					end)
				else
					SFX:Play()
					task.delay(SFX.TimeLength, SFX.Destroy, SFX)
				end
			end)

			local Theme = Assets.Theme:Clone()
			Theme.Parent = RootPart

			if not Theme.IsLoaded then
				Theme.Loaded:Once(function()
					Theme:Play()
					task.delay(Theme.TimeLength, Theme.Destroy, Theme)
				end)
			else
				Theme:Play()
				task.delay(Theme.TimeLength, Theme.Destroy, Theme)
			end
		end

		Track.Stopped:Wait()
		Yuki_FOV.Reset()
	end

	local MainThread = coroutine.create(function()
		local Success, Result = pcall(Fart)

		if not Success then
			return warn(Result)
		end
	end)

	if MainThread then
		coroutine.resume(MainThread)
	end

	AttributeListener.new(Player, "GojoMaxPurple", function()
		if MainThread and coroutine.status(MainThread) == "suspended" then
			coroutine.close(MainThread)
		end

		NewJob:Destroy()

		Track:Stop()
		Track:Destroy()
	end)
end

return VFX