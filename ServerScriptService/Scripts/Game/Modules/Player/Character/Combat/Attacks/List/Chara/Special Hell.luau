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
local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )
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
	self.Available = false
	
	--if self.ResetTimer then
	--	Utility.CloseThreadSafe(self.ResetTimer)
	--end
	
	self.Combat:ChangeAttackDisplay(script.Name, script.Name, {
		Tip = "NOT READY", 
		FlashColor = Color3.fromRGB(255, 0, 0)
	})
	
	self.Combat:StackState("Attacking", true)
	self.Combat:StackState("HitboxImmunity", true)
	self.Combat:DivideSpeed(100)

	local CircleHitbox = self:CreateHitbox()
	CircleHitbox.Params.Offset = CFrame.new(0, 10, 0)
	CircleHitbox.Params.Size = Vector3.new(100, 30, 100)
	CircleHitbox.Params.MaxTargets = -1
	
	local BigBoomsHitbox = self:CreateHitbox()
	BigBoomsHitbox.Params.Offset = CFrame.new(0, 30, 0)
	BigBoomsHitbox.Params.Size = Vector3.new(125, 75, 125)
	BigBoomsHitbox.Params.MaxTargets = -1
	
	local BigBoomHitbox = self:CreateHitbox()
	BigBoomHitbox.Params.Offset = CFrame.new(0, 35, 0)
	BigBoomHitbox.Params.Size = Vector3.new(150, 125, 150)
	BigBoomHitbox.Params.MaxTargets = -1

	CircleHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			DontBypassIFrames = {},
			DontCheckBlock = true,
			Damage = 10,
			Ragdoll = 3,
			Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 25 + Vector3.yAxis * 75, 0.1}
		})
	end)
	
	BigBoomsHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			DontBypassIFrames = {},
			DontCheckBlock = true,
			Damage = 15,
			Ragdoll = 3,
			Velocity = {Vector3.yAxis * 65, 0.1}
		})
	end)
	
	BigBoomHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			DontBypassIFrames = {},
			DontCheckBlock = true,
			Damage = 25,
			Ragdoll = 4,
			Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 75 + Vector3.yAxis * 150, 0.1}
		})
		
		if Validated then
			VictimCombat:ImpactOnGroundHit()
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(15)
		
		self.Combat:TimesSpeed(100)
		
		self.Combat:StackState("HitboxImmunity", false)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
		if (Parameter == "1") then -- circle
			CircleHitbox:Detect()

		elseif (Parameter == "2") then -- lil booms
			

		elseif (Parameter == "2.5") then -- impacts before big booms
			

		elseif (Parameter == "2.8") then -- big booms
			BigBoomsHitbox:BeginCast(0.5)

		elseif (Parameter == "3") then -- big boom at end
			BigBoomHitbox:Detect()
		end
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Once(function()
		self:Close()
	end))
	
	self:FireReliableVFX("Chara/Special Hell", "Start", self.LuaCharacter.Model)
end

function Attack:CompleteStep()
	self.StepsCompleted += 1
	
	if (self.StepsCompleted == 1) then
		self.Combat:ChangeAttackDisplay(script.Name, script.Name, {
			Tip = "ONE STEP TAKEN", 
			FlashColor = Color3.fromRGB(255, 128, 128)
		})
	
	elseif (self.StepsCompleted == 2) then
		self:SetAvailability(true)

		--self.ResetTimer = task.delay(10, function()
		--	self:SetAvailability(false)
		--end)
	end
end

function Attack:SetAvailability(Value : boolean)
	self.Available = Value

	if Value then
		self.Combat:ChangeAttackDisplay(script.Name, script.Name, {
			Tip = "READY", 
			FlashColor = Color3.fromRGB(255, 0, 0)
		})
	else
		self.Combat:ChangeAttackDisplay(script.Name, script.Name, {
			Tip = "NOT READY", 
			FlashColor = Color3.fromRGB(255, 0, 0)
		})
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.StepsCompleted = 0
	self.TryToCancelMoves = true
	self.Hit = false
	self:_Init()
	
	task.defer(self.SetAvailability, self, false)

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack