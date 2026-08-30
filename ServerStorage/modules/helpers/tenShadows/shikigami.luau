local PathfindingService = game:GetService("PathfindingService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local Job = require( replicatedStorage.modules.shared.Utilities.Job )

local Extra = replicatedStorage.ass_sets.Miscellaneous

local FLAT = Vector3.new(1, 0, 1)

----------------------------------------------------------------------------------

local Specs = {
	bunny = {
		Animations = Extra.bunny,
		Offset = CFrame.new(0, -2.5, -5),

		Speed = 16,

		CatchUp = 2.25,
		TurnSpeed = 11,

		HipHeight = 0.45,

		StepHeight = 2.5,
		GroundReach = 500,
		ClimbSpeed = 30,
		FallSpeed = 60,

		FollowDistance = 7,
		StopDistance = 3,
		LeashDistance = 100,

		RoamRange = 5.5,
		RoamIdle = NumberRange.new(1.5, 4),

		Tick = 0.12,
		Reached = 1.5,
		WalkTimeout = 6,

		StillBeforeIdle = 0.2,

		StuckStep = 0.35,
		StuckTicks = 6,

		HopHeight = 3,
		HopMinTime = 0.28,
		HopMaxTime = 0.7,

		AgentParams = {
			AgentRadius = 1.5,
			AgentHeight = 2,
			AgentCanJump = true,
			AgentCanClimb = true,
			WaypointSpacing = 6,
		},

		Prompt = {
			Part = "head",
			ActionText = "Pet",
			ObjectText = "Bunny",
			KeyCode = Enum.KeyCode.E,
			HoldDuration = 0.35,
			MaxActivationDistance = 3.5,
			RequiresLineOfSight = false,
			OwnerOnly = false,
		},
	},
}

----------------------------------------------------------------------------------

local Shikigami = {}
Shikigami.__index = Shikigami

function Shikigami.Spec(Name : string)
	return Specs[Name]
end

function Shikigami.new(Name : string, Owner : {}, Model : Model)
	local Spec = Specs[Name]

	if (Spec == nil) then
		return warn(`shikigami: no spec named {Name}`)
	end

	local self = setmetatable({}, Shikigami)

	self.Name = Name
	self.Spec = Spec
	self.Owner = Owner
	self.Model = Model

	self.Job = Job.new()
	self.Active = true

	self.Goal = nil :: Vector3?
	self.Chase = nil :: BasePart?
	self.Hop = nil :: {}?

	self.Moving = false
	self.Still = 0
	self.Busy = false
	self.Emoting = false

	self.Root = Model:FindFirstChild("HumanoidRootPart")

	if (self.Root == nil) then
		self:Destroy()
		return warn(`shikigami: {Name} has no HumanoidRootPart`)
	end

	self:_PrepareRig()
	self:_LoadAnimations()
	self:_CreatePrompt()
	self:_BindOwnerEmoting()

	self.Job:Task(RunService.PostSimulation:Connect(function(DeltaTime : number)
		self:_Step(DeltaTime)
	end))

	self.Job:Task(Owner.OnHumanoidAvailabilityChanged:Connect(function(Available : boolean)
		if not Available then
			self:Destroy()
		end
	end))

	self.Thread = task.spawn(self._Behaviour, self)

	return self
end

----------------------------------------------------------------------------------

function Shikigami:_PrepareRig()
	for _, Part in self.Model:GetDescendants() do
		if not Part:IsA("BasePart") then continue end

		Part.CanCollide = false
		Part.CanTouch = false

		Part.CanQuery = false
	end

	self.Root.Anchored = true
end

function Shikigami:_LoadAnimations()
	local Controller = self.Model:FindFirstChildWhichIsA("AnimationController")
	local Animator = Controller and Controller:FindFirstChildWhichIsA("Animator")

	self.Tracks = {}

	if (Animator == nil) then
		return warn(`shikigami: {self.Name} has no Animator`)
	end

	for _, Animation in self.Spec.Animations:GetChildren() do
		if not Animation:IsA("Animation") then continue end

		local Track = Animator:LoadAnimation(Animation)
		Track.Priority = Enum.AnimationPriority.Movement

		self.Tracks[Animation.Name] = self.Job:Task(Track)
	end

	if self.Tracks.idle then
		self.Tracks.idle.Looped = true
		self.Tracks.idle:Play(0.2)
	end

	if self.Tracks.walk then
		self.Tracks.walk.Looped = true
	end

	if self.Tracks.pet then
		self.Tracks.pet.Priority = Enum.AnimationPriority.Action
		self.Tracks.pet.Looped = false
	end

	if self.Tracks.dance then
		local Dance = self.Tracks.dance

		Dance.Priority = Enum.AnimationPriority.Action
		Dance.Looped = true

		self.Job:Task(Dance.Stopped:Connect(function()
			if self.Active and self.Emoting and not self.Busy then
				Dance:Play(0.1)
			end
		end))
	end
end

function Shikigami:_CreatePrompt()
	local Info = self.Spec.Prompt

	if (Info == nil) then return end

	local Part = self.Model:FindFirstChild(Info.Part, true)

	if not (Part and Part:IsA("BasePart")) then
		return warn(`shikigami: {self.Name} has no {Info.Part} to hang a prompt on`)
	end

	local Prompt = Instance.new("ProximityPrompt")
	Prompt.ActionText = Info.ActionText
	Prompt.ObjectText = Info.ObjectText
	Prompt.KeyboardKeyCode = Info.KeyCode
	Prompt.HoldDuration = Info.HoldDuration
	Prompt.MaxActivationDistance = Info.MaxActivationDistance
	Prompt.RequiresLineOfSight = Info.RequiresLineOfSight
	Prompt.Parent = Part

	self.Prompt = self.Job:Task(Prompt)

	self.Job:Task(Prompt.Triggered:Connect(function(Player : Player)
		if Info.OwnerOnly then
			local LuaPlayer = self.Owner and self.Owner.LuaPlayer

			if (Player ~= (LuaPlayer and LuaPlayer.Player)) then
				return
			end
		end

		self:Pet(Player)
	end))
end

function Shikigami:_BindOwnerEmoting()
	local Combat = self.Owner and self.Owner.Combat

	if (Combat == nil) then return end

	self.Job:Task(Combat:GetStateChanged("Emoting"):Connect(function(Value : boolean)
		self:_SetOwnerEmoting(Value)
	end))

	self:_SetOwnerEmoting(Combat:GetState("Emoting"))
end

function Shikigami:_SetOwnerEmoting(Value : boolean)
	if (self.Emoting == Value) then return end

	self.Emoting = Value

	local Dance = self.Tracks.dance

	if Value then
		self:Stop()

		if Dance and not self.Busy then
			Dance:Play(0.2)
		end
	elseif Dance and Dance.IsPlaying then
		Dance:Stop(0.2)
	end

	if self.Prompt and self.Active and not self.Busy then
		self.Prompt.Enabled = not Value
	end
end

----------------------------------------------------------------------------------

function Shikigami:_SetMoving(Value : boolean, DeltaTime : number)
	if Value then
		self.Still = 0
	else
		self.Still += DeltaTime

		if (self.Still < self.Spec.StillBeforeIdle) then
			return
		end
	end

	if (self.Moving == Value) then return end

	self.Moving = Value

	local Walk, Idle = self.Tracks.walk, self.Tracks.idle

	if Value then
		if Idle and Idle.IsPlaying then Idle:Stop(0.2) end
		if Walk and not Walk.IsPlaying then Walk:Play(0.2) end
	else
		if Walk and Walk.IsPlaying then Walk:Stop(0.2) end
		if Idle and not Idle.IsPlaying then Idle:Play(0.2) end
	end
end

function Shikigami:_GroundAt(Position : Vector3) : number?
	local Hit = workspace:Raycast(
		Position + Vector3.yAxis * self.Spec.StepHeight,
		Vector3.yAxis * -self.Spec.GroundReach,
		Utility.VisualParams
	)

	return Hit and (Hit.Position.Y + self.Spec.HipHeight) or nil
end

function Shikigami:_Suspended() : boolean
	return self.Busy or self.Emoting
end

function Shikigami:_Destination() : (Vector3?, number)
	if self:_Suspended() then
		return nil, 0
	end

	local Chase = self.Chase

	if Chase and Chase.Parent then
		return Chase.Position, self.Spec.StopDistance
	end

	return self.Goal, self.Spec.Reached
end

function Shikigami:_StepHop(DeltaTime : number)
	local Hop = self.Hop

	Hop.Elapsed += DeltaTime

	local Alpha = math.min(Hop.Elapsed / Hop.Duration, 1)
	local Position = Hop.From:Lerp(Hop.To, Alpha)

	local Facing = self.Root.CFrame.Rotation
	local Flat = (Hop.To - Hop.From) * FLAT

	if (Flat.Magnitude > 1e-3) then
		local Turn = math.min(self.Spec.TurnSpeed * DeltaTime, 1)
		Facing = Facing:Lerp(CFrame.lookAt(Vector3.zero, Flat.Unit), Turn)
	end

	self.Root.CFrame = CFrame.new(Position.X, Position.Y + Hop.Height * 4 * Alpha * (1 - Alpha), Position.Z) * Facing

	if (Alpha >= 1) then
		local Height = self:_GroundAt(Hop.To)

		if Height then
			self.Root.CFrame = CFrame.new(Hop.To.X, Height, Hop.To.Z) * Facing
		end

		self.Hop = nil
	end
end

function Shikigami:_Step(DeltaTime : number)
	if not self.Active then return end

	if self.Hop then
		self:_StepHop(DeltaTime)
		return
	end

	local Goal, Stop = self:_Destination()

	if (Goal == nil) then
		self:_SetMoving(false, DeltaTime)
		return
	end

	local Root : BasePart = self.Root
	local Position = Root.Position

	local Flat = (Goal - Position) * FLAT
	local Distance = Flat.Magnitude

	if (Distance <= Stop) then
		self.Goal = nil
		self:_SetMoving(false, DeltaTime)
		return
	end

	self:_SetMoving(true, DeltaTime)

	local Over = (Distance - self.Spec.StopDistance) / self.Spec.FollowDistance
	local Speed = self.Spec.Speed * (1 + math.clamp(Over, 0, 1) * (self.Spec.CatchUp - 1))

	local Walk = self.Tracks.walk

	if Walk and Walk.IsPlaying then
		Walk:AdjustSpeed(Speed / self.Spec.Speed)
	end

	local Direction = Flat.Unit
	local Target = Position + Direction * math.min(Speed * DeltaTime, Distance)

	local Ground = self:_GroundAt(Target)
	local Height = Position.Y

	if Ground and (Ground > Height) then
		Height = math.min(Ground, Height + self.Spec.ClimbSpeed * DeltaTime)
	else
		Height = math.max(Ground or -math.huge, Height - self.Spec.FallSpeed * DeltaTime)
	end

	local Turn = math.min(self.Spec.TurnSpeed * DeltaTime, 1)
	local Facing = Root.CFrame.Rotation:Lerp(CFrame.lookAt(Vector3.zero, Direction), Turn)

	Root.CFrame = CFrame.new(Target.X, Height, Target.Z) * Facing
end

----------------------------------------------------------------------------------

function Shikigami:GetOwnerRoot() : BasePart?
	local Owner = self.Owner

	if not (Owner and Owner.HumanoidAlive and Owner.RootPart) then
		return nil
	end

	return Owner.RootPart
end

function Shikigami:WalkTo(Position : Vector3, Timeout : number?) : boolean
	if not self.Active then return false end

	self.Chase = nil
	self.Goal = Position

	local Deadline = os.clock() + (Timeout or self.Spec.WalkTimeout)

	while self.Active and (self.Goal ~= nil) do
		if (os.clock() > Deadline) then
			self.Goal = nil
			return false
		end

		task.wait()
	end

	return self.Active
end

function Shikigami:HopTo(Position : Vector3) : boolean
	if not self.Active then return false end

	self.Chase = nil
	self.Goal = nil

	local From = self.Root.Position
	local Distance = ((Position - From) * FLAT).Magnitude

	self.Hop = {
		From = From,
		To = Position,
		Elapsed = 0,
		Height = self.Spec.HopHeight + math.max(0, Position.Y - From.Y) * 0.35,
		Duration = math.clamp(Distance / self.Spec.Speed, self.Spec.HopMinTime, self.Spec.HopMaxTime),
	}

	self:_SetMoving(true, 0)

	while self.Active and self.Hop do
		task.wait()
	end

	return self.Active
end

function Shikigami:PathTo(Position : Vector3) : boolean
	if not self.Active then return false end

	self.Chase = nil

	local Path = PathfindingService:CreatePath(self.Spec.AgentParams)
	local Ok = pcall(Path.ComputeAsync, Path, self.Root.Position, Position)

	if not (Ok and Path.Status == Enum.PathStatus.Success) then
		return self:WalkTo(Position)
	end

	for Index, Waypoint in Path:GetWaypoints() do
		if not self.Active or (self.Chase ~= nil) then return false end

		if (Index == 1) then continue end

		local Reached = if (Waypoint.Action == Enum.PathWaypointAction.Jump)
			then self:HopTo(Waypoint.Position)
			else self:WalkTo(Waypoint.Position)

		if not Reached then
			return false
		end
	end

	return true
end

function Shikigami:Stop()
	self.Goal = nil
	self.Chase = nil
end

function Shikigami:Teleport(Coordinate : CFrame)
	self:Stop()
	self.Hop = nil

	local Height = self:_GroundAt(Coordinate.Position)
	local Position = Height and Vector3.new(Coordinate.X, Height, Coordinate.Z) or Coordinate.Position

	self.Root.CFrame = CFrame.new(Position) * Coordinate.Rotation
end

function Shikigami:Roam()
	local Anchor = self:GetOwnerRoot()
	local Origin = Anchor and Anchor.Position or self.Root.Position

	local Offset = Utility.Seed:NextUnitVector() * FLAT

	if (Offset.Magnitude < 1e-3) then return end

	local Point = Origin + Offset.Unit * (self.Spec.RoamRange * Utility.Seed:NextNumber(0.35, 1))
	local Ground = self:_GroundAt(Point)

	if (Ground == nil) or (math.abs(Ground - self.Root.Position.Y) > self.Spec.RoamRange) then return end

	self:PathTo(Point)

	if self.Active then
		task.wait(Utility.NumberRangeRandom(self.Spec.RoamIdle))
	end
end

function Shikigami:FollowOwner() : boolean
	local Owner = self:GetOwnerRoot()

	if (Owner == nil) then return false end

	self.Goal = nil
	self.Chase = Owner

	local Last = self.Root.Position
	local Stuck = 0

	while self.Active and (self.Chase == Owner) and not self:_Suspended() do
		local Root = self:GetOwnerRoot()

		if (Root ~= Owner) then break end

		local Position = self.Root.Position
		local Distance = ((Owner.Position - Position) * FLAT).Magnitude

		if (Distance <= self.Spec.StopDistance) then break end

		if ((Position - Last).Magnitude < self.Spec.StuckStep) then
			Stuck += 1

			if (Stuck >= self.Spec.StuckTicks) then
				self:PathTo(Owner.Position)
				return true
			end
		else
			Stuck = 0
		end

		Last = Position
		task.wait(self.Spec.Tick)
	end

	if (self.Chase == Owner) then
		self.Chase = nil
	end

	return true
end

function Shikigami:Pet(Player : Player?) : boolean
	local Track = self.Tracks.pet

	if not (Track and self.Active) or self.Busy then
		return false
	end

	self.Busy = true
	self:Stop()

	if self.Prompt then
		self.Prompt.Enabled = false
	end

	local Dance = self.Tracks.dance

	if Dance and Dance.IsPlaying then
		Dance:Stop(0.15)
	end

	local Character = Player and Player.Character
	local Toward = (Character and Character:FindFirstChild("HumanoidRootPart")) or self:GetOwnerRoot()

	if Toward then
		local Flat = (Toward.Position - self.Root.Position) * FLAT

		if (Flat.Magnitude > 1e-3) then
			self.Root.CFrame = CFrame.lookAt(self.Root.Position, self.Root.Position + Flat.Unit)
		end
	end

	Track:Play(0.15)

	local Finished = false
	local Deadline = os.clock() + 10

	self.Job:Task(Track.Stopped:Once(function()
		Finished = true
	end))

	while self.Active and not Finished and (os.clock() < Deadline) do
		task.wait()
	end

	self.Busy = false

	if self.Active and self.Emoting and Dance then
		Dance:Play(0.2)
	end

	if self.Prompt and self.Active then
		self.Prompt.Enabled = not self.Emoting
	end

	return Finished
end

----------------------------------------------------------------------------------

function Shikigami:_Behaviour()
	while self.Active do
		local Owner = self:GetOwnerRoot()

		if (Owner == nil) or self.Busy then
			self.Chase = nil
			task.wait(0.25)
			continue
		end

		local Distance = ((Owner.Position - self.Root.Position) * FLAT).Magnitude

		if (Distance > self.Spec.LeashDistance) then
			self:Teleport(Owner.CFrame * self.Spec.Offset)

		elseif self.Emoting then
			self.Chase = nil

		elseif (Distance > self.Spec.FollowDistance) then
			self:FollowOwner()
		else
			self.Chase = nil
			self:Roam()
		end

		if self.Active then
			task.wait(self.Spec.Tick)
		end
	end
end

function Shikigami:Destroy()
	if not self.Active then return end

	self.Active = false
	self.Goal = nil
	self.Chase = nil
	self.Hop = nil

	self.Job:Destroy()

	if self.Model then
		self.Model:Destroy()
		self.Model = nil
	end
end

----------------------------------------------------------------------------------

table.freeze(Shikigami)

return Shikigami
