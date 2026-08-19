local ServerScriptService = game:GetService("ServerScriptService")

----------------------------------------------------------------------------------

local Attack = {}
Attack.__index = Attack

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate() : boolean
	return self:BasicConditions() and not self.Combat:GetState("Blocking") and not self.DimpleWorking
end

function Attack:Activate()
	self.DimpleWorking = true
	self.Animations.UserStart:Play()

	self:FireReliableVFX("Reigen/Spirit Link", "Start", self.LuaCharacter.Model, self.PassiveDuration)
	
	self.Thread.CancelJob:Task(
		self:CreateMoveSFX("Reigen", "Spirit Link")
	)
	
	self.Thread.OnClosed:Connect(function()
		self.DimpleWorking = false
	end)

	self.Thread.Job:Task(self.Animations.UserStart:GetMarkerReachedSignal("possess"):Connect(function()
		self.Combat.DamageMultiplier = 1.35
		self.LuaCharacter:Heal(25)

		task.delay(self.PassiveDuration, function()
			self.Combat.DamageMultiplier = 1
			self:Close()
		end);
	end));
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.TryToCancelMoves = false
	self.DontBuffer = true
	self.Uncancellable = true
	self.DimpleWorking = false
	
	self.PassiveDuration = 10

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack