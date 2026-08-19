local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )

--local SharmMeshVFX = require( ReplicatedStorage.Modules.Player.Replication.Global.SharmMeshVFX )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local VFX = {}

local KickFinisherAssets = script.KickFinisher

function VFX.AimToTarget(AttackerRootPart : BasePart, VictimRootPart : BasePart) -- fires to attacker
	local Y = AttackerRootPart.Position.Y
	local Lookat = CFrame.lookAt(AttackerRootPart.Position * Vector3.new(1, 0, 1), VictimRootPart.Position * Vector3.new(1, 0, 1)) * CFrame.new(0, Y, 0)

	local Gyro = Instance.new("BodyGyro")
	Gyro.MaxTorque = Vector3.new(0, 1, 0) * 400000
	Gyro.D = 100
	Gyro.P = 5000
	Gyro.CFrame = Lookat
	Gyro.Parent = AttackerRootPart

	task.delay(0.5, Gyro.Destroy, Gyro)
end

function VFX.Chosen(VictimRootPart : BasePart) -- fires to both players client
	Yuki_FOV.Tween(60, {0.15})
	ScreenPulse("Blue Choose")
	
	local Highlight = Instance.new("Highlight")
	Highlight.FillTransparency = 1
	Highlight.OutlineTransparency = 1
	Highlight.FillColor = Color3.fromRGB(20, 102, 255)
	Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	Highlight.Parent = VictimRootPart.Parent

	TweenService:Create(Highlight, TweenInfo.new(0.15),
		{FillTransparency = 0.35}
	):Play()

	task.delay(0.75, function()
		Yuki_FOV.Tween(70, {0.4})

		TweenService:Create(Highlight, TweenInfo.new(0.75),
			{FillTransparency = 1}
		):Play()

		task.delay(0.75, Highlight.Destroy, Highlight)
	end)
end

function VFX.Indicator(VictimTorso : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.VictimIndicator, VictimTorso)
end

function VFX.Pull(AttackerRootPart : BasePart, VictimRootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(AttackerRootPart.Position)

	if (Distance < 25) then
		CameraShake(2, 15, 0.1, 0.25, Vector3.one * 0.8)
	end

	if (Distance < 75) then
		EffectUtility.CloneAndEmit(script.Assets.Pull, AttackerRootPart)
		
		local Lookat = CFrame.lookAt(VictimRootPart.Position, AttackerRootPart.Position)
		
		local Effect = script.VictimPull:Clone()
		Effect.CFrame = Lookat * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0)
		Effect.Parent = workspace.Visuals
		EffectUtility.Emit(Effect)
	end
end

function VFX.Charge(Arm : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Arm.Position)
	
	if (Distance < 75) then
		--EffectUtility.EmitEffects(script.PullSFX, Arm)
		EffectUtility.CloneAndEmit(script.Assets.Hand, Arm)
	end
end

function VFX.Kick(Leg : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Leg.Position)

	if (Distance < 75) then
		local Trail = EffectUtility.WeldArmTrail(Leg)
		task.delay(1.35, Trail.Destroy, Trail)
		
		EffectUtility.EmitEffects(script.KickSFX, workspace.Terrain, CFrame.new(Leg.Position))
	end
end

function VFX.KickHit(AttackerRootPart : BasePart, VictimRootPart : BasePart)
	local Model : Model = VictimRootPart.Parent
	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimRootPart.Position)
	
	if (Distance < 10) then
		CameraShake(1.5, 15, 0.05, 0.25)
	end

	--SharmMeshVFX.Create(SharmMeshVFX.DefaultStorage.HitWind.MeshHit1, AttackerRootPart.CFrame, 4)
	--SharmMeshVFX.Create(SharmMeshVFX.DefaultStorage.HitWind.MeshHit2, AttackerRootPart.CFrame, 4)

	if (Distance < 75) then
		Blood.BloodRays("SpitOut", VictimRootPart.Parent.Head.MouthAttachment)
		EffectUtility.EmitEffects(script.KickHit, workspace.Terrain, CFrame.new(VictimRootPart.Position))
	end
end


function VFX.KickFinisher(AttackerRootPart : BasePart, RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	if (Distance < 10) then
		CameraShake(1.5, 15, 0.05, 0.2)
	end
	
	if Distance < 100 then
		EffectUtility.EmitEffects(KickFinisherAssets.Start, RootPart)
		
		Blood.BloodRays("SpitOut", RootPart.Parent.Head.MouthAttachment)
		
		--SharmMeshVFX.Create(SharmMeshVFX.DefaultStorage.HitWind.MeshHit1, AttackerRootPart.CFrame, 4)
		--SharmMeshVFX.Create(SharmMeshVFX.DefaultStorage.HitWind.MeshHit2, AttackerRootPart.CFrame, 4)
	end
end

function VFX.KickFinisherPullWindup1(AttackerRootPart : BasePart, RootPart : BasePart)
	if AttackerRootPart == nil or AttackerRootPart.Parent == nil then return end
	if RootPart == nil or RootPart.Parent == nil then return end
	
	local AttackerModel = AttackerRootPart.Parent
	local VictimModel = RootPart.Parent
	
	local Head : BasePart = VictimModel.Head
	local RightArm : BasePart = AttackerModel["Right Arm"]
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if Player == Players:GetPlayerFromCharacter(AttackerModel) or Player == Players:GetPlayerFromCharacter(VictimModel) then
		Yuki_FOV.Tween(50, {2})
	end
	
	if Distance < 25 then
		ScreenPulse("Soft Blue", true)
	end
	
	if Distance < 100 then
		local HeadEffect = KickFinisherAssets.Assets.HeadPull:Clone()
		HeadEffect.Parent = Head
		
		local HandEffect = KickFinisherAssets.Assets.HandPull1:Clone()
		HandEffect.Parent = RightArm

		EffectUtility.Toggle(HeadEffect, true)
		EffectUtility.Toggle(HandEffect, true)
		
		task.wait(0.6)
		
		EffectUtility.Toggle(HeadEffect, false)
		EffectUtility.Toggle(HandEffect, false)
		
		task.delay(2, HeadEffect.Destroy, HandEffect)
		task.delay(2, HandEffect.Destroy, HandEffect)
	end
end

function VFX.KickFinisherKickPause1(AttackerRootPart : BasePart, RootPart : BasePart)
	if AttackerRootPart == nil or AttackerRootPart.Parent == nil then return end
	if RootPart == nil or RootPart.Parent == nil then return end
	
	local AttackerModel = AttackerRootPart.Parent
	local VictimModel = RootPart.Parent

	if Player == Players:GetPlayerFromCharacter(AttackerModel) or Player == Players:GetPlayerFromCharacter(VictimModel) then
		Yuki_FOV.Tween(90, {0.1})
	end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	if (Distance < 10) then
		CameraShake(2, 15, 0.1, 0.25, Vector3.one * 0.8)
	end

	--if Distance < 100 then
	--	SharmMeshVFX.Create(SharmMeshVFX.DefaultStorage.HitWind.MeshHit1, AttackerRootPart.CFrame * CFrame.Angles(math.pi / 10, 0, 0), 6)
	--end
end

function VFX.KickFinisherKickResume1(AttackerRootPart : BasePart, RootPart : BasePart)
	if AttackerRootPart == nil or AttackerRootPart.Parent == nil then return end
	if RootPart == nil or RootPart.Parent == nil then return end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	local AttackerModel = AttackerRootPart.Parent
	local VictimModel = RootPart.Parent

	if Player == Players:GetPlayerFromCharacter(AttackerModel) or Player == Players:GetPlayerFromCharacter(VictimModel) then
		Yuki_FOV.Tween(140, {0.1, Enum.EasingStyle.Back})

		task.delay(0.1, function()
			Yuki_FOV.Tween(70, {0.5})
		end)
	end
	
	if (Distance < 10) then
		CameraShake(2, 15, 0.1, 0.5, Vector3.one * 0.8)
	end

	if Distance < 100 then
		Blood.BloodRays("SpitOut", RootPart.Parent.Head.MouthAttachment)

		EffectUtility.EmitEffects(KickFinisherAssets.Kick1, RootPart)
		--SharmMeshVFX.Create(SharmMeshVFX.DefaultStorage.HitWind.MeshHit2, AttackerRootPart.CFrame * CFrame.Angles(math.pi / 10, 0, 0), 6)
	end
	
end

function VFX.KickFinisherPullWindup2(AttackerRootPart : BasePart, RootPart : BasePart)
	if AttackerRootPart == nil or AttackerRootPart.Parent == nil then return end
	if RootPart == nil or RootPart.Parent == nil then return end
	
	local AttackerModel = AttackerRootPart.Parent
	local VictimModel = RootPart.Parent
	
	local Torso : BasePart = VictimModel.Head
	local RightArm : BasePart = AttackerModel["Right Arm"]

	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if Player == Players:GetPlayerFromCharacter(AttackerModel) or Player == Players:GetPlayerFromCharacter(VictimModel) then
		Yuki_FOV.Tween(50, {2})
		
		task.delay(1, function()
			Yuki_FOV.Tween(70, {0.5})
		end)
	end

	if Distance < 25 then
		ScreenPulse("Soft Blue")
	end
	
	if Distance < 100 then
		local TorsoEffect = KickFinisherAssets.Assets.TorsoPull:Clone()
		TorsoEffect.Parent = Torso

		local HandEffect = KickFinisherAssets.Assets.HandPull1:Clone()
		HandEffect.Parent = RightArm

		EffectUtility.Toggle(TorsoEffect, true)
		EffectUtility.Toggle(HandEffect, true)

		task.wait(0.5)

		EffectUtility.Toggle(TorsoEffect, false)
		EffectUtility.Toggle(HandEffect, false)

		task.delay(2, TorsoEffect.Destroy, TorsoEffect)
		task.delay(2, HandEffect.Destroy, HandEffect)
	end
end

function VFX.KickFinisherKickPause2(AttackerRootPart : BasePart, RootPart : BasePart)
	if AttackerRootPart == nil or AttackerRootPart.Parent == nil then return end
	if RootPart == nil or RootPart.Parent == nil then return end
	
	local AttackerModel = AttackerRootPart.Parent
	local VictimModel = RootPart.Parent
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	if Player == Players:GetPlayerFromCharacter(AttackerModel) or Player == Players:GetPlayerFromCharacter(VictimModel) then
		Yuki_FOV.Tween(90, {0.1})
	end
	
	if (Distance < 10) then
		CameraShake(2, 15, 0.1, 0.25, Vector3.one * 0.8)
	end

	--if Distance < 100 then
	--	SharmMeshVFX.Create(SharmMeshVFX.DefaultStorage.BiggerGroundWind.MeshHit1, RootPart.CFrame * CFrame.new(0, 10, 0) * CFrame.Angles(-(math.pi / 2), 0, 0), 5)
	--end
end

function VFX.KickFinisherKickResume2(AttackerRootPart : BasePart, RootPart : BasePart)
	if AttackerRootPart == nil or AttackerRootPart.Parent == nil then return end
	if RootPart == nil or RootPart.Parent == nil then return end
	
	local AttackerModel = AttackerRootPart.Parent
	local VictimModel = RootPart.Parent
	
	local Head : BasePart = RootPart.Parent.Head
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Head.Position)

	if Player == Players:GetPlayerFromCharacter(AttackerModel) or Player == Players:GetPlayerFromCharacter(VictimModel) then
		Yuki_FOV.Tween(140, {0.1, Enum.EasingStyle.Back})

		task.delay(0.1, function()
			Yuki_FOV.Tween(70, {0.5})
		end)
	end
	
	if (Distance < 10) then
		CameraShake(2, 15, 0.1, 0.25, Vector3.one * 0.8)
	end
	
	if Distance < 100 then
		--SharmMeshVFX.Create(SharmMeshVFX.DefaultStorage.BiggerGroundWind.MeshHit2, RootPart.CFrame * CFrame.new(0, 6, 0) * CFrame.Angles(-(math.pi / 2), 0, 0), 5)
		
		local Direction = Vector3.yAxis * -10
		Blood.BloodRays("SpitOut", Head.MouthAttachment)

		coroutine.wrap(RockHandler.Crater)(Head.Position, Direction, {
			Amount = 5;
			Distance = 2.5;	

			SizeMagnitude = 1.35,
		})

		coroutine.wrap(RockHandler.Crater)(Head.Position, Direction, {
			Amount = 8;
			Distance = 5;	

			SizeMagnitude = 1.35,
		})

		coroutine.wrap(RockHandler.Rockst)(Head.Position, Vector3.new(0, 1, 0), {
			Size = {0.75, 1.5},
			Count = 5,
			Velocity = 15,
		})
		
		local Effect = KickFinisherAssets.Assets.Slam:Clone()
		Effect.WorldCFrame = CFrame.lookAt(Head.Position, AttackerRootPart.CFrame.LookVector) * CFrame.Angles(-math.pi / 2, 0, 0)
		Effect.Parent = workspace.Terrain
		
		local Raycast = workspace:Raycast(Head.Position, Vector3.yAxis * -5, Utility.VisualParams)

		if (Raycast ~= nil) then
			Effect.fxGround.Dust1.Color = ColorSequence.new(Raycast.Instance.Color)
		end
		
		EffectUtility.Emit(Effect, true)

		for _, Item in ipairs(AttackerRootPart.Parent:GetChildren()) do
			if Item:IsA("BasePart") and string.find(Item.Name, "Right") or string.find(Item.Name, "Left") then
				local Trail = EffectUtility.WeldArmTrail(Item)
				task.delay(1.5, Trail.Destroy, Trail)
			end
		end
		
		local HandEffect = KickFinisherAssets.Assets.HandPull2:Clone()
		HandEffect.Parent = AttackerRootPart.Parent["Left Arm"]
		EffectUtility.Toggle(HandEffect, true)
		
		task.delay(2.25, function()
			EffectUtility.Toggle(HandEffect, false)
			task.delay(2, HandEffect.Destroy, HandEffect)
		end)
	end
