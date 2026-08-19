local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )

local DomainHandler = require( ServerScriptService.Scripts.DomainHandler )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AenoirEmit = EffectUtility.AenoirEmit

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return true
end

function Attack:Activate()
	local domain = DomainHandler:create("InfiniteOil", {
		owner = self.LuaPlayer.Player,
		origin = self.Combat:GetSimulatedRoot().CFrame - Vector3.yAxis * 3
	})
	
	domain:play_popup();
	domain:spawn_wave();

	task.wait(1.25);
	domain:spawn_dome();
	
	task.delay(2, function()
		domain:engulf_in_dome()
		domain:engulf(self.LuaCharacter.Model)
	end)
	
	task.delay(15, function()
		domain:destroy()
	end)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack