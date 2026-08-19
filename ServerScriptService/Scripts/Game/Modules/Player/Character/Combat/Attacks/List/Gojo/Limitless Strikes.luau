local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

----------------------------------------------------------------------------------

local Attack = {}
Attack.__index = Attack

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self.Thread.CancelJob:Task(self:CreateMoveSFX("Gojo", "Limitless Strikes"))

	self.Hit = false

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, -1, -2)
	Hitbox.Params.Size = Vector3.new(6, 3.5, 7)
	Hitbox.Params.DestroyOnEndCast = false
	Hitbox.Params.MaxTargets = 1

	local Blocked = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated, Type = self:Afflict(VictimLuaPlayer, {
			YDifferenceValue = -2
		})

		Blocked = (Type == "Blocked")

		if Validated then
			self.Hit = true

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart)
			local VictimAnimation : AnimationTrack = VictimLuaCharacter.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Gojo["Limitless Strikes"].Victim)

			local Ended = false
			local FinisherActivated = false

			local SFX = self.Thread.CancelJob:Task(self:CreateMoveSFX("Gojo", "Limitless Strikes", "Hit"))

			local function Hit(Count : number, Damage : number)
				if Damage then		
					local VelocityObject = self.Combat:Velocity()
					VelocityObject.Settings.Duration = 0.55
					VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
					VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
					VelocityObject.Settings.Controllable = true
					VelocityObject.Settings.Z = 27.5 * (Damage * 1.5)
					VelocityObject:Fire()

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = {
							DontKill = true,
							Amount = Damage
						}
					})
				end

				self:FireReliableVFX("Gojo/Limitless Strikes", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, Count)

				local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -2), Vector3.one * 8)

				AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
					local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
						Damage = 1,
						Stun = 0.6
					})

					if Validated then
						NewVictimLuaPlayer.Character.Combat:PlayRandomHitReaction()
					end
				end)

				AOEHitbox:BeginCast(0.05)
			end

			Hit(1, 2.5)

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("hit"):Connect(function(Parameter : string)
				Hit(tonumber(Parameter), 1.5)
				
				if VictimLuaCharacter.Humanoid.Health <= 7.5 then
					local FinisherEnded = false
					
					self.Combat:StackState("HitboxImmunity", true)
					VictimCombat:StackState("HitboxImmunity", true)
					
					self.Animations.Hit:Stop(0)
					VictimAnimation:Stop(0)

					self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
					
					local FinisherVictimAnimation = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Gojo["Limitless Strikes"].FinisherVictim)
					local FinisherEndlag = 0.6
					
					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("grab"):Connect(function()
						self.Thread.CancelJob:Task(self:CreateMoveSFX("Gojo", "Limitless Strikes Finisher"))
						self:FireReliableVFX("Gojo/Limitless Strikes Finisher", "Grab", self.LuaCharacter.RootPart)
					end))
					
					--task.delay(0.4, SFX.Destroy, SFX)
					SFX:Destroy()
					
					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("charge"):Connect(function(Type : string)
						self:FireReliableVFX("Gojo/Limitless Strikes Finisher", "Charge", self.LuaCharacter.RootPart, Type)
					end))
					
					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("blast"):Connect(function(Type)
						self:FireReliableVFX("Gojo/Limitless Strikes Finisher", "Blast", self.LuaCharacter.RootPart, VictimLuaCharacter.Model, Type)

						if Type == "right" then
							Ended = true

							if FinisherVictimAnimation then
								FinisherVictimAnimation:Stop(0)
							end
							
							GrabObject.Destroy(FinisherEndlag)
							
							VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -2) * CFrame.Angles(0, math.pi, 0))

							self:Afflict(VictimLuaPlayer, {
								ExcludeAttempts = true,
								FinisherKill = true,
								Velocity = {Vector3.yAxis * -5, 0.1},
							})

							VictimCombat:Unstun()
							
							FinisherEnded = true
							
							task.wait(FinisherEndlag)
							
							self:Close()
						end
					end))
					
					self.Thread.OnClosed:Connect(function()
						if FinisherVictimAnimation then
							FinisherVictimAnimation:Stop()
						end
					
						self.Combat:StackState("HitboxImmunity", false)
						
						if not FinisherEnded then
							VictimCombat:StackState("HitboxImmunity", false)
						end
					end)

					self.Animations.Finisher:Play(0)
					
					if FinisherVictimAnimation then
						FinisherVictimAnimation:Play(0)
					end
				end
			end))

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("uppercut"):Once(function()
				Hit(2, 2.5)
			end))

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("kickpause"):Once(function()
				Hit(3, 3)
			end))

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("end"):Once(function()
				Ended = true

				local Endlag = 0.1

				--VictimCombat:StackState("BackdashIFrames", true, 0.35 + VictimLuaPlayer:GetPing()) -- so u cant shove tech
				GrabObject.Destroy(Endlag)

				VictimAnimation:Stop(0)
				VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 3.5, -9) * CFrame.Angles(0, math.pi, 0))

				local Finisher = (VictimLuaCharacter.Humanoid.Health <= 5)

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = 3
				})

				if Finisher then
					self:FireReliableVFX("Gojo/Limitless Strikes", "FinisherLastHit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)

					self:Afflict(VictimLuaPlayer, {
						FinisherKill = true,
						ExcludeAttempts = true,
					})

					local VelocityObject = self:VelocityOn(VictimCombat)
					VelocityObject.Settings.RemoveTime = 0.1
					VelocityObject.Settings.Velocity = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 75 + Vector3.yAxis * 27.5
					VelocityObject:Fire()

					VictimCombat.Ragdoll:Toggle(true)
				else
					Hit(4)
					
					local VelocityObject = self:VelocityOn(VictimCombat)
					VelocityObject.Settings.RemoveTime = 0.1
					VelocityObject.Settings.Velocity = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 70 + Vector3.yAxis * 30
					VelocityObject:Fire()
					
					VictimCombat:StackState("BackdashIFrames", true, 1);
					
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true;
						Ragdoll = 1.3;
					})
					--VictimCombat.Ragdoll:Toggle(true, 1.3)
				end

				task.wait(Endlag)

				self:Close()
			end))

			self.Animations.Windup:Stop()
			self.Animations.Hit:Play()
			VictimAnimation:Play(0)

			self.Thread.OnClosed:Connect(function()
				if not Ended then
					self.Animations.Hit:Stop()
					VictimAnimation:Stop()
				end

				GrabObject.Destroy(0)
				VictimCombat:Unstun()
			end)
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(19)

		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("jump"):Once(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 0.75
		VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 50
		VelocityObject:Fire()

		self.Thread.Job:Task(VelocityObject)
		
		self.Animations.Windup:AdjustSpeed(1.25)
	end))

	local HitboxTime = 0.05

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Once(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 0.65
		VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 37.5
		VelocityObject:Fire()

		self.Thread.Job:Task(VelocityObject)

		Hitbox:BeginCast(HitboxTime)
	end))

	Hitbox.Events.OnCastEnded:Wait()

	if Blocked then
		self.Animations.Windup:AdjustSpeed(0.85)
	end

	task.wait(0.75 + HitboxTime)

	if not self.Hit then
		self:Close()
	end
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