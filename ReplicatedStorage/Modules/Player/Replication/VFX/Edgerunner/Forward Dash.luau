local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local VFX = {};

function VFX.Start(RootPart : BasePart)
	local Replication = AttributeListener.GetReplicationFromSource(RootPart)
	
	if not Replication:GetAttribute("ForwardDash") then
		return
	end
	
	local Model = RootPart.Parent
	local LeftArm = Model:FindFirstChild("Left Arm")
	local FakeArm = LeftArm and EffectUtility.WeldArmTrail(LeftArm)
	
	local CancelAttribute : RBXScriptConnection = nil

	local function RemoveFunc()
		if CancelAttribute.Connected then
			CancelAttribute:Disconnect()
		end
		
		if FakeArm then
			task.delay(1, FakeArm.Destroy, FakeArm)
			task.delay(0.3, EffectUtility.Toggle, FakeArm, false)
		end
	end

	CancelAttribute = Replication:GetAttributeChangedSignal("ForwardDash"):Connect(function()
		if not Replication:GetAttribute("ForwardDash") then
			RemoveFunc()
		end
	end)
end

return VFX