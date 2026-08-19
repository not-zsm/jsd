local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Chara["Lethal Wound"]

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local function Stab(MainRootPart : BasePart, VictimModel : Model, Type : string)
	EffectUtility.CloneAndEmit(script.Assets[Type], MainRootPart)

	if LocalPlayer:DistanceFromCharacter(MainRootPart.Position) < 20 then
		CameraShake(2.5, 25, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.25)
		Vignette(Color3.fromRGB(255, 0, 0), 0.35, 0.35)
	end

	local VictimHead = VictimModel:FindFirstChild("Head")

	if VictimHead then
		Blood.BloodRays("SpitOut", VictimHead.MouthAttachment)
	end
end

return {
	Windup = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local Humanoid = Retrieved.Humanoid
		local Torso = Retrieved.Torso
		local RootPart = Retrieved.RootPart

		local MainJob = Retrieved.Job
		local Animation = Retrieved.Animation

		local SlideThread = coroutine.create(function()
			while (RootPart.Parent ~= nil) do
				RockHandler.Rocks("CharaLethalWoundSlide", RootPart)
				Smoke(RootPart, 7.5)

				task.wait(0.025)
			end
		end)
		
		MainJob:Task(function()
			Utility.CloseThreadSafe(SlideThread)
		end)

		MainJob:Task(EffectUtility.AddSFX(script.SFX.Windup, Torso, 0.25))
		
		MainJob:Task(Animation:GetMarkerReachedSignal("run"):Once(function()
			EffectUtility.WeldTrailsToAllLimbs(Model, 0.9)

			if EffectUtility.Distance_Close(Model) then
				CameraShake(0.5, 5, 0.01, 0.25, Vector3.one * 0.4, Vector3.one * 0.3)
			end
		end))

		MainJob:Task(Animation:GetMarkerReachedSignal("slide"):Once(function()
			--local LookVector = CFrame.lookAlong(RootPart.Position, RootPart.CFrame.LookVector)

			--local Gyro = Instance.new("BodyGyro")
			--Gyro.MaxTorque = Vector3.one * 800000
			--Gyro.P = 10000
			--Gyro.CFrame = LookVector
			--Gyro.Parent = RootPart

			--MainJob:Task(Gyro)

			--MainJob:Task(Animation:GetMarkerReachedSignal("end"):Once(function()
			--	Gyro:Destroy()
			--end))

			coroutine.resume(SlideThread)
			
			if EffectUtility.Distance_Close(Model) then
				CameraShake(0.65, 6.5, 0.025, 1, Vector3.one * 0.4, Vector3.one * 0.2)
			end
		end))

		MainJob:Task(Animation:GetMarkerReachedSignal("endcast"):Once(function()
			MainJob:Task(EffectUtility.AddSFX(script.SFX.Getup, Torso, 0.3))
			Utility.CloseThreadSafe(SlideThread)
		end))
	end,

	Hit = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Hit)
		if (Retrieved == nil) then return end

		local RootPart = Retrieved.RootPart

		local MainJob = Retrieved.Job
		local Animation = Retrieved.Animation

		MainJob:Task(Animation:GetMarkerReachedSignal("stab"):Connect(function(Type : string)
			if (Type ~= "3") then
				Stab(RootPart, VictimModel, Type)
			end
		end))

		local Dist = LocalPlayer:DistanceFromCharacter(RootPart.Position)

		if Dist < 20 then
			CameraShake(1, 10, 0.01, 0.4, Vector3.one * 0.4, Vector3.one * 0.85)
		end

		if Dist < 80 then
			local Thread = coroutine.create(function()
				while (RootPart.Parent ~= nil) do
					RockHandler.Rocks("CharaLethalWoundSlide", RootPart)
					Smoke(RootPart, 7.5, 2.25)

					task.wait(0.03)
				end
			end)

			coroutine.resume(Thread)

			task.delay(0.65, function()
				Utility.CloseThreadSafe(Thread)
			end)
		end

		EffectUtility.CloneAndEmit(script.Assets.tackle, RootPart)

		do
			local Knife : Model = RootPart.Parent:FindFirstChild("Knife")

			if Knife then
				Knife.Handle.BladeAttachment.Trail.Enabled = true

				MainJob:Task(function()
					Knife.Handle.BladeAttachment.Trail.Enabled = false
				end)
			end
		end
	end,
	
	Stab = Stab
}

--function VFX.Slide(RootPart : BasePart)
--	local Thread = coroutine.create(function()
--		while (RootPart.Parent ~= nil) do
--			RockHandler.Rocks("CharaLethalWoundSlide", RootPart)
--			Smoke(RootPart, 7.5)

--			task.wait(0.035)
--		end
--	end)

--	coroutine.resume(Thread)

--	AttributeListener.new(RootPart, "LethalWoundSlide", function()
--		if coroutine.status(Thread) == "suspended" then
--			coroutine.close(Thread)
--		end
--	end)
--end

--function VFX.Tackle(RootPart : BasePart)
--	local Dist = LocalPlayer:DistanceFromCharacter(RootPart.Position)

--	if Dist < 20 then
--		CameraShake(1, 10, 0.01, 0.4, Vector3.one * 0.4, Vector3.one * 0.85)
--	end

--	if Dist < 80 then
--		local Thread = coroutine.create(function()
--			while (RootPart.Parent ~= nil) do
--				RockHandler.Rocks("CharaLethalWoundSlide", RootPart)
--				Smoke(RootPart, 7.5, 2.25)

--				task.wait(0.03)
--			end
--		end)

--		coroutine.resume(Thread)

--		task.delay(0.65, function()
--			if coroutine.status(Thread) == "suspended" then
--				coroutine.close(Thread)
--			end
--		end)
--	end

--	EffectUtility.CloneAndEmit(script.Assets.tackle, RootPart)

--	do
--		local Knife : Model = RootPart.Parent:FindFirstChild("Knife")

--		if Knife then
--			Knife.Handle.BladeAttachment.Trail.Enabled = true

--			AttributeListener.new(RootPart, "LethalWoundHit", function()
--				Knife.Handle.BladeAttachment.Trail.Enabled = false
--			end)
--		end
--	end
--end

--function VFX.Stab(RootPart : BasePart, VictimHead : BasePart, Type : number)
--	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 20 then
--		CameraShake(2.5, 25, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.25)
--		Vignette(Color3.fromRGB(255, 0, 0), 0.35, 0.35)
--	end

--	Blood.BloodRays("SpitOut", VictimHead.MouthAttachment)
--	EffectUtility.CloneAndEmit(script.Assets[Type], RootPart)
--end

--return VFX