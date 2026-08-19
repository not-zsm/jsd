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
	self.Combat:DivideSpeed(50)
	
	self:FireReliableVFX("Powers/Super Speed", "Start", self.LuaCharacter.Model)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(self.Cooldown)
		self.Combat:TimesSpeed(self.SpeedDecrease)
		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("GrabIFrames", false)
	end)
	
	local RunHitbox = self:CreateHitbox(false);
	RunHitbox.Params.Offset = CFrame.new(0, 1.5, -4)
	RunHitbox.Params.Size = Vector3.new(10, 9, 12)
	RunHitbox.Params.DestroyOnEndCast = false

	RunHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Finisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= (18))
		
		if Finisher then
			local Validated = self:Afflict(VictimLuaPlayer, {
				BreakBlock = true,
				Damage = 100,
				Ragdoll = 3,
				Velocity = {self.Combat:GetSimulatedRoot().CFrame.LookVector * 80 + Vector3.yAxis * 25, 0.1}
			})

			if Validated then
				self:FireReliableVFX("Powers/Super Speed", "Finisher", VictimLuaCharacter.Model)
			end
		end
		
		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = 2,
			BreakBlock = true,
			Damage = 15,
			Ragdoll = 3,
			Velocity = {self.Combat:GetSimulatedRoot().CFrame.LookVector * 80 + Vector3.yAxis * 25, 0.1}
		})

		if Validated then
			self:FireReliableVFX("Global/M1", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, math.random(1, 2))
			VictimCombat:PlayRandomHitReaction(3)
		end

		task.delay(1, function()
			RunHitbox:RemoveHumanoid(VictimLuaCharacter.Humanoid)
		end)
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Sprint"):Connect(function()
		self.Combat:StackState("GrabIFrames", true)
		RunHitbox:BeginCast()
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Stop"):Connect(function()
		RunHitbox:EndCast()
		self.Combat:StackState("GrabIFrames", false)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup.Stopped:Wait())
	
	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.TryToCancelMoves = true
	self.SpeedDecrease = 50
	self.Cooldown = 50

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack