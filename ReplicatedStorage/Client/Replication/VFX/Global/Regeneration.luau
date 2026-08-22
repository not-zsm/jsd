local ReplicatedStorage = game:GetService("ReplicatedStorage")


local ScreenPulse = require( ReplicatedStorage.Client.Replication.Global.ScreenPulse )

local VFX = {}

function VFX.OnRegenStep()
	ScreenPulse("Regeneration", true)
end

return VFX
