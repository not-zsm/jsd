local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AenoirEmit = EffectUtility.AenoirEmit

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(100)

	local Hitbox = self:CreateHitbox(true);
	Hitbox.Params.Size = 25

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			Damage = 20,
			BreakBlock = true,
			TrueStun = 5,
			Velocity = {(VictimLuaCharacter.RootPart.Position - Hitbox.Adornee).Unit * 7.5, 0.1},
			TriggerActiveCounterOverOrEqualLevel = -1,
		})

		if Validated then
			VictimCombat.Animations.BlackFlashed:Play(0, 1, 0.5)
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(15)

		self.Combat:TimesSpeed(100)
		self.Combat:StackState("Attacking", false)
	end)

	self:FireReliableVFX("Walter/This, Is Candy.", "Bag", self.LuaCharacter.Model, AenoirUtil.GetAnimationId(self.Animations.Windup.Animation.AnimationId))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Turn"):Once(function()
		self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Land"):Once(function()
		task.wait(0.25)

		local BlastCFrame : CFrame = self.Combat:GetSimulatedRoot().CFrame * CFrame.new(0, 0, 6);
		self:FireReliableVFX("Walter/This, Is Candy.", "Blast", BlastCFrame.Position)

		Hitbox.Adornee = BlastCFrame.Position
		Hitbox:Detect()
	end))

	task.wait(2)

	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.AnimationSettings = {
		FadeTime = 0.2,
		Speed = 1
	}

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack