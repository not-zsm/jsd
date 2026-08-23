--[[
	Landing roll.

	Hit the ground fast with jump tapped inside the window and you roll out of
	it, carrying the fall speed forward. Miss either condition and you get the
	soft landing instead, weighted by how hard you hit.
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

----------------------------------------------------------------------------------

local Animations = ReplicatedStorage.Animations

----------------------------------------------------------------------------------

local INPUT_WINDOW = 0.25   -- the jump tap has to be this close to landing
local MIN_FALL_SPEED = 50   -- studs/s downward before a roll is on the table
local DURATION = 0.4        -- lockout, and how long the force lives
local FORCE_FADE = 0.6      -- MaxForce reaches zero after the force is gone, on purpose
local DOWN_PIN = -30        -- keeps the roll glued to the floor instead of skipping
local SPEED_DIVISOR = 1.5
local MAX_SPEED = 60

----------------------------------------------------------------------------------

local RollHandler = {}
RollHandler.__index = RollHandler

function RollHandler:OnHumanoidLoaded()
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

	if self.StateConnection then
		self.StateConnection:Disconnect()
	end

	self.StateConnection = self.LuaCharacter.Humanoid.StateChanged:Connect(function(_, NewState)
		if NewState ~= Enum.HumanoidStateType.Landed then return end

		self:OnLand()
	end)
end

function RollHandler:_Init()
	self.Combat.OnSpaceChanged:Connect(function(Down : boolean)
		if Down then
			self.LastJumpPress = time()
		end
	end)
end

----------------------------------------------------------------------------------

function RollHandler:CanRoll(FallSpeed : number)
	return
		FallSpeed > MIN_FALL_SPEED and
		(time() - self.LastJumpPress) <= INPUT_WINDOW and
		not self.Rolling and
		not self.Combat:GetState("Attacking") and
		not self.Combat:GetState("Stunned") and
		not self.Combat:GetState("Ragdolled") and
		not self.Combat:GetState("Dashing") and
		not self.Combat:GetState("M1ing") and
		not self.Combat.ClientHandlers.Vault.Vaulting and
		not self.Combat.ClientHandlers.WallJump.WallJumping
end

function RollHandler:OnLand()
	if not self.LuaCharacter.HumanoidAlive then return end

	local FallSpeed = -self.LuaCharacter.RootPart.AssemblyLinearVelocity.Y

	if self:CanRoll(FallSpeed) then
		self:Roll(FallSpeed)
		return
	end

	local Land : AnimationTrack? = self.Animations.land

	if Land and FallSpeed > 0 then
		Land:Play(nil, math.clamp(FallSpeed / 100, 0, 1), 2)
	end
end

function RollHandler:Roll(FallSpeed : number)
	local RootPart : BasePart = self.LuaCharacter.RootPart
	local Humanoid : Humanoid = self.LuaCharacter.Humanoid

	self.Rolling = true

	local JumpWasEnabled = Humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

	local Animation : AnimationTrack? = self.Animations.roll

	if Animation then
		Animation:Play(0.1)
	end

	-- the velocity holds while the force fades, which is what makes the roll
	-- run out rather than stop dead. A plain BodyVelocity, since the shared
	-- Velocity helper has no way to express a fading MaxForce.
	local Velocity = self.Combat:CreateBodyVelocity(script.Name)

	if (Velocity == nil) then
		self.Rolling = false
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, JumpWasEnabled)
		return
	end

	Velocity.MaxForce = Vector3.new(40000, 1000, 40000)
	Velocity.P = 40000
	Velocity.Velocity = Vector3.new(0, DOWN_PIN, 0)
		+ RootPart.CFrame.LookVector * math.clamp(FallSpeed / SPEED_DIVISOR, 0, MAX_SPEED)
	Velocity.Parent = RootPart

	TweenService:Create(Velocity, TweenInfo.new(FORCE_FADE), { MaxForce = Vector3.zero }):Play()
	Debris:AddItem(Velocity, DURATION)

	task.delay(DURATION, function()
		self.Rolling = false

		if self.LuaCharacter.HumanoidAlive then
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, JumpWasEnabled)
		end
	end)
end

----------------------------------------------------------------------------------

function RollHandler.new(Combat)
	local self = setmetatable({}, RollHandler)

	self.Combat = Combat
	self.LuaCharacter = Combat.LuaCharacter
	self.LuaPlayer = Combat.LuaCharacter.LuaPlayer

	self.Animations = {}

	self.Rolling = false
	self.LastJumpPress = -math.huge

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(RollHandler)

return RollHandler
