local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

---------------------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local Yuki_FOV = require( ReplicatedStorage.Client.Replication.Global.Yuki_FOV )

local AttributeListener = require( ReplicatedStorage.Client.Replication.Global.AttributeListener )
local RunCameraRig = require( ReplicatedStorage.Client.Replication.Global.RunCameraRig )
local Observer = require(ReplicatedStorage.Shared.Utilities.Observer)

---------------------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Client.Replication.VFX.AnimationRetriever )

---------------------------------------------------------------------------------

local LocalPlayer = Players.LocalPlayer

local Cache = workspace.Visuals

local Effects = script.Effects
local LocalEffectUtility = require(script.Modules.EffectUtility)

local AnimationFolder = ReplicatedStorage.Animations.Emotes["Love Train"]

local ImpactFrames = LocalPlayer.PlayerGui.ImpactFrames.LoveTrain

Observer("LoveTrainBarrier", function(Character : Model)
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local RootPart = Humanoid.RootPart
	
	local Holder = script.LoveTrainBarrierPassive:Clone()
	
	local PointLightAura = Holder.PointLightAttachment
	PointLightAura.Parent = RootPart
	
	local TrailAttachment = Holder.Trail
	TrailAttachment.Parent = RootPart
	
	Holder:Destroy()
	
	local Connection : RBXScriptConnection
	
	Connection = RunService.PostSimulation:Connect(function()
		if not Character:IsDescendantOf(workspace) then
			return Connection:Disconnect()
		end
		
		LocalEffectUtility.Enable(PointLightAura, Humanoid.MoveDirection ~= vector.zero)
		LocalEffectUtility.Enable(TrailAttachment, Humanoid.MoveDirection ~= vector.zero)
	end)
	
	local function End()
		if Connection.Connected then
			Connection:Disconnect()
		end
		
		if not Character:IsDescendantOf(workspace) then
			return
		end
		
		TweenService:Create(PointLightAura.PointLight, TweenInfo.new(0.25), {
			Brightness = 0
		}):Play()
		
		LocalEffectUtility.Enable(TrailAttachment, false)
		
		task.wait(math.max(LocalEffectUtility.GetMaxLifetime(TrailAttachment), 0.25))
		
		TrailAttachment:Destroy()
		PointLightAura:Destroy()
	end
	
	return function()
		task.spawn(End)
	end
end)

return {
	OnStart = function(Model : Model)
		local Stand = Model:WaitForChild("D4C", 100)

		local Retrieved = AnimationRetriever.new(Model, AnimationFolder.Start)
		if (Retrieved == nil) then return end
		
		local WasInterupted = true
		
		local Animation, NewJob = Retrieved.Animation, Retrieved.Job
		local Humanoid = Retrieved.Humanoid
		local RootPart = Retrieved.RootPart

		local IsMe = LocalPlayer.Character == Model
		
		local StandTrack = Stand.Controller.Animator:LoadAnimation(AnimationFolder.Stand)
		StandTrack:Play()
		
		local BoxHighlight
		local Domain
		
		if IsMe then
			local Camera = NewJob:Task(script.MJCam:Clone())
			Camera.RootPart.CFrame = RootPart.CFrame
			Camera.Parent = Cache

			local CameraAnimation = Camera.AnimationController.Animator:LoadAnimation(AnimationFolder.Camera)
			CameraAnimation:Play(0)

			NewJob:Task(RunCameraRig(RootPart, Camera, CFrame.identity, {
				DontDoTransition = true,
				DontSupportCutsceneSetting = true
			}))
			
			NewJob:Task(Yuki_FOV.AnimateWithMoonFile(script.FOV, true))
			
			NewJob:Task(function()
				local CurrentFov = workspace.CurrentCamera.FieldOfView
				
				task.wait(2 / 60)
				
				if CurrentFov ~= workspace.CurrentCamera.FieldOfView then
					return
				end
				
				Yuki_FOV.Tween(70, {0.75})
			end)
		
			NewJob:Task(CameraAnimation.Stopped:Connect(function()
				Camera:Destroy()
			end))
		
			Domain = NewJob:Task(Effects.Domain:Clone())
			Domain.PrimaryPart.CFrame = RootPart.CFrame
			Domain.Parent = Cache
			
			BoxHighlight = NewJob:Task(Instance.new("Highlight"))
			BoxHighlight.FillColor = Color3.new(1)
			BoxHighlight.FillTransparency = 1
			BoxHighlight.OutlineTransparency = 1
			BoxHighlight.OutlineColor = Color3.new(1, 1, 1)
			BoxHighlight.Enabled = true
			BoxHighlight.Parent = Domain

			EffectUtility.ToggleImpactFrames(ImpactFrames.Stage1, true)
			EffectUtility.ToggleImpactFrames(ImpactFrames.Stage2, true)

			NewJob:Task(function()
				EffectUtility.ToggleImpactFrames(ImpactFrames.Stage1, false)
				EffectUtility.ToggleImpactFrames(ImpactFrames.Stage2, false)
			end)
			
			NewJob:Task(task.delay(344/60, function()
				EffectUtility.EmitImpactFrames(ImpactFrames.Stage1, 20)
			end))
			
			NewJob:Task(task.delay(710/60, function()
				EffectUtility.EmitImpactFrames(ImpactFrames.Stage2, 20)
			end))
			
			do -- blur
				local BlurEffect = NewJob:Task(Instance.new("BlurEffect"))
				BlurEffect.Enabled = true
				BlurEffect.Size = 24
				BlurEffect.Parent = Lighting

				NewJob:Task(task.delay(50/60, function()
					if BlurEffect == nil then
						return
					end

					TweenService:Create(BlurEffect, TweenInfo.new(30/60, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
						Size = 0
					}):Play()
				end))

				NewJob:Task(task.delay(80/60, function()
					if BlurEffect == nil then
						return
					end

					BlurEffect:Destroy()
				end))
			end

			do -- cc
				local ColorCorrection = NewJob:Task(Instance.new("ColorCorrectionEffect"))
				ColorCorrection.TintColor = Color3.new()
				ColorCorrection.Brightness = 0
				ColorCorrection.Contrast = 0.1
				ColorCorrection.Saturation = 0.7
				ColorCorrection.Parent = Lighting

				TweenService:Create(ColorCorrection, TweenInfo.new(75/60, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
					TintColor = Color3.new(1, 1, 1)
				}):Play()

				NewJob:Task(task.delay(495/60, function()
					if ColorCorrection == nil then
						return
					end

					ColorCorrection:Destroy()
				end))
			end
		end

		NewJob:Task(Animation:GetMarkerReachedSignal("Emit"):Connect(function(Name)
			local ToEmit = Effects.Emit:FindFirstChild(Name)

			if not Name then
				warn(`emit effect {Name} is missing, lt`)
				return
			end

			LocalEffectUtility.SimpleEmit(ToEmit, RootPart.CFrame, Cache)
		end))

		do -- back flare
			local FlareAttachment
			local FlareAttachment2
			local Specs
			local FlareAttachment0
			local LoveTrainBarrier

			NewJob:Task(Animation:GetMarkerReachedSignal("Specs"):Once(function()
				Specs = NewJob:Task(Effects.specs:Clone())
				Specs.CFrame = RootPart.CFrame * CFrame.Angles(0, math.pi/2, 0)
				Specs.Parent = Cache

				FlareAttachment0 = NewJob:Task(Effects.flares0.Attachment:Clone())
				FlareAttachment0.Parent = RootPart
			end))

			NewJob:Task(Animation:GetMarkerReachedSignal("Flare"):Once(function()
				task.spawn(LocalEffectUtility.DisableRemove, FlareAttachment0)

				FlareAttachment = NewJob:Task(Effects.flares.Attachment:Clone())
				FlareAttachment.Parent = RootPart

				FlareAttachment2 = NewJob:Task(Effects.flares2.Attachment:Clone())
				FlareAttachment2.Parent = RootPart
			end))

			NewJob:Task(Animation:GetMarkerReachedSignal("FlareRemove"):Once(function()
				task.spawn(LocalEffectUtility.DisableRemove, FlareAttachment)
				task.spawn(LocalEffectUtility.DisableRemove, FlareAttachment2)
				task.spawn(LocalEffectUtility.DisableRemove, Specs)

				if Domain ~= nil then
					Domain:Destroy()
				end
				
				LoveTrainBarrier = NewJob:Task(Effects.barier:Clone())
				LoveTrainBarrier.barierground.Attach.Part0 =RootPart
				LoveTrainBarrier.Parent = Cache
			end))

			NewJob:Task(Animation:GetMarkerReachedSignal("BarrierRemove"):Once(function()
				WasInterupted = false
				
				LoveTrainBarrier.barierground.Anchored = true
				LoveTrainBarrier.barierground.Attach:Destroy()
				
				TweenService:Create(LoveTrainBarrier.barierground, TweenInfo.new(0.5), {
					CFrame = LoveTrainBarrier.barierground.CFrame * CFrame.new(0, -50, 0)
				}):Play()
			end))
		end
	end,
}