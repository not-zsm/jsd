local VFX = {};

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Rnd = Random.new();
local Assets = script.Assets

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AenoirEmit = EffectUtility.AenoirEmit

local function TweenModelTransparency(Decals, Info, Value)
	local Goal = {Transparency = Value};
	
	for _, Part in Decals do
		TweenService:Create(Part, Info, Goal):Play();
	end;
end

local function GetTimeDistance(Origin: CFrame, Target: CFrame): number
	return (Target.Position - Origin.Position).Magnitude / 500;
end

function VFX.Charge(RootPart: BasePart)
	AenoirEmit(Assets.Charge, RootPart);
end

function VFX.Charmed(RootPart: BasePart)
	AenoirEmit(Assets.Charmed, RootPart);
end

function VFX.Swing(RootPart: BasePart)
	AenoirEmit(Assets.Swing, RootPart);
	VFX.LoveTrails(RootPart.CFrame, RootPart.CFrame * CFrame.new(0, 0, -4), 6)
end

function VFX.Attack(Coordinate: CFrame)
	local EffectAttachment = Instance.new("Attachment")
	EffectAttachment.Name = "CupidAttachment";
	EffectAttachment.CFrame = Coordinate;
	EffectAttachment.Parent = workspace.Terrain;
	
	if LocalPlayer:DistanceFromCharacter(Coordinate.Position) <= 30 then
		CameraShake(2.5, 20, 0.01, 0.5, Vector3.one * 0.8, Vector3.one * 0.25)
		Vignette(Color3.fromRGB(255, 164, 226), 0.5, 0.2)
	end

	AenoirEmit(Assets.Cupid, EffectAttachment, function()
		EffectAttachment:Destroy();
	end)
end

function VFX.ArrowShoot(Origin: CFrame, Target: CFrame)
	local PrismTrail = Assets.ArrowTrail:Clone();
	PrismTrail.CFrame = Origin;
	PrismTrail.Parent = workspace.Terrain;
	
	local HitRay = workspace:Raycast(Origin.Position, (Target.Position - Origin.Position).Unit * 1000);
	local TargetHit = CFrame.lookAlong(Target.Position, Vector3.yAxis);
	
	if HitRay then
		Target = Target.Rotation + HitRay.Position;
		TargetHit = CFrame.lookAlong(HitRay.Position, HitRay.Normal)
	end;
	
	local Tween = TweenService:Create(PrismTrail, TweenInfo.new(GetTimeDistance(Target, Origin), Enum.EasingStyle.Linear), {
		CFrame = Target;
	})
	Tween:Play();
	
	Tween.Completed:Once(function()
		AenoirUtil.StopEffects(PrismTrail);
		
		PrismTrail.CFrame = TargetHit;
		AenoirEmit(Assets.BowHit, PrismTrail)
		
		if LocalPlayer:DistanceFromCharacter(Target.Position) <= 25 then
			CameraShake(2.25, 20, 0.01, 0.35, Vector3.one * 0.8, Vector3.one * 0.25)
			Vignette(Color3.fromRGB(255, 164, 226), 0.5, 0.25)
		end
		
		task.wait(5)
		PrismTrail:Destroy();
	end)
end

function VFX.CupidShoot(Character: Model, Coordinate: CFrame, LookAt: CFrame)
	local IsArchivable = Character.Archivable;
	Character.Archivable = true;
	
	local CloneCharacter = Character:Clone();
	CloneCharacter.Archivable = false;
	Character.Archivable = IsArchivable;
	
	local Direction = LookAt.Position - Coordinate.Position;
	
	local Humanoid = CloneCharacter.Humanoid;
	local RootAttachment = CloneCharacter.HumanoidRootPart.RootAttachment;
	local Parts, DecalParts = AenoirUtil.CleanAfterimage(CloneCharacter, 1);
	
	local Attachment = Instance.new("Attachment");
	Attachment.CFrame = Coordinate;
	Attachment.Parent = workspace.Terrain;
	
	local Alignment = Assets.CupidPosition:Clone();
	Alignment.Position = Coordinate.Position - Direction.Unit * 3
	Alignment.Attachment0 = RootAttachment;
	Alignment.Parent = RootAttachment;

	local Orientation = Assets.CupidOrientation:Clone();
	Orientation.CFrame = CFrame.lookAlong(Vector3.zero, Direction)
	Orientation.Attachment0 = RootAttachment;
	Orientation.Parent = RootAttachment;
	
	CloneCharacter:PivotTo(Coordinate + Direction.Unit * 10);
	CloneCharacter.Parent = workspace.Visuals;

	local Animation: AnimationTrack = Humanoid.Animator:LoadAnimation(Assets.CupidBow)
	Animation:Play(0.25, 1, 0.5);
	
	local function DestroyAll()
		Attachment:Destroy();
		Alignment:Destroy()
		Orientation:Destroy();
		CloneCharacter:Destroy();
	end
	
	Animation.Stopped:Once(function()
		task.delay(2, DestroyAll);
	end)
	
	TweenModelTransparency(DecalParts, TweenInfo.new(0.5), 0);
	
	Animation:GetMarkerReachedSignal("Charge"):Once(function()
		AenoirEmit(Assets.BowCharge, CloneCharacter["Right Arm"].RightGripAttachment)
		VFX.LoveTrails(Coordinate, Coordinate * CFrame.new(0, 0, -4), 3)
		Animation:AdjustSpeed(0.7)
	end)
	
	Animation:GetMarkerReachedSignal("Shoot"):Once(function()
		AenoirEmit(Assets.BowShoot, CloneCharacter["Right Arm"].RightGripAttachment)
		VFX.ArrowShoot(Coordinate, LookAt)
		task.wait(0.25)
		Animation:AdjustSpeed(0.1)
		TweenModelTransparency(DecalParts, TweenInfo.new(1), 1);
	end)
end

function VFX.LoveTrails(Origin: CFrame, Target: CFrame, NumOfTrails: number)
	local PrismCollapseInfo = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.In);
	local PrismInInfo = TweenInfo.new(2, Enum.EasingStyle.Sine);
	local PrismInGoal = {Value = 1};
	local TrailsRadius = 102;

	for Count = 1, NumOfTrails do
		local Speed = Rnd:NextNumber(4, 12);
		local Angle = CFrame.lookAlong(Vector3.zero, Rnd:NextUnitVector());

		local PrismTrail = Assets.PrismTrail:Clone();
		PrismTrail.CFrame = Origin;
		PrismTrail.Parent = workspace.Terrain;

		local NumberTo = Instance.new("NumberValue");
		TweenService:Create(NumberTo, PrismInInfo, PrismInGoal):Play();

		local NumberIn = Instance.new("NumberValue");
		NumberIn.Value = TrailsRadius;
		
		local Elapsed = Rnd:NextNumber(0, math.pi);

		local Connection = RunService.PreSimulation:Connect(function(Delta)
			Elapsed += Delta;

			local ElapseValue = Elapsed * Speed;
			local Goal = Target * Angle * CFrame.new( 
				math.sin(ElapseValue) * NumberIn.Value, 0,
				math.cos(ElapseValue) * NumberIn.Value
			);

			PrismTrail.CFrame = Origin:Lerp(Goal, NumberTo.Value);
		end)

		local Closing = TweenService:Create(NumberIn, PrismCollapseInfo, PrismInGoal);
		Closing:Play();
		Closing.Completed:Once(function()
			Connection:Disconnect();
			AenoirUtil.StopEffects(PrismTrail)
			task.wait(3);
			PrismTrail:Destroy();
		end)
	end
end

return VFX;