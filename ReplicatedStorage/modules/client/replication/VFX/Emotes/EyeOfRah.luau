local replicatedStorage = game:GetService("ReplicatedStorage")

local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )

local VFX = {}

function VFX.Rah(Color : Color3)
	CameraShake(1, 10, 0.05, 0.3, Vector3.one * 0.8)
	Vignette(Color or Color3.fromRGB(255, 106, 0), 0.5, 0.3)
end

return VFX
