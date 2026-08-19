local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local RNG = Random.new()

local VFX = {}
local CurrentScuffedTrails = {}

local function RandomRotation()
	return Vector3.new(360*RNG:NextNumber(), 360*RNG:NextNumber(), 360*RNG:NextNumber())
end

local function CastRay(Origin: Vector3, Direction : Vector3)
	local GroundRay = workspace:Raycast(Origin, Direction or Vector3.yAxis * -8, Utility.VisualParams);
	if not GroundRay then return end;

	return table.freeze({
		Position = GroundRay.Position :: Vector3;
		Normal = GroundRay.Normal :: Vector3;
		Color = GroundRay.Instance.Color :: Color3;
		Material = GroundRay.Instance.Material :: Enum.Material;
		Instance = GroundRay.Instance :: BasePart,
		Transparency = GroundRay.Instance.Transparency :: number,
		Raw = GroundRay;
	});
end;

local function ScuffedRockTrailBegin(UID : string, AttachPart : BasePart | Attachment, Data : {[string] : any})
	if not table.find(CurrentScuffedTrails, UID) then
		table.insert(CurrentScuffedTrails, UID)
	end

	repeat
		for Index = 1, 3 do
			local NewRay = CastRay(AttachPart.Position, AttachPart.CFrame[Data.Side] * Data.Direction)
			if NewRay == nil then continue end

			local Rock = Instance.new("Part")
			Rock.CFrame = CFrame.new(NewRay.Position) * CFrame.new(Utility.Seed:NextNumber(-1, 1), Utility.Seed:NextNumber(-1, 1), 0) * CFrame.fromEulerAnglesXYZ(math.random(-45,45),math.random(-45,45),math.random(-45,45))
			Rock.Size = Vector3.zero
			Rock.Material = NewRay.Material
			Rock.Color = NewRay.Instance.Color
			Rock.BottomSurface = Enum.SurfaceType.Smooth
			Rock.TopSurface = Enum.SurfaceType.Smooth
			Rock.Anchored = true
			Rock.CanTouch = false
			Rock.CanQuery = false
			Rock.CanCollide = false
			Rock.Parent = workspace.Visuals

			for _, Image in next, NewRay.Instance:GetChildren() do
				if not Image:IsA("Decal") or not Image:IsA("Texture") then
					continue
				end

				Image:Clone().Parent = Rock
			end

			TweenService:Create(Rock,TweenInfo.new(0.3), {
				Size = Vector3.one * RNG:NextNumber(Data.MinimumSize, Data.MaximumSize)
			}):Play()

			task.delay(1, function()
				TweenService:Create(Rock, TweenInfo.new(0.3), {
					Size = Vector3.zero
				}):Play()

				task.delay(0.6, Rock.Destroy, Rock)
			end)

			local FallingRock = Rock:Clone()
			FallingRock.CanCollide = true
			FallingRock.Anchored = false

			local BodyVelocity = Instance.new("BodyVelocity")
			BodyVelocity.MaxForce = Vector3.one * 800000
			BodyVelocity.Velocity = NewRay.Normal * 17.5
			BodyVelocity.Parent = FallingRock

			task.delay(0.1, BodyVelocity.Destroy, BodyVelocity)

			task.delay(1, function()
				TweenService:Create(FallingRock, TweenInfo.new(0.3),{
					Size = Vector3.zero
				}):Play()

				task.delay(0.6, FallingRock.Destroy, FallingRock)
			end)
		end

		task.wait(Data.DebounceTime)
	until not AttachPart:IsDescendantOf(workspace) or not table.find(CurrentScuffedTrails, UID)
end

local function ScuffedRockTrailEnd(UID)
	if not table.find(CurrentScuffedTrails, UID) then
		return
	end

	table.remove(CurrentScuffedTrails, table.find(CurrentScuffedTrails, UID))
end

function VFX.Slam(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.assets.slam, RootPart)
	
	if Players.LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25 then
		CameraShake(2, 20, 0.1, 0.3, Vector3.one * 0.8, Vector3.one * 0.35)
		Vignette(Color3.fromRGB(140, 0, 255), 0.75, 0.3)
	end
end

function VFX.Land(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.assets.land, RootPart)
	
	if Players.LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25 then
		CameraShake(1, 10, 0.1, 0.1, Vector3.one * 0.8, Vector3.one * 0.35)
	end
end

function VFX.Launch(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.assets.land, RootPart)
end

function VFX.Throw(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.assets.throw, RootPart)
	
	if Players.LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25 then
		CameraShake(2, 20, 0.1, 0.3, Vector3.one * 0.8, Vector3.one * 0.35)
	end
end

function VFX.Tp(Torso : BasePart)
	EffectUtility.CloneAndEmit(script.assets.tp, Torso)
end

function VFX.RunVFX(RootPart : BasePart)
	local Replication = AttributeListener.GetReplicationFromSource(RootPart)

	if not Replication:GetAttribute("AcceleratorWallCombo") then
		return
	end
	
	local RemoveConnection : RBXScriptConnection
	
	local Effect = script.assets.run:Clone()
	Effect.Parent = RootPart
	EffectUtility.Toggle(Effect, true)
	
	local Ended = false
	
	task.spawn(function()
		while not Ended do
			if Players.LocalPlayer:DistanceFromCharacter(RootPart.Position) > 25 then return end
			
			CameraShake(1, 30, 0.1, 0.1, Vector3.one * 0.8, Vector3.one * 0.1)
			Vignette(Color3.fromRGB(140, 0, 255), 0.8, 0.15)
			
			task.wait(0.1)
		end
	end)

	RemoveConnection = Replication:GetAttributeChangedSignal("AcceleratorWallCombo"):Connect(function()
		if not Replication:GetAttribute("AcceleratorWallCombo") then
			Ended = true
			
			EffectUtility.Toggle(Effect, false)
			task.delay(1, Effect.Destroy, Effect)
		end
	end)
end

function VFX.RunVelocity(RootPart : BasePart)
	local Replication = AttributeListener.GetReplicationFromSource(RootPart)
	
	if not Replication:GetAttribute("AcceleratorWallCombo") then
		return
	end
	
	local Push = Instance.new("BodyVelocity")
	Push.MaxForce = Vector3.new(1, 0, 1) * 80000
	Push.Parent = RootPart
	
	local Gyro = Instance.new("BodyGyro")
	Gyro.MaxTorque = Vector3.one * 100000
	Gyro.P = 5000
	Gyro.CFrame = RootPart.CFrame
	Gyro.Parent = RootPart

	local Start = os.clock()
	local Power = 0

	local RemoveConnection : RBXScriptConnection
	local VelocityLoop : RBXScriptConnection
	
	VelocityLoop = RunService.PostSimulation:Connect(function(Delta)
		if (Push.Parent == nil) then
			return
		end
		
		Power = math.min(45, Power + 1.5 * (Delta * 60))
		Push.Velocity = -RootPart.CFrame.RightVector * Power
	end)

	Push.Destroying:Connect(function()
		RemoveConnection:Disconnect()
		VelocityLoop:Disconnect()
		Gyro:Destroy()
	end)
	
	RemoveConnection = Replication:GetAttributeChangedSignal("AcceleratorWallCombo"):Connect(function()
		if not Replication:GetAttribute("AcceleratorWallCombo") then
			Push:Destroy()
		end
	end)
end

--function VFX.RunOthers(RootPart : BasePart, VictimHead : BasePart)
--	local Player = Players:GetPlayerFromCharacter(RootPart.Parent)
--	local Replication = workspace.PlayerReplication[Player.Name]

--	if not Replication:GetAttribute("AcceleratorWallCombo") then
--		return
--	end
	
--	local Loop : RBXScriptConnection
--	local RemoveConnection : RBXScriptConnection
	
--	task.spawn(ScuffedRockTrailBegin, "Main", VictimHead, {
--		Side = "LookVector",
--		Direction = -3,
--		MinimumSize = 0.5,
--		MaximumSize = 0.85,
--		DebounceTime = 0.03,
--		LifeTime = 0.75,
--		Fall = true,
--		FallDuration = 0,
--	})

--	local function Remove()
--		Loop:Disconnect()
--		RemoveConnection:Disconnect()
--		ScuffedRockTrailEnd("Main")
--	end
	
--	local Start = os.clock()
--	local Power = 0
--	local Step = 1
	
--	Loop = RunService.PostSimulation:Connect(function(Delta)
--		Step += 1

--		local Interval = math.max(1, math.floor(250 / Power))

--		if (Step % Interval == 0) then
--			CameraShake(0.75, 5, 0.1, 0.2)

--			if LocalPlayer:GetAttribute("Blood") then
--				EffectUtility.EmitEffects(ReplicatedStorage.Effects.Blood.SmallSplash, VictimHead)
--			end

--			Blood.BloodRaysWithoutPreset(VictimHead, {
--				Face = Enum.NormalId.Front,
--				Amount = Vector2.new(1, 2),
--				PoolSize = 0.8,
--				PoolSizeRandom = Vector2.new(-0.35, 0.35),
--			})
--		end
		
--		Power = math.min(45, Power + 0.5 * (Delta * 60))
--	end)
	
--	RemoveConnection = Replication:GetAttributeChangedSignal("AcceleratorWallCombo"):Connect(function()
--		if not Replication:GetAttribute("AcceleratorWallCombo") then
--			Remove()
--		end
--	end)
--end

return VFX