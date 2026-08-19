local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Whitelist = require( ReplicatedStorage.Modules.Shared.Game.Whitelist )

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

	self.Thread.CancelJob:Task(self:CreateMoveSFX("Gebura Red Mist", "Upstanding Slash"))

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 3, -10)
	Hitbox.Params.Size = Vector3.new(30, 12, 30)
	
	local OnWhitelist = Whitelist.is_permitted(self.LuaPlayer.UserId, "Gebura")
	local Damage = OnWhitelist and 40 or 25
	
	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local FinsherHealth = self:IsFinisherEnabled() and VictimLuaCharacter.Humanoid.Health <= Damage
		
		local Validated = self:Afflict(VictimLuaPlayer, {
			DontCheckBlock = true,
			DontBypassIFrames = {},
			Velocity = FinsherHealth and {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 30 + Vector3.yAxis * 110, 0.1} or nil,
			Damage = Damage
		})

		if Validated then
			self.Combat:VictimImpactGround(VictimLuaPlayer)

			if FinsherHealth then
				self:FireReliableVFX("Gebura Red Mist/Level Slash", "Finisher", VictimLuaCharacter.Head)
			else
				self.Combat:PushSkidVictim(VictimLuaPlayer, {
					TimeTilGroundDetection = 0.35,
					StartVelocityXZ = self.Combat:GetSimulatedRoot().CFrame.LookVector * 30,
					StartVelocityY = Vector3.yAxis * 115,
					StartDuration = 0.725,
					LandedRollVelocityZ = 130,
					LandedRollDuration = 0.7875
				})
			end
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:FireReliableVFX("Gebura Red Mist/Upstanding Slash", "Sparks", self.LuaCharacter.RootPart, "false")
		
		self:AddCooldown(13)
		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("sparks"):Connect(function(Parameter : string)
		self:FireReliableVFX("Gebura Red Mist/Upstanding Slash", "Sparks", self.LuaCharacter.RootPart, Parameter)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("slash"):Connect(function()
		self:FireReliableVFX("Gebura Red Mist/Upstanding Slash", "Slash", self.LuaCharacter.RootPart)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("ground"):Connect(function()
		self:FireReliableVFX("Gebura Red Mist/Upstanding Slash", "Ground", self.LuaCharacter.RootPart)
		
		Hitbox:Detect()
		self.Combat.Hitbox:Destruction(Hitbox.Params.Offset, Hitbox.Params.Size, 8)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Connect(function()
		self:Close()
	end))
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.Uncancellable = true
	self.TryToCancelMoves = true
	self.AnimationSettings = {Speed = 1.07}
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack