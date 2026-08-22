local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )

local Bubble = require( ReplicatedStorage.Client.Replication.Global.Bubble )
local CameraShake = require( ReplicatedStorage.Client.Replication.Global.CameraShake )
local RockHandler = require( ReplicatedStorage.Client.Replication.Global.RockHandler )

local Direction = Vector3.yAxis * -10

local VFX = {}

function VFX.Push(RootPart : BasePart)
	if (RootPart == nil or RootPart.Parent == nil) then return end
	
	local Position = RootPart.Position
	local Distance = LocalPlayer:DistanceFromCharacter(Position)
	
	EffectUtility.EmitEffects(script.SFX, RootPart)
	
	if Distance < 35 then
		CameraShake(2.5, 25, 0.1, 0.35)
	end
	
	if Distance < 125 then
		Bubble(Position, 6, Vector3.zero, Vector3.one * 25, 0.25)

		coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			Amount = 5,
			Distance = 6,

			LookAt = { -- Where the rocks face towards (y axis)
				Min = -7,
				Max = -7
			},

			BaseZ = 1.5,
			SizeMultiplier = 0.85,
		})

		coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			Amount = 9,
			Distance = 10,
			
			LookAt = { -- Where the rocks face towards (y axis)
				Min = 9,
				Max = -9
			},
			
			SizeMultiplier = 1.45,
		})

		coroutine.wrap(RockHandler.Rockst)(Position, Direction, {
			Count = 16,
			Size = {0.3, 1.3},
			Velocity = 35,
		})
	end
end

return VFX

