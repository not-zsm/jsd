local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Global.M1.Jimpee

local LightInfo = TweenInfo.new(1)

local SFX = script.SFX
local SwingsSFX = SFX.Swings

local Arms = {
	[1] = "Right Arm",
	[2] = "Left Arm",
	[3] = "Right Arm",
	[4] = "Left Arm"
}

return {
	Start = function(Model : BasePart, Count : number)
		local Retrieved = AnimationRetriever.new(Model, Animations[Count])
		if (Retrieved == nil) then return end

		Retrieved.Job:Task(EffectUtility.WeldArmTrail(Model[Arms[Count]]))
		Retrieved.Job:Task(EffectUtility.AddSFX(SwingsSFX[Count], Retrieved.RootPart, 0.3))
	end,
	
	Hit = function(VictimRootPart : BasePart, Count : number)
		if (VictimRootPart == nil or VictimRootPart.Parent == nil) then return end

		local VictimModel : Model = VictimRootPart.Parent
		local Distance = LocalPlayer:DistanceFromCharacter(VictimRootPart.Position)

		if EffectUtility.Distance_Close(VictimModel, 50) then
			ScreenPulse("Black Flash")
			
			if (Count == 4) then
				CameraShake(10, 50, 0.01, 1, Vector3.one * 0.8)
			else
				CameraShake(5, 50, 0.01, 0.35, Vector3.one * 0.8)
			end
		end

		local Head = VictimModel:FindFirstChild("Head")

		if Head then
			Blood.BloodRays("BigSpitOut", Head.MouthAttachment)
		end
	
		if (Count == 4) then
			EffectUtility.EmitEffects(SFX.Final_Hit, VictimRootPart)
		end
		
		EffectUtility.EmitEffects(script["Black Flash"], VictimRootPart)

		local Attachment = Instance.new("Attachment")
		Attachment.Parent = workspace.Terrain
		Attachment.WorldPosition = VictimRootPart.Position

		local Light = script.BlackFlashPointlight:Clone()
		Light.Parent = Attachment

		TweenService:Create(Light, LightInfo, 
			{Brightness = 0}
		):Play()

		task.delay(LightInfo.Time, Attachment.Destroy, Attachment)
	end,
}