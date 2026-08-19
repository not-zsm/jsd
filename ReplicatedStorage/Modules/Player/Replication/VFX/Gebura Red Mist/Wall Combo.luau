local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer;

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local VFX = {}

function VFX.VFX(RootPart : BasePart, Parameter : string)
	local Distance =  Player:DistanceFromCharacter(RootPart.Position)
	
	if Distance < 25 then
		if Parameter == "3" then -- stab
			Vignette(Color3.fromRGB(255, 80, 80), 0.5, 0.4)
		end
		
		CameraShake(2.75, 25, 0.01, 0.2, Vector3.one * 0.8, Vector3.one * 0.3)
	end

	if Distance < 70 then
		local Attachment : Attachment = EffectUtility.CloneAndEmit(script.Assets[Parameter], RootPart)

		local Direction = RootPart.CFrame.LookVector * 10
		local Raycast = workspace:Raycast(Attachment.WorldPosition, Direction, Utility.VisualParams)

		if (Raycast ~= nil) then
			if Parameter == "1" then
				coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
					Amount = 8,
					Distance = 3.5,

					LookAt = { -- Where the rocks face towards (y axis)
						Min = -3,
						Max = -3
					},

					Exposure = {
						Min = 0.4,
						Max = 0.6
					},

					SizeMultiplier = 0.95,
				})

				coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
					Amount = 12,
					Distance = 6,
					SizeMultiplier = 1.15,
				})

				coroutine.wrap(RockHandler.Rockst)(Raycast.Position, Direction, {
					Count = 7,
					Size = {0.3, 1},
					Velocity = 25,
				})

			elseif Parameter == "3" then
				coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
					Amount = 5,
					Distance = 3.5,

					LookAt = { -- Where the rocks face towards (y axis)
						Min = -4,
						Max = -4
					},

					Exposure = {
						Min = 0.4,
						Max = 0.6
					},

					SizeMultiplier = 0.875,
				})

				coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
					Amount = 8,
					Distance = 5,
					SizeMultiplier = 1,
				})

				coroutine.wrap(RockHandler.Rockst)(Raycast.Position, Direction, {
					Count = 5,
					Size = {0.15, 0.5},
					Velocity = 15,
				})

			elseif Parameter == "4" then
				coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
					Amount = 10,
					Distance = 5,

					LookAt = { -- Where the rocks face towards (y axis)
						Min = -3,
						Max = -3
					},

					Exposure = {
						Min = 0.4,
						Max = 0.6
					},

					SizeMultiplier = 0.975,
				})

				coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
					Amount = 14,
					Distance = 7,
					SizeMultiplier = 1.2,
				})

				coroutine.wrap(RockHandler.Rockst)(Raycast.Position, Direction, {
					Count = 8,
					Size = {0.4, 1},
					Velocity = 40,
				})
			end
		end

	end

end

return VFX