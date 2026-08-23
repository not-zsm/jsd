

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )
local VelocityUtil = require( ReplicatedStorage.modules.shared.Game.Velocity.VelocityUtil )
local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions()
end

function Attack:Activate()
	self.LuaPlayer.Replication:FireReliableVFX("Global/Blood", "Explode", self.LuaCharacter.RootPart)
	self.LuaPlayer.Replication:FireReliableVFX("Chara/Damage Indicator", "Value", self.LuaCharacter.RootPart, 9999) --global effect now
	self.LuaCharacter:Die()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack