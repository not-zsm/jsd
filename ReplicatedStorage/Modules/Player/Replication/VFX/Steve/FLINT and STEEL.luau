local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

function VFX.Spark(Flint : BasePart)
	EffectUtility.CloneAndEmit(Flint.sparks, Flint) -- ok sigma
end
-- im flinting nad STEELIng it
return VFX
