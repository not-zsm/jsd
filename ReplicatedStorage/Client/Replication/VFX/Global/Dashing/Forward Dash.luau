local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )

local AttributeListener = require( ReplicatedStorage.Client.Replication.Global.AttributeListener )

local DashRocks = require( ReplicatedStorage.Client.Replication.Global.DashRocks )
local CameraShake = require( ReplicatedStorage.Client.Replication.Global.CameraShake )
local Shockwave = require( ReplicatedStorage.Client.Replication.Global.Shockwave )

local Blood = require( ReplicatedStorage.Client.Replication.Global.Blood )

local RockHandler = require( ReplicatedStorage.Client.Replication.Global.RockHandler )

local VFX = {}

function VFX.Start(RootPart : BasePart)
	if (RootPart == nil or RootPart.Parent == nil) then return end

	local Replication = AttributeListener.GetReplicationFromSource(RootPart)
	
	if not Replication:GetAttribute("ForwardDash") then
		return
	end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	if (Distance <= 75) then
		Shockwave(RootPart.CFrame)
		EffectUtility.EmitEffects(script.Windup, RootPart)
	end
	
	local Model : Model = RootPart.Parent
	
	local CancelAttribute : RBXScriptConnection = nil
	local RemoveFunc = nil
	
	CancelAttribute = Replication:GetAttributeChangedSignal("ForwardDash"):Connect(function()
		if not Replication:GetAttribute("ForwardDash") then
			RemoveFunc()
		end
	end)
	
	RemoveFunc = DashRocks(RootPart, "Forward Dash", 0.8, function()
		if CancelAttribute.Connected then
			CancelAttribute:Disconnect()
		end

		EffectUtility.EmitEffects(script.Throw, RootPart)
		
		local Raycast = workspace:Raycast(RootPart.Position, Vector3.yAxis * -10, Utility.VisualParams)
		
		if (Raycast ~= nil) then
			local Items = EffectUtility.EmitEffects(script.WhooshDust, workspace.Terrain, RootPart.CFrame * CFrame.new(0, -Raycast.Distance, 0)) 
			
			for Item in Items do
				Item.Color = ColorSequence.new(Raycast.Instance.Color)
			end
		end
	end)
end

function VFX.DefaultStart(RootPart : BasePart, Arm : BasePart)
	local Replication = AttributeListener.GetReplicationFromSource(RootPart)

	if not Replication:GetAttribute("ForwardDash") then
		return
	end
	
	local FakeArm = EffectUtility.WeldArmTrail(Arm)
	local CancelAttribute : RBXScriptConnection = nil
	
	local function RemoveFunc()
		if CancelAttribute.Connected then
			CancelAttribute:Disconnect()
		end
		
		task.delay(1, FakeArm.Destroy, FakeArm)
		task.delay(0.3, EffectUtility.Toggle, FakeArm, false)
	end
	
	CancelAttribute = Replication:GetAttributeChangedSignal("ForwardDash"):Connect(function()
		if not Replication:GetAttribute("ForwardDash") then
			RemoveFunc()
		end
	end)
end

function VFX.Hit(AttackerRootPart : BasePart, VictimRootPart : BasePart)
	if (VictimRootPart == nil) then
		EffectUtility.EmitEffects(script.Hit, workspace.Terrain, AttackerRootPart.CFrame * CFrame.Angles(0, math.pi, 0))

		local Distance = Players.LocalPlayer:DistanceFromCharacter(AttackerRootPart.Position)

		if (Distance < 10) then
			CameraShake(2, 15, 0.1, 0.25, Vector3.one * 0.8)
		end

		if Distance < 75 then
			Shockwave(AttackerRootPart)
			Blood.BloodRays("SpitOut", AttackerRootPart.Parent.Head.MouthAttachment)
		end
	else
		EffectUtility.EmitEffects(script.Hit, workspace.Terrain, CFrame.lookAt(VictimRootPart.Position, AttackerRootPart.Position) * CFrame.Angles(0, math.pi, 0))

		local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimRootPart.Position)

		if (Distance < 10) then
			CameraShake(2, 15, 0.1, 0.25, Vector3.one * 0.8)
		end

		if Distance < 75 then
			Shockwave(VictimRootPart, AttackerRootPart)
			Blood.BloodRays("SpitOut", VictimRootPart.Parent.Head.MouthAttachment)
		end
	end
end

function VFX.WallSlam(RootPart : BasePart, Difference)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 75) then return end
	
	local Position = RootPart.Position
	local Direction = Difference * 20
	
	if (Distance < 15) then
		CameraShake(2, 15, 0.05, 0.3, Vector3.one * 0.8)
	end
	
	local Raycast = workspace:Raycast(RootPart.Position, Direction, Utility.VisualParams)
	
	if Raycast then
		EffectUtility.EmitEffects(script.WallSlam, workspace.Terrain, Raycast.Position)
		EffectUtility.CraterSmoke("Normal", Raycast)
	end
	
	coroutine.wrap(RockHandler.Crater)(Position, Direction, {
		Amount = 8,
		Distance = 6,

		LookAt = { -- Where the rocks face towards (y axis)
			Min = -3,
			Max = -3
		},

		Exposure = {
			Min = 0.4,
			Max = 0.6
		},

		SizeMultiplier = 0.95,
	})

	coroutine.wrap(RockHandler.Crater)(Position, Direction, {
		Amount = 10,
		Distance = 7.5,
		SizeMultiplier = 1.15,
	})

	coroutine.wrap(RockHandler.Rockst)(Position, Direction, {
		Count = 14,
		Size = {0.85, 1},
		Velocity = 35,
	})
end

return VFX
