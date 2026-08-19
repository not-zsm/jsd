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

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

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

	local Root : BasePart = self.Combat:GetSimulatedRoot()

	local TripHitbox = self:CreateHitbox(true)
	TripHitbox.Params.MaxTargets = -1
	TripHitbox.Params.Offset = CFrame.identity
	TripHitbox.Params.Size = 30
	TripHitbox.Params.DestroyOnEndCast = false
	
	local GrabHitbox = self:CreateHitbox(true)
	GrabHitbox.Params.MaxTargets = 15
	GrabHitbox.Params.Offset = CFrame.new(0, 0, -7.5)
	GrabHitbox.Params.Size = 40

	local Grabbed = {}
	
	TripHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		self:Afflict(VictimLuaPlayer, {
			DontBypassIFrames = {"Grab", "Backdash"},
			Damage = 7.5,
			Ragdoll = 3,
			Velocity = {Root.CFrame.LookVector * 10 + Vector3.yAxis * 15, 0.05}
		})
	end)
	
	GrabHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			DontBypassIFrames = {"Grab", "Backdash"},
		})
		
		if Validated and not Grabbed[VictimLuaPlayer] then
			local GrabJob = Job.new()
			
			local OriginalCount = Utility.TableCount(Grabbed)
			local NewCount = (OriginalCount + 1)
			
			local Z_Offset = -20 - (NewCount * 4)
			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, Z_Offset) * CFrame.Angles(0, math.pi, 0))
			
			local Animation : AnimationTrack = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Mori["Staff Whiplash"]["Victim" .. math.random(1, 2)])
		
			--self.Thread.Job:Task(RunService.PreAnimation:Connect(function()
			--	Animation.TimePosition = self.Animations.Windup.TimePosition - (244 / 60)
			--end))
			
			GrabJob:Task(function()
				Animation:Stop(0)
				GrabObject.Destroy(0)
				VictimCombat:Unstun()
			end)
			
			Grabbed[VictimLuaPlayer] = GrabJob
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(15)
		
		self.Combat:TimesSpeed(50)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("spin_trip"):Connect(function(Parameter : string)
		if (Parameter == "true") then
			local SpinVelocity = self.Combat:Velocity()
			SpinVelocity.Settings.Duration = 1.35
			SpinVelocity.Settings.RemoveTime = SpinVelocity.Settings.Duration
			SpinVelocity.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
			SpinVelocity.Settings.Controllable = true
			SpinVelocity.Settings.FixScale = true
			SpinVelocity.Settings.Z = 25
			SpinVelocity:Fire()
			
			TripHitbox:BeginCast()
		else
			TripHitbox:EndCast()
		end
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("spin_grab"):Connect(function()
		local SpinVelocity = self.Combat:Velocity()
		SpinVelocity.Settings.Duration = 1.4
		SpinVelocity.Settings.RemoveTime = SpinVelocity.Settings.Duration
		SpinVelocity.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		SpinVelocity.Settings.Controllable = true
		SpinVelocity.Settings.FixScale = true
		SpinVelocity.Settings.Z = 30
		SpinVelocity:Fire()
		
		GrabHitbox:Detect()
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("slam"):Connect(function()
		for VictimLuaPlayer, GrabJob in Grabbed do
			GrabJob:Destroy()
			VictimLuaPlayer.Character.Combat.Ragdoll:Toggle(true, 2)
		end
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Connect(function()
		self:Close()
	end))

	self:FireReliableVFX("Mori/Staff Whiplash", "Start", self.LuaCharacter.Model)
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