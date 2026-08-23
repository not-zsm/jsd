local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local RockHandler = require( ReplicatedStorage.modules.client.replication.Global.RockHandler )
local EffectUtility = require( ReplicatedStorage.modules.client.replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.modules.client.replication.Global.CameraShake )
local Shockwave = require( ReplicatedStorage.modules.client.replication.Global.Shockwave )

local AttributeListener = require( ReplicatedStorage.modules.client.replication.Global.AttributeListener )

local Job = require( ReplicatedStorage.modules.shared.Utilities.Job )
local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )

local VFX = {}

local function Impact(Impacter : BasePart, AttributeToListenTo : string, Callback : () -> ()) : (Job.object, Configuration)
	if (Impacter == nil or Impacter.Parent == nil) then
		return
	end

	local NewJob, Replication : Configuration = AttributeListener.new(Impacter, AttributeToListenTo)

	NewJob:Task(RunService.PreSimulation:Connect(function()
		if (Impacter == nil or Impacter.Parent == nil) then
			return NewJob:Destroy()
		end

		local Velocity = Impacter.AssemblyLinearVelocity
		local Direction = Velocity.Unit * math.max(1.5, Velocity.Magnitude / 10) --(Velocity.Magnitude / 11)

		local HitRaycast = workspace:Raycast(Impacter.Position, Direction, Utility.VisualParams)

		if (HitRaycast ~= nil) then
			NewJob:Destroy()
			task.spawn(Callback, HitRaycast, Direction, Velocity)
		end
	end))

	return NewJob, Replication

	--local Replication = AttributeListener.GetReplicationFromSource(Impacter)
	--local NewJob = Job.new()

	--NewJob:Task(RunService.PostSimulation:Connect(function()
	--	if (Impacter == nil or Impacter.Parent == nil) or not Replication:GetAttribute(AttributeToListenTo) then
	--		return NewJob:Destroy()
	--	end

	--	local Velocity = Impacter.AssemblyLinearVelocity
	--	local Direction = Velocity.Unit * (Velocity.Magnitude / 8)

	--	local HitRaycast = workspace:Raycast(Impacter.Position, Direction, Utility.VisualParams)

	--	if (HitRaycast ~= nil) then
	--		NewJob:Destroy()
	--		task.spawn(Callback, HitRaycast, Direction, Velocity)
	--	end
	--end))
end

function VFX.RagdollImpact(Impacter : BasePart)
	Impact(Impacter, "RagdollImpact", function(HitRaycast : RaycastResult)
		EffectUtility.EmitEffects(script.RagdollImpact, Impacter)

		local Effect = script.RagdollImpactPart.Attachment:Clone()
		Effect.Position = HitRaycast.Position
		Effect.Parent = workspace.Terrain
		Effect.Smoke.Color = ColorSequence.new(HitRaycast.Instance.Color)
		EffectUtility.Emit(Effect)
	end)
end

function VFX.GoofySlip(Impacter : BasePart)
	local SlipVFX = EffectUtility.EmitEffects(script.Slip, Impacter)

	Impact(Impacter, "RagdollImpact", function()
		for Item in SlipVFX do
			Item:Destroy()
		end

		EffectUtility.EmitEffects(script.SlipLand, Impacter)
	end)
end

function VFX.CraterImpact(Culprit : Model, Impacter : BasePart)
	task.wait(0.25)

	local ImpactJob = Job.new()
	local TrailJob = Job.new()

	if (Impacter and Impacter.Parent ~= nil) then
		local Trails = {}

		for _, Item in ipairs(Impacter.Parent:GetChildren()) do
			if Item:IsA("BasePart") and Item.Name ~= "HumanoidRootPart" then
				local Trail = script.Trail:Clone()
				Trail.Parent = workspace.Visuals
				EffectUtility.Weld(Trail, Item)
				Trails[Trail] = true
			end
		end

		TrailJob:Task(function()
			for Trail in Trails do
				EffectUtility.Toggle(Trail, false)
				task.delay(1, Trail.Destroy, Trail)
			end
		end)

		local ShockwaveAngleFix = CFrame.Angles(0, math.pi / 2, 0)
		local ShockwaveInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

		local ShockwavesThread = coroutine.create(function()
			while task.wait(0.1) do
				local Shockwave = script.Shockwave:Clone()

				local Velocity = Impacter.AssemblyLinearVelocity
				local Speed = Velocity.Magnitude
				 
				if (Speed > 2) then
					local ForwardOffset = math.clamp(Speed * 0.1, 2, 15)
					local SizeScale = math.clamp(Speed * 0.1, 7.5, 20)
					
					local LookDirection = Speed > 0.1 and Velocity.Unit or Vector3.new(0, 0, -1)
					local ShockwavePosition = Impacter.Position + (LookDirection * ForwardOffset)

					Shockwave.CFrame = CFrame.lookAlong(ShockwavePosition, LookDirection) * ShockwaveAngleFix
					Shockwave.Size = Vector3.zero
					Shockwave.Parent = workspace.Visuals

					TweenService:Create(Shockwave, ShockwaveInfo, {
						CFrame = Shockwave.CFrame * CFrame.Angles(0, math.pi * 4, 0),
						Size = Vector3.new(SizeScale / 6, SizeScale, SizeScale),
						Transparency = 1
					}):Play()

					task.delay(ShockwaveInfo.Time, Shockwave.Destroy, Shockwave)
				end
			end
		end)

		coroutine.resume(ShockwavesThread)
		ImpactJob:Task(ShockwavesThread)
	end
	
	local CraterTiming = {
		In = 0,

		Idle = { -- Time where the rocks stay idle
			Min = 4.7,
			Max = 5.1
		},

		Out = { -- Time it takes for the rocks to fade out
			Min = 1.6,
			Max = 2.2
		},
	}
	
	local Magnitudes = {
		[250] = function(HitPosition : Vector3, Direction : Vector3, Show_Shake : boolean)
			coroutine.wrap(RockHandler.Crater)(HitPosition, Direction, {
				Timing = CraterTiming,

				Amount = 16,
				Distance = 10,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = -13,
					Max = -13
				},

				Exposure = {
					Min = 0.2,
					Max = 0.4
				},

				BaseZ = 1.5,

				SizeMultiplier = 1.1,
			})

			coroutine.wrap(RockHandler.Crater)(HitPosition, Direction, {
				Timing = CraterTiming,

				Amount = 20,
				Distance = 17.5,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = -13,
					Max = 13
				},

				SizeMultiplier = 1.85,
			})

			coroutine.wrap(RockHandler.Rockst)(HitPosition, Direction, {
				Count = 25,
				Size = {0.75, 2.5},
				Velocity = 90,
			})

			EffectUtility.RaycastCraterSmoke("Big", HitPosition, Direction)

			if Show_Shake then
				CameraShake(6, 60, 0.1, 1, Vector3.one * 1, Vector3.one * 0.5)
			end
		end,
		
		[150] = function(HitPosition : Vector3, Direction : Vector3, Show_Shake : boolean)
			coroutine.wrap(RockHandler.Crater)(HitPosition, Direction, {
				Timing = CraterTiming,

				Amount = 9,
				Distance = 5,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = -7.5,
					Max = -7.5
				},

				Exposure = {
					Min = 0.3,
					Max = 0.5
				},

				BaseZ = 1.5,

				SizeMultiplier = 0.95,
			})

			coroutine.wrap(RockHandler.Crater)(HitPosition, Direction, {
				Timing = CraterTiming,

				Amount = 15,
				Distance = 12.5,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = -7.5,
					Max = 7.5
				},

				SizeMultiplier = 1.65,
			})

			coroutine.wrap(RockHandler.Rockst)(HitPosition, Direction, {
				Count = 15,
				Size = {0.76, 2.15},
				Velocity = 70,
			})

			EffectUtility.RaycastCraterSmoke("Big", HitPosition, Direction)

			if Show_Shake then
				CameraShake(4, 40, 0.1, 0.6, Vector3.one * 0.8, Vector3.one * 0.35)
			end
		end,
		
		[0] = function(HitPosition : Vector3, Direction : Vector3, Show_Shake : boolean)
			coroutine.wrap(RockHandler.Crater)(HitPosition, Direction, {
				Timing = CraterTiming,

				Amount = 5,
				Distance = 2.25,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = -3.5,
					Max = -3.5
				},

				Exposure = {
					Min = 0.4,
					Max = 0.6
				},

				BaseZ = 1.5,

				SizeMultiplier = 0.75,
			})

			coroutine.wrap(RockHandler.Crater)(HitPosition, Direction, {
				Timing = CraterTiming,

				Amount = 10,
				Distance = 7,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = -3.5,
					Max = 3.5
				},

				SizeMultiplier = 1.35,
			})

			coroutine.wrap(RockHandler.Rockst)(HitPosition, Direction, {
				Count = 12,
				Size = {0.5, 1.5},
				Velocity = 45,
			})

			EffectUtility.RaycastCraterSmoke("Normal", HitPosition, Direction)

			if Show_Shake then
				CameraShake(2.5, 25, 0.1, 0.4, Vector3.one * 0.8, Vector3.one * 0.25)
			end
		end,
	}

	local MainJob, Replication = Impact(Impacter, "CraterImpact", function(HitRaycast : RaycastResult, Direction : Vector3, ImpacterVelocity : Vector3)
		local HitPosition = HitRaycast.Position
		
		local Attachment = Instance.new("Attachment")
		
		local SFX = script.SFX:Clone()
		
		SFX.Parent = Attachment
		Attachment.WorldPosition = HitPosition
		Attachment.Parent = workspace.Terrain
		SFX:Play()
		
		task.delay(4, Attachment.Destroy, Attachment)

		local Show_Shake = (Impacter and Impacter.Parent) and (
			LocalPlayer.Character == Impacter.Parent or 
			LocalPlayer.Character == Culprit or 
			EffectUtility.Distance_Close(Impacter.Parent)
		)
		
		local Magnitude = ImpacterVelocity.Magnitude
		
		for Mag, Fn in Magnitudes do
			if Magnitude >= Mag then
				Fn(HitPosition, Direction, Show_Shake)

				break
			end
		end

		--if (ImpacterVelocity.Magnitude > 250) then

		--	coroutine.wrap(RockHandler.Crater)(HitPosition, Direction, {
		--		Timing = CraterTiming,
				
		--		Amount = 16,
		--		Distance = 10,

		--		LookAt = { -- Where the rocks face towards (y axis)
		--			Min = -13,
		--			Max = -13
		--		},

		--		Exposure = {
		--			Min = 0.2,
		--			Max = 0.4
		--		},

		--		BaseZ = 1.5,

		--		SizeMultiplier = 1.1,
		--	})

		--	coroutine.wrap(RockHandler.Crater)(HitPosition, Direction, {
		--		Timing = CraterTiming,
				
		--		Amount = 20,
		--		Distance = 17.5,

		--		LookAt = { -- Where the rocks face towards (y axis)
		--			Min = -13,
		--			Max = 13
		--		},

		--		SizeMultiplier = 1.85,
		--	})

		--	coroutine.wrap(RockHandler.Rockst)(HitPosition, Direction, {
		--		Count = 25,
		--		Size = {0.75, 2.5},
		--		Velocity = 90,
		--	})

		--	EffectUtility.RaycastCraterSmoke("Big", HitPosition, Direction)

		--	if Show_Shake then
		--		CameraShake(6, 60, 0.1, 1, Vector3.one * 1, Vector3.one * 0.5)
		--	end

		--elseif (ImpacterVelocity.Magnitude > 150) then

		--	coroutine.wrap(RockHandler.Crater)(HitPosition, Direction, {
		--		Timing = CraterTiming,
				
		--		Amount = 9,
		--		Distance = 5,

		--		LookAt = { -- Where the rocks face towards (y axis)
		--			Min = -7.5,
		--			Max = -7.5
		--		},

		--		Exposure = {
		--			Min = 0.3,
		--			Max = 0.5
		--		},

		--		BaseZ = 1.5,

		--		SizeMultiplier = 0.95,
		--	})

		--	coroutine.wrap(RockHandler.Crater)(HitPosition, Direction, {
		--		Timing = CraterTiming,
				
		--		Amount = 15,
		--		Distance = 12.5,

		--		LookAt = { -- Where the rocks face towards (y axis)
		--			Min = -7.5,
		--			Max = 7.5
		--		},

		--		SizeMultiplier = 1.65,
		--	})

		--	coroutine.wrap(RockHandler.Rockst)(HitPosition, Direction, {
		--		Count = 15,
		--		Size = {0.76, 2.15},
		--		Velocity = 70,
		--	})

		--	EffectUtility.RaycastCraterSmoke("Big", HitPosition, Direction)

		--	if Show_Shake then
		--		CameraShake(4, 40, 0.1, 0.6, Vector3.one * 0.8, Vector3.one * 0.35)
		--	end

		--else
		--	coroutine.wrap(RockHandler.Crater)(HitPosition, Direction, {
		--		Timing = CraterTiming,
				
		--		Amount = 5,
		--		Distance = 2.25,

		--		LookAt = { -- Where the rocks face towards (y axis)
		--			Min = -3.5,
		--			Max = -3.5
		--		},

		--		Exposure = {
		--			Min = 0.4,
		--			Max = 0.6
		--		},

		--		BaseZ = 1.5,

		--		SizeMultiplier = 0.75,
		--	})

		--	coroutine.wrap(RockHandler.Crater)(HitPosition, Direction, {
		--		Timing = CraterTiming,
				
		--		Amount = 10,
		--		Distance = 7,

		--		LookAt = { -- Where the rocks face towards (y axis)
		--			Min = -3.5,
		--			Max = 3.5
		--		},

		--		SizeMultiplier = 1.35,
		--	})

		--	coroutine.wrap(RockHandler.Rockst)(HitPosition, Direction, {
		--		Count = 12,
		--		Size = {0.5, 1.5},
		--		Velocity = 45,
		--	})

		--	EffectUtility.RaycastCraterSmoke("Normal", HitPosition, Direction)

		--	if Show_Shake then
		--		CameraShake(2.5, 25, 0.1, 0.4, Vector3.one * 0.8, Vector3.one * 0.25)
		--	end
		--end
	end)
	
	if MainJob and Replication then
		MainJob:Task(Replication:GetAttributeChangedSignal("SideDash"):Connect(function()
			if not Replication:GetAttribute("SideDash") then
				MainJob:Destroy()
			end
		end))
		
		MainJob:Task(Replication:GetAttributeChangedSignal("BackwardDash"):Connect(function()
			if not Replication:GetAttribute("BackwardDash") then
				MainJob:Destroy()
			end
		end))
		
		MainJob:Task(function()
			ImpactJob:Destroy()
			TrailJob:Destroy()
		end)
	end
end

return VFX