--[[
	Wall jump.

	This used to run along walls: stick to one for a second, rotate to face
	along it, climb, then leap off. It is jjk's bounce now -- a single kick off
	a wall you are pushing into mid-fall, up to three per airtime, reset when
	you land. The script keeps the WallRun name because the animation folder,
	the server-side attack and anyone's saved keybind are all keyed to it.
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

----------------------------------------------------------------------------------

local Animations = ReplicatedStorage.Animations

local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )

----------------------------------------------------------------------------------

local MAX_CHAIN = 3      -- bounces per airtime
local DURATION = 0.4     -- force lifetime, and the debounce
local WALL_RANGE = 3     -- studs sideways to find a wall
local OVERHEAD = 4       -- no bounce with this much geometry above you

local KICK_IN = 50       -- shove into the wall, so the animation has something to plant against
local KICK_AWAY = 40     -- push off it
local KICK_UP = 20
local KICK_FORWARD = 30

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
		not self.Combat.ClientHandlers.Vault.Vaulting
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

	-- you have to be pushing into the wall, not just falling past it
	local Side = math.round(Humanoid.MoveDirection:Dot(RootPart.CFrame.RightVector))
	if (Side == 0) then return end

	if workspace:Raycast(RootPart.Position, Vector3.yAxis * OVERHEAD, Utility.VisualParams) then
		return
	end

	-- flatten the facing so a bounce off a wall while looking up or down still
	-- sends you along the ground plane
	local Look = RootPart.CFrame.LookVector
	local Flat = Vector3.new(Look.X, 0, Look.Z)
	if (Flat.Magnitude < 1e-3) then return end

	local Facing = CFrame.lookAt(RootPart.Position, RootPart.Position + Flat)
	local Forward, Right, Up = Facing.LookVector, Facing.RightVector, Facing.UpVector

	local Wall = workspace:Raycast(RootPart.Position, Right * (Side * WALL_RANGE), Utility.VisualParams)
	if (Wall == nil) or not Wall.Instance.CanCollide then return end

	self:Fire(Side, Forward, Right, Up)
end

function WallJumpHandler:Fire(Side : number, Forward : Vector3, Right : Vector3, Up : Vector3)
	local RootPart : BasePart = self.LuaCharacter.RootPart

	local Velocity : BodyVelocity = self.Combat:CreateBodyVelocity("WallJump")
	if (Velocity == nil) then return end

	self.WallJumping = true
	self.Chain += 1

	task.delay(DURATION, function()
		self.WallJumping = false
	end)

	-- M1 reads this to allow an air attack off the bounce
	local AttackInput = self.LuaPlayer.Remotes.Combat.AttackInput
	AttackInput:FireServer(script.Name, true)

	task.delay(DURATION, function()
		AttackInput:FireServer(script.Name, false)
	end)

	local Animation : AnimationTrack? = self.Animations[Side == 1 and "JumpRight" or "JumpLeft"]

	if Animation then
		Animation:Play(0.05)
	end

	self.Combat:ResetJumpFatigue()

	task.spawn(function()
		EffectUtility.EmitEffects(script.Jump, RootPart)
	end)

	Velocity.MaxForce = Vector3.one * 40000
	Velocity.P = 40000
	Velocity.Velocity = RootPart.AssemblyLinearVelocity + Right * (Side * KICK_IN)
	Velocity.Parent = RootPart

	TweenService:Create(Velocity, TweenInfo.new(DURATION), {
		Velocity = Up * KICK_UP - Right * (Side * KICK_AWAY) + Forward * KICK_FORWARD
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
