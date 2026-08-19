local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Animations = ReplicatedStorage.Animations.Attacks.Universal.Railgun

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

return {
	Start = function(Model : Model, RandomFriend)
		local Retrieved = AnimationRetriever.new(Model, Animations.User)
		if (Retrieved == nil) then return end

		local Job = Retrieved.Job
		local Animation = Retrieved.Animation
		
		local RootPart = Retrieved.RootPart
		
		local AnimationsToPosition = {}
		
		local Railgun = Job:Task(script.RailGun:Clone())
		Railgun.Parent = Model
		
		local Weld = Instance.new("Motor6D")
		Weld.Name = "BodyHandle"
		Weld.C0 = CFrame.new(-1.125, 1.273, -0.69)
		Weld.C1 = CFrame.new(0.5, -1, -0.625)
		Weld.Part0 = RootPart
		Weld.Part1 = Railgun.Body.BodyHandle
		Weld.Parent = RootPart
		
		local VFXPart = Job:Task(script.EffectPart:Clone())
		VFXPart.Parent = workspace.Visuals
		
		local EffectWeld = Instance.new("Motor6D")
		EffectWeld.Name = "EffectPart"
		EffectWeld.C0 = CFrame.new(-0.969, 1.361, -9.973)
		EffectWeld.Part0 = RootPart
		EffectWeld.Part1 = VFXPart
		EffectWeld.Parent = RootPart
		
		local Friend = script.Friend:Clone()
		EffectUtility.Weld(Friend, RootPart, CFrame.new(0, 0, 3.947))
		Friend.Parent = workspace.Visuals

		Job:Task(Friend)
	
		task.spawn(function()
			if RandomFriend then
				local Humanoid = Friend:WaitForChild("Humanoid")
				local Description = Players:GetHumanoidDescriptionFromUserId(tonumber(RandomFriend.Id))

				if Description then
					Humanoid:ApplyDescription(Description)
				end
			end
		end)
		
		local FriendAnimation = Friend.Humanoid.Animator:LoadAnimation(Animations.Friend)
		AnimationsToPosition[FriendAnimation] = true

		Job:Task(RunService.PreAnimation:Connect(function()
			for AnimationToPosition in AnimationsToPosition do
				if AnimationToPosition.IsPlaying then
					AnimationToPosition.TimePosition = Animation.TimePosition
				end
			end
		end))

		Job:Task(FriendAnimation.Stopped:Once(function()
			Friend:Destroy()
		end))
		
		FriendAnimation:Play(0)
		
		local ChargeShake
		
		local ScreenVFX = coroutine.create(function()
			while true do
				Vignette(Color3.new(0.447059, 0.741176, 1), 0.3, 0.1)
				task.wait(0.075)
			end
		end)
		
		Job:Task(function()
			Utility.CloseThreadSafe(ScreenVFX)
		end)
		
		Job:Task(Animation:GetMarkerReachedSignal("ChargeStart"):Connect(function()
			EffectUtility.Toggle(Railgun.Plate.ChargeUpFX, true)	
			
			if Players:GetPlayerFromCharacter(Model) == LocalPlayer then
				Yuki_FOV.Tween(40, {4})
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("ChargeReady"):Connect(function()
			ChargeShake = CameraShake(1, 25, 0.1, 0)
			
			coroutine.resume(ScreenVFX)
			
			EffectUtility.Toggle(Railgun.Plate.BarrelHandle.ChargeComplete, true)	
			EffectUtility.Toggle(Railgun.Plate.BarrelHandle.FinishedCharge, true)	
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("Shoot"):Connect(function()
			if (ChargeShake ~= nil) then
				ChargeShake:StartFadeOut(0.01)
			end
			
			Utility.CloseThreadSafe(ScreenVFX)
			
			Railgun.Plate.ChargeUpFX:Destroy()
			Railgun.Plate.BarrelHandle.ChargeComplete:Destroy()
			Railgun.Plate.BarrelHandle.FinishedCharge:Destroy()
			
			EffectUtility.Toggle(VFXPart.BeamFolder, true, true)
			EffectUtility.Emit(VFXPart.ShotTaken)
			
			if Players:GetPlayerFromCharacter(Model) == LocalPlayer then
				local ImpactHighlight = Job:Task(script.ImpactHighlight:Clone())
				ImpactHighlight.Parent = Model

				local ImpactHighlight2 = Job:Task(script.ImpactHighlight:Clone())
				ImpactHighlight2.Parent = Friend
				
				local ImpactFrame = Job:Task(script.ColorCorrection:Clone())
				ImpactFrame.Parent = game.Lighting
				
				task.delay(0.075, function()
					ImpactFrame.Brightness = -10
					ImpactHighlight.FillColor = Color3.fromRGB(255, 255, 255)
					ImpactHighlight2.FillColor = Color3.fromRGB(255, 255, 255)
					
					task.delay(0.075, ImpactHighlight.Destroy, ImpactHighlight)
					task.delay(0.075, ImpactHighlight2.Destroy, ImpactHighlight2)
					task.delay(0.075, ImpactFrame.Destroy, ImpactFrame)
				end)
			end
			
			if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 250 then
				CameraShake(10, 125, 0.01, 1.5)
				Yuki_FOV.Tween(CurrentCamera.FieldOfView + 70, {0.25})

				task.delay(1.5, function()
					Yuki_FOV.Tween(70, {2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In})
				end)
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("StartFade"):Connect(function()
			for _, Beam in VFXPart.BeamFolder:GetChildren() do
				TweenService:Create(Beam, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextureSpeed = 0, Brightness = 0}):Play()
			end
			
			task.delay(3, VFXPart.Destroy, VFXPart)
		end))
	end,
}
