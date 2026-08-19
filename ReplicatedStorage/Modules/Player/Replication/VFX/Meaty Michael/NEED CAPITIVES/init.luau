local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Rnd = Random.new();
local ShowerModelCFrame = CFrame.new(0, 5, 12345)
local Assets = script.Assets

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AenoirEmit = EffectUtility.AenoirEmit

local function Enlarge(Keypoint : (NumberSequenceKeypoint), ScaleFactor: number)
	return Keypoint.Time, Keypoint.Value * ScaleFactor, Keypoint.Envelope * ScaleFactor;
end

local function TransformNumberSequence(Sequence : (NumberSequence), Function, ...)
	local SequenceArray = {}

	for _, Keypoint in ipairs(Sequence.Keypoints) do
		table.insert(SequenceArray, NumberSequenceKeypoint.new(Function(Keypoint, ...)));
	end;

	return NumberSequence.new(SequenceArray);
end

-- client effects remote
local function FloorPrisonEffect(TargetAttachment: Attachment)
	local RayResult = workspace:Raycast(TargetAttachment.Position, -Vector3.yAxis * 15, Utility.VisualParams);
	local GroundCoordinate = TargetAttachment.CFrame - Vector3.yAxis * 4;

	if RayResult then
		GroundCoordinate = CFrame.lookAlong(RayResult.Position, RayResult.Normal) + RayResult.Normal * 0.1;
	end;

	local Floor = Instance.new("Attachment");
	Floor.Name = "FloorAttachment";
	Floor.CFrame = GroundCoordinate;
	Floor.Parent = workspace.Terrain;

	AenoirEmit(Assets.PrisonMiddleFloor, Floor, function()
		Floor:Destroy();
	end)
end

-- client effects code
local function CurseOfShower(ArmAttachment: Attachment, TargetAttachment: Attachment, Settings)
	local PrismCollapseInfo = Settings.CollapseInfo or TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In);
	local PrismInInfo = Settings.PullInfo or TweenInfo.new(2, Enum.EasingStyle.Back);
	local PrismInGoal = {Value = 1};

	local NumOfCurseTrails = Settings.Amount or 12;
	local CurseTrailRadius = Settings.Radius or 15;

	AenoirEmit(Assets.ArmOrb, ArmAttachment)

	if not Settings.NoVoidPull then
		local Pull = Assets.Pull.Pull:Clone();
		Pull.Parent = TargetAttachment;

		task.delay(0.5, function()
			Pull.Enabled = true;
		end)

		local Sequence = Pull.Size;
		local NumberIn = Instance.new("NumberValue");
		NumberIn.Value = 1;

		NumberIn.Changed:Connect(function()
			Pull.Size = TransformNumberSequence(Sequence, Enlarge, NumberIn.Value)
		end)

		TweenService:Create(NumberIn, TweenInfo.new(2.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			Value = 0;
		}):Play();
	end
	
	task.spawn(function()
		for Count = 1, NumOfCurseTrails do
			if LocalPlayer:DistanceFromCharacter(TargetAttachment.Position) <= 50 then
				CameraShake(1, 10, 0.02, 0.15, Vector3.one * 0.8, Vector3.one * 0.15)
				Vignette(Color3.fromRGB(0, 0, 0), 0.75, 0.1)
			end
			
			task.wait(0.1)
		end
	end)

	for Count = 1, NumOfCurseTrails do
		local OriginCFrame: CFrame = ArmAttachment.WorldCFrame;
		local Speed = Rnd:NextNumber(4, 12) * (Settings.Speed or 1);
		local Angle = CFrame.lookAlong(Vector3.zero, Rnd:NextUnitVector());

		local PrismTrail = Assets.PrismTrail:Clone();
		PrismTrail.CFrame = OriginCFrame;
		PrismTrail.Parent = workspace.Terrain;

		local NumberTo = Instance.new("NumberValue");
		TweenService:Create(NumberTo, PrismInInfo, PrismInGoal):Play();

		local NumberIn = Instance.new("NumberValue");
		NumberIn.Value = CurseTrailRadius;

		local Elapsed = Rnd:NextNumber(0, 4 * math.pi);
		local OutValue = Settings.OutValue or 0;
		
		local Connection = RunService.PreSimulation:Connect(function(Delta)
			Elapsed += Delta;

			local ElapseValue = Elapsed * Speed;
			
			local Goal = Angle * CFrame.new(0, 0, OutValue * NumberIn.Value) * CFrame.new( 
				math.sin(ElapseValue) * NumberIn.Value, 0,
				math.cos(ElapseValue) * NumberIn.Value
			);

			PrismTrail.CFrame = OriginCFrame:Lerp(Goal + TargetAttachment.WorldPosition, NumberTo.Value);
		end)

		do
			local Closing = TweenService:Create(NumberIn, PrismCollapseInfo, PrismInGoal);
			Closing:Play();
			Closing.Completed:Once(function()
				Connection:Disconnect();

				task.delay(0.1, VFX.StopEffects, PrismTrail);
				task.wait(PrismTrail.Trail.Lifetime);

				PrismTrail:Destroy();
			end)
		end;
	end
end

function VFX.StopEffects(Object: Instance): ()
	for _, Particle in Object:GetChildren() do
		if Particle:IsA("ParticleEmitter") then
			Particle.Enabled = false;
		end;
	end;
end;

function VFX.ChargeStart(Character : Model, ArmAttachment : Attachment, TargetAttachment : Attachment)
	AenoirEmit(Assets.PrisonStart, Character.Humanoid.RootPart);
	CurseOfShower(ArmAttachment, TargetAttachment, {});
end

function VFX.Prison(TargetAttachment : Attachment)
	AenoirEmit(Assets.PrisonMiddle, TargetAttachment);
	FloorPrisonEffect(TargetAttachment)
	
	if LocalPlayer:DistanceFromCharacter(TargetAttachment.Position) <= 50 then
		CameraShake(2.25, 40, 0.02, 0.6, Vector3.one * 0.8, Vector3.one * 0.3)
		Vignette(Color3.fromRGB(0, 0, 0), 0.35, 0.2)
	end
end;

function VFX.PrisonFinisher(TargetAttachment: Attachment)
	AenoirEmit(Assets.PrisonStartFinisher, TargetAttachment);
	
	local NewAttachment = Instance.new("Attachment");
	NewAttachment.CFrame = CFrame.new(0, -3, 0);
	NewAttachment.Parent = TargetAttachment;
	
	CurseOfShower(TargetAttachment, NewAttachment, {
		Amount = 20;
		Radius = 90;
		CollapseInfo = TweenInfo.new(1.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out);
		PullInfo = TweenInfo.new(1.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out);
		Speed = 1.25;
		OutValue = 1;
	});
	
	task.wait(0.65);
	
	if LocalPlayer:DistanceFromCharacter(TargetAttachment.Position) <= 100 then
		CameraShake(2.25, 40, 0.02, 2, Vector3.one * 0.8, Vector3.one * 0.3)
		Vignette(Color3.fromRGB(0, 0, 0), 0.35, 0.3)
	end
	
	AenoirEmit(Assets.PrisonMiddleFinisher, TargetAttachment);
end

return VFX