end


function VFX.KickFinisherPunchFreeze(AttackerRootPart : BasePart, RootPart : BasePart)
	if RootPart == nil or RootPart.Parent == nil then return end

	local Head : BasePart = RootPart.Parent.Head
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Head.Position)

	local ShakeObject = nil
	
	if (Distance < 10) then
		CameraShake(1.5, 15, 0.05, 0.2)
	end

	if Distance < 100 then
		local Effect = KickFinisherAssets.Assets.BlackFlashEnable:Clone()
		Effect.WorldCFrame = RootPart.CFrame
		Effect.Parent = workspace.Terrain
		
		EffectUtility.Emit(Effect, true)
		EffectUtility.Toggle(Effect, true)

		task.wait(0.4)
		
		if ShakeObject ~= nil then
			ShakeObject:StopSustain()
		end
		
		EffectUtility.Toggle(Effect, false)
		task.delay(2, Effect.Destroy, Effect)
	end
end

function VFX.KickFinisherPunchResume(AttackerRootPart : BasePart, RootPart : BasePart)
	if AttackerRootPart == nil or AttackerRootPart.Parent == nil then return end
	if RootPart == nil or RootPart.Parent == nil then return end
	
	local AttackerModel = AttackerRootPart.Parent
	local VictimModel = RootPart.Parent
	
	local Head : BasePart = VictimModel.Head
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Head.Position)

	if Player == Players:GetPlayerFromCharacter(AttackerModel) or Player == Players:GetPlayerFromCharacter(VictimModel) then
		Yuki_FOV.Tween(140, {0.1, Enum.EasingStyle.Back})

		task.delay(0.1, function()
			Yuki_FOV.Tween(70, {0.5})
		end)
	end
	
	if (Distance < 35) then
		CameraShake(2.5, 40, 0.05, 0.5)
		ScreenPulse("Black Flash")
	end

	if Distance < 100 then
		local Effect = KickFinisherAssets.Assets.BlackFlash:Clone()
		Effect.WorldCFrame = AttackerRootPart.CFrame * CFrame.new(0, 0, -3)
		Effect.Parent = workspace.Terrain

		EffectUtility.Emit(Effect)
		
		Blood.BloodRays("BigSpitOut", Head.MouthAttachment)
		
		local CF = AttackerRootPart.CFrame
		
		--SharmMeshVFX.Create(KickFinisherAssets.MeshHits["4"].MeshHit1, CF * CFrame.new(0, 0, -6), 10)
		
		--SharmMeshVFX.Create(KickFinisherAssets.MeshHits["4"].Wind1, CF * CFrame.new(10, 0, 3) * CFrame.Angles(0, math.pi, 0))
		--SharmMeshVFX.Create(KickFinisherAssets.MeshHits["4"].Wind2, CF * CFrame.new(-10, 0, 3) * CFrame.Angles(0, math.pi, 0))
		
		--SharmMeshVFX.Create(SharmMeshVFX.DefaultStorage.BiggerGroundWind.MeshHit1, CF * CFrame.new(0, 0, -3), 3)
		--SharmMeshVFX.Create(SharmMeshVFX.DefaultStorage.BiggerGroundWind.MeshHit2, CF * CFrame.new(0, 0, -6), 6)

		coroutine.wrap(RockHandler.RockLines)(CF, {Amount = 6, Size = 1.5, Angle = math.rad(50)})
		coroutine.wrap(RockHandler.RockLines)(CF, {Amount = 15, Angle = math.rad(25)})
		coroutine.wrap(RockHandler.RockLines)(CF, {Amount = 25, SizeIndex = 0.2, Angle = math.rad(40)})
	end
