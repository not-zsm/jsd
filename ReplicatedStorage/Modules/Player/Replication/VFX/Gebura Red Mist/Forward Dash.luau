local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local RedMistEffects = ReplicatedStorage.Effects.Characters.RedMist

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local VFX = {};

function VFX.Hit(AttackerRootPart : BasePart, VictimRootPart : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(VictimRootPart.Position)

	if (Distance < 25) then
		CameraShake(3, 20, 0.1, 0.25, Vector3.one * 0.8)
		Vignette(Color3.fromRGB(255, 0, 0), 0.5, 0.25)
	end

	if Distance < 100 then
		EffectUtility.CloneAndEmit(RedMistEffects.Assets.Hit, VictimRootPart)

		local Rand = math.random(1, 2)

		Blood.BloodRaysWithoutPreset(VictimRootPart, {
			Amount = Vector2.new(4, 5),
			Spread = Vector2.new(55, 55),
			Face = Enum.NormalId[Rand == 1 and "Top" or "Front"],
		})
	end
end

function VFX.Start(RootPart : BasePart, Arm : BasePart)
	local Sword : Model = RootPart.Parent:FindFirstChild("Mimicry")
	if (Sword == nil) then return end

	local Replication = AttributeListener.GetReplicationFromSource(RootPart)
	local CancelAttribute : RBXScriptConnection = nil

	local function RemoveFunc()
		if CancelAttribute.Connected then
			CancelAttribute:Disconnect()
		end

		EffectUtility.CloneAndEmit(RedMistEffects.Swings["4"], RootPart)

		local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)

		if (Distance < 25) then
			CameraShake(1.5, 10, 0.1, 0.15, Vector3.one * 0.8)
			Vignette(Color3.fromRGB(255, 0, 0), 0.5, 0.25)
		end
	
		task.delay(0.4, function()
			Sword.Blade.Attachment1.Trail.Enabled = false
		end)
	end

	Sword.Blade.Attachment1.Trail.Enabled = true

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