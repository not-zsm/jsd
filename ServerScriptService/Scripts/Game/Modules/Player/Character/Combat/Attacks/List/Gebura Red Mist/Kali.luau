local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local EventService = require(ReplicatedStorage.Modules.Shared.Utilities.EventService)

local VFX_Path = "Gebura Red Mist/Kali"

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
	self.Combat:DivideSpeed(20)
	
	local Reference = self.Thread.Job:Task(Instance.new("Configuration"))
	Reference.Name = "Kali-ReferenceBoost"
	Reference.Parent = self.LuaCharacter.Model
	self.Thread.Job:Task(task.delay(1.7 + (71/60), Reference.Destroy, Reference))
	
	local SpinningHitbox = self:CreateHitbox(true);
	SpinningHitbox.Params.Offset = CFrame.identity
	SpinningHitbox.Params.Recursive = true
	SpinningHitbox.Params.Size = 15
	
	local SpinningHitboxTargets = {}

	SpinningHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat
		
		if SpinningHitboxTargets[VictimLuaCharacter.Model] then
			return
		end
		
		SpinningHitboxTargets[VictimLuaCharacter.Model] = true
		
		task.delay(0.05, function()
			SpinningHitboxTargets[VictimLuaCharacter.Model] = nil
		end)
		
		self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			BreakBlock = true,
			Damage = 1,
			TrueStun = 0.75,
			PlayRandomHitReaction = true
		})
	end)
	
	local SlamHitbox = self:CreateHitbox(true);
	SlamHitbox.Params.Offset = CFrame.new(0, 0, -10.5)
	SlamHitbox.Params.Size = 10
	
	SlamHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			DontBypassIFrames = {},
			BreakBlock = true,
			Ragdoll = 3,
			Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 5 + Vector3.yAxis * 100, 0.1},
			Damage = 40
		})

		if Validated then
			self.Combat:VictimImpactGround(VictimLuaPlayer)
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		table.clear(SpinningHitboxTargets)
		
		self.Combat:TimesSpeed(20)
		
		self:AddCooldown(10)
		
		self.Combat:StackState("HitboxImmunity", false)
		self.Combat:StackState("Attacking", false)
	end)
	
	self:FireReliableVFX(VFX_Path, "Start", self.LuaCharacter.Model, Reference)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Enable"):Connect(function(Name)
		if Name ~= "1" then
			return
		end
		
		SpinningHitbox:BeginCast()
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Disable"):Connect(function(Name)
		if Name ~= "1" then
			return
		end

		SpinningHitbox:EndCast()
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Emit"):Connect(function(Name)
		if Name == "2" then
			SlamHitbox:Detect()
			
			task.wait(0.4)
			
			self.Animations.Windup:Stop(0.3)
		end
	end))
	
	self.Thread.Job:Task(self.Animations.Windup.Stopped:Connect(function(Name)
		if self.Hit then
			return
		end

		self:Close()
	end))
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