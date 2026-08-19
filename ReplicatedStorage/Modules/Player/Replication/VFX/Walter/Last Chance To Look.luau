local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer;

local Assets = script.Assets;
local Rnd = Random.new();

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
--local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )
local Ragdoll = require( ReplicatedStorage.MovementReplicator.Lib.Ragdoll )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Velocities = require( ReplicatedStorage.BuildTools.Build.Velocities )
local AenoirEmit = EffectUtility.AenoirEmit

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Flashbang = require( ReplicatedStorage.Modules.Player.Replication.Global.Flashbang )
local ProjectileHandler = require( ReplicatedStorage.Projectiles.ProjectileHandler )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local Maid = require( ReplicatedStorage.Packages.Maid )

local Animations = ReplicatedStorage.Animations.Attacks.Walter[script.Name]

type Wheelchair = typeof(script.Assets.WheelChair);
type Victim = typeof(script.Assets.Victim);

return {
	["Bump"] = function(Wheelchair: Wheelchair, Laugh: boolean)
		AenoirEmit(Assets.Bump, Wheelchair.HumanoidRootPart);
		
		if Laugh then
			AenoirEmit(Assets.BumpLaugh, Wheelchair.HumanoidRootPart);
		end;
	end,
	
	["Dismantle"] = function(Wheelchair: Wheelchair, Character)
		local Victim = Wheelchair:FindFirstChild("Victim") :: Victim?;
		
		if not Victim then return end;
		
		local blood_enabled = Blood.CanShowBlood();
		local rnd = Random.new();
		local wheel_root = Wheelchair.HumanoidRootPart;
		local victim_root = Victim.HumanoidRootPart;
		
		--Wheelchair.HumanoidRootPart.Anchored = false;
		victim_root.WheelchairBound.Enabled = false;
		
		local ExplosionWheelchair = Wheelchair:Clone();
		
		for _, Part in Wheelchair:GetDescendants() do
			if Part:IsDescendantOf(Victim) then continue; end;
			
			if ( Part:IsA("BasePart") ) then
				Part.Transparency = 1;
				
			elseif Part:IsA("Sound") then
				Part:Destroy();
			end;
		end;
		
		for _, Part in ExplosionWheelchair:GetDescendants() do
			if ( Part:IsA("BasePart") )then
				--Part.Transparency = 1;
				Part.Anchored = false;
				Part.CanCollide = true;
				
				Part.AssemblyLinearVelocity = (rnd:NextUnitVector() + Vector3.yAxis * 1.5).Unit * 100;
				Part.AssemblyAngularVelocity = rnd:NextUnitVector() * 30;
				
				Velocities.gravity(Part, 1, 2);
				
			elseif Part:IsA("Motor") or Part:IsA("JointInstance") or Part:IsA("Constraint") or Part:IsA("Sound") then
				Part:Destroy();
			end;
		end;

		AenoirEmit(Assets.Explode, wheel_root);
		
		if blood_enabled then
			AenoirEmit(Assets.Slice, victim_root);
		else
			for _, Part in Victim:GetDescendants() do
				if Part:IsA("BasePart") or Part:IsA("Decal") then
					Part.Transparency = 1;
				end;
			end;
		end;
		
		task.defer(RockHandler.Crater, wheel_root.Position + Vector3.yAxis * 10, -Vector3.yAxis * 25, {
			Amount = 20,
			Distance = {Min = 12, Max = 20},
			LookAt = {Min = -5, Max = 15},
			Timing = {
				In = {Min = 0.075, Max = 0.2},
				Idle = {Min = 4.7, Max = 5.1},
				Out = {Min = 1.6, Max = 2.2},
			},
			Exposure = {Min = 1.35, Max = 1.65},
			BaseZ = 1.5,
			SizeMultiplier = 2.75,
		})
	
		if Player:DistanceFromCharacter(wheel_root.Position) < 250 then
			local InInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out);
			local OutInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In);

			if Player:DistanceFromCharacter(wheel_root.Position) < 125 then
				CameraShake(7.5, 20, 0.01, 0.45, Vector3.one * 0.1, Vector3.one * 0.65)
				
				local Correction = Instance.new("ColorCorrectionEffect")
				Correction.Parent = Lighting;

				local CorrectionTween = TweenService:Create(Correction, InInfo, {TintColor = Color3.fromRGB(214, 167, 167);})
				CorrectionTween:Play();

				CorrectionTween.Completed:Once(function()
					local Tween = TweenService:Create(Correction, OutInfo, {TintColor = Color3.fromRGB(255, 255, 255);})
					Tween:Play()
					Tween.Completed:Wait();

					Correction:Destroy();
				end);
			end;
			
			if blood_enabled then
				local Highlight = Instance.new("Highlight");
				Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop;
				Highlight.OutlineTransparency = 1;
				Highlight.FillTransparency = 1;
				Highlight.FillColor = Color3.fromRGB(128, 0, 0);
				Highlight.Parent = Victim;

				local HighlightTween = TweenService:Create(Highlight, InInfo, {FillTransparency = 0.5})
				HighlightTween:Play()

				HighlightTween.Completed:Once(function()
					task.wait(0.25);

					local Tween = TweenService:Create(Highlight, OutInfo, {FillTransparency = 1})
					Tween:Play()
					Tween.Completed:Wait();

					Highlight:Destroy();
				end);
			end;
		end;
	
		ExplosionWheelchair.Parent = workspace.Visuals;
		
		Wheelchair.Destroying:Once(function()
			ExplosionWheelchair:Destroy();
		end);
		
		local victim_ragdoll = Ragdoll.new(Victim);
		victim_ragdoll:set_enabled(true);
		
		local direction = (rnd:NextUnitVector() + Vector3.yAxis * 1.5).Unit * 50;
		local linear_velocity = Velocities.simple(victim_root, direction, 0.25);
		
		victim_root.AssemblyLinearVelocity = direction;
		victim_root.AssemblyAngularVelocity = rnd:NextUnitVector() * 150;
		
		task.delay(0.1, function()
			for _, joint in victim_ragdoll:get_ball_sockets() do
				if math.random() < 0.2 then
					joint.Enabled = false;
				end;
			end;
		end)
	end,

	["Wheelchair"] = function(Wheelchair: Wheelchair, Character, Friend)
		if not Character then return end;

		local Animation = AenoirUtil.WaitForAnimation(Character.Humanoid.Animator, Animations.Windup.AnimationId)

		if Animation then
			local ThisPlayer = Players:GetPlayerFromCharacter(Character);
			local RootPart = Character.HumanoidRootPart;
			local WheelRoot = Wheelchair.HumanoidRootPart;
			
			local TempMaid = Maid.new();
			
			local Victim = Assets.Victim:Clone();
			Victim.HumanoidRootPart.WheelchairBound.Part0 = Wheelchair.HumanoidRootPart;
			Victim.Archivable = false;
			Victim.Parent = Wheelchair;
			
			if Friend then
				task.spawn(function()
					local Success, Description = pcall(Players.GetHumanoidDescriptionFromUserId, Players, tonumber(Friend.Id))

					if Success and Description and Victim:IsDescendantOf(workspace) then
						Victim.Humanoid:ApplyDescription(Description);
					end;
				end);
			end;
			
			local Tween = TweenService:Create(Victim.HumanoidRootPart.WheelchairBound, TweenInfo.new(0, Enum.EasingStyle.Cubic), {C0 = CFrame.new(0.2, 0.65, 5.75);})
			Tween:Play();

			local Tween = TweenService:Create(WheelRoot.RootJoint, TweenInfo.new(0, Enum.EasingStyle.Cubic), {C0 = CFrame.new(1.5, 0.55, 5.9);})
			Tween:Play();
			
			local VictimAnimation = Victim.Humanoid.Animator:LoadAnimation(Animations.WindupVictim);
			VictimAnimation.Looped = false;
			VictimAnimation:Play(0, 1, Animation.Speed * 1);
			VictimAnimation.TimePosition = Animation.TimePosition;
			
			local WheelchairAnimation = Wheelchair.AnimationController.Animator:LoadAnimation(Animations.WindupWheelchair);
			WheelchairAnimation.Looped = false;
			WheelchairAnimation:Play(0, 1, Animation.Speed * 1);
			WheelchairAnimation.TimePosition = Animation.TimePosition;
			
			local TargetCFrame = WheelRoot.CFrame;
			local TargetVelocity = Vector3.zAxis;
			local Pushed = false;
			
			WheelRoot.Anchored = true;
			
			local Wheels: {[Motor6D]: number} = {};
			local DistanceTravel = 0;
			
			for _, Wheel in Wheelchair:GetChildren() do
				if Wheel ~= Wheelchair.Wheelsandupper and string.sub(Wheel.Name, 1, 5) == "Wheel" then
					Wheels[Wheel.Joint] = 1 / Wheel.Size.X;
				end;
			end;
			
			local ConnectionMaid = Maid.new();
			local LastMeasure: Vector3;
			local CurrentSpeed = 0;
			
			task.delay(0.1, function()
				ConnectionMaid:add(RunService.PreSimulation:Connect(function(dt)
					if not LastMeasure then
						LastMeasure = WheelRoot.Position;
					end;
					
					CurrentSpeed = math.lerp(CurrentSpeed, (LastMeasure - WheelRoot.Position).Magnitude, 1 * dt);
					LastMeasure = WheelRoot.Position;
					
					DistanceTravel += CurrentSpeed;
					
					for WheelJoint, Radius in Wheels do
						WheelJoint.Transform = CFrame.Angles(-DistanceTravel * Radius * 0.5, 0, 0)
					end;
				end));
			end);
			
			ConnectionMaid:add(RunService.PreRender:Connect(function(dt)
				if Pushed then
					local Distance = (WheelRoot.Position - TargetCFrame.Position).Magnitude;

					-- Too far from server position: stop prediction and interpolate to target cframe
					if Distance > 8 then
						WheelRoot.CFrame = WheelRoot.CFrame:Lerp(TargetCFrame, 8 * dt);
					else
						WheelRoot.CFrame = WheelRoot.CFrame.Rotation:Lerp(TargetCFrame.Rotation, 8 * dt) + WheelRoot.Position:Lerp(TargetCFrame.Position, math.map(Distance, 0, 8, 1, 3) * dt) + TargetVelocity * Vector3.new(1,0,1) * dt;
					end;

					-- Prop up onto floor because the prediction will skew the wheelchair into the floor :(
					local FloorCast = workspace:Raycast(WheelRoot.Position, -Vector3.yAxis * 4, Utility.VisualParams);

					if FloorCast then
						WheelRoot.CFrame = WheelRoot.CFrame:Lerp(WheelRoot.CFrame.Rotation + FloorCast.Position + Vector3.yAxis * (Wheelchair.Hitbox.Size.Y * 0.5 + 0.2), 8 * dt);
					end;
				else
					WheelRoot.CFrame = Character.HumanoidRootPart.CFrame * CFrame.new(-0.25, -0.6, -6.25);
				end;
			end))
			
			Wheelchair.Replicator.OnClientEvent:Connect(function(coordinate: CFrame, velocity: Vector3)
				TargetCFrame, TargetVelocity = coordinate, velocity;
			end);
			
			TempMaid:add(Animation:GetMarkerReachedSignal("Push"):Once(function()
				--local Tween = TweenService:Create(Victim.HumanoidRootPart.WheelchairBound, TweenInfo.new(1.25, Enum.EasingStyle.Cubic), {C0 = CFrame.new(0.2, 0.45, 5.75);})
				--Tween:Play();
				
				--local Tween = TweenService:Create(WheelRoot.RootJoint, TweenInfo.new(1.25, Enum.EasingStyle.Cubic), {C0 = CFrame.new(1.5, -0.35, 6);})
				--Tween:Play();
				
				--WheelRoot.CFrame = WheelRoot.CFrame:Lerp(TargetCFrame, 0.33);
				Pushed = true;
				AenoirEmit(Assets.Click, Wheelchair.HumanoidRootPart);
			end))
			
			VictimAnimation.Stopped:Once(function()
				VictimAnimation:Play(0, 1, 0);
				VictimAnimation.TimePosition = VictimAnimation.Length - 0.001;
			end);
			
			WheelchairAnimation.Stopped:Once(function()
				WheelchairAnimation:Play(0, 1, 0);
				WheelchairAnimation.TimePosition = WheelchairAnimation.Length - 0.001;
			end)
			
			Wheelchair.Destroying:Once(function()
				Victim:Destroy();
				ConnectionMaid:destroy();
			end)
			
			TempMaid:add(Animation.Stopped:Once(function()
				TempMaid:destroy();
			end))
		end
	end,
};