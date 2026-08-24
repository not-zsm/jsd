local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local Animations = replicatedStorage.animations.Attacks.invincible["Death Leap"]

---------------------------------------------------------------------

local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )
local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )

local RunCameraRig = require( replicatedStorage.modules.client.replication.Global.RunCameraRig )
local Yuki_FOV = require( replicatedStorage.modules.client.replication.Global.Yuki_FOV )

---------------------------------------------------------------------

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local JobModule = require( replicatedStorage.modules.shared.Utilities.Job )

local VelocityUtil = require( replicatedStorage.modules.shared.Game.Velocity.VelocityUtil )
local Smoke = require( replicatedStorage.modules.client.replication.Global.Smoke )

---------------------------------------------------------------------

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		
		local BloodEnabled = LocalPlayer:GetAttribute("Blood")
		local IsMainPlayer = (LocalPlayer.Character == Model)
		
		if IsMainPlayer then
			CameraShake(1, 10, 0.04, 0.5, Vector3.one * 0.8, Vector3.one * 0.4)
			Yuki_FOV.Tween(80, {0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out})
		end
		
		Job:Task(EffectUtility.AddSFX(script.Launch, Torso, 0.5))

		--task.delay(0.7, function()
		--	Yuki_FOV.Tween(75, {0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In})
		--end)
		
		--local WindupSFX = script.Windup:Clone()

		--if IsMainPlayer then
		--	WindupSFX.Parent = workspace
		--else
		--	WindupSFX.Parent = Retrieved.Torso
		--end
		--WindupSFX:Play()

		--Job:Task(function()
		--	--if Ended == false then
		--	WindupSFX:Destroy()
		--	--end
		--end)

		-- task.delay(27, SFX.Destroy, SFX)
		
		Job:Task(Animation:GetMarkerReachedSignal("VFX"):Connect(function(Parameter)
			if Parameter == "1" then
				EffectUtility.CloneAndEmit(script.Assets[tostring(Parameter)], RootPart)
			end
		end))
	end,
	
	Loop = function(Model : Model, RaycastCF : CFrame, Duration : number)--Raycast : Table)
		local Torso : BasePart = Model and Model:FindFirstChild("Torso")
		local Humanoid : Humanoid = Model and Model:FindFirstChild("Humanoid")
		local RootPart : BasePart = Model and Model:FindFirstChild("HumanoidRootPart")
		local Animator : Animator = Humanoid and Humanoid:FindFirstChild("Animator")
		
		local Job = JobModule.new()
		
		local Animation = Animator:LoadAnimation(Animations.Loop)
		Animation:Play()
		Job:Task(EffectUtility.AddSFX(script.Loop, Torso, 0.5))
	
		Job:Task(Animation.Stopped:Once(function()
			Job:Destroy()
		end))

		--local Retrieved = AnimationRetriever.new(Model, Animations.Loop)
		--if (Retrieved == nil) then return end

 		-- if Job then Job:Quit() end
		local BloodEnabled = LocalPlayer:GetAttribute("Blood")
		local IsMainPlayer = (LocalPlayer.Character == Model)
		
		local Attachment = script.Assets["2 LOOP"]:Clone()

		if IsMainPlayer then 
			Yuki_FOV.Tween(110, {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})

			Job:Task(function()
				Yuki_FOV.Tween(70, {0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In})
			end)
		end
		
		if IsMainPlayer then
			local LoopCoroutine = coroutine.create(function()
				while task.wait(0.1) do
					CameraShake(1, 20, 0.02, 0.15, Vector3.one * 0.8, Vector3.one * 0.4)
				end
			end)
			
			task.spawn(LoopCoroutine)
			Job:Task(LoopCoroutine)
		end
		
		Attachment.Parent = RootPart
		EffectUtility.Toggle(Attachment, true)
		
		local ArmTrails = EffectUtility.WeldTrailsToAllLimbs(RootPart.Parent)
		
		Job:Task(function()
			for _, Trail in pairs(ArmTrails) do
				EffectUtility.Toggle(Trail, false)
				task.delay(3, Trail.Destroy, Trail)
			end
			
			ArmTrails = nil
		end)
		
		Job:Task(function()
			EffectUtility.Toggle(Attachment, false)
			task.delay(1, Attachment.Destroy, Attachment)
		end)

		--if IsMainPlayer then
		--	RootPart.Anchored = true

		--	Job:Task(function()
		--		RootPart.Anchored = false
		--	end)
		--end
		
		local Elapsed = 0
		local StartCF = RootPart.CFrame

		local Connection; Connection = Job:Task(RunService.PreSimulation:Connect(function(Delta)
			Elapsed += Delta

			if (Elapsed >= Duration) then
				return Animation:Stop()
			end
			
			if IsMainPlayer then
				local Alpha = math.clamp(Elapsed / Duration, 0, 1)
				RootPart.CFrame = StartCF:Lerp(RaycastCF, Alpha)
			end
		end))
	end,
	
	Slam = function(Model : Model, RaycastCF : CFrame)
		local Retrieved = AnimationRetriever.new(Model, Animations.Slam)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		
		Job:Task(EffectUtility.AddSFX(script.Slam, Torso, 0.5))
		
		if EffectUtility.Distance_Close(Model) then -- just a util function i use 
			CameraShake(3, 30, 0.05, 1, Vector3.one * 0.9, Vector3.one * 0.4)
		end

		local Position = RaycastCF.Position
		local LookVector = Vector3.yAxis * -10
		
		coroutine.wrap(RockHandler.Crater)(Position, LookVector, {
			Amount = 27,
			
			Distance = {
				Min = 7.5, 
				Max = 20
			},

			LookAt = { -- Where the rocks face towards (y axis)
				Min = -5,
				Max = 5
			},

			Exposure = {
				Min = 0.55,
				Max = 0.75
			},

			BaseZ = 2,
			SizeMultiplier = 1.5,
		})
		
		Job:Task(Animation:GetMarkerReachedSignal("VFX"):Connect(function(Parameter)
			if Parameter == "3" then
				local RaycastResult = workspace:Raycast(Position + Vector3.yAxis * 2, Vector3.yAxis * -30, Utility.VisualParams)

				if RaycastResult then
					local GroundClone = script.Assets["3"]:Clone()
					GroundClone.WorldPosition = Vector3.new(RootPart.Position.X, RaycastResult.Position.Y, RootPart.Position.Z)--  CFrame.new(0, -RaycastResult.Distance + 0.1, 0)
					GroundClone.Parent = workspace.Terrain
					EffectUtility.Emit(GroundClone)
					
					task.delay(5, GroundClone.Destroy, GroundClone)
				end
			else
				EffectUtility.CloneAndEmit(script.Assets[tostring(Parameter)], RootPart)
			end
		end))
	end,
}

