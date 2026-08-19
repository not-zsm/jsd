local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer;

local Assets = script.Assets;
local Rnd = Random.new();

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AenoirEmit = EffectUtility.AenoirEmit

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local VFX = {};

local function CreateAttachment(Coordinate: CFrame, Parent: Instance?)
	local Attachment = Instance.new("Attachment");
	Attachment.CFrame = Coordinate;
	Attachment.Parent = Parent;

	return Attachment;
end

local function CastOnGround(Position: Vector3, Distance: number): (CFrame, RaycastResult)
	local Result = workspace:Raycast(Position, -Vector3.yAxis * Distance, Utility.VisualParams);

	if Result then
		return CFrame.lookAlong(Result.Position, Result.Normal) + Result.Normal * 0.1, Result;
	else
		return CFrame.lookAlong(Position, Vector3.yAxis), Result;
	end
end

function VFX.BugoSlam(Coordinate: CFrame)
	local Attachment = CreateAttachment(Coordinate, workspace.Terrain);

	AenoirEmit(Assets.Slam, Attachment, function()
		Attachment:Destroy();
	end)

	task.defer(RockHandler.Crater, Coordinate.Position, -Vector3.yAxis * 50, {
		Amount = 40,
		Distance = {Min = 15, Max = 40},
		LookAt = {Min = 5, Max = 10},
		Timing = {
			In = {Min = 0.075, Max = 0.2},
			Idle = {Min = 4.7, Max = 5.1},
			Out = {Min = 1.6, Max = 2.2},
		},
		Exposure = {Min = 0.5, Max = 2},
		BaseZ = 1.25,
		SizeMultiplier = 3,
	})

	task.defer(RockHandler.Crater, Coordinate.Position, -Vector3.yAxis * 50, {
		Amount = 65,
		Distance = {Min = 45, Max = 65},
		LookAt = {Min = -5, Max = -10},
		Timing = {
			In = {Min = 0.05, Max = 0.35},
			Idle = {Min = 4.7, Max = 5.1},
			Out = {Min = 1.6, Max = 2.2},
		},
		Exposure = {Min = 2, Max = 3},
		BaseZ = 0.75,
		SizeMultiplier = 5,
	})

	task.defer(RockHandler.Rockst, Coordinate.Position, -Vector3.yAxis * 50, {
		Size = {2.25, 4.5},
		Count = 80,
		Velocity = 125,
		SpawnVariance = 35;
	})
end

function VFX.LeftArmTrail(Character: Model, Size: number)
	local Attachment0 = Character["Left Arm"].LeftGripAttachment;
	local Attachment1 = CreateAttachment(CFrame.new(0, Size, 0), Attachment0);

	local Trail = Assets.MovementTrail:Clone();
	Trail.Attachment0 = Attachment0;
	Trail.Attachment1 = Attachment1;
	Trail.Enabled = true;
	Trail.Parent = Attachment1;

	task.delay(0.8, function()
		Trail.Enabled = false;
		task.wait(Trail.Lifetime);
		Attachment1:Destroy();
	end)
end

function VFX.Summoning(Attachment: Attachment)
	local Attachment = CreateAttachment(Attachment.WorldCFrame, workspace.Terrain);
	
	AenoirEmit(Assets.Summoning, Attachment, function()
		Attachment:Destroy();
	end)
end

function VFX.BugoBoss(RootCoordinate: CFrame, Coordinate: CFrame)
	local OriginAttachment = CreateAttachment(RootCoordinate * CFrame.new(5, -2, -12), workspace.Terrain);
	local CharacterAttachment = CreateAttachment(Coordinate + Vector3.new(0, 5, 0) + (RootCoordinate.Rotation * CFrame.new(0, 0, -5)).Position, workspace.Terrain);
	
	task.delay(15, function()
		OriginAttachment:Destroy();
		CharacterAttachment:Destroy();
	end)
	
	local Bugo = Assets.Character:Clone();
	Bugo:PivotTo(RootCoordinate + Vector3.new(0, -100, 0));
	Bugo.Parent = workspace.Visuals;

	AenoirEmit(Assets.Appear, CharacterAttachment)
	VFX.Summoning(CharacterAttachment);
	
	local Animation = Bugo.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks["Meaty Michael"]["Bugo's Last Resort"].Slam);
	
	--local start = tick()
	
	Animation:GetMarkerReachedSignal("Slam"):Once(function()
		task.wait(0.075);
		
		--print(tick() - start)
		
		if Player:DistanceFromCharacter(RootCoordinate.Position) <= 175 then
			CameraShake(15, 100, 0.01, 2, Vector3.one * 0.8, Vector3.one * 0.5)

			local ColorCorrection = Instance.new("ColorCorrectionEffect")
			ColorCorrection.Brightness = 10
			ColorCorrection.Saturation = -0.5
			ColorCorrection.TintColor = Color3.fromRGB(255, 255, 255)

			TweenService:Create(ColorCorrection, TweenInfo.new(0.85), {
				Brightness = 0;
				Saturation = 0
			}):Play()

			task.delay(0.5, ColorCorrection.Destroy, ColorCorrection)
		end
		
		VFX.BugoSlam( RootCoordinate * CFrame.new(-5, 0, -50) );
	end)

	Animation:GetMarkerReachedSignal("Swing"):Once(function()
		AenoirEmit(Assets.Swing, Bugo["Left Arm"].LeftGripAttachment);
		VFX.LeftArmTrail(Bugo, 8);
	end)

	Animation:GetMarkerReachedSignal("Appear"):Once(function()
		Bugo.HumanoidRootPart.CFrame = RootCoordinate * CFrame.new(0, 15, -20)
		
		task.defer(RockHandler.Crater, CharacterAttachment.Position, -Vector3.yAxis * 50, {
			Amount = 15,
			Distance = {Min = 15, Max = 20},
			LookAt = {Min = -8, Max = -4},
			Timing = {
				In = {Min = 1, Max = 1.3},
				Idle = {Min = 4.7, Max = 5.1},
				Out = {Min = 1.6, Max = 2.2},
			},
			Exposure = {Min = 0.3, Max = 0.5},
			BaseZ = 2,
			SizeMultiplier = 2,
		})
		
		if Player:DistanceFromCharacter(RootCoordinate.Position) <= 175 then
			CameraShake(7.5, 12.5, 0.01, 1.35, Vector3.one * 0.8)
		end
	end)

	Animation:GetMarkerReachedSignal("Disappear"):Once(function()
		AenoirEmit(Assets.Disappear, CharacterAttachment)
	end)

	for _, Limb in Bugo:GetChildren() do
		if Limb:IsA("BasePart") then
			Limb.CanCollide = false;
		end;
	end;
	
	Animation:Play(0, 1, 0.75)
	Animation.Stopped:Wait();
	Bugo:Destroy();
end

return VFX;