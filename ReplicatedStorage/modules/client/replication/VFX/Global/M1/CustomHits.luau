local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Effects = replicatedStorage.modules.effect.assets
local CharacterEffects = Effects.Characters

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )

local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )

local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )

local BugoVFX = require(replicatedStorage.modules.client.replication.EffectUtility.Bugo)

local Sounds = script.Sounds

return {
	["Chara"] = function(_, RootPart : BasePart, Count : number, Distance : number)
		if Count == 2 or Count == 4 then
			EffectUtility.EmitEffects(CharacterEffects.Chara.M1Sounds[Count], RootPart)
		end
		
		if Count == 2 then
			local Effect = CharacterEffects.Chara.Assets.slashed:Clone()
			Effect.Parent = RootPart.Parent.Head
			EffectUtility.Emit(Effect)
			
			if (Distance < 35) then
				CameraShake(0.5, 5, 0.075, 0.25, Vector3.one * 0.8)
			end
			
		elseif Count ~= 4 then
			EffectUtility.EmitEffects(CharacterEffects.Chara.Hit, RootPart.Parent.Torso)
			EffectUtility.EmitEffects(script.Parent.HitSounds[Count], RootPart)
		end
	end,
}
