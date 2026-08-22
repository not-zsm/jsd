local ReplicatedStorage = game:GetService("ReplicatedStorage")


local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local Yuki_InfinityBubble = require( ReplicatedStorage.Client.Replication.Global.Yuki_InfinityBubble )

local VFX = {}

function VFX.Hit(Torso : BasePart)
	if (Torso == nil) then return end

	EffectUtility.EmitEffects(script.Hit, Torso)
	Yuki_InfinityBubble(Torso, 0.25, Vector3.one * 10, 1)
end

return VFX
