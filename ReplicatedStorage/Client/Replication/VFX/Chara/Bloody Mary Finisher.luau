-- I'm tired

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local RunCameraRig = require( ReplicatedStorage.Client.Replication.Global.RunCameraRig )
local HideAllUI = require( ReplicatedStorage.Client.Replication.Global.HideAllUI )
local Vignette = require( ReplicatedStorage.Client.Replication.Global.Vignette )
local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local Create_Clone = require( ReplicatedStorage.Effects.Characters.Chara.Create_Clone )

local MoonUtil = require( ReplicatedStorage.Client.Replication.Global.MoonUtil )

local Job = require( ReplicatedStorage.Shared.Utilities.Job )

local AnimationRetriever = require( ReplicatedStorage.Client.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Chara["Bloody Mary"]

local Assets = script.Assets

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Finisher)
		if (Retrieved == nil) then return end

		local Animation, MainJob = Retrieved.Animation, Retrieved.Job
		local RootPart, Torso = Retrieved.RootPart, Retrieved.Torso

		do
			local Clone : Model, CloneHumanoid : Humanoid, CloneRootPart : BasePart = Create_Clone(Model, true)

			for _, Part : BasePart | Decal in ipairs(Clone:GetDescendants()) do
				if Part:IsA("BasePart") or Part:IsA("Decal") then
					Part.Transparency = 1
				end
			end

			for _, Folder in ipairs(Assets.Clone_VFX.Aura:GetChildren()) do
				for _, Item in ipairs(Folder:GetChildren()) do
					local NewAura = Item:Clone()
					NewAura.Parent = Clone[Folder.Name]
				end
			end
			
			local Highlight = Instance.new("Highlight")
			Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			Highlight.FillColor = Color3.fromRGB(38, 82, 98)
			Highlight.FillTransparency = 5
			Highlight.OutlineColor = Color3.fromRGB(234, 0, 0)
			Highlight.OutlineTransparency = 0
			Highlight.Parent = Clone
	
			Clone.Parent = workspace.Visuals

			local CloneAnimation : AnimationTrack = CloneHumanoid.Animator:LoadAnimation(Animations.FinisherClone)
			CloneAnimation:Play(0) 

			CloneAnimation.Stopped:Once(function()
				Clone:Destroy()
			end)
			
			MainJob:Task(Animation:GetMarkerReachedSignal("clone"):Connect(function()
				for _, Part : BasePart | Decal in ipairs(Clone:GetDescendants()) do
					if (Part:IsA("BasePart") and Part.Name ~= "HumanoidRootPart") or (Part:IsA("Decal") and Part.Name ~= "Face") then
						Part.Transparency = 0
						
					elseif Part:IsA("ParticleEmitter") then
						Part.Enabled = true
						Part:Emit(1)
					end
				end
			end))
			
			MainJob:Task(Animation:GetMarkerReachedSignal("clone_eye"):Connect(function(Parameter : string)
				EffectUtility.Arc.CloneAndEmit(Assets.Clone_VFX.eye, Clone.Head)
			end))
		end
		
		-- (1:25am 04/11/2025) I'm tired i'm gonna finish this tomorrow maybe
		-- (8:44am 04/11/2025) I'm doing it.
		-- (8:50am 04/11/2025) Break time! I go play azure latch
		-- (10:47am 04/11/2025) I'm back. My internet went out for like 30 mins as well
		
		if Retrieved.IsLocalSource then

			MainJob:Task(Animation:GetMarkerReachedSignal("camera"):Connect(function()
				local CameraJob = Job.Extend(MainJob)
				
				local ScreenCover = Assets.ScreenCover:Clone()
				ScreenCover.Enabled = true
				ScreenCover.Parent = LocalPlayer.PlayerGui

				CameraJob:Task(Animation:GetMarkerReachedSignal("camera_cover"):Connect(function(Parameter : string)
					ScreenCover.Frame.BackgroundTransparency = (Parameter == "true" and 0 or 1)
				end))
	
				local Camera = Assets.Camera:Clone()
				EffectUtility.Weld(Camera, RootPart)
				Camera.Parent = workspace.Visuals

				local CameraDisabled = false
				local CameraAnimation : AnimationTrack = Camera.Humanoid.Animator:LoadAnimation(Animations.FinisherCamera)

				CameraAnimation.Stopped:Once(function()
					CameraJob:Destroy()
				end)

				CameraAnimation:Play(0) 

				CameraJob:Task(RunCameraRig(RootPart, Camera, nil, {
					--DontSaveCameraPosition = true,
					DontDoTransition = true,

				}, function(Value)
					CameraDisabled = not Value
				end)) 
				
				CameraJob:Task(MoonUtil.AnimateValueWithMoonFile(Lighting, "ExposureCompensation", Assets.ExposureCompensation)) 
				-- Don't feel like doing the exposure compensation myself, thanks SolidSounds for making this
				-- Nvm it doesn't even work
				
				CameraJob:Task(ScreenCover)
				CameraJob:Task(Camera)
				CameraJob:Task(HideAllUI())
			end))
		end
		
		MainJob:Task(Animation:GetMarkerReachedSignal("eye"):Connect(function(Parameter : string)
			EffectUtility.Arc.CloneAndEmit(Assets.VFX.eye, Model.Head)
		end))

		MainJob:Task(Animation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
			local VFX = Assets.VFX:FindFirstChild(Parameter)
			
			if VFX then
				EffectUtility.Arc.CloneAndEmit(VFX, RootPart)
			end
		end))
	end,
	
	-- So many hoes they ratchet all of my hoes they ratchet
	-- Bow
}