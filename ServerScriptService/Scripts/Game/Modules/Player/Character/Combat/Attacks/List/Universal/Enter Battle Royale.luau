local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--local SafeTeleport = require( ServerScriptService.SafeTeleport )
local TeleportToBattleRoyale = require( ServerScriptService.Scripts.TeleportToBattleRoyale )

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

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
	self.Combat:DivideSpeed(10)
	
	self.LuaCharacter:Anchor(true)
	
	self.Thread.OnClosed:Connect(function()
		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	local Portal = script.portal:Clone()
	Portal.CFrame = self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 1, -22)
	Portal.Parent = workspace.Visuals
	
	self:FireReliableVFXToSelf("Universal/Enter Battle Royale", "Start", self.LuaCharacter.RootPart)
	self.Animations.Windup:GetMarkerReachedSignal("tp"):Wait()
	self:FireReliableVFX("Universal/Enter Battle Royale", "Tp", self.LuaCharacter.RootPart)

	TeleportToBattleRoyale.Player(self.LuaPlayer.Player)
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