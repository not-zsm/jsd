local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local VFX = {}

function VFX.Stomp(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if (Distance < 10) then
		CameraShake(1.5, 15, 0.1, 0.1, Vector3.one * 0.8)
	end
	
	if (Distance < 75) then
		EffectUtility.RaycastCraterSmoke("Small", (RootPart.CFrame * CFrame.new(0.5, 0, -3)).Position, Vector3.new(0, 1, 0))
		
		for Index = 1, 6 do
			local CF = RootPart.CFrame * CFrame.new(0.5, 0, -1.5 - (Index / 1.75))

			RockHandler.Rockst(CF.Position, Vector3.yAxis * -10, {
				Size = {0.5, 0.7},
				Count = 1,
				Velocity = 20
			})

			RockHandler.Rocks("Dragged", CF)
		end
	end
end

return VFX