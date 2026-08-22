local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraShake = require( ReplicatedStorage.Client.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Client.Replication.Global.Vignette )

local VFX = {}

function VFX.Rah(Color : Color3)
	CameraShake(1, 10, 0.05, 0.3, Vector3.one * 0.8)
	Vignette(Color or Color3.fromRGB(255, 106, 0), 0.5, 0.3)
end

return VFX
