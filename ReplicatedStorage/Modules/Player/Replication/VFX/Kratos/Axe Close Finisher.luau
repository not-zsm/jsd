local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

---------------------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )
local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )

local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

---------------------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )

---------------------------------------------------------------------------------

local Holder = script.Holder
local LocalPlayer = Players.LocalPlayer

return {
	OnStart = function(AttackerModel : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(AttackerModel, ReplicatedStorage.Animations.Attacks.Kratos["Leviathan Throw"].CloseUserFinisher)

		if (Retrieved == nil) then return end

		local Animation, NewJob = Retrieved.Animation, Retrieved.Job
		local RootPart = Retrieved.RootPart

		local Player = Players:GetPlayerFromCharacter(AttackerModel)
		local VictimPlayer = Players:GetPlayerFromCharacter(VictimModel)
		
		local PlayerIsAttackerOrVictim = (Player == LocalPlayer or VictimPlayer == LocalPlayer)
		
		local Blood = NewJob:Task(script.Holder.Blood:Clone())
		local HeadHit = NewJob:Task(script.Holder.HeadHit:Clone())
		
		Blood.Parent = VictimModel.Head
		HeadHit.Parent = VictimModel.Head
		
		EffectUtility.Toggle(Blood, true)
		EffectUtility.Emit(HeadHit, true)
		
		task.spawn(function()
			if PlayerIsAttackerOrVictim then
				local Camera = script.Camera:Clone()
				local DestroyCameraRunner = NewJob:Task(RunCameraRig(RootPart, Camera, CFrame.new(0, -2, -2)))
				Camera.Parent = workspace.Visuals

				local Animation = Camera.AnimationController.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Kratos["Leviathan Throw"].CloseCamera)
				Animation:Play(0)

				NewJob:Task(function()
					Yuki_FOV.Immune = false
					Yuki_FOV.Tween(70, {0.75})
				end)

				NewJob:Task(Animation.Stopped:Once(DestroyCameraRunner))
				NewJob:Task(Camera)
			end
			
			local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)

			if (Distance <= 15) then
				CameraShake(2, 8, 0.01, 0.15, Vector3.one * 0.8)
				Vignette(Color3.fromRGB(170, 0, 0), 0.5, 0.5)
			end
		end)

		NewJob:Task(Animation:GetMarkerReachedSignal("pullhit"):Connect(function()
			local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
			
			local HitVFX = script.NormalHit:Clone()
			HitVFX.CFrame = VictimModel.Torso.CFrame
			HitVFX.Parent = workspace.Visuals
			
			EffectUtility.Emit(HitVFX)
			EffectUtility.Emit(HeadHit, true)
			
			if (Distance <= 15) then
				CameraShake(2, 10, 0.01, 0.25, Vector3.one * 0.8)
				Vignette(Color3.fromRGB(34, 152, 255), 0.5, 0.25)
			end
		end))
		
		NewJob:Task(Animation:GetMarkerReachedSignal("finalhit"):Connect(function()
			local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
			
			local HitVFX = script.BloodHit:Clone()
			HitVFX.CFrame = VictimModel.HumanoidRootPart.CFrame
			HitVFX.Parent = workspace.Visuals

			EffectUtility.Emit(HitVFX)
			EffectUtility.Emit(HeadHit)
			
			if (Distance <= 15) then
				CameraShake(4, 15, 0.01, 0.35, Vector3.one * 0.8)
				Vignette(Color3.fromRGB(34, 152, 255), 0.25, 0.25)
			end
		end))
	end,
}