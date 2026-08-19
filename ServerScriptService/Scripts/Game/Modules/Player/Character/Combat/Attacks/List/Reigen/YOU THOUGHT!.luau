local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	local BasicConditions = not self.Combat:GetState(`Cannot{self.NameNoSpaces}`) and
		not self.Combat:GetState("Stunned") 
		and not self.Combat:GetState("Ragdolled") 
		and not self.Combat:GetState("Ulting")
		and not self.Combat:GetState("GotDashBlocked")
		and not self.Combat:GetState("Grabbing")
		and not self.OnCooldown
	
	local CanFeintIn = (self.Combat:GetState("M1ing") or self.Combat:GetState("Attacking") or self.Combat:GetState("Dashing") or self.Combat:GetState("Backdashing"))
	local M1, M1Matched = self.Combat:MatchAttack("M1", Enum.UserInputType.MouseButton1)
	
	if (M1Matched and M1:ThreadAvailable() and M1.Count > 3) then
		return (BasicConditions and CanFeintIn and M1.InWindup and M1.Condition ~= nil)
	end
	
	return BasicConditions and CanFeintIn
end

function Attack:Activate()
	self.Animations[tostring(math.random(1, 2))]:Play(0)
	
	self.Combat:StackState("BackdashIFrames", true, 0.1)
	self:FireReliableVFX("Reigen/YOU THOUGHT!", "Feint", self.LuaCharacter.Model, self.Duration, self.IFrameDuration)

	self.Combat:StackState("CannotM1", true)
	self.Combat:StackState("CannotDash", true)
	self.Combat:StackState("CannotBlock", true)
	
	local Dash, DashMatched = self.Combat:MatchAttack("Dash", Enum.KeyCode.Q)

	if DashMatched and Dash:ThreadAvailable() then
		Dash:Cancel()
	end

	self.Combat:DivideSpeed(4)
	self:AddCooldown(13)

	self.Thread.OnClosed:Connect(function()
		self.Combat:TimesSpeed(4)
		
		self.Combat:StackState("CannotM1", false)
		self.Combat:StackState("CannotDash", false)
		self.Combat:StackState("CannotBlock", false)
	end)

	task.wait(self.Duration)

	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.DontBuffer = true
	self.TryToCancelMoves = true
	--self.AnimationSettings = {FadeTime = 0}
	self.Duration = 0.275
	self.IFrameDuration = 0.15

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack