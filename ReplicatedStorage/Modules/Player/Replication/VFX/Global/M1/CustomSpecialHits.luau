local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Effects = ReplicatedStorage.Effects
local CharacterEffects = Effects.Characters

local LocalPlayer = Players.LocalPlayer

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

return {
	["Stardust Crusader"] = function(RootPart : BasePart, Type : string, Distance : number)
		EffectUtility.AddSFX(script.Parent.Hit["Stardust Crusader"].Hit, RootPart)
		CameraShake(1.75, 20, 0.075, 0.25, Vector3.one * 0.8)
	end,
	
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
	
	["Edgerunner"] = function(RootPart : BasePart, Type : string, Distance : number)
		if (Distance < 15) then
			CameraShake(1, 10, 0.01, 0.25, Vector3.one * 0.8)
		end
		
		EffectUtility.EmitEffects(script.Parent.Hit.Default, RootPart)
		EffectUtility.EmitEffects(script.Edgerunner.Sounds[Type], RootPart)
	end,
	
	["Mori"] = function(RootPart : BasePart, Type : string, Distance : number)
		if Type == "Up" then
			EffectUtility.EmitEffects(CharacterEffects.Mori.M1Sounds.Uppercut, RootPart)
		end
	end,
	
	["Gebura Red Mist"] = function(RootPart : BasePart, Type : string)
		local Effect = script.RedMist:FindFirstChild(Type)
		
		if not Effect then
			return
		end
		
		EffectUtility.EmitEffects(Effect, RootPart)
	end
}
