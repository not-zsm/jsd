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
		local Retrieved = AnimationRetriever.new(Model, Animations.Air)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, MainJob = Retrieved.Animation, Retrieved.Job
		
		local IsMainPlayer = (LocalPlayer.Character == Model)
		
		--local AirImpactLandEvent : RemoteEvent = Model:WaitForChild("AirImpactLand")
		
		local UpVelocity = Instance.new("LinearVelocity")
		UpVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
		UpVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
		UpVelocity.LineDirection = vector.create(0, 1, 0)
		UpVelocity.MaxForce = math.huge
		UpVelocity.Attachment0 = RootPart.RootAttachment
		UpVelocity.LineVelocity = 75
		UpVelocity.Parent = RootPart
		
		local UserBodyVelocity = VelocityUtil.Create(RootPart, "WhirlwindSlamAir")
		UserBodyVelocity.Velocity = RootPart.CFrame.LookVector
		UserBodyVelocity.MaxForce = vector.create(80_000, 0, 80_000)
		UserBodyVelocity.Parent = RootPart
		
		local ForwardForce = 50
		
		local NumberValue = Instance.new("NumberValue")
		NumberValue.Value = 50
		NumberValue.Parent = UserBodyVelocity
		
		task.spawn(function()
			while (not MainJob.Destroyed and UserBodyVelocity.Parent ~= nil and RootPart.Parent ~= nil) do
				UserBodyVelocity.Velocity = RootPart.CFrame.LookVector * NumberValue.Value
				RunService.PreSimulation:Wait()
			end
		end)
		
		local FallJob = Job.Extend(MainJob)
		
		local FadeTween = TweenService:Create(NumberValue, TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{Value = 30}
		)
			
		FadeTween:Play()

		FallJob:Task(UpVelocity)
		FallJob:Task(UserBodyVelocity)
		
		do
			local Dragon1 = script.Dragon1:Clone()
			EffectUtility.Weld(Dragon1, RootPart, CFrame.new(0, -3, 0) * CFrame.Angles(0, math.pi, 0))

			local Dragon2 = script.Dragon2:Clone()
			EffectUtility.Weld(Dragon2, RootPart, CFrame.new(0, -3, 0) * CFrame.Angles(0, math.pi, 0))

			local Info = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			
			for _, Item in {Dragon1, Dragon2} do
				for _, Part in pairs(Item:GetDescendants()) do
					if Part:IsA("BasePart") then
						Part.Transparency = 1
						
						if (Part.Name ~= "RootPart") then
							TweenService:Create(Part, Info, {Transparency = 0}):Play()
						end
					end
				end
			end
			
			Dragon1.Parent = workspace.Visuals
			Dragon2.Parent = workspace.Visuals

			local Dragon1Animation = Dragon1.Humanoid.Animator:LoadAnimation(Animations.AirDragon1)
			local Dragon2Animation = Dragon2.Humanoid.Animator:LoadAnimation(Animations.AirDragon2)

			Dragon1Animation.Stopped:Once(function()
				Dragon1:Destroy()
			end)

			Dragon2Animation.Stopped:Once(function()
				Dragon2:Destroy()
			end)
			
			Dragon1Animation:Play(0, 1, Animation.Speed)
			Dragon2Animation:Play(0, 1, Animation.Speed)

			MainJob:Task(Dragon1)
			MainJob:Task(Dragon2)
		end
		
		MainJob:Task(EffectUtility.AddSFX(script.SFX.Windup, Torso, 0.3))
		
		--local function Land()
		--	AirImpactLandEvent:FireServer()
		--end

		--MainJob:Task(Animation:GetMarkerReachedSignal("spawn"):Connect(function()
		--	if EffectUtility.Distance_Close(Model) then
		--		CameraShake(1.25, 30, 0.01, 0.4, Vector3.one * 0.8, Vector3.one * 0.15)
		--		Vignette(Jin_Color, 0.35, 0.4)
		--	end
			
		--	BugoVFX(VFX.Spawn, RootPart)
		--end))
		
		do
			if EffectUtility.Distance_Close(Model) then
				CameraShake(2, 20, 0.01, 0.4, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Jin_Color, 0.5, 0.3)
			end

			BugoVFX(VFX.Spawn, RootPart)
		end
		
		local VFX1 = VFX.Beam.Emit.ImpaleJump:Clone()
		local VFX2 = VFX.Beam.Emit.VFXPart:Clone()

		MainJob:Task(Animation:GetMarkerReachedSignal("trails"):Connect(function()
			BugoVFX(VFX.BeamMeshTrail, RootPart)

			EffectUtility.Weld(VFX1, RootPart, CFrame.new(0.135, -0.414, -4.062) * CFrame.Angles(math.rad(65.267), 0, 0))
			EffectUtility.Weld(VFX2, RootPart)
			
			VFX1.Parent = workspace.Visuals
			VFX2.Parent = workspace.Visuals
			
			for _, Item in {VFX1, VFX2} do
				for _, particle in pairs(Item:GetDescendants()) do
					if particle:IsA("Beam") then
						particle.Enabled = true
					end
				end
			end
			
			MainJob:Task(VFX1)
			MainJob:Task(VFX2)
		end))
		
		MainJob:Task(Animation:GetMarkerReachedSignal("drop"):Connect(function(Parameter : string)
			if (Parameter == "true") then
				if EffectUtility.Distance_Close(Model) then
					CameraShake(1.5, 25, 0.01, 0.4, Vector3.one * 0.8, Vector3.one * 0.15)
					Vignette(Jin_Color, 0.35, 0.4)
				end
				
				BugoVFX(VFX.BeamMesh, RootPart)
				
				for _, Item in {VFX1, VFX2} do
					for _, particle in pairs(Item:GetDescendants()) do
						if particle:IsA("ParticleEmitter") then
							particle.Enabled = true
						end
					end
				end

				local Elapsed = 0
				local StartCF = RootPart.CFrame
				local Origin : Vector3 = StartCF.Position

				local Map = workspace:FindFirstChild("Map")
				local Models = workspace:FindFirstChild("Models")

				local MapModel = Map:FindFirstChild("Model")
				local Props = MapModel:FindFirstChild("Props")

				local Ball = workspace:FindFirstChild("Ball")
				
				local Params = RaycastParams.new()
				Params.FilterType = Enum.RaycastFilterType.Exclude
				Params.FilterDescendantsInstances = {Models, Props, workspace.Visuals}

				if Ball then
					Params:AddToFilter(Ball)
				end
				
				local Raycast = workspace:Raycast(
					Origin, 
					(StartCF * CFrame.Angles(math.rad(45), 0, 0)).UpVector * -1000,
					Params
				)

				if Raycast then
					local Distance = (Origin - Raycast.Position).Magnitude * 1.15
	
					--MainJob:Task(Retrieved.Humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
					--	--if IsMainPlayer then
					--	--	AirImpactLandEvent:FireServer()
					--	--end
						
					--	RootPart.AssemblyLinearVelocity = Vector3.zero
					--	FallJob:Destroy()
					--end))
					
					MainJob:Task(Retrieved.Humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
						FallJob:Destroy()
					end))

					--UpVelocity.LineVelocity = 0
					
					FadeTween:Pause()
					NumberValue.Value = Distance
					UpVelocity.LineVelocity = 0
					
					--TweenService:Create(NumberValue, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					--	{Value = Distance}
					--):Play()

					TweenService:Create(UpVelocity, TweenInfo.new(0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
						{LineVelocity = -Distance}
					):Play()
		
					if IsMainPlayer then
						FallJob:Task(CameraShake(2, 20, 0.01, 0, Vector3.one * 0.8, Vector3.one * 0.25))
						FallJob:Task(task.defer(function()
							while true do
								Vignette(Jin_Color, 0.6, 0.3)
								task.wait(0.15)
							end
						end))
					end
				end
				
			elseif (Parameter == "false") then
				for _, Item in {VFX1, VFX2} do
					for _, particle in pairs(Item:GetDescendants()) do
						if particle:IsA("ParticleEmitter") or particle:IsA("Beam") then
							particle.Enabled = false
						end
					end
				end
			end
		end))
		
		MainJob:Task(Animation:GetMarkerReachedSignal("shoot"):Connect(function()
			if EffectUtility.Distance_Close(Model) then
				CameraShake(3, 30, 0.01, 0.7, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Jin_Color, 0.35, 0.4)
			end
			
			RootPart.AssemblyLinearVelocity = Vector3.zero

			MainJob:Task(EffectUtility.AddSFX(script.SFX.Slam, Torso, 0.5))

			--FallJob:Destroy()
			
			--if IsMainPlayer then
			--	AirImpactLandEvent:FireServer()
			--end
		
			local Position = (RootPart.CFrame * CFrame.new(0, -2.76, -2.279)).Position
			local Direction = Vector3.yAxis * -10
	
			--local Attachment = Instance.new("Attachment")
			--Attachment.WorldPosition = Position
			--Attachment.Parent = workspace.Terrain
			--EffectUtility.AddSFX(script.SFX.Slam, Attachment)
			--task.delay(3, Attachment.Destroy, Attachment)
			
			coroutine.wrap(RockHandler.Crater)(Position, Direction, {
				Amount = 8,
				Distance = 5,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = -5,
					Max = -5
				},

				Exposure = {
					Min = 0.5,
					Max = 0.7
				},

				BaseZ = 1.35,

				SizeMultiplier = 0.9,
			})

			coroutine.wrap(RockHandler.Crater)(Position, Direction, {
				Amount = 13,
				Distance = 6.5,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = 7,
					Max = -7
				},

				Exposure = {
					Min = 0.5,
					Max = 0.7
				},

				SizeMultiplier = 1.15,
			})

			coroutine.wrap(RockHandler.Rockst)(Position, Direction, {
				Count = 20,
				Size = {0.35, 0.9},
				Velocity = 65,
			})
			
			BugoVFX(VFX.Shoot, RootPart)
		end))
		
		MainJob:Task(Animation:GetMarkerReachedSignal("slide"):Connect(function()
			local SlideVFX = VFX.LandEnabled.Emit.VFXPart:Clone()
			EffectUtility.Weld(SlideVFX, RootPart)
			SlideVFX.Parent = workspace.Visuals
			
			EffectUtility.ToggleForTime(SlideVFX, 0.8, nil, true)
			
			MainJob:Task(function()
				EffectUtility.Toggle(SlideVFX, false)
				task.delay(3, SlideVFX.Destroy, SlideVFX)
			end)
			
			local NumberValue = Instance.new("NumberValue")
			NumberValue.Value = 65
			
			MainJob:Task(task.defer(function()
				while RootPart and RootPart.Parent and NumberValue.Value > 20 do
					local CF = RootPart.CFrame * CFrame.new(0, 0, -4)

					RockHandler.RocksWithoutPreset(
						{RaycastDistance = 5, Messy = false, Spacing = 1.5}, 
						CF
					)

					coroutine.wrap(RockHandler.Rockst)(CF.Position, Vector3.yAxis * -12.5, {
						SpawnVariance = 1.5,
						Count = 2,
						Size = {0.4, 0.7},
						XZVelocity = NumberRange.new(0.2, 0.4),
						Velocity = 50,
					})

					task.wait(0.05)
				end
			end))

			TweenService:Create(NumberValue, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{Value = 0}
			):Play()
			
			if IsMainPlayer then
				
				local SlideVelocity = VelocityUtil.Create(RootPart, "WhirlwindSlamAirEndSlide")
				SlideVelocity.Velocity = RootPart.CFrame.LookVector
				SlideVelocity.MaxForce = vector.create(80_000, 0, 80_000)
				
				NumberValue.Parent = SlideVelocity
				SlideVelocity.Parent = RootPart

				task.spawn(function()
					while (not MainJob.Destroyed and SlideVelocity.Parent ~= nil and RootPart.Parent ~= nil) do
						SlideVelocity.Velocity = RootPart.CFrame.LookVector * NumberValue.Value
						RunService.PreSimulation:Wait()
					end
				end)
				
				MainJob:Task(SlideVelocity)
	
				local Shake = MainJob:Task(CameraShake(1, 10, 0.01, 0, Vector3.one * 0.8, Vector3.one * 0.3))

				MainJob:Task(task.delay(0.8, function()
					if Shake then
						Shake:StartFadeOut(0.3)
					end
				end))
			end
		end))
	end,
}