local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local CharaEffects = ReplicatedStorage.Effects.Characters.Chara

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )

local AttributeListener = require( ReplicatedStorage.Client.Replication.Global.AttributeListener )

local CameraShake = require( ReplicatedStorage.Client.Replication.Global.CameraShake )
local Blood = require( ReplicatedStorage.Client.Replication.Global.Blood )

local VFX = {};

function VFX.Hit(AttackerRootPart : BasePart, VictimRootPart : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(VictimRootPart.Position)

	if (Distance < 10) then
		CameraShake(3, 20, 0.1, 0.25, Vector3.one * 0.8)
	end
	
	if Distance < 100 then
		EffectUtility.EmitEffects(CharaEffects.FrontDashHit, VictimRootPart)

		local Effect = CharaEffects.Assets.slashed:Clone()
		Effect.CFrame = CFrame.new(0.35, 0, -0.3) * CFrame.Angles(0, 0, math.rad(-90))
		Effect.Parent = VictimRootPart
		EffectUtility.Emit(Effect)
	end
end

function VFX.Start(RootPart : BasePart, Arm : BasePart)
	local Knife : Model = RootPart.Parent:FindFirstChild("Knife")
	if (Knife == nil) then return end

	local Replication = AttributeListener.GetReplicationFromSource(RootPart)

	local CancelAttribute : RBXScriptConnection = nil

	local function RemoveFunc()
		if CancelAttribute.Connected then
			CancelAttribute:Disconnect()
		end
		
		EffectUtility.EmitEffects(CharaEffects.Swing, RootPart)

		task.delay(0.3, function()
			Knife.Handle.BladeAttachment.Trail.Enabled = false
		end)
	end
	
	Knife.Handle.BladeAttachment.Trail.Enabled = true

	CancelAttribute = Replication:GetAttributeChangedSignal("ForwardDash"):Connect(function()
		if not Replication:GetAttribute("ForwardDash") then
			RemoveFunc()
		end
	end)
	
	if not Replication:GetAttribute("ForwardDash") then
		RemoveFunc()
	end
end

return VFX