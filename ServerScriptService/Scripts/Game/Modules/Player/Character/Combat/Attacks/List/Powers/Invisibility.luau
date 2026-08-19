local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Signal = require( ReplicatedStorage.Packages.Signal )

--local CharacterTransparency = require( ReplicatedStorage.Modules.Player.Replication.Global.CharacterTransparency )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking") and not self.Combat:GetState("Emoting")
end

function Attack:Activate()
	if self.Active then return end
	self.Active = true
	
	--self.Combat:StackState("Attacking", true)
	self.Combat:TimesSpeed(self.SpeedIncrease)
	
	self:FireReliableVFX("Powers/Invisibility", "Start", self.LuaCharacter.Model)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(self.Cooldown)
		self.Combat:DivideSpeed(self.SpeedIncrease)
		--self.Combat:StackState("Attacking", false)
		self:FireReliableVFX("Powers/Invisibility", "End", self.LuaCharacter.Model)
		self.Active = false
	end)
	
	self.Thread.Job:Task(self.Combat.OnStateChanged:Connect(function(State, Value)
		self:Close()
	end))

	task.wait(0.7)
	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.SpeedIncrease = 3
	self.Cooldown = 30
	self.Active = false

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack