local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer;

local Assets = script.Assets;
local Rnd = Random.new();

local Visuals = workspace.Visuals;
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AenoirEmit = EffectUtility.AenoirEmit

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Flashbang = require( ReplicatedStorage.Modules.Player.Replication.Global.Flashbang )

local VFX = {};

function VFX.Jumpscare(Restricted: boolean)
	local Gui = Assets.ImageJumpscare:Clone()
	
	if Restricted then
		Gui.Icon.Image = "rbxassetid://102572778761127";
	else
		Gui.Icon.Image = "rbxassetid://85462826391722";
	end

	Gui.Enabled = true;
	Gui.Parent = Player.PlayerGui;

	local Tween = TweenService:Create(Gui.Icon, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 1})
	Tween:Play()
	Tween.Completed:Once(function()
		Gui:Destroy();
	end)

	AenoirEmit(Assets.Jumpscare, Player.PlayerGui);
end

function VFX.Attack(RootAttachment: Attachment, Direction: Vector3, Restricted: boolean)
	if not RootAttachment then return end;

	local Attachment1 = AenoirUtil.CreateAttachment(CFrame.lookAlong(RootAttachment.WorldPosition, Direction), workspace.Terrain);

	if Restricted then
		AenoirEmit(Assets.AttackSFXRestricted, RootAttachment);
	else
		AenoirEmit(Assets.AttackSFX, RootAttachment);
	end;

	AenoirEmit(Assets.Attack, RootAttachment);
	
	AenoirEmit(Assets.AttackDirection, Attachment1, function()
		Attachment1:Destroy();
	end)

	for count = 1, 2 do
		local Spin = Assets.Meshes.Spin:Clone();
		Spin.Transparency = 0.9;
		Spin.CFrame = CFrame.lookAlong(RootAttachment.WorldPosition - Direction * 7, Direction) * CFrame.Angles(math.rad(90), 0, 0);
		Spin.Size = Vector3.new(0, 0, 0);
		Spin.Parent = Visuals;

		local Connection = RunService.PreSimulation:Connect(function(dt)
			Spin.CFrame *= CFrame.Angles(0, math.rad(480) * dt / count, 0);
		end);

		local Tween2 = TweenService:Create(Spin, TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Vector3.new(30, 30, 30)})
		Tween2:Play();

		local Tween = TweenService:Create(Spin, TweenInfo.new(0.65 + count * 0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = Spin.Position + Direction * 35, Transparency = 1})
		Tween.Completed:Once(function()
			Connection:Disconnect();
			Spin:Destroy();
		end)
		Tween:Play()
	end;

	do
		local Spin = Assets.Meshes.ThickSpin:Clone();
		Spin.Transparency = 0.95;
		Spin.CFrame = CFrame.lookAlong(RootAttachment.WorldPosition + Direction * 10, Direction) * CFrame.Angles(math.rad(90), 0, 0);
		Spin.Size = Vector3.new(0, 0, 0);
		Spin.Parent = Visuals;

		local Tween2 = TweenService:Create(Spin, TweenInfo.new(1.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Vector3.new(45, 60, 45)})
		Tween2:Play();

		local Tween = TweenService:Create(Spin, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = Spin.CFrame * CFrame.Angles(0, math.rad(175), 0) + Direction * 15, Transparency = 1})
		Tween.Completed:Once(function()
			Spin:Destroy();
		end)
		Tween:Play()
	end;
end

function VFX.Summon(Character: Model, LookVector: Vector3, Restricted: boolean)
	if not Character then return end;

	local RootPart = Character.HumanoidRootPart;
	local Origin = CFrame.lookAlong(Vector3.zero, LookVector) + RootPart.Position - Vector3.yAxis * 2.50;
	local AttackOffset = CFrame.new(-2.5, 0, 3.5);
	local SummonOffset = Vector3.zero;

	do
		local Result = workspace:Raycast(RootPart.Position + Vector3.yAxis * 15, -Vector3.yAxis * 50, Utility.VisualParams);

		if Result then
			Origin = Origin.Rotation + Result.Position;
		end;
	end

	if math.random() < 0.5 then
		SummonOffset = (Rnd:NextUnitVector() * Vector3.new(1, 0, 1) + RootPart.CFrame.RightVector * 3 - LookVector).Unit * 40;
	else
		SummonOffset = (Rnd:NextUnitVector() * Vector3.new(1, 0, 1) - RootPart.CFrame.RightVector * 3 - LookVector).Unit * 40;
	end

	local SummonCF = CFrame.lookAlong(Origin.Position + SummonOffset, SummonOffset);

	local Tung = Assets.Sahur:Clone();
	local TungMaid = Job.new();
	
	Tung.Destroying:Once(function()
		TungMaid:Destroy()
	end)
	
	Tung:ScaleTo(0.2);
	Tung:PivotTo(SummonCF)
	Tung.Torso.Transparency = 1;
	Tung.Parent = workspace.Visuals;

	local BatBone = Tung.Torso.spine:FindFirstChild("Bat", true);
	local Animation = Tung.AnimationController.Animator:LoadAnimation(Assets.SwingAnimation)

	Animation:GetMarkerReachedSignal("Swing"):Once(function()
		task.wait(0.15)
		TungMaid:Clean();
		Animation:AdjustSpeed(0.8)
		task.wait(0.2);
		BatBone.Trail.Enabled = false;
		task.wait(0.3);
		TweenService:Create(Tung.Torso, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Transparency = 1}):Play();
	end)

	Animation.Stopped:Once(function()
		TungMaid:Destroy();
		Tung:Destroy();
	end);

	local ToeRight = Tung.Torso.spine:FindFirstChild("toe.L", true);
	local ToeLeft = Tung.Torso.spine:FindFirstChild("toe.R", true);

	AenoirEmit(Assets.GlideSmoke, ToeRight);
	AenoirEmit(Assets.GlideSmoke, ToeLeft);

	do
		local elapsed, value, glitch = 0, 0, 0;
		local glitch_power = 2;

		local offset_pivot = Tung.Torso.PivotOffset:Inverse();
		local new_position = SummonCF;

		TungMaid:Task(RunService.PreSimulation:Connect(function(dt)
			elapsed += dt;
			value = TweenService:GetValue(elapsed / 0.75, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out);
			glitch = TweenService:GetValue(elapsed / 0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In);

			local position = SummonCF:Lerp(Origin.Rotation * AttackOffset + RootPart.Position, value)
			local result = workspace:Raycast(position.Position + Vector3.yAxis * 15, -Vector3.yAxis * 50, Utility.VisualParams);

			if result then
				new_position = new_position:Lerp(position.Rotation + result.Position, 0.25);
			else
				new_position = new_position:Lerp(position, 0.25);
			end;

			Tung.Torso.CFrame = (new_position) * offset_pivot + Rnd:NextUnitVector() * (1 - glitch) * glitch_power;
		end))
	end;
	
	AenoirEmit(Assets.Appear, Tung.Torso.Lower);
	
	if Restricted then
		AenoirEmit(Assets.AppearSFXRestricted, Tung.Torso.Lower);
	else
		AenoirEmit(Assets.AppearSFX, Tung.Torso.Lower);
	end

	Animation:Play(0, 1, 1.2);

	local TransparencyTween = TweenService:Create(Tung.Torso, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {Transparency = 0})

	TransparencyTween.Completed:Once(function()
		task.wait(0.3);
		BatBone.Trail.Enabled = true;
	end)

	TransparencyTween:Play();
end

return VFX;