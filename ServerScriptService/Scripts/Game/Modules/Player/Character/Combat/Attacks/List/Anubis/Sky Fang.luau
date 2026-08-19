local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Anubis_Utility = require("./Anubis Utility")

local EventService = require(ReplicatedStorage.Modules.Shared.Utilities.EventService)

local Remotes = ReplicatedStorage.Remotes

local CombatRemotes = Remotes.Combat
local GrabRemotes = Remotes.Grab

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:StackState("GrabIFrames", true)
	self.Combat:DivideSpeed(self.SpeedReduction)

	self.Animations.Windup:AdjustSpeed(1)

	self.Landed = false

	local function Resume()
		self.Landed = true
		self.Combat:StackState("GrabIFrames", false)

		task.delay(0.1, function()
			self.Animations.Windup:AdjustSpeed(1)
		end)
	end

	local ImpactLand = self.Thread.Job:Task(Instance.new("RemoteEvent"))
	ImpactLand.Name = "ImpactLand"
	ImpactLand.Parent = self.LuaCharacter.Model

	self.Thread.OnClosed:Connect(function()
		if not self.Landed then
			Resume()
		end

		self:AddCooldown(self.Cooldown)

		self.Combat:TimesSpeed(self.SpeedReduction)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(task.delay(self.TimeUntilMoveTimesOut, function()
		self.Animations.Windup:Stop(0)
		self:Close()
	end)) 

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("End"):Once(function()
		self:Close()
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Pause"):Once(function()
		self.Animations.Windup:AdjustSpeed(0)
	end))

	self.Thread.Job:Task(ImpactLand.OnServerEvent:Connect(function(FiredPlayer)
		if (FiredPlayer ~= self.LuaPlayer.Player) or self.Landed then
			return
		end

		Resume()
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Hitbox"):Once(function()
		local SlamHitbox = self:CreateHitbox(true)
		SlamHitbox.Params.Offset = CFrame.identity
		SlamHitbox.Params.Size = 10

		SlamHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Validated = self:Afflict(VictimLuaPlayer, {
				BreakBlock = true,
				Ragdoll = 2.5,
				Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 30 + vector.create(0, 40, 0) , 0.1},
				Damage = 10
			})
		end)

		SlamHitbox:BeginCast(0.05)

		self.Combat.Hitbox:Destruction(CFrame.identity, vector.one * SlamHitbox.Params.Size, 1)
	end))

	self:FireReliableVFX(self.InternalEffectPath, "Start", self.LuaCharacter.Model)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true

	self.Cooldown = 12

	self.TimeUntilMoveTimesOut = 3
	self.SpeedReduction = 4

	self.InternalEffectPath = `Anubis/{script.Name}`

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack