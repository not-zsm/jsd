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
	self.StandHandler = self.Combat.Attacks["Star Platinum"]
	
	return self.StandHandler and self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.StandHandler:MoveStand(CFrame.new(-1, 0, 2.25), 2)
	
	self.Hit = false
	
	local Animation : AnimationTrack = self.StandHandler.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks["Stardust Crusader"]["Star Finger"].Stand)

	local Hitbox = self:CreateHitbox()
	Hitbox.Params.Offset = CFrame.new(1.5, 0, -7)
	Hitbox.Params.Size = Vector3.new(8, 8, 11)
	Hitbox.Params.DestroyOnEndCast = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		self.Hit = self:Afflict(VictimLuaPlayer, {
			Damage = 5,
			TrueStun = 1,
			Velocity = {self.Combat:GetSimulatedRoot().CFrame.LookVector * 10, 0.2},
			PlayRandomHitReaction = true
		})

		if self.Hit then
			Animation:AdjustSpeed(1.5)
			self:FireReliableVFX("Stardust Crusader/Heavy Barrage", "BarrageHit", VictimLuaCharacter.Torso)
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(8)
		
		if Animation.IsPlaying then
			Animation:Stop()
		end
		
		Animation:Destroy()
		
		self.StandHandler:MoveStandByAction("Idle", 1)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(Animation:GetMarkerReachedSignal("finger"):Connect(function(Parameter : string)
		self.Combat:DivideSpeed(1.5)
		
		self.Thread.OnClosed:Connect(function()
			self.Combat:TimesSpeed(1.5)
		end)
		
		Hitbox:BeginCast(0.25)
	end))

	self.Thread.Job:Task(Animation:GetMarkerReachedSignal("end"):Connect(function()
		self:Close()
	end))
	
	Animation:Play()
	self:FireReliableVFX("Stardust Crusader/Star Finger", "Start", self.StandHandler.Model)
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