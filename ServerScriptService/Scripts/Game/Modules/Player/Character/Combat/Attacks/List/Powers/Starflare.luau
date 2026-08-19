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


local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(self.SpeedDecrease)
	
	self:FireReliableVFX("Powers/Starflare", "Start", self.LuaCharacter.Model)
	
	local Hitbox = self:CreateHitbox(true);
	Hitbox.Params.Size = 15

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			Damage = 8,
			BreakBlock = true,
			TrueStun = 3,
			Velocity = {(VictimLuaCharacter.RootPart.Position - Hitbox.Adornee.Position).Unit * 8, 0.1},
			TriggerActiveCounterOverOrEqualLevel = -1,
		})

		if Validated then
			VictimCombat.Animations.BlackFlashed:Play(0, 1, 0.5)
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(self.Cooldown)
		self.Combat:TimesSpeed(self.SpeedDecrease)
		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("HitboxImmunity", false)
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Flash"):Connect(function()
		Hitbox:Detect()
		self.Combat:StackState("HitboxImmunity", false)
	end))
	
	self.Thread.Job:Task(task.delay(0.35, function()
		self.Combat:StackState("HitboxImmunity", true)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup.Stopped:Wait())
	task.wait(0.5)
	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.TryToCancelMoves = true
	self.SpeedDecrease = 10
	self.Cooldown = 40

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack