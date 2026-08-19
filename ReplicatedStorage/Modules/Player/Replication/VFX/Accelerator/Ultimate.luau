local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local BlackBars = require( ReplicatedStorage.Modules.Player.Replication.Global.BlackBars )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local Player = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera
local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local ImpactFrames = Player.PlayerGui.ImpactFrames.AcceleratorUltimate

local VFX = {}

function VFX.OnUltimateStart(Model : Model)
	if (Model == nil or Model.Parent == nil) then return end
	
	local AuraVFX = {}
	local RootPart = Model.HumanoidRootPart;
	
	for _, Limb in ipairs(Model:GetChildren()) do 
		if Limb:IsA("BasePart") and (Limb.Name:find("Arm") or Limb.Name == "Torso") then
			for Index, Particle in script.Assets.Aura.Default:GetChildren() do
				local ParticleClone = Particle:Clone()
				ParticleClone.Parent = Limb
				
				table.insert(AuraVFX, ParticleClone)
			end

			local LimbEffect = script.Assets.Aura:FindFirstChild(Limb.Name)
			
			if LimbEffect then
				local LimbEffectClone = LimbEffect:Clone()
				LimbEffectClone.Name = "LimbEffect";
				LimbEffectClone.Parent = RootPart;
				
				EffectUtility.Weld(LimbEffectClone, Limb)
				
				table.insert(AuraVFX, LimbEffectClone)
			end
		end
	end
	
	AttributeListener.new(Model, "Ultimate", function()
		for _, Effect in AuraVFX do
			EffectUtility.Toggle(Effect, false)
			task.delay(1, Effect.Destroy, Effect)
		end
		
		table.clear(AuraVFX)
	end)
end

function VFX.Stomp(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if Distance > 300 then return end
	
	local Position = (RootPart.CFrame * CFrame.new(0.5, 0, -2)).Position
	local Direction = Vector3.yAxis * -10

	local Stars = script.Assets.Part:Clone()
	Stars.CFrame = RootPart.CFrame
	Stars.Parent = RootPart

	EffectUtility.Emit(Stars)

	if Player == Players:GetPlayerFromCharacter(RootPart.Parent) then
		local CameraRig = script.CameraRig:Clone()
		CameraRig.PrimaryPart:PivotTo(RootPart.CFrame)
		CameraRig.Parent = workspace.Visuals

		local Animation = CameraRig.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Ultimate.Accelerator.Camera)
		local Clean = RunCameraRig(RootPart, CameraRig)

		Animation:GetMarkerReachedSignal("Disable"):Once(Clean)

		Animation:GetMarkerReachedSignal("Return"):Once(function()
			Yuki_FOV.Tween(55, {0.5})

			local OldTimePosition = Animation.TimePosition

			local CameraRig2 = script.CameraRig:Clone()
			CameraRig2.PrimaryPart:PivotTo(RootPart.CFrame)
			CameraRig2.Parent = workspace.Visuals
			
			local Animation2 = CameraRig.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Ultimate.Accelerator.Camera)
			local Clean2 = RunCameraRig(RootPart, CameraRig2, CFrame.new(0, 0.5, 0))

			Animation2:Play(0)
			Animation2.TimePosition = OldTimePosition
			
			Animation2.Stopped:Connect(function()
				Clean2()
				Yuki_FOV.Tween(70, {0.75})
			end)
		end)

		EffectUtility.ToggleImpactFrames(ImpactFrames, true)
		Animation:Play(0)
	end

	if (Distance <= 50) then
		CameraShake(5.5, 55, 0.1, 0.55, Vector3.one * 0.8)
	end
	
	task.defer(RockHandler.Crater, Position, Direction, {
		Amount = 40,
		Distance = {Min = 15, Max = 40},
		LookAt = {Min = 5, Max = 10},
		Timing = {
			In = {Min = 0.05, Max = 0.35},
			Idle = {Min = 4.7, Max = 5.1},
			Out = 4,
		},
		Exposure = {Min = 0.5, Max = 2},
		BaseZ = 1.25,
		SizeMultiplier = 3,
	})

	task.defer(RockHandler.Crater, Position, Direction, {
		Amount = 65,
		Distance = {Min = 45, Max = 65},
		LookAt = {Min = -5, Max = -10},
		Timing = {
			In = {Min = 0.05, Max = 0.35},
			Idle = {Min = 4.7, Max = 5.1},
			Out = 4,
		},
		Exposure = {Min = 2, Max = 3},
		BaseZ = 0.75,
		SizeMultiplier = 5,
	})

	task.defer(RockHandler.Rockst, Position, Direction, {
		Size = {1.5, 3.5},
		Count = 60,
		Velocity = 125,
		SpawnVariance = 35;
	})
