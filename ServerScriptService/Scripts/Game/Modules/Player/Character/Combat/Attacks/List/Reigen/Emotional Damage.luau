local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

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
	self.Combat:DivideSpeed(30)
	
	self.Success = false
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(18)
		
		self.Combat:RemoveActiveCounter()
		
		self.Combat:TimesSpeed(30)
		self.Combat:StackState("Attacking", false)
	end)

	self.Combat:CreateCounter(2, function(VictimLuaPlayer)
		self.Success = true
		
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat
		
		self.Combat:StackState("HitboxImmunity", true)
		VictimCombat:StackState("HitboxImmunity", true)
		
		self.Thread.OnClosed:Connect(function()
			self.Combat:StackState("HitboxImmunity", false)
			VictimCombat:StackState("HitboxImmunity", false)
		end)
		
		self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

		local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -4) * CFrame.Angles(0, math.pi, 0))
		local VictimAnimation : AnimationTrack = VictimLuaCharacter.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Reigen["Emotional Damage"].Victim)

		local Ended = false
		
		local Ultimate, Matched = self.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

		if Matched then
			Ultimate:SetBarPausing(true)

			self.Thread.OnClosed:Connect(function()
				Ultimate:SetBarPausing(false)
			end)
		end

		self.Thread.Job:Task(self.Animations.Success:GetMarkerReachedSignal("block"):Connect(function()
			self:FireReliableVFX("Reigen/Fraud Counter", "Block", self.LuaCharacter.RootPart)
		end))
		
		self.Thread.Job:Task(self.Animations.Success:GetMarkerReachedSignal("catch"):Connect(function()
			self:FireReliableVFX("Reigen/Fraud Counter", "Catch", self.LuaCharacter.RootPart)
			
			self.LuaPlayer.Replication.Attributes:SetAttribute("ReigenCounterCamera", true)
			VictimLuaPlayer.Replication.Attributes:SetAttribute("ReigenCounterCamera", true)
			
			self:FireReliableVFXToSelf("Reigen/Fraud Counter", "Camera", self.LuaCharacter.RootPart)
			VictimLuaPlayer.Replication:FireReliableVFXToSelf("Reigen/Fraud Counter", "Camera", self.LuaCharacter.RootPart)
			
			self.Combat:HideUI(true)
			VictimCombat:HideUI(true)
			
			self.Thread.OnClosed:Connect(function()
				self.Combat:HideUI(false)
				VictimCombat:HideUI(false)
				
				self.LuaPlayer.Replication.Attributes:SetAttribute("ReigenCounterCamera", nil)
				VictimLuaPlayer.Replication.Attributes:SetAttribute("ReigenCounterCamera", nil)
			end)
		end))
		
		self.Thread.Job:Task(self.Animations.Success:GetMarkerReachedSignal("gutpunch"):Connect(function()
			self:FireReliableVFX("Reigen/Fraud Counter", "GutPunch", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
			
			self:Afflict(VictimLuaPlayer, {
				ExcludeAttempts = true,
				Damage = {
					DontKill = true,
					Amount = 20
				}
			})
		end))
		
		self.Thread.Job:Task(self.Animations.Success:GetMarkerReachedSignal("end"):Connect(function()
			self:FireReliableVFX("Reigen/Fraud Counter", "End", self.LuaCharacter.RootPart)
			
			GrabObject.Destroy(0)
			VictimAnimation:Stop(0)
			
			self:Afflict(VictimLuaPlayer, {
				ExcludeAttempts = true,
				Ragdoll = 3,
				Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 115 + Vector3.yAxis * 60, 0.1},
				Damage = 40,
			})
			
			VictimCombat:Unstun()
		end))
		
		self.Thread.Job:Task(self.Animations.Success.Stopped:Connect(function()
			self:Close()
		end))

		self.Animations.Windup:Stop()
		self.Animations.Success:Play()
		VictimAnimation:Play()
		
		self.Thread.CancelJob:Task(self:CreateMoveSFX("Reigen", "Fraud Counter"))
		
		self.Thread.OnClosed:Connect(function()
			GrabObject.Destroy(0)
			VictimCombat:Unstun()
			
			self.Animations.Success:Stop()
			VictimAnimation:Stop()
		end)
	end)

	task.wait(0.3)

	self.Animations.Windup:AdjustSpeed(0.5)

	task.wait(0.65)

	self.Combat:RemoveActiveCounter()

	task.wait(0.35)

	if not self.Success then
		self:Close()
	end
end


function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.TryToCancelMoves = true
	self.AnimationSettings = {Speed = 1.3}
	self.Success = false

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack