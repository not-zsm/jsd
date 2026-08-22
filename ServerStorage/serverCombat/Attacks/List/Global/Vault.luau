local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return true
end

function Attack:ResetActiveTimer()
	if (self.ActiveThread ~= nil and coroutine.status(self.ActiveThread) == "suspended") then
		task.cancel(self.ActiveThread)
	end

	self.ActiveThread = nil
end

function Attack:Activate(State : boolean)
	self.Active = true
	self.Combat:StackState("CannotBlock", true)
	
	self.Thread.OnClosed:Connect(function()
		self.ActiveThread = task.delay(0.2, function()
			self.ActiveThread = nil
			self.Active = false
		end)
		
		self.Combat:StackState("CannotBlock", false)
	end)

	task.wait(0.2)
	
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