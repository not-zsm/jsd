local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Players = game:GetService("Players")

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local AttributeListener = require( ReplicatedStorage.Client.Replication.Global.AttributeListener )

local DashRocks = require( ReplicatedStorage.Client.Replication.Global.DashRocks )
local Shockwave = require( ReplicatedStorage.Client.Replication.Global.Shockwave )

local VFX = {}

function VFX.Up(RootPart : BasePart, Type : string)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 75) then return end
	
	Shockwave(RootPart)
	EffectUtility.EmitEffects(script.Up, RootPart)
end

function VFX.Land(RootPart : BasePart, Type : string, Time : number)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 75) then return end

	local Replication = AttributeListener.GetReplicationFromSource(RootPart)
	
	local CancelAttribute : RBXScriptConnection = nil
	local RemoveFunc = nil

	local FakeArms = {}
	
	for _, Item in ipairs(RootPart.Parent:GetChildren()) do
		if Item:IsA("BasePart") and string.find(Item.Name, "Arm") then
			local FakeArm = EffectUtility.WeldArmTrail(Item)
			table.insert(FakeArms, FakeArm)
		end
	end
	
	CancelAttribute = Replication:GetAttributeChangedSignal("Landed"):Connect(function()
		if not Replication:GetAttribute("Landed") then
			RemoveFunc()
		end
	end)

	RemoveFunc = DashRocks(RootPart, "Backward Dash", Time or 1, function()
		if CancelAttribute.Connected then
			CancelAttribute:Disconnect()
		end
		
		for _, Arm in FakeArms do
			EffectUtility.Toggle(Arm, false)
			task.delay(1, Arm.Destroy, Arm)
		end
	end)
	
	if not Replication:GetAttribute("Landed") then
		RemoveFunc()
	end
	
	EffectUtility.EmitEffects(script.Land, RootPart)
end


return VFX
