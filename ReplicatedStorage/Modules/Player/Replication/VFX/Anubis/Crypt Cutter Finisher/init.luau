local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local LocalPlayerGui = LocalPlayer:WaitForChild("PlayerGui")


local AnimationRetriever = require(ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever)
local RunCameraRig = require(ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig)
local CameraShake = require(ReplicatedStorage.Modules.Player.Replication.Global.CameraShake)
local RockHandler = require(ReplicatedStorage.Modules.Player.Replication.Global.RockHandler)
local EffectBlood = require(ReplicatedStorage.Modules.Player.Replication.VFX.Global.Blood)
local VelocityUtil = require(ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil)
local EffectUtility = require(ReplicatedStorage.Modules.Player.Replication.EffectUtility)
local BugoVFX = require(ReplicatedStorage.Modules.Player.Replication.EffectUtility.Bugo)
local Vignette = require(ReplicatedStorage.Modules.Player.Replication.Global.Vignette)
local Yuki_FOV = require(ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV)
local Blood = require(ReplicatedStorage.Modules.Player.Replication.Global.Blood)
local Utility = require(ReplicatedStorage.Modules.Shared.Utilities.Utility)
local Table = require(ReplicatedStorage.Packages.Table)

local Animations = ReplicatedStorage.Animations.Attacks.Anubis["Crypt Cutter"]

