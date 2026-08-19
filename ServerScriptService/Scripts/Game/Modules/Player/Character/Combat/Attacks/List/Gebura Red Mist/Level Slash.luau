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

	self.Thread.CancelJob:Task(self:CreateMoveSFX("Gebura Red Mist", "Level Slash"))
	
	local OnWhitelist = Whitelist.is_permitted(self.LuaPlayer.UserId, "Gebura")
	local Damage = if OnWhitelist then 15 else 7.5
	
	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(-5, 0, -10)
	Hitbox.Params.Size = Vector3.new(45, 45, 28)

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local FinsherHealth = self:IsFinisherEnabled() and VictimLuaCharacter.Humanoid.Health <= Damage
		
		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = (Whitelist.is_permitted(self.LuaPlayer.UserId, "Gebura")),
			Ragdoll = 2.25,
			Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 25 + (self.LuaCharacter.RootPart.CFrame.RightVector * -50) + Vector3.yAxis * 30, 0.1},
			Damage = Damage,
		})
		
		if Validated and FinsherHealth then
			self:FireReliableVFX("Gebura Red Mist/Level Slash", "Finisher", VictimLuaCharacter.Head)
		end
	end)

	-- Aura Hitbox
	local AuraHitbox = self:CreateHitbox(false);
	AuraHitbox.Params.Offset = CFrame.identity
	AuraHitbox.Params.Size = Vector3.one * 20

	AuraHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true,
			TrueStun = 0.5,
			Damage = 1,
			Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 20, 0.1}
		})
		
		if Validated then
			VictimCombat:PlayRandomHitReaction()
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(15)
		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("aura"):Connect(function(Parameter : string)
		self:FireReliableVFX("Gebura Red Mist/Level Slash", "Aura", self.LuaCharacter.RootPart, Parameter)
		
		if Parameter == "true" then
			AuraHitbox:BeginCast()
			
			self.Thread.OnClosed:Connect(function()
				self:FireReliableVFX("Gebura Red Mist/Level Slash", "Aura", self.LuaCharacter.RootPart, "false")
			end)
		else
			AuraHitbox:EndCast()
		end
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("slash"):Connect(function()
		self:FireReliableVFX("Gebura Red Mist/Level Slash", "Swing", self.LuaCharacter.RootPart)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Connect(function()
		self:FireReliableVFX("Gebura Red Mist/Level Slash", "Hit", self.LuaCharacter.RootPart)
		
		Hitbox:Detect()
		self.Combat.Hitbox:Destruction(Hitbox.Params.Offset, Hitbox.Params.Size, 8)
	end))

	task.wait(1)

	self:Close()
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