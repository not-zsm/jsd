local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
	self.Combat:DivideSpeed(10)

	self.Hit = false

	self.Thread.OnClosed:Once(function()
		self:AddCooldown(25)
		
		self.LuaCharacter.Model:SetAttribute("InfinityPush", nil)
		
		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.LuaCharacter.Model:SetAttribute("InfinityPush", true)
	self:FireReliableVFXToSelf("Gojo/Infinity Push", "Velocity", self.LuaCharacter.RootPart)
	
	task.wait(0.075)

	self:FireReliableVFX("Gojo/Infinity Push", "Start", self.LuaCharacter.RootPart)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("runend"):Once(function()
		self.Animations.Windup:AdjustSpeed(0.5)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("push"):Once(function()
		self.Animations.Windup:AdjustSpeed(1)
		
		self:FireReliableVFX("Gojo/Infinity Push", "Swing", self.LuaCharacter.RootPart)
		
		local Hitbox = self:CreateHitbox(false);
		Hitbox.Params.Offset = CFrame.new(0, 1.5, 0)
		Hitbox.Params.Size = Vector3.new(8, 9, 8)

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Validated = self:Afflict(VictimLuaPlayer, {
				BreakBlock = true,
				Damage = 10
			})

			if Validated then
				self.Hit = true

				self:FireVFX("Global/Dashing/Forward Dash", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)

				self.Combat:PushSkidVictim(VictimLuaPlayer, {
					ScaleLandedRollVelocityWithAirTime = true,
					StartVelocity = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 25 - Vector3.yAxis * 75,
					LandedRollVelocityZ = 150,
					LandedRollDuration = 1
				})

				self:Close()
			end
		end)
		
		Hitbox:BeginCast(0.15)
		
		Hitbox.Events.OnCastEnded:Once(function()
			if not self.Hit then
				self.Animations.Windup:AdjustSpeed(0.25)
			end
		end)
	end))

	task.wait(2)

	if not self.Hit then
		self:Close()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	
	self.AnimationSettings = {
		FadeTime = 0.25,
		Weight = 1,
		Speed = 1
	}
	
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack