local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("HitboxImmunity", true)
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)
	
	self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
	self.Thread.CancelJob:Task(self:CreateMoveSFX("Reigen", "1000% Exorcism"))

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -500)
	Hitbox.Params.Size = Vector3.new(200, 75, 1000)
	Hitbox.Params.DestroyOnEndCast = false
	Hitbox.Params.MaxTargets = 30
	Hitbox.Params.TrySorting = false
	
	local StompHitbox = self:CreateHitbox(false);
	StompHitbox.Params.Offset = CFrame.new(0, 5, 0)
	StompHitbox.Params.Size = Vector3.new(25, 25, 25)
	StompHitbox.Params.DestroyOnEndCast = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			
			Ragdoll = 3,
			Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 225 + Vector3.yAxis * 125, 0.1},

			Damage = {
				Amount = StompHitbox.Humanoids[VictimLuaCharacter.Humanoid] and 100 or 40,
				DontCountToUltimate = true
			},

			BreakBlock = true
		})
	end)

	StompHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			Damage = 10,
			BreakBlock = true
		})

		if Validated then
			VictimCombat:TrueStun(10)

			self.Combat:TSBPushVictim(VictimLuaPlayer, {
				LandedRollVelocityZ = 300,
				LandedRollDuration = 0.85,
			})
		end
	end)

	self.Combat:HideUI(true)
	
	local Ultimate, Matched = self.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

	if Matched then
		Ultimate:StopUltimate()
	end

	self.Thread.OnClosed:Connect(function()
		self.Combat:HideUI(false)
		
		self.Combat:TimesSpeed(50)
		
		self.Combat:StackState("HitboxImmunity", false)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("ready"):Connect(function()
		StompHitbox:Detect()
		self:FireReliableVFX("Reigen/1000% Exorcism", "Ready", self.LuaCharacter.RootPart)
		
		self.Animations.Windup:AdjustSpeed(1)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("powerup"):Connect(function()
		self:FireReliableVFX("Reigen/1000% Exorcism", "PowerUp", self.LuaCharacter.RootPart)
		
		self.Thread.OnClosed:Connect(function()
			self:FireReliableVFX("Reigen/1000% Exorcism", "PowerDown", self.LuaCharacter.RootPart)
		end)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("abouttoshoot"):Connect(function()
		self:FireReliableVFX("Reigen/1000% Exorcism", "AboutToShoot", self.LuaCharacter.RootPart)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
		self:FireReliableVFX("Reigen/1000% Exorcism", "VFX", self.LuaCharacter.RootPart, Parameter)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("shoot"):Connect(function()
		self:FireReliableVFX("Reigen/1000% Exorcism", "Shoot", self.LuaCharacter.RootPart)
		
		Hitbox:Detect()
		self.Combat.Hitbox:Destruction(Hitbox.Params.Offset, Hitbox.Params.Size, 10, nil, {dont_create_debris = true})
		
		task.wait(3)
		
		self:Close()
	end))
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.AnimationSettings = {Speed = 0.5}
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack