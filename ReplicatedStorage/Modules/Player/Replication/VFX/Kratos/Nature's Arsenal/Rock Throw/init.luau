local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Kratos["Nature's Arsenal"]

---------------------------------------------------------------------

local Meshes = script.Meshes
local DojyanMeshEmit = require( ReplicatedStorage.Modules.Player.Replication.Global.DojyanMeshEmit )

local function Mesh(Name : string, RootPart : BasePart)
	local Main = Meshes:FindFirstChild(Name)

	if Main then
		Main = Main:Clone()
		Main:PivotTo(RootPart.CFrame)

		for _, Mesh in ipairs(Main:GetChildren()) do
			if Mesh:IsA("Model") then
				DojyanMeshEmit(Mesh, true)
			end
		end

		task.delay(3, Main.Destroy, Main)
	end
end

local function EmitVFX(Name : string, RootPart : BasePart)
	task.spawn(Mesh, Name, RootPart)

	local VFX = script.VFX[Name]:Clone()
	VFX.CFrame = RootPart.CFrame * VFX.CFrame
	VFX.Parent = workspace.Visuals

	EffectUtility.Emit(VFX)

	return VFX
end

---------------------------------------------------------------------

local ProjectileList = {}
local ProjectileData = require( script.ProjectileData )

return {
	Start = function(AttackerModel : Model)
		local Retrieved = AnimationRetriever.new(AttackerModel, Animations.Rock)
		if (Retrieved == nil) then return end

		local MainAnimation = Retrieved.Animation
		local Job = Retrieved.Job

		local RootPart = Retrieved.RootPart

		local Rock = script.Rock2:Clone()
		Rock.Parent = AttackerModel.Torso

		local Weld = Instance.new("Motor6D")
		Weld.Part0 = AttackerModel.Torso
		Weld.Part1 = Rock.RootPart
		Weld.C0 = CFrame.Angles(0, math.rad(-90), 0)
		Weld.Parent = Rock

		local Animation = Rock.AnimationController.Animator:LoadAnimation(Animations.Rock)
		Animation:Play(0)

		Job:Task(Rock)

		Job:Task(MainAnimation:GetMarkerReachedSignal("pull"):Connect(function()
			local VFX = EmitVFX("Pull", RootPart)

			coroutine.wrap(RockHandler.Crater)(VFX.Position, Vector3.yAxis * -5, {
				Amount = 5,
				Distance = 3,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = -3,
					Max = -3
				},

				Exposure = {
					Min = 0.3,
					Max = 0.5
				},

				BaseZ = 1.5,
				SizeMultiplier = 1.2,
			})

			local Distance = LocalPlayer:DistanceFromCharacter(AttackerModel.HumanoidRootPart.Position)

			if Distance <= 25 then
				CameraShake(1, 15, 0.05, 0.4, Vector3.one * 0.8)
			end
		end))

		Job:Task(MainAnimation:GetMarkerReachedSignal("dust"):Connect(function()
			if Rock then
				local VFX = script.VFX.Rock:Clone()
				VFX.CFrame = Rock.Rock.CFrame

				EffectUtility.Weld(VFX, Rock.Rock, CFrame.new(-0.002, 0.345, 0.064) * CFrame.Angles(-0, -19.806, 0))

				VFX.Parent = workspace.Visuals
				EffectUtility.Emit(VFX)
			end
		end))

		Job:Task(MainAnimation:GetMarkerReachedSignal("throw"):Connect(function()
			if Rock then
				Rock:Destroy()
			end

			EmitVFX("Throw", RootPart)
		end))
	end,

	Throw = function(AttackerModel : Model, StartCF : CFrame, Velocity : Vector3)
		local Distance = LocalPlayer:DistanceFromCharacter(AttackerModel.HumanoidRootPart.Position)

		local MaxDistance = ProjectileData.MaxDistance
		local StartFallingAt = ProjectileData.StartFallingAt
		local Gravity = ProjectileData.Gravity

		local CF = StartCF
		local RotCF = CFrame.identity

		local Spin = 35

		local Projectile = script.RockProjectile:Clone()
		Projectile.CFrame = StartCF * CFrame.new(0, -math.pi, 0)
		Projectile.Parent = workspace.Visuals
		Projectile.Loop:Play()

		Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Projectile, function(Delta : number)
			local DistanceFromStart : number = (StartCF.Position - Projectile.Position).Magnitude

			if DistanceFromStart > StartFallingAt then
				Velocity += Gravity * Delta
			end

			local NewCF = CF + Velocity * Delta
			--local SpinVelocity = (NewCF.Position - CF.Position).Magnitude

			Velocity += Gravity * Delta
			CF = NewCF
			Spin += 8 * (Delta * 60)

			do
				local LookVector = Velocity.Unit
				local DownVector = -Gravity.Unit

				local RightVector = LookVector:Cross(DownVector).Unit
				local Up = RightVector:Cross(LookVector).Unit

				Projectile.CFrame = CFrame.fromMatrix(CF.Position, LookVector, Up) * CFrame.Angles(math.rad(Spin), math.rad(90), 0)
			end
		end)

		if Distance <= 25 then
			CameraShake(2.5, 30, 0.01, 0.1, Vector3.one * 0.8)

			Yuki_FOV.Tween(80, {0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut})

			task.delay(0.4, function()
				Yuki_FOV.Tween(70, {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In})
			end)
		end

		ProjectileList[AttackerModel] = Projectile
	end,

	Hit = function(AttackerModel : Model, Position : Vector3, Normal : Vector3)
		local Distance = LocalPlayer:DistanceFromCharacter(Position)
		local Direction = Normal * -25

		local VFX = script.VFX.Hit:Clone()
		VFX.CFrame = CFrame.new(Position)
		VFX.Parent = workspace.Visuals

		EffectUtility.Emit(VFX)

		Position += Normal * 10

		task.spawn(RockHandler.Crater, Position, Direction, { -- big middle rocks
			Amount = 6,
			Distance = {Min = 6, Max = 14},
			LookAt = { Min = 5, Max = 20 },
			Timing = {
				In = {Min = 0.075, Max = 0.2},
				Idle = {Min = 5.7, Max = 6.1},
				Out = {Min = 1.6, Max = 2.2},
			},
			Exposure = { Min = 1, Max = 2 },
			BaseZ = 2.5,
			SizeMultiplier = 2.2,
		})

		task.spawn(RockHandler.Crater, Position, Direction, { -- smaller outside rocks
			Amount = 45,
			Distance = {Min = 5, Max = 15},
			LookAt = { Min = -15, Max = 15 },
			Timing = {
				In = {Min = 0.05, Max = 0.35},
				Idle = {Min = 5.3, Max = 6.2},
				Out = {Min = 1.6, Max = 2.2},
			},
			Exposure = { Min = 0.75, Max = 1 },
			BaseZ = 1.2,
			SizeMultiplier = 1.5,
		})

		task.spawn(RockHandler.Rockst, Position, Direction, {
			Size = {0.75, 1.5},
			Count = 6,
			Velocity = 15,
			SpawnVariance = 2;
		})

		if Distance <= 40 then	
			CameraShake(5, 30, 0.01, 0.45, Vector3.one * 0.8, Vector3.one * 0.3)
		end
	end,

	Stop = function(AttackerModel : Model)
		if (AttackerModel == nil) then return end

		if ProjectileList[AttackerModel] then
			local OriginalRock = ProjectileList[AttackerModel]

			local BrokenRock = script.RockPieces:Clone()
			BrokenRock:PivotTo(OriginalRock.CFrame)
			BrokenRock.Parent = workspace.Visuals

			for _, Item : BasePart in ipairs(BrokenRock:GetChildren()) do
				if Item:IsA("BasePart") then
					Item.AssemblyLinearVelocity = Vector3.new(Utility.Seed:NextNumber(-35, 35), Utility.Seed:NextNumber(60, 70), Utility.Seed:NextNumber(-35, 35))
					Item.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15))
				end
			end

			task.delay(5, function()
				local Info = TweenInfo.new(1)

				for _, Item : BasePart in ipairs(BrokenRock:GetChildren()) do
					if Item:IsA("BasePart") then
						TweenService:Create(Item, Info, {Size = Vector3.zero, Transparency = 1}):Play()
					end
				end
			end)

			task.delay(7.5, BrokenRock.Destroy, BrokenRock)

			OriginalRock:Destroy()
			ProjectileList[AttackerModel] = nil
		end
	end
}