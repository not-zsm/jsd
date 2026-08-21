

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(1.3)
	
	self.Combat.Mouse:BeginRequesting(nil, "Default")
	
	self.Thread.OnClosed:Connect(function()
		self.Combat:TimesSpeed(1.3)
		self.Combat.Mouse:EndRequesting()
		
		self.Combat:StackState("Attacking", false)
	end)
	
	self:FireReliableVFX("Chara/Check", "Start", self.LuaCharacter.Model)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("point"):Connect(function()
		local TargetLuaPlayer 
		local TargetLuaCharacter
		local TargetCombat
		
		local Success = false

		if self.Combat.CurrentDevicePlayingOn == "Keyboard" then

			if (self.Combat.Mouse.Target ~= nil and self.Combat.Mouse.Target ~= self.LuaCharacter.Model) then
				TargetLuaPlayer = LuaPlayerList.Get(self.Combat.Mouse.Target)
				TargetLuaCharacter = TargetLuaPlayer.Character
				TargetCombat = TargetLuaCharacter.Combat
				
				Success = true
			end
			
		else
			local Hitbox = self:CreateHitbox(true);
			Hitbox.Params.Size = (self.Range - 2)
			Hitbox.Params.MaxTargets = 1

			Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				if self:Afflict(VictimLuaPlayer, {DontCheckBlock = true}) then
					TargetLuaPlayer = VictimLuaPlayer
					TargetLuaCharacter = TargetLuaPlayer.Character
					TargetCombat = TargetLuaCharacter.Combat
					
					Success = true
				end
			end)

			Hitbox:Detect()
		end

		if (TargetLuaPlayer == nil or self.Combat:CalculateMagnitude(TargetLuaPlayer) > self.Range or not self.Combat.Hitbox:ValidatePlayer(TargetLuaPlayer)) then
			Success = false
		end
		
		self.Animations.Windup:Stop()
		
		if Success then
			self.Animations.Success:Play(0.1, 1, 1.35)
			self:FireReliableVFX("Chara/Check", "Target", self.LuaCharacter.Model, TargetLuaCharacter.Model, self.Debuff_Time)
			
			self.Combat:Afflict(TargetLuaPlayer, {
				DontCheckBlock = true,
				Damage = 2.5,
				TrueStun = 1
			})
			
			TargetCombat.Animations.BlackFlashed:Play(0, 1, 1.4)

			TargetLuaPlayer.Character.Combat.DefenseMultiplier /= 1.3

			TargetLuaPlayer.Character.HumanoidJob:Task(task.delay(self.Debuff_Time, function()
				TargetLuaPlayer.Character.Combat.DefenseMultiplier *= 1.3
			end))
		else
			self.Animations.Fail:Play(0.1, 1, 0.75)
		end
		
		task.wait(1)
		
		self:Close()
	end))
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.Uncancellable = true
	self.Debuff_Time = 15
	self.Range = 75
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack