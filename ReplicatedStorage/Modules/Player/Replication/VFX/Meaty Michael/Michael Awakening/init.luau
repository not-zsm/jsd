local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CurrentCamera = workspace.CurrentCamera

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local MichaelUtil = require( ReplicatedStorage.Modules.Player.Replication.VFX["Meaty Michael"]["Michael Awakening"].Util )

local AenoirEmit = EffectUtility.AenoirEmit

local Assets = script.Assets;

local function IsInDistance(Point : Vector3, Distance : number)
	local InDistance = false
	
	if LocalPlayer.Character then
		InDistance = (LocalPlayer.Character.PrimaryPart.Position - Point).Magnitude < Distance
	end
	
	return InDistance
end

local VFX = {};

function VFX.Camera(root : BasePart)
	Yuki_FOV.Immune = true
	
	local rig = script.CameraRig:Clone();
	rig:PivotTo(root.CFrame);
	rig.Parent = workspace.Visuals
	
	local new_job = Job.new()
	local fov_target = 70;
	
	local anim = rig.AnimationController.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Ultimate["Meaty Michael"].Camera)
	local camera_run = RunCameraRig(root, rig)
	
	new_job:Task(anim:GetMarkerReachedSignal("FOV"):Connect(function(value)
		fov_target = tonumber(value);
	end))
	
	RunService:BindToRenderStep("MeatyMichaelCutsceneFOV", Enum.RenderPriority.Camera.Value + 1, function(delta: number)
		CurrentCamera.FieldOfView = math.lerp(CurrentCamera.FieldOfView, fov_target, 0.025 * (delta * 60));
	end)
	
	local attribute_job = AttributeListener.new(root, "MeatyMichaelAwakening", function()
		new_job:Destroy()
	end)
	
	anim.Stopped:Once(function()
		new_job:Destroy()
	end)
	
	new_job:Task(function()
		attribute_job:Destroy()
		
		RunService:UnbindFromRenderStep("MeatyMichaelCutsceneFOV")
		camera_run()
		
		rig:Destroy()
		anim:Stop()

		CurrentCamera.FieldOfView = 70
		Yuki_FOV.Immune = false
	end)
	
	anim:Play(0, 1, 1.4)
end

function VFX.StopEffects(Object: Instance): ()
	for _, Particle in Object:GetChildren() do
		if Particle:IsA("ParticleEmitter") then
			Particle.Enabled = false;
		end;
	end;
end;

function VFX.PreSummon(Steak: Steak)
	AenoirEmit(Assets.PreSummon, Steak);
	VFX.FloorSteak(Steak, false);
end

function VFX.Summon(Steak: Steak)
	AenoirEmit(Assets.Summon, Steak);
	AenoirEmit(Assets.SummonBottom, Steak.Bottom);
end

function VFX.Footstep(Steak: Steak)
	AenoirEmit(Assets.Footstep, Steak.Bottom);
end

function VFX.FloorSteak(Steak: Steak, NoLock: boolean)
	if not Steak then return end;

	local Floor = Instance.new("Attachment");
	Floor.Name = "FloorAttachment";
	Floor.Parent = workspace.Terrain;

	local function CastRayToUpdateAttachment()
		local RayResult = workspace:Raycast(Steak.Position + Vector3.yAxis * 40, -Vector3.yAxis * 75, Utility.VisualParams); -- i dont know but the ground

		if RayResult then
			local GroundCoordinate = CFrame.lookAlong(RayResult.Position, RayResult.Normal) + RayResult.Normal * 0.1;
			Floor.CFrame = GroundCoordinate;
		end;
	end

	if not NoLock then
		local Elapsed = 0;

		local Connection; Connection = RunService.PostSimulation:Connect(function(Delta)
			if not Steak.Parent or Elapsed > 1 then
				return Connection:Disconnect();
			end;
			
			Elapsed += Delta;
			
			CastRayToUpdateAttachment()
		end)
	end

	CastRayToUpdateAttachment()

	AenoirEmit(Assets.SummonGround, Floor, function()
		Floor:Destroy();
	end)
end

function VFX.AttackStart(Steak: Steak, RootPart: BasePart, LaserOffset: CFrame)
	if not Steak or not RootPart then return end;

	AenoirEmit(Assets.Attack, Steak.Mouth);
	
	local TargetAttachment = Instance.new("Attachment");
	TargetAttachment.Name = "LaserTargetAttachment";
	TargetAttachment.Parent = workspace.Terrain;
	
	local Connection, Thread;

	local function StopThreads()
		if Connection and Connection.Connected then
			Connection:Disconnect();
		end;

		if Thread and coroutine.status(Thread) == "suspended" then
			task.cancel(Thread);
		end;
	end
	
	Steak:GetAttributeChangedSignal("Stop"):Once(function()
		StopThreads()
		VFX.StopEffects(TargetAttachment)
		
		task.wait(5)
		
		TargetAttachment:Destroy();
	end)
	
	local Elapsed = 0;

	Connection = RunService.PreSimulation:Connect(function(Delta)
		if not TargetAttachment.Parent or not Steak.Parent then
			return StopThreads()
		end;
		
		Elapsed += Delta;
		
		local Coordinate = CFrame.lookAlong(MichaelUtil.GetLaserCoordinateAtTime(RootPart.CFrame * LaserOffset, Elapsed).Position, Vector3.yAxis);
		local Result = workspace:Raycast(Coordinate.Position + Vector3.yAxis * (Steak.Position.Y - Coordinate.Y), Vector3.yAxis * (RootPart.Position.Y - Steak.Position.Y - 10), Utility.VisualParams);

		if Result then
			Coordinate = CFrame.lookAlong(Result.Position, Result.Normal) + Result.Normal * 0.1;
		end

		TargetAttachment.WorldCFrame = Coordinate;
	end)
	
	Thread = task.spawn(function()
		while task.wait(0.1) do
			if IsInDistance(TargetAttachment.Position, 50) then
				CameraShake(8, 40, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.5)
			end
		end
	end)
	
	VFX.MichaelTrailAwakening(Steak, TargetAttachment);
end

function VFX.Swing(RootPart: BasePart)
	if not RootPart then return end;
	
	AenoirEmit(Assets.Music, RootPart);
	AenoirEmit(Assets.Swing, RootPart);

	local TargetAttachment = Instance.new("Attachment");
	TargetAttachment.Name = "TargetAttachment";
	TargetAttachment.CFrame = CFrame.new(0, -3, 0)
	TargetAttachment.Parent = RootPart;

	task.delay(5, TargetAttachment.Destroy, TargetAttachment);

	AenoirEmit(Assets.SwingGround, TargetAttachment)
end

function VFX.GlowingTrails(Steak: Steak, LaserTargetAttachment: Attachment)
	if not Steak then return end;
	if not LaserTargetAttachment then return end;
	
	local Rnd = Random.new()
	local PrismCollapseInfo = TweenInfo.new(9, Enum.EasingStyle.Quint, Enum.EasingDirection.In);
	local PrismInInfo = TweenInfo.new(1.5, Enum.EasingStyle.Back);
	local PrismInGoal = {Value = 1};

	local NumOfCurseTrails = 12;
	local CurseTrailRadius = 22.5;

	for Count = 1, NumOfCurseTrails do
		local OriginCFrame: CFrame = Steak.CFrame;
		local Speed = Rnd:NextNumber(0, 15);
		local Angle = CFrame.lookAlong(Vector3.zero, Rnd:NextUnitVector());

		local PrismTrail = Assets.PrismTrail:Clone();
		PrismTrail.CFrame = OriginCFrame;
		PrismTrail.Parent = workspace.Terrain;

		local NumberTo = Instance.new("NumberValue");
		TweenService:Create(NumberTo, PrismInInfo, PrismInGoal):Play();

		local NumberIn = Instance.new("NumberValue");
		NumberIn.Value = CurseTrailRadius;

		local Elapsed = Rnd:NextNumber(0, math.pi);

		local Connection = RunService.PreSimulation:Connect(function(Delta)
			Elapsed += Delta;

			local ElapseValue = Elapsed * Speed;
			local Goal = CFrame.new(Steak.Position) * Angle * CFrame.new( 
				math.sin(ElapseValue) * NumberIn.Value, 0,
				math.cos(ElapseValue) * NumberIn.Value
			);

			PrismTrail.CFrame = OriginCFrame:Lerp(Goal, NumberTo.Value);
		end)

		do
			local Closing = TweenService:Create(NumberIn, PrismCollapseInfo, PrismInGoal);
			Closing:Play();
			Closing.Completed:Once(function()
				Connection:Disconnect();

				VFX.StopEffects(LaserTargetAttachment)
				task.delay(0.1, VFX.StopEffects, PrismTrail);
				task.wait(PrismTrail.Trail.Lifetime);

				PrismTrail:Destroy();
			end)
		end;
	end
end

function VFX.MichaelTrailAwakening(Steak: Steak, LaserTargetAttachment: Attachment)
	if not Steak then return end;
	if not LaserTargetAttachment then return end;
	
	VFX.GlowingTrails(Steak, LaserTargetAttachment);

	local BeamRight = Assets.LaserBeam:Clone()
	BeamRight.Attachment0 = Steak.RightEye;
	BeamRight.Attachment1 = LaserTargetAttachment;
	
	local BeamLeft = Assets.LaserBeam:Clone()
	BeamLeft.Attachment0 = Steak.LeftEye;
	BeamLeft.Attachment1 = LaserTargetAttachment;
	
	BeamRight.Parent = LaserTargetAttachment;
	BeamLeft.Parent = LaserTargetAttachment;

	task.delay(0.1, AenoirEmit.Emit, Assets.LaserTarget, LaserTargetAttachment);
	
	local SteakConnection: RBXScriptConnection;
	local StopConnection: RBXScriptConnection;
	
	local Sine = 0;
	local Joint = Steak.SteakJoint;
	local C0 = Joint.C0;
	
	local function StopTheSteak()
		if SteakConnection and SteakConnection.Connected then
			SteakConnection:Disconnect();
		end;
		
		if StopConnection and StopConnection.Connected then
			StopConnection:Disconnect();
		end;
		
		BeamRight:Destroy();
		BeamLeft:Destroy();
		VFX.StopEffects(LaserTargetAttachment);
	end
	
	StopConnection = Steak:GetAttributeChangedSignal("Stop"):Once(StopTheSteak)
	
	SteakConnection = RunService.PreAnimation:Connect(function(Delta)
		Sine += Delta;

		if not Joint.Parent then
			return StopTheSteak();
		end

		Joint.C1 = CFrame.lookAlong(Vector3.zero, LaserTargetAttachment.Position - Steak.Position):Inverse() * Joint.Part0.CFrame.Rotation
	end)
end

return VFX;