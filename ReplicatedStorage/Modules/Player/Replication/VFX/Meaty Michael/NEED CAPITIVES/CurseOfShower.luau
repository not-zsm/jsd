local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Assets = script.Assets;
local Rnd = Random.new();
local ShowerModelCFrame = CFrame.new(0, 5, 12345)
local GroundParams = RaycastParams.new()
GroundParams.FilterDescendantsInstances = {workspace:FindFirstChild("Alive")}
GroundParams.FilterType = Enum.RaycastFilterType.Exclude;

local Emit = require( script.Parent.Emit )
local Blackout = require( script.Parent.Blackout );
local RegionUI = require( script.Parent.RegionUI );

local function StopEffects(Object: Instance): ()
	for _, Particle in Object:GetChildren() do
		if Particle:IsA("ParticleEmitter") then
			Particle.Enabled = false;
		end;
	end;
end;

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
	local RayResult = workspace:Raycast(TargetAttachment.Position, -Vector3.yAxis * 15, GroundParams);
	local GroundCoordinate = TargetAttachment.CFrame - Vector3.yAxis * 4;

	if RayResult then
		GroundCoordinate = CFrame.lookAlong(RayResult.Position, RayResult.Normal) + RayResult.Normal * 0.1;
	end;

	local Floor = Instance.new("Attachment");
	Floor.Name = "FloorAttachment";
	Floor.CFrame = GroundCoordinate;
	Floor.Parent = workspace.Terrain;
	
	Emit(Assets.PrisonMiddleFloor, Floor, function()
		Floor:Destroy();
	end)
end

-- client effects code
local function CurseOfShower(Character: Model, ArmAttachment: Attachment, TargetAttachment: Attachment)
	local RootPart = Character:FindFirstChild("HumanoidRootPart");
	local Arm = Character:FindFirstChild("Right Arm");
	
	local PrismCollapseInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In);
	local PrismInInfo = TweenInfo.new(2, Enum.EasingStyle.Back);
	local PrismInGoal = {Value = 1};
	
	local NumOfCurseTrails = 12;
	local CurseTrailRadius = 12;
	
	Emit(Assets.ArmOrb, ArmAttachment)
	
	do
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
	
	for Count = 1, NumOfCurseTrails do
		local OriginCFrame: CFrame = ArmAttachment.WorldCFrame;
		local Speed = Rnd:NextNumber(4, 12);
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
			local Goal = TargetAttachment.CFrame * Angle * CFrame.new( 
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
				
				task.delay(0.1, StopEffects, PrismTrail);
				task.wait(PrismTrail.Trail.Lifetime);
				
				PrismTrail:Destroy();
			end)
		end;
	end
end

-- server code
local function TpVictimsShowers(PlayerList: {Player})
	-- Diplay this for all victims (put in loop and have remote)

	for _, Player in PlayerList do
		local Character = Player.Character;

		local VictimPrevious = Character:GetPivot();
		
		Blackout:display(); -- client code
		
		task.delay(0.6, function()
			RegionUI:set("The Showers", "im so lost 🗣️🗣️ where am i 🗣️🗣️", 10); -- client coed
			Character:PivotTo( ShowerModelCFrame )

			-- client remotes
			-- enable region gui for the given player
			-----------------------------

			task.delay(15, function()
				Blackout:display(); -- client code
				task.wait(0.6);
				Character:PivotTo(VictimPrevious);
			end)
		end);
	end
end

-- probably server code
return function()
	local Player = Players.LocalPlayer;
	local Character = Player.Character :: Model;
	local Humanoid = Character.Humanoid :: Humanoid;
	local RootPart = Humanoid.RootPart;
	
	local Animation = Humanoid.Animator:LoadAnimation(Assets.NeedCaptives) :: AnimationTrack;
	Animation:Play(0.2, 1, 0.45);
	
	-- attachments convieniant to do on server
	local TargetAttachment = Instance.new("Attachment");
	TargetAttachment.Name = "TargetAttachment";
	
	local ArmAttachment = Instance.new("Attachment");
	ArmAttachment.Name = "ArmAttachment";
	ArmAttachment.CFrame = CFrame.new(-0.75, -1.25, 0.5);
	ArmAttachment.Parent = Character:FindFirstChild("Right Arm");
	
	Animation:GetMarkerReachedSignal("ChargeStart"):Once(function()
		TargetAttachment.CFrame = RootPart.CFrame * CFrame.new(0, 5, -25);
		TargetAttachment.Parent = workspace.Terrain;
		
		Emit(Assets.PrisonStart, Humanoid.RootPart);
		-- remote client vfx
		CurseOfShower(Character, ArmAttachment, TargetAttachment);
	end)
	
	Animation:GetMarkerReachedSignal("Prison"):Once(function()
		Emit(Assets.PrisonMiddle, TargetAttachment);
		-- remote
		FloorPrisonEffect(TargetAttachment)
		
		task.delay(0.5, function()
			TpVictimsShowers({Player});
		end)
	end);
	
	Animation.Stopped:Wait();
	
	StopEffects(TargetAttachment);
	
	task.delay(5, ArmAttachment.Destroy, ArmAttachment);
	task.delay(5, TargetAttachment.Destroy, TargetAttachment);
end