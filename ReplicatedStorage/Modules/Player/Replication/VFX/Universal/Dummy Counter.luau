local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local RunCameraRig = require(ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig)
local CharacterTransparency = require(ReplicatedStorage.Modules.Player.Replication.Global.CharacterTransparency)

local Animations = ReplicatedStorage.Animations.Attacks.Universal.DummyCounter

local LocalPlayer = Players.LocalPlayer
local LocalPlayerGui = LocalPlayer.PlayerGui
local CurrentCamera = workspace.CurrentCamera

return {
	Start = function(Model : Model, Victim : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.User)
		if (Retrieved == nil) then return end

		local Job = Retrieved.Job
		local Animation = Retrieved.Animation

		local RootPart = Retrieved.RootPart
		
		local ShowCamera = (LocalPlayer.Character == Victim)

		local ISOH = Job:Task(script["Inverted Spear Of Heaven"]:Clone())
		ISOH.Parent = Model

		local Weld = Instance.new("Motor6D")
		Weld.Name = "ISOH"
		Weld.C0 = CFrame.new(0.026, -1, 0) * CFrame.Angles(0, math.rad(90), math.rad(-90))
		Weld.Part0 = Model["Right Arm"]
		Weld.Part1 = ISOH.ISOH
		Weld.Parent = Model["Right Arm"]

		local HoldVFX = Job:Task(script.TeleportHold:Clone())
		HoldVFX.CFrame = RootPart.CFrame
		HoldVFX.Parent = workspace.Visuals
		
		local Weld = Instance.new("Motor6D")
		Weld.C0 = CFrame.Angles(0, math.rad(90), 0)
		Weld.Part0 = Model.Torso
		Weld.Part1 = HoldVFX
		Weld.Parent = Model.Torso 
		
		local Camera = script.CamRig:Clone()
		Job:Task(Camera)
		
		if ShowCamera then
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
			LocalPlayerGui.Statistics.Enabled = false

			task.spawn(function()
				local IconModule = require(ReplicatedStorage.Modules.Icon)
				IconModule.setTopbarEnabled(false)
			end)

			Job:Task(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
				LocalPlayerGui.Statistics.Enabled = true

				task.spawn(function()
					local IconModule = require(ReplicatedStorage.Modules.Icon)
					IconModule.setTopbarEnabled(true)
				end)
			end) 

			Camera:PivotTo(RootPart.CFrame * CFrame.new(0, 0, -1.5))
			Camera.Parent = workspace.Visuals
			Camera.AnimationController.Animator:LoadAnimation(Animations.Camera):Play(0)

			local RemoveFOVRunner = Job:Task(Yuki_FOV.AnimateWithMoonFile(script.FOV))
			Camera.Destroying:Once(RemoveFOVRunner)

			Job:Task(RunCameraRig(RootPart, Camera, CFrame.new(0, 0, -1.5)))
		end

		Job:Task(Animation:GetMarkerReachedSignal("disappear"):Connect(function()
			local Teleport = script.Teleport:Clone()
			Teleport.CFrame = RootPart.CFrame
			Teleport.Parent = workspace.Visuals
			
			CharacterTransparency(Model, 1)

			EffectUtility.Emit(Teleport)
		end))

		Job:Task(Animation:GetMarkerReachedSignal("appear"):Connect(function()
			EffectUtility.Toggle(HoldVFX, true)
			
			CharacterTransparency(Model, 0)
			
			EffectUtility.EmitEffects(script.Appear, Model.HumanoidRootPart, nil, CFrame.new(25.6, -0.2, 2.4))
			EffectUtility.EmitEffects(script.SlideIn, Model.HumanoidRootPart, nil, CFrame.new(7.5, -3, 2.5))
			
			task.delay(1.25, function()
				EffectUtility.Toggle(HoldVFX, false)
			end)
			
			-- bro ur avatar jumnpscared me when i open studio
		end))

		--Job:Task(Animation:GetMarkerReachedSignal("speedlines"):Connect(function()

		--end))

		Job:Task(Animation:GetMarkerReachedSignal("startstab"):Connect(function()
			EffectUtility.Toggle(ISOH.ISOH, true)
		end))
		
		local Parameter = 0

		Job:Task(Animation:GetMarkerReachedSignal("stab"):Connect(function()
			Parameter += 1
			
			if Parameter == 1 then
				EffectUtility.EmitEffects(script.NeckHitFirst, Victim.Torso, nil, CFrame.new(0, 0.75, 0))
			elseif Parameter == 2 or Parameter == 3 then
				EffectUtility.EmitEffects(script.LegHit, Victim["Right Leg"])
			end
			
			EffectUtility.Toggle(ISOH.ISOH, false)

			if (HoldVFX ~= nil) then
				HoldVFX:Destroy()
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("pullout"):Connect(function(AnimParameter : number)
			if AnimParameter == "1" then
				EffectUtility.EmitEffects(script.NeckPullout, Victim.Torso, nil, CFrame.new(0, 0.75, 0))
			end
			
			EffectUtility.Toggle(ISOH.ISOH, true)
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("land"):Connect(function()
			EffectUtility.EmitEffects(script.Land, Model.HumanoidRootPart, nil, CFrame.new(-4, -3, 3) * CFrame.Angles(math.rad(-90), 0, 0))
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("sweep"):Connect(function()
			EffectUtility.EmitEffects(script.Sweep, Model.HumanoidRootPart, nil, CFrame.new(0.135, -3, -2.4) * CFrame.Angles(0, math.rad(-168), 0))
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("finalstab"):Connect(function()
			local VFX = script.Slam:Clone()
			VFX.CFrame = Model.HumanoidRootPart.CFrame * CFrame.new(0, -2.5, -1.75)
			VFX.Parent = workspace.Visuals

			EffectUtility.Emit(VFX)
			EffectUtility.Toggle(ISOH.ISOH, false)
		end))
	end,
}
