local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	local Item = self.LuaCharacter.Items.PeacemakerHelmet
	if not Item then
		self:Close()
		return
	end
	
	self.LuaCharacter.Model:SetAttribute("FreezeHotbar", true)
	
	self.Combat:StackState("Attacking", true)
	self.Combat:StackState("HitboxImmunity", true)
	--self.Combat:DivideSpeed(1.5)

	self.Thread.OnClosed:Connect(function()
		--self.Combat:TimesSpeed(1.5)
		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("HitboxImmunity", false)
		
		self.LuaCharacter.Model:SetAttribute("FreezeHotbar", false)
		
		if Item.UsesLeft < 1 then
			self.LuaCharacter.Items:Remove(Item)
		end
	end)
	
	-- Hitbox
	local Hitbox = self:CreateHitbox(true);
	Hitbox.Params.Size = 65

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat
		
		local Finisher = self:IsFinisherEnabled() and VictimLuaCharacter.Humanoid.Health <= self.Config.Damage + 3
		
		if Finisher then
			local Validated = self:Afflict(VictimLuaPlayer, {
				ExcludeAttempts = true,
				FinisherKill = true,
				Ragdoll = 2.5,
				Velocity = {(VictimLuaCharacter.RootPart.Position - Hitbox.Adornee.Position).Unit * 100 + Vector3.yAxis * 30, 0.1},
			})
			
			if Validated then
				self:FireReliableVFX("Items/Helmet of Peace", "Finisher", VictimLuaCharacter.Model)
			end
		else
			local Validated = self:Afflict(VictimLuaPlayer, {
				Damage = self.Config.Damage,
				BreakBlock = true,
				Ragdoll = 2.5,
				Velocity = {(VictimLuaCharacter.RootPart.Position - Hitbox.Adornee.Position).Unit * 100 + Vector3.yAxis * 30, 0.1},
				TriggerActiveCounterOverOrEqualLevel = -1,
			})
		end
	end)
	
	self:FireReliableVFX("Items/Helmet of Peace", "Start", self.LuaCharacter.Model)
	task.wait(self.Config.DetonationTime)
	Hitbox:Detect()
	self:FireReliableVFX("Items/Helmet of Peace", "Explode", self.LuaCharacter.Model)
	task.wait(0.5)
	self:Close()
end

function Attack.new(...) 
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	
	self.Config = {
		DetonationTime = 2,
		Damage = 30,
	}
	
	self:_Init()
	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack
