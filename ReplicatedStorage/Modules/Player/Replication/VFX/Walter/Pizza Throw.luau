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

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AenoirEmit = EffectUtility.AenoirEmit

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Flashbang = require( ReplicatedStorage.Modules.Player.Replication.Global.Flashbang )
local ProjectileHandler = require( ReplicatedStorage.Projectiles.ProjectileHandler )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local Maid = require( ReplicatedStorage.Packages.Maid )

local Animations = ReplicatedStorage.Animations.Attacks.Walter["Pizza Throw"]

return {
	["Slice"] = function(Humanoid: Humanoid)
		if not Humanoid then return end;

		local Character = Humanoid.Parent;
		local RootPart = Character:FindFirstChild("HumanoidRootPart");
		
		if not RootPart then return end;
		
		local BloodEnabled = Blood.CanShowBlood();
		
		if Player:DistanceFromCharacter(RootPart.Position) < 300 then
			if BloodEnabled then
				AenoirEmit(Assets.Slice, Character.Head);
			else
				AenoirEmit(Assets.SliceNoBlood, Character.Head);
			end
			
			local Highlight = Instance.new("Highlight");
			Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop;
			Highlight.OutlineTransparency = 1;
			Highlight.FillTransparency = 1;
			Highlight.FillColor = if BloodEnabled then Color3.fromRGB(128, 0, 0) else Color3.new(1, 1, 1);
			Highlight.Parent = Character;
			
			local InInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out);
			local OutInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In);
		
			if Player:DistanceFromCharacter(RootPart.Position) < 160 then
				local Correction = Instance.new("ColorCorrectionEffect")
				Correction.Parent = Lighting;
				
				local CorrectionTween = TweenService:Create(Correction, InInfo, {
					TintColor = if BloodEnabled then Color3.fromRGB(214, 125, 125) else Color3.new(1, 1, 1);
					Brightness = if BloodEnabled then 0 else 0.1;
				})
				CorrectionTween:Play();
				
				CorrectionTween.Completed:Once(function()
					local Tween = TweenService:Create(Correction, OutInfo, {
						TintColor = Color3.fromRGB(255, 255, 255);
						Brightness = 0;
					})
					Tween:Play()
					Tween.Completed:Wait();
					
					Correction:Destroy();
				end)
			end;
			
			local HighlightTween = TweenService:Create(Highlight, InInfo, {FillTransparency = if BloodEnabled then 0 else 0.4})
			HighlightTween:Play()
			
			HighlightTween.Completed:Once(function()
				task.wait(0.5);
				
				local Tween = TweenService:Create(Highlight, OutInfo, {FillTransparency = 1})
				Tween:Play()
				Tween.Completed:Wait();
				
				Highlight:Destroy();
			end);
		end;
	end,

	["Swing"] = function(Character)
		if not Character then return end;

		local Animation = AenoirUtil.WaitForAnimation(Character.Humanoid.Animator, Animations.SwingBack.AnimationId)

		if Animation then
			local RootPart = Character.HumanoidRootPart;
			local RightArm = Character["Right Arm"];
			local LeftArm = Character["Left Arm"];
			local RightLeg = Character["Right Leg"];
			local LeftLeg = Character["Left Leg"];

			AenoirEmit(Assets.SwingStart, RootPart.RootAttachment);

			--Animation:GetMarkerReachedSignal("Throw"):Once(function()
			AenoirEmit(Assets.Parry, RootPart)
			AenoirEmit(Assets.ThrowAlign, RootPart.CFrame * CFrame.new(0, 0, -1.5));
			--end)
		end
	end,

	["Pizza"] = function(Character)
		if not Character then return end;

		local Animation = AenoirUtil.WaitForAnimation(Character.Humanoid.Animator, Animations.Windup.AnimationId)

		if Animation then
			local ThisPlayer = Players:GetPlayerFromCharacter(Character);
			local RootPart = Character.HumanoidRootPart;
			local RightArm = Character["Right Arm"];

			local Pizza = Assets.Pizza:Clone();
			Pizza.RootPart.PizzaJoint.Part0 = Character.HumanoidRootPart;
			Pizza.RootPart.Anchored = false;
			Pizza.Parent = workspace.Visuals;
			
			local PizzaAnimation = Pizza.AnimationController.Animator:LoadAnimation(Animations.WindupPizza);
			PizzaAnimation:Play();
			
			local TempMaid = Maid.new();
			
			TempMaid:add(Animation.Stopped:Once(function()
				TempMaid:destroy();
				
				PizzaAnimation:Stop();
				PizzaAnimation:Destroy();
				
				if Pizza.RootPart.PizzaJoint.Enabled then
					-- Animation stopped before it was thrown to the ground
					Pizza:Destroy()
				else
					task.wait(10);
					
					Pizza.RootPart.Anchored = true;
					
					local Tween =TweenService:Create(Pizza.Cube, TweenInfo.new(2), {Size = Vector3.zero})
					Tween:Play();
					Tween.Completed:Wait();
					
					Pizza:Destroy();
				end;
			end))
			
			AenoirEmit(Assets.Summon, Pizza.RootPart)
			
			TempMaid:add(Animation:GetMarkerReachedSignal("PizzaSwing"):Once(function()
				AenoirEmit(Assets.Unveil, Pizza.RootPart)
			end))

			local ThrowCFrame: CFrame;

			TempMaid:add(Animation:GetMarkerReachedSignal("Throw"):Once(function()
				Pizza.Cube.CanCollide = true;
				Pizza.RootPart.Anchored = false;
				Pizza.RootPart.PizzaJoint.Enabled = false;
				Pizza.RootPart.AssemblyLinearVelocity = (RootPart.CFrame.LookVector * 25 - RootPart.CFrame.RightVector * 20) + Vector3.yAxis * 5
				Pizza.Cube["Bone.002"].CFrame = CFrame.new(0, 1e5, 0);
				
				ThrowCFrame = RootPart.CFrame;

				AenoirEmit(Assets.ThrowAlign, RootPart.CFrame * CFrame.new(0, 0, -1.5));
			end))

			--TempMaid:add(Animation:GetMarkerReachedSignal("Turn"):Once(function()
			--	AenoirEmit(Assets.Turn, RootPart)
			--	AenoirEmit(Assets.TurnPizza, Pizza.RootPart)
			--end))
		end
	end,
};