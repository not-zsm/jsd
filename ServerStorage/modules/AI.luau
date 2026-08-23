--!native



local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )
local EventService = require( ReplicatedStorage.Shared.Utilities.EventService )

local LuaPlayerList = require( ServerStorage.modules.LuaPlayerList )

local Time = require(script.Time)

local Default_Info = require(script.Default)
local Detection = require(script.Detection)

----------------------------------------------

local Entity = {}
Entity.__index = Entity

local Main = {}
local List = {} :: {[Entity] : boolean}

function Main.new(LuaCharacter : {}, Info : Default_Info.Type)
	assert(Info, "No info table was provided.")
	setmetatable(Info, Default_Info)

	local self = {}
	setmetatable(self, Entity)

	self.Info = Info

	self.LuaCharacter = LuaCharacter :: {}
	self.Combat = LuaCharacter.Combat :: {}

	self.Humanoid = self.LuaCharacter.Humanoid :: Humanoid
	self.RootPart = self.LuaCharacter.RootPart :: BasePart
	self.Character = self.LuaCharacter.Model :: Model

	self.Target = nil :: {}?
	self.TargetSighted = false
	self.CanTarget = true

	self.Time = Time.new()
	self.Moves = Time.new()

	---------------------------

	self.IsPathing = false
	self.IsPatrolling = false
	self.IsRunning = false

	self.AverageVelocity = 0
	self.Step = 0
	self.GyroRotationalOffset = 0
	self.CurrentTargetCount = 0

	self.OnTargetFrame = EventService.new()
	self.OnTargetFound = EventService.new()
	self.OnTargetSwitched = EventService.new()
	self.OnTargetChanged = EventService.new()
	self.OnTargetLost = EventService.new()
	self.OnTargetDied = EventService.new()

	self.OnRunningBegin = EventService.new()
	self.OnRunningEnded = EventService.new()

	self.OnPatrolBegin = EventService.new()
	self.OnPatrolEnded = EventService.new()

	self.CancelPathEvent = EventService.new()
	self.OnPathingStateChanged = EventService.new()
	self.OnPathingEnded = EventService.new()

	self.OnMoveBegin = EventService.new()

	local v = Random.new():NextUnitVector() do
		self.Debug_Color = Color3.new(math.abs(v.x), math.abs(v.y), math.abs(v.z))
	end

	---------------------------

	self.Path_Object = PathfindingService:CreatePath({
		AgentRadius = self.Info.AgentRadius,
		AgentHeight = self.Info.AgentHeight,
		AgentCanJump = self.Info.AgentCanJump,
		AgentCanClimb = self.Info.AgentCanClimb,
		--WaypointSpacing = self.Info.AgentWaypointSpacing
	}) :: Path

	self.Seeker = Detection.new(self.RootPart, {
		Range = self.Info.Range,
		ListSorting = self.Info.TargetSorting,
		Ignore = {self.Character}
	})

	self.AlignRotation = script.Assets.AlignOrientation:Clone()
	self.AlignRotation.Attachment0 = self.LuaCharacter.RootAttachment
	self.AlignRotation.Name = "Rotator"
	
	self.RotationResponsiveness = self.AlignRotation.Responsiveness
	
	self.AlignRotation.Parent = self.RootPart

	self.LuaCharacter.OnHumanoidAvailabilityChanged:Connect(function(Value : boolean)
		if not Value then
			self:Disable()

			self.AlignRotation.Enabled = false
			self:SetTarget(nil)
		end
	end)

	self:Enable()

	return self
end

export type Entity = typeof(Main.new(...))

----------------------------------------------

function Entity.ClearDebugWaypoints(self : Entity)
	if self.Debug_Waypoints then
		for _, Part : BasePart in ipairs(self.Debug_Waypoints) do
			Part:Destroy()
		end

		table.clear(self.Debug_Waypoints)
	end
end


function Entity.SetDebugWaypoints(self : Entity, Waypoints : {PathWaypoint}) : {BasePart}
	self:ClearDebugWaypoints()
	self.Debug_Waypoints = {}

	for _, Waypoint in ipairs(Waypoints) do
		local Point = Instance.new("Part")
		Point.Color = self.Debug_Color;
		Point.Size = Vector3.one * 0.25
		Point.Material = Enum.Material.Neon
		Point.Anchored = true
		Point.CanCollide = false
		Point.Position = Waypoint.Position
		Point.Parent = workspace

		table.insert(self.Debug_Waypoints, Point)
	end
end

----------------------------------------------

function Entity.CancelPathing(self : Entity)
	self.CancelPathEvent:Fire()
end


function Entity.SetPathing(self : Entity, Value : boolean)
	local Last_Value = self.IsPathing
	self.IsPathing = Value

	if (Last_Value ~= Value) then
		self.OnPathingStateChanged:Fire()
	end
end


function Entity.PathTo(self : Entity, Destination : Vector3) : boolean
	self:SetPathing(true)
	self.Time.History.PathingStarted = time()

	local Success, Error = pcall(self.Path_Object.ComputeAsync, self.Path_Object, self.RootPart.Position, Destination)

	if (Success and self.Path_Object.Status == Enum.PathStatus.Success) then
		local Waypoints : {PathWaypoint} = self.Path_Object:GetWaypoints()

		if self.Info.DebugMode then
			self:SetDebugWaypoints(Waypoints)
		end

		local ThisIndex = 1

		local MoveToConnection : RBXScriptConnection
		local BlockedConnection : RBXScriptConnection
		local SeizeConnection : RBXScriptConnection

		local function End()
			MoveToConnection:Disconnect()
			BlockedConnection:Disconnect()
			SeizeConnection:Disconnect()

			if self.Info.UseAntiSticking then
				local Next = Waypoints[ThisIndex + 1]

				if (Next and self.AverageVelocity < 0.25) and not self.Combat:GetState("Ragdolled") then
					self.Character:TranslateBy((Next.Position - self.RootPart.Position))
				end
			end

			self.OnPathingEnded:Fire()
			self:SetPathing(false)
		end

		local function Move(Reached)
			if Reached and ThisIndex < #Waypoints then
				ThisIndex += 1

				if Waypoints[ThisIndex].Action == Enum.PathWaypointAction.Jump then
					self.Humanoid.Jump = true
				end

				self.Humanoid:MoveTo(Waypoints[ThisIndex].Position)
			else
				End()
			end
		end

		MoveToConnection = self.Humanoid.MoveToFinished:Connect(Move)

		BlockedConnection = self.Path_Object.Blocked:Connect(function(Index)
			if Index >= ThisIndex then
				End()

				self:PathTo(Destination)
			end
		end)

		SeizeConnection = self.CancelPathEvent:Connect(End)

		if (Waypoints[1].Position.Y > self.RootPart.Position.Y - 0.5) and not self.Combat:GetState("Ragdolled") then
			self.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end

		Move(true)

		return true
	else
		self:SetPathing(false)
	end

	return false
end


function Entity.CancelPatrol(self : Entity)
	if self.IsPatrolling then
		self.IsPatrolling = false
		self.OnPatrolEnded:Fire()
	end
end


function Entity.Patrol(self : Entity)
	if not self.IsPathing then
		local PatrolPoints : {Vector3} = self.PatrolPoints or self.Info.PatrolPoints
		local RootPosition : Vector3 = self.RootPart.Position
		local Position : Vector3

		if (#PatrolPoints ~= 0) then
			local InRange = self:GetPatrolPointsInRange(RootPosition)

			if (#InRange > 0) then
				Position = InRange[math.random(1, #InRange)]
			else
				Position = PatrolPoints[math.random(#PatrolPoints)]
			end
		else
			Position = RootPosition + Random.new():NextUnitVector() * Vector3.new(1, 0, 1) * self.Info.PatrolRange
		end

		if not Position then
			return
		end

		if not self.IsPatrolling then
			self.IsPatrolling = true
			self.OnPatrolBegin:Fire()
		end

		local Success = self:PathTo(Position)

		if Success then
			self.OnPathingEnded:Wait()

			self.Time.Next.PatrolIdlePeriod = Utility.NumberRangeRandom(self.Info.PatrolIdlePeriod)
			self.Time.History.LastPatrol = time()
		end
	end
end


function Entity.GetPatrolPointsInRange(self : Entity, Position : Vector3) : {Vector3}
	local InRange = {}

	for _, Point : Vector3 in ipairs(self.PatrolPoints or self.Info.PatrolPoints) do
		if (Point - Position).Magnitude < self.Info.PatrolRange then
			table.insert(InRange, Point)
		end
	end

	return InRange
end

function Entity.SetPatrolPoints(self : Entity, List : {Vector3})
	self.PatrolPoints = List
end

----------------------------------------------

function Entity.SetTarget(self : Entity, Target : {}?)
	local Last_Target = self.Target

	if Target ~= Last_Target then

		--print("new target:", Target)

		self.Target = Target
		self.OnTargetChanged:Fire(Target, Last_Target)
		self.Time.History.TargetLastChanged = time()
		self.AverageVelocity = 16

		if (Last_Target ~= nil and (not Last_Target.Character.HumanoidAlive and Last_Target.Character.HumanoidExists)) then --Last_Target.Character.Humanoid.Health <= 0.1) then
			--warn("last target dead")
			
			self.Time.History.TargetLastSighted = nil
			self.OnTargetDied:Fire(Last_Target)
		end

		if (Last_Target == nil) then
			self.OnTargetFound:Fire(Target)

			if self.TargetDeadConnection then
				self.TargetDeadConnection:Disconnect()
				self.TargetDeadConnection = nil

				--print("disconnected target died")
			end

			self.TargetDeadConnection = Target.Character.OnHumanoidDied:Connect(function()
				--warn("target dead")

				self.Time.History.TargetLastSighted = nil
				self.OnTargetDied:Fire(Target)
			end)

			--print("connected to target died")

		elseif (Target == nil) then
			self.OnTargetLost:Fire(Last_Target)
		else
			self.OnTargetSwitched:Fire(Target, Last_Target)
		end
	end
end


function Entity.HasTarget(self : Entity) : boolean
	return (self.Target and self.Target.Character.HumanoidAlive) or false
end


function Entity.IsTargetRagdolled(self : Entity) : boolean
	return (self:HasTarget() and self.Target.Character.Combat:GetState("Ragdolled") or false)
end


function Entity.IsTargetAttacking(self : Entity) : boolean
	return (self:HasTarget() and self.Target.Character.Combat:GetState("Attacking") or false)
end


function Entity.IsTargetViolent(self : Entity) : boolean
	return self:IsTargetAttacking() or self.Target.Character.Combat:GetState("M1ing")
end


function Entity.DistanceFromPoint(self : Entity, Position : (Vector3)) : number
	return (Position - self.RootPart.Position).Magnitude
end


function Entity.DistanceFromTarget(self : Entity) : number
	--return self:DistanceFromPoint(self.Target.Character.RootPart.Position)
	local TargetRoot : BasePart = self.Target.Character.Combat:GetSimulatedRoot()

	return self:DistanceFromPoint(TargetRoot.Position)
end


function Entity.GetTargetPosition(self : Entity) : Vector3
	--local TargetPosition : BasePart = self.Target.Character.RootPart.Position
	local TargetRoot : BasePart = self.Target.Character.Combat:GetSimulatedRoot()
	local TargetPosition = TargetRoot.Position

	return (TargetPosition) - (TargetPosition - self.RootPart.Position).Unit * self.Info.TargetDistancing
end


function Entity.HasSightOfLuaPlayer(self : Entity, Target : {})
	local Humanoid = self.Humanoid

	local RootPosition = Humanoid.RootPart.Position
	local TargetPosition = Target.Character.RootPart.Position

	local Direction = (TargetPosition - RootPosition)

	local Raycast = workspace:Raycast(RootPosition, Direction - Direction.Unit, Utility.VisualParams)
	
	--if Raycast then
	--	print(Raycast.Instance)
	--end
	
	return (Raycast == nil or not Raycast.Instance.CanCollide)
end

--- (Vector3.yAxis * 1.5)

function Entity.HasSightOfTarget(self : Entity) : boolean
	local HasSight = self:HasSightOfLuaPlayer(self.Target)
	self.TargetSighted = HasSight

	if HasSight then
		self.Time.History.TargetLastSighted = time()
	else
		self.Time.History.TargetLastHidden = time()
	end

	return HasSight
end


function Entity.GetCooldown(self : Entity, Move)
	return Utility.NumberRangeRandom(Move.Cooldown)
end


function Entity._AddCooldown(self : Entity, Index, Cooldown)
	self.Moves.History[Index] = time()
	self.Moves.Next[Index] = Cooldown
end


function Entity._RemoveCooldown(self : Entity, Index)
	self.Moves.History[Index] = nil
	self.Moves.Next[Index] = nil
end


function Entity.AddCooldownsTo(self : Entity, Name, Cooldown)
	for Index, Move in ipairs(self.Info.MoveProcedures) do
		if (Move.Name == Name) then
			self:_AddCooldown(Index, Cooldown)
		end
	end
end


function Entity.RemoveCooldownTo(self : Entity, Name)
	for Index, Move in ipairs(self.Info.MoveProcedures) do
		if (Move.Name == Name) then
			self:_RemoveCooldown(Index)
		end
	end
end

----------------------------------------------

--function Entity.RefreshTargetSight(self : Entity)
--	if (self.Target ~= nil and not self.Target.Character.HumanoidAlive) then
--		self.Time.History.TargetLastSighted = nil
--	end
--end

function Entity._AttemptMove(self : Entity, Index, Move, TargetDistance, HasTarget)
	if Utility.BeyondTime(self.Moves.History[Index], self.Moves.Next[Index]) then

		if (not Move.Target or HasTarget and Utility.XOR(Move.Target.InverseRange, Utility.BetweenNumberRange(Move.Target.Range, TargetDistance)) and (not Move.Target.RequiresSight or self.TargetSighted)) and (not Move.Condition or Move.Condition(self)) then

			if (Move.Cooldown ~= nil) then
				self:_AddCooldown(Index, self:GetCooldown(Move))
			end

			self.OnMoveBegin:Fire(Move)
		end
	end
end


function Entity.TryMoveProcedures(self : Entity)
	local HasTarget = self:HasTarget()
	local TargetDistance = HasTarget and self:DistanceFromTarget()

	local RandomOrders = {}

	for Index, Move in ipairs(self.Info.MoveProcedures) do
		if (Move.RandomOrder == true) then
			local Next = self.Info.MoveProcedures[Index + 1]

			table.insert(RandomOrders, Move)

			if (Next == nil or Next.RandomOrder ~= true) then
				local Choice = math.random(1, #RandomOrders)
				self:_AttemptMove(Index - Choice + 1, RandomOrders[Choice], TargetDistance, HasTarget)

				table.clear(RandomOrders)
			end

		else
			self:_AttemptMove(Index, Move, TargetDistance, HasTarget)
		end
	end
end


function Entity._Simulate(self : Entity)
	if self.RootPart:CanSetNetworkOwnership() then
		self.RootPart:SetNetworkOwner(nil)
	end

	self.AverageVelocity = math.lerp(self.AverageVelocity, self.RootPart.Velocity.Magnitude, 0.05)

	if self.RootPart.AssemblyLinearVelocity.Magnitude > 2 then
		if not self.IsRunning then
			self.IsRunning = true
			self.OnRunningBegin:Fire()
		end

		self.Time.History.LastRunning = time()

	elseif self.IsRunning then
		self.IsRunning = false
		self.OnRunningEnded:Fire()
	end

	if self.LuaCharacter.HumanoidAlive then
		local List, Count = self.Seeker:Detect()
		local Target = List[1]

		self.CurrentTargetCount = Count

		if not self.CanTarget or (Count == 0) or (self.Info.OnlyPathWithTargetSight and not self:HasSightOfLuaPlayer(Target) and Utility.BeyondTime(self.Time.History.TargetLastSighted, self.Info.DisengageAfterSightLost)) then
			self:SetTarget(nil)

			if Utility.BeyondTime(self.Time.History.LastPatrol, self.Time.Next.PatrolIdlePeriod) then
				self:Patrol()
			end
		else
			self:SetTarget(Target)
			self:TargetFrame(Target)
		end
	end

	if (not self:HasTarget() or not self.TargetSighted) or (self.Combat:GetState("Ragdolled") or self.Combat:GetState("Grabbing")) then
		self.AlignRotation.Enabled = false

		if self.NoRotator then
			self.NoRotator:Destroy()
			self.NoRotator = nil
		end
	else
		self.AlignRotation.Enabled = true
	end

	if self.LuaCharacter.HumanoidAlive then
		self:TryMoveProcedures()
	end
end


function Entity.TargetFrame(self : Entity, Target : Humanoid?)
	self.OnTargetFrame:Fire(Target)

	local TH, TN, Info = self.Time.History, self.Time.Next, self.Info
	local Position = self:GetTargetPosition()

	if not self:HasSightOfTarget() then

		if Info.OnlyPathWithTargetSight and Utility.BeyondTime(TH.TargetLastSighted, Info.DisengageAfterSightLost) then

			if Utility.BeyondTime(TH.LastPatrol, TN.PatrolIdlePeriod) then
				self:Patrol()
			end
		else
			if Utility.BeyondTime(TH.PathingStarted, Info.RepathingDelay) and Utility.BeyondTime(TH.TargetLastSighted, Info.StartPathingAfterSightLostThreshold) then
				self:CancelPatrol()

				if self.IsPathing then
					self:CancelPathing()
				end

				self:PathTo(Position)
			end
		end

	elseif not self.IsPathing or Utility.BeyondTime(TH.TargetLastHidden, Info.ChargeTowardTargetThreshold) then
		self:CancelPatrol()

		if self.IsPathing then
			self:CancelPathing()
		end

		local TargetRoot : BasePart = self.Target.Character.Combat:GetSimulatedRoot()
		local P, V = self.RootPart.Position, TargetRoot.Position--self.Target.Character.RootPart.Position

		if (self.NoRotator == nil) then
			self.NoRotator = self.LuaCharacter:StopAutoRotate()
		end

		if self.AlignRotation.Enabled then
			self.AlignRotation.CFrame = CFrame.Angles(0, math.atan2(P.X - V.X, P.Z - V.Z) + math.rad(self.GyroRotationalOffset), 0)
		end

		self.Humanoid:MoveTo(Position, TargetRoot)--self.Target.Character.RootPart)
	end
end


function Entity.SetGyroRotationOffset(self : Entity, Value : number, Duration : number?)
	if self.GyroRotationOffsetResetThread and coroutine.status(self.GyroRotationOffsetResetThread) == "suspended" then
		task.cancel(self.GyroRotationOffsetResetThread)
		self.GyroRotationOffsetResetThread = nil
	end

	self.GyroRotationalOffset = Value

	if (Duration ~= nil) then
		self.GyroRotationOffsetResetThread = task.delay(Duration, function()
			self.GyroRotationOffsetResetThread = nil
			self.GyroRotationalOffset = 0
		end)
	end
end

function Entity.SetGyroRotationResponsiveness(self : Entity, Value : number)
	if self.AlignRotation then
		self.AlignRotation.Responsiveness = Value
	end
end

function Entity.ResetGyroRotationResponsiveness(self : Entity)
	if self.AlignRotation then
		self.AlignRotation.Responsiveness = self.RotationResponsiveness
	end
end

function Entity.Disable(self : Entity)
	List[self] = nil
end


function Entity.Enable(self : Entity)
	List[self] = true
end


function Entity.Destroy(self : Entity)
	self:Disable()

	self.OnTargetFrame:Destroy()
	self.OnTargetFound:Destroy()
	self.OnTargetSwitched:Destroy()
	self.OnTargetChanged:Destroy()
	self.OnTargetLost:Destroy()
	self.OnTargetDied:Destroy()

	self.OnRunningBegin:Destroy()
	self.OnRunningEnded:Destroy()

	self.OnPatrolBegin:Destroy()
	self.OnPatrolEnded:Destroy()

	self.CancelPathEvent:Destroy()
	self.OnPathingStateChanged:Destroy()
	self.OnPathingEnded:Destroy()

	self.OnMoveBegin:Destroy()

	self.Path_Object:Destroy()
	self.Seeker:Destroy()

	table.clear(self)
	setmetatable(self, nil)
end

----------------------------------------------

RunService.PostSimulation:Connect(function()
	for self : Entity in List do
		self:_Simulate()
	end
end)

----------------------------------------------

return Main