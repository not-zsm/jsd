local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Client.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Chara["Bloody Mary"]

---------------------------------------------------------------------

local RockHandler = require( ReplicatedStorage.Client.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Client.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Client.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Client.Replication.Global.Blood )


local RunCameraRig = require( ReplicatedStorage.Client.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Client.Replication.Global.Yuki_FOV )


local Afterimage = require( ReplicatedStorage.Client.Replication.Global.Afterimage )
local ATrainAfterimage = require( ReplicatedStorage.Client.Replication.Global.ATrainAfterimage )

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )

local VelocityUtil = require( ReplicatedStorage.Shared.Game.Velocity.VelocityUtil )

local StartupVFX = script.StartupVFX
local HitVFX = script.HitVFX

---------------------------------------------------------------------

local function Distance_Close(Model : Model)
	return (if LocalPlayer.Character == Model then true else LocalPlayer:DistanceFromCharacter(Model.PrimaryPart.Position) < 15)
end

local function Distance_Far(Model : Model)
	return (if LocalPlayer.Character == Model then true else LocalPlayer:DistanceFromCharacter(Model.PrimaryPart.Position) < 75)
end

return {
	Hit = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Hit)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job

		local Knife = Model:FindFirstChild("Knife")

		local function VFX(Effect : BasePart)
			local CF = RootPart.CFrame * (Effect.CFrame - Vector3.yAxis * 3)
			
			local Clone = Effect:Clone()
			Clone:PivotTo(CF)
			Clone.Parent = workspace.Visuals
			EffectUtility.Emit(Clone)
			
			return CF
		end
		
		Job:Task(EffectUtility.AddSFX(script.ConnectSFX, Torso, 0.6))
		
		Job:Task(function()
			if Knife then
				Knife.Handle.BladeAttachment.Trail.Enabled = false
			end
		end)
		
		local function Toggle_Knife(Value : boolean)
			if Knife then
				Knife.Handle.BladeAttachment.Trail.Enabled = Value
			end
		end
		
		do
			local Spin = HitVFX.spin:Clone()
			EffectUtility.Weld(Spin, Model.Torso)
			Spin.Parent = workspace.Visuals

			local Flick = HitVFX.flick:Clone()

			if Knife then
				EffectUtility.Weld(Flick, Knife.BladeInner)
				Flick.Parent = workspace.Visuals
			end

			Job:Task(Spin)
			Job:Task(Flick)

			Job:Task(Animation:GetMarkerReachedSignal("spin"):Connect(function(Parameter : string)
				EffectUtility.Toggle(Spin, (Parameter == "true"))
			end))

			Job:Task(Animation:GetMarkerReachedSignal("flick"):Connect(function()
				Toggle_Knife(true)
				task.delay(1, Toggle_Knife, false)
				
				local AfterimageVanishInfo = {0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out}
				local AfterimageMoveInfo = {0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out}
				
				local function Afterimage_Effect(Afterimage : Model)
					local Highlight = Instance.new("Highlight")
					Highlight.FillColor = Color3.fromRGB(161, 45, 16)
					Highlight.OutlineColor = Color3.new(0, 0, 0)
					Highlight.FillTransparency = -10
					Highlight.OutlineTransparency = 1
					Highlight.Parent = Afterimage
					
					local Tween = TweenService:Create(Highlight, TweenInfo.new(table.unpack(AfterimageVanishInfo)),
						{FillTransparency = 1, OutlineTransparency = 1}
					)
					
					Tween:Play()
					
					Tween.Completed:Once(function()
						Highlight:Destroy()
					end)
					
					if Distance_Close(Model) then
						CameraShake(0.75, 20, 0.01, 0.2, Vector3.one * 0.8, Vector3.one * 0.3)
					end
				end
				
				task.spawn(function()
					for Index = 1, 5 do
						Afterimage(Model, AfterimageVanishInfo, AfterimageMoveInfo, 2, Afterimage_Effect)
						task.wait(0.13)
					end
				end)
				
				EffectUtility.Emit(Flick, true)
			end))
		end
		
		do
			local Knee = HitVFX.kneehit:Clone()
			Job:Task(Knee)

			local Shake 

			Job:Task(Animation:GetMarkerReachedSignal("knee"):Connect(function(Parameter : string)
				if (Parameter == "true") then
					Knee:PivotTo((RootPart.CFrame * Knee.CFrame) - Vector3.yAxis * 3)
					Knee.Parent = workspace.Visuals
					EffectUtility.Emit(Knee, true)

					for _, ParticleEmitter in pairs(Knee.slow:GetDescendants()) do 
						if ParticleEmitter.ClassName == "ParticleEmitter" then 
							local Tween = TweenService:Create(ParticleEmitter, TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TimeScale = 0})
							Tween:Play()

							task.spawn(function()
								Tween.Completed:Wait()
								Tween:Destroy()
							end)
						end 
					end
					
					if Distance_Close(Model) then
						Shake = Job:Task(CameraShake(1.5, 25, 0.025, 0, Vector3.one * 0.8, Vector3.one * 0.1))
						Vignette(Color3.fromRGB(255, 0, 0), 0.5, 0.6)
					end

				elseif (Parameter == "false") then
					for _, ParticleEmitter in pairs(Knee.slow:GetDescendants()) do 
						if ParticleEmitter.ClassName == "ParticleEmitter" then 
							local Tween = TweenService:Create(ParticleEmitter, TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TimeScale = 1})
							Tween:Play()

							task.spawn(function()
								Tween.Completed:Wait()
								Tween:Destroy()
								Knee:Destroy()
							end)
						end 
					end

					VFX(HitVFX.kneehit_end)
					
					if Shake then
						Shake:StartFadeOut(0.05)
					end

					if Distance_Close(Model) then
						CameraShake(2, 20, 0.01, 0.3, Vector3.one * 0.8, Vector3.one * 0.25)
						Vignette(Color3.fromRGB(255, 0, 0), 0.35, 0.35)
					end
				end
			end))
		end
		
		do
			local FinalHit = HitVFX.finalhit:Clone()
			Job:Task(FinalHit)

			local Shake 
			
			Job:Task(Animation:GetMarkerReachedSignal("finalhit"):Connect(function(Parameter : string)
				if (Parameter == "true") then
					FinalHit:PivotTo((RootPart.CFrame * FinalHit.CFrame) - Vector3.yAxis * 3)
					FinalHit.Parent = workspace.Visuals
					EffectUtility.Emit(FinalHit, true)

					for _, ParticleEmitter in pairs(FinalHit.slow:GetDescendants()) do 
						if ParticleEmitter.ClassName == "ParticleEmitter" then 
							local Tween = TweenService:Create(ParticleEmitter, TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TimeScale = 0.005})
							Tween:Play()

							task.spawn(function()
								Tween.Completed:Wait()
								Tween:Destroy()
							end)
						end 
					end
					
					if Distance_Close(Model) then
						Shake = Job:Task(CameraShake(1, 22.5, 0.01, 0, Vector3.one * 0.8, Vector3.one * 0.1))
						Vignette(Color3.fromRGB(255, 0, 0), 0.5, 0.6)
					end

				elseif (Parameter == "false") then
					if Shake then
						Shake:StartFadeOut(0.05)
					end
					
					if Distance_Close(Model) then
						CameraShake(3, 25, 0.01, 0.4, Vector3.one * 0.8, Vector3.one * 0.25)
						Vignette(Color3.fromRGB(255, 0, 0), 0.35, 0.35)
					end
					
					for _, ParticleEmitter in pairs(FinalHit.slow:GetDescendants()) do 
						if ParticleEmitter.ClassName == "ParticleEmitter" then 
							local Tween = TweenService:Create(ParticleEmitter, TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TimeScale = 1})
							Tween:Play()

							task.spawn(function()
								Tween.Completed:Wait()
								Tween:Destroy()
								FinalHit:Destroy()
							end)
						end 
					end

					VFX(HitVFX.finalhit_end)
	
					Toggle_Knife(true)
				end
			end))
		end
		
		Job:Task(Animation:GetMarkerReachedSignal("slash"):Once(function()
			VFX(HitVFX.slash)
			VFX(HitVFX.slash_hit)
			
			if Distance_Close(Model) then
				CameraShake(1.75, 25, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.25)
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("kick"):Once(function()
			VFX(HitVFX.kick)

			if Distance_Close(Model) then
				CameraShake(1.75, 25, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.25)
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("teleport"):Once(function()
			VFX(HitVFX.teleport)
			
			ATrainAfterimage(Model, true)
			task.delay(0.3, ATrainAfterimage, Model, false)
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("stab"):Once(function()
			local CF = VFX(HitVFX.stab)
			local Position = CF.Position
			local Direction = Vector3.yAxis * -5

			if Distance_Close(Model) then
				CameraShake(2.5, 25, 0.01, 0.5, Vector3.one * 0.8, Vector3.one * 0.25)
				Vignette(Color3.fromRGB(255, 0, 0), 0.35, 0.35)
			end

			if VictimModel and VictimModel.Parent then
				Blood.BloodRays("SpitOut", VictimModel.Head.MouthAttachment)
			end

			task.spawn(RockHandler.Crater, Position, Direction, {
				Amount = 5,
				Distance = 3,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = -5,
					Max = -5
				},

				Exposure = {
					Min = 0.45,
					Max = 0.6
				},

				BaseZ = 1.35,

				SizeMultiplier = 0.65,
			})

			task.spawn(RockHandler.Crater, Position, Direction, {
				Amount = 8,
				Distance = 6,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = 7,
					Max = -7
				},

				Exposure = {
					Min = 0.475,
					Max = 0.575
				},

				SizeMultiplier = 0.85,
			})

			task.spawn(RockHandler.Rockst, Position, Direction, {
				Count = 20,
				Size = {0.15, 0.75},
				Velocity = 50,
			})
		end))
	
		task.spawn(function() -- different thread, since the .new errors
			if not VictimModel or not VictimModel.Parent then return end

			local VictimRetrieved = AnimationRetriever.new(VictimModel, Animations.Victim)

			if (VictimRetrieved ~= nil) then
				local VictimAnimation = VictimRetrieved.Animation
				local VictimJob = VictimRetrieved.Job
				
				VictimJob:Task(VictimAnimation:GetMarkerReachedSignal("land"):Connect(function(Parameter : string)
					VFX(HitVFX.Lands[Parameter])
				end))
			end
		end)
	end,
	
	Dropkick = function(VictimModel : Model)
		if not VictimModel or not VictimModel.Parent then return end
		
		EffectUtility.AddSFX(script.DropkickSFX, VictimModel.PrimaryPart)
	end,

	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job

		local Knife = Model:FindFirstChild("Knife")

		local function Toggle_Knife(Value : boolean)
			if (Knife and Knife.Parent) then
				Knife.Handle.BladeAttachment.Trail.Enabled = Value
			end
		end
		
		if Knife then
			Job:Task(function()
				if (Knife and Knife.Parent) then
					Knife.Handle.BladeAttachment.Trail.Enabled = false
				end
			end)
		end

		local function VFX(Effect : BasePart, DoWeld : boolean?)
			local Offset = (Effect.CFrame - Vector3.yAxis * 3)
			
			local Clone = Effect:Clone()
			Clone.CFrame = RootPart.CFrame * Offset
			
			if DoWeld then
				EffectUtility.Weld(Clone, RootPart, Offset)
			end
			
			Clone.Parent = workspace.Visuals
			EffectUtility.Emit(Clone)
		end
		
		Job:Task(EffectUtility.AddSFX(script.StartupSFX, Torso, 0.3))
	
		local Max = 52.5
		local Multiply = 0
		local FadeOut = false

		local Velocity = VelocityUtil.Create(RootPart, "Bloody Mary Start")
		Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
		Velocity.Parent = RootPart

		Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
			Velocity.Velocity = RootPart.CFrame.LookVector * Multiply
		end)

		local StartFadeInJob; StartFadeInJob = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
			if Multiply <= -25 then
				return StartFadeInJob:Destroy()
			end
			
			Multiply -= (Delta * 60) * 2
		end)

		Job:Task(Velocity)
		
		Job:Task(Animation:GetMarkerReachedSignal("kick"):Connect(function()
			Multiply *= 1.75
			
			Job:Task(task.delay(0.4, function()
				local Job; Job = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
					if Multiply < 0 then
						Multiply = math.clamp(Multiply + (Delta * 60) * 1.3, -Max, 0)
					else
						Job:Destroy()
					end
				end)
			end))
			
			VFX(StartupVFX.dropkick)
		end))

		Job:Task(Animation:GetMarkerReachedSignal("land"):Connect(function()
			VFX(StartupVFX.land)
			Toggle_Knife(true)
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("dash"):Connect(function()
			VFX(StartupVFX.dash)

			Multiply = 100

			Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
				Multiply = math.clamp(Multiply - (Delta * 60) * 0.85, 0, Max)
			end)
		end))

		Job:Task(Animation:GetMarkerReachedSignal("hit"):Connect(function()
			VFX(StartupVFX.slash, true)
			task.delay(0.4, Toggle_Knife, false)
		end))

		do
			local Spin = StartupVFX.spin:Clone()
			EffectUtility.Weld(Spin, Model.Torso)
			Spin.Parent = workspace.Visuals

			local Eye = StartupVFX.head:Clone()
			EffectUtility.Weld(Eye, Model.Head)
			Eye.Parent = workspace.Visuals

			local Flick = StartupVFX.flick:Clone()

			if Knife then
				EffectUtility.Weld(Flick, Knife.BladeInner)
				Flick.Parent = workspace.Visuals
			end

			Job:Task(Spin)
			Job:Task(Eye)
			Job:Task(Flick)

			Job:Task(Animation:GetMarkerReachedSignal("spin"):Connect(function(Parameter : string)
				EffectUtility.Toggle(Spin, (Parameter == "true"))
				Toggle_Knife(Parameter == "true")
			end))

			Job:Task(Animation:GetMarkerReachedSignal("eye"):Connect(function()
				EffectUtility.Emit(Eye, true)
			end))

			Job:Task(Animation:GetMarkerReachedSignal("flick"):Connect(function()
				EffectUtility.Emit(Flick, true)
			end))
		end
	end,
}