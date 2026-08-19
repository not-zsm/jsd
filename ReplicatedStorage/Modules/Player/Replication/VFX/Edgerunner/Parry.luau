local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Global.Block.Edgerunner

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local Shockwave = require( ReplicatedStorage.Modules.Player.Replication.Global.Shockwave )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )
local DashRocks = require( ReplicatedStorage.Modules.Player.Replication.Global.DashRocks )

return {
	Start = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Catch)
		if (Retrieved == nil) then return end
		
		local Job = Retrieved.Job
		local Animation = Retrieved.Animation
		
		if EffectUtility.Distance_Close(Model) then
			CameraShake(1.35, 15, 0.01, 0.6, Vector3.one * 0.8, Vector3.one * 0.4)
			Vignette(Color3.fromRGB(255, 198, 53), 0.75, 0.3)
		end
		
		Job:Task(EffectUtility.AddSFX(script.SFX, Model.PrimaryPart, 0.3))
		
		if (VictimModel and VictimModel.Parent) then
			Job:Task(EffectUtility.AddSFX(script.VictimSFX, VictimModel.PrimaryPart, 0.3))
		end
		
		Job:Task(Animation:GetMarkerReachedSignal("Push"):Connect(function()
			if EffectUtility.Distance_Close(Model) then
				CameraShake(1, 10, 0.01, 0.35, Vector3.one * 0.8, Vector3.one * 0.25)
				
				Lighting.ExposureCompensation = 1

				TweenService:Create(Lighting, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{ExposureCompensation = 0}
				):Play()
			end
			
			Shockwave(VictimModel.PrimaryPart, Retrieved.RootPart, nil, Vector3.new(0.5, 15, 15))
			
			local VictimRetrieved = AnimationRetriever.new(VictimModel, Animations.Victim)
			if (VictimRetrieved == nil) then return end
			
			local Replication = AttributeListener.GetReplicationFromSource(VictimModel)
			local FakeArms = {}

			for _, Item in ipairs(VictimModel:GetChildren()) do
				if Item:IsA("BasePart") and string.find(Item.Name, "Arm") then
					local FakeArm = EffectUtility.WeldArmTrail(Item)
					table.insert(FakeArms, FakeArm)
				end
			end

			VictimRetrieved.Job:Task(DashRocks(VictimModel.PrimaryPart, "Backward Dash", 1, function()
				for _, Arm in FakeArms do
					EffectUtility.Toggle(Arm, false)
					task.delay(1, Arm.Destroy, Arm)
				end
			end))
		end))
		
		EffectUtility.EmitEffects(script["Clash Initial"], Retrieved.RootPart)
		EffectUtility.EmitEffects(script.Spark, Model["Left Arm"], nil, CFrame.new(0, -1, 0))
	end,
}