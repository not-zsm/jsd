local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Anubis_Utility = require("./Anubis Utility")

local Remotes = ReplicatedStorage.Remotes

local CombatRemotes = Remotes.Combat
local GrabRemotes = Remotes.Grab

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	local Pass = self:BasicConditions() and not self.Combat:GetState("Blocking")
	
	if self.Variant then
		return (Pass and self.VariantVictim ~= nil)
	end
	
	return Pass
end

function Attack:Elevation()
	self:DoVariant(false)
	local VictimLuaPlayer = self.VariantVictim
	local VictimLuaCharacter = VictimLuaPlayer.Character
	local VictimCombat = VictimLuaCharacter.Combat
	
	if VictimCombat:GetState("Evasived") then
		self:Close()
		return
	end
end

function Attack:Spiral()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(self.SpeedReduction)
	
	self.Animations.Spiral:Play(0)
	
	self.VariantVictim = nil
	local StopAnim = true
	
	self.Thread.OnClosed:Connect(function()
		if StopAnim then
			self.Animations.Spiral:Stop(0)
		end
		
		if not self.Variant then
			self:AddCooldown(self.Cooldown)
		end
		
		self.Combat:TimesSpeed(self.SpeedReduction)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(task.delay(self.TimeUntilMoveTimesOut, function()
		self:Close()
	end))
	
	self.Thread.Job:Task(self.Animations.Spiral:GetMarkerReachedSignal("End"):Once(function()
		StopAnim = false
		self:Close()
	end))
	
	local Hitbox = self:CreateHitbox(true)
	Hitbox.Params.Offset = CFrame.identity
	Hitbox.Params.Size = 10
	Hitbox.Params.Recursive = true
	
	local HitTable = {}
	
	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		if HitTable[VictimLuaPlayer] then
			return
		end
		
		HitTable[VictimLuaPlayer] = true
		
		task.delay(0.05, function()
			HitTable[VictimLuaPlayer] = nil
		end)
		
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			Damage = 1,
			Stun = 0.75,
			Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 10 + (self.LuaCharacter.RootPart.CFrame.LookVector * 15), 0.1},
			DontRestartRespawnTimer = true
		})

		if Validated then
			self:FireReliableVFX(self.InternalEffectPath, "Emit", VictimLuaCharacter.RootPart, "HitEffect")
			VictimCombat:PlayRandomHitReaction()
			
			--[[if not self.VariantVictim then
				self.VariantVictim = VictimLuaPlayer
				self:DoVariant(true, VictimLuaPlayer)
				
				self.Thread.OnCancelled:Connect(function()
					self:DoVariant(false)
				end)
			end]]
		end
	end)
	
	self.Thread.Job:Task(self.Animations.Spiral:GetMarkerReachedSignal("Hitbox"):Connect(function(State)
		if State == "Start" then
			Hitbox:BeginCast()
		elseif State == "End" then
			Hitbox:EndCast()
		end
	end))
	
	self.Thread.Job:Task(self.Animations.Spiral:GetMarkerReachedSignal("Boost"):Connect(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 60
		VelocityObject:Fire()
		
		self.Thread.Job:Task(VelocityObject)
		
		self.Thread.Job:Task(task.delay(0.65, function()
			VelocityObject:Destroy()
		end))
	end))
	
	self:FireReliableVFX(self.InternalEffectPath, "Start", self.LuaCharacter.Model)
end

function Attack:DoVariant(Value : boolean, VictimLuaPlayer)
	if self.Variant ~= Value then
		if self.Timer and coroutine.status(self.Timer) == "suspended" then
			task.cancel(self.Timer)
			self.Timer = nil
		end

		if Value then
			self.Combat:ChangeAttackDisplay(self.Name, "Adaptive Elevation", {
				Tip = "[PRESS AGAIN]",
				FlashColor = Color3.fromRGB(212, 83, 255)
			})

			self.Timer = task.delay(1, function()
				self.Timer = nil
				self:DoVariant(false)
			end)
		else
			self:AddCooldown(self.Cooldown)

			self.Combat:ChangeAttackDisplay(self.Name, self.DisplayName, {
				Tip = "",
				FlashColor = Color3.fromRGB(212, 83, 255)
			})
		end

		self.Variant = Value
	end
end

function Attack:Activate()
	if self.Variant then
		self:Elevation()
	else
		self:Spiral()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	
	self.Cooldown = 10
	
	self.TimeUntilMoveTimesOut = 2.25
	self.SpeedReduction = 4
	
	self.InternalEffectPath = `Anubis/{script.Name}`
	
	self.Variant = false
	self.VariantVictim = nil
	
	self.Timer = nil
	
	self.TimeUntilVariantTimesOut = 2
	
	self.InternalVariantEffectPath = "Anubis/Adaptive Elevation"
	
	self:_Init()
	
	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack