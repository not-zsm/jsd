local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.modules.client.replication.EffectUtility )

local Bubble = require( ReplicatedStorage.modules.client.replication.Global.Bubble )
local CameraShake = require( ReplicatedStorage.modules.client.replication.Global.CameraShake )
local RockHandler = require( ReplicatedStorage.modules.client.replication.Global.RockHandler )

local Direction = Vector3.yAxis * -10

local VFX = {}

function VFX.At(Origin : CFrame, Part : BasePart)
	local Clone = Part:Clone()
	Clone.CFrame = Origin
	Clone.Parent = workspace.Terrain
	
	EffectUtility.Emit(Clone)
end

return VFX

