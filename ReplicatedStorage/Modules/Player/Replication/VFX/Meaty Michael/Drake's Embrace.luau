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

function VFX.Footstep(Attachment: Attachment)
	local Attachment2 = CreateAttachment(CFrame.new(Attachment.WorldPosition), workspace.Terrain);
	
	if Player:DistanceFromCharacter(Attachment.WorldPosition) <= 25 then
		CameraShake(1, 18.5, 0.01, 0.05, Vector3.one * 0.8)
	end
	
	AenoirEmit(Assets.Footstep, Attachment2, function()
		Attachment2:Destroy();
	end)
end

function VFX.Charmed(RootPart: BasePart)
	AenoirEmit(Assets.Charmed, RootPart);
end

function VFX.RunTrails(Character: Model)
	local Torso = Character.Torso;
	local RightArm = Character["Right Arm"];
	local LeftArm = Character["Left Arm"];
	local RightLeg = Character["Right Leg"];
	local LeftLeg = Character["Left Leg"];

	for _, Attachment0 in {RightArm.RightGripAttachment, LeftArm.LeftGripAttachment, RightLeg.RightFootAttachment, LeftLeg.LeftFootAttachment} do
		local Attachment1 = CreateAttachment(CFrame.new(0, 0.4, 0), Attachment0);

		local Trail = Assets.MovementTrail:Clone();
		Trail.Attachment0 = Attachment0;
		Trail.Attachment1 = Attachment1;
		Trail.Enabled = true;
		Trail.Parent = Attachment1;

		task.delay(2, function()
			Trail.Enabled = false;
			task.wait(Trail.Lifetime);
			Attachment1:Destroy();
		end)
	end;
end

function VFX.StepBack(Character: Model)
	local RootPart = Character.HumanoidRootPart;

	task.delay(0.1, VFX.RunTrails, Character);
	AenoirEmit(Assets.StepBack, RootPart)
	
	if Players:GetPlayerFromCharacter(Character) == Player then
		local Velocity = Instance.new("LinearVelocity");
		Velocity.Attachment0 = RootPart.RootAttachment;
		Velocity.RelativeTo = Enum.ActuatorRelativeTo.Attachment0;
		Velocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis;
		Velocity.MaxAxesForce = Vector3.new(1, 0, 1) * 50_000;
		Velocity.VectorVelocity = Vector3.new(0, 1, 0)
		Velocity.Parent = RootPart;
		
		local Tween = TweenService:Create(Velocity, TweenInfo.new(0.35), {
			VectorVelocity = Vector3.new(0, 1, -40)
		})
		Tween:Play()
		
		task.wait(1.15)
		
		Velocity.MaxAxesForce = Vector3.new(1, 1, 1) * 50_000;
		Velocity.VectorVelocity = Vector3.new(0, 200, -200)

		local Tween = TweenService:Create(Velocity, TweenInfo.new(0.8), {
			VectorVelocity = Vector3.new(0, -200, 0)
		})
		Tween:Play()
		Tween.Completed:Wait()
		Velocity:Destroy();
	end;
end

function VFX.Land(RootPart: BasePart)
	local Coordinate = RootPart.CFrame * CFrame.new(0, 1, 0);
	local Origin, Result = CastOnGround(Coordinate.Position, 20);
	
	local Attachment2 = CreateAttachment(Origin, workspace.Terrain);
	
	if Player:DistanceFromCharacter(Coordinate.Position) <= 30 then
		CameraShake(2.5, 22.5, 0.01, 0.5, Vector3.one * 0.8, Vector3.one * 0.25)
		Vignette(Color3.fromRGB(255, 164, 226), 0.5, 0.25)
	end
	
	AenoirEmit(Assets.Land, Attachment2, function()
		Attachment2:Destroy();
	end)
	
	local Attachment3 = CreateAttachment(Origin + Vector3.new(0, 20, 0), workspace.Terrain);
	
	AenoirEmit(Assets.LandHeart, Attachment3, function()
		Attachment3:Destroy();
	end)
end

function VFX.Jump(RootPart: BasePart, Restricted: boolean)
	local Attachment2 = CreateAttachment(RootPart.CFrame * CFrame.new(0, -2.5, 0), workspace.Terrain);
	
	AenoirEmit(Assets.Jump, Attachment2, function()
		Attachment2:Destroy();
	end)
	
	if not Restricted then
		AenoirEmit(Assets.Jumper, RootPart);
	end;
end

return VFX;