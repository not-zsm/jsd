local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )
local Quicktime =  require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Quicktime )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking") and not self:HasCertainCooldown("AntiStuck")
end

function Attack:Pretrigger()
	if self.Posing then
		self.PoseCancel:Fire()
	end
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(100)

	self.Thread.OnClosed:Connect(function()
		self.Animations.Loop:Stop()
		
		self:AddCertainCooldown("AntiStuck", 0.2)
		self:AddCooldown(30)
		
		self.Posing = false
		
		self.Combat:TimesSpeed(100)
		self.Combat:StackState("Attacking", false)
	end)

	self.Animations.Loop:Play(0.25)
	self:FireReliableVFX("Anubis/Pose", "Start", self.LuaCharacter.Model) --, self.TimeUntilHealing)
	self.Posing = true
	
	local QTETime = 0.45
	local QTEPrecision = 0.1
	local QTEAmount = 3

	local QTESeed = Random.new()
	local QTEKeys = {Enum.KeyCode.E, Enum.KeyCode.Q}
	local ControllerQTEKeys = {Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonX}
	
	local HealThread = coroutine.create(function()
		for i = 1, 20 do
			if self.LuaPlayer:PlayerExists() and not self.LuaPlayer.IsNPC then
				local Key = QTEKeys[QTESeed:NextInteger(1, #QTEKeys)]
				local ControllerKey = ControllerQTEKeys[QTESeed:NextInteger(1, #ControllerQTEKeys)]

				local AttackerQTE = Quicktime.new(self.LuaPlayer.Player, Key, ControllerKey, NumberRange.new(QTETime, QTETime + QTEPrecision))

				AttackerQTE.OnUpdate:Connect(function(Value : boolean)
					if Value then
						local HealAmount = if self.Combat.InCombat then self.Heals.InCombat else self.Heals.OutOfCombat
						self.LuaCharacter:Heal(HealAmount)
					end
				end)
			end
			
			task.wait(1)
		end
	end)

	self.Thread.Job:Task(HealThread)
	coroutine.resume(HealThread)
	
	self.PoseCancel:Wait()

	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	
	self.TryToCancelMoves = true
	self.PoseCancel = self.Job:Task(EventService.new())
	self.Posing = false
	
	self.Heals = {
		InCombat = 4,
		OutOfCombat = 8,
	}
	
	--self.TimeUntilHealing = 7
	
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack