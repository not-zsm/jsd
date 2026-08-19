
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Afterimage = require( ReplicatedStorage.Modules.Player.Replication.Global.Afterimage )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local Yuki_Skeleton = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_Skeleton )

local VFX = {}

function VFX.WaterStream(Limb : BasePart, Duration : number)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Limb.Position)
	if (Distance > 75) then return end
	
	local Stream = script.Trail.WaterStream:Clone()
	Stream.Parent = Limb
	
	EffectUtility.Toggle(Stream, true)
	
	task.delay(Duration, function()
		EffectUtility.Toggle(Stream, false)
		task.delay(2, Stream.Destroy, Stream)
	end)
end

function VFX.DualHandWaterStream(Model : Model, Duration : number)
	for _, Arm in {Model["Left Arm"], Model["Right Arm"]} do
		VFX.WaterStream(Arm, Duration)
	end
end

function VFX.Swing(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 100) then return end
	
	coroutine.wrap(function()
		for Index = 1, 10 do
			RockHandler.Rockst(RootPart.Position, Vector3.yAxis * -10, {
				Size = {0.2, 0.4},
				Count = 1,
				Velocity = 20
			})
			
			RockHandler.Rocks("Dragged", RootPart)
			Smoke(RootPart)
			
			task.wait(0.02)
		end
	end)()
end

function VFX.Hit(Attacker : Model, VictimRootPart : BasePart)
	if (VictimRootPart == nil or VictimRootPart.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimRootPart.Position)

	if (Distance < 15) then
		CameraShake(1.75, 12.5, 0.1, 0.25, Vector3.one * 0.8)
	end

	if (Distance < 100) then
		EffectUtility.EmitEffects(script.Hit, VictimRootPart)
		
		Blood.BloodRaysWithoutPreset(VictimRootPart.Parent.Head.MouthAttachment, {
			Face = Enum.NormalId.Front, 
			SpreadAngle = Vector2.new(45, 45), 
			Amount = Vector2.new(2, 3), 
			PoolSize = 1.5	
		})
		
		Afterimage(Attacker, {0.75}, {0.3}, 2)
	end
end

function VFX.FinalHit(VictimRootPart : BasePart)
	if (VictimRootPart == nil or VictimRootPart.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimRootPart.Position)

	if (Distance < 15) then
		CameraShake(2.5, 20, 0.1, 0.25, Vector3.one * 0.8)
	end

	if (Distance < 100) then
		Yuki_Skeleton(VictimRootPart.Parent.Torso, 0.1, 0.4)
		EffectUtility.EmitEffects(script.FinalHit, VictimRootPart)
		
		coroutine.wrap(function()
			for Index = 1, 8 do
				Blood.BloodRaysWithoutPreset(VictimRootPart.Parent.Head.MouthAttachment, {
					Face = Enum.NormalId.Front, 
					SpreadAngle = Vector2.new(45, 45), 
					Amount = Vector2.new(2, 4), 
					PoolSize = 1.2
				})

				task.wait(0.13)
			end
		end)()
	end
end

return VFX