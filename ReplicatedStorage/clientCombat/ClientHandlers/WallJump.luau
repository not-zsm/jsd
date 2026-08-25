--[[
	Wall jump.

	This used to run along walls: stick to one for a second, rotate to face
	along it, climb, then leap off. It is jjk's bounce now -- a single kick off
	a wall you are pushing into mid-fall, up to three per airtime, reset when
	you land. jjk's own jumpL and jumpR are the animations; the ones jsd had
	were posed for a character already rotated flat against the wall, which is
	not what happens any more.
--]]
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

----------------------------------------------------------------------------------

local Animations = replicatedStorage.animations

local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )

----------------------------------------------------------------------------------

local MAX_CHAIN = 3      -- bounces per airtime
local DURATION = 0.4     -- force lifetime, and the debounce
local WALL_RANGE = 3     -- studs sideways to find a wall
local OVERHEAD = 4       -- no bounce with this much geometry above you

local KICK_IN = 50       -- shove into the wall, so the animation has something to plant against
local KICK_AWAY = 18     -- enough to clear the wall, no more
local KICK_UP = 22
local KICK_FORWARD = 45  -- along where you are looking, the one that decides the bounce

local FLAT = Vector3.new(1, 0, 1)

----------------------------------------------------------------------------------

local WallJumpHandler = {}
WallJumpHandler.__index = WallJumpHandler

function WallJumpHandler:OnHumanoidLoaded()
	for _, Animation : AnimationTrack in self.Animations do
		Animation:Destroy()
	end

	table.clear(self.Animations)

	local Animator : Animator = self.LuaCharacter.Animator

	for _, Animation : Animation in ipairs(Animations.ClientActions[script.Name]:GetChildren()) do
		if Animation:IsA("Animation") then
			self.Animations[Animation.Name] = Animator:LoadAnimation(Animation)
			self.Animations[Animation.Name].Priority = Enum.AnimationPriority.Movement
		end
	end
end

function WallJumpHandler:_Init()
	RunService.PreSimulation:Connect(function()
		if not self.LuaCharacter.HumanoidAlive then return end

		local Humanoid : Humanoid = self.LuaCharacter.Humanoid

		if Humanoid.FloorMaterial ~= Enum.Material.Air then
			self.Chain = 0
			return
		end

		if Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then return end

		self:TryJump()
	end)
end

----------------------------------------------------------------------------------

function WallJumpHandler:NotStunned()
	return
		not self.Combat:GetState("Stunned") and
		not self.Combat:GetState("Ragdolled") and
		not self.Combat:GetState("Dashing") and
		not self.Combat:GetState("Blocking") and
		not self.Combat:GetState("M1ing") and
		not self.Combat.ClientHandlers.Vault.Vaulting and
		not self.Combat.ClientHandlers.Roll.Rolling
end

function WallJumpHandler:CanActivate()
	return
		not self.Combat:GetState("Attacking") and
		self:NotStunned() and
		not workspace:GetAttribute("IsRankedLobby")
end

----------------------------------------------------------------------------------

function WallJumpHandler:TryJump()
	if self.WallJumping then return end
	if not self.Combat.HoldingJump then return end
	if self.Chain >= MAX_CHAIN then return end
	if not self:CanActivate() then return end

	local RootPart : BasePart = self.LuaCharacter.RootPart
	local Humanoid : Humanoid = self.LuaCharacter.Humanoid

	--[[
		You have to be pushing into the wall, not just falling past it.

		This used to read the move direction against the character's own right
		vector and round it, so it only passed within about 60 degrees of straight
		sideways -- and then only cast sideways to find the wall. With autorotate
		on, which is the default, the character turns to face where it is going,
		so that dot sits near zero and the bounce silently refused. It worked in
		the cases where facing and movement had come apart: shift lock, mid-turn,
		or a move that had stopped autorotate. Hence "sometimes".

		Cast along the movement instead, and take the kick off the wall's normal
		rather than off the character's facing.
	--]]
	local Move = Humanoid.MoveDirection * FLAT
	if (Move.Magnitude < 0.1) then return end

	if workspace:Raycast(RootPart.Position, Vector3.yAxis * OVERHEAD, Utility.VisualParams) then
		return
	end

	local Wall = workspace:Raycast(RootPart.Position, Move.Unit * WALL_RANGE, Utility.VisualParams)
	if (Wall == nil) or not Wall.Instance.CanCollide then return end

	local Normal = Wall.Normal * FLAT
	if (Normal.Magnitude < 1e-3) then return end

	local Away = Normal.Unit
	local Into = -Away

	-- the animations are posed per side, so this still asks which side of the
	-- character the wall is on, it just no longer decides whether to bounce
	local Side = (RootPart.CFrame.RightVector:Dot(Into) >= 0) and 1 or -1

	--[[
		Where you go is where you are looking.

		Projecting the look onto the wall and using that left the wall normal
		deciding everything -- look straight at it and the along-wall component
		is zero, so every bounce off a given wall went the same way regardless of
		the camera. Reflecting instead keeps the look axis meaningful: face the
		wall and you come off it backwards, which is what a bounce should do.
	--]]
	local Look = RootPart.CFrame.LookVector * FLAT
	local Facing = (Look.Magnitude > 1e-3) and Look.Unit or Away

	local Dot = Facing:Dot(Away)
	local Travel = (Dot < 0) and (Facing - Away * (2 * Dot)).Unit or Facing

	self:Fire(Side, Travel, Away, Vector3.yAxis)
end

function WallJumpHandler:Fire(Side : number, Travel : Vector3, Away : Vector3, Up : Vector3)
	local RootPart : BasePart = self.LuaCharacter.RootPart

	local Velocity : BodyVelocity = self.Combat:CreateBodyVelocity("WallJump")
	if (Velocity == nil) then return end

	self.WallJumping = true
	self.Chain += 1

	task.delay(DURATION, function()
		self.WallJumping = false
	end)

	-- M1 reads this to allow an air attack off the bounce
	network.useMove.send({ move = script.Name, state = true })

	task.delay(DURATION, function()
		network.useMove.send({ move = script.Name, state = false })
	end)

	local Animation : AnimationTrack? = self.Animations[Side == 1 and "jumpR" or "jumpL"]

	if Animation then
		Animation:Play(0.05)
	end

	self.Combat:ResetJumpFatigue()

	task.spawn(function()
		EffectUtility.EmitEffects(script.Jump, RootPart)
	end)

	Velocity.MaxForce = Vector3.one * 40000
	Velocity.P = 40000
	Velocity.Velocity = RootPart.AssemblyLinearVelocity - Away * KICK_IN
	Velocity.Parent = RootPart

	--- Travel is the dominant term now; the wall only has to push far enough to
	--- clear it, which is why KICK_AWAY came down and KICK_FORWARD went up.
	TweenService:Create(Velocity, TweenInfo.new(DURATION), {
		Velocity = Up * KICK_UP + Away * KICK_AWAY + Travel * KICK_FORWARD
	}):Play()

	Debris:AddItem(Velocity, DURATION)
end

----------------------------------------------------------------------------------

function WallJumpHandler.new(Combat)
	local self = setmetatable({}, WallJumpHandler)

	self.Combat = Combat
	self.LuaCharacter = Combat.LuaCharacter
	self.LuaPlayer = Combat.LuaCharacter.LuaPlayer

	self.Animations = {}

	self.WallJumping = false
	self.Chain = 0

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(WallJumpHandler)

return WallJumpHandler