end

function VFX.Laugh1(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if Distance > 50 then return end

	VFX.Laugh2(RootPart)

	local Dust = script.Assets.DustHere:Clone()
	Dust.CFrame = RootPart.CFrame
	Dust.Parent = RootPart

	EffectUtility.Toggle(Dust, true)
	task.delay(3, EffectUtility.Toggle, Dust, false)
	task.delay(6, Dust.Destroy, Dust)

	task.wait(1.5)

	if Player == Players:GetPlayerFromCharacter(RootPart.Parent) then
		BlackBars(true)

		local LaughScreen = script.Assets.LaughScreen:Clone()
		LaughScreen.CFrame = RootPart.CFrame
		LaughScreen.Parent = RootPart

		EffectUtility.Toggle(LaughScreen, true)

		task.delay(1.59, function()
			EffectUtility.Toggle(LaughScreen, false)
			task.delay(2, LaughScreen.Destroy, LaughScreen)
		end)
	end
end

function VFX.Laugh2(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if Distance > 50 then return end

	local Attach = script.Assets.Laughs:Clone()
	Attach.CFrame = RootPart.CFrame
	Attach.Parent = RootPart

	EffectUtility.Toggle(Attach, true)
	task.delay(1.5, EffectUtility.Toggle, Attach, false)
	task.delay(6, Attach.Destroy, Attach)
end

function VFX.FinalLaugh(RootPart : BasePart)
	VFX.Laugh2(RootPart)
end

function VFX.Blood(Head : BasePart)
	if not LocalPlayer:GetAttribute("Blood") then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(Head.Position)
	if Distance > 50 then return end

	local Blood = script.Assets.Blood.BloodEnable:Clone()
	Blood.Parent = Head

	task.delay(4, Blood.Destroy, Blood)
end

function VFX.Wipe(Head : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Head.Position)
	if Distance > 50 then return end

	local Blood = Head:FindFirstChild("BloodEnable")

	if (Blood ~= nil) then
		Blood:Destroy()
	end

	local Stars = script.Assets.Blood.BloodEmit:Clone()
	Stars.Parent = Head

	EffectUtility.Emit(Stars)
end

function VFX.Impact(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if Distance > 50 then return end

	local Impact = script.Assets.ImpactFramesNotByUserHere:Clone()
	Impact.CFrame = RootPart.CFrame
	Impact.Parent = RootPart

	EffectUtility.Toggle(Impact, true)

	task.delay(0.15, function()
		if Player == Players:GetPlayerFromCharacter(RootPart.Parent) then
			ImpactFrames.AnchorPoint = Vector2.zero

			for Index = 1, #ImpactFrames:GetChildren(), 1 do
				task.wait(0.025)

				local Frame : ImageLabel = ImpactFrames[Index]
				Frame.Visible = false
			end
		end
	end)

	task.wait(0.4)

	EffectUtility.Toggle(Impact, false)
	task.delay(4, Impact.Destroy, Impact)
end

function VFX.Explosions(RootPart : BasePart)
	task.wait(0.05)

	if Player == Players:GetPlayerFromCharacter(RootPart.Parent) then
		BlackBars(false)
	end

	for Index = 1, 14 do
		local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
		if Distance > 500 then return end

		if (Distance <= 50) then
			CameraShake(2, 15, 0.01, 0.3, Vector3.one * 0.8, Vector3.one * 0.5)
			Vignette(Color3.fromRGB(255, 131, 7), 0.5, 0.25)
		end

		local Origin = RootPart.CFrame * CFrame.new(Utility.Seed:NextNumber(-50, 50), 0, Utility.Seed:NextNumber(-50, 50))

		local Direction = Vector3.yAxis * -25
		local Raycast = workspace:Raycast(Origin.Position, Direction, Utility.VisualParams)

		if (Raycast ~= nil) then
			EffectUtility.EmitEffects(script.Assets.Explosion, workspace.Terrain, Raycast.Position)
		end
		
		task.spawn(RockHandler.Crater, Origin.Position, Direction, {
			Amount = 25,
			Distance = {Min = 20, Max = 30},
			LookAt = {Min = -5, Max = -10},
			Timing = {
				In = {Min = 0.05, Max = 0.35},
				Idle = {Min = 4.7, Max = 5.1},
				Out = 4,
			},
			Exposure = {Min = 2.5, Max = 3},
			BaseZ = 0.75,
			SizeMultiplier = 2.5,
		})

		task.spawn(RockHandler.Rockst, Origin.Position, Direction, {
			Size = {1, 2},
			Count = 10,
			Velocity = 125,
			SpawnVariance = 25;
		})

		task.wait(0.2)
	end
end

return VFX

