local ReplicatedStorage = game:GetService("ReplicatedStorage")


local ScreenPulse = require( ReplicatedStorage.modules.client.replication.Global.ScreenPulse )

local VFX = {}

function VFX.OnRegenStep()
	ScreenPulse("Regeneration", true)
end

return VFX
