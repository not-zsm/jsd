local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local Bubble = require( ReplicatedStorage.Modules.Player.Replication.Global.Bubble )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Afterimage = require( ReplicatedStorage.Modules.Player.Replication.Global.Afterimage )
local Distort = require( ReplicatedStorage.Modules.Player.Replication.Global.Distort )

local VFX = {}

local Assets = script.Assets

function VFX.Aura(Model : Model)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Model.PrimaryPart.Position)

	if (Distance < 25) then
		CameraShake(1.25, 12.5, 0.1, 0.4, Vector3.one * 0.8)
		Yuki_FOV.Tween(60, {0.35})
		
		task.delay(0.35, function()
			Yuki_FOV.Tween(70, {0.5})
		end)
	end
	
	if (Distance < 75) then
		Distort{Character = Model, Rate = 3}
		Bubble(Model.PrimaryPart.Position, 6, Vector3.zero, Vector3.one * 12.5, 0.4)
		
		local Items = {}
		
		local function Aura(Model : Model)
			for _, BasePart in {Model["Right Arm"], Model["Left Arm"]} do
				for _, Item in ipairs(Assets.ArmAura:GetChildren()) do
					local NewItem = Item:Clone()
					NewItem.Enabled = true
					NewItem.Parent = BasePart
					Items[NewItem] = true
				end

				EffectUtility.EmitEffectsOnBasePart(script.AuraBurst1, BasePart)
				EffectUtility.EmitEffects(script.AuraBurst2, BasePart)
			end
		end
		
		Aura(Model)
		
		task.delay(3, function()
			for Item in Items do
				Item.Enabled = false
				task.delay(Item.Lifetime.Max, Item.Destroy, Item)
			end
		end)
	end
end

function VFX.Hit(AttackerRootPart : BasePart, VictimRootPart : BasePart, Count : string)
	if (VictimRootPart == nil or VictimRootPart.Parent == nil) then return end
	
	local AttackerPlayer = Players:GetPlayerFromCharacter(AttackerRootPart.Parent)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimRootPart.Position)

	if (Distance < 25) then
		CameraShake(3.5, 35, 0.1, 0.1, Vector3.one * 0.8)
	end
	
	if (Distance < 75) then
		local Offset = CFrame.new(0, 0, -6) -- rootpart is inside me but the animation makes him in front 😭

		EffectUtility.EmitEffects(script.Hit1, VictimRootPart, nil, Offset)
		EffectUtility.EmitEffectsOnBasePart(script.Hit2, VictimRootPart, nil, Offset)
		EffectUtility.EmitEffects(script.BigHit, VictimRootPart, nil, Offset * CFrame.Angles(0, math.rad(-90), 0))

		Blood.BloodRays("SpitOut", VictimRootPart.Parent.Head.MouthAttachment)
		
		Distort{Character = VictimRootPart.Parent, Rate = 4}	
		Afterimage(AttackerRootPart.Parent, {1}, {0.5}, 2)
	end
end

function VFX.Kick(VictimTorso : BasePart, Finisher : boolean)
	if (VictimTorso == nil or VictimTorso.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimTorso.Position)

	if (Distance < 25) then
		CameraShake(4.5, 45, 0.1, 0.1, Vector3.one * 0.8)
	end

	if (Distance < 75) then
		if not Finisher then
			EffectUtility.EmitEffects(script.KickSFX, VictimTorso)
		end
		
		local Position = VictimTorso.Parent.HumanoidRootPart.Position
		local Direction = Vector3.yAxis * -7
		
		local Raycast = workspace:Raycast(Position + (Vector3.yAxis * 1.5), Direction, Utility.VisualParams)

		if Raycast then
			local Kick = script.Kick:Clone()
			Kick.CFrame = CFrame.new(VictimTorso.CFrame.X, Raycast.Position, VictimTorso.CFrame.Z) 
			Kick.Parent = workspace.Visuals
			
			EffectUtility.EmitAttachment(Kick)
			
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

				SizeMultiplier = 0.65,
			})

			coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
				Amount = 9,
				Distance = 6,

				SizeMultiplier = 1.25,
			})

			coroutine.wrap(RockHandler.Rockst)(Raycast.Position, Direction, {
				Count = 7,
				Size = {0.85, 1},
				Velocity = 25,
			})
		end
	end
end

function VFX.HitOutsiders(VictimRootPart : BasePart, Count : string)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimRootPart.Position)

	if (Distance < 75 and Count ~= "last") then
		EffectUtility.EmitEffects(script.Hit1, VictimRootPart)
		EffectUtility.EmitEffectsOnBasePart(script.Hit2, VictimRootPart)
	end
end

function VFX.Windup(RootPart : BasePart)
	local Trail = EffectUtility.WeldArmTrail(RootPart.Parent["Right Leg"])
	task.delay(1, Trail.Destroy, Trail)
	
	EffectUtility.EmitEffects(script.Windup, RootPart)
end


function VFX.Start(AttackerRootPart : BasePart)
	EffectUtility.EmitEffects(script.SFX, AttackerRootPart)
end

function VFX.FinisherStart(AttackerRootPart : BasePart)
	EffectUtility.EmitEffects(script.FinisherSFX, AttackerRootPart)
end

function VFX.FinisherSlam(VictimTorso : BasePart)
	if (VictimTorso == nil or VictimTorso.Parent == nil) then return end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimTorso.Position)

	if (Distance < 25) then
		CameraShake(3, 25, 0.1, 0.4, Vector3.one * 0.8)
	end

	if (Distance < 75) then
		
		local Position = VictimTorso.Position
		local Direction = Vector3.yAxis * -7
		
		local Raycast = workspace:Raycast(Position + (Vector3.yAxis * 2), Direction, Utility.VisualParams)

		if Raycast then
			EffectUtility.EmitEffects(script.Finisher.Slam, workspace.Terrain, Raycast.Position)
		end
		
		coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			Amount = 5,
			Distance = 2.75,

			LookAt = { -- Where the rocks face towards (y axis)
				Min = -3,
				Max = -3
			},

			Exposure = {
				Min = 0.4,
				Max = 0.6
			},

			BaseZ = 1.5,

			SizeMultiplier = 0.85,
		})

		coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			Amount = 11,
			Distance = 7.5,
			
			Exposure = {
				Min = 0.6,
				Max = 0.85
			},

			SizeMultiplier = 1.45,
		})

		coroutine.wrap(RockHandler.Rockst)(Position, Direction, {
			Count = 8,
			Size = {0.85, 1},
			Velocity = 35,
		})

		if (VictimTorso ~= nil and VictimTorso.Parent ~= nil) then
			Blood.BloodRays("SpitOut", VictimTorso.Parent.Head.MouthAttachment)
		end
	end
end

local Finishers = {}

function VFX.FinisherCrush(AttackerTorso : BasePart, VictimTorso : BasePart)
	if (VictimTorso == nil or VictimTorso.Parent == nil) then return end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimTorso.Position)

	if (Distance < 75) then
		local ShakeObject
		
		if (Distance < 25) then
			ShakeObject = CameraShake(4, 20, 0.1, 0, Vector3.one * 0.8)
			Yuki_FOV.Tween(45, {1})
		end
		
		local Crush = script.Finisher.Crush:Clone()
		local Raycast = workspace:Raycast(VictimTorso.Position + (Vector3.yAxis * 2), Vector3.yAxis * -7, Utility.VisualParams)
	
		if Raycast then
			EffectUtility.EmitEffects(script.Finisher.Slam, workspace.Terrain, Raycast.Position + Vector3.yAxis * 0.25)

			Crush.CFrame = CFrame.new(VictimTorso.CFrame.X, Raycast.Position, VictimTorso.CFrame.Z) 
			Crush.Parent = workspace.Visuals
		end
		
		local AuraItems = {}
		
		for _, BasePart in ipairs(AttackerTorso.Parent:GetChildren()) do
			if BasePart:IsA("BasePart") and BasePart.Name ~= "HumanoidRootPart" then
				for _, Aura in ipairs(Assets.ArmAura:GetChildren()) do
					local NewItem = Aura:Clone()
					NewItem.Enabled = true
					NewItem.Parent = BasePart

					AuraItems[NewItem] = true
				end
			end
		end
		
		local Time = time()
	
		coroutine.wrap(function()
			while (Crush.Parent ~= nil) do
				Bubble(VictimTorso.Position, 6, Vector3.zero, Vector3.one * 30, 0.5)

				if time() - Time > 1 then
					Blood.BloodRays("SpitOut", VictimTorso.Parent.Head.MouthAttachment)
					
					coroutine.wrap(RockHandler.Rockst)(VictimTorso.Position, Vector3.yAxis * -10, {
						Size = {0.75, 1},
						Count = 4,
						Velocity = 20,
					})
				end

				task.wait(0.1)
			end
		end)()
		
		Crush.Destroying:Once(function()
			if (Distance < 25) then
				if ShakeObject ~= nil then
					ShakeObject:StartFadeOut(0.1)
				end

				Yuki_FOV.Tween(70, {1})
			end
			
			for Aura in AuraItems do
				Aura:Destroy()
			end
		end)
		
		Finishers[AttackerTorso] = Crush
	end
end

function VFX.ClearFinisherCrush(AttackerTorso : BasePart)
	if (Finishers[AttackerTorso] == nil) then return end

	Finishers[AttackerTorso]:Destroy()
end

function VFX.FinisherCrushed(AttackerTorso : BasePart, VictimTorso : BasePart)
	VFX.ClearFinisherCrush(AttackerTorso)
	
	if (VictimTorso ~= nil and VictimTorso.Parent ~= nil) then
		local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimTorso.Position)
		if  Distance >100 then return end
		
		if Distance < 25 then
			CameraShake(2.5, 40, 0.05, 0.5)
		end

		local Position = VictimTorso.Position
		local Direction = Vector3.yAxis * -7

		local Raycast2 = workspace:Raycast(VictimTorso.Position + (Vector3.yAxis * 2), Direction, Utility.VisualParams)

		if Raycast2 then
			local BloodEnabled = Players.LocalPlayer:GetAttribute("Blood")

			local FinisherBoom
			if BloodEnabled then
				FinisherBoom = script.Finisher.Boom
			else
				FinisherBoom = script.Finisher.BoomNoBlood
			end
			
			local Boom = FinisherBoom:Clone()
			Boom.CFrame = CFrame.new(VictimTorso.CFrame.X, Raycast2.Position, VictimTorso.CFrame.Z) 
			Boom.Parent = workspace.Visuals

			EffectUtility.EmitAttachment(Boom)
		end

		coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			Amount = 15,
			Distance = 7.5,
			
			Exposure = {
				Min = 0.3,
				Max = 0.5
			},

			SizeMultiplier = 1,
		})

		coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			Amount = 20,
			Distance = 14,
			
			Exposure = {
				Min = 0.75,
				Max = 1
			},
			
			SizeMultiplier = 1.5,
		})
		
		coroutine.wrap(RockHandler.Rockst)(Position, Direction, {
			Count = 12,
			Size = {0.9, 1.1},
			Velocity = 55,
		})

		Blood.BloodRays("BeatdownFinisher", VictimTorso)

		for _, Item in ipairs(VictimTorso.Parent:GetDescendants()) do
			if Item:IsA("BasePart") or Item:IsA("Decal") then
				Item.Transparency = 1
			end
		end
	end
end

return VFX
