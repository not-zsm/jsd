local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return not self.OnCooldown and self.Enabled
end

function Attack:Activate()
	self:FireReliableVFX("Stardust Crusader/Yare Yare Daze", "Start", self.LuaCharacter.Model)
	self.LuaCharacter:Heal(30)
	self:AddCooldown(3.5)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.Uncancellable = true
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack