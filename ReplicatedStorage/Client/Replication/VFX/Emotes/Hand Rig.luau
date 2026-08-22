local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraShake = require( ReplicatedStorage.Client.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Client.Replication.Global.Vignette )

local Info = TweenInfo.new(0.5)

local VFX = {}

function VFX.Remove(Hands : Table)
	for _, Hand in Hands do
		for _, Part in Hand:GetChildren() do
			if Part:IsA("MeshPart") then
				TweenService:Create(Part, Info, {Transparency = 1}):Play()
			end
		end
	end
end

return VFX
