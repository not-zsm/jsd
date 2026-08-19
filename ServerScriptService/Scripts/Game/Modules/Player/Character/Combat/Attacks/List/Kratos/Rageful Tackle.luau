local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Remotes = ReplicatedStorage.Remotes
local HotbarRemotes = Remotes.Combat.UI.Hotbar

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:StackState("HitboxImmunity", true)

	self.Combat:DivideSpeed(100)

	self.Hit = false

	local Weapons = self.Combat.Attacks.Weapons

	if Weapons then
		Weapons:SetCurrent("Fists")
	end

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(16)

		self.Combat:TimesSpeed(100)
		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("HitboxImmunity", false)
	end)

	self:FireReliableVFX("Kratos/Rageful Tackle", "Start", self.LuaCharacter.Model)
	
	self.Thread.CancelJob:Task(self:CreateMoveSFX("Kratos", "Rageful Tackle", "Windup"))

	local RoarHitbox = self:CreateHitbox()
	RoarHitbox.Params.Size = Vector3.new(27.706, 20, 28.463)
	RoarHitbox.Params.Offset = CFrame.identity

	RoarHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
		self:Afflict(NewVictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			Damage = 3,
			TrueStun = 1,
			Velocity = {self.Combat:GetSimulatedRoot().CFrame.LookVector * 5 + Vector3.yAxis * 10, 0.1},
			BreakBlock = true,
			PlayRandomHitReaction = true,
		})

		task.delay(0.1, RoarHitbox.RemoveHumanoid, RoarHitbox, NewVictimLuaPlayer.Character.Humanoid)
	end)
	
	local RunHitbox = self:CreateHitbox()
	RunHitbox.Params.Offset = CFrame.new(0, 0, -6)
	RunHitbox.Params.Size = Vector3.new(15, 10, 15)

	RunHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
		self:Afflict(NewVictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			BreakBlock = true,
			Velocity = {self.Combat:GetSimulatedRoot().CFrame.LookVector * 5, 0.1},
			Damage = 1,
			TrueStun = 0.75,
			PlayRandomHitReaction = true,
		})

		task.delay(0.2, RunHitbox.RemoveHumanoid, RunHitbox, NewVictimLuaPlayer.Character.Humanoid)
	end)

	self.Thread.OnClosed:Connect(function()
		RoarHitbox:EndCast()
		RoarHitbox:Destroy()
		
		RunHitbox:EndCast()
		RunHitbox:Destroy()
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("roar"):Once(function()
		RoarHitbox:BeginCast()
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("endroar"):Once(function()
		RoarHitbox:EndCast()
		RoarHitbox:Destroy()
		
		if self.LuaPlayer.IsNPC then
			local VelocityObject = self.Combat:Velocity()
			VelocityObject.Settings.Duration = 2
			VelocityObject.Settings.RemoveTime = 1.8
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 90000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 20
			VelocityObject:Fire();
		end;
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("run"):Once(function()
		RunHitbox:BeginCast();
		
		if self.LuaPlayer.IsNPC then
			local VelocityObject = self.Combat:Velocity()
			VelocityObject.Settings.Duration = 3.5
			VelocityObject.Settings.RemoveTime = 3.75
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 100000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 37.5
			VelocityObject:Fire();
		end;
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("tackle"):Once(function()
		RunHitbox:EndCast()
		RunHitbox:Destroy()
		
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 1.25
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 50 -- 30
		VelocityObject:Fire()

		self.Thread.Job:Task(VelocityObject)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Once(function()
		local Hitbox = self:CreateHitbox(false);
		Hitbox.Params.DestroyOnEndCast = false
		Hitbox.Params.Offset = CFrame.new(0, 0, -5)
		Hitbox.Params.Size = Vector3.new(8.5, 10.5, 11) --Vector3.new(6, 10.5, 8)
		Hitbox.Params.MaxTargets = 1

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Validated = self:Afflict(VictimLuaPlayer, {
				BreakBlock = true,
			})

			if Validated then
				self.Hit = true

				local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0))
				local VictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Kratos["Rageful Tackle"].Victim)

				self.Animations.Windup:Stop()
				self.Animations.Hit:Play()

				if VictimAnimation then
					VictimAnimation:Play()
				end
				
				self.Thread.CancelJob:Task(self:CreateMoveSFX("Kratos", "Rageful Tackle", "Hit"))

				local StrongerRunHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -7), Vector3.new(10, 8, 13))
				local SlamHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -5), Vector3.new(20, 20, 20))

				SlamHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
					self:Afflict(NewVictimLuaPlayer, {
						TriggerActiveCounterOverOrEqualLevel = -1,
						DontCheckBlock = true,
						Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 40 + Vector3.yAxis * 35, 0.1},
						Damage = 10,
						Ragdoll = 2,
					})
				end)
				
				StrongerRunHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
					self:Afflict(NewVictimLuaPlayer, {
						TriggerActiveCounterOverOrEqualLevel = -1,
						DontCheckBlock = true,
						Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 75 + Vector3.yAxis * 5, 0.1},
						Damage = 1,
						Ragdoll = 2,
					})

					task.delay(0.2, function()
						StrongerRunHitbox:RemoveHumanoid(NewVictimLuaPlayer.Character.Humanoid)
					end)
				end)

				StrongerRunHitbox:BeginCast()

				self.Thread.OnClosed:Connect(function()
					GrabObject.Destroy(0)	
					VictimCombat:Unstun()	

					SlamHitbox:Destroy()
					StrongerRunHitbox:EndCast()
					StrongerRunHitbox:Destroy()
					
					if VictimAnimation then
						VictimAnimation:Stop()
					end
				end)

				local RunVelocityObject = self.Combat:Velocity()
				RunVelocityObject.Settings.Duration = 4
				RunVelocityObject.Settings.RemoveTime = RunVelocityObject.Settings.Duration
				RunVelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				RunVelocityObject.Settings.Controllable = true
				RunVelocityObject.Settings.Z = 30
				RunVelocityObject:Fire()
				
				self.Thread.Job:Task(RunVelocityObject)

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("stoprun"):Once(function()
					StrongerRunHitbox:EndCast()
					StrongerRunHitbox:Destroy()
					
					local VelocityObject = self.Combat:Velocity()
					VelocityObject.Settings.RemoveTime = 0.65
					VelocityObject.Settings.MaxForce = Vector3.one * 80000
					VelocityObject.Settings.Controllable = true
					VelocityObject.Settings.Y = 28
					VelocityObject.Settings.Z = 85
					VelocityObject:Fire()
					
					self.Thread.Job:Task(VelocityObject)
				end))

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("slam"):Once(function()
					SlamHitbox:Detect()
					GrabObject.Destroy()
					
					self:Afflict(VictimLuaPlayer, {
						TriggerActiveCounterOverOrEqualLevel = -1,
						DontCheckBlock = true,
						ExcludeAttempts = true,
						Ragdoll = 2.5,
						Damage = 20,
						Velocity = {Vector3.yAxis * -75, 0.1}
					})

					task.wait(0.75)

					self:Close()
				end))

				self:FireReliableVFX("Kratos/Rageful Tackle", "Hit", self.LuaCharacter.Model)
			end
		end)

		Hitbox:BeginCast(0.1)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Once(function()
		if not self.Hit then
			self:Close()
		end
	end))
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack