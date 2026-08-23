local replicatedStorage = game:GetService("ReplicatedStorage")
local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Distort = require( replicatedStorage.modules.client.replication.Global.Distort )

local VFX = {}

function VFX.Yeowch(RootPart : BasePart)
	Distort{Rate = 6, StartPercentage = 5}
	EffectUtility.EmitEffects(script.SFX, RootPart)
end

return VFX

