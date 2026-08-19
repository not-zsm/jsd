local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Hornet["Dive Nail"]

---------------------------------------------------------------------

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local JobModule = require( ReplicatedStorage.Modules.Shared.Utilities.Job )
local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )
---------------------------------------------------------------------

return {
	Start = function(Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		local IsMainPlayer = (LocalPlayer.Character == Model)
		
		local IsPrimary = EffectUtility.SetPrimary({Model})
		
		IsPrimary(function()
			VelocityUtil.Clear(RootPart)
			
			Job:Task(Animation:GetMarkerReachedSignal("Dive"):Connect(function()
				local Velocity = Job:Task(VelocityUtil.Create(RootPart, "Dive Nail"))
				Velocity.MaxForce = Vector3.new(1, 1, 1) * 80000
				Velocity.Parent = RootPart

				local VelStrength = Instance.new("NumberValue")
				VelStrength.Value = 20
				VelStrength.Parent = Velocity

				TweenService:Create(VelStrength, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Value = 140
				}):Play()
				
				Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function()
					Velocity.Velocity = (RootPart.CFrame.LookVector * VelStrength.Value) + Vector3.new(0, -VelStrength.Value, 0)
				end)

				task.delay(3, Velocity.Destroy, Velocity)
			end))
		end)
	end,
	
	HitGround = function(Model)
		VelocityUtil.Clear(Model.HumanoidRootPart)
	end,
	
	Hit = function(Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Hit)
		if (Retrieved == nil) then return end

		local Torso, RootPart : BasePart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		local IsMainPlayer = (LocalPlayer.Character == Model)

		local IsPrimary = EffectUtility.SetPrimary({Model})

		IsPrimary(function()
			VelocityUtil.Clear(RootPart)
			RootPart.AssemblyLinearVelocity = Vector3.zero
			
			local Velocity = Job:Task(VelocityUtil.Create(RootPart, "Dive Nail 2"))
			Velocity.MaxForce = Vector3.new(1, 1, 1) * 80000
			Velocity.Parent = RootPart
			
			local VelStrength = 110

			Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function()
				Velocity.Velocity = (RootPart.CFrame.LookVector * VelStrength) + Vector3.new(0, VelStrength, 0)
			end)
			
			task.delay(0.02, Velocity.Destroy, Velocity)
		end)
	end,
}

