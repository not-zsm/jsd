local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shockwave = require( ReplicatedStorage.Modules.Player.Replication.Global.Shockwave )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local VFX = {}

function VFX.Hit(Torso : BasePart, Index)
	if (Torso == nil or Torso.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(Torso.Position)

	if (Distance < 15) then
		CameraShake(1.75, 12.5, 0.1, 0.25, Vector3.one * 0.8)
	end
	
	if (Distance < 100) then
		EffectUtility.EmitEffects(script.Hit, Torso)
		
		if Index == 1 then
			Shockwave(Torso)
		end
	end
end

return VFX