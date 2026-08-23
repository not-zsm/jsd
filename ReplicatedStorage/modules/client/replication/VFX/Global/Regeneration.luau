local replicatedStorage = game:GetService("ReplicatedStorage")


local ScreenPulse = require( replicatedStorage.modules.client.replication.Global.ScreenPulse )

local VFX = {}

function VFX.OnRegenStep()
	ScreenPulse("Regeneration", true)
end

return VFX
