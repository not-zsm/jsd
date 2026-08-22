local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local Distort = require( ReplicatedStorage.Client.Replication.Global.Distort )

local VFX = {}

function VFX.Yeowch(RootPart : BasePart)
	Distort{Rate = 6, StartPercentage = 5}
	EffectUtility.EmitEffects(script.SFX, RootPart)
end

return VFX

