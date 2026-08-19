local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer;

local Assets = script.Assets;
local Rnd = Random.new();

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AenoirEmit = EffectUtility.AenoirEmit

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Flashbang = require( ReplicatedStorage.Modules.Player.Replication.Global.Flashbang )

local VFX = {};

function VFX.MovementTrail(Attachment0: Attachment, Size: number)
	local Attachment1 = AenoirUtil.CreateAttachment(CFrame.new(0, Size, 0), Attachment0);

	local Trail = Assets.MovementTrail:Clone();
	Trail.Attachment0 = Attachment0;
	Trail.Attachment1 = Attachment1;
	Trail.Enabled = true;
	Trail.Parent = Attachment1;
	
	return function()
		Trail.Enabled = false;
		task.wait(Trail.Lifetime);
		Attachment1:Destroy();
	end
end

function VFX.CastBagRay(RootCFrame: CFrame)
	local Origin = RootCFrame * CFrame.new(0, 0, 6)
	local Coordinate = AenoirUtil.CastOnGround(Origin.Position, 20);
	
	return Coordinate
end

function VFX.Blast(Position: Vector3)
	Flashbang.create_flash({ 
		range = 50,
		inner_range = 25,
		distance = Player:DistanceFromCharacter(Position),
		position = Position;
	})
end

function VFX.BagExplosion(Coordinate: CFrame)
	AenoirEmit(Assets.BagExplode, Coordinate);

	if Player:DistanceFromCharacter(Coordinate.Position) <= 45 then
		CameraShake(15, 25, 0.01, 0.6, Vector3.one * 0.8, Vector3.one * 0.2)
	end

	task.defer(RockHandler.Crater, Coordinate.Position + Vector3.yAxis * 10, -Vector3.yAxis * 25, {
		Amount = 15,
		Distance = {Min = 16, Max = 22},
		LookAt = {Min = -2, Max = 10},
		Timing = {
			In = {Min = 0.075, Max = 0.2},
			Idle = {Min = 4.7, Max = 5.1},
			Out = {Min = 1.6, Max = 2.2},
		},
		Exposure = {Min = 1.2, Max = 1.5},
		BaseZ = 1.25,
		SizeMultiplier = 2.25,
	})
end

function VFX.Bag(Character: Utility.Character, AnimationId: number)
	if not Character then return end;
	
	local Animation = AenoirUtil.WaitForAnimation(Character.Humanoid.Animator, AnimationId)
	
	if Animation then
		local RootPart = Character.HumanoidRootPart;
		local RightArm = Character["Right Arm"];
		
		local GripAttachment = AenoirUtil.CreatePsuedoAttachment(RightArm.RightGripAttachment);
		local Bag = Assets.Bag:Clone();
		Bag.BallSocketConstraint.Attachment1 = GripAttachment
		
		Animation.Stopped:Once(function()
			GripAttachment:Destroy();
			
			task.wait(3);
			Bag:Destroy();
		end)
		
		Animation:GetMarkerReachedSignal("Equip"):Once(function()
			Bag:PivotTo( RightArm.CFrame );
			Bag.Parent = workspace.Visuals;
		end)
		
		Animation:GetMarkerReachedSignal("Swing"):Once(function()
			local StopEffect = VFX.MovementTrail(RightArm.RightGripAttachment, 0.25);
			
			task.delay(0.5, StopEffect)
		end)
		
		local ThrowCFrame: CFrame;
		
		Animation:GetMarkerReachedSignal("Throw"):Once(function()
			if Bag and Bag.Parent then
				Bag.BallSocketConstraint.Attachment1 = nil;
				Bag.Bag.CanCollide = true;
				Bag.Handle.AssemblyLinearVelocity = (-RootPart.CFrame.LookVector * 40 + RootPart.CFrame.RightVector * 5) + Vector3.yAxis * -15
			end
		
			ThrowCFrame = RootPart.CFrame;
			AenoirEmit(Assets.BagThrow, Bag.Handle);
		end)
		
		Animation:GetMarkerReachedSignal("Turn"):Once(function()
			AenoirEmit(Assets.Turn, RootPart);
		end)
		
		Animation:GetMarkerReachedSignal("Land"):Once(function()
			if Bag and Bag.Parent then
				Bag.Handle.Anchored = true;
			end
			
			local Land = VFX.CastBagRay(ThrowCFrame)
			local TweenTo = TweenService:Create(Bag.Handle, TweenInfo.new(0.1), {CFrame = Land})
			TweenTo:Play();
			
			local EmitCFrame = Land * CFrame.Angles(math.rad(90), 0, 0)
			
			AenoirEmit(Assets.BagLand, EmitCFrame);
			task.wait(0.2)
			
			VFX.BagExplosion(EmitCFrame);
			Bag:PivotTo(CFrame.new(0, 1e7, 0));
			Bag:Destroy();
		end)
	end
end

return VFX;