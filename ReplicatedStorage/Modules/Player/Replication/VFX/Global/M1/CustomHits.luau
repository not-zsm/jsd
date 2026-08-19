local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Effects = ReplicatedStorage.Effects
local CharacterEffects = Effects.Characters

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local BugoVFX = require(ReplicatedStorage.Modules.Player.Replication.EffectUtility.Bugo)

local Sounds = script.Sounds

return {
	["Stardust Crusader"] = function(_, RootPart : BasePart, Count : number, Distance : number)
		if (Distance < 35) then
			CameraShake(1.75, 20, 0.075, 0.25, Vector3.one * 0.8)
		end

		local Rand = math.random(1, 2)

		if Count == 4 then
			Blood.BloodRaysWithoutPreset(RootPart, {
				Amount = Vector2.new(2, 4),
				Spread = Vector2.new(55, 55),
				Face = Enum.NormalId.Front,
			})
		end
	end,
	
	["Gebura Red Mist"] = function(_, RootPart : BasePart, Count, Distance : number)
		EffectUtility.EmitEffects(CharacterEffects.RedMist.M1Sounds[Count], RootPart)
		
		if (Distance < 35) then
			CameraShake(1, 10, 0.075, 0.3, Vector3.one * 0.8)
			EffectUtility.CloneAndEmit(CharacterEffects.RedMist.Assets.Hit, RootPart)
		end
		
		local Rand = math.random(1, 2)
		
		Blood.BloodRaysWithoutPreset(RootPart, {
			Amount = Vector2.new(4, 5),
			Spread = Vector2.new(55, 55),
			Face = Enum.NormalId[Rand == 1 and "Top" or "Front"],
		})
	end,
	
	["Edgerunner"] = function(AttackerRootPart : BasePart, VictimRootPart : BasePart, Count, Distance : number)
		if (Distance < 15) then
			CameraShake(1, 10, 0.01, 0.25, Vector3.one * 0.8)
		end

		if (Distance < 100) then
			if (Count == 2) then
				EffectUtility.EmitEffects(script.Edgerunner.Visuals["2"], VictimRootPart)
				
			elseif (Count == 3) then
				local ThirdHit = script.Edgerunner.Visuals["3"]:Clone()
				local CF = CFrame.lookAt(VictimRootPart.Position, AttackerRootPart.Position)
				ThirdHit["the direction of the kill"].CFrame = CF
				ThirdHit["the direction of the killest"].CFrame = CF
				ThirdHit.Parent = VictimRootPart
				EffectUtility.Emit(ThirdHit)
				
				EffectUtility.Arc.CloneAndEmit(script.Edgerunner.Visuals["3"], VictimRootPart)
				
			elseif (Count == 4) then
				if Blood.CanShowBlood() then
					EffectUtility.Arc.CloneAndEmit(script.Edgerunner.Visuals["4_blood"], VictimRootPart)
				end
				
				Blood.BloodRaysWithoutPreset(VictimRootPart, {
					Amount = Vector2.new(3, 5),
					PoolSize = 1.35,
					Spread = Vector2.new(55, 55),
					Face = Enum.NormalId.Front,
				})
				
				if LocalPlayer.Character == VictimRootPart.Parent then
					CameraShake(2, 20, 0.01, 0.25, Vector3.one * 0.8)
					Vignette(Color3.fromRGB(136, 0, 5), 0.5, 0.35)
				end
				
				EffectUtility.EmitEffects(script.Parent.Hit.Default, VictimRootPart)
				
				--if Blood.CanShowBlood() then
				--	EffectUtility.Arc.CloneAndEmit(script.Edgerunner.Visuals["4"], VictimRootPart)
				--else
				--	EffectUtility.EmitEffects(script.Parent.Hit.Default, VictimRootPart)
				--end
			else
				EffectUtility.EmitEffects(script.Parent.Hit.Default, VictimRootPart)
			end
			
			if (Count ~= 4) then
				EffectUtility.EmitEffects(script.Edgerunner.Sounds[Count], VictimRootPart)
			end
		end
	end,
	
	["Mori"] = function(_, RootPart : BasePart, Count, Distance : number)
		if (Distance < 15) then
			CameraShake(1, 10, 0.01, 0.25, Vector3.one * 0.8)
			Vignette(Color3.fromRGB(84, 144, 255), 0.9, 0.2, true)
		end
		
		if (Distance < 100) then
			EffectUtility.Arc.CloneAndEmit(CharacterEffects.Mori.Basic_Hit, RootPart)
			EffectUtility.EmitEffects(CharacterEffects.Mori.M1Sounds[Count], RootPart)
		end
	end,
	
	["Kratos"] = function(_, RootPart : BasePart, Count : number, Distance : number, Name : string, CurrentlyUsing : string)
		if (Distance < 35) then
			CameraShake(0.5, 5, 0.075, 0.25, Vector3.one * 0.8)
		end

		if CurrentlyUsing == "Fists" then
			EffectUtility.EmitEffects(script.Sounds.Kratos.Fists[Count], RootPart)
		else
			if LocalPlayer:GetAttribute("Blood") then
				EffectUtility.EmitEffects(Effects.Blood.SlashNoSFX, RootPart)
			end
			
			EffectUtility.EmitEffects(script.Sounds[Name][CurrentlyUsing][Count], RootPart)
			
			Blood.BloodRaysWithoutPreset(RootPart, {
				Amount = Vector2.new(3, 5),
				Spread = Vector2.new(45, 45),
				Face = Enum.NormalId.Front,
				PoolSize = 0.85,
			})
		end
	end,
	
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
	
	["Anubis"] = function(_, RootPart : BasePart, Count : number, Distance : number)
		if (Distance < 50) then
			BugoVFX(script.Anubis.Visuals[Count], RootPart)
		end
		
		if (Distance < 100) then
			EffectUtility.EmitEffects(script.Anubis.Sounds.M1Sounds[Count], RootPart)
		end
	end,

}
