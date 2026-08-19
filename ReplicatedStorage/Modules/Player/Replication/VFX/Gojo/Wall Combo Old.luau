local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local Bubble = require( ReplicatedStorage.Modules.Player.Replication.Global.Bubble )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local Yuki_Skeleton = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_Skeleton )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local Shockwave = require( ReplicatedStorage.Modules.Player.Replication.Global.Shockwave )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local Player = Players.LocalPlayer

local RNG = Random.new()

local Assets = script.Assets

-- vfx scripted by mxitz i just edited to make it work in game properly

local function Enable(Directory : {ParticleEmitter | Beam | Trail}, State : boolean)
	for _, Item in Directory do
		if typeof(Item) == "table" then
			Enable(Item, State) 
			
			continue
		end

		if not table.find({"ParticleEmitter", "Beam", "Trail", "PointLight"}, Item.ClassName) then
			continue
		end

		Item.Enabled = State
	end
end

local function Flash(Data)
	Data = Data or {}

	setmetatable(Data, { __index = {
		TweenIn = {0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In},
		TweenOut = {0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut},

		LifeTime = 0.3,

		Size = UDim2.fromScale(1,1),

		Transparency = 0.5,
		Color = Color3.new(1)
	}})

	local ScreenEffect = Assets.Vignette:Clone()
	ScreenEffect["Image"].ImageColor3 = Data.Color
	ScreenEffect["Image"].ImageTransparency = 1
	ScreenEffect["Image"].Size = Data.Size
	ScreenEffect["Image"].Visible = true

	TweenService:Create(ScreenEffect["Image"], TweenInfo.new(unpack(Data.TweenIn)), {
		ImageTransparency = Data.Transparency;
	}):Play()

	ScreenEffect.Parent = Player.PlayerGui
	
	task.delay(Data.LifeTime, function()
		TweenService:Create(ScreenEffect["Image"], TweenInfo.new(unpack(Data.TweenOut)), {
			ImageTransparency = 1;
		}):Play()

		task.delay(Data.TweenOut[1] + 0.1, ScreenEffect.Destroy, ScreenEffect)

		setmetatable(Data, nil)
		table.clear(Data)
		Data = nil
	end)
end


local function Wind(CF : CFrame, Size: Vector3, Time : number)
	local Circle = Assets.Wind2:Clone()
	Circle.CFrame = CF
	Circle.Parent = workspace.Visuals

	TweenService:Create(Circle, TweenInfo.new(Time), 
		{Transparency = 1, Size = Size or Vector3.new(0.45, 21.92, 21.92)}
	):Play()
	
	task.delay(1, Circle.Destroy, Circle)
end

local function CameraToPositionDistance(Point : Vector3)
	return (workspace.CurrentCamera.CFrame.Position - Point).Magnitude
end

local VFX = {}

function VFX.Start(RootPart : BasePart)
	EffectUtility.EmitEffects(script.SFX.Normal, RootPart)
end

function VFX.FinisherStart(RootPart : BasePart)
	EffectUtility.EmitEffects(script.SFX.Finisher, RootPart)
end

function VFX.Kick(Leg : BasePart)
	if (Leg == nil or Leg.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(Leg.Position)

	if (Distance < 15) then
		CameraShake(1.75, 12.5, 0.1, 0.25, Vector3.one * 0.8)
	end
	
	if (Distance < 100) then
		Shockwave(Leg)

		local HitEffect = Assets.HITFX.Attachment:Clone()
		HitEffect.Parent = Leg
		EffectUtility.Emit(HitEffect)

		Yuki_Skeleton(Leg)
	end
end

function VFX.FinisherInfinity(Character : Model, Victim : Model)
	local AttackerPlayer = Players:GetPlayerFromCharacter(Character)
	local Humanoid : Humanoid = Character:FindFirstChild("Humanoid") or Character:WaitForChild("Humanoid")
	local Torso : BasePart = Character:WaitForChild("Torso") -- animation offsets torso so it looks off when on root

	local NewJob = Job.new()

	local AttackerVFX = Assets.vfxFloor.FxGround:Clone()
	local VictimVFX = Assets.vfxVictim.VfxEnable:Clone()
	local Lines = Assets.Wallcombolines:Clone()

	local InfinityShake = nil

	local Replication : Configuration = AttributeListener.GetReplicationFromSource(AttackerPlayer)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Torso.Position)

	if (Distance < 125) then 
		Wind(Torso.CFrame * CFrame.new(0, -2, 0), Vector3.new(15.322,22.4,15.139), 0.2)
		Wind(Torso.CFrame * CFrame.new(0, -2, 0), Vector3.new(-1.322,22.4,22.139), 0.2)
		Wind(Torso.CFrame * CFrame.new(0, -2, 0), Vector3.new(3.246, 15.301, 15.735), 0.2)
		Wind(Torso.CFrame * CFrame.new(0, -2, 0), Vector3.new(15.612, 2.69, 15.612), 0.2)

		AttackerVFX.Parent = Humanoid.RootPart
		Enable({AttackerVFX:GetDescendants()}, true)

		for _, Item in ipairs(Victim:GetChildren()) do
			if Item:IsA("BasePart") and Item.Name ~= "HumanoidRootPart" then
				Yuki_Skeleton(Item, 2)
			end
		end
	end

	if (Distance < 20) then
		NewJob:Task(Bubble(Torso, 6, Vector3.zero, Vector3.one * 25, 4))

		coroutine.wrap(Flash)({
			LifeTime = 2.25,
			Size = UDim2.fromScale(1.5, 1.5),
			Color = Color3.new(0, 0.666667, 1),

			TweenIn = {0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.In},
			TweenOut = {0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut},
			Transparency = 0.25,
		})

		InfinityShake = CameraShake(2, 35, 0.1, 0, Vector3.one * 0.8)

		if Player == AttackerPlayer or Player == Players:GetPlayerFromCharacter(Victim) then
			Yuki_FOV.Tween(40, {3})
		end
	end

	task.delay(0.05, function()
		if (Players.LocalPlayer:DistanceFromCharacter(Torso.Position) < 125) then 
			VictimVFX.Parent = Victim.Torso

			Lines.Size *= 2
			Lines.CFrame = Humanoid.RootPart.CFrame * CFrame.new(1, 0, -1)
			Lines.Parent = workspace.Visuals

			Enable({VictimVFX:GetDescendants(), Lines:GetDescendants()}, true)
		end
	end)
	
	local function Remove()
		NewJob:Clean()

		if (InfinityShake ~= nil) then
			InfinityShake:StartFadeOut(0.1)
		end
		
		task.delay(2, AttackerVFX.Destroy, AttackerVFX)
		task.delay(2, VictimVFX.Destroy, VictimVFX)
		task.delay(2, Lines.Destroy, Lines)
		
		Enable({AttackerVFX:GetDescendants(), VictimVFX:GetDescendants(), Lines:GetDescendants()}, false)
	end

	NewJob:Task(Replication.Destroying:Once(Remove))

	NewJob:Task(Replication:GetAttributeChangedSignal("GojoWallCombo"):Connect(function()
		if not Replication:GetAttribute("GojoWallCombo") then
			task.spawn(Remove)
		end
	end))
end

function VFX.Infinity(Character : Model, Victim : Model)
	local AttackerPlayer = Players:GetPlayerFromCharacter(Character)
	local Humanoid : Humanoid = Character:FindFirstChild("Humanoid") or Character:WaitForChild("Humanoid")
	local Torso : BasePart = Character:WaitForChild("Torso") -- animation offsets torso so it looks off when on root

	local NewJob = Job.new()
	
	local AttackerVFX = Assets.vfxFloor.FxGround:Clone()
	local VictimVFX = Assets.vfxVictim.VfxEnable:Clone()
	local Lines = Assets.Wallcombolines:Clone()

	local InfinityShake = nil
	
	local Replication : Configuration = AttributeListener.GetReplicationFromSource(AttackerPlayer)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Torso.Position)

	if (Distance < 125) then 
		Wind(Torso.CFrame * CFrame.new(0, -2, 0), Vector3.new(15.322,22.4,15.139), 0.2)
		Wind(Torso.CFrame * CFrame.new(0, -2, 0), Vector3.new(-1.322,22.4,22.139), 0.2)
		Wind(Torso.CFrame * CFrame.new(0, -2, 0), Vector3.new(3.246, 15.301, 15.735), 0.2)
		Wind(Torso.CFrame * CFrame.new(0, -2, 0), Vector3.new(15.612, 2.69, 15.612), 0.2)

		AttackerVFX.Parent = Humanoid.RootPart
		Enable({AttackerVFX:GetDescendants()}, true)
	end

	if (Distance < 20) then
		NewJob:Task(Bubble(Torso, 6, Vector3.zero, Vector3.one * 15, 4))

		coroutine.wrap(Flash)({
			LifeTime = 2.25,
			Size = UDim2.fromScale(1.5, 1.5),
			Color = Color3.new(0, 0.666667, 1),

			TweenIn = {0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.In},
			TweenOut = {0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut},
			Transparency = 0.25,
		})

		InfinityShake = CameraShake(2, 15, 0.1, 0, Vector3.one * 0.8)
	end

	task.delay(0.05, function()
		if (Players.LocalPlayer:DistanceFromCharacter(Torso.Position) < 125) then 
			VictimVFX.Parent = Victim.Torso

			Lines.CFrame = Humanoid.RootPart.CFrame * CFrame.new(1, 0, -1)
			Lines.Parent = workspace.Visuals

			Enable({VictimVFX:GetDescendants(), Lines:GetDescendants()}, true)
		end
	end)
	
	local function Remove()
		NewJob:Clean()

		if (InfinityShake ~= nil) then
			InfinityShake:StartFadeOut(0.1)
		end

		task.delay(2, AttackerVFX.Destroy, AttackerVFX)
		task.delay(2, VictimVFX.Destroy, VictimVFX)
		task.delay(2, Lines.Destroy, Lines)

		Enable({AttackerVFX:GetDescendants(), VictimVFX:GetDescendants(), Lines:GetDescendants()}, false)
	end

	NewJob:Task(Replication.Destroying:Once(Remove))

	NewJob:Task(Replication:GetAttributeChangedSignal("GojoWallCombo"):Connect(function()
		if not Replication:GetAttribute("GojoWallCombo") then
			task.spawn(Remove)
		end
	end))
end

function VFX.FinisherSplat(Character : Model, Victim : Model)
	local AttackerPlayer = Players:GetPlayerFromCharacter(Character)
	local Torso : BasePart = Character:WaitForChild("Torso") -- animation offsets torso so it looks off when on root

	for _, Item in ipairs(Victim:GetDescendants()) do
		if Item:IsA("BasePart") or Item:IsA("Decal") then
			Item.Transparency = 1
		end
	end
	
	if (Players.LocalPlayer:DistanceFromCharacter(Torso.Position) < 20) then
		CameraShake(2.5, 50, 0.1, 0.5, Vector3.one * 0.8)
	end
	
	if Player == AttackerPlayer or Player == Players:GetPlayerFromCharacter(Victim) then
		Yuki_FOV.Tween(120, {0.25, Enum.EasingStyle.Back})

		task.delay(0.4, function()
			Yuki_FOV.Tween(70, {1})
		end)
	end
	
	local LastDistance = Players.LocalPlayer:DistanceFromCharacter(Torso.Position)

	if (LastDistance < 75) then
		local CF = Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2)
		local Raycast = workspace:Raycast(CF.Position, Character.HumanoidRootPart.CFrame.LookVector * 10, Utility.VisualParams)

		if (Raycast ~= nil) then
			local Finisher = Assets.Finisher.VfxEmitEndFinisher:Clone()
			Finisher.WorldCFrame = CFrame.lookAt(Raycast.Position, Raycast.Position + Raycast.Normal)
			Finisher.Parent = workspace.Terrain
			EffectUtility.Emit(Finisher)

			Blood.BloodRaysWithoutPreset(Finisher, {Face = Enum.NormalId.Front, Power = 50, Amount = Vector2.new(25, 30), Spread = Vector2.new(75, 75), PoolSize = 3.5, PoolSizeRandom = Vector2.new(-0.5, 0.5), Color = Color3.fromRGB(48, 0, 1)})
		end
	end

	if (LastDistance < 50) then 
		for _, Item : BasePart in  Assets.ShatteredInfinity:GetChildren() do
			local ShatteredGlass = Item:Clone()
			ShatteredGlass.Size *= 1.2
			ShatteredGlass.CFrame = Torso.CFrame * CFrame.new(RNG:NextInteger(-7.5, 7.5), RNG:NextInteger(-2, 3), RNG:NextInteger(-5, 5))
			ShatteredGlass.Parent = workspace.Terrain

			ShatteredGlass.AssemblyLinearVelocity = ((ShatteredGlass.Position - Torso.Position).Unit * 50) / (ShatteredGlass.Position - Torso.Position).Magnitude
			ShatteredGlass.AssemblyAngularVelocity = Vector3.new(RNG:NextInteger(-100, 100), RNG:NextInteger(-100, 100), RNG:NextInteger(-100, 100))

			task.delay(3, function()
				ShatteredGlass.AssemblyLinearVelocity = Vector3.zero
				ShatteredGlass.AssemblyAngularVelocity = Vector3.zero

				ShatteredGlass.Anchored = true
				ShatteredGlass.CanCollide = false

				local DissapearTween = TweenService:Create(ShatteredGlass, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Size = Vector3.zero
				})

				DissapearTween:Play()

				DissapearTween.Completed:Once(function()
					ShatteredGlass:Destroy()
				end)
			end)
		end
	end
end

function VFX.Splat(Character : Model, Victim : Model)
	local Torso : BasePart = Character:WaitForChild("Torso") -- animation offsets torso so it looks off when on root
	local LastDistance = Players.LocalPlayer:DistanceFromCharacter(Torso.Position)

	if (LastDistance < 20) then
		CameraShake(3, 30, 0.1, 0.5, Vector3.one * 0.8)
	end

	if (LastDistance < 75) then
		local CF = Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2)
		
		local Direction = Character.HumanoidRootPart.CFrame.LookVector * 10
		local Raycast = workspace:Raycast(CF.Position, Direction, Utility.VisualParams)

		if (Raycast ~= nil) then
			coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
				Amount = 8,
				Distance = 6,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = -3,
					Max = -3
				},

				Exposure = {
					Min = 0.4,
					Max = 0.6
				},

				SizeMultiplier = 0.95,
			})

			coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
				Amount = 10,
				Distance = 7.5,
				SizeMultiplier = 1.15,
			})

			coroutine.wrap(RockHandler.Rockst)(Raycast.Position, Direction, {
				Count = 14,
				Size = {0.85, 1},
				Velocity = 35,
			})
			
			if Raycast.Instance.Size.X > 0.5 or  Raycast.Instance.Size.Z > 0.5 then
				EffectUtility.EmitEffects(Assets.WallComboEndStain, workspace.Terrain, CFrame.lookAt(Raycast.Position, Raycast.Position + Raycast.Normal) * CFrame.new(0, 0, -0.05))
			end
		end
	end

	if (LastDistance < 50) then 
		for _, Item : BasePart in  Assets.ShatteredInfinity:GetChildren() do
			local ShatteredGlass = Item:Clone()
			ShatteredGlass.CFrame = Torso.CFrame * CFrame.new(RNG:NextInteger(-7.5, 7.5), RNG:NextInteger(-2, 3), RNG:NextInteger(-5, 5))
			ShatteredGlass.Parent = workspace.Terrain

			ShatteredGlass.AssemblyLinearVelocity = ((ShatteredGlass.Position - Torso.Position).Unit * 50) / (ShatteredGlass.Position - Torso.Position).Magnitude
			ShatteredGlass.AssemblyAngularVelocity = Vector3.new(RNG:NextInteger(-100, 100), RNG:NextInteger(-100, 100), RNG:NextInteger(-100, 100))

			task.delay(3, function()
				ShatteredGlass.AssemblyLinearVelocity = Vector3.zero
				ShatteredGlass.AssemblyAngularVelocity = Vector3.zero

				ShatteredGlass.Anchored = true
				ShatteredGlass.CanCollide = false

				local DissapearTween = TweenService:Create(ShatteredGlass, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Size = Vector3.zero
				})

				DissapearTween:Play()

				DissapearTween.Completed:Once(function()
					ShatteredGlass:Destroy()
				end)
			end)
		end
	end
end

return VFX