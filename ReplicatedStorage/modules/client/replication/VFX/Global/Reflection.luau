local replicatedStorage = game:GetService("ReplicatedStorage")


local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Yuki_InfinityBubble = require( replicatedStorage.modules.client.replication.Global.Yuki_InfinityBubble )

local VFX = {}

function VFX.Hit(Torso : BasePart)
	if (Torso == nil) then return end

	EffectUtility.EmitEffects(script.Hit, Torso)
	Yuki_InfinityBubble(Torso, 0.25, Vector3.one * 10, 1)
end

return VFX
