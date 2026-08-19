local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Hornet.Sprint

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
			Job:Task(Animation:GetMarkerReachedSignal("Run"):Connect(function()
				local Velocity = Job:Task(VelocityUtil.Create(RootPart, "Hornet Sprint"))
				Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
				Velocity.Parent = RootPart

				local VelStrength = Instance.new("NumberValue")
				VelStrength.Value = 65
				VelStrength.Parent = Velocity

				Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function()
					Velocity.Velocity = RootPart.CFrame.LookVector * VelStrength.Value
				end)
				
				--TweenService:Create(VelStrength, TweenInfo.new(0.1, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {
				--	Value = 65
				--}):Play()				
				
				--Job:Task(function()
				--	Yuki_FOV.Set(70)
				--end)
				
				-- FOV Cam
				--CameraShake(2, 30, 0.01, 0.5, Vector3.one * 0.8)
				--Yuki_FOV.Tween(80, {0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In})

				Job:Task(Animation:GetMarkerReachedSignal("Stop"):Connect(function()
					TweenService:Create(VelStrength, TweenInfo.new(0.9, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {
						Value = 0
					}):Play()

					task.delay(0.9, Velocity.Destroy, Velocity)

					-- FOV Cam
					--Yuki_FOV.Tween(70, {0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
				end))
			end))
		end)
	end,
}

