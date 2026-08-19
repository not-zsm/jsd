local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)
	
	self.Hit = false
	local Blocked = false
	
	local BarrageHitbox = self:CreateHitbox(false);
	BarrageHitbox.Params.Offset = CFrame.identity
	BarrageHitbox.Params.Size = Vector3.new(12.5, 8, 12.5)
	BarrageHitbox.Params.DestroyOnEndCast = false
	
	self.Thread.CancelJob:Task(self:CreateMoveSFX("Reigen", "Salt Splash"))

	BarrageHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated, Type = self:Afflict(VictimLuaPlayer, {
			Damage = 0.25,
			Stun = 0.4,
			DontRestartRespawnTimer = true
		})
		
		self.Hit = Validated
		Blocked = (Type == "Blocked")

		if self.Hit then
			self:FireReliableVFX("Reigen/Salt Splash", "Hit", VictimLuaCharacter.RootPart)
			VictimCombat:PlayRandomHitReaction(4)
		end

		task.delay(0.1, function()
			BarrageHitbox:RemoveHumanoid(VictimLuaCharacter.Humanoid)
		end)
	end)
	
	local EndHitbox = self:CreateHitbox(false);
	EndHitbox.Params.Offset = CFrame.identity
	EndHitbox.Params.Size = Vector3.new(12.5, 8, 12.5)
	EndHitbox.Params.DestroyOnEndCast = false

	EndHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local KnockbackVelocity : Vector3 = self.Combat:CalculateUnitDifference(VictimLuaPlayer)
		
		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true,
			Damage = 7.5,
			Ragdoll = 1,
			Velocity = {KnockbackVelocity * 75 + Vector3.yAxis * 15, 0.1},
			DontRestartRespawnTimer = true
		})

		if Validated then
			self:FireReliableVFX("Reigen/Salt Splash", "Hit", VictimLuaCharacter.RootPart)
			VictimCombat:PlayRandomHitReaction(4)
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(15)
		
		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("stepback"):Connect(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 0.66
		VelocityObject.Settings.RemoveTime = 0.66
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = -120
		VelocityObject:Fire()
		
		self.Thread.Job:Task(VelocityObject)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("shine"):Connect(function()
		self.Thread.CancelJob:Task(self:CreateMoveSFX("Reigen", "Salt Splash", "Barrage"))
		self:FireReliableVFX("Reigen/Salt Splash", "Shine", self.LuaCharacter.RightArm)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("splash"):Connect(function(Value : string)
		if Value == "true" then
			self.Animations.Windup:AdjustSpeed(1)
			
			BarrageHitbox:BeginCast()
			self:FireReliableVFX("Reigen/Salt Splash", "Splash", self.LuaCharacter.RootPart, true)
			
			self.Thread.OnClosed:Connect(function()
				self:FireReliableVFX("Reigen/Salt Splash", "Splash", self.LuaCharacter.RootPart, false)
			end)
		else
			self:FireReliableVFX("Reigen/Salt Splash", "Splash", self.LuaCharacter.RootPart, false)
			
			BarrageHitbox:EndCast()
			
			if Blocked then
				self.Animations.Windup:AdjustSpeed(0.075)
				
				self.Thread.Job:Task(task.delay(0.325, function()
					self.Animations.Windup:AdjustSpeed(1)
					EndHitbox:Detect()
					
					task.wait(0.65)
					
					self:Close()
				end))
			else
				EndHitbox:Detect()
				
				task.wait(self.Hit and 0.15 or 0.65)
				
				self:Close()
			end
		end
	end))
end


function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.AnimationSettings = {FadeTime = 0.035, Speed = 1.175}
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack