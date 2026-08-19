local ServerScriptService = game:GetService("ServerScriptService")

----------------------------------------------------------------------------------

local Attack = {}
Attack.__index = Attack

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:Activate()
	self.LuaPlayer.Replication.Attributes:SetAttribute("VectorReflecting", true)
	self:FireReliableVFX("Accelerator/Vector Reflection", "Start", self.LuaCharacter.Model)
	
	self.Thread.CancelJob:Task(self:CreateMoveSFX("Accelerator", "Vector Reflection"))

	self.Combat:CreateCounter(1, function(VictimLuaPlayer)
		self:ClearUnreflectThread()

		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			DontCheckBlock = true,
		})
		
		if Validated and self.Combat:CalculateMagnitude(VictimLuaPlayer) <= 10 then
			self.Combat:DealDamage(VictimLuaPlayer, 5)
			
			local VelocityObject = self:VelocityOn(VictimCombat)
			VelocityObject.Settings.RemoveTime = 0.1
			VelocityObject.Settings.Velocity = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 30
			VelocityObject:Fire()
			
			self:Afflict(VictimLuaPlayer, {
				ExcludeAttempts = true;
				Ragdoll = 1.25;
			})
			--VictimCombat.Ragdoll:Toggle(true, 1.25)
		end
		
		self.LuaPlayer.Replication.Attributes:SetAttribute("VectorReflecting", nil)
		self:FireReliableVFX("Accelerator/Vector Reflection", "Reflect", self.LuaCharacter.Model)
		
		self:Close()
	end)
	
	self.Active = true
	self:ClearUnreflectThread()
	
	self.UnreflectThread = task.delay(25, function()
		self.UnreflectThread = nil
		
		self.LuaPlayer.Replication.Attributes:SetAttribute("VectorReflecting", nil)
		self.Combat:RemoveActiveCounter()
		
		self.Active = false
		self:Close()
	end)
end

function Attack:ClearUnreflectThread()
	if self.UnreflectThread then
		if coroutine.status(self.UnreflectThread) == "suspended" then
			task.cancel(self.UnreflectThread)
		end
		
		self.UnreflectThread = nil
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.Uncancellable = true
	
	self.Job:Task(function()
		if self.Active then
			self.LuaPlayer.Replication.Attributes:SetAttribute("VectorReflecting", nil)
			self.Combat:RemoveActiveCounter()
		end
		
		self:ClearUnreflectThread()
	end)
	
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack