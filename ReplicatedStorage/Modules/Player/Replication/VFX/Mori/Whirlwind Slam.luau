local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Mori["Whirlwind Slam"] -- put anim folder

---------------------------------------------------------------------

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local Afterimage = require( ReplicatedStorage.Modules.Player.Replication.Global.Afterimage )
local ATrainAfterimage = require( ReplicatedStorage.Modules.Player.Replication.Global.ATrainAfterimage )

local BugoVFX = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.Bugo )

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )

---------------------------------------------------------------------

local Jin_Color = Color3.fromRGB(84, 144, 255)
local VFX = script.VFX

return {
	Start = function(Model : Model)
		local Torso : BasePart = Model and Model:FindFirstChild("Torso")
		local Humanoid : Humanoid = Model and Model:FindFirstChild("Humanoid")
		local RootPart : BasePart = Model and Model:FindFirstChild("HumanoidRootPart")
		local Animator : Animator = Humanoid and Humanoid:FindFirstChild("Animator")

		local ImpactLandEvent = Model:WaitForChild("ImpactLand")

		local IsMainPlayer = (LocalPlayer.Character == Model)
		
		local Animation = Animator:LoadAnimation(Animations.Startup)
		local SlamAnimation = Animator:LoadAnimation(Animations.Slam)
		
		local MainJob = Job.new()
		local FallJob = Job.Extend(MainJob)
		
		SlamAnimation.Stopped:Once(function()
			MainJob:Destroy()
		end)
		
		ImpactLandEvent.Destroying:Once(function()
			Animation:Stop(0.15)
			SlamAnimation:Stop(0.15)
			MainJob:Destroy()
		end)
		
		local Wind = VFX.Wind:Clone()
		EffectUtility.Weld(Wind, Torso)
		Wind.Parent = workspace.Visuals
		MainJob:Task(Wind)
		
		local Trails = {}

		for _, Item in ipairs(VFX.In_Torso:GetChildren()) do
			local NewItem = Item:Clone()
			NewItem.Parent = Torso
			Trails[NewItem] = true
		end
		
		MainJob:Task(function()
			for Trail in Trails do
				EffectUtility.Toggle(Trail, false)
			end
			
			task.delay(3, function()
				for Trail in Trails do
					Trail:Destroy()
				end
				
				table.clear(Trails)
			end)
		end)
		
		MainJob:Task(EffectUtility.AddSFX(script.SFX.Windup, Torso, 0.3))
		
		FallJob:Task(Animation:GetMarkerReachedSignal("loopstart"):Once(function()
			Animation:AdjustSpeed(1.25)
		end))

		FallJob:Task(Animation:GetMarkerReachedSignal("loopend"):Connect(function()
			Animation.TimePosition = 0.8
		end))
		
		MainJob:Task(Animation:GetMarkerReachedSignal("loopend"):Once(function()
			while not FallJob.Destroyed do
				local CF = RootPart.CFrame * CFrame.new(0, -0.5, -1)

				local Velocity = math.max(1.5, RootPart.AssemblyLinearVelocity.Magnitude / 4)
				local Raycast = workspace:Raycast(CF.Position, -CF.UpVector * Velocity, Utility.VisualParams)

				if Raycast and Raycast.Instance.CanCollide then
					FallJob:Destroy()
					
					Animation:Stop(0.05)
					SlamAnimation:Play(0.05, 1, 1.2)
				end

				RunService.PreSimulation:Wait()
			end
		end))

		MainJob:Task(Animation:GetMarkerReachedSignal("jump"):Once(function()
			BugoVFX(VFX.JumpUp, RootPart)

			if EffectUtility.Distance_Close(Model) then
				CameraShake(2, 20, 0.01, 0.4, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Jin_Color, 0.75, 0.3)
			end
			
			if IsMainPlayer then
				local UpVelocity = Instance.new("LinearVelocity")
				UpVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
				UpVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
				UpVelocity.LineDirection = vector.create(0, 1, 0)
				UpVelocity.MaxForce = math.huge
				UpVelocity.Attachment0 = RootPart.RootAttachment
				UpVelocity.LineVelocity = 30
				UpVelocity.Parent = RootPart

				task.delay(0.4, UpVelocity.Destroy, UpVelocity)

				local UserBodyVelocity = VelocityUtil.Create(RootPart, "WhirlwindSlam")
				UserBodyVelocity.Velocity = RootPart.CFrame.LookVector
				UserBodyVelocity.MaxForce = vector.create(80_000, 0, 80_000)
				UserBodyVelocity.Parent = RootPart

				local NumberValue = Instance.new("NumberValue")
				NumberValue.Value = 60
				NumberValue.Parent = UserBodyVelocity

				MainJob:Task(NumberValue)

				FallJob:Task(function()
					TweenService:Create(NumberValue, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Value = 0
					}):Play()
				end)

				MainJob:Task(function()
					if UpVelocity then
						UpVelocity:Destroy()
					end

					if UserBodyVelocity then
						UserBodyVelocity:Destroy()
					end
				end)

				while (not MainJob.Destroyed and UserBodyVelocity.Parent ~= nil and RootPart.Parent ~= nil) do
					UserBodyVelocity.Velocity = RootPart.CFrame.LookVector * NumberValue.Value
					RunService.PreSimulation:Wait()
				end

				if UserBodyVelocity then
					UserBodyVelocity:Destroy()
				end
			end
		end))
		
		MainJob:Task(Animation:GetMarkerReachedSignal("spin"):Connect(function(Parameter : string)
			if (Parameter == "true") then
				EffectUtility.Toggle(Wind, true)
				FallJob:Task(EffectUtility.AddSFX(script.SFX.Loop, Torso, 0.5))

				for Trail in Trails do
					EffectUtility.Toggle(Trail, true)
				end
				
				if EffectUtility.Distance_Close(Model) then
					FallJob:Task(CameraShake(1.5, 15, 0.01, 0, Vector3.one * 0.8, Vector3.one * 0.3))
					FallJob:Task(task.defer(function()
						while true do
							Vignette(Jin_Color, 0.75, 0.25)
							task.wait(0.2)
						end
					end))
				end
			end
		end))

		MainJob:Task(SlamAnimation:GetMarkerReachedSignal("slam"):Once(function()
			
			BugoVFX(VFX.Slam, RootPart)

			if EffectUtility.Distance_Close(Model) then
				CameraShake(2, 15, 0.01, 0.5, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Jin_Color, 0.35, 0.4)
			end
			
			local Position = (RootPart.CFrame * CFrame.new(0, -2.64, -1.9)).Position
			local Direction = Vector3.yAxis * -5
			
			local Attachment = Instance.new("Attachment")
			Attachment.WorldPosition = Position
			Attachment.Parent = workspace.Terrain
			EffectUtility.AddSFX(script.SFX.Slam, Attachment)
			task.delay(3, Attachment.Destroy, Attachment)

			coroutine.wrap(RockHandler.Crater)(Position, Direction, {
				Amount = 7,
				Distance = 4.5,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = -5,
					Max = -5
				},

				Exposure = {
					Min = 0.5,
					Max = 0.7
				},

				BaseZ = 1.35,

				SizeMultiplier = 0.85,
			})

			coroutine.wrap(RockHandler.Crater)(Position, Direction, {
				Amount = 12,
				Distance = 5.5,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = 7,
					Max = -7
				},

				Exposure = {
					Min = 0.5,
					Max = 0.7
				},

				SizeMultiplier = 1.1,
			})

			coroutine.wrap(RockHandler.Rockst)(Position, Direction, {
				Count = 20,
				Size = {0.35, 0.9},
				Velocity = 40,
			})

			if IsMainPlayer then
				ImpactLandEvent:FireServer()
			end
		end))

		MainJob:Task(SlamAnimation:GetMarkerReachedSignal("spin"):Connect(function(Parameter : string)
			if (Parameter == "false") then
				EffectUtility.Toggle(Wind, false)
			end
		end))

		MainJob:Task(SlamAnimation:GetMarkerReachedSignal("remove_trail"):Connect(function()
			for Trail in Trails do
				EffectUtility.Toggle(Trail, false)
			end
		end))

		Animation:Play()
	end,
}