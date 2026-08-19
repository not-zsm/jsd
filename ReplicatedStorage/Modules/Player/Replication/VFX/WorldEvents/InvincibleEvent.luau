local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------


local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.WorldEvents.InvincibleBoss

---------------------------------------------------------------------

local JobModule = require( ReplicatedStorage.Modules.Shared.Utilities.Job )
--local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Dialogue = require(ReplicatedStorage.Modules.TekrinnDialogue)
--local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

--local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )
--local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )
--local Indicator = require ( ReplicatedStorage.Packages.Indicator )
--local Signal = require(ReplicatedStorage.Modules.Shared.Utilities.EventService)

---------------------------------------------------------------------


-- local Ended = Signal.new()

local StrokeColor = Color3.new(0, 0, 0)
local NameColor = ColorSequence.new(Color3.new(0.780392, 0.156863, 0.156863), Color3.new(0.294118, 0, 0.00392157))
local MainColor = ColorSequence.new(Color3.new(1, 0, 0))

local function Speak(Model, Phrase : number)
	if Phrase == 1 then
		Dialogue.Speak(Model, 
			{
				Image = "101089066666765",
				Text = "Don't thank me.",
				TextStrokeColor = StrokeColor,
				Color = MainColor,
				Shake = {
					Lifetime = 0.5,
					Enabled = true,
					Intensity = 3,
				},
				HigherUp = true,
				TypeSpeed = 0.038,
			}, 

			{
				StrokeColor = StrokeColor,
				Color = NameColor,
			}, 

			3
		)
	else
		Dialogue.Speak(Model, 
			{
				Image = "101089066666765",
				Text = "Please don't thank me for that.",
				TextStrokeColor = StrokeColor,
				Color = MainColor,
				Shake = {
					Lifetime = 0.5,
					Enabled = true,
					Intensity = 3,
				},
				HigherUp = true,
				TypeSpeed = 0.0275,
			}, 

			{
				StrokeColor = StrokeColor,
				Color = NameColor,
			}, 

			3
		)
	end
end

