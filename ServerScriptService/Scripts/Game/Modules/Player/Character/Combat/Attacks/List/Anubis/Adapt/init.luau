local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

----------------------------------------------------------------------------------

local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:Activate()
	self.Combat:StackState("CannotM1", true)
	self.Combat:StackState("CannotBlock", true)
	self.Combat:StackState("GrabIFrames", true)

	local AnimName =`Dodge{math.random(1, 3)}`
	self.Animations[AnimName]:Play(0.1, 1, 1)
	
	self:FireReliableVFX("Anubis/Adapt", "Dodge", self.LuaCharacter.Model, AnimName)
	
	self.Thread.OnClosed:Connect(function()
		self.Combat:StackState("GrabIFrames", false)
		self.Combat:StackState("CannotM1", false)
		self.Combat:StackState("CannotBlock", false)

		if not self.DamageReductionActive then
			self.DamageReductionActive = true
			self.Combat:MinusDefense(self.Config.DefenseReduction)
		end
		
		if self.DamageReductionThread then
			Utility.CloseThreadSafe(self.DamageReductionThread)
		end
		
		self.DamageReductionThread = task.delay(self.Config.DefenseDuration, function()
			self.DamageReductionThread = nil
			self.DamageReductionActive = false
			self.Combat:PlusDefense(self.Config.DefenseReduction)
		end)
	end)
	
	self.Thread.Job:Task(self.Animations[AnimName].Stopped:Once(function()
		self:Close()
	end))
end

function Attack:OnHit(MoveName)
	if self.ProgressDelayedMoves[MoveName] then
		return false
	end

	if not self.AdaptedMoves[MoveName] then
		self.AdaptedMoves[MoveName] = 0
	end

	self.AdaptedMoves[MoveName] += 1
	self.ProgressDelayedMoves[MoveName] = true
	
	task.delay(self.Config.ProgressDelayDuration, function()
		self.ProgressDelayedMoves[MoveName] = nil
	end)

	if (self.AdaptedMoves[MoveName] > self.Config.RequiredHitsToAdapt and not self.DodgeCooldown and math.random(1, 100) <= self.CurrentAdaptChance) then
		self.DodgeCooldown = true

		task.delay(self.Config.DodgeCooldown, function()
			self.DodgeCooldown = false
		end)

		self:Trigger()

		return true
	else
		local Sword = self.Combat.Sword

		if Sword and Sword.Model then
			self:FireReliableVFX("Anubis/Adapt", "Highlight", self.LuaCharacter.Model, Sword.Model, self.AdaptedMoves[MoveName])
		else
			warn("Anubis: Sword Missing")
		end
	end
	
	return false
end

----------------------------------------------------------------------------------

function Attack.new(...) 
	local self = setmetatable(BaseAttack.new(...), Attack)
	
	self.Config = {
		RequiredHitsToAdapt = 3,
		DefaultAdaptChance = 20, -- 25
		ProgressDelayDuration = 15, -- 10
		
		KillAdaptChanceBuff = 30,
		KillAdaptChanceDuration = 30,
		
		DefenseReduction = 0.10,
		DefenseDuration = 7,
		
		DodgeCooldown = 1, -- 0.5
	}
	
	self.AdaptedMoves = {}
	self.CurrentAdaptChance = self.Config.DefaultAdaptChance
	
	self.ProgressDelayedMoves = {}

	self.DamageReductionActive = false
	self.AdaptChanceBuffActive = false
	
	self.DodgeCooldown = false
	
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack