local VFX = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CharaAssets = replicatedStorage.modules.effect.assets.Characters.chara

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )

local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )

local AttributeListener = require( replicatedStorage.modules.client.replication.Global.AttributeListener )

local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )
local Smoke = require( replicatedStorage.modules.client.replication.Global.Smoke )
	
function VFX.Start(RootPart : BasePart)
	local Knife : Model = RootPart.Parent:FindFirstChild("Knife")
	
	if (Knife ~= nil) then
		Knife.Handle.BladeAttachment.Trail.Enabled = true

		AttributeListener.new(RootPart, "OnslaughtAerial", function()
			if (Knife ~= nil and Knife.Parent ~= nil) then
				Knife.Handle.BladeAttachment.Trail.Enabled = false
			end
		end)
	end
	
	EffectUtility.AddSFX(script.WindupSFX, RootPart, 0.25)
end

function VFX.Spin(Model : Model)
	local Trails ={}
	
	for _, Item in ipairs(Model:GetChildren()) do
		if Item:IsA("BasePart") and string.find(Item.Name, "Left") or string.find(Item.Name, "Right") then
			local Arm = EffectUtility.WeldArmTrail(Item)
			
			if (Arm ~= nil) then
				Trails[Arm] = true
			end
		end
	end
	
	task.delay(0.4, function()
		for Trail in Trails do
			Trail:Destroy()
		end
	end)
end

function VFX.Hit(Model : Model)
	EffectUtility.AddSFX(script.HitSFX, Model.PrimaryPart, 0.25)
end

function VFX.Drop(RootPart : BasePart, VictimRootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.drop, VictimRootPart)

	if LocalPlayer:DistanceFromCharacter(VictimRootPart.Position) < 20 then
		CameraShake(1, 10, 0.01, 0.2, Vector3.one * 0.8, Vector3.one * 0.5)
	end
end

function VFX.Stab(RootPart : BasePart, VictimRootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.stab, VictimRootPart)
	
	if LocalPlayer:DistanceFromCharacter(VictimRootPart.Position) < 20 then
		CameraShake(1.75, 25, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.15)
		Vignette(Color3.fromRGB(255, 0, 0), 0.5, 0.25)
	end

	Blood.BloodRaysWithoutPreset(VictimRootPart, {
		Amount = Vector2.new(4, 6),
		Face = Enum.NormalId.Top,
		PoolSize = 1.5
	})
end

return VFX