--local SuperRootAttachment = Instance.new("Attachment")
		--SuperRootAttachment.Name = "SuperRootAttachment"
		--SuperRootAttachment.Parent = workspace.Terrain
		
		--local RootAttachment = RootPart.RootAttachment
		
		--local Velocity = Job:Task(script.LinearVelocity:Clone())
		--Velocity.Attachment0 = RootAttachment
		--Velocity.Attachment1 = SuperRootAttachment
		--Velocity.VectorVelocity = Vector3.new(0, 0, 0)
		--Velocity.Enabled = true;
		--Velocity.Parent = RootPart;
		
		--Velocity.VectorVelocity = Vector3.new(0, 150, 0)
		
		--local Set = TweenService:Create(Velocity, TweenInfo.new(1.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
		--	VectorVelocity = Vector3.new(0, 1, 0);
		--})
		--Set:Play();
		
		--Animation:GetMarkerReachedSignal("startloop"):Connect(function()
		--	Set:Cancel()
		--	Velocity:Destroy()
			
		--	local SlamVelocity = script.LinearVelocity:Clone()
		--	SlamVelocity.Attachment0 = RootAttachment
		--	SlamVelocity.Attachment1 = SuperRootAttachment
		--	SlamVelocity.VectorVelocity = Vector3.new(0, 0, 0);
		--	SlamVelocity.Enabled = true;
		--	SlamVelocity.Parent = RootPart;

		--	SlamVelocity.VectorVelocity = Vector3.new(0, -100, -200)
			
		--	local SlamSet = TweenService:Create(SlamVelocity, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		--		VectorVelocity = Vector3.new(0, -200, -400)
		--	})
		--	SlamSet:Play();
		--end)