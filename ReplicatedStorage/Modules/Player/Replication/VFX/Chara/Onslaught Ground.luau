local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CharaAssets = ReplicatedStorage.Effects.Characters.Chara

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

local Spins = {}

function VFX.Spin(RootPart : BasePart, Value : string)
	if Value == "true" then
		EffectUtility.CloneAndEmit(script.Assets.hit, RootPart)
		
		if (Spins[RootPart] == nil) then
			local Trails ={}

			local Effect = script.Assets.spin:Clone()
			Effect.Parent = RootPart

			EffectUtility.Emit(Effect, true)
			EffectUtility.Toggle(Effect, true)

			for _, Item in ipairs(RootPart.Parent:GetChildren()) do
				if Item:IsA("BasePart") and string.find(Item.Name, "Left") or string.find(Item.Name, "Right") then
					Trails[ EffectUtility.WeldArmTrail(Item) ] = true
				end
			end

			Spins[RootPart] = {Effect = Effect, Trails = Trails}
		end
	else
		if (Spins[RootPart] ~= nil) then
			EffectUtility.Toggle(Spins[RootPart].Effect, false)
			task.delay(1, Spins[RootPart].Effect.Destroy, Spins[RootPart].Effect)
			
			for Trail in Spins[RootPart].Trails do
				Trail:Destroy()
			end
			
			Spins[RootPart] = nil
		end
	end
end

function VFX.End(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.endhit, RootPart)
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 20 then
		CameraShake(1.75, 25, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.15)
		Vignette(Color3.fromRGB(255, 0, 0), 0.5, 0.25)
	end
end

return VFX