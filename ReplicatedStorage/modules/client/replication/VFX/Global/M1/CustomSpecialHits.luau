local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Effects = ReplicatedStorage.modules.effect.assets
local CharacterEffects = Effects.Characters

local LocalPlayer = Players.LocalPlayer

local Blood = require( ReplicatedStorage.modules.client.replication.Global.Blood )
local CameraShake = require( ReplicatedStorage.modules.client.replication.Global.CameraShake )
local EffectUtility = require( ReplicatedStorage.modules.client.replication.EffectUtility )

return {
	["Chara"] = function(RootPart : BasePart, Type : string, Distance : number)
		if Type == "Up" then
			EffectUtility.EmitEffects(CharacterEffects.Chara.M1Sounds.Uppercut, RootPart)
			
			local Effect = CharacterEffects.Chara.Assets.slashed:Clone()
			Effect.CFrame = Effect.CFrame * CFrame.Angles(0, 0, math.rad(55))
			Effect.Parent = RootPart
			EffectUtility.Emit(Effect)
			
			if (Distance < 15) then
				CameraShake(1, 10, 0.075, 0.15, Vector3.one * 0.8)
			end
		end
	end,
}
