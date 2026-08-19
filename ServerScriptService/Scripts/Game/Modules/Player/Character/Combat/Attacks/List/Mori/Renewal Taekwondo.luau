--[[
    © 2025 swrerm. All Rights Reserved.
    Author: swrerm
    Created: July 16, 2024
    Developed under the group: Jimpee's Cabin

    Licensed for use by Jimpee's Cabin only.
    Redistribution, resale, or unauthorized use of this code, 
    in whole or in part, without express permission from the author
    is strictly prohibited.

    This script is the original work of the author listed above.

    Contacts:
      wboyd4029@gmail.com
      jimpeeisbusiness@gmail.com
--]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

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
	
	local Can_Times = true

	local Hitbox = self:CreateHitbox()
	Hitbox.Params.Offset = CFrame.new(0, 0, -4)
	Hitbox.Params.Size = Vector3.new(6.5, 5.5, 6.75)
	Hitbox.Params.DestroyOnEndCast = false
	
	local GotYoShitBlockedTwin = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		if Hitbox.HitCount > 1 then
			self:Afflict(VictimLuaPlayer, {
				DontBypassIFrames = {"Grab", "Backdash"},
				Damage = 2,
				TrueStun = 1.3,
				PlayRandomHitReaction = true,
				Velocity = {self.Combat:GetSimulatedRoot().CFrame.LookVector * 25, 0.225}
			})
		else
			local Validated, Type = self:Afflict(VictimLuaPlayer, {
				DontBypassIFrames = {"Grab", "Backdash"},
				--BreakBlock = true,
				YDifferenceValue = -2,
				Damage = {Amount = 1, DontKill = true}
			})
			
			GotYoShitBlockedTwin = (not Validated and Type == "Blocked")
			
			if Validated then
				self.Combat:DivideSpeed(100)

				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat

				local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.Angles(0, math.pi, 0))
				
				self.VictimAnimations.Grab = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Mori["Renewal Taekwondo"].Victim)
				self.VictimAnimations.GrabFinisher = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Mori["Renewal Taekwondo"].FinisherVictim)
				
				local VictimAnimation, FinisherVictimAnimation = self.VictimAnimations.Grab, self.VictimAnimations.GrabFinisher;
				
				self.Animations.Windup:Stop(0)
				self.Animations.Hit:Play(0);

				if self.VictimAnimations.Grab then
					VictimAnimation:Play(0) -- Looks weird on 0.1.
				end
				
				local ActivateFinisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health < 12.5)--15)

				self.Thread.OnClosed:Connect(function()
					self.Combat:TimesSpeed(100)

					if VictimAnimation then
						VictimAnimation:Stop()
					end
					
					if FinisherVictimAnimation then
						FinisherVictimAnimation:Stop()
					end
					
					if self.Animations.Finisher and self.Animations.Finisher.IsPlaying then
						self.Animations.Finisher:Stop(0)
					end
					
					if not GrabObject.Destroyed then
						GrabObject.Destroy(0)
						VictimCombat:Unstun()
					end
				end)
				
				local function Finisher()
					self.Combat:StackState("HitboxImmunity", true)
					VictimCombat:StackState("HitboxImmunity", true)

					VictimLuaCharacter:StopRespawnTimer()

					self.Combat:HideUI(true)
					VictimCombat:HideUI(true)

					self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
					
					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("10"):Connect(function()
						local AOEHitbox = self.Thread.Job:Task(self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(5, -1, 0), Vector3.one * 15))

						AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
							self.Combat:Afflict(NewVictimLuaPlayer, {
								BreakBlock = true,
								Damage = 5,
								Ragdoll = 2,
								Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 15 + Vector3.yAxis * 20, 0.1}
							})
						end)

						AOEHitbox:Detect()
					end))
						
					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("20"):Connect(function()
						FinisherVictimAnimation:Stop(0)
						
						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							FinisherKill = true,
							Velocity = {self.LuaCharacter.RootPart.CFrame.RightVector * 100 + Vector3.yAxis * 50, 0.1}
						})
						
						local AOEHitbox = self.Thread.Job:Task(self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(17.5, 0, 0), Vector3.new(37.5, 35, 20)))
						
						AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
							self.Combat:Afflict(NewVictimLuaPlayer, {
								BreakBlock = true,
								Damage = 10,
								Ragdoll = 2.5,
								Velocity = {self.LuaCharacter.RootPart.CFrame.RightVector * 50 + Vector3.yAxis * 35, 0.1}
							})
						end)
	
						AOEHitbox:BeginCast(0.3)
		
						GrabObject.Destroy(0)
						VictimCombat:Unstun()
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("end"):Once(function()
						self:Close()
					end))

					self.Thread.OnClosed:Connect(function()
						VictimLuaCharacter:RestartRespawnTimer()

						self.Combat:HideUI(false)
						VictimCombat:HideUI(false)

						self.Combat:StackState("HitboxImmunity", false)
						VictimCombat:StackState("HitboxImmunity", false)
					end)

					self.Animations.Hit:Stop(0)
					VictimAnimation:Stop(0)

					self.Animations.Finisher:Play(0)
					FinisherVictimAnimation:Play(0)

					self:FireReliableVFX("Mori/Renewal Taekwondo Finisher", "Start", self.LuaCharacter.Model, VictimLuaCharacter.Model)
				end

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("dmg"):Connect(function(Parameter : string)
					local Damage = Utility.DecimalRound(tonumber(Parameter) / 1.3, 2)
					--print("renewal taekwondo dmg:", Damage)
					
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = {Amount = Damage, DontKill = true},
					})

					local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -3), Vector3.one * 9)

					AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
						self.Combat:Afflict(NewVictimLuaPlayer, {
							BreakBlock = true,
							Damage = (tonumber(Parameter) / 1.25),
							TrueStun = 0.75,
							PlayRandomHitReaction = true,
							Velocity = {self.Combat:GetSimulatedRoot().CFrame.LookVector * 17.5, 0.1}
						})
					end)

					AOEHitbox:Detect()
					task.delay(1 / 60, AOEHitbox.Destroy, AOEHitbox)
				end))

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
					if (Parameter == "3") then
						local VelocityObject = self.Combat:Velocity()
						VelocityObject.Settings.Duration = 0.8
						VelocityObject.Settings.RemoveTime = 0.7
						VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
						VelocityObject.Settings.Controllable = true
						VelocityObject.Settings.Z = 25
						VelocityObject:Fire()

					elseif (Parameter == "4") then
						self.Combat.Hitbox:Destruction(CFrame.new(0, 0, -3), Vector3.one * 9, 1)

					elseif (Parameter == "5") then
						local VelocityObject = self.Combat:Velocity()
						VelocityObject.Settings.Duration = 0.49
						VelocityObject.Settings.RemoveTime = 0.39
						VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
						VelocityObject.Settings.Controllable = true
						VelocityObject.Settings.Z = 30
						VelocityObject:Fire()

					elseif (Parameter == "6") then
						local VelocityObject = self.Combat:Velocity()
						VelocityObject.Settings.Duration = 0.625
						VelocityObject.Settings.RemoveTime = 0.525
						VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
						VelocityObject.Settings.Controllable = true
						VelocityObject.Settings.Z = 40
						VelocityObject:Fire()
					end
				end))

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("hit"):Connect(function()
					if ActivateFinisher then
						Finisher()
					else
						GrabObject.Destroy(0.5)
						VictimAnimation:Stop(0)

						local function EndHit(NewVictimLuaPlayer)
							local NewVictimLuaCharacter = NewVictimLuaPlayer.Character
							local NewVictimCombat = NewVictimLuaCharacter.Combat

							local Finisher = self:IsFinisherEnabled() and (NewVictimLuaCharacter.Humanoid.Health <= 3)

							local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
								ExcludeAttempts = true,
								Damage = 1.5,
							})

							if Validated then
								if Finisher then
									local VelocityObject = self:VelocityOn(NewVictimCombat)
									VelocityObject.Settings.RemoveTime = 0.1
									VelocityObject.Settings.MaxForce = Vector3.one * 80000
									VelocityObject.Settings.Velocity = -self.LuaCharacter.RootPart.CFrame.RightVector * 35 + Vector3.yAxis * 25
									VelocityObject:Fire()

									NewVictimCombat.Ragdoll:Toggle(true)
								else
									local LandedRollDuration = 0.8
									local DurationMultiplier = 1.15

									local EvasiveStateTime = (LandedRollDuration * DurationMultiplier)

									NewVictimCombat:StackState("ForceDashPush", true, 1.3)
									
									self.Combat:TSBPushVictim(NewVictimLuaPlayer, {
										Difference = -self.LuaCharacter.RootPart.CFrame.RightVector,
										DontBeginAoeHitbox = true,
										LandedRollVelocityZ = 100,
										LandedRollDuration = LandedRollDuration,
										DurationMultiplier = DurationMultiplier
									})
									
									NewVictimCombat:StackState("EvasiveState", true)

									local Thread = task.delay(EvasiveStateTime + math.clamp(self.LuaPlayer:GetPing(), 0, 1), function()
										NewVictimCombat:StackState("EvasiveState", false)
									end)

									local Connection : RBXScriptConnection; Connection = NewVictimCombat:GetStateChanged("Stunned"):Connect(function(Value : boolean)
										if Value then
											Connection:Disconnect()
											Utility.CloseThreadSafe(Thread)
											NewVictimCombat:StackState("EvasiveState", false)
										end
									end)
									
									--local LandedRollDuration = 0.8
									--local DurationMultiplier = 1.15
									
									--local EvasiveStateTime = (LandedRollDuration * DurationMultiplier)

									--NewVictimCombat:StackState("ForceDashPush", true, 1.3)

									--self.Combat:TSBPushVictim(NewVictimLuaPlayer, {
									--	Difference = -self.LuaCharacter.RootPart.CFrame.RightVector,
									--	DontBeginAoeHitbox = true,
									--	LandedRollVelocityZ = 100,
									--	LandedRollDuration = LandedRollDuration,
									--	DurationMultiplier = DurationMultiplier
									--})

									--NewVictimCombat:StackState("EvasiveState", true)

									--task.delay(EvasiveStateTime + math.clamp(self.LuaPlayer:GetPing(), 0, 1), function()
									--	NewVictimCombat:StackState("EvasiveState", false)
									--end)
								end
							end
						end

						local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -3), Vector3.one * 10)
						AOEHitbox.Events.OnLuaPlayerHit:Connect(EndHit)
						AOEHitbox:Detect()
						task.delay(1 / 60, AOEHitbox.Destroy, AOEHitbox)

						EndHit(VictimLuaPlayer)
						VictimCombat:Unstun()

						task.wait(0.3)

						self.Animations.Hit:Stop(0.3)
						self:Close()
					end
				end))

				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 0.85
				VelocityObject.Settings.RemoveTime = 0.75
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = 45
				VelocityObject:Fire()

				self:FireReliableVFX("Mori/Renewal Taekwondo", "Hit", self.LuaCharacter.Model, VictimLuaCharacter.Model)
			end
		end
	end)

	self.Thread.OnClosed:Connect(function()
		if Can_Times then
			self.Combat:TimesSpeed(10)
		end
		
		self:AddCooldown(21)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("jump"):Connect(function()
		Can_Times = false
		self.Combat:TimesSpeed(10)
		
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 0.8
		VelocityObject.Settings.RemoveTime = 0.575
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 50
		VelocityObject:Fire()
		
		self.Thread.Job:Task(VelocityObject)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("land"):Connect(function()
		self.Combat:DivideSpeed(10)
		Can_Times = true
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Connect(function()
		Hitbox:BeginCast(0.15)
		
		Hitbox.Events.OnCastEnded:Connect(function()
			if (Hitbox.HitCount == 0) then
				self.Animations.Windup:AdjustSpeed(0.7)
				
			elseif GotYoShitBlockedTwin then
				self.Animations.Windup:AdjustSpeed(0.5)
			end
		end)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Connect(function()
		self:Close()
	end))

	self:FireReliableVFX("Mori/Renewal Taekwondo", "Start", self.LuaCharacter.Model)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.AnimationSettings = {Speed = 1.15}
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack