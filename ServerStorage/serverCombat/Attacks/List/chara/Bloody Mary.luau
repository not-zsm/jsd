

local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )
local VelocityUtil = require( replicatedStorage.modules.shared.Game.Velocity.VelocityUtil )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)

	self.Hit = false
	
	local SlashHitbox = self:CreateHitbox(false);
	SlashHitbox.Params.Offset = CFrame.new(0, 1, -3.5)
	SlashHitbox.Params.Size = Vector3.new(8, 8, 8.5)
	SlashHitbox.Params.DestroyOnEndCast = false
	SlashHitbox.Params.MaxTargets = 1
	
	local KickHitbox = self:CreateHitbox(false);
	KickHitbox.Params.Offset = CFrame.new(0, 1, 0)
	KickHitbox.Params.Size = Vector3.new(10, 8, 13)
	KickHitbox.Params.DestroyOnEndCast = false
	KickHitbox.Params.MaxTargets = 1
	
	local Velocity
	
	SlashHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true
		})

		if Validated then
			SlashHitbox:EndCast()
			
			if Velocity then
				Velocity:Destroy()
			end

			self.Hit = true
			self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
			
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat
			
			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart)
			
			local VictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(replicatedStorage.animations.Attacks.chara["Bloody Mary"].Victim)
			local FinisherVictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(replicatedStorage.animations.Attacks.chara["Bloody Mary"].FinisherVictim)
			
			self.Animations.Windup:Stop()
			self.Animations.Hit:Play()
			
			if VictimAnimation then
				VictimAnimation:Play(0) -- Looks weird on 0.1.
			end
			
			self.Thread.OnClosed:Connect(function()
				if VictimAnimation then
					VictimAnimation:Stop()
				end
				
				if not GrabObject.Destroyed then
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end
			end)
			
			local function Damage(Value : number)
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {DontKill = true, Amount = Value},
				})
			end
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("finisher"):Connect(function()
				if (VictimLuaCharacter.Humanoid.Health <= 15 and RunService:IsStudio() and not self.Thread.Closed) then
					self.Combat:StackState("HitboxImmunity", true)
					VictimCombat:StackState("HitboxImmunity", true)
					
					self.Combat:DivideSpeed(100)
					
					self.Thread.OnClosed:Connect(function()
						self.Combat:TimesSpeed(100)
						
						self.Combat:StackState("HitboxImmunity", false)
						VictimCombat:StackState("HitboxImmunity", false)
					end)
					
					self.Animations.Hit:Stop(0)

					if VictimAnimation then
						VictimAnimation:Stop(0)
					end
					
					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("kill"):Connect(function()
						GrabObject.Destroy(0)

						if FinisherVictimAnimation then
							FinisherVictimAnimation:Stop(0)
						end
						
						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							FinisherKill = true,
							Ragdoll = 2,
						})
						
						VictimCombat:Unstun()
					end))
					
					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("end"):Connect(function()
						self:Close()
					end))
					
					self.Animations.Finisher:Play(0)
					
					if FinisherVictimAnimation then
						FinisherVictimAnimation:Play(0) -- Looks weird on 0.1.
					end
					
					self:FireReliableVFX("Chara/Bloody Mary Finisher", "Start", self.LuaCharacter.Model, VictimLuaCharacter.Model)
				end
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("knee"):Connect(function(Parameter : string)
				if (Parameter == "true") then
					Damage(1)
				else
					Damage(2)
				end
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("slash"):Once(function()
				Damage(2)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("kick"):Once(function()
				Damage(1)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("stab"):Once(function()
				Damage(4)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("finalhit"):Connect(function(Parameter : string)
				if (Parameter == "true") then
					Damage(2)
					
					return
				end
				
				self.Animations.Hit:AdjustSpeed(0.9)
				
				GrabObject.Destroy(1.4)
				VictimAnimation:Stop(0)
				
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = 3,
					Velocity = {self.LuaCharacter.RootPart.CFrame.RightVector * 70 + Vector3.yAxis * 35, 0.05},
					Ragdoll = 1.4,
				})
				
				if not VictimLuaCharacter.HumanoidAlive then
					VictimCombat:SetFinisherKillIFrames()
				end
		
				--self.Combat:PushSkidVictim(VictimLuaPlayer, {
				--	TimeTilGroundDetection = 0.35,
				--	StartVelocityXZ = self.LuaCharacter.RootPart.CFrame.RightVector * 55,
				--	StartVelocityY = Vector3.yAxis * 105,
				--	StartDuration = 0.6,
				--	LandedRollVelocityZ = 140,
				--	LandedRollDuration = 0.79
				--})
				
				VictimCombat:Unstun()
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("end"):Connect(function()
				self:Close()
			end))
				
			self:FireReliableVFX("Chara/Bloody Mary", "Hit", self.LuaCharacter.Model, VictimLuaCharacter.Model)
		end
	end)
	
	KickHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local Validated = self:Afflict(VictimLuaPlayer, {
			YDifferenceValue = -2,
			Velocity = {self.Combat:GetSimulatedRoot().CFrame.LookVector * 27.5 + Vector3.yAxis * 25, 0.1},
			Ragdoll = 2.5,
			Damage = 4,
		})
		
		if Validated then
			self:FireReliableVFX("Chara/Bloody Mary", "Dropkick", VictimLuaPlayer.Character.Model)
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		--self:AddCooldown(21) -- when bloody mary extended
		self:AddCooldown(21)
		
		self.Combat:TimesSpeed(50)
		self.Combat:StackState("Attacking", false)
	end)

	task.spawn(function()
		if self.LuaPlayer.IsNPC then
			local Max = 52.5
			local Multiply = 0
			local FadeOut = false

			Velocity = VelocityUtil.Create(self.LuaCharacter.RootPart, "Bloody Mary Start")
			Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
			Velocity.Parent = self.LuaCharacter.RootPart

			Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
				Velocity.Velocity = self.LuaCharacter.RootPart.CFrame.LookVector * Multiply
			end)

			local StartFadeInJob; StartFadeInJob = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
				if Multiply <= -25 then
					return StartFadeInJob:Destroy()
				end

				Multiply -= (Delta * 60) * 2
			end)

			self.Thread.Job:Task(Velocity)

			self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("kick"):Connect(function()
				Multiply *= 1.75

				self.Thread.Job:Task(task.delay(0.4, function()
					local Job; Job = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
						if Multiply < 0 then
							Multiply = math.clamp(Multiply + (Delta * 60) * 1.3, -Max, 0)
						else
							Job:Destroy()
						end
					end)
				end))
			end))

			self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("dash"):Connect(function()
				Multiply = 100

				Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
					Multiply = math.clamp(Multiply - (Delta * 60) * 0.85, 0, Max)
				end)
			end))
		end
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("kick"):Once(function()
		KickHitbox:BeginCast(0.175)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Once(function()
		SlashHitbox.Events.OnCastEnded:Once(function()
			if not self.Hit then
				self.Animations.Windup:AdjustSpeed(0.8)
			end
		end)
		
		SlashHitbox:BeginCast(0.325)
	end))
		
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Once(function()
		if not self.Hit then
			self:Close()
		end
	end))
	
	self:FireReliableVFX("Chara/Bloody Mary", "Start", self.LuaCharacter.Model)
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