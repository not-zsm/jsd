local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer;

local Assets = script.Assets
local Animations = ReplicatedStorage.Animations.Attacks.Accelerator["Carnal Revolution"]

local Rnd = Random.new();
local XZ = Vector3.new(1, 0, 1);

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler ) -- i disabled it
-- yea same
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AenoirEmit = EffectUtility.AenoirEmit

local VFX = {};

local function CreateWings(Torso: BasePart)
	local Wings = Assets.Visuals.Wings:Clone();
	
	local Weld = Instance.new("Weld", Wings);
	Weld.C0 = CFrame.new(-0.027, -0.056, 0.049)
	Weld.Part1 = Torso;
	Weld.Part0 = Wings.Torso;

	return Wings;
end

local function CreateDashEffects(Character, IsPlayer)
	local RootPart = Character.HumanoidRootPart;

	local DashVFX = Assets.Visuals.InitialDashVFX:Clone()
	DashVFX.CFrame = RootPart.CFrame;
	DashVFX.Parent = workspace.Visuals;

	AenoirEmit(Assets.Visuals.InitialDashVFX, RootPart.CFrame)

	task.delay(4, DashVFX.Destroy, DashVFX)

	local mesh_origin = RootPart.CFrame * CFrame.Angles(0, math.rad(90), math.rad(90));
	AenoirEmit(Assets.Visuals.StartDashMesh, mesh_origin)

	if IsPlayer then
		local ZoomOut = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
			FieldOfView = 105
		})
		ZoomOut.Completed:Connect(function(playbackState: Enum.PlaybackState) 
			local Reset = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {
				FieldOfView = 70
			})
			Reset:Play()
		end)
		ZoomOut:Play();
	end

	local Dash = Assets.Visuals.DashVFX:Clone()
	Dash:PivotTo(RootPart.CFrame);

	local Weld = Instance.new("Motor6D", Dash);
	Weld.C1 = CFrame.new(0, 3, 0);
	Weld.Part0 = RootPart;
	Weld.Part1 = Dash.PrimaryPart;

	return Dash, Weld;
end

local function CreateUptiltEffects(Character, IsPlayer)
	local RootPart : BasePart = Character.HumanoidRootPart;

	if IsPlayer then
		local ZoomOut = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			FieldOfView = 90
		})
		ZoomOut.Completed:Connect(function(playbackState: Enum.PlaybackState) 
			local Reset = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				FieldOfView = 70
			})
			Reset:Play()
		end)
		ZoomOut:Play();
	end

	AenoirEmit(Assets.Visuals.FlyVFX, RootPart.CFrame)

	local mesh_origin = CFrame.new(RootPart.Position) * CFrame.Angles(math.rad(180), math.rad(90), 0);
	AenoirEmit(Assets.Visuals.FlyDashMesh, mesh_origin)
	AenoirEmit(Assets.Visuals.FlyUpMesh, mesh_origin)

	local Dash = Assets.Visuals.DashUpVFX:Clone()
	Dash:PivotTo(RootPart.CFrame);

	local Weld = Instance.new("Motor6D", Dash);
	Weld.C1 = CFrame.new(0, 3, 0) * CFrame.Angles(math.rad(-90), 0, 0);
	Weld.Part0 = RootPart;
	Weld.Part1 = Dash;
	Dash.Parent = workspace.Visuals;

	task.delay(1, function()
		AenoirUtil.StopEffects(Dash);
		task.delay(2, Dash.Destroy, Dash)
	end);
end

local function CreateImpactFrames()
	local Children = Assets.ImpactLighting:GetChildren();

	for FrameIndex = 1, #Children do
		local ImpactFrame = Assets.ImpactLighting[`Frame{FrameIndex}`]:Clone()
		ImpactFrame.Parent = Lighting

		task.wait(1 / 30);
		ImpactFrame:Destroy()
	end
end

local function CreateImpactEffects(Coordinate, IsPlayer)
	if IsPlayer then
		local ZoomOut = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			FieldOfView = 105
		})
		ZoomOut:Play()
		ZoomOut.Completed:Connect(function(playbackState: Enum.PlaybackState) 
			local Reset = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
				FieldOfView = 70
			})
			Reset:Play()
		end)
	end

	if IsPlayer or Player:DistanceFromCharacter(Coordinate.Position) < 50 then
		CameraShake(4, 30, 0.01, 0.65, Vector3.one * 0.8, Vector3.one * 0.4)
		task.spawn(CreateImpactFrames);
	end;

	AenoirEmit(Assets.Visuals.ImpactVFX, Coordinate);
	AenoirEmit(Assets.Sounds.Impact, Coordinate);

	local mesh_origin = CFrame.new(Coordinate.Position) * CFrame.Angles(0, math.rad(90), 0) + Vector3.yAxis * 10;
	AenoirEmit(Assets.Visuals.ImpactMesh, mesh_origin);

	task.spawn(RockHandler.Crater, Coordinate.Position + Vector3.yAxis * 10, -Vector3.yAxis * 50, {
		Amount = 6,
		Distance = {Min = 12.5, Max = 25},
		LookAt = { Min = 5, Max = 20 },
		Timing = {
			In = {Min = 0.075, Max = 0.2},
			Idle = {Min = 5.7, Max = 6.1},
			Out = {Min = 1.6, Max = 2.2},
		},
		Exposure = { Min = 3.75, Max = 4.5 },
		BaseZ = 2.5,
		SizeMultiplier = 5.75,
	})

	task.spawn(RockHandler.Crater, Coordinate.Position + Vector3.yAxis * 10, -Vector3.yAxis * 50, {
		Amount = 45,
		Distance = {Min = 15, Max = 45},
		LookAt = { Min = -15, Max = 15 },
		Timing = {
			In = {Min = 0.05, Max = 0.35},
			Idle = {Min = 5.3, Max = 6.2},
			Out = {Min = 1.6, Max = 2.2},
		},
		Exposure = { Min = 1.5, Max = 3 },
		BaseZ = 0.9,
		SizeMultiplier = 4,
	})

	task.spawn(RockHandler.Rockst, Coordinate.Position + Vector3.yAxis * 10, -Vector3.yAxis * 50, {
		Size = {1.25, 3.5},
		Count = 30,
		Velocity = 60,
		SpawnVariance = 2;
	})
end

local function CreateUpbackEffects(Character)
	local RootPart = Character.HumanoidRootPart;

	local DownwardsDash = Assets.Visuals.DownwardsDash:Clone()
	DownwardsDash.Name = DownwardsDash.Name..Character.Name
	DownwardsDash.CFrame = RootPart.CFrame

	local DownwardsDashWeld = Instance.new("Motor6D", DownwardsDash);
	DownwardsDashWeld.Part0 = DownwardsDash;
	DownwardsDashWeld.Part1 = RootPart;
	DownwardsDashWeld.C0 = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-90),0,0);
	
	local Dash = Assets.Visuals.DashVFX:Clone()
	Dash:PivotTo(RootPart.CFrame);

	local Weld = Instance.new("Motor6D", Dash);
	Weld.C0 = CFrame.Angles(math.rad(-90), 0, 0);
	Weld.Part0 = RootPart;
	Weld.Part1 = Dash.PrimaryPart;

	Dash.Parent = DownwardsDash;
	DownwardsDash.Parent = workspace.Visuals;
	
	return DownwardsDash;
end

function VFX.Start(Character, Listener : RemoteEvent)
	if not Character then return end;

	local Humanoid = Character.Humanoid;
	local RootPart = Humanoid.RootPart;
	local Animator = Humanoid.Animator;
	local RootAttachment = RootPart.RootAttachment;
	local IsMe = Player.Character == Character;

	local Accelerator = AenoirUtil.WaitForAnimation(Animator, Animations.Windup.AnimationId, 5)
	local Impact = AenoirUtil.WaitForAnimation(Animator, Animations.Impact.AnimationId, 5)
	local LoopDash = AenoirUtil.WaitForAnimation(Animator, Animations.Spin.AnimationId, 5)
	
	if not Accelerator.IsPlaying then
		return
	end
	
	local Cleanup = Job.new();
	local Landed = false;
	
	-- Memory leak safeguard and timeout 😭
	Cleanup:Task(task.delay(30, Cleanup.Destroy, Cleanup));

	Impact.Ended:Once(function()
		Cleanup:Destroy();
	end)
	
	Listener.Destroying:Connect(function()
		Cleanup:Destroy()
	end)
	
	do
		local Use = Assets.Sounds.Use.SFX:Clone();
		Use.Parent = RootPart;
		Use:Play();

		Cleanup:Task(Use);
	end

	local Wings = Cleanup:Task(CreateWings(Character.Torso));
	Wings.Parent = Character;

	Cleanup:Task(Impact:GetMarkerReachedSignal("hidewings"):Once(function() 
		Wings:Destroy()	
	end))

	local DiveEndVelocity = Vector3.new(0, -300, -15);
	local Velocity: LinearVelocity;
	
	local Shake

	if IsMe then
		local _LookAtCamera;
		
		local function LookAtCamera(Value : boolean)
			Humanoid:SetAttribute("LockShiftlockCFrame", Value)
			_LookAtCamera = Value
		end
		
		Cleanup:Task(function()
			Humanoid:SetAttribute("LockShiftlockCFrame", nil)
		end)
		
		-- If you somehow topple over you won't go everywhere
		local SuperRootAttachment = Instance.new("Attachment");
		SuperRootAttachment.Name = "SuperRootAttachment";
		SuperRootAttachment.Parent = RootPart;

		LookAtCamera(true)
		
		local AlignGyro = Assets.AlignOrientation:Clone();
		AlignGyro.Attachment0 = RootAttachment;
		AlignGyro.RigidityEnabled = true
		AlignGyro.Parent = RootPart;

		Cleanup:Task(AlignGyro);
		Cleanup:Task(SuperRootAttachment);

		--Cleanup:BindToRender(tostring(Cleanup), Utility.ShiftlockRenderPriority + 3, function(dt)
		Cleanup:Task(RunService.PreSimulation:Connect(function(dt)
			local Vector = if _LookAtCamera then workspace.CurrentCamera.CFrame.LookVector else RootPart.CFrame.LookVector * XZ;

			if (Vector == Vector and Vector ~= Vector3.zero) then -- nan check
				local LookAlong = CFrame.lookAlong(Vector3.zero, Vector);
				
				if LookAlong.Position == LookAlong.Position then
					SuperRootAttachment.CFrame = RootPart.CFrame.Rotation:Inverse() * LookAlong;
					AlignGyro.CFrame = LookAlong;
				end;
			end;
			
			if AlignGyro.Enabled ~= _LookAtCamera then
				AlignGyro.Enabled = _LookAtCamera;
			end;
		end))

		Velocity = Assets.LinearVelocity:Clone();
		Velocity.Attachment0 = SuperRootAttachment;
		Velocity.RelativeTo = Enum.ActuatorRelativeTo.Attachment0;
		Velocity.VectorVelocity = Vector3.new(0, 0, 0);
		Velocity.Enabled = true;
		Velocity.Parent = RootPart;

		local Set = TweenService:Create(Velocity, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
			VectorVelocity = Vector3.new(0, 0, 30);
		})
		Set:Play();
		Set.Completed:Once(function()
			local Set = TweenService:Create(Velocity, TweenInfo.new(1.5, Enum.EasingStyle.Cubic), {
				VectorVelocity = Vector3.new(0, 0, -50);
			})
			Set:Play();
		end)

		Cleanup:Task(Accelerator:GetMarkerReachedSignal("fly"):Once(function()
			task.spawn(function()
				Shake = CameraShake(1.4, 25, 0.01, 0, Vector3.one * 0.8, Vector3.one * 0.25)
				
				Cleanup:Task(function()
					Shake:StartFadeOut(0.2)
					Shake = nil
				end)
			end)
			
			Velocity.VectorVelocity = Vector3.new(0, 5, -200);

			local Set = TweenService:Create(Velocity, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
				VectorVelocity = Vector3.new(0, 15, -100);
			})
			Set:Play();
		end));

		Cleanup:Task(Accelerator:GetMarkerReachedSignal("up"):Once(function()
			if Shake then
				Shake:StartFadeOut(0.4)
			end
			
			LookAtCamera(false);
			Velocity.VectorVelocity = Vector3.new(0, 60, 0);

			local FadeIn = TweenService:Create(Velocity, TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
				VectorVelocity = Vector3.new(0, 125, -20);
			})
			FadeIn:Play();
			FadeIn.Completed:Wait();

			local FadeOut = TweenService:Create(Velocity, TweenInfo.new(2, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {
				VectorVelocity = Vector3.new(0, 40, 0);
			})
			FadeOut:Play();
		end))

		Cleanup:Task(Accelerator:GetMarkerReachedSignal("upback"):Once(function()
			local Set = TweenService:Create(Velocity, TweenInfo.new(0.3), {
				VectorVelocity = Vector3.new(0, 60, -70);
			})
			Set:Play();

			local ArcMaid = Job.new()
			Cleanup:Task(ArcMaid)
			
			ArcMaid:Task(RunService.PreSimulation:Connect(function(dt)
				Velocity.VectorVelocity -= Vector3.new(0, 350 * dt, 0);

				if Velocity.VectorVelocity.Y < 0 then
					ArcMaid:Destroy();

					local FadeOut = TweenService:Create(Velocity, TweenInfo.new(2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
						VectorVelocity = DiveEndVelocity;
					})
					FadeOut:Play();
				end
			end))
		end))
	end

	local DashModel, DashWeld;

	Cleanup:Task(Accelerator:GetMarkerReachedSignal("fly"):Once(function()
		DashModel, DashWeld = CreateDashEffects(Character, IsMe);
		DashModel.Parent = workspace.Visuals;

		Cleanup:Task(DashModel);
	end))

	Cleanup:Task(Accelerator:GetMarkerReachedSignal("up"):Once(function()
		task.spawn(RockHandler.Crater, RootPart.Position + Vector3.yAxis * 10, -Vector3.yAxis * 50, {
			Amount = 20,
			Distance = {Min = 13, Max = 23},
			LookAt = { Min = 2, Max = 10 },
			Timing = {
				In = {Min = 0.075, Max = 0.2},
				Idle = {Min = 4.7, Max = 6.1},
				Out = {Min = 1.6, Max = 2.2},
			},
			Exposure = { Min = 1, Max = 2 },
			BaseZ = 2,
			SizeMultiplier = 2.5,
		})

		task.delay(0.1, function()
			AenoirUtil.StopEffects(DashModel);
			task.delay(2, DashModel.Destroy, DashModel)
		end)

		local AnimateTween = TweenService:Create(DashWeld, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
			C0 = DashWeld.C0 * CFrame.Angles(math.rad(80), 0, 0)
		})
		AnimateTween:Play()

		CreateUptiltEffects(Character, IsMe);
	end))

	Cleanup:Task(Accelerator:GetMarkerReachedSignal("upback"):Once(function()
		local mesh_origin = RootPart.CFrame * CFrame.Angles(math.rad(-40), math.rad(90), 0);
		AenoirEmit(Assets.Visuals.FlyBoostMesh, mesh_origin);

		task.wait(0.75);

		local Effects = Cleanup:Task(CreateUpbackEffects(Character));
		LoopDash.Stopped:Once(function()
			Effects:Destroy();
		end)
	end))

	Cleanup:Task(Accelerator:GetMarkerReachedSignal("dive"):Once(function()
		LoopDash:Play(0.25);
		local Shake
		
		if IsMe then	
			Shake = CameraShake(2, 30, 0.01, 0, Vector3.one * 0.8, Vector3.one * 0.4)
			
			if Shake then
				Cleanup:Task(function()
					Shake:StartFadeOut(0.2)
					Shake = nil
				end)
			end
			
			local ZoomOut = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
				FieldOfView = 90
			})
			
			ZoomOut:Play()
		end

		local GroundMaid = Job.new()
		Cleanup:Task(GroundMaid)

		do
			local Loop = Assets.Sounds.WingLoop.SFX:Clone();
			Loop.Parent = RootPart;
			Loop:Play();

			GroundMaid:Task(function()
				Loop:Destroy();
			end)
		end;

		GroundMaid:Task(RunService.PostSimulation:Connect(function(dt)
			local Result = workspace:Raycast(RootPart.Position, DiveEndVelocity.Unit * 10, Utility.VisualParams);

			if Result then
				Landed = true;
				
				GroundMaid:Destroy();
				Accelerator:Stop(0);
				LoopDash:Stop(0);
				Impact:Play(0, 1, 1.1);
				
				Cleanup:Task(task.delay(2.25, function()
					Impact:Stop(0.3);
					task.wait(0.3);
					Cleanup:Destroy();
				end))

				if Velocity then
					Velocity:Destroy();
				end

				if IsMe then
					if Shake then
						Shake:StartFadeOut(0.2)
					end
					
					Listener:FireServer();
					RootPart.AssemblyLinearVelocity = -Vector3.yAxis * 25
				end;
			end
		end))
	end))
end

function VFX.Impact(Character, Coordinate)
	CreateImpactEffects(Coordinate, Player.Character == Character);
end

return VFX;