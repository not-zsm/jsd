local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local VFX = {}

function VFX.Start(RootPart : BasePart)
	if (RootPart == nil or RootPart.Parent == nil) then return end
	
	local Blocker = (LocalPlayer.Character == RootPart.Parent)
	
	if Blocker then
		SoundService:PlayLocalSound(script.SFX.Sound)
	else
		if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 100 then
			EffectUtility.EmitEffects(script.SFX, RootPart)
		end
	end
end

function VFX.Parry(RootPart : BasePart, Character : string, Chance : number)
	if (RootPart == nil or RootPart.Parent == nil) then return end

	VFX.Hit(RootPart)
	EffectUtility.EmitEffects(script.Parried, RootPart)
	
	local Folder = script.CharacterParry:FindFirstChild(Character)

	if (Folder ~= nil) then
		if Character == "Gojo" then
			
			if (Chance == 1) then
				EffectUtility.EmitEffects(Folder.Rare, RootPart)
			else
				EffectUtility.EmitEffects(Folder.Normal, RootPart)
			end
		
		elseif Folder:FindFirstChild(Character) then
			EffectUtility.EmitEffects(Folder[Character], RootPart)
		else
			EffectUtility.EmitEffects(Folder, RootPart)
		end
	end
end

function VFX.Hit(RootPart : BasePart)
	if (RootPart == nil or RootPart.Parent == nil) then return end

	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 75) then return end
	
	if (Distance < 15) then
		CameraShake(1, 10, 0.01, 0.1, Vector3.one * 0.8)
	end
	
	EffectUtility.Arc.CloneAndEmit(script.Blocked, RootPart)
	EffectUtility.EmitEffects(script.Hits[tostring(math.random(1, 4))], RootPart)
end

return VFX

