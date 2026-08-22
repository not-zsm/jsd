local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )

local VFX = {}

function VFX.Spin(Leg : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Leg.Position)

	if (Distance < 75) then
		local Trail = EffectUtility.WeldArmTrail(Leg)
		task.delay(0.6, Trail.Destroy, Trail)
	end
end

return VFX