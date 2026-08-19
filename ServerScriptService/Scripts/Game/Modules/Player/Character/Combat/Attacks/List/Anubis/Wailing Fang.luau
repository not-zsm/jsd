local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Anubis_Utility = require("./Anubis Utility")

local EventService = require(ReplicatedStorage.Modules.Shared.Utilities.EventService)

local Remotes = ReplicatedStorage.Remotes

local CombatRemotes = Remotes.Combat
local GrabRemotes = Remotes.Grab

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Kick()
	self:DoVariant(false)
	self.KickHit = false
	
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(self.SpeedReduction)
	
	self.Animations.Kick:Play(nil, nil, 1.15)
	
	local SFX = self:CreateMoveSFX("Anubis", script.Name, "Shatter")

	self.Thread.OnCancelled:Connect(function()
		SFX:Destroy()
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(self.Cooldown)
		
		self.Combat:TimesSpeed(self.SpeedReduction)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(task.delay(self.TimeUntilVariantTimesOut, function() 
		self.Animations.Kick:Stop(0)
		self:Close()
	end))

	self.Thread.Job:Task(self.Animations.Kick:GetMarkerReachedSignal("End"):Once(function()
		self:Close()
	end))
	
	self.Thread.Job:Task(self.Animations.Kick:GetMarkerReachedSignal("Hitbox"):Once(function()
		local Root : BasePart = self.Combat:GetSimulatedRoot()
		
		local Hitbox = self:CreateHitbox()
		Hitbox.Params.Offset = CFrame.new(0, 0, -3)
		Hitbox.Params.Size = vector.create(9, 7, 8)
		
		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat
		
			local Dead = VictimLuaCharacter.Humanoid.Health <= 5
			
			self.KickHit = self:Afflict(VictimLuaPlayer, {
				Ragdoll = Dead and 2 or nil,
				Velocity = Dead and {Root.CFrame.LookVector * 45 + Vector3.yAxis * 85, 0.1} or nil,
				Damage = 5
			})
			
			if self.KickHit then
				self:FireReliableVFX(self.InternalVariantEffectPath, "Emit", VictimLuaCharacter.RootPart, "Hit")
				
				if not Dead then
					self.Combat:PushSkidVictim(VictimLuaPlayer, {
						TimeTilGroundDetection = 0.35,
						StartVelocityXZ = (self.LuaCharacter.RootPart.CFrame.LookVector * 25) + vector.create(0, 15, 0),
						StartVelocityY = Vector3.yAxis * 120,
						StartDuration = 0.55,
						LandedRollVelocityZ = 130,
						LandedRollDuration = 0.7775
					})
				end
				
				--local DashAttack, Matched = self.Combat:MatchAttack("Dash", Enum.KeyCode.Q)
				
				--if Matched and DashAttack.FrontDashHit and DashAttack:HasCertainCooldown("Front&Back Dash") and (os.clock() - DashAttack.LastTimeFrontDashHit < 6) then
				--	print("use variant")
				--else
				--	print("grab em")
				--end
			end
		end)
		
		Hitbox:Detect()
		
		task.defer(function()
			if not self.KickHit then
				self.Animations.Kick:AdjustSpeed(0.6)
			end
		end)
	end))
	
	self:FireReliableVFX(self.InternalVariantEffectPath, "Start", self.LuaCharacter.Model)
end

function Attack:Ground()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(self.SpeedReduction)
	
	self.Animations.Ground:Play(0)
	self.Thread.CancelJob:Task(self:CreateMoveSFX("Anubis", script.Name, "Wail"))

	local Hit = false
	local StopAnim = true
	
	self.Thread.OnClosed:Connect(function()
		if StopAnim then
			self.Animations.Ground:Stop(0)
		end
		
		self:AddCooldown(if Hit then self.DebounceCooldown else self.Cooldown)
		
		self.Combat:TimesSpeed(self.SpeedReduction)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(task.delay(self.TimeUntilMoveTimesOut, function()
		self:Close()
	end))
	
	self.Thread.Job:Task(self.Animations.Ground:GetMarkerReachedSignal("End"):Once(function()
		StopAnim = false
		self:Close()
	end))
	
	self.Thread.Job:Task(self.Animations.Ground:GetMarkerReachedSignal("Hitbox"):Connect(function()
		local Root : BasePart = self.Combat:GetSimulatedRoot()

		local Hitbox = self:CreateHitbox()
		Hitbox.Params.Offset = CFrame.new(0, 0, -3.5)
		Hitbox.Params.Size = vector.create(10, 7, 10)
		
		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat
			
			local Dead = VictimLuaCharacter.Humanoid.Health <= 10
			
			local Validated = self:Afflict(VictimLuaPlayer, {
				Damage = 8.5,
				Ragdoll = Dead and 2 or nil,
				Velocity = Dead and {Root.CFrame.LookVector * 50, 0.1} or nil,
				DontRestartRespawnTimer = true
			})
			
			if Validated then
				Hit = true
				
				if not Dead then
					local PingScaledStun = math.clamp(self.LuaPlayer:GetPing() * 1.5, 0, 0.5)
					print("wailing fang ping scaled push stun:", PingScaledStun)
					
					self.Combat:TSBPushVictim(VictimLuaPlayer, {
						LandedRollVelocityZ = 125,
						LandedRollDuration = 0.9,
						DurationMultiplier = 1 + PingScaledStun
					})
				end
				
				self:FireReliableVFX(self.InternalEffectPath, "Emit", VictimLuaCharacter.RootPart, "Hit")
			end
		end)
		
		Hitbox:Detect()
		
		self.Thread.Job:Task(task.delay(0.05, function()
			self.Animations.Ground:AdjustSpeed(Hit and 1.15 or 0.6)
		end))
		
		self:DoVariant(true)

		self.Thread.OnCancelled:Connect(function()
			self:DoVariant(false)
		end)
	end))
	
	self:FireReliableVFX(self.InternalEffectPath, "Start", self.LuaCharacter.Model)
	
	local VelocityObject = self.Combat:Velocity()
	VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
	VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
	VelocityObject.Settings.Controllable = true
	VelocityObject.Settings.Z = 40
	VelocityObject:Fire()
	
	self.Thread.Job:Task(VelocityObject)
	
	self.Thread.Job:Task(task.delay(0.65, function()
		VelocityObject:Destroy()
	end))
end

function Attack:DoVariant(Value : boolean)
	if self.Variant ~= Value then
		if self.Timer and coroutine.status(self.Timer) == "suspended" then
			task.cancel(self.Timer)
			self.Timer = nil
		end

		if Value then
			self.Combat:ChangeAttackDisplay(self.Name, "Shatter Fang", {
				Tip = "[PRESS AGAIN]",
				FlashColor = Color3.fromRGB(212, 83, 255)
			})

			self.Timer = task.delay(self.VariantWindow, function()
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
	if (self.VariantsEnabled and self.Variant) or self.ForceVariant then
		self:Kick()
	else
		self:Ground()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	
	self.Cooldown = 25 --16
	self.DebounceCooldown = 0.75
	
	self.TimeUntilMoveTimesOut = 2
	self.TimeUntilVariantTimesOut = 2

	self.SpeedReduction = 4
	
	self.InternalEffectPath = `Anubis/{script.Name}`
	
	self.Variant = false
	
	self.Timer = nil

	self.InternalVariantEffectPath = "Anubis/Shatter Fang"
	
	self.VariantWindow = 5 + self.DebounceCooldown
	
	self:_Init()
	
	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack