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
	return self:BasicConditions() and not self.Combat:GetState("Blocking") and not self:HasCertainCooldown("AntiInfCombo")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(5)

	self.HitFinisher = false
	self.Hit = false

	local SFX = nil

	local M1Attack, M1Matched = self.Combat:MatchAttack("M1", Enum.UserInputType.MouseButton1)
	
	if M1Matched then
		M1Attack:AntiM1ResetTech()
	end

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -4.5)
	Hitbox.Params.Size = Vector3.new(6.5, 6, 8)
	Hitbox.Params.DestroyOnEndCast = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat
	
		local FinishersEnabled = self:IsFinisherEnabled();
		local Activate_Finisher = FinishersEnabled and VictimLuaCharacter.Humanoid.Health <= 10 and not self.HitFinisher
		
		self.Hit = self:Afflict(VictimLuaPlayer, {
			Damage = {Amount = 0.3, DontKill = FinishersEnabled and not self.HitFinisher},
			Stun = 0.6,
			DontRestartRespawnTimer = true
		})

		if self.Hit then
			if Activate_Finisher then
				self.HitFinisher = true
				
				local VictimAnimation : AnimationTrack = VictimLuaCharacter.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Reigen["SELF DEFENSE RUSH!!!"].FinisherVictim)
				local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0))
				
				self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
				self:CreateMoveSFX("Reigen", "Self Defense Rush", "FinisherSFX")
				self.Combat:DivideSpeed(50)
				
				VictimLuaCharacter:StopRespawnTimer()
				
				self.Thread.OnClosed:Connect(function()
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
					
					VictimAnimation:Stop(0)
					
					self.Combat:TimesSpeed(50)
					self:FireReliableVFX("Reigen/Self Defense Rush", "FinisherEnd", self.LuaPlayer.Player)
					
					VictimLuaCharacter:RestartRespawnTimer()
				end)
			
				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("end"):Connect(function()
					GrabObject.Destroy()
					
					self.Hit = self:Afflict(VictimLuaPlayer, {
						FinisherKill = true,
						Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 85 + Vector3.yAxis * 30, 0.1},
					})
					
					task.wait(1)
					
					self:Close()
				end))

				self.Animations.Windup:Stop(0.2)
				self.Animations.Finisher:Play(0.2)
				VictimAnimation:Play(0.2)
				
				if SFX then
					SFX:Destroy()
				end
				
				self:FireReliableVFX("Reigen/Self Defense Rush", "FinisherStart", self.LuaPlayer.Player)

				Hitbox:EndCast()
				self.LuaPlayer.Replication.Attributes:SetAttribute("SelfDefenseRush", nil)
			else
				self:FireReliableVFX("Global/M1", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, math.random(1, 3))
				VictimCombat:PlayRandomHitReaction(4)
			end
		end

		task.delay(0.05, function()
			Hitbox:RemoveHumanoid(VictimLuaCharacter.Humanoid)
		end)
	end)

	self.Thread.OnClosed:Connect(function()
		self.LuaPlayer.Replication.Attributes:SetAttribute("SelfDefenseRush", nil)

		if M1Matched then
			if M1Attack.Downslammed then
				M1Attack.Count = 3
			end
			
			M1Attack.ResetTime = time()
		end
		
		self:AddCooldown(15)
		
		self.Combat:TimesSpeed(5)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("start"):Connect(function()
		SFX = self.Thread.CancelJob:Task(self:CreateMoveSFX("Reigen", "Self Defense Rush"))
		
		self.LuaPlayer.Replication.Attributes:SetAttribute("SelfDefenseRush", true)
		self:FireReliableVFX("Reigen/Self Defense Rush", "Barrage", self.LuaCharacter.Model)

		Hitbox:BeginCast()
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Connect(function()
		Hitbox:EndCast()
		self.LuaPlayer.Replication.Attributes:SetAttribute("SelfDefenseRush", nil)

		if not self.Hit then
			self.Combat:TimesSpeed(3)

			self.Thread.OnClosed:Connect(function()
				self.Combat:DivideSpeed(3)
			end)

			task.wait(0.55)
		end

		self:Close()
	end))
end


function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.AnimationSettings = {
		FadeTime = 0.075,
		Weight = 1,
		Speed = 1
	}
	
	self.TryToCancelMoves = true
	self.HitFinisher = false
	self.Hit = false

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack