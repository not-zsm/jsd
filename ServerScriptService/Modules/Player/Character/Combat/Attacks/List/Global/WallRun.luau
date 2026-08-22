local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:Pretrigger(Extra : {})
	if (Extra ~= nil and typeof(Extra) == "table") then
		if (Extra.Slipped ~= nil) then
			self.Slipped = Extra.Slipped
		end
	end
end

function Attack:ConditionToActivate()
	return true
end


function Attack:ResetActiveTimer()
	if (self.ActiveThread ~= nil and coroutine.status(self.ActiveThread) == "suspended") then
		task.cancel(self.ActiveThread)
	end
	
	self.ActiveThread = nil
end

function Attack:Activate()
	self:ResetActiveTimer()
	self.Active = true

	self.Combat:StackState("Attacking", true)
	
	self.Thread.OnClosed:Connect(function()
		self.ActiveThread = task.delay(0.3, function()
			self.ActiveThread = nil
			self.Active = false
		end)
		
		self.Combat:StackState("Attacking", false)
	end)
end

function Attack:Deactivate()
	if self.Slipped then
		self.Slipped = false
		
		self:FireReliableVFX("Global/Impact", "GoofySlip", self.LuaCharacter.RootPart)
		self.Combat.Ragdoll:Toggle(true, 2)
	end
	
	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.DontBuffer = true

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack