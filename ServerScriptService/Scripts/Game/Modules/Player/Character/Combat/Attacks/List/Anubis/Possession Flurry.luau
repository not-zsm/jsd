local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Anubis_Utility = require("./Anubis Utility")

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
	self.Combat:DivideSpeed(self.SpeedReduction)

	self.HitFinisher = false
	self.Hit = false
	self.HitType = nil
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(self.Cooldown)
		
		self.Combat:TimesSpeed(self.SpeedReduction)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(task.delay(self.TimeUntilMoveTimesOut, function()
		if self.HitFinisher then
			return
		end
		
		self:Close()
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("End"):Once(function()
		if self.HitFinisher then
			return
		end
		
		self:Close()
	end))
	
	local SFX = self.Thread.CancelJob:Task(self:CreateMoveSFX("Anubis", script.Name, "Flurry"))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Hitbox"):Connect(function(HitEffect)
		local IsFinal = (HitEffect == "HitEffectSlash")
		
		local Hitbox = self:CreateHitbox()
		Hitbox.Params.Offset = if IsFinal then CFrame.new(0, 0, -3.5) else CFrame.new(0, 0, -7)
		Hitbox.Params.Size = if IsFinal then vector.create(10, 7, 10) else vector.create(6, 7, 14)
		
		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat
			
			local FinishersEnabled = self:IsFinisherEnabled();
			local WillFinish = FinishersEnabled and IsFinal and VictimLuaCharacter.Humanoid.Health <= 8 and not self.HitFinisher
			
			self.Hit, self.HitType = self:Afflict(VictimLuaPlayer, {
				Damage = {Amount = if IsFinal then 8 else 1, DontKill = FinishersEnabled and not self.HitFinisher},
				Stun = not IsFinal and 0.6 or 0.25,
				Ragdoll = if IsFinal then 1.5 else nil,
				BreakBlock = IsFinal,
				
				Velocity = if IsFinal then 
					{self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 5 + (self.LuaCharacter.RootPart.CFrame.RightVector * 75) + vector.create(0, 15, 0), 0.1} 
					else 
					{self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 10 + (self.LuaCharacter.RootPart.CFrame.LookVector * 15), 0.1}
				,
				
				DontRestartRespawnTimer = true,
				PlayRandomHitReaction = true,
				YDifferenceValue = -2
			})
			
			if self.Hit then
				self:FireReliableVFX(self.InternalEffectPath, "Emit", VictimLuaCharacter.RootPart, HitEffect)
				
				if not self.HitFinisher and WillFinish and IsFinal then
					self.HitFinisher = true

					local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -8.3) * CFrame.Angles(0, math.pi, 0))

					self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
					self.Combat:DivideSpeed(50)
					VictimLuaCharacter:StopRespawnTimer()

					self.Thread.OnClosed:Connect(function()
						GrabObject.Destroy(0)
						VictimCombat:Unstun()
						
						self.Combat:HideUI(false)
						VictimCombat:HideUI(false)

						self.Combat:TimesSpeed(50)
						VictimLuaCharacter:RestartRespawnTimer()
						
						self.Combat:StackState("HitboxImmunity", false)
						VictimCombat:StackState("HitboxImmunity", false)
					end)

					self.Thread.Job:Task(self.Animations.FinisherEnd.Ended:Once(function()
						self:Close()
					end))

					self.Thread.Job:Task(task.delay(130/60, function()
						GrabObject.Destroy(0)

						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							FinisherKill = true,
						})
						
						VictimCombat:Unstun()
					end))

					self.Animations.Windup:Stop(0)

					if SFX then
						SFX:Destroy()
					end
					
					self.Combat:StackState("HitboxImmunity", true)
					VictimCombat:StackState("HitboxImmunity", true)
					
					self.Combat:HideUI(true)
					VictimCombat:HideUI(true)
					
					self.Animations.FinisherEnd:Play()
					self:FireReliableVFX(self.InternalEffectPath, "Finisher", self.LuaCharacter.Model, VictimLuaCharacter.Model)
				end
			end
		end)
		
		Hitbox:BeginCast(0.05) 
		
		if IsFinal then
			Hitbox.Events.OnCastEnded:Connect(function()
				if self.HitType == "Blocked" or not self.Hit then
					self.Animations.Windup:AdjustSpeed(0.75)
				end
			end)
		end
	end))
	
	if self.LuaPlayer.IsNPC then
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 2
		VelocityObject.Settings.RemoveTime = 1.8
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 90000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 14;
		VelocityObject:Fire();
	end;
	
	self:FireReliableVFX(self.InternalEffectPath, "Start", self.LuaCharacter.Model)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	
	self.Cooldown = 15
	
	self.TimeUntilMoveTimesOut = 4
	self.SpeedReduction = 4
	
	self.InternalEffectPath = `Anubis/{script.Name}`
	
	self:_Init()
	
	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack