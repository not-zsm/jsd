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
local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Hit = false
	
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(200)

	self.Thread.OnClosed:Connect(function()
		self.Combat:RemoveActiveCounter()
		
		self:AddCooldown(18)
		
		self.Combat:TimesSpeed(200)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Connect(function()
		self:Close()
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("counter"):Connect(function(Parameter : string)
		if (Parameter == "true") then
			self.Animations.Windup:AdjustSpeed(1)
			
			self.Combat:CreateCounter(1, function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat
				
				local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -3.9) * CFrame.Angles(0, math.pi, 0))
				local VictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Mori[script.Name].Victim)

				self.Animations.Windup:Stop(0)
				self.Animations.Hit:Play(0)

				if VictimAnimation then
					VictimAnimation:Play(0) -- Looks weird on 0.1.
				end
				
				self.Thread.OnClosed:Connect(function()
					if not GrabObject.Destroyed then
						GrabObject.Destroy(0)
						VictimCombat:Unstun()
					end
					
					if VictimAnimation then
						VictimAnimation:Stop()
					end
				end)
				
				if VictimAnimation then
					self.Thread.Job:Task(VictimAnimation:GetMarkerReachedSignal("booms"):Connect(function()
						self:Afflict(VictimLuaPlayer, {
							DontCheckBlock = true,
							Damage = {Amount = 1.5, DontKill = true}
						})
						
						self.Thread.Job:Task(task.delay(0.14, function()
							self:Afflict(VictimLuaPlayer, {
								DontCheckBlock = true,
								Damage = {Amount = 1.5, DontKill = true}
							})
						end))

						self.Thread.Job:Task(task.delay(0.28, function()
							self:Afflict(VictimLuaPlayer, {
								DontCheckBlock = true,
								Damage = 3.5
							})
						end))
					end))
					
					self.Thread.Job:Task(VictimAnimation.Stopped:Once(function()
						VictimCombat:StackState("ForceDashPush", true, 1.5)

						self.Combat:TSBPushVictim(VictimLuaPlayer, {
							Difference = Utility.Seed:NextUnitVector(),
							LandedRollVelocityZ = 155,
							LandedRollDuration = 0.9
						})
					end))
				end
				
				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("hit"):Connect(function()
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = {Amount = 1.5, DontKill = true}
					})
				end))
				
				local StopRotate = self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
				
				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("zap"):Connect(function()
					GrabObject.Destroy(1)
					VictimCombat:Unstun()
					VictimCombat:TrueStun(1.5)
					
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = {Amount = 4, DontKill = true}
					})
					
					VictimLuaCharacter:SetCollisionGroup("NoPlayerCollision")
					
					self.Thread.OnClosed:Connect(function()
						if not VictimCombat:GetState("Grabbed") and not VictimCombat:GetState("Pushed") then
							VictimLuaCharacter:SetCollisionGroup("Player")
						end
					end)

					self.LuaCharacter.Model:PivotTo(VictimLuaCharacter.RootPart.CFrame * CFrame.new(0, 0, 2.5) * CFrame.Angles(0, math.pi, 0))
					
					self.Animations.Hit:Stop(0)
					self.Animations.Slide:Play(0)

					self:FireReliableVFX(`Mori/{script.Name}`, "Zap", self.LuaCharacter.Model, VictimLuaCharacter.Model)
					
					local VelocityObject = self.Combat:Velocity()
					VelocityObject.Settings.Duration = 0.9
					VelocityObject.Settings.RemoveTime = 0.9
					VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
					VelocityObject.Settings.Controllable = true
					VelocityObject.Settings.Z = 65
					VelocityObject:Fire()

					self.Thread.Job:Task(VelocityObject)
					
					StopRotate:Destroy()
				end))
				
				self.Thread.Job:Task(task.delay(78 / 60, function()
					self:Close()
				end))
				
				print("fire reliable")
				self:FireReliableVFX(`Mori/{script.Name}`, "Hit", self.LuaCharacter.Model, VictimLuaCharacter.Model)
			end)
			
		else
			self.Animations.Windup:AdjustSpeed(0.3)
			self.Combat:RemoveActiveCounter()
		end
	end))
	
	self:FireReliableVFX(`Mori/{script.Name}`, "Start", self.LuaCharacter.Model)
end


function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.AnimationSettings = {Speed = 3}
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack