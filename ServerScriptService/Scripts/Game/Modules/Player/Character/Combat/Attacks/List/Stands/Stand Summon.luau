local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local BaseStand = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseStand )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Preloading = require( ReplicatedStorage.Modules.Preloading )

local Attack = setmetatable({}, BaseAttack)
Attack.__index = Attack

----------------------------------------------------------------------------------

function Attack:ConditionToActivate() : boolean
	return not self:HasCertainCooldown("AntiSpam") and not self.OnCooldown
end

function Attack:Activate()
	local CharacterInfo = self.Combat.CurrentCharacter.Info;
	local Stand = self.Combat:GetStand();
	
	if not Stand then
		warn("Unable to summon stand: No stand exists");
		return self:Close();
	end;
	
	self:AddCertainCooldown("AntiSpam", 0.1)
	
	if Stand.Summoned then
		Stand:Unsummon();
		self:AddCooldown(self.UnsummonCooldown);
	else
		Stand:Summon();
		self:AddCooldown(self.SummonCooldown);
	end;
	
	self:Close()
end;

function Attack.new(...)
	local self = setmetatable(BaseStand.new(...), Attack)
	
	self.TryToCancelMoves = true
	
	self.UnsummonCooldown = 10
	self.SummonCooldown = 0.5
	
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack