local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Animations = ReplicatedStorage.Animations.Items["Death Note"].Use

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	local Item = self.LuaCharacter.Items:GetEquippedTool()
	if not Item then self:Close() return end
	
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)
	
	local LoopAnimation = self.LuaCharacter:LoadAnimation(Animations.Loop)
	local WriteAnimation = self.LuaCharacter:LoadAnimation(Animations.Write)
	
	LoopAnimation:Play()
	
	self.Thread.OnClosed:Connect(function()
		self.Combat:TimesSpeed(50)
		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("HitboxImmunity", false)
		LoopAnimation:Stop()
	end)
	
	self:FireReliableVFXToSelf("Items/Death Note", "Use/Open", self.LuaCharacter.Model)
	self.Thread.Job:Task(self.LuaCharacter.Items.OnEquipChanged:Connect(function(PreviousItem, NewItem)
		self:FireReliableVFXToSelf("Items/Death Note", "Use/Close", self.LuaCharacter.Model)
		self:Close()
	end))
	
	self.Thread.Job:Task(ReplicatedStorage.PlayerRemotes.Items["Death Note"].SelectTarget.OnServerEvent:Connect(function(Player : Player, Target : Player, Cause : String)
		if Player == self.LuaPlayer.Player then
			print(`{Player.Name} has selected {Target.Name} to die by: {Cause}`)
			
			self.Combat:StackState("HitboxImmunity", true)
			self.LuaCharacter.Items:LockItems(true)
			LoopAnimation:Stop()
			WriteAnimation:Play()
			self.Thread.Job:Task(WriteAnimation.Stopped:Connect(function()
				self.LuaCharacter.Items:LockItems(false, true)
				self:Close()
			end))
		end
	end))
end

function Attack.new(...) 
	local self = setmetatable(BaseAttack.new(...), Attack)
	
	self:_Init()
	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack
