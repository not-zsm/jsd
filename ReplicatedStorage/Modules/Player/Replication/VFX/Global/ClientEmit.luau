local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local Bubble = require( ReplicatedStorage.Modules.Player.Replication.Global.Bubble )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local Direction = Vector3.yAxis * -10

local VFX = {}

function VFX.At(Origin : CFrame, Part : BasePart)
	local Clone = Part:Clone()
	Clone.CFrame = Origin
	Clone.Parent = workspace.Terrain
	
	EffectUtility.Emit(Clone)
end

return VFX

