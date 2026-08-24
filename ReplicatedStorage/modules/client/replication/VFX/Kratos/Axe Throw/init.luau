local VFX = {}

local Players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")

local Data = require( script.Data )

local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )

local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )
local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )

local LocalPlayer = Players.LocalPlayer

local AxeList = {}

function VFX.Create(Model : Model, StartCF : CFrame, Velocity : Vector3)
	if (AxeList[Model] ~= nil) then return end

	local MaxDistance = Data.MaxDistance
	local StartFallingAt =  Data.StartFallingAt
	local Gravity = Data.Gravity
	
	local CF = StartCF
	local RotCF = CFrame.identity

	if (LocalPlayer:DistanceFromCharacter(StartCF.Position) <= 15) then
		CameraShake(3, 25, 0.03, 0.4, Vector3.one * 0.8)
	end

	if LocalPlayer.Character == Model then
		Vignette(Color3.fromRGB(141, 189, 252), 0.9, 0.8)
	end

	local Spin = 35
	
	local Axe = script.Model:Clone()
	Axe.Name = `{Model.Name}'s Axe`
	Axe.CFrame = StartCF
	Axe.Parent = workspace.Visuals

	Axe["Axe Loop"]:Play()

	local ProjectileJob; ProjectileJob = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Axe, function(Delta : number)
		local DistanceFromStart = (StartCF.Position - CF.Position).Magnitude
		
		if DistanceFromStart > MaxDistance then
			Axe.CanCollide = true 
			Axe.Anchored = false

			Axe.AssemblyLinearVelocity = Velocity.Unit * 20
			
			return
		end

		local NewAxePosition = CF.Position + Velocity.Unit * (Velocity.Magnitude * Delta)
		local Raycast = workspace:Raycast(CF.Position, NewAxePosition - CF.Position, Utility.VisualParams)

		if Raycast and Raycast.Instance.CanCollide then
			ProjectileJob:Destroy()

			local Right = StartCF.RightVector
			local Up = Right:Cross(-Raycast.Normal).Unit

			Axe.CFrame = CFrame.fromMatrix(Raycast.Position, Right, Up) * CFrame.new(0, 0, 1.5) * CFrame.Angles(math.rad(35 + 180), 0, 0)
			
			if Axe then
				Axe["Axe Loop"]:Stop()
				Axe["Wall Hit"]:Play()
			end
			
			return
		end

		if DistanceFromStart > StartFallingAt then
			Velocity += Gravity * Delta
		end
		
		CF += Velocity * Delta
		
		Spin += 25 * (Delta * 60)
		Axe.CFrame = CF * CFrame.Angles(math.rad(Spin), 0, 0)
	end)

	AxeList[Model] = {
		Axe = Axe,
		ProjectileJob = ProjectileJob
	}

	local Remover : RBXScriptConnection; Remover = Model.AncestryChanged:Connect(function(_, Parent)
		if (Parent == nil) then
			Remover:Disconnect()
			VFX.Remove(Model)
		end
	end)

	Axe.Destroying:Once(function()
		Remover:Disconnect()
	end)
end

function VFX.Remove(Model : Model)
	local AxeTable = AxeList[Model]

	if AxeTable  then
		AxeTable.Axe:Destroy()
		AxeList[Model] = nil
	end
end

local function BezierInterpolation(Start : Vector3, Middle : Vector3, End : Vector3, Alpha : number)
	local L1 = Start:Lerp(Middle, Alpha)
	local L2 = Middle:Lerp(End, Alpha)
	return L1:Lerp(L2, Alpha)
end

function VFX.StickToVictim(Model : Model, Torso : BasePart, CustomOffset : CFrame?)
	local AxeTable = AxeList[Model]

	if AxeTable  then
		AxeTable.ProjectileJob:Destroy()
		
		-------------------------------------------------------
		
		local Axe : BasePart = AxeTable.Axe
		
		if (Axe and Axe.Parent ~= nil) then
			if CustomOffset then
				Axe.CFrame = Torso.CFrame * CustomOffset
			else
				Axe.CFrame = CFrame.lookAt(Torso.Position, Axe.Position) * CFrame.new(0, 0, -2) * CFrame.Angles(math.rad(35), 0, 0)
			end

			local Weld = Instance.new("WeldConstraint")
			Weld.Part0 = Axe
			Weld.Part1 = Torso

			Axe.Anchored = false
			Weld.Parent = Axe

			Torso.AncestryChanged:Connect(function(_, Parent) 
				if (Parent == nil) then
					Weld:Destroy()
					Axe.CanCollide = true
				end
			end)
			
			AxeTable.StickWeld = Weld
		end
	
		AxeTable.Sticked = true

		-------------------------------------------------------
		
		if (Axe and Axe.Parent ~= nil) then
			Axe["Axe Loop"]:Stop()
			Axe["Victim Hit"]:Play()
		end

		EffectUtility.EmitEffects(replicatedStorage.modules.effect.assets.Blood.SmallSplash, Axe)
		Blood.BloodRays("SpitOut", Axe)
	end
end

function VFX.Recall(Model : Model, Magnitude : number, Time : number, Trajectory : Vector3)
	local RootPart : BasePart = Model:FindFirstChild("HumanoidRootPart")
	
	if (RootPart == nil) then
		return VFX.Remove(Model)
	end
	
	local AxeTable = AxeList[Model]

	if AxeTable then
		AxeTable.ProjectileJob:Destroy()

		local Axe : BasePart = AxeTable.Axe
		
		if (Axe == nil or Axe.Parent == nil) then 
			return VFX.Remove(Model) 
		end
		
		Axe.Anchored = true
		Axe.CanCollide = false
		
		if AxeTable.StickWeld then
			AxeTable.StickWeld:Destroy()
			AxeTable.StickWeld = nil
		end

		if AxeTable.Sticked then
			Axe["Victim Hit"]:Play()
			EffectUtility.EmitEffects(replicatedStorage.modules.effect.assets.Blood.SmallSplash, workspace.Terrain, Axe.Position)
			Blood.BloodRays("SpitOut", Axe)
		end

		local Follow : Attachment = Model["Right Arm"].RightGripAttachment

		local StartPosition = Axe.Position
		local StartTime = tick()

		local Spin = 0
		local SpinAmount = math.clamp(Magnitude / 3, 5, 30)
		
		local RecallJob; RecallJob = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Axe, function(Delta : number)
			local Elapsed = (tick() - StartTime)
			local Alpha = math.clamp(Elapsed / Time, 0, 1)

			if (Alpha >= 1) then
				VFX.Remove(Model)

				if LocalPlayer == Players:GetPlayerFromCharacter(Model) then
					CameraShake(0.6, 10, 0.04, 0.4, Vector3.one * 0.8)
				end
				
				Axe.CFrame = Follow.WorldCFrame * CFrame.new(0, 0, -1) * CFrame.Angles(math.rad(35), 0, 0)
				task.delay(1 / 60, Axe.Destroy, Axe)
				
				if Axe and Axe:FindFirstChild("Axe Loop") then
					Axe["Axe Loop"]:Stop()
				end
				
				return
			end

			local EndPosition = (Follow.WorldCFrame * CFrame.new(0, 0, -1)).Position
			local MidPosition = (StartPosition + EndPosition) / 2 + RootPart.CFrame:VectorToWorldSpace(Trajectory)

			local NewPosition = BezierInterpolation(StartPosition, MidPosition, EndPosition, Alpha)

			Axe.CFrame = CFrame.lookAt(NewPosition, EndPosition) * CFrame.Angles(math.rad(Spin), 0, 0)
			Spin += SpinAmount * (Delta * 60)
		end)
		
		AxeTable.RecallJob = RecallJob
		
		if Axe then
			Axe["Axe Loop"]:Play()
		end
	end
end


--function VFX.PathfindingRecall(Model : Model, Waypoints : {PathWaypoint}, Target : Attachment, Time : number)
--	local Axe = AxeList[Model]

--	if Axe then
--		Axe.Anchored = true
--		Axe.CanCollide = false

--		for _, Waypoint in pairs(Waypoints) do
--			local Goal = Waypoint.Position

--			local Direction = (Goal - Axe.Position).Unit
--			local LookAtCFrame = CFrame.lookAlong(Axe.Position, Direction) * CFrame.Angles(math.rad(90), 0, 0)

--			-- Tween position movement
--			local positionTween = TweenService:Create(
--				Axe,
--				TweenInfo.new(Time, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
--				{Position = Goal + Vector3.yAxis * 4}
--			)

--			-- Tween rotation movement
--			local rotationTween = TweenService:Create(
--				Axe,
--				TweenInfo.new(Time, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
--				{CFrame = LookAtCFrame}
--			)

--			-- Start both tweens
--			positionTween:Play()
--			rotationTween:Play()

--			positionTween.Completed:Wait()
--		end

--		Axe.CFrame = Target.CFrame
--		Axe:Destroy()
--	end
--end


return VFX