return { 
	Start = function(Model : Model, VictimModel : Model, SheatheModel : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.FinisherUser)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		local IsMainPlayer = (LocalPlayer.Character == Model or LocalPlayer.Character == VictimModel)
		
		local Assets = script.VFX
		
		local IsPrimary = EffectUtility.SetPrimary({Model, VictimModel})
		local SFX = Job:Task(EffectUtility.AddSFX(script.SFX, if IsMainPlayer then workspace else RootPart, 0.5))
		--local PlayerIsAttackerOrVictim = (LocalPlayer.Character == Model or LocalPlayer.Character == VictimModel)
		
		--Job:Task(EffectUtility.AddSFX(script.HitSFX, PlayerIsAttackerOrVictim and workspace or RootPart, 0.35))
		
		local StabEffect = nil
		local LightningEffect = nil
		local SheatheEffect = nil
		local DashSlashEffect = nil
		
		-- Vids
		local Videos
		IsPrimary(function()
			Videos = Job:Task(script.Videos:Clone())
			Videos.Name = "AnubisImpactFrames"
			Videos.Parent = LocalPlayerGui
		end)		
		
		local VFX = {
			["1"] = function()
				BugoVFX(Assets.KickStart, RootPart)
			end,
		
			["2"] = function()
				BugoVFX(Assets.AirLaunch, RootPart)
			end,
			
			["3"] = function()
				BugoVFX(Assets.GroundRoll, RootPart)
			end,
			
			["4"] = function()
				BugoVFX(Assets.SwordAir, RootPart)
			end,
			
			["5"] = function()
				StabEffect = Job:Task(EffectUtility.CloneAndToggle(script.AttachmentVFX.StabEffect, VictimModel.Torso, true))
				Job:Task(StabEffect)
			end,
			
			["6"] = function()
				BugoVFX(Assets.SwordStab, RootPart)
			end,
			
			["7"] = function()
				BugoVFX(Assets.Danger, RootPart)
			end,
			["8"] = function()
				BugoVFX(Assets.FlashStep, RootPart)
				
				IsPrimary(function()
					Vignette(Color3.new(0.639216, 0.0588235, 1), 0.65, 0.45 )
				end)
			end,
			["9"] = function()
				BugoVFX(Assets.SwordPullOut, RootPart) 
				
				if StabEffect then
					EffectUtility.Toggle(StabEffect, false)
				end
				
				IsPrimary(function()
					Vignette(Color3.new(1, 0, 0), 0.5, 0.3 )
				end)
			end,
			["10"] = function()
				BugoVFX(Assets.Twirl1, RootPart)
			end,
			["11"] = function()
				BugoVFX(Assets.Shealth, RootPart)
			end,
			
			["12"] = function()
				BugoVFX(Assets.Twirl2, RootPart)
			end,
			
			["13"] = function()
				BugoVFX(Assets.Twirl3, RootPart)
			end,
			
			["14"] = function()
				BugoVFX(Assets.Shine, RootPart)
			end,
			["15"] = function()
				BugoVFX(Assets.Slice, RootPart)
			end,
			
			["16"] = function()
				BugoVFX(Assets.SliceHit, RootPart)
				
				IsPrimary(function()
					Vignette(Color3.new(0, 0, 0), 0.6, 0.4)
				end)
			end,
			
			["17"] = function()
				BugoVFX(Assets.GroundRoll2, RootPart)
			end,
			
			["18"] = function()
				BugoVFX(Assets.HUH, RootPart)
			end,
			
			["19"] = function()
				LightningEffect = Job:Task(Assets.ClientSidedEnable.Root:Clone())
				LightningEffect.Weld.Part0 = RootPart
				LightningEffect.Parent = workspace.Visuals
				
				EffectUtility.Toggle(LightningEffect, true)
				
				SheatheEffect = Job:Task(EffectUtility.CloneAndToggle(script.AttachmentVFX.Sheathe, SheatheModel["Cube.004"], true))
				Job:Task(StabEffect)
			end,
			
			["20"] = function()
				BugoVFX(Assets.Dash, RootPart)
			end,
			
			["21"] = function()
				EffectUtility.Toggle(LightningEffect, false)
				EffectUtility.Toggle(SheatheEffect, false)
			end,
			
			["22"] = function()
				DashSlashEffect = Job:Task(Assets.DashSlashEnable.Root:Clone())
				DashSlashEffect.Weld.Part0 = RootPart
				DashSlashEffect.Parent = workspace.Visuals
				
				EffectUtility.Toggle(DashSlashEffect, true)
				
				IsPrimary(function()
					Vignette(Color3.new(0.639216, 0.0588235, 1), 0.5, 0.7 )
				end)
			end,
			
			["23"] = function()
				BugoVFX(Assets.Crack, RootPart)
				
				IsPrimary(function()
					Vignette(Color3.new(1, 1, 1), 0.6, 0.35)
				end)
			end,
			
			["24"] = function()
				BugoVFX(Assets.Close, RootPart)
			end,
			
			["25"] = function()
				EffectUtility.Toggle(DashSlashEffect, false)
				
				IsPrimary(function()
					Vignette(Color3.new(1, 0, 0), 0.5, 0.25 )
				end)
			end,
		}
		
		Job:Task(Animation:GetMarkerReachedSignal("VFX"):Connect(function(Parameter : string)
			local Func = VFX[Parameter]
			if Func then
				Func()
			end
		end))
		
		-- Impact Frames
		IsPrimary(function()
			Job:Task(Animation:GetMarkerReachedSignal("ImpactFrames"):Connect(function(Parameter : string)
				local Video = Videos.Frame[`Part{Parameter}`]
				if Video then
					Video.Visible = true
					Video:Play()

					Job:Task(Video.Ended:Once(function()
						Video.Visible = false
					end))
				end
			end))
		end)
		
		-- Start Camera
		IsPrimary(function()
			local Camera : Model = Job:Task(script.Cam:Clone())
			Camera:PivotTo(RootPart.CFrame)
			Camera.Parent = workspace.Visuals

			local CameraAnimation : AnimationTrack = Camera.Humanoid.Animator:LoadAnimation(Animations.FinisherCam)
			CameraAnimation:Play(0)
			
			Job:Task(RunService.PreAnimation:Connect(function()
				CameraAnimation.TimePosition = Animation.TimePosition
			end))
			
			local RemoveFOV = Yuki_FOV.AnimateWithMoonFile(ReplicatedStorage.FOVFiles["Crypt Cutter Finisher"])
			Job:Task(RemoveFOV)
			
			Job:Task(Animation:GetMarkerReachedSignal("VFX"):Connect(function(Parameter : string)
				if (Parameter == "2") then
					Job:Task(RunCameraRig(RootPart, Camera, CFrame.new(0, -3, 0), {}))
				end
			end))

			Job:Task(CameraAnimation.Stopped:Connect(function()
				if RemoveFOV then
					RemoveFOV()
					RemoveFOV = nil
				end
				
				Camera:Destroy()
			end))
		end)
	end,
}