local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local AttributeListener = require( ReplicatedStorage.Client.Replication.Global.AttributeListener )
local DashRocks = require( ReplicatedStorage.Client.Replication.Global.DashRocks )

local VFX = {}

function VFX.Start(RootPart : BasePart)
	if (LocalPlayer.Character ~= RootPart.Parent) then
		local Replication = AttributeListener.GetReplicationFromSource(RootPart)

		local CancelAttribute : RBXScriptConnection = nil
		local RemoveFunc = nil

		local FakeArms = {}

		for _, Item in ipairs(RootPart.Parent:GetChildren()) do
			if Item:IsA("BasePart") and (string.find(Item.Name, "Right") or string.find(Item.Name, "Left")) then
				local FakeArm = EffectUtility.WeldArmTrail(Item)
				table.insert(FakeArms, FakeArm)
			end
		end

		CancelAttribute = Replication:GetAttributeChangedSignal("BackwardDash"):Connect(function()
			if not Replication:GetAttribute("BackwardDash") and RemoveFunc then
				RemoveFunc()
			end
		end) 
		-- 
		RemoveFunc = DashRocks(RootPart, "Backward Dash", 1.1, function()
			if (CancelAttribute ~= nil and CancelAttribute.Connected) then
				CancelAttribute:Disconnect()
			end

			for _, Arm in FakeArms do
				EffectUtility.Toggle(Arm, false)
				task.delay(1, Arm.Destroy, Arm)
			end
		end)

		if not Replication:GetAttribute("BackwardDash") and RemoveFunc then
			RemoveFunc()
		end
		
		EffectUtility.EmitEffects(script.SFX, RootPart)
	end
end

return VFX