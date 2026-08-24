local replicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Flight = require(replicatedStorage:WaitForChild("BuildTools"):WaitForChild("FlightHandler"):WaitForChild("Flight"))

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local Animations = replicatedStorage.animations.Attacks.Global.Ultimate.invincible

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

local BugoMesh = require( replicatedStorage.modules.client.replication.EffectUtility.Bugo )

local TekrinnDialogue = require(replicatedStorage.modules.effect.tekrinnDialogue)

---------------------------------------------------------------------

local StrokeColor = Color3.new(0, 0, 0)
local NameColor = ColorSequence.new(Color3.new(0.333333, 0.666667, 1), Color3.new(0, 0.666667, 1))
local MainColor = ColorSequence.new(Color3.new(0, 0.4, 1))

local function LimbTrails(Character)
	local Trails = script.Assets.Trails
	local Attachments = {}
	
	for _, Limb in Trails:GetChildren() do
		local BeamAttachments = Limb:GetChildren()
		for _, Attachment in BeamAttachments do
			Attachment.Parent = Character[Limb.Name]
			table.insert(Attachments, Attachment)
		end
	end
	
	return Attachments
end

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Start)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		
		local BloodEnabled = LocalPlayer:GetAttribute("Blood")
		local IsMainPlayer = (LocalPlayer.Character == Model)
		local ShowCamera = true
		
		-- Camera Setup
		if IsMainPlayer and ShowCamera then
			local Camera : Model = Job:Task(script.Camera:Clone())
			Camera:PivotTo(RootPart.CFrame)
			Camera.Parent = workspace.Visuals

			local CameraAnimation : AnimationTrack = Camera.Humanoid.Animator:LoadAnimation(Animations.Camera)
			CameraAnimation:Play(0)
			
			Job:Task(Yuki_FOV.AnimateWithMoonFile(replicatedStorage.fovFiles["Invincible Ultimate"]))

			Job:Task(Animation:GetMarkerReachedSignal("end"):Connect(function()
				CameraAnimation:Stop(0)
				Camera:Destroy()
			end))

			Job:Task(RunCameraRig(RootPart, Camera, CFrame.new(-0.48, -2, -1.311), {
				DontDoTransition = true
			}))
			
			SoundService:PlayLocalSound(script.ThisIsOver)
		else
			Job:Task(EffectUtility.AddSFX(script.ThisIsOver, Torso, 0.5))
		end
		
		--Job:Task(Animation:GetMarkerReachedSignal("launch"):Once(function()
		--	if IsMainPlayer then
		--		SoundService:PlayLocalSound(script.FlyBoost)
		--	else
		--		Job:Task(EffectUtility.AddSFX(script.FlyBoost, Torso, 0.5))
		--	end
		--end))
		
		-- VFX
		Job:Task(Animation:GetMarkerReachedSignal("VFX"):Connect(function(Parameter)
			EffectUtility.CloneAndEmit(script.Assets[tostring(Parameter)], RootPart)
			
			if Parameter == "2" then
				local LimbTrails = LimbTrails(Model)
				
				Job:Task(function()
					for _, Trail in pairs(LimbTrails) do
						Trail:Destroy()
					end
				end)
			end
		end))
		
		Job:Task(task.delay(math.max(0, 2.25 - Animation.TimePosition), function()
			if not (IsMainPlayer or (LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 100)) then
				return
			end
			
			Job:Task(TekrinnDialogue.Speak(Model, {
				Image = "101089066666765",
				Text = "THIS IS OVER!",
				TextStrokeColor = StrokeColor,
				Color = MainColor,
				Shake = {
					Lifetime = 0.5,
					Enabled = true,
					Intensity = 3,
				},
				TypeSpeed = 0.0275,
			}, {
				StrokeColor = StrokeColor,
				Color = NameColor,
			}, 1))
		end))
	end,
	
	Flight = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.FlightStart)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job

		local BloodEnabled = LocalPlayer:GetAttribute("Blood")
		local IsMainPlayer = (LocalPlayer.Character == Model)
		
		RootPart.CFrame = RootPart.CFrame * CFrame.new(0, 250, 0)
		
		-- Takeoff
		local Velocity = VelocityUtil.Create(RootPart, "Ultimate Launch")
		Velocity.MaxForce =  Vector3.new(0, 1, 0) * 80000
		Velocity.Parent = RootPart
		Velocity.Velocity = Vector3.new(0, 1, 0)
		
		local MultiplyValue = Job:Task(Instance.new("NumberValue"))
		MultiplyValue.Value = 200
		MultiplyValue.Parent = RootPart
		
		Job:Task(task.delay(0.5, function()
			if not (Velocity and Velocity:IsDescendantOf(RootPart)) then
				return
			end
			
			TweenService:Create(MultiplyValue, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
				Value = 100
			}):Play()
		end))
		
		Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
			Velocity.Velocity = Vector3.new(0, 1, 0) * MultiplyValue.Value
		end)
		
		-- Velocity Fade
		local Fade; Fade = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
			if (MultiplyValue.Value <= 0) then
				return Fade:Destroy()
			end
			
			local FadeIntensity = 1
			MultiplyValue.Value = math.max(MultiplyValue.Value - (Delta * 60) * FadeIntensity, 0) -- this is the fade
		end)

		Job:Task(Velocity)
		
		Job:Task(Animation:GetMarkerReachedSignal("Velocity"):Connect(function(Parameter)
			-- Swoop back before taking off
			if Parameter == "back" then
				Velocity:Destroy()
				
				local FlightVelocity = VelocityUtil.Create(RootPart, "Ultimate Start")
				FlightVelocity.MaxForce = Vector3.one * 80000
				FlightVelocity.Parent = RootPart

				MultiplyValue.Value = -80

				Job:Task(FlightVelocity)
				--
				Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, FlightVelocity, function(Delta : number)
					FlightVelocity.Velocity = RootPart.CFrame.LookVector * MultiplyValue.Value
				end)
				
				local StartFadeInJob; StartFadeInJob = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, FlightVelocity, function(Delta : number)
					if MultiplyValue.Value >= 0 then
						return StartFadeInJob:Destroy()
					end

					MultiplyValue.Value += (Delta * 60) * 2
				end)
			--elseif Parameter == "forward" then
			--	FlightJob:Destroy()
			end
		end))
	end,
	
	Loop = function(Model : Model, RaycastCF : CFrame, RaycastNormal, Duration : number)
		local Retrieved = AnimationRetriever.new(Model, Animations.FlightStart)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, RetrievedJob = Retrieved.Animation, Retrieved.Job
		local Animator : Animator = Retrieved.Humanoid:FindFirstChild("Animator")

		local LoopAnimation = Animator:LoadAnimation(Animations.FlightLoop)
		
		
		local Job = JobModule.new()
		
		local Connection = RetrievedJob:Task(function()
			Job:Destroy()
		end)
		
		Job:Task(Animation:GetMarkerReachedSignal("StartLoop"):Connect(function()
			Connection:Disconnect()
			
			Animation:Stop()
			LoopAnimation:Play()

			Job:Task(LoopAnimation.Stopped:Connect(function()
				Job:Destroy()
			end))
		end))
		
		Job:Task(EffectUtility.AddSFX(script.FlyBoost, Torso, 0.5))

		local BloodEnabled = LocalPlayer:GetAttribute("Blood")
		local IsMainPlayer = (LocalPlayer.Character == Model)

		if IsMainPlayer then
			local LoopCoroutine = coroutine.create(function()
				while task.wait(0.1) do
					CameraShake(1, 20, 0.02, 0.15, Vector3.one * 0.8, Vector3.one * 0.4)
				end
			end)

			task.spawn(LoopCoroutine)
			Job:Task(LoopCoroutine)
		end

		--if IsMainPlayer then
		--	RootPart.Anchored = true

		--	Job:Task(function()
		--		RootPart.Anchored = false
		--	end)
		--end

		local Elapsed = 0
		--RootPart.CFrame = CFrame.lookAt(RootPart.Position, RaycastCF.Position)
		local StartCF = RootPart.CFrame
		
		local FlightRotation = Job:Task(script.Rotation:Clone())
		FlightRotation.Attachment0 = RootPart:FindFirstChild("RootAttachment")
		FlightRotation.Parent = RootPart:FindFirstChild("RootAttachment")
		FlightRotation.Enabled = true

		local Connection; Connection = Job:Task(RunService.PreSimulation:Connect(function(Delta)
			Elapsed += Delta

			if (Elapsed >= Duration) then
				Connection:Disconnect()
				return Animation:Stop()
			end

			if IsMainPlayer then
				local Alpha = math.clamp(Elapsed / Duration, 0, 1)
				local NewPosition = StartCF.Position:Lerp(RaycastCF.Position, Alpha)

				-- Face the target (RaycastCF.Position), including pitch
				local LookAtCF = CFrame.lookAt(NewPosition, RaycastCF.Position)

				RootPart.CFrame = LookAtCF
				
				FlightRotation.CFrame = CFrame.new(RootPart.Position, RootPart.Position + RaycastCF.Position)
			end
		end))
		
		-- VFX
		local Attachment = Job:Task(script.Assets.FlightLoop:Clone())
		Attachment.Parent = RootPart
		EffectUtility.Toggle(Attachment, true)

		Job:Task(EffectUtility.Toggle(Attachment, true))
		
		-- Visual
		if IsMainPlayer then 
			Yuki_FOV.Tween(130, {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})

			Job:Task(function()
				Yuki_FOV.Tween(70, {0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In})
			end)
		end

		if IsMainPlayer then
			local LoopCoroutine = coroutine.create(function()
				while task.wait(0.1) do
					CameraShake(3, 25, 0.03, 0.15, Vector3.one * 0.8, Vector3.one * 0.4)
				end
			end)

			task.spawn(LoopCoroutine)
			Job:Task(LoopCoroutine)
		end

		local ArmTrails = EffectUtility.WeldTrailsToAllLimbs(RootPart.Parent)

		Job:Task(function()
			for _, Trail in pairs(ArmTrails) do
				EffectUtility.Toggle(Trail, false)
				task.delay(3, Trail.Destroy, Trail)
			end

			ArmTrails = nil
		end)
	end,
	
	Slam = function(Model : Model, RaycastCF : CFrame)
		local Retrieved = AnimationRetriever.new(Model, Animations.Slam)
		if (Retrieved == nil) then return end
		
		local IsMainPlayer = (LocalPlayer.Character == Model)
		
		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job

		if EffectUtility.Distance_Close(Model) then 
			CameraShake(4, 30, 0.01, 1, Vector3.one * 0.9, Vector3.one * 0.4)
		end
		
		-- i still need to patch chara cheese 😭
	
		local Position = RaycastCF.Position
		local LookVector = Vector3.yAxis * -10
		
		-- Rocks
		coroutine.wrap(RockHandler.OldJSDRocks)(Position, {
			VariationMin = .8;
			VariationMax = 1.2;
			MinAngleVariation = 20;
			MaxAngleVariation = 20;
			
			BaseDuration = 5;

			Rocks = 10 ;

			ExposeLevel = -2.25;
			Distance = 25;

			SizeMagnitude = Vector3.new(2.5, 2.8, 3.8);
		})
		
		coroutine.wrap(RockHandler.OldJSDRocks)(Position, {
			VariationMin = .8;
			VariationMax = 1.2;
			MinAngleVariation = 20;
			MaxAngleVariation = 20;
			
			BaseDuration = 5;

			Rocks = 20 ;

			ExposeLevel = -2.25;
			Distance = 50;

			SizeMagnitude = Vector3.new(2.5, 2.8, 3.8) * 2;
		})
		
		--coroutine.wrap(RockHandler.OldJSDRocks)(Position, {
		--	VariationMin = .8;
		--	VariationMax = 1.2;
		--	MinAngleVariation = 20;
		--	MaxAngleVariation = 20;

		--	Rocks = 30 ;

		--	ExposeLevel = -2.25;
		--	Distance = 75;

		--	SizeMagnitude = Vector3.new(2.5, 2.8, 3.8) * 2;
		--})
		
		task.spawn(function()
			local Ground = workspace:Raycast(Position + vector.create(0, 10, 0), vector.create(0, -100, 0), Utility.VisualParams)

			if (Ground == nil) then
				return
			end
			
			EffectUtility.CraterSmoke("Big", Ground)
			
			for Index = 1, 20 do
				local Part = Instance.new("Part")
				Part.CollisionGroup = "Rockst"
				Part.Size = vector.one * Utility.Seed:NextInteger(4, 8)
				
				Part.Material = Ground.Material
				Part.Color = Ground.Instance.Color
				
				for _, Texture in Ground.Instance:GetChildren() do
					if not Texture:IsA("Texture") then
						continue
					end
					
					Texture:Clone().Parent = Part
				end
				
				Part.CFrame = CFrame.new(Position) * CFrame.new(Utility.Seed:NextInteger(-30, 30), 3, Utility.Seed:NextInteger(-30, 30))
				Part.Parent = workspace.Visuals
				
				local Mover = Instance.new("BodyVelocity")
				Mover.MaxForce = vector.one * 1e6
				Mover.Velocity = vector.create(Utility.Seed:NextInteger(-30, 30), Utility.Seed:NextInteger(10, 35), Utility.Seed:NextInteger(-30, 30)) * Utility.Seed:NextInteger(2, 4)
				Mover.Parent = Part

				task.delay(0.35, Mover.Destroy, Mover)
				
				task.delay(10, function()
					TweenService:Create(Part, TweenInfo.new(1), {
						Size = vector.zero,
						Transparency = 1,
					}):Play()
					
					task.delay(1, Part.Destroy, Part)
				end)
			end
		end)
		
		-- Temporary VFX
		Job:Task(Animation:GetMarkerReachedSignal("VFX"):Connect(function(Parameter)
			if Parameter == "Slam" then
				local Explosion = script.Assets.VFXPart:Clone()
				Explosion.CFrame = RaycastCF
				Explosion.Parent = workspace.Visuals
				EffectUtility.Emit(Explosion)

				task.delay(5, Explosion.Destroy, Explosion)
				
				BugoMesh(script.Assets.Meshes, RootPart)
			elseif Parameter == "PunchGround" then
				EffectUtility.CloneAndEmit(script.Assets["1"], RootPart)
			end
		end))
	end,
}