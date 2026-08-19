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

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:Activate()
	self.Combat:StackState("HitboxImmunity", true)
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(100)
	
	local NoRotate = self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

	local Hitbox = self:CreateHitbox()
	Hitbox.Params.Size = Vector3.new(15, 4, 8)
	Hitbox.Params.Offset = CFrame.new(0, 0, -3)
	Hitbox.Params.DestroyOnEndCast = false
	Hitbox.Params.MaxTargets = 1

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local Validated, Type = self:Afflict(VictimLuaPlayer, {
			DontCheckBlock = true
		})

		if Validated then
			self.Hit = true
			self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -4.224) * CFrame.Angles(0, math.pi, 0))
			local VictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Chara["Death Charge"].Victim)

			self.Animations.Windup:Stop(0)
			self.Animations.Hit:Play(0)

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

			self.Thread.Job:Task(self.Animations.Hit.Stopped:Connect(function()
				self:Close()
			end))

			self:FireReliableVFX("Chara/Death Charge", "Hit", self.LuaCharacter.Model, VictimLuaCharacter.Model)
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(30)

		self.Combat:TimesSpeed(100)
		
		self.Combat:StackState("HitboxImmunity", false)
		self.Combat:StackState("Attacking", false)
	end)
	
	local Connection : RBXScriptConnection; Connection = self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
		if (Parameter == "2") then
			Connection:Disconnect()
			
			if NoRotate then
				NoRotate:Destroy()
			end
		end
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Once(function()
		Hitbox:Detect()
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Once(function()
		self:Close()
	end))

	self:FireReliableVFX("Chara/Death Charge", "Start", self.LuaCharacter.Model)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.Hit = false
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack