local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local Animations = replicatedStorage.Animations.Attacks.Kratos["Guardian Shield"]

---------------------------------------------------------------------

local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )

---------------------------------------------------------------------

local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local AenoirEmit = EffectUtility.AenoirEmit

local VelocityUtil = require( replicatedStorage.modules.shared.Game.Velocity.VelocityUtil )

---------------------------------------------------------------------

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Rush)
		if (Retrieved == nil) then return end

		local RootPart = Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job

		local SFX = script.SFX:Clone()
		SFX.Parent = RootPart
		SFX:Play()

		local Trails = {}

		task.spawn(function()
			for _, Item in ipairs(Model:GetChildren()) do
				if Item:IsA("BasePart") and (string.find(Item.Name, "Right") or string.find(Item.Name, "Left")) then
					Trails[EffectUtility.WeldArmTrail(Item)] = true
				end
			end
		end)

		local Velocity = VelocityUtil.Create(RootPart, "Guardian Bash")
		Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
		Velocity.Parent = RootPart

		local Hit = false
		local Slid = false
		local Max = 57.5

		local FadeOutMulti = 1.5
		local FadeInMulti = 1.5

		local Multiply = 0

		Job:Task(function()
			for Trail in Trails do
				Trail:Destroy()
			end

			table.clear(Trails)
		end)

		Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
			if Slid then
				Multiply = math.clamp(Multiply - (Delta * 60) * FadeOutMulti, 0, Max)
			else
				Multiply = math.clamp(Multiply + (Delta * 60) * FadeInMulti, 0, Max)
			end

			Velocity.Velocity = RootPart.CFrame.LookVector * Multiply
		end)

		Job:Task(Velocity)

		Job:Task(function()
			TweenService:Create(SFX, TweenInfo.new(0.5), {Volume = 0}):Play()
			task.delay(0.5, SFX.Destroy, SFX)
		end)

		Job:Task(Animation:GetMarkerReachedSignal("launch"):Connect(function()
			task.spawn(function()
				while not Job.Destroyed and not Slid do
					AenoirEmit(script.Mesh, RootPart.CFrame * CFrame.Angles(math.rad(90), 0, 0))
					task.wait(0.2)
				end
			end)
		end))

		Job:Task(Animation:GetMarkerReachedSignal("slide"):Connect(function()
			Slid = true
		end))

		Job:Task(Animation:GetMarkerReachedSignal("hit"):Connect(function()
			Hit = true
			
			for Trail in Trails do
				for _, Item in ipairs(Trail:GetChildren()) do
					if not Item:IsA("Trail") then continue end

					Item.Enabled = false
				end
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("step"):Connect(function()
			if EffectUtility.Distance_Close(Model) then
				CameraShake(1, 15, 0.01, 0.15, Vector3.one * 0.8, Vector3.one * 0.5)
			end
		end))
	end,

	Hit = function(VictimModel : Model)
		if (VictimModel and VictimModel.Parent) then
			do
				local SFX = script.Hit:Clone()
				SFX.Parent = VictimModel.PrimaryPart
				SFX:Play()

				task.delay(2, SFX.Destroy, SFX)
			end

			local Distance = LocalPlayer:DistanceFromCharacter(VictimModel:GetPivot().Position)

			if (Distance <= 20) then
				CameraShake(3, 20, 0.01, 0.6, Vector3.one * 0.8, Vector3.one * 0.4)

				Lighting.ExposureCompensation += 1

				TweenService:Create(Lighting, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
					{ExposureCompensation = 0}
				):Play()
			end

			if (Distance <= 50) then
				local Head : BasePart = VictimModel:FindFirstChild("Head")

				if Head then
					EffectUtility.EmitEffects(replicatedStorage.Effects.Blood.Splash, Head)

					Blood.BloodRaysWithoutPreset(Head, {
						Face = Enum.NormalId.Front,
						Amount = Vector2.new(3, 5),
						PoolSize = 1.5,
					})

					Blood.BloodRaysWithoutPreset(Head, {
						Face = Enum.NormalId.Back,
						Amount = Vector2.new(3, 5),
						PoolSize = 1.5,
					})

					Blood.BloodRaysWithoutPreset(Head, {
						Face = Enum.NormalId.Top,
						Amount = Vector2.new(2, 4),
						PoolSize = 1.5,
					})
				end
			end
		end
	end,
}