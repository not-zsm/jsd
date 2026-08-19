local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local Assets = script.Assets;
local Rnd = Random.new();

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AenoirEmit = EffectUtility.AenoirEmit

local VFX = {}

local function SteakCar(Steak: typeof(Assets.Steak))
	local Sine = 0;
	
	if not Steak then
		return;
	end;
	
	local EngineLoop = Assets.EngineLoop:Clone();
	EngineLoop.Playing = true;
	EngineLoop.Parent = Steak;
	
	local Connection; Connection = RunService.PreAnimation:Connect(function(Delta)
		if not Steak.Parent then
			EngineLoop:Destroy();
			
			return Connection:Disconnect();
		end;
		
		Sine += Delta;
		Steak.SteakJoint.C0 *= CFrame.new(0, math.sin(Sine * 100) * 0.02, 0)
	end)
end

local function CarBeep(Character)
	local Arm = Character:FindFirstChild("Right Arm");

	local Attachment = Instance.new("Attachment");
	Attachment.CFrame = CFrame.new(-0.125, -1, -0.55);
	Attachment.Parent = Arm;
	
	for Beeps = 1, 2 do
		AenoirEmit(Assets.Beep, Attachment, function()
			Attachment:Destroy();
		end)
		
		task.wait(0.3);
	end
end

function VFX.Start(RootPart : BasePart)
	AenoirEmit(Assets.Start, RootPart)
end

function VFX.BumperHit(RootAttachment: Attachment, Steak: any)
	AenoirEmit(Assets.BumperHit, RootAttachment);
end

function VFX.CarKey(Model : Model)
	AenoirEmit(Assets.Key, Model.HumanoidRootPart);
	CarBeep(Model);
end

function VFX.CarEngine(Steak)
	AenoirEmit(Assets.Engine, Steak);
	SteakCar(Steak);
end

function VFX.Jump(RootPart : BasePart, Steak)
	local Height = 4;
	local BaseVector = Vector3.new(0, -2, -100);
	local ClimbOffset = CFrame.new(0, Height, -10);
	local ClimbSpeed = 15;

	local Align = Instance.new("AlignOrientation")
	Align.Attachment0 = RootPart.RootAttachment;
	Align.RigidityEnabled = true;
	Align.Mode = Enum.OrientationAlignmentMode.OneAttachment;
	Align.CFrame = RootPart.CFrame.Rotation;
	Align.Parent = Steak;

	local Velocity = Instance.new("LinearVelocity");
	Velocity.Attachment0 = RootPart.RootAttachment;
	Velocity.RelativeTo = Enum.ActuatorRelativeTo.Attachment0;
	Velocity.MaxForce = 250_000;
	Velocity.VectorVelocity = BaseVector
	Velocity.Parent = Steak;

	local Connection; Connection = RunService.PostSimulation:Connect(function(Delta)
		if not Velocity.Parent then
			return Connection:Disconnect();
		end;

		Align.CFrame = RootPart.CFrame.Rotation;

		local Result = workspace:Raycast((RootPart.CFrame * ClimbOffset).Position, -Vector3.yAxis * (Height + ClimbOffset.Y), Utility.VisualParams)

		if Result then
			Velocity.VectorVelocity = BaseVector + Vector3.yAxis * ClimbSpeed;
		else
			Velocity.VectorVelocity = BaseVector
		end
	end);
	
	return Velocity, Align;
end

-- probably server code
function aenoir_code()
	local Player = Players.LocalPlayer;
	local Character = Player.Character :: Model;
	local Humanoid = Character.Humanoid :: Humanoid;
	local RootPart = Humanoid.RootPart;
	
	local Steak = Assets.Steak:Clone()
	Steak.SteakJoint.Part0 = Character.Torso;
	Steak.Parent = Character;
	
	local SteakKey = Assets.SteakKey:Clone();
	
	local Animation = Humanoid.Animator:LoadAnimation(Assets.SteakOrder) :: AnimationTrack;
	Animation:Play(0.2, 1, 1);
	
	Animation.Stopped:Once(function()
		Steak:Destroy();
		SteakKey:Destroy();
	end)
	
	AenoirEmit(Assets.Start, Humanoid.RootPart)
	
	Animation:GetMarkerReachedSignal("KeyGrab"):Once(function()
		SteakKey.SteakKeyJoint.Part0 = Character:FindFirstChild("Right Arm");
		SteakKey.Parent = Character;
	end)
	
	Animation:GetMarkerReachedSignal("CarKey"):Once(function()
		AenoirEmit(Assets.Key, Humanoid.RootPart);
		CarBeep(Character);
	end)
	
	Animation:GetMarkerReachedSignal("CarEngine"):Once(function()
		AenoirEmit(Assets.Engine, Steak);
		SteakCar(Steak);
	end)
	
	Animation:GetMarkerReachedSignal("Jump"):Once(function()
		SteakKey:Destroy();

		local Height = 4;
		local BaseVector = Vector3.new(0, -5, -100);
		local ClimbOffset = CFrame.new(0, Height, -10);
		local ClimbSpeed = 25;

		local Velocity = Instance.new("LinearVelocity");
		Velocity.Attachment0 = RootPart.RootAttachment;
		Velocity.RelativeTo = Enum.ActuatorRelativeTo.Attachment0;
		Velocity.MaxForce = 250_000;
		Velocity.VectorVelocity = BaseVector
		Velocity.Parent = Steak;

		local Connection; Connection = RunService.PostSimulation:Connect(function(Delta)
			if not Velocity.Parent then
				return Connection:Disconnect();
			end;

			local Result = workspace:Raycast((RootPart.CFrame * ClimbOffset).Position, -Vector3.yAxis * (Height + ClimbOffset.Y), Utility.VisualParams)

			if Result then
				Velocity.VectorVelocity = BaseVector + Vector3.yAxis * ClimbSpeed;
			else
				Velocity.VectorVelocity = BaseVector
			end
		end)
	end)
	
	Animation.Stopped:Wait();
end

return VFX