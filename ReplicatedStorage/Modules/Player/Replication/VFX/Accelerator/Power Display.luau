local VFX = {}
local Vanishes = {}
local Kicks = {}
local KickHeads = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local Afterimage = require( ReplicatedStorage.Modules.Player.Replication.Global.Afterimage )
local Distort = require( ReplicatedStorage.Modules.Player.Replication.Global.Distort )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )

local CharacterTransparency = require( ReplicatedStorage.Modules.Player.Replication.Global.CharacterTransparency )
local MeshVFX = require( ReplicatedStorage.Modules.Player.Replication.Global.MeshVFX )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local ImpactFrames : Frame =  LocalPlayer.PlayerGui.ImpactFrames.AcceleratorPowerDisplay

function VFX.Camera(RootPart : BasePart)
	local Replication : Configuration = AttributeListener.GetReplicationFromSource(LocalPlayer)
	local Offset = CFrame.new(-4.2, -2.496, -3.306) * CFrame.Angles(0, math.rad(-90), 0)

	local Camera = script.Camera:Clone()
	Camera:PivotTo(RootPart.CFrame * Offset)
	Camera.Parent = workspace.Visuals

	local Animation = Camera.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Accelerator["Power Display"].Camera)
	Animation:Play(0)

	local Clean = RunCameraRig(RootPart, Camera, Offset)

	AttributeListener.new(RootPart, "PowerDisplayCamera", function()
		Clean()
		Yuki_FOV.Reset()
	end)
end

function VFX.Hit(RootPart : BasePart, VictimRootPart : BasePart)
	local PlayerIsAttackerOrVictim = (Players:GetPlayerFromCharacter(RootPart.Parent) == LocalPlayer or Players:GetPlayerFromCharacter(VictimRootPart.Parent) == LocalPlayer)
	
	local HitSFX = script.HitSFX:Clone()
	HitSFX.Parent = PlayerIsAttackerOrVictim and workspace or RootPart
	HitSFX:Play()
	
	AttributeListener.new(RootPart, "PowerDisplayCamera", function()
		TweenService:Create(HitSFX, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{Volume = 0}
		):Play()
		
		task.delay(1.5, HitSFX.Destroy, HitSFX)
	end)
	
	if PlayerIsAttackerOrVictim then
		EffectUtility.ToggleImpactFrames(ImpactFrames, true)
	end
end

function VFX.Vanishing(Torso : BasePart)
	local RootPart : BasePart = Torso.Parent.HumanoidRootPart
	
	local Effect = script.TP:Clone()
	Effect.Parent = workspace.Visuals
	
	EffectUtility.Toggle(Effect, true)
	EffectUtility.Weld(Effect, Torso)
	
	Vanishes[Torso] = Effect
	
	Distort{Character = Torso.Parent}
	
	local Radius = 7.5
	local Time = 0.4
	
	local function RandomRockComingOut()
		local RandomPosition = RootPart.Position + Vector3.new(Utility.Seed:NextNumber(-Radius, Radius), 0, Utility.Seed:NextNumber(-Radius, Radius))
		local Direction = Vector3.yAxis * -10

		local Raycast = workspace:Raycast(RandomPosition, Direction, Utility.VisualParams)
		if (Raycast == nil) then return end

		coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
			Amount = 6;
			Distance = 2;	

			LookAt = {
				Min = -3,
				Max = -3
			},

			Exposure = {
				Min = 0.85,
				Max = 1
			},

			SizeMagnitude = 0.5,
		})

		EffectUtility.CraterSmoke("Small", Raycast)

		local Rock = Instance.new("Part")
		Rock.Color = Raycast.Instance.Color
		Rock.Material = Raycast.Instance.Material
		Rock.MaterialVariant = Raycast.Instance.MaterialVariant

		Rock.CanCollide = false
		Rock.Size = Vector3.one * Utility.Seed:NextNumber(0.75, 1.5)

		Rock.Position = Raycast.Position

		local BodyPosition = Instance.new("BodyPosition")
		BodyPosition.MaxForce = Vector3.one * 80000
		BodyPosition.P = Utility.Seed:NextNumber(5000, 6000)
		BodyPosition.Position = RandomPosition + (Vector3.yAxis * Utility.Seed:NextNumber(4.5, 6.5))
		BodyPosition.Parent = Rock

		Rock.Parent = workspace.Visuals
		Rock.AssemblyAngularVelocity = Vector3.one * Utility.Seed:NextNumber(-7, 7)

		task.delay(Time + 1, function()
			BodyPosition:Destroy()

			Rock.AssemblyLinearVelocity = Vector3.yAxis * -50
			Rock.CanCollide = true

			task.delay(1, function()
				TweenService:Create(Rock, TweenInfo.new(1), {
					Size = Vector3.zero,
					Transparency = 1
				}):Play()

				task.delay(1, Rock.Destroy, Rock)
			end)
		end)
	end
	
	if Players:GetPlayerFromCharacter(Torso.Parent) == LocalPlayer then
		local Shake = CameraShake(3.5, 35, 0.1, 0, Vector3.one * 0.8)
	
		if Shake then
			task.delay(Time, function()
				Shake:StartFadeOut(0.15)
			end)
		end
		
		task.spawn(function()
			local Start = time()

			while time() - Start < Time do
				Vignette(Color3.fromRGB(123, 46, 255), 0.5, 0.25)
				
				MeshVFX.new{ 
					MeshPart = ReplicatedStorage.Effects.Parts.MeshVFX.Start, 
					CFrame = RootPart.CFrame * CFrame.new(0, -1.5, 0),

					TweenDuration = 0.2,
					Duration = 0.2,

					TweenProperties = {
						Transparency = 1,
						Size = Vector3.new(25, 0.75, 25)
					},
				}
				
				for Index = 1, 2 do
					RandomRockComingOut()
				end

				task.wait(0.05)
			end
		end)

		Yuki_FOV.Tween(100, {0.5})
	end
end

function VFX.Dash(RootPart : BasePart, CF : CFrame)
	Afterimage(RootPart.Parent, {0.75}, {0.25}, 2)

	task.spawn(function()
		local Torso : BasePart = RootPart.Parent.Torso

		if Torso and Vanishes[Torso] then
			Vanishes[Torso]:Destroy()
			Vanishes[Torso] = nil
		end
	end)
	
	local Dash1 = script.DASH:Clone()
	Dash1.CFrame = CF
	
	local CFs = {
		[1] = 15,
		[2] = 40,
		[3] = 75,
	}

	for Index = 1, 3 do
		local Dash2 = script.DASH2:Clone()
		Dash2.CFrame = CF * CFrame.new(0, 0, -CFs[Index])
		Dash2.Parent = workspace.Visuals
		EffectUtility.Emit(Dash2)
	end

	Dash1.Parent = workspace.Visuals
	EffectUtility.Emit(Dash1)
	
	CharacterTransparency(RootPart.Parent, 1)
	
	if LocalPlayer:DistanceFromCharacter(CF.Position) <= 25 then
		CameraShake(2.5, 25, 0.1, 0.15, Vector3.one * 0.8)
	end
end

function VFX.Unvanishing(Torso : BasePart)
	VFX.Unvanish(Torso)
	
	local Effect = script.TP:Clone()
	Effect.Parent = workspace.Visuals

	EffectUtility.Toggle(Effect, true)
	EffectUtility.Weld(Effect, Torso)
	
	task.delay(0.1, function()
		EffectUtility.Toggle(Effect, false)
		task.delay(1, Effect.Destroy, Effect)
	end)
	
	Afterimage(Torso.Parent, {0.75}, {0.25}, 5)
end

function VFX.Unvanish(Torso : BasePart)
	if Vanishes[Torso] then
		Vanishes[Torso]:Destroy()
		Vanishes[Torso] = nil
	end
	
	if Players:GetPlayerFromCharacter(Torso.Parent) == LocalPlayer then
		Yuki_FOV.Tween(70, {0.5})
	end
	
	CharacterTransparency(Torso.Parent, 0)
end

function VFX.Slam(RootPart : BasePart)
	local CF = RootPart.CFrame * CFrame.new(0, -3, -2)
	local Position = CF.Position
	local Direction = Vector3.yAxis * -10
	
	local Distance =  LocalPlayer:DistanceFromCharacter(Position)
	
	if Distance <= 100 then
		local Effect = script.Slam.Attachment:Clone()
		Effect.CFrame = CF
		Effect.Parent = workspace.Terrain
		EffectUtility.Emit(Effect)

		coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			Amount = 8,
			Distance = 6,

			LookAt = { -- Where the rocks face towards (y axis)
				Min = -3,
				Max = -3
			},

			Exposure = {
				Min = 0.3,
				Max = 0.5
			},

			BaseZ = 1.5,
			SizeMultiplier = 1,
		})

		coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			Amount = 13,
			Distance = 11,
			SizeMultiplier = 1.5,
		})

		EffectUtility.RaycastCraterSmoke("Big", Position, Direction)
	end

	if Distance <= 40 then
		CameraShake(4, 65, 0.1, 0.7, Vector3.one * 0.8)
		Vignette(Color3.fromRGB(123, 46, 255), 0.15, 0.75)
	end
end

local Barriers = {}

local HitAssets = script.Hit
local BarrierAssets = HitAssets.Barrier

function VFX.Barrier(RootPart : BasePart)
	local Barrier = BarrierAssets.barrier:Clone()
	Barrier.CFrame = RootPart.CFrame
	Barrier.Parent = workspace.Visuals
	
	EffectUtility.Toggle(Barrier.Enable, true)
	EffectUtility.Emit(Barrier.Emit, true)
	
	Barriers[RootPart] = Barrier
	
	task.delay(5, function()
		Barrier:Destroy()
		
		if RootPart and Barriers[RootPart] then
			Barriers[RootPart] = nil
		end
	end)
end

function VFX.Pushaway(RootPart : BasePart)
	if RootPart and Barriers[RootPart] then
		local Barrier = Barriers[RootPart]
		Barriers[RootPart] = nil
		
		EffectUtility.Toggle(Barrier.Enable, false)
		EffectUtility.Emit(Barrier.LEmit, true)
	end
	
	MeshVFX.new({ 
		MeshPart = ReplicatedStorage.Effects.Parts.MeshVFX.Start, 
		CFrame = RootPart.CFrame * CFrame.new(0, -1, 0),

		TweenDuration = 0.75,
		Duration = 0.75,

		TweenProperties = {
			Transparency = 1,
			Size = Vector3.new(20, 10, 20)
		},
	})
	
	local Time =1.5166666666666666
	
	local Mesh1 = BarrierAssets.Mesh1:Clone() --M5
	Mesh1.CFrame = RootPart.CFrame * CFrame.new(0.542, -0.427, 0.971)
	Mesh1.Size = Vector3.new(8.081, 7.75, 8.081)
	Mesh1.Transparency = 0.8
	Mesh1.Parent = workspace.Visuals
	
	TweenService:Create(Mesh1, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		CFrame = Mesh1.CFrame * CFrame.Angles(math.rad(180), math.rad(52.793), math.rad(180)),
		Size = Vector3.new(18, 8, 18)
	}):Play()
	
	TweenService:Create(Mesh1, TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
		Transparency = 1
	}):Play()
	
	----------------------------------------------------------------------------------------------------------------------------------------
	
	local Mesh2 = BarrierAssets.Mesh2:Clone() --M6
	Mesh2.CFrame = RootPart.CFrame * CFrame.new(0.542, -0.427, 0.971) * CFrame.Angles(math.rad(180), math.rad(52.231), math.rad(180))
	Mesh2.Size = Vector3.new(8.081, 7.75, 8.081)
	Mesh2.Transparency = 0.8
	Mesh2.Parent = workspace.Visuals

	TweenService:Create(Mesh2, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		CFrame = Mesh2.CFrame * CFrame.Angles(math.rad(180), math.rad(1.646), math.rad(180)),
		Size = Vector3.new(8, 8, 8)
	}):Play()

	TweenService:Create(Mesh2, TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
		Transparency = 1
	}):Play()
	
	----------------------------------------------------------------------------------------------------------------------------------------
	
	local Spin = HitAssets.SPIN:Clone()
	Spin.CFrame = RootPart.CFrame * CFrame.new(0.542, -3, 0.971)
	Spin.Parent = workspace.Visuals
	
	TweenService:Create(Spin, TweenInfo.new(2, Enum.EasingStyle.Linear), {
		CFrame = Spin.CFrame * CFrame.Angles(0, math.pi, 0)
	}):Play()
end

function VFX.Teleport(Torso : BasePart)
	local Effect = script.TP:Clone()
	Effect.Parent = workspace.Visuals

	EffectUtility.Toggle(Effect, true)
	EffectUtility.Weld(Effect, Torso)

	task.delay(0.2, EffectUtility.Toggle, Effect, false)
	task.delay(1, Effect.Destroy, Effect)
end

function VFX.Grab(RootPart : BasePart)
	local Effect = HitAssets.Grab:Clone()
	Effect.CFrame = RootPart.CFrame
	Effect.Parent = workspace.Visuals
	EffectUtility.Emit(Effect)
end

function VFX.GrabSlam(RootPart : BasePart)
	local Effect = HitAssets.Slam:Clone()
	Effect.CFrame = RootPart.CFrame * CFrame.new(3.5, -3, -25)
	Effect.Parent = workspace.Visuals
	EffectUtility.Emit(Effect)
end

function VFX.Kick1(RootPart : BasePart)
	local Model = HitAssets.Kick:Clone()
	Model:PivotTo(RootPart.CFrame * CFrame.new(3.5, -3, -25))
	Model.Parent = workspace.Visuals
	EffectUtility.Emit(Model)
	
	for _, v in pairs(Model:GetDescendants()) do
		if v:IsA('ParticleEmitter') then
			TweenService:Create(v, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TimeScale = 0.05}):Play()
		end
	end
	
	Kicks[RootPart] = Model
end

function VFX.Kick2(RootPart : BasePart)
	if Kicks[RootPart] then
		local KickModel = Kicks[RootPart]
		Kicks[RootPart] = nil

		for _, v in pairs(KickModel:GetDescendants()) do
			if v:IsA('ParticleEmitter') then
				TweenService:Create(v, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TimeScale = 1}):Play()
			end
		end
		
		task.delay(3, KickModel.Destroy, KickModel)

		local Model = HitAssets.Kick2:Clone()
		Model:PivotTo(RootPart.CFrame * CFrame.new(3.5, -3, -25))
		Model.Parent = workspace.Visuals
		EffectUtility.Emit(Model)
	end
end

function VFX.KickHead(RootPart : BasePart)
	if Players:GetPlayerFromCharacter(RootPart.Parent) == LocalPlayer then
		CameraShake(2.25, 22.5, 0.01, 0.1, Vector3.one * 0.8, Vector3.one * 0.3)
	end

	local Effect = HitAssets.FINAL.F:Clone()
	Effect.CFrame = CFrame.new(3.357, -0.684, -24.096) * CFrame.Angles(0, math.rad(32.723), math.rad(-42.308))
	Effect.Parent = RootPart
	EffectUtility.Emit(Effect)
	
	for _, v in pairs(Effect:GetDescendants()) do
		if v:IsA('ParticleEmitter') then
			TweenService:Create(v, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TimeScale = 0.05}):Play()
		end
	end
	
	KickHeads[RootPart] = Effect
end

function VFX.KickHeadResume(RootPart : BasePart)
	if KickHeads[RootPart] then
		for _, v in pairs(KickHeads[RootPart]:GetDescendants()) do
			if v:IsA('ParticleEmitter') then
				TweenService:Create(v, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {TimeScale = 1}):Play()
			end
		end
		
		task.delay(3, KickHeads[RootPart].Destroy, KickHeads[RootPart])
		KickHeads[RootPart] = nil
	end
end

function VFX.Crack(RootPart : BasePart, Type : number)
	if Players:GetPlayerFromCharacter(RootPart.Parent) == LocalPlayer then
		CameraShake(1, 10, 0.01, 0.175, Vector3.one * 0.8, Vector3.one * 0.3)
	end
	
	local Effect = HitAssets.FINAL[`C{Type}`]:Clone()
	Effect.CFrame = CFrame.new(3.357, -0.684, -24.096) * CFrame.Angles(0, math.rad(32.723), math.rad(-42.308))
	Effect.Parent = RootPart
	EffectUtility.Emit(Effect)
end

function VFX.Splat(RootPart : BasePart)
	if Players:GetPlayerFromCharacter(RootPart.Parent) == LocalPlayer then
		CameraShake(7, 70, 0.01, 0.35, Vector3.one * 0.8)
	end
	
	local Effect = HitAssets.FINAL.LEMIT:Clone()
	Effect.CFrame = CFrame.new(3.357, -0.684, -24.096) * CFrame.Angles(0, math.rad(32.723), math.rad(-42.308))
	Effect.Parent = RootPart
	EffectUtility.Emit(Effect)
end

function VFX.ImpactFrames()
	EffectUtility.EmitImpactFrames(ImpactFrames)
end

return VFX