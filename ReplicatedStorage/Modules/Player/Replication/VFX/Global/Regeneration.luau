local ReplicatedStorage = game:GetService("ReplicatedStorage")


local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )

local VFX = {}

function VFX.OnRegenStep()
	ScreenPulse("Regeneration", true)
end

return VFX