return {
	Enter = function()
		local Character = LocalPlayer.Character
		local RootPart = Character.HumanoidRootPart

		local Map = workspace.Visuals.InvincibleMap
		local EntrancePortal = Map.EntrancePortal
		local ClonePortal = Map.ClonePortal

		RootPart.CFrame = CFrame.new(0, 2.997, -20000)

		local Animation : AnimationTrack = Character.Humanoid.Animator:LoadAnimation(Animations.User)
		local Job = JobModule.new()

		Job:Task(Animation.Stopped:Connect(function()
			Job:Destroy()
		end))
		
		-- Black Screen UI
		local BlackScreen = script.Assets.BlackScreen:Clone()
		BlackScreen.Parent = LocalPlayer.PlayerGui
		BlackScreen.Enabled = true

		--local Success, Result = pcall(Players.GetHumanoidDescriptionFromUserId, Players, LocalPlayer.UserId)

		-- Clone with Clothes rig
		local Clone = Job:Task(script.InvincibleClothesR6:Clone())

		-- Set Appearence
		Clone:PivotTo(RootPart.CFrame)

		task.delay(3, function()
			Clone.Humanoid:ApplyDescription(Character.Humanoid.HumanoidDescription)
		end)

		Clone.Parent = workspace.Visuals

		local CloneAnimation = Clone.Humanoid.Animator:LoadAnimation(Animations.ClothesMan)

		-- Setup Camera
		local Camera : Model = Job:Task(script.Assets.Camera:Clone())
		Camera:PivotTo(RootPart.CFrame)
		Camera.Parent = workspace.Visuals

		local CameraAnimation : AnimationTrack = Camera.AnimationController.Animator:LoadAnimation(Animations.Camera)

		Job:Task(CameraAnimation.Stopped:Connect(function()
			Camera:Destroy()
		end))
		
		EffectUtility.Toggle(EntrancePortal, true)
		
		task.wait(2)
		
		-- Start Animations
		Yuki_FOV.Set(50)
		
		CloneAnimation:Play(0)
		Animation:Play(0)
		CameraAnimation:Play(0)
		
		EffectUtility.AddSFX(script.Assets.EnterSFX, SoundService, 0.3)

		Job:Task(RunCameraRig(RootPart, Camera, nil, {
			DontDoTransition = true,
			DontSupportCutsceneSetting = true
		}))
		
		Job:Task(Animation:GetMarkerReachedSignal("Portal"):Connect(function(Parameter : String)
			if Parameter == "1" then
				EffectUtility.Toggle(EntrancePortal, false)
			else
				EffectUtility.Toggle(ClonePortal, true)
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("End"):Connect(function()
			BlackScreen.Enabled = true
		end))
		
		Job:Task(function()
			Yuki_FOV.Set(70)
			
			EffectUtility.Toggle(EntrancePortal, false)
			EffectUtility.Toggle(ClonePortal, false)
		end)
		
		BlackScreen.Enabled = false
	end,
	
	Exit = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model,
			Animations.PortalExit.User
		)

		if (Retrieved == nil) then return end
		
		local Ended = false

		local Animation = Retrieved.Animation
		local Job = Retrieved.Job

		local Humanoid = Retrieved.Humanoid
		local RootPart = Retrieved.RootPart
		
		-- Camera
		if LocalPlayer.Character == Model then
			EffectUtility.AddSFX(script.Assets.ExitSFX, SoundService, 0.3)

			Speak(Model, 1)

			task.delay(1.82, function()
				Speak(Model, 2)
			end)
			
			local Camera : Model = Job:Task(script.Assets.Camera:Clone())
			Camera:PivotTo(RootPart.CFrame)
			Camera.Parent = workspace.Visuals
			
			local CameraAnimation : AnimationTrack = Camera.AnimationController.Animator:LoadAnimation(Animations.PortalExit.Camera)
			
			Job:Task(CameraAnimation.Stopped:Connect(function()
				Camera:Destroy()
			end))
			
			Job:Task(CameraAnimation:GetMarkerReachedSignal("Start"):Connect(function()
				local BlackScreen = LocalPlayer.PlayerGui:FindFirstChild("BlackScreen")
				
				if BlackScreen then
					BlackScreen:Destroy()
				end
			end))
			
			-- incase somehow doesnt get marker
			Job:Task(function()
				Yuki_FOV.Tween(70, {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
				
				task.wait(0.05)
				
				local BlackScreen = LocalPlayer.PlayerGui:FindFirstChild("BlackScreen")
				if BlackScreen then
					BlackScreen:Destroy()
				end
			end)
			
			CameraAnimation:Play(0)
			
			Job:Task(RunCameraRig(RootPart, Camera, nil, {
				DontSaveCameraPosition = true,
				DontDoTransition = true,
				DontSupportCutsceneSetting = true
			}))

			Yuki_FOV.Set(50)
		else
			EffectUtility.AddSFX(script.Assets.ExitSFX, Model.HumanoidRootPart, 0.3)
		end
		
		-- Create Immortal's Head
		local ImmortalHead = script.Assets.ImmortalHead:Clone()
		ImmortalHead.Parent = Model
		ImmortalHead.Weld.Part0 = Model["Right Arm"]
		
		local BloodLoop = coroutine.create(function()
			while ImmortalHead and ImmortalHead.Parent do
				Blood.BloodRaysWithoutPreset(ImmortalHead.BloodAttachment, {
					Amount = Vector2.new(2, 4),
					Spread = Vector2.new(45, 45),

					Face = Enum.NormalId.Front,
				})

				task.wait(0.4)
			end
		end)
		
		task.delay(10, function()
			if ImmortalHead then
				Utility.CloseThreadSafe(BloodLoop)
				
				for _, Item in ipairs(ImmortalHead:GetChildren()) do
					if Item:IsA("BasePart") then
						TweenService:Create(Item, TweenInfo.new(3), {Transparency = 1}):Play()
					end
				end
				
				task.delay(3, ImmortalHead.Destroy, ImmortalHead)
			end
		end)
		
		coroutine.resume(BloodLoop)
		Job:Task(BloodLoop)
		
		Job:Task(Animation:GetMarkerReachedSignal("ThrowHead"):Connect(function()
			ImmortalHead.Weld:Destroy()
			ImmortalHead.AssemblyLinearVelocity = Vector3.new(15, 0, -18)
		end))
	end,
	
	--TogglePortal = function(Portal : Model, Value : Bolean, OpenEmit : Bolean)
	--	if not Portal then
	--		Portal:Wait()
	--	end
		
	--	EffectUtility.Toggle(Portal.VFX, Value)
		
	--	if OpenEmit then
	--		EffectUtility.Emit(Portal.OpenEmit)
	--	end
		
		
	--end,
}