local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Powers["Plasmatic Throw"]

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
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

local Effects = script.Assets

local BugoVFX = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.Bugo )
local Flashbang = require( ReplicatedStorage.Modules.Player.Replication.Global.Flashbang )

local quickutil = require( script.quickutil )

---------------------------------------------------------------------

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		local IsMainPlayer = (LocalPlayer.Character == Model)
		
		Job:Task(EffectUtility.AddSFX(script.Windup, Torso, 0.5))
		
		local WeakLight = Job:Task(Effects.weaklight:Clone())
		WeakLight.Weld.Part0 = Model["Right Arm"]
		WeakLight.Parent = workspace.Visuals

		local Charge = Job:Task(Effects.lightning:Clone())
		Charge.Weld.Part0 = Model["Right Arm"]
		Charge.Parent = workspace.Visuals
		
		local LoopCoroutine
		
		Job:Task(Animation:GetMarkerReachedSignal("Charge"):Connect(function(Parameter)
			if Parameter == "1" then
				if IsMainPlayer then
					Vignette(Color3.new(0.482353, 0.0313725, 1), 0.9, 2)
					CameraShake(2, 5, 0.01, 0.2, Vector3.one * 0.8)
				end
				
				EffectUtility.Toggle(WeakLight, true)
			else
				EffectUtility.Toggle(WeakLight, false)
				EffectUtility.Toggle(Charge, true)
				
				EffectUtility.CloneAndEmit(Effects.powerup, Model["Right Arm"])
				EffectUtility.CloneAndEmit(Effects.charge, RootPart)
				
				BugoVFX(Effects.ChargeMesh, RootPart)
				
				quickutil:interact(WeakLight, "PointLight", "Brightness", 4)
				quickutil:tween_descendant(WeakLight, "PointLight", 1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Brightness = 0})
				
				local Beams = Job:Task(Effects.Beams:Clone())
				Beams.Parent = RootPart
				
				quickutil:tween_single(Beams, 1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {["CFrame"] = Beams.CFrame * CFrame.Angles(0, math.rad(-180), 0)}, true)
				quickutil:tween_descendant(Beams, "Beam", .7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Width0 = 0, Width1 = 0}, true)
				
				--
				
				if EffectUtility.Distance_Close(Model) then
					CameraShake(3, 9, 0.01, 0.2, Vector3.one * 0.8)
				end
				
				if IsMainPlayer then
					Yuki_FOV.Tween(75, {0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.In})
					Job:Task(function()
						Yuki_FOV.Set(70)
					end)
					
					LoopCoroutine = coroutine.create(function()
						while true do
							Vignette(Color3.new(0.482353, 0.0313725, 1), 0.85, 2)
							CameraShake(1, 12, 0.05, 0.1, Vector3.one * 0.8)

							task.wait(0.1)
						end
					end)

					Job:Task(LoopCoroutine)
					task.spawn(LoopCoroutine)
				end
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("Throw"):Connect(function()
			EffectUtility.Toggle(Charge, false)
			EffectUtility.CloneAndEmit(Effects.Throw, RootPart)
			BugoVFX(Effects.ThrowMesh, RootPart)
			
			if LoopCoroutine then
				task.cancel(LoopCoroutine)
			end
			
			if EffectUtility.Distance_Close(Model) then
				CameraShake(7, 20, 0.015, 0.3, Vector3.one * 0.8)
				
				if not IsMainPlayer then
					Vignette(Color3.new(0.482353, 0.0313725, 1), 0.9, 2)
				end
			end
			
			if IsMainPlayer then
				-- Velocity
				local Velocity = Job:Task(VelocityUtil.Create(RootPart, "Plasmatic Throw"))
				Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
				Velocity.Parent = RootPart

				local VelStrength = Instance.new("NumberValue")
				VelStrength.Value = 50
				VelStrength.Parent = Velocity

				TweenService:Create(VelStrength, TweenInfo.new(0.7, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {
					Value = 0
				}):Play()

				Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function()
					Velocity.Velocity = RootPart.CFrame.LookVector * VelStrength.Value
				end)

				task.delay(2, Velocity.Destroy, Velocity)
				
				-- VFX
				Yuki_FOV.Tween(70, {0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
				Vignette(Color3.new(0.482353, 0.0313725, 1), 0.75, 3)
			end
		end))
	end,
	
	Hit = function(HitPosition : Position)
		local HitEffect = Effects.Hit:Clone()
		HitEffect.WorldPosition = HitPosition
		HitEffect.Parent = workspace.Terrain
		
		EffectUtility.AddSFX(script.Explode, HitEffect, 0.2)
		
		EffectUtility.EmitAttachment(HitEffect, true)
		
		local Distance = LocalPlayer:DistanceFromCharacter(HitPosition)
		if Distance < 50 then
			CameraShake(((50 - Distance) / 10), 20, 0.05, 0.4, Vector3.one * 0.9, Vector3.one * 0.4)
			Vignette(Color3.new(0.482353, 0.0313725, 1), 0.8, 2)
		end
		
		task.delay(3, HitEffect.Destroy, HitEffect)
	end,
	
	HitPlayer = function(RootPart : BasePart)
		local Effect = EffectUtility.CloneAndToggle(Effects.HitPlayer, RootPart, true)
		task.delay(0.6, EffectUtility.Toggle, Effect, false)
		task.delay(1.5, Effect.Destroy, Effect)
	end,
}