end

function VFX.FinisherGrab(AttackerRootPart : BasePart, VictimHead : BasePart)
	if (VictimHead == nil or VictimHead.Parent == nil) then return end
	
	local AttackerModel : Model = AttackerRootPart.Parent
	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimHead.Position)

	EffectUtility.EmitEffects(script.Finisher.Grab, VictimHead)
	EffectUtility.EmitEffects(script.Finisher.SFX, AttackerRootPart)

	if (Distance < 10) then
		CameraShake(2, 15, 0.1, 0.25, Vector3.one * 0.8)
	end
	
	if (Distance < 75) then
		local Trail = EffectUtility.WeldArmTrail(AttackerModel["Left Arm"])

		local Hand = script.Assets.FinisherHand:Clone()
		Hand.Name = "Hand"
		Hand.Parent = AttackerModel["Left Arm"]

		task.wait(0.35)
		
		EffectUtility.Toggle(Hand, true)
		
		task.delay(1.5, function()
			EffectUtility.Toggle(Hand, false)
			EffectUtility.Toggle(Trail, false)
			
			task.delay(1, Hand.Destroy, Hand)
			task.delay(1, Trail.Destroy, Trail)
		end)
	end
end

function VFX.FinisherSlam(VictimHead : BasePart)
	if (VictimHead == nil or VictimHead.Parent == nil) then return end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimHead.Position)

	if (Distance < 10) then
		ScreenPulse("Black Flash")
		CameraShake(2, 20, 0.1, 0.5, Vector3.one * 0.8)
	end
	
	local Direction = Vector3.yAxis * -10
	
	coroutine.wrap(RockHandler.Crater)(VictimHead.Position, Direction, {
		Amount = 9;
		Distance = 5;	

		Exposure = {
			Min = 0.2,
			Max = 0.4
		},

		SizeMagnitude = 1.25,
	})

	coroutine.wrap(RockHandler.Crater)(VictimHead.Position, Direction, {
		Amount = 13;
		Distance = 13;	

		Exposure = {
			Min = 0.2,
			Max = 0.4
		},

		SizeMagnitude = 1.45,
	})

	coroutine.wrap(RockHandler.Rockst)(VictimHead.Position, Direction, {
		Size = {0.75, 1.5},
		Count = 12,
		Velocity = 15,
	})
	
	if (Distance < 75) then
		local Raycast = workspace:Raycast(VictimHead.Position + (Vector3.yAxis * 2), Direction, Utility.VisualParams)

		if Raycast then
			EffectUtility.EmitEffects(script.Finisher.Slam, workspace.Terrain, Raycast.Position)
		end
	end
end

return VFX
