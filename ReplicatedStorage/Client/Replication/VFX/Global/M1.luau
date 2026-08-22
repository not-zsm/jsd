local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )

local CameraShake = require( ReplicatedStorage.Client.Replication.Global.CameraShake )
local RockHandler = require( ReplicatedStorage.Client.Replication.Global.RockHandler )
local ScreenPulse = require( ReplicatedStorage.Client.Replication.Global.ScreenPulse )

local Shockwave = require( ReplicatedStorage.Client.Replication.Global.Shockwave )

local RaycastHitbox = require( ReplicatedStorage.Shared.Utilities.RaycastHitbox )

local Blood = require( ReplicatedStorage.Client.Replication.Global.Blood )
local LightInfo = TweenInfo.new(1)

local CustomHits = require( script.CustomHits )
local CustomSwings = require( script.CustomSwings )
local CustomSpecialSwings = require( script.CustomSpecialSwings )
local CustomSpecialHits = require( script.CustomSpecialHits )

local VFX = {}

function VFX.Hit(AttackerRootPart : BasePart, VictimRootPart : BasePart, Count : number, Character : string, CurrentlyUsing : string)
	if (VictimRootPart == nil or VictimRootPart.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimRootPart.Position)
	if (Distance > 75) then return end

	if Character then
		local CustomHitEffects = script.Hit:FindFirstChild(Character)

		if CustomHitEffects then
			EffectUtility.EmitEffects(CustomHitEffects, VictimRootPart)
		else
			EffectUtility.EmitEffects(script.Hit.Default, VictimRootPart)
			EffectUtility.EmitEffects(script.HitSounds[Count], VictimRootPart)
		end

		if CustomHits[Character] then
			if CurrentlyUsing then
				task.spawn(CustomHits[Character], AttackerRootPart, VictimRootPart, Count, Distance, Character, CurrentlyUsing)
			else
				task.spawn(CustomHits[Character], AttackerRootPart, VictimRootPart, Count, Distance)
			end
		else
			if (Distance < 20) then
				CameraShake(0.8, 8, 0.075, 0.2, Vector3.one * 0.8)
			end
		end
	else
		if (Distance < 20) then
			CameraShake(0.8, 8, 0.075, 0.2, Vector3.one * 0.8)
		end

		EffectUtility.EmitEffects(script.Hit.Default, VictimRootPart)
		EffectUtility.EmitEffects(script.HitSounds[Count], VictimRootPart)
	end
end

function VFX.Uppercut(RootPart : BasePart, Character : string)
	if (RootPart == nil or RootPart.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 75) then return end

	Shockwave(CFrame.new(RootPart.Position) * CFrame.Angles(-(math.pi / 2), 0, 0))
	
	if Character ~= "Edgerunner" then
		EffectUtility.EmitEffects(script.UppercutHit, RootPart)
	end
	
	if CustomSpecialHits[Character] then
		task.spawn(CustomSpecialHits[Character], RootPart, "Up", Distance)
	else
		CameraShake(0.8, 8, 0.075, 0.2, Vector3.one * 0.8)
		EffectUtility.EmitEffects(script.Hit.Default, RootPart)
	end
end

function VFX.SpecialSwing(RootPart : BasePart, Type : string, Character : string)
	if (RootPart == nil or RootPart.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 75) then return end

	if Type == "Down" then
		local Trail = EffectUtility.WeldArmTrail(RootPart.Parent["Right Leg"])

		task.delay(0.4, function()
			EffectUtility.Toggle(Trail, false)
			task.delay(1, Trail.Destroy, Trail)
		end)
	end

	if CustomSpecialSwings[Character] then
		task.spawn(CustomSpecialSwings[Character], RootPart, Type, Distance)
	else
		EffectUtility.EmitEffects(script.SpecialSwings[Type], RootPart)
	end
end

function VFX.Swing(RootPart : BasePart, Count : number, Character : string, Arm : BasePart, CurrentlyUsing : string)
	if (RootPart == nil or RootPart.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 75) then return end

	if CustomSwings[Character] then
		task.spawn(CustomSwings[Character], RootPart, Count, Distance, CurrentlyUsing)
	else
		if Arm and Distance <= 50 then
			local Hitbox = RaycastHitbox.new(Arm)

			Hitbox.OnHit:Connect(function(Raycast)
				local SecondDistance = Players.LocalPlayer:DistanceFromCharacter(Raycast.Position)

				if SecondDistance <= 50 then
					local Effects = EffectUtility.EmitEffects(script.WallHit, workspace.Terrain, Raycast.Position)

					for Effect in Effects do
						if Effect:IsA("ParticleEmitter") then
							Effect.Color = ColorSequence.new(Raycast.Instance.Color)
						end
					end
				end

				if SecondDistance <= 10 then
					CameraShake(0.75, 9.5, 0.05, 0.275, Vector3.one * 0.8, Vector3.one * 0.15)
				end
			end)

			Hitbox:Start(0.25, true)
		end

		EffectUtility.EmitEffects(script.Swings[Count], RootPart)
	end
end

VFX["Down Slam"] = function(RootPart : BasePart, Character : string)
	if (RootPart == nil or RootPart.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 75) then return end

	if (Distance < 20) then
		CameraShake(3.5, 40, 0.075, 0.35, Vector3.one * 0.8)
	end

	Shockwave(CFrame.new(RootPart.Position) * CFrame.Angles(-(math.pi / 2), 0, 0))
	
	if Character ~= "Edgerunner" then
		EffectUtility.EmitEffects(script.DownSlamHit, RootPart)
	end

	if CustomSpecialHits[Character] then
		task.spawn(CustomSpecialHits[Character], RootPart, "Down", Distance)
	end

	local Detected = false

	local function Fire()
		local Direction = Vector3.yAxis * -5
		local Raycast = workspace:Raycast(RootPart.Position + (Vector3.yAxis * 1.5), Direction, Utility.VisualParams)

		if Raycast then
			Detected = true

			EffectUtility.EmitEffects(script.DownSlamLand, workspace.Terrain, Raycast.Position)
			EffectUtility.CraterSmoke("Normal", Raycast)

			coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
				Amount = 5,
				Distance = 2,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = -3,
					Max = -3
				},

				Exposure = {
					Min = 0.4,
					Max = 0.6
				},

				BaseZ = 1.5,

				SizeMultiplier = 0.75,
			})

			coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
				Amount = 9,
				Distance = 6,

				SizeMultiplier = 1.35,
			})

			coroutine.wrap(RockHandler.Rockst)(Raycast.Position, Direction, {
				Count = 17,
				Size = {0.35, 0.9},
				Velocity = 40,
			})
		end
	end

	Fire()

	local Thread = coroutine.create(function()
		while (RootPart.Parent ~= nil and not Detected) do
			Fire()
			RunService.PreSimulation:Wait()
		end
	end)

	coroutine.resume(Thread)

	task.delay(5, function()
		if coroutine.status(Thread) == "suspended" then
			coroutine.close(Thread)
		end
	end)
end

VFX["Black Flash"] = function(RootPart : BasePart, Condition : string?)
	if (RootPart == nil or RootPart.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 75) then return end

	if (Distance < 20) then
		ScreenPulse("Black Flash")
		CameraShake(5, 50, 0.1, 0.35, Vector3.one * 0.8)
	end

	Blood.BloodRays("BigSpitOut", RootPart.Parent.Head.MouthAttachment)

	if (Condition == "Up") then
		EffectUtility.EmitEffects(script["Black Flash Uppercut"], RootPart)

	elseif (Condition == "Down") then
		local Raycast = workspace:Raycast(RootPart.Position, -Vector3.yAxis * 10, Utility.VisualParams)

		if Raycast then
			EffectUtility.EmitEffects(script["Black Flash Down Slam"], workspace.Terrain, Raycast.Position)
		end

	elseif (Condition == nil) then
		EffectUtility.EmitEffects(script["Black Flash"], RootPart)
	end

	local Attachment = Instance.new("Attachment")
	Attachment.Parent = workspace.Terrain
	Attachment.WorldPosition = RootPart.Position

	local Light = script.BlackFlashPointlight:Clone()
	Light.Parent = Attachment

	TweenService:Create(Light, LightInfo, 
		{Brightness = 0}
	):Play()

	task.delay(LightInfo.Time, Attachment.Destroy, Attachment)
end

return VFX
