local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )

local Bubble = require( ReplicatedStorage.Modules.Player.Replication.Global.Bubble )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local GrabbedAssets = script.Grabbed

local VFX = {}
VFX.HandEffects = {}

function VFX.Land(Model : Model)
	local RootPart = Model:FindFirstChild("HumanoidRootPart")
	if (RootPart == nil) then return print("no root") end
	
	local Position : Vector3 = RootPart.Position
	local Direction = Vector3.yAxis * -10
	
	if EffectUtility.Distance_Close(Model) then
		CameraShake(1.5, 15, 0.01, 0.4, Vector3.one * 0.8, Vector3.one * 0.35)
	end
	
	coroutine.wrap(RockHandler.Crater)(Position, Direction, {
		Amount = 12,
		
		Distance = {
			Min = 2.5,
			Max = 7
		},

		LookAt = { -- Where the rocks face towards (y axis)
			Min = -5,
			Max = -5
		},

		Exposure = {
			Min = 0.1,
			Max = 0.2
		},

		BaseZ = 1.35,

		SizeMultiplier = 1,
	})

	coroutine.wrap(RockHandler.Rockst)(Position, Direction, {
		Count = 15,
		Size = {0.35, 0.9},
		Velocity = 50,
	})
	
	EffectUtility.RaycastCraterSmoke("Normal", Position, Direction)
end

function VFX.Hand(Arm : BasePart)
	if (Arm == nil or Arm.Parent == nil) then return end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Arm.Position)
	
	if (Distance < 75) then
		local Hand = GrabbedAssets.Ball.Hand:Clone()
		Hand.Name = "Hand"
		Hand.Parent = Arm

		EffectUtility.Toggle(Hand, true)
		VFX.HandEffects[Arm] = Hand
	end
end

function VFX.RemoveHand(Arm : BasePart)
	if (VFX.HandEffects[Arm] ~= nil) then
		local HandEffect = VFX.HandEffects[Arm]
		VFX.HandEffects[Arm] = nil
		
		EffectUtility.Toggle(HandEffect, false)
		task.delay(1, HandEffect.Destroy, HandEffect)
	end
end

function VFX.AirVariantSFX(RootPart : BasePart)
	EffectUtility.EmitEffects(script.AirVariantSFX, RootPart)
end

function VFX.AirBlast(AttackerArm : BasePart)
	if (AttackerArm == nil or AttackerArm.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(AttackerArm.Position)

	if (Distance < 10) then
		ScreenPulse("Black Flash")
		CameraShake(4.5, 45, 0.1, 0.35, Vector3.one * 0.8)
	end
	
	VFX.RemoveHand(AttackerArm)
	
	local AttackerRootPart : BasePart = AttackerArm.Parent.HumanoidRootPart
	local CF = AttackerRootPart.CFrame * CFrame.Angles(math.rad(-45), 0, 0)

	for Index = 1, 2 do
		local Shoot = GrabbedAssets.Shoot.Air["Shoot" .. Index]:Clone()
		Shoot.CFrame = CF
		Shoot.Parent = workspace.Visuals
		EffectUtility.Emit(Shoot)
	end
	
	local Direction = CF.LookVector * 45
	local Raycast = workspace:Raycast(CF.Position, Direction, Utility.VisualParams)

	if (Raycast ~= nil) then
		EffectUtility.EmitEffects(script.Impact, workspace.Terrain, Raycast.Position)
		EffectUtility.CraterSmoke("Big", Raycast)
		
		coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
			Amount = 8,
			Distance = 5.5,
			
			LookAt = {
				Min = -3,
				Max = -3
			},

			Exposure = {
				Min = 0.2,
				Max = 0.4
			},
		})
		
		coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
			Amount = 10,
			Distance = 7.5,
			
			Exposure = {
				Min = 0.475,
				Max = 0.65
			},
		})
		
		coroutine.wrap(RockHandler.Rockst)(Raycast.Position, Direction, {
			Size = {0.85, 1.5},
			Count = 8,
			Velocity = 35,
		})
	end
end

function VFX.Blast(AttackerArm : BasePart, AirVariant : boolean)
	if (AttackerArm == nil or AttackerArm.Parent == nil) then return end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(AttackerArm.Position)

	if (Distance < 10) then
		ScreenPulse("Black Flash")
		CameraShake(3.5, 35, 0.1, 0.35, Vector3.one * 0.8)
	end

	VFX.RemoveHand(AttackerArm)
	
	local AttackerRootPart : BasePart = AttackerArm.Parent.HumanoidRootPart

	for Index = 1, (AirVariant and 2 or 3) do
		local Shoot = GrabbedAssets.Shoot[AirVariant and "Air" or "Normal"]["Shoot" .. Index]:Clone()
		
		if AirVariant then
			Shoot.CFrame = AttackerRootPart.CFrame * CFrame.new(0, 1.5, -3) * CFrame.Angles(math.rad(30), 0, 0)
		else
			if Index == 3 then
				Shoot.CFrame = AttackerRootPart.CFrame * CFrame.new(0, 0.4, -22.3)
			else
				Shoot.CFrame = AttackerRootPart.CFrame * CFrame.new(0, 0.4, -3)
			end
		end
		
		Shoot.Parent = workspace.Visuals
		EffectUtility.Emit(Shoot)
	end
end

function VFX.Hit(AttackerRootPart : BasePart, VictimRootPart : BasePart, Count : string)
	if (VictimRootPart == nil or VictimRootPart.Parent == nil) then return end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimRootPart.Position)

	if (Distance < 10) then
		CameraShake(2.5, 20, 0.1, 0.25, Vector3.one * 0.8)
	end
	
	if Distance < 75 then
		Blood.BloodRays("SpitOut", VictimRootPart.Parent.Head.MouthAttachment)
	end
	
	EffectUtility.EmitEffects(GrabbedAssets.Punch, workspace.Terrain, AttackerRootPart.CFrame * CFrame.new(0, 1.5, -3))
end

function VFX.Sweep(RootPart : BasePart)
	if (RootPart == nil or RootPart.Parent == nil) then return end

	local Model : Model = RootPart.Parent
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if (Distance < 75) then
		local Trail = EffectUtility.WeldArmTrail(Model["Left Leg"])
		local Raycast = workspace:Raycast(RootPart.Position, Vector3.yAxis * -10, Utility.VisualParams)

		if (Raycast) then
			EffectUtility.EmitEffects(script.Windup, workspace.Terrain, Raycast.Position + Vector3.yAxis * 1.5)
		end

		task.delay(0.5, Trail.Destroy, Trail)
	end
end

function VFX.Start(VictimRootPart : BasePart, AttackerRootPart : BasePart)
	EffectUtility.EmitEffects(script.SFX, AttackerRootPart)
	EffectUtility.EmitEffects(script.Grabbed.Swinged, workspace.Terrain, VictimRootPart.Position - Vector3.yAxis * 1.5)
end

local Finishers = {
	Pulls = {},
	Runs = {}
}

local FinisherAssets = script.Finisher
local FinisherAssetsRun = FinisherAssets.Run

function VFX.FinisherStart(RootPart : BasePart, Arm : BasePart)
	VFX.Blast(Arm, false)
	task.delay(0.1, EffectUtility.EmitEffects, FinisherAssets.SFX, RootPart)
end

function VFX.FinisherPull(AttackerTorso : BasePart, VictimTorso : BasePart)
	if (VictimTorso == nil or VictimTorso.Parent == nil) then return end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimTorso.Parent.HumanoidRootPart.Position)

	if (Distance < 100) then
		local Blue = FinisherAssets.blue:Clone()
		Blue.Weld.Part1 = VictimTorso
		Blue.Parent = workspace.Visuals

		EffectUtility.Toggle(Blue, true)

		Finishers.Pulls[VictimTorso] = Blue
	end
	
	if (Distance < 25) then
		ScreenPulse("Blue Choose")
		CameraShake(1, 10, 0.05, 0.2, Vector3.one * 0.8)
	end
	
	if Player == Players:GetPlayerFromCharacter(AttackerTorso.Parent) or Player == Players:GetPlayerFromCharacter(VictimTorso.Parent) then
		Yuki_FOV.Tween(90, {0.5})
	end
end

function VFX.RemovePullEffect(VictimTorso : BasePart)
	if (VictimTorso == nil or VictimTorso.Parent == nil) or (Finishers.Pulls[VictimTorso] == nil) then return end

	local Effect = Finishers.Pulls[VictimTorso]
	Finishers.Pulls[VictimTorso] = nil
	
	EffectUtility.Toggle(Effect, false)
	task.delay(2, Effect.Destroy, Effect)
end

function VFX.RemoveRunEffects(AttackerTorso : BasePart)
	if (AttackerTorso == nil or AttackerTorso.Parent == nil) or (Finishers.Runs[AttackerTorso] == nil) then return end
	
	for _, Item in Finishers.Runs[AttackerTorso] do
		if typeof(Item) == "table" and Item.IsACameraShakeInstance then
			Item:StartFadeOut(0.1)
			
		elseif typeof(Item) == "table" then
			for ItemInItem in Item do
				ItemInItem:Destroy()
			end
			
		elseif typeof(Item) == "thread" then
			task.cancel(Item)
			
		else
			Finishers.Runs[AttackerTorso][Item] = nil
			EffectUtility.Toggle(Item, false)
			task.delay(1, Item.Destroy, Item)
		end
	end
	
	table.clear(Finishers.Runs[AttackerTorso])
	Finishers.Runs[AttackerTorso] = nil
end

function VFX.FinisherRun(AttackerTorso : BasePart, VictimTorso : BasePart)
	if (VictimTorso == nil or VictimTorso.Parent == nil) then return end
	
	VFX.RemovePullEffect(VictimTorso)

	local Inf1 = FinisherAssetsRun.User:Clone()
	Inf1.Weld.Part1 = AttackerTorso
	Inf1.Parent = workspace.Visuals

	local Inf2 = FinisherAssetsRun.Victim:Clone()
	Inf2.Weld.Part1 = AttackerTorso.Parent.HumanoidRootPart
	Inf2.Parent = workspace.Visuals

	local Rush = FinisherAssetsRun.Rush:Clone()
	Rush.Weld.Part1 = AttackerTorso.Parent.HumanoidRootPart
	Rush.Parent = workspace.Visuals

	EffectUtility.Toggle(Inf1, true)
	EffectUtility.Toggle(Inf2, true)
	EffectUtility.Toggle(Rush, true)

	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimTorso.Position)
	local Shake = nil
	
	if Player == Players:GetPlayerFromCharacter(AttackerTorso.Parent) or Player == Players:GetPlayerFromCharacter(VictimTorso.Parent) then
		Yuki_FOV.Tween(67.5, {0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
		Shake = CameraShake(1.5, 15, 0.1, 0, Vector3.one * 0.8)
	end

	local FakeArms = {}

	for _, Item in ipairs(AttackerTorso.Parent:GetChildren()) do
		if Item:IsA("BasePart") and (string.find(Item.Name, "Right") or string.find(Item.Name, "Left")) then
			local FakeArm = EffectUtility.WeldArmTrail(Item)
			FakeArms[FakeArm] = true
		end
	end
	
	local RunThread = coroutine.create(function()
		while (AttackerTorso ~= nil and AttackerTorso.Parent ~= nil) do
			RockHandler.Rocks("Side Dash", AttackerTorso)
			Smoke(AttackerTorso, -5, 2)

			task.wait(0.02)
		end
	end)
	
	local BubbleThread = coroutine.create(function()
		while (AttackerTorso ~= nil and AttackerTorso.Parent ~= nil) do
			Bubble(AttackerTorso, 6, Vector3.zero, Vector3.one * 11, 0.4)

			task.wait(0.15)
		end
	end)

	coroutine.resume(RunThread)
	coroutine.resume(BubbleThread)
	
	Finishers.Runs[AttackerTorso] = {Inf1, Inf2, Rush, RunThread, BubbleThread, FakeArms, Shake}
end

function VFX.FinisherPush(AttackerTorso : BasePart, VictimTorso : BasePart)
	VFX.RemoveRunEffects(AttackerTorso)

	if (VictimTorso == nil or VictimTorso.Parent == nil) then return end
	
	if Player == Players:GetPlayerFromCharacter(AttackerTorso.Parent) or Player == Players:GetPlayerFromCharacter(VictimTorso.Parent) then
		Yuki_FOV.Tween(110, {0.5})
		
		task.delay(0.8, function()
			Yuki_FOV.Tween(70, {1})
		end)
	end
	
	Bubble(AttackerTorso, 6, Vector3.zero, Vector3.one * 25, 0.25)

	local Burst = FinisherAssets.Burst:Clone()
	Burst.CFrame = AttackerTorso.Parent.HumanoidRootPart.CFrame * CFrame.new(0, 0, -4.27)
	Burst.Parent = workspace.Visuals

	EffectUtility.Emit(Burst)
	
	VFX.FinisherSlide(AttackerTorso, 30)
	
	local GroundThread = coroutine.create(function()
		while (VictimTorso ~= nil and VictimTorso.Parent ~= nil) do
			Smoke(VictimTorso)
			task.wait(0.03)
		end
	end)

	coroutine.resume(GroundThread)
	
	task.delay(1, function()
		task.cancel(GroundThread)
	end)
	
	CameraShake(2.5, 25, 0.05, 0.2, Vector3.one * 0.8)
end

function VFX.FinisherSlide(AttackerTorso : BasePart, Indexes : number)
	coroutine.wrap(function()
		for Index = 1, Indexes do
			if (AttackerTorso == nil or AttackerTorso.Parent == nil) then
				return
			end
			
			RockHandler.Rocks("Side Dash", AttackerTorso)
			Smoke(AttackerTorso)
			
			task.wait(0.02)
		end
	end)()
end

function VFX.FinisherGrabbed(VictimTorso : BasePart)
	if (VictimTorso == nil or VictimTorso.Parent == nil) then return end
	
	VFX.RemovePullEffect(VictimTorso)
	CameraShake(2.5, 25, 0.05, 0.25, Vector3.one * 0.8)
end

function VFX.FinisherSlam(VictimTorso : BasePart)
	if (VictimTorso == nil or VictimTorso.Parent == nil) then return end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimTorso.Position)

	if (Distance < 25) then
		CameraShake(5.5, 55, 0.1, 0.5, Vector3.one * 0.8)
	end
	
	if (Distance < 100) then
		local Position = VictimTorso.Position
		local Direction = Vector3.yAxis * -10
		
		local Raycast = workspace:Raycast(Position + Vector3.yAxis * 2, Direction, Utility.VisualParams)

		if Raycast then
			local Slam = FinisherAssets.slamdown:Clone()
			Slam.Position = Raycast.Position + Vector3.yAxis * 1.1
			Slam.Parent = workspace.Terrain
			EffectUtility.Emit(Slam)
			
			EffectUtility.CraterSmoke("Big", Raycast)
		end

		coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			Amount = 8,
			Distance = 6,

			LookAt = { -- Where the rocks face towards (y axis)
				Min = -3,
				Max = -3
			},

			Exposure = {
				Min = 0.3,
				Max = 0.5
			},

			BaseZ = 1.5,
			SizeMultiplier = 1,
		})

		coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			Amount = 13,
			Distance = 11,
			SizeMultiplier = 1.5,
		})
		
		Blood.BloodRaysWithoutPreset(VictimTorso, {
			Face = Enum.NormalId.Top, 
			SpreadAngle = Vector2.new(65, 65), 
			Amount = Vector2.new(6, 8), 
			Power = 35,
			PoolSize = 1.5	
		})
	end
end

return VFX
