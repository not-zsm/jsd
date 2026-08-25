local PathfindingService = game:GetService("PathfindingService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local Job = require( replicatedStorage.modules.shared.Utilities.Job )

local Extra = replicatedStorage.ass.megumi.extra

local FLAT = Vector3.new(1, 0, 1)

----------------------------------------------------------------------------------

--[[
	One summoned shikigami: its rig, its animation tracks, and the loop that
	decides where it wants to be.

	The rigs are AnimationController models with no Humanoid, so none of
	modules/AI applies -- that one drives everything through Humanoid:MoveTo and
	needs a whole LuaCharacter with a Combat object behind it. Movement here is
	the root part stepped by hand along the ground, which is also what keeps a
	pet from shoving players around.

	Following steers at the player every frame rather than walking a path to
	where they used to be. Pathfinding is for roaming, and for the moment a wall
	gets between the two of them.
--]]
local Specs = {
	bunny = {
		Animations = Extra.bunny,
		Offset = CFrame.new(0, -2.5, -5),

		Speed = 16,

		--- A player sprints at about 28. Without this it can never close the gap
		--- and just trails at leash range forever.
		CatchUp = 2.25,
		TurnSpeed = 11,

		--- Half the root's height, so it sits on the floor rather than in it.
		HipHeight = 0.45,
		GroundSnap = 10,

		--- Starts following past Follow, settles at Stop. Past Leash it gives up
		--- on walking and reappears next to its summoner.
		FollowDistance = 7,
		StopDistance = 4,
		LeashDistance = 100,

		--- Kept inside FollowDistance, or every wander ends in being called back.
		RoamRange = 5.5,
		RoamIdle = NumberRange.new(1.5, 4),

		Tick = 0.12,
		Reached = 1.5,
		WalkTimeout = 6,

		--- A frame or two between waypoints is not standing still.
		StillBeforeIdle = 0.2,

		--- Ground covered per tick below which it counts as blocked, and how many
		--- ticks of that before the pathfinder takes over.
		StuckStep = 0.35,
		StuckTicks = 6,

		AgentParams = {
			AgentRadius = 1.5,
			AgentHeight = 2,
			AgentCanJump = false,
			AgentCanClimb = false,
			WaypointSpacing = 6,
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

	--- Goal is a fixed point, Chase is something to keep steering at. Chase wins.
	self.Goal = nil :: Vector3?
	self.Chase = nil :: BasePart?

	self.Moving = false
	self.Still = 0
	self.Busy = false

	self.Root = Model:FindFirstChild("HumanoidRootPart")

	if (self.Root == nil) then
		self:Destroy()
		return warn(`shikigami: {Name} has no HumanoidRootPart`)
	end

	self:_PrepareRig()
	self:_LoadAnimations()

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

		--- Every world raycast in the game filters to the Map on an include
		--- list, so this is belt and braces -- but a summon should never be
		--- something a hitbox or a wall check can find.
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

	--- Above the other two, or it plays underneath them and reads as a twitch.
	if self.Tracks.pet then
		self.Tracks.pet.Priority = Enum.AnimationPriority.Action
	end
end

----------------------------------------------------------------------------------

--[[
	Held on the walk for StillBeforeIdle after it stops moving.

	Pathing hands off one waypoint at a time, and there are always a couple of
	frames between arriving at one and being given the next. Reacting to those
	restarted the walk cycle from the top every few studs, which is what made it
	look like the loop was broken.
--]]
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

--- Where the ground is under a point, or nil if there is nothing to stand on.
function Shikigami:_GroundAt(Position : Vector3) : number?
	local Snap = self.Spec.GroundSnap

	local Hit = workspace:Raycast(
		Position + Vector3.yAxis * Snap,
		Vector3.yAxis * -(Snap * 2),
		Utility.VisualParams
	)

	return Hit and (Hit.Position.Y + self.Spec.HipHeight) or nil
end

--- Read fresh every frame, so chasing tracks the player rather than the spot
--- they were standing on when the path was drawn.
function Shikigami:_Destination() : (Vector3?, number)
	if self.Busy then
		return nil, 0
	end

	local Chase = self.Chase

	if Chase and Chase.Parent then
		return Chase.Position, self.Spec.StopDistance
	end

	return self.Goal, self.Spec.Reached
end

function Shikigami:_Step(DeltaTime : number)
	if not self.Active then return end

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

	--- Ramped rather than switched: a hard step at FollowDistance means it
	--- crosses the line, slows, falls behind, and surges again.
	local Over = (Distance - self.Spec.StopDistance) / self.Spec.FollowDistance
	local Speed = self.Spec.Speed * (1 + math.clamp(Over, 0, 1) * (self.Spec.CatchUp - 1))

	local Walk = self.Tracks.walk

	if Walk and Walk.IsPlaying then
		Walk:AdjustSpeed(Speed / self.Spec.Speed)
	end

	local Direction = Flat.Unit
	local Target = Position + Direction * math.min(Speed * DeltaTime, Distance)
	local Height = self:_GroundAt(Target) or Position.Y

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

--- Straight at a point, no pathing. Returns false if it gave up or was stopped.
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

--- Around whatever is in the way. Falls back to walking straight at it when
--- there is no path, which off a ledge is usually the honest answer.
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

		--- The first waypoint is where it already is.
		if (Index == 1) then continue end

		if not self:WalkTo(Waypoint.Position) then
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

	local Height = self:_GroundAt(Coordinate.Position)
	local Position = Height and Vector3.new(Coordinate.X, Height, Coordinate.Z) or Coordinate.Position

	self.Root.CFrame = CFrame.new(Position) * Coordinate.Rotation
end

--- One wander: somewhere near the summoner, then a breather.
function Shikigami:Roam()
	local Anchor = self:GetOwnerRoot()
	local Origin = Anchor and Anchor.Position or self.Root.Position

	local Offset = Utility.Seed:NextUnitVector() * FLAT

	if (Offset.Magnitude < 1e-3) then return end

	local Point = Origin + Offset.Unit * (self.Spec.RoamRange * Utility.Seed:NextNumber(0.35, 1))

	if (self:_GroundAt(Point) == nil) then return end

	self:PathTo(Point)

	if self.Active then
		task.wait(Utility.NumberRangeRandom(self.Spec.RoamIdle))
	end
end

--[[
	Steers at the player until it is close enough, rather than pathing to where
	they stood a moment ago and stopping there.

	Steering is a straight line, which is right in the open and useless against a
	wall, so losing ground for long enough hands one leg to the pathfinder and
	the loop picks it back up after.
--]]
function Shikigami:FollowOwner() : boolean
	local Owner = self:GetOwnerRoot()

	if (Owner == nil) then return false end

	self.Goal = nil
	self.Chase = Owner

	local Last = self.Root.Position
	local Stuck = 0

	while self.Active and (self.Chase == Owner) and not self.Busy do
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

--- Plays through and holds the loop still until it finishes.
function Shikigami:Pet() : boolean
	local Track = self.Tracks.pet

	if not (Track and self.Active) or self.Busy then
		return false
	end

	self.Busy = true
	self:Stop()

	local Owner = self:GetOwnerRoot()

	if Owner then
		local Flat = (Owner.Position - self.Root.Position) * FLAT

		if (Flat.Magnitude > 1e-3) then
			self.Root.CFrame = CFrame.lookAt(self.Root.Position, self.Root.Position + Flat.Unit)
		end
	end

	Track:Play(0.15)

	--- Not Stopped:Wait(): Destroy takes the track with it, and a wait that
	--- never returns would strand whoever called this.
	local Finished = false
	local Deadline = os.clock() + 10

	self.Job:Task(Track.Stopped:Once(function()
		Finished = true
	end))

	while self.Active and not Finished and (os.clock() < Deadline) do
		task.wait()
	end

	self.Busy = false

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

	self.Job:Destroy()

	if self.Model then
		self.Model:Destroy()
		self.Model = nil
	end
end

----------------------------------------------------------------------------------

table.freeze(Shikigami)

return Shikigami
