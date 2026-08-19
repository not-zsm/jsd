--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local TweenService = game:GetService('TweenService');
local Players = game:GetService("Players")

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local Shockwave = require( ReplicatedStorage.Modules.Player.Replication.Global.Shockwave )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local VFX = {};
VFX.UnchargeEvents = {}

function VFX.Charge(Arm : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Arm.Position)
	if (Distance > 75) then return end

	if Distance < 25 then
		CameraShake(2.5, 20, 0.1, 0.25, Vector3.one * 0.8)
		ScreenPulse("Bio Electric Burst Hit")
	end

	local Attach = script.Assets.Holder.Charge:Clone()
	Attach.Parent = Arm

	for _, Item in ipairs(Attach:GetDescendants()) do
		if (Item:IsA('ParticleEmitter')) then
			if (Item.Parent.Name == "Emit") then
				Item:Emit(Item:GetAttribute("EmitCount"))
			else
				Item.Enabled = true
			end
		end
	end

	local function Finish()
		for _, Item in ipairs(Attach:GetDescendants()) do
			if (Item:IsA('ParticleEmitter')) then
				Item.Enabled = false
			end
		end

		task.delay(2, Attach.Destroy, Attach)
	end

	EffectUtility.EmitEffects(script.SFXCharge, Arm)
	VFX.UnchargeEvents[Arm] = EventService.new()
	
	local Event = VFX.UnchargeEvents[Arm]:Once(Finish)

	task.delay(3, function()
		Event:Disconnect(); Finish();
	end)
end

function VFX.Uncharge(Arm : BasePart)
	if (VFX.UnchargeEvents[Arm] == nil) then return end
	
	VFX.UnchargeEvents[Arm]:Fire()
end

function VFX.Hit(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 75) then return end
	
	EffectUtility.EmitEffects(script.SFXHit, RootPart)
end

function VFX.Shoot(RootPart : BasePart, ServerCFrame : CFrame, Hit : boolean)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(ServerCFrame.Position)
	if (Distance > 75) then return end

	if Distance < 25 then
		CameraShake(3, 20, 0.1, 0.5, Vector3.one * 0.8)
		ScreenPulse("Bio Electric Burst Final Hit")
	end

	EffectUtility.EmitEffects(script.SFXShoot, RootPart)
	Shockwave(ServerCFrame, nil, nil, Vector3.new(0.5, 15, 15))
	
	local Punch : typeof(script.Assets.Punch) = script.Assets[Hit and "Punch" or "PunchMiss"]:Clone()
	Punch.CFrame = ServerCFrame * CFrame.new(0, 0, -3)
	Punch.Parent = workspace.Visuals

	for Index = 1, 3 do
		local Attachment : Attachment = (Index == 1 and Punch["ground smth"] or Index == 2 and Punch["left smoke"] or Index == 3 and Punch["right smoke"])
		local Raycast = workspace:Raycast(Attachment.WorldPosition, Vector3.yAxis * -10, Utility.VisualParams)

		if (Raycast ~= nil) then
			for _, Item in ipairs(Attachment:GetChildren()) do
				if (Item:IsA('ParticleEmitter')) then
					Item.Color = ColorSequence.new(Raycast.Instance.Color)
				end
			end
		end
	end 
	
	EffectUtility.Emit(Punch)

	--local Punch = script.Assets.Holder.Punch:Clone()
	--Punch.CFrame = ServerCFrame

	--local Wind = script.Assets.Holder.Wind:Clone()
	--Wind.CFrame = ServerCFrame

	--for Index = 1, 3 do
	--	local Attachment : Attachment = (Index == 1 and Punch.Ground or Punch.Ground[Index == 2 and "Left" or "Right"])
	--	local Raycast = workspace:Raycast((Attachment.WorldCFrame * CFrame.new(0, 0, -5)).Position, Vector3.yAxis * -5, Utility.VisualParams)

	--	if (Raycast ~= nil) then
	--		for _, Item in ipairs(Attachment:GetChildren()) do
	--			if (Item:IsA('ParticleEmitter')) then
	--				Item.Color = ColorSequence.new(Raycast.Instance.Color)
	--			end
	--		end
	--	end
	--end 

	--Punch.Parent, Wind.Parent = workspace.Terrain, workspace.Terrain

	--EffectUtility.Emit(Punch, true)
	--EffectUtility.Toggle(Wind, true)

	--local Tween = TweenService:Create(Wind, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), 
	--	{CFrame = Wind.CFrame * CFrame.new(0, 0, -20)}
	--)

	--Tween:Play()

	--Tween.Completed:Once(function(State)
	--	if (State == Enum.PlaybackState.Completed) then
	--		EffectUtility.Toggle(Wind, false)
	--	end
	--end)

	coroutine.wrap(RockHandler.RockLines)(ServerCFrame, {})
	coroutine.wrap(RockHandler.RockLines)(ServerCFrame, {RandomJitter = 0.65, SizeIndex = 0.1, Angle = math.rad(55)})
end

local FinisherAssets = script.Assets.Finisher

local DownDirection = Vector3.yAxis * -10

function VFX.FinisherHit(RootPart : BasePart)
	EffectUtility.EmitEffects(FinisherAssets.SFX, RootPart)
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 100) then return end

	local CF = RootPart.CFrame * CFrame.new(0, 1, -4)

	local Effect = FinisherAssets.Hit:Clone()
	Effect.CFrame = CF
	Effect.Parent = workspace.Visuals
	EffectUtility.Emit(Effect)
end

function VFX.FinisherSwingDown(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 100) then return end

	if Distance < 25 then
		CameraShake(0.5, 7.5, 0.1, 0.35, Vector3.one * 0.8)
	end
	
	EffectUtility.EmitEffects(FinisherAssets.SwingDown, workspace.Terrain, RootPart.CFrame * CFrame.new(0, 0, 1))
end

function VFX.FinisherThrowDown(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 150) then return end

	if Distance < 25 then
		CameraShake(2.5, 25, 0.1, 0.3, Vector3.one * 0.8)
	end
	
	EffectUtility.EmitEffects(FinisherAssets.ThrowDown, workspace.Terrain, RootPart.CFrame * CFrame.new(0, -2.5, 4))
	
	task.delay(0.175, function()
		EffectUtility.EmitEffects(FinisherAssets.Up, workspace.Terrain, RootPart.CFrame * CFrame.new(0, 0.5, 0))
		
		for _, Item in ipairs(RootPart.Parent:GetChildren()) do
			if Item:IsA("BasePart") and (string.find(Item.Name, "Right") or string.find(Item.Name, "Left")) then
				local FakeArm = EffectUtility.WeldArmTrail(Item)
				task.delay(0.5, FakeArm.Destroy, FakeArm)
			end
		end
	end)
	
	task.delay(0.3, function()
		EffectUtility.EmitEffects(FinisherAssets.Spin, workspace.Terrain, RootPart.CFrame * CFrame.new(0, 2.5, 2.5))
	end)
end

function VFX.FinisherKickDownPause(RootPart : BasePart)
	EffectUtility.EmitEffects(FinisherAssets.KickDownPause, workspace.Terrain, RootPart.CFrame * CFrame.new(0, 2, 6))
end

function VFX.FinisherKickDownResume(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 150) then return end

	if Distance < 25 then
		CameraShake(3, 30, 0.1, 0.25, Vector3.one * 0.8)
	end
	
	EffectUtility.EmitEffects(FinisherAssets.KickDownResume, workspace.Terrain, RootPart.CFrame * CFrame.new(0, -2.5, 6))
end

function VFX.FinisherStomp(RootPart : BasePart, VictimRootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 150) then return end

	if Distance < 25 then
		CameraShake(4, 40, 0.1, 0.3, Vector3.one * 0.8)
	end
	
	local CF = RootPart.CFrame * CFrame.new(0, -2.5, 6)
	local Position = CF.Position
	
	Blood.BloodRaysWithoutPreset(VictimRootPart.Parent.Head.MouthAttachment, {
		Amount = Vector2.new(5, 8),

		Spread = Vector2.new(90, 90),
		Face = Enum.NormalId.Top,

		PoolSize = 1.15,
	})
	
	coroutine.wrap(RockHandler.Crater)(Position, DownDirection, {
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

	coroutine.wrap(RockHandler.Crater)(Position, DownDirection, {
		Amount = 9,
		Distance = 6,

		SizeMultiplier = 1.35,
	})

	coroutine.wrap(RockHandler.Rockst)(Position, DownDirection, {
		Count = 14,
		Size = {0.85, 1},
		Velocity = 35,
	})
	
	EffectUtility.EmitEffects(FinisherAssets.Stomp, workspace.Terrain, CF)
end

function VFX.FinisherPosition(RootPart : BasePart)
	EffectUtility.RaycastCraterSmoke("Small", RootPart.Position, DownDirection)
	EffectUtility.EmitEffects(FinisherAssets.Position, workspace.Terrain, RootPart.CFrame * CFrame.new(0, -2.5, 0))
	VFX.Charge(RootPart.Parent["Right Arm"])
end

function VFX.FinisherPunchPause(RootPart : BasePart, VictimRootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 150) then return end
	
	if Distance < 25 then
		CameraShake(3.5, 25, 0.1, 1.5, Vector3.one * 0.8)
		
		coroutine.wrap(function()
			for Index = 1, 6 do
				ScreenPulse("Vector Punch", true)
				task.wait(0.2)
			end
		end)()
	end

	if Players:GetPlayerFromCharacter(RootPart.Parent) == Players.LocalPlayer or Players:GetPlayerFromCharacter(VictimRootPart.Parent) == Players.LocalPlayer then
		Yuki_FOV.Tween(50, {1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
	end
	
	EffectUtility.EmitEffects(FinisherAssets.PunchPause, workspace.Terrain, RootPart.CFrame * CFrame.new(0, 1, -5))
end

function VFX.ScreenFXEnd(RootPart : BasePart)
	if Players:GetPlayerFromCharacter(RootPart.Parent) == Players.LocalPlayer then
		Yuki_FOV.Tween(70, {0.75})
	end
end

function VFX.FinisherPunchResume(RootPart : BasePart, VictimRootPart : BasePart)
	VFX.Uncharge(RootPart.Parent["Right Arm"])
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 150) then return end

	if Players:GetPlayerFromCharacter(RootPart.Parent) == Players.LocalPlayer or Players:GetPlayerFromCharacter(VictimRootPart.Parent) == Players.LocalPlayer then
		Yuki_FOV.Tween(105, {0.3, Enum.EasingStyle.Back})
		
		task.delay(0.75, function()
			if RootPart then
				VFX.ScreenFXEnd(RootPart)
			end
			
			if VictimRootPart then
				VFX.ScreenFXEnd(VictimRootPart)
			end
		end)
	end
	
	if Distance < 25 then
		local Shake = CameraShake(7.5, 75, 0.1, 0, Vector3.one * 0.8)
		
		if Shake then
			task.delay(0.5, function()
				Shake:StartFadeOut(0.5)
			end)
		end
		
		
		ScreenPulse("Vector Punch")
	end
	
	local CF = RootPart.CFrame * CFrame.new(0, 1, -3)
	local Raycast = workspace:Raycast(CF.Position, DownDirection, Utility.VisualParams)

	local Effect = FinisherAssets.PunchResume:Clone()
	Effect.CFrame = CF
	
	if Raycast then
		Effect["ground smth"].Smoke1.Color = ColorSequence.new(Raycast.Instance.Color)
	end
	
	Effect.Parent = workspace.Visuals
	EffectUtility.Emit(Effect)
	
	local RockLineCF = CF * CFrame.new(0, 0, 1.5)
	coroutine.wrap(RockHandler.RockLines)(RockLineCF, {Amount = 5, Size = 1.35, Angle = math.rad(45)})
	coroutine.wrap(RockHandler.RockLines)(RockLineCF, {Amount = 9, Angle = math.rad(35)})
	coroutine.wrap(RockHandler.RockLines)(RockLineCF, {Amount = 16, SizeIndex = 0.15, Angle = math.rad(57.5)})
end

return VFX