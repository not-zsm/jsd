local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local LocalPlayerGui = LocalPlayer.PlayerGui

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Chara["Cursed Remedy"]

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )
local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

return {
	Start = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Finisher)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local MainAnimation, MainJob = Retrieved.Animation, Retrieved.Job
		
		local Knife = Model:FindFirstChild("Knife")
		local VictimHead : BasePart = VictimModel:FindFirstChild("Head")
		local VictimHumanoid : Humanoid = VictimModel:FindFirstChild("Humanoid")
		
		local IsLocalSource = (LocalPlayer.Character == Model or LocalPlayer.Character == VictimModel)
		
		local PlayRareSound = (math.random(1, 10) == 1)

		if IsLocalSource then
			local Camera = script.Camera:Clone()
			Camera:PivotTo(RootPart.CFrame)
			Camera.Parent = workspace.Visuals
			
			local ColorCorrection = script.ColorCorrection:Clone()
			ColorCorrection.Enabled = false
			ColorCorrection.Parent = Lighting
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("zoom_scare"):Connect(function(Parameter : string)
				ColorCorrection.Enabled = (Parameter == "start")
				
				if ColorCorrection.Enabled then
					TweenService:Create(ColorCorrection, TweenInfo.new(3.216666666666667, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
						Contrast = 1.3,
						Saturation = -0.5
					}):Play()
				end
			end))
				
			local CameraAnimation = Camera.Humanoid.Animator:LoadAnimation(Animations.FinisherCamera)
		
			MainJob:Task(CameraAnimation.Stopped:Once(function()
				Camera:Destroy()
			end))
			
			MainJob:Task(CameraAnimation:GetMarkerReachedSignal("hide_head"):Connect(function(Parameter : string)
				local Transparency = (Parameter == "true" and 1 or 0)

				if VictimHumanoid then
					for _, Item in ipairs(VictimHumanoid:GetAccessories()) do
						local Handle = Item:FindFirstChild("Handle")

						if Handle then
							Handle.Transparency = Transparency
						end
					end
				end
				
				if VictimHead then
					VictimHead.Transparency = Transparency
					
					for _, Item in ipairs(VictimHead:GetChildren()) do
						if Item:IsA("BasePart") or Item:IsA("Decal") then
							Item.Transparency = Transparency
						end
					end
				end
			end))

			MainJob:Task(MainAnimation:GetMarkerReachedSignal("camera"):Connect(function()
				RunCameraRig(RootPart, Camera)
			end))
			
			--local ScreenCover = MainJob:Task(script.ScreenCover:Clone())
			--ScreenCover.Enabled = true
			--ScreenCover.Frame.BackgroundTransparency = 1
			--ScreenCover.Parent = LocalPlayerGui
			
			--TweenService:Create(ScreenCover.Frame, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			--	{BackgroundTransparency = 0}
			--):Play()

			--MainJob:Task(task.delay(0.15, function()
			--	TweenService:Create(ScreenCover.Frame, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			--		{BackgroundTransparency = 1}
			--	):Play()
			--end))
			
			local ScreenCover = MainJob:Task(script.ScreenCover:Clone())
			ScreenCover.Enabled = true
			ScreenCover.Frame.BackgroundTransparency = 0.25
			ScreenCover.Parent = LocalPlayerGui
			
			MainJob:Task(task.delay(0.15, function()
				TweenService:Create(ScreenCover.Frame, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{BackgroundTransparency = 1}
				):Play()
			end))

			CameraAnimation:Play(0)
			
			MainJob:Task(Yuki_FOV.AnimateWithMoonFile(script.FOV))
			MainJob:Task(Camera)
			
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
			LocalPlayerGui.Statistics.Enabled = false

			task.spawn(function()
				local IconModule = require(ReplicatedStorage.Modules.Icon)
				IconModule.setTopbarEnabled(false)
			end)

			MainJob:Task(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
				LocalPlayerGui.Statistics.Enabled = true

				task.spawn(function()
					local IconModule = require(ReplicatedStorage.Modules.Icon)
					IconModule.setTopbarEnabled(true)
				end)
			end)

			LocalPlayer:SetAttribute("CannotCameraShake", true)

			MainJob:Task(function()
				LocalPlayer:SetAttribute("CannotCameraShake", nil)
			end)
		end
		
		do
			local Velocity = VelocityUtil.Create(RootPart, "HOLDIN THAT BEAM LES GO SEEYUH")
			Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
			Velocity.Parent = RootPart

			MainJob:Task(Velocity)

			local Z = -25

			Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
				if (Z == 0) then
					return Velocity:Destroy()
				end
				
				Velocity.Velocity = (RootPart.CFrame.LookVector * Z)
				
				local Elapsed = (Delta * 60)
				Z = math.min(Z + Elapsed, 0)
			end)
		end
	
		MainJob:Task(MainAnimation:GetMarkerReachedSignal("fast_block"):Connect(function(Parameter : string)
			EffectUtility.CloneAndEmit(script.VFX.fast[Parameter], RootPart)
		end))
		
		MainJob:Task(MainAnimation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
			if (Parameter == "startcatch") then
				MainJob:Task(EffectUtility.AddSFX(script.SFX[PlayRareSound and "Rare" or "Normal"], IsLocalSource and workspace or Torso, 0.4))
			end
			
			local VFX = script.VFX:FindFirstChild(Parameter)
			if (VFX == nil) then return warn("this not valid buddy") end
			
			local Attached = VFX:GetAttribute("attached")
			local Person = VFX:GetAttribute("person")
			
			if (Knife and Person == "knife") then
				
				if (Parameter == "rotate") then
					local New_VFX = VFX:Clone()
					New_VFX.Parent = Knife.BladeInner
					EffectUtility.Arc.ToggleAttachment(New_VFX, true, 0.6)
					task.delay(2, New_VFX.Destroy, New_VFX)
				else
					EffectUtility.Arc.CloneAndEmit(VFX, Knife.BladeInner)
				end
				
			else
				local Parent = (Person == "attacker" and Model) or (Person == "victim" and VictimModel)
				EffectUtility.Arc.CloneAndEmit(VFX, Parent[Attached])
			end
		end))
		
		task.spawn(function()
			local VictimRetrieved = AnimationRetriever.new(VictimModel, Animations.FinisherVictim)
			if (VictimRetrieved == nil) then return end

			VictimRetrieved.Job:Task(VictimRetrieved.Animation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
				if (Parameter == "wipe") then
					EffectUtility.Arc.CloneAndEmit(script.VFX.wipe, VictimHead)
				end
			end))
		end)
	end,
}