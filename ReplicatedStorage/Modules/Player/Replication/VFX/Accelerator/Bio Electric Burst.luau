local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local Distort = require( ReplicatedStorage.Modules.Player.Replication.Global.Distort )

local Assets = script.Assets

local VFX = {}

local function ArmRip(Victim : Model, Side : string, Velocity)
	local Arm : BasePart = Victim[Side.. " Arm"]
	local ActualVelocity = (Velocity or Vector3.new(30, 5, 0))

	if Arm.Transparency ~= 0 then
		return
	end

	local ArmModel = Instance.new("Model")
	ArmModel.Name = "ArmEffect"
	ArmModel.Parent = workspace.Visuals

	if Victim:FindFirstChildOfClass("Shirt") then
		Victim.Shirt:Clone().Parent = ArmModel
	end

	for _,v in Victim:GetChildren() do
		if v:IsA("CharacterMesh") then
			v:Clone().Parent = ArmModel
		end
	end

	local FakeArm = Arm:Clone()
	FakeArm.Parent = ArmModel

	FakeArm.CanCollide = true

	FakeArm.CollisionGroup = "Rockst"

	local ArmHumanoid = Instance.new("Humanoid")
	ArmHumanoid.BreakJointsOnDeath = false
	ArmHumanoid.Parent = ArmModel

	Arm.Transparency = 1

	FakeArm.AssemblyLinearVelocity = ActualVelocity
	FakeArm.AssemblyAngularVelocity = ActualVelocity / 2

	task.spawn(function()
		repeat
			FakeArm.CanCollide = true

			task.wait(0.25)
		until not ArmModel:IsDescendantOf(game)
	end)

	task.delay(5, function()
		Arm.Transparency = 0
		ArmModel:Destroy()
	end)
end

function VFX.Shock(Arm : BasePart, Victim : Model)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Arm.Position)
	if (Distance > 75) then return end

	local Attach : Attachment = Assets.Holder.Shock:Clone()
	Attach.Parent = Arm

	EffectUtility.Toggle(Attach, true)

	task.delay(0.75, function()
		EffectUtility.Toggle(Attach, false)
		task.delay(3, Attach.Destroy, Attach)
	end)

	Distort{Rate = 6, StartPercentage = 2}

	local Shake = CameraShake(3, 20, 0.1, 0, Vector3.one * 0.8)

	local Highlight = Instance.new("Highlight")
	Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	Highlight.FillTransparency = 0
	Highlight.OutlineTransparency = 1
	Highlight.FillColor = Color3.fromRGB(141, 60, 255)
	Highlight.Parent = Victim

	TweenService:Create(Highlight, TweenInfo.new(0.025, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 27, true), 
		{FillTransparency = 1}
	):Play()

	task.spawn(function()
		for Index = 1, 27 do
			if (Victim == nil or Victim.Parent == nil) then break end

			ScreenPulse("Bio Electric Burst Hit")
			task.wait(0.01)
		end

		Highlight:Destroy()
		
		if Shake then
			Shake:StartFadeOut(0.2)
		end
	end)
end

function VFX.Swing(RootPart : BasePart, Index : number)
	EffectUtility.EmitEffects(Assets["Swing" .. Index], RootPart, CFrame.new(0, 0, -0.25))
end

function VFX.Startup(RootPart : BasePart)
	EffectUtility.EmitEffects(script.StartupSFX, RootPart)
end

function VFX.Hit(RootPart : BasePart, Victim : Model, Index : number)
	if (Victim == nil or Victim.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 75) then return end

	local Highlight = Instance.new("Highlight")
	Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	Highlight.FillTransparency = 0
	Highlight.OutlineTransparency = 1
	Highlight.FillColor = Color3.fromRGB(141, 60, 255)
	Highlight.Parent = Victim

	TweenService:Create(Highlight, TweenInfo.new(0.3), 
		{FillTransparency = 1}
	):Play()
	
	task.delay(0.3, Highlight.Destroy, Highlight)

	if Index == 1 then
		EffectUtility.EmitEffects(script.SFX, RootPart)
	end

	if (Index == 4) then
		if (Distance < 25) then
			CameraShake(2.5, 25, 0.1, 0.5, Vector3.one * 0.8)
			ScreenPulse("Bio Electric Burst Final Hit")
		end

		local ExplosionPosition = (RootPart.CFrame * CFrame.new(0, -2.5, -5.5)).Position
		EffectUtility.EmitEffects(Assets.Explosion, workspace.Terrain, ExplosionPosition)

		local Direction = (Vector3.yAxis * -10)

		coroutine.wrap(RockHandler.Crater)(ExplosionPosition, Direction, {
			Amount = 8,
			Distance = 6,

			LookAt = { -- Where the rocks face towards (y axis)
				Min = -3,
				Max = -3
			},

			Exposure = {
				Min = 0.2,
				Max = 0.4
			},

			SizeMultiplier = 0.95,
		})

		coroutine.wrap(RockHandler.Crater)(ExplosionPosition, Direction, {
			Amount = 10,
			Distance = 7.5,
			SizeMultiplier = 1.15,
		})

		coroutine.wrap(RockHandler.Rockst)(ExplosionPosition, Direction, {
			Count = 14,
			Size = {0.85, 1},
			Velocity = 35,
		})
	else
		EffectUtility.EmitEffects(Assets.Smack, Victim.Torso)

		if (Distance < 25) then
			CameraShake(2, 15, 0.1, 0.25, Vector3.one * 0.8)
			ScreenPulse("Bio Electric Burst Hit")
		end
	end
end

function VFX.HitOutsider(Victim : Model)
	if (Victim == nil or Victim.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(Victim.Torso.Position)
	if (Distance > 75) then return end

	EffectUtility.EmitEffects(Assets.Smack, Victim.Torso)
end

local VFXHolder = {}

function VFX.Start(RootPart : BasePart)
	EffectUtility.EmitEffects(script.FinisherSFX, RootPart)
end

function VFX.FinisherExplosion(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	local ExplosionVFX = Assets.Holder["1"]:Clone()
	ExplosionVFX.Parent = RootPart

	EffectUtility.Emit(ExplosionVFX)

	if (Distance < 25) then
		CameraShake(3, 20, 0.1, 0.25, Vector3.one * 0.8)
		ScreenPulse("Bio Electric Burst Hit")
	end
end

local ShakeTable = {}

function VFX.FinisherRipping(RootPart : BasePart, Victim)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	local ExplosionVFX = Assets.Holder["1"]:Clone()
	ExplosionVFX.Parent = RootPart

	local ArmVFX = Assets.Holder.Arm1:Clone()
	ArmVFX.Parent = RootPart.Parent["Left Arm"]

	local ArmVFX2 = Assets.Holder.Arm1:Clone()
	ArmVFX2.Parent = RootPart.Parent["Right Arm"]

	local RippingVFX = Assets.Holder["3"]:Clone()
	RippingVFX.Parent = RootPart

	EffectUtility.Toggle(ArmVFX, true)
	EffectUtility.Toggle(ArmVFX2, true)
	EffectUtility.Toggle(RippingVFX, true)

	EffectUtility.Emit(ExplosionVFX)

	local Shake
	
	task.spawn(function()
		if Players.LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or (Victim and Players.LocalPlayer == Players:GetPlayerFromCharacter(Victim)) then
			Yuki_FOV.Tween(45, {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
		end
	end)

	if (Distance < 25) then
		Shake = CameraShake(2, 15, 0.1, 0, Vector3.one * 0.7)
		
		task.delay(3, function()
			if Shake then
				Shake:StartFadeOut(0.1)
			end
		end)

		coroutine.wrap(function()
			for Index = 1, 50 do
				ScreenPulse("Bio Electric Burst Hit")

				task.wait(0.01)
			end
		end)()
	end

	VFXHolder[RootPart] = {ArmVFX, ArmVFX2, RippingVFX}
	
	if Shake then
		ShakeTable[RootPart] = Shake
	end
end

function VFX.ScreenFXEnd(RootPart : BasePart, Victim : Model)
	if RootPart and ShakeTable[RootPart] then
		ShakeTable[RootPart]:StartFadeOut(0.1)
	end
	
	if Players.LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or (Victim and Players.LocalPlayer == Players:GetPlayerFromCharacter(Victim)) then
		Yuki_FOV.Tween(95, {0.15})
	end

	task.delay(0.5, function()
		if Players.LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or (Victim and Players.LocalPlayer == Players:GetPlayerFromCharacter(Victim)) then
			Yuki_FOV.Tween(70, {1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
		end
	end)
end

function VFX.FinisherRip(RootPart : BasePart, Victim : Model)
	if (RootPart == nil or RootPart.Parent == nil) or (VFXHolder[RootPart] == nil) then return end

	for _, Item in VFXHolder[RootPart] do
		if typeof(Item) == "Instance" and Item:IsA("Attachment") then
			EffectUtility.Toggle(Item, false)
			task.delay(2, Item.Destroy, Item)
		end
	end

	VFX.ScreenFXEnd(RootPart, Victim)
	
	local BloodEnabled = Players.LocalPlayer:GetAttribute("Blood")

	local Holder
	if BloodEnabled then
		Holder = script.Assets.Holder
	else
		Holder = script.Assets.NoBloodHolder
	end
	
	local RipVFX = Holder["2"]:Clone()
	RipVFX.Parent = RootPart

	EffectUtility.Emit(RipVFX)

	if (Victim ~= nil and Victim.Parent ~= nil) then
		ArmRip(Victim, "Left")
		ArmRip(Victim, "Right")
	end
end

return VFX