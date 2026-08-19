local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local VFX = {}

function VFX.CreateModel(RootPart : BasePart)
	local Model = script.Model:Clone()
	Model.Parent = workspace.Visuals
end

return VFX
