
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )
local Yuki_Skeleton = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_Skeleton )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Direction = Vector3.yAxis * -12.5

local VFX = {}

function VFX.Slam(VictimTorso : BasePart)
	if (VictimTorso == nil or VictimTorso.Parent == nil) then return end
	
	local Position = VictimTorso.Position + Vector3.yAxis * 1.5
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Position)

	if (Distance < 15) then
		CameraShake(2.5, 25, 0.1, 0.3, Vector3.one * 0.8)
	end

	if (Distance < 100) then
		Blood.BloodRaysWithoutPreset(VictimTorso, {
			Face = Enum.NormalId.Top, 
			SpreadAngle = Vector2.new(45, 45), 
			Amount = Vector2.new(3, 4), 
			PoolSize = 1.5	
		})

		coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			Amount = 7;
			Distance = 5;	

			ExposeLevel = -0.75;
			SizeMagnitude = 1.5,
		})

		coroutine.wrap(RockHandler.Rockst)(Position, Direction, {
			Size = {0.5, 1},
			Count = 4,
			Velocity = 20,
		})
		
		coroutine.wrap(function()
			for Index = 1, 37 do
				RockHandler.Rockst(VictimTorso.Position, Vector3.yAxis * -10, {
					Size = {0.3, 0.5},
					Count = 1,
					Velocity = 20
				})
				
				Smoke(VictimTorso)
				RockHandler.Rocks("Dragged", VictimTorso)
				
				task.wait(0.0175)
			end
		end)()
		
		EffectUtility.RaycastCraterSmoke("Normal", Position, Vector3.new(0, 1, 0))
		EffectUtility.EmitEffects(script.Slam, workspace.Terrain, Position)
		
		coroutine.wrap(function()
			for Index = 1, 16 do
				local Raycast = workspace:Raycast(VictimTorso.Position, -Vector3.yAxis * 5, shared.VisualParams)

				if (Raycast ~= nil) then
					Blood.BloodRaysWithoutPreset(VictimTorso, {
						Face = Enum.NormalId.Top, 
						SpreadAngle = Vector2.new(35, 35), 
						Amount = Vector2.new(3, 4), 
						PoolSize = 1.5
					})
				end

				task.wait(0.06)
			end
		end)()
	end
end

function VFX.FinalSlam(VictimTorso : BasePart)
	if (VictimTorso == nil or VictimTorso.Parent == nil) then return end

	local Position = VictimTorso.Position
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Position)

	if (Distance < 15) then
		CameraShake(4, 40, 0.1, 0.35, Vector3.one * 0.8)
	end

	if (Distance < 100) then
		Yuki_Skeleton(VictimTorso, 0.1, 0.4)
		
		Blood.BloodRaysWithoutPreset(VictimTorso.Parent.Head, {
			Face = Enum.NormalId.Top, 
			SpreadAngle = Vector2.new(65, 65), 
			Amount = Vector2.new(6, 8), 
			PoolSize = 3	
		})
		
		--coroutine.wrap(RockHandler.Crater)(Position, Direction, {
		--	Amount = 6;
		--	Distance = 5;	

		--	ExposeLevel = -0.7;
		--	SizeMagnitude = 1.35,
		--})

		--coroutine.wrap(RockHandler.Crater)(Position, Direction, {
		--	Amount = 9;
		--	Distance = 11;	

		--	ExposeLevel = -1.2;
		--	SizeMagnitude = 1.85,
		--})
		
		task.spawn(RockHandler.Crater, Position, Direction, { -- big middle rocks
			Amount = 10,
			Distance = {Min = 5 * 1.5, Max = 11 * 1.5},
			LookAt = { Min = 5, Max = 20 },
			Timing = {
				In = {Min = 0.075, Max = 0.2},
				Idle = {Min = 5.7, Max = 6.1},
				Out = {Min = 1.6, Max = 2.2},
			},
			Exposure = { Min = 0.85, Max = 1.5 },
			BaseZ = 2.5,
			SizeMultiplier = 1.75,
		})

		task.spawn(RockHandler.Crater, Position, Direction, { -- smaller outside rocks
			Amount = 25,
			Distance = {Min = 4.75 * 1.2, Max = 15 * 1.2},
			LookAt = { Min = -15, Max = 15 },
			Timing = {
				In = {Min = 0.05, Max = 0.35},
				Idle = {Min = 5.3, Max = 6.2},
				Out = {Min = 1.6, Max = 2.2},
			},
			Exposure = { Min = 1, Max = 1.2 },
			BaseZ = 1.2,
			SizeMultiplier = 1.4,
		})
		
		for Index = 1, 5 do
			local RandomPosition = Position + Vector3.new(Utility.Seed:NextNumber(-12, 12), 0, Utility.Seed:NextNumber(-12, 12))
			
			coroutine.wrap(RockHandler.Rockst)(RandomPosition, Vector3.yAxis * -10, {
				Size = {1.1, 1.6},
				Count = 2,
				Velocity = 30,
			})
		end

		EffectUtility.EmitEffects(script.FinalSlam, workspace.Terrain, CFrame.new(VictimTorso.Position) * CFrame.new(0, -1.5, 0) * CFrame.Angles(-(math.pi / 2), 0, 0))
		EffectUtility.RaycastCraterSmoke("Big", VictimTorso.Position, Vector3.new(0, 1, 0))
	end
end

function VFX.BodySlam(VictimTorso : BasePart)
	if (VictimTorso == nil or VictimTorso.Parent == nil) then return end

	local Position = VictimTorso.Position
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Position)

	if (Distance < 15) then
		CameraShake(10, 100, 0.1, 0.6, Vector3.one * 0.8)
	end

	if (Distance < 100) then
		Yuki_Skeleton(VictimTorso, 0.1, 0.4)

		Blood.BloodRaysWithoutPreset(VictimTorso.Parent.Head, {
			Face = Enum.NormalId.Top, 
			SpreadAngle = Vector2.new(65, 65), 
			Amount = Vector2.new(6, 8), 
			PoolSize = 3	
		})

		--coroutine.wrap(RockHandler.Crater)(Position, Direction, {
		--	Amount = 10;
		--	Distance = 9;	

		--	ExposeLevel = -0.7;
		--	SizeMagnitude = 1.35,
		--})

		--coroutine.wrap(RockHandler.Crater)(Position, Direction, {
		--	Amount = 15;
		--	Distance = 17;	

		--	ExposeLevel = -1.2;
		--	SizeMagnitude = 1.85,
		--})
		
		task.spawn(RockHandler.Crater, Position, Direction, { -- big middle rocks
			Amount = 10,
			Distance = {Min = 6 * 1.5, Max = 14 * 1.5},
			LookAt = { Min = 5, Max = 20 },
			Timing = {
				In = {Min = 0.075, Max = 0.2},
				Idle = {Min = 5.7, Max = 6.1},
				Out = {Min = 1.6, Max = 2.2},
			},
			Exposure = { Min = 1, Max = 2 },
			BaseZ = 2.5,
			SizeMultiplier = 2.2,
		})

		task.spawn(RockHandler.Crater, Position, Direction, { -- smaller outside rocks
			Amount = 45,
			Distance = {Min = 5 * 1.2, Max = 15 * 1.2},
			LookAt = { Min = -15, Max = 15 },
			Timing = {
				In = {Min = 0.05, Max = 0.35},
				Idle = {Min = 5.3, Max = 6.2},
				Out = {Min = 1.6, Max = 2.2},
			},
			Exposure = { Min = 0.75, Max = 1 },
			BaseZ = 1.2,
			SizeMultiplier = 1.5,
		})

		for Index = 1, 5 do
			local RandomPosition = Position + Vector3.new(Utility.Seed:NextNumber(-12, 12), 0, Utility.Seed:NextNumber(-12, 12))

			coroutine.wrap(RockHandler.Rockst)(RandomPosition, Direction, {
				Size = {1.5, 1.9},
				Count = 3,
				Velocity = 50,
			})
		end

		EffectUtility.EmitEffects(script.FinalSlam, workspace.Terrain, CFrame.new(VictimTorso.Position) * CFrame.new(0, -1.5, 0) * CFrame.Angles(-(math.pi / 2), 0, 0))
		EffectUtility.RaycastCraterSmoke("Big", VictimTorso.Position, Vector3.new(0, 1, 0))
	end
end

return VFX