local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )

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
	self.Combat:StackState("GrabIFrames", true)
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(100)

	self.Thread.OnClosed:Connect(function()
		self.Animations.Start:Stop()
		self.Animations.Loop:Stop()
		
		self:AddCertainCooldown("AntiStuck", 0.2)
		self:AddCooldown(0.5)
		
		self.Posing = false
		
		self.Combat:TimesSpeed(100)
	
		self.Combat:StackState("GrabIFrames", false)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(self.Animations.Start:GetMarkerReachedSignal("pause"):Once(function()
		self.Animations.Start:Stop(0)
		self.Animations.Loop:Play(0)
		
		self.LuaPlayer.Replication.Attributes:SetAttribute("RedMistPoseAura", true)
		self:FireReliableVFX("Gebura Red Mist/Pose", "Pose", self.LuaCharacter.Torso)
		
		self.Thread.OnClosed:Connect(function()
			self.LuaPlayer.Replication.Attributes:SetAttribute("RedMistPoseAura", nil)
		end)
		
		self.Posing = true
	end))

	self.Animations.Start:Play(0.25)

	self.PoseCancel:Wait()

	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	
	self.TryToCancelMoves = true
	self.PoseCancel = self.Job:Task(EventService.new())
	self.Posing = false
	
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack