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
	self.Combat:DivideSpeed(4)

	self.Thread.CancelJob:Task(self:CreateMoveSFX("Gebura Red Mist", "Spear", "Windup"))
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(8)
		self.Combat:TimesSpeed(4)
		self.Combat:StackState("Attacking", false)
	end)
	
	local HasGeburaWhitelist = Whitelist.is_permitted(self.LuaPlayer.UserId, "Gebura")
	local Count = 0
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("stab"):Connect(function()
		Count += 1
		
		self.Thread.CancelJob:Task(self:CreateMoveSFX("Gebura Red Mist", "Spear", `stabby{Count}`))
		self:FireReliableVFX("Gebura Red Mist/Spear", "Stab", self.LuaCharacter.RootPart)
		
		local Hitbox = self:CreateHitbox(false);
		Hitbox.Params.Offset = CFrame.new(0, 0, -7.25)
		Hitbox.Params.Size = Vector3.new(3.5, 5.25, 11)

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Validated = self:Afflict(VictimLuaPlayer, {
				TrueStun = 1,
				BreakBlock = (HasGeburaWhitelist),
				Damage = 3,
				Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 5, 0.05},
			})

			if Validated then
				VictimCombat:PlayRandomHitReaction()
				self:FireReliableVFX("Gebura Red Mist/Spear", "StabHit", VictimLuaCharacter.RootPart)
			end
		end)
		
		Hitbox:Detect()
		
		self.Combat.Hitbox:Destruction(Hitbox.Params.Offset, Hitbox.Params.Size, 4)
		self.Animations.Windup:AdjustSpeed(1)
	end))

	task.wait(1.25)

	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.AnimationSettings = {Speed = 1.4}

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack




























