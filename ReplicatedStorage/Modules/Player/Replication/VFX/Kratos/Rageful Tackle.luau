local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Kratos["Rageful Tackle"]

---------------------------------------------------------------------

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

---------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )

---------------------------------------------------------------------

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local Job, Animation = Retrieved.Job, Retrieved.Animation
		local RootPart = Retrieved.RootPart

		local RoarVFX = Job:Task(script.Holder.Roar:Clone())
		RoarVFX.Parent = RootPart

		local RushVFX = Job:Task(script.Holder.Rush:Clone())
		RushVFX.Parent = RootPart

		local RoarShake = nil
		local RunShake = nil
		local Multiply = 0
		local Max = 120

		if LocalPlayer == Players:GetPlayerFromCharacter(Model) then
			Yuki_FOV.Tween(50, {0.75})
		end
		
		Job:Task(function()
			Yuki_FOV.Tween(70, {0.25})
		end)

		Job:Task(Animation:GetMarkerReachedSignal("roar"):Once(function() 
			local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)

			EffectUtility.Toggle(RoarVFX, true)

			if LocalPlayer == Players:GetPlayerFromCharacter(Model) then
				Yuki_FOV.Tween(95, {0.25})
			end

			if (Distance < 15) then 
				RoarShake = CameraShake(3, 15, 0.01, 0, Vector3.one * 0.8, Vector3.one * 0.5)
				Vignette(Color3.fromRGB(255, 81, 0), 0.2, 2)
				
				Job:Task(function()
					if (RoarShake ~= nil) then
						RoarShake:StartFadeOut(0.25)
					end
				end)
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("endroar"):Once(function() 
			EffectUtility.Toggle(RoarVFX, false)

			if (RoarShake ~= nil) then
				RoarShake:StartFadeOut(0.25)
			end

			task.delay(2, RoarVFX.Destroy, RoarVFX)
		end))

		Job:Task(Animation:GetMarkerReachedSignal("move"):Once(function()
			local Velocity = VelocityUtil.Create(RootPart, "Rageful Tackle Run")
			Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
			Velocity.Parent = RootPart

			Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
				Multiply = math.min(Multiply + (Delta * 60) * 1.1, Max)
				Velocity.Velocity = RootPart.CFrame.LookVector * Multiply
			end)
			
			if LocalPlayer == Players:GetPlayerFromCharacter(Model) then
				Yuki_FOV.Tween(60, {1.35})
			end

			Job:Task(Velocity)
		end))

		Job:Task(Animation:GetMarkerReachedSignal("run"):Once(function() 
			local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)

			EffectUtility.Toggle(RushVFX, true)

			if LocalPlayer == Players:GetPlayerFromCharacter(Model) then
				Yuki_FOV.Tween(115, {0.2})
				RunShake = CameraShake(1.5, 10, 0.01, 0, Vector3.one * 0.8)
			end

			task.delay(0.25, function()
				if LocalPlayer == Players:GetPlayerFromCharacter(Model) then
					Vignette(Color3.fromRGB(255, 81, 0), 0.5, 4.25)
				end
			end)
		end))

		Job:Task(Animation:GetMarkerReachedSignal("tackle"):Once(function() 
			EffectUtility.Toggle(RushVFX, false)
			
			if LocalPlayer == Players:GetPlayerFromCharacter(Model) then
				Yuki_FOV.Tween(70, {0.5})
			end

			if (RunShake ~= nil) then
				RunShake:StartFadeOut(0.1)
			end

			task.delay(2, RushVFX.Destroy, RushVFX)
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("end"):Once(function() 
		end))
	end,

	Hit = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Hit)
		if (Retrieved == nil) then return end

		local Job, Animation = Retrieved.Job, Retrieved.Animation
		local RootPart = Retrieved.RootPart
		
		local RunShake = nil

		local RushVFX = Job:Task(script.Holder.Rush:Clone())
		RushVFX.Parent = RootPart

		Job:Task(function()
			Yuki_FOV.Tween(70, {0.5})
		end)
		
		Job:Task(Animation:GetMarkerReachedSignal("Grab"):Once(function() 
			EffectUtility.Toggle(RushVFX, true)

			if LocalPlayer == Players:GetPlayerFromCharacter(Model) then
				Yuki_FOV.Tween(115, {0.1})
				RunShake = Job:Task(CameraShake(2.5, 25, 0.01, 0, Vector3.one * 0.8, Vector3.one * 0.3))
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("stoprun"):Once(function() 
			local VFX = script.Holder.Jump:Clone()
			VFX.Parent = RootPart

			EffectUtility.Emit(VFX)
			EffectUtility.Toggle(RushVFX, false)
			
			if (RunShake ~= nil) then
				RunShake:StartFadeOut(0.25)
			end

			task.delay(2, RushVFX.Destroy, RushVFX)
		end))

		Job:Task(Animation:GetMarkerReachedSignal("slam"):Once(function() 
			local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)

			local Direction = Vector3.yAxis * -50
			local Raycast = workspace:Raycast(RootPart.Position, Direction, Utility.VisualParams)
			local Attachment = script.SlamHolder.Slam:Clone()
			
			if Raycast then
				Attachment.WorldCFrame = CFrame.new(RootPart.Position.X, Raycast.Position.Y + 0.1, RootPart.Position.Z - 5)
			else
				Attachment.WorldCFrame = RootPart.CFrame * CFrame.new(0, -2.5, -5)
			end
		
			Attachment.Parent = workspace.Terrain
			EffectUtility.Emit(Attachment)

			if Distance < 30 then
				CameraShake(4, 40, 0.01, 0.7, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Color3.fromRGB(255, 81, 0), 0.25, 0.75)
			end

			coroutine.wrap(RockHandler.Crater)(Attachment.WorldPosition, Direction, {
				Amount = 30,

				Distance = {
					Min = 15, 
					Max = 30
				},

				LookAt = { -- Where the rocks face towards (y axis)
					Min = -6,
					Max = 6
				},

				Exposure = {
					Min = 0.55,
					Max = 0.75
				},

				BaseZ = 2,
				SizeMultiplier = 1.75,
			})

			coroutine.wrap(RockHandler.Rockst)(Attachment.WorldPosition, Direction, {
				Count = 20,
				Size = {0.5, 2},
				Velocity = 75,
			})

			--EffectUtility.RaycastCraterSmoke("Big", Attachment.WorldPosition, Direction)
		end))		
	end
}

