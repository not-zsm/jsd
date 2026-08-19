local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	if (self.VariantsEnabled and (self.HoldingJump or self.FreeFalling)) or self.ForceVariant then
		return self:AirVariant()
	end

	self.Animations.Punch:Play(0.05, 1, 0.85)

	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(7)

	self.SaltHit = false
	self.SaltFinisherHit = false

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 1, -2.75)--CFrame.new(0, 1, -8.5)
	Hitbox.Params.Size = Vector3.new(7, 9, 6.75)--Vector3.new(7.25, 9, 10)
	Hitbox.Params.DestroyOnEndCast = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Finisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= 15 and not self.SaltFinisherHit)

		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true,
			Damage = if Finisher then 0 else 15,
			YDifferenceValue = -2
		})

		if Validated then
			self.SaltHit = true

			if Finisher then
				self.SaltFinisherHit = true
				
				self.Combat:StackState("HitboxImmunity", true)
				VictimCombat:StackState("HitboxImmunity", true)
				
				self.Combat:DivideSpeed(100)
				self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

				VictimLuaCharacter:StopRespawnTimer()

				self.Thread.CancelJob:Task(self:CreateMoveSFX("Reigen", "Salt Punch Finisher"))

				local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.identity)

				self.Animations.Punch:Stop()
				self.Animations.Finisher:Play(0.1, 1, 0)
				VictimCombat.Animations.GrabVictims.SaltPunchFinisher:Play(0.1, 1, 0)

				self.Combat:HideUI(true)
				VictimCombat:HideUI(true)

				self.LuaPlayer.Replication.Attributes:SetAttribute("SaltPunchFinisherCamera", true)
				VictimLuaPlayer.Replication.Attributes:SetAttribute("SaltPunchFinisherCamera", true)

				self:FireReliableVFXToSelf("Reigen/Salt Punch Finisher", "Hit", self.LuaCharacter.RootPart)
				VictimLuaPlayer.Replication:FireReliableVFXToSelf("Reigen/Salt Punch Finisher", "Hit", self.LuaCharacter.RootPart)

				self.Thread.Job:Task(task.delay(5, function()
					self:Close()
				end))

				self.Thread.OnClosed:Connect(function()
					self.Combat:StackState("HitboxImmunity", false)
					VictimCombat:StackState("HitboxImmunity", false)

					GrabObject.Destroy(1)

					VictimLuaCharacter.RootPart.CFrame = self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -5)

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						FinisherKill = true,
						Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 150 + Vector3.yAxis * 50, 0.125}
					})

					VictimCombat:Unstun()

					self.Combat:TimesSpeed(100)
			
					self.Animations.Finisher:Stop()
					VictimCombat.Animations.GrabVictims.SaltPunchFinisher:Stop()

					self.Combat:HideUI(false)
					VictimCombat:HideUI(false)

					self.LuaPlayer.Replication.Attributes:SetAttribute("SaltPunchFinisherCamera", nil)
					VictimLuaPlayer.Replication.Attributes:SetAttribute("SaltPunchFinisherCamera", nil)
					
					VictimLuaCharacter:RestartRespawnTimer()
				end)
			else
				self:FireReliableVFX("Global/Dashing/Forward Dash", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
				self:FireReliableVFX("Reigen/Salt Punch", "Hit", self.LuaCharacter.RootPart)

				if self.Combat:CalculateYDifference(VictimLuaPlayer) >= 3 then
					self.Combat:PushSkidVictim(VictimLuaPlayer, {
						StartVelocityXZ = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 40,
						StartVelocityY = Vector3.yAxis * 90,
						StartDuration = 0.4,
						LandedRollVelocityZ = 125,
						LandedRollDuration = 0.75
					})
				else
					local VelocityObject = self:VelocityOn(VictimCombat)
					VelocityObject.Settings.RemoveTime = 0.1
					VelocityObject.Settings.Velocity = self.LuaCharacter.RootPart.CFrame.LookVector * 55 + Vector3.yAxis * 32.5
					VelocityObject:Fire()

					self:Afflict(VictimLuaPlayer, {
						Ragdoll = 1.75;
						ExcludeAttempts = true,
					})
					-- VictimCombat.Ragdoll:Toggle(true, 1.75)
				end
			end
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(self.Cooldown)

		self.Combat:TimesSpeed(7)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.CancelJob:Task(self:CreateMoveSFX("Reigen", "Salt Punch"))
	self:FireReliableVFX("Reigen/Salt Punch", "Start", self.LuaCharacter.RootPart)

	local VelocityObject = self.Combat:Velocity()
	VelocityObject.Settings.Duration = 1.05
	VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
	VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
	VelocityObject.Settings.Controllable = true
	VelocityObject.Settings.Z = 60
	VelocityObject:Fire()

	self.Thread.Job:Task(VelocityObject)

	self.Animations.Punch:GetMarkerReachedSignal("hit"):Wait()

	self:FireReliableVFX("Reigen/Salt Punch", "Punch", self.LuaCharacter.RootPart)

	Hitbox:BeginCast(0.1)

	task.wait(0.25)

	if self.SaltFinisherHit then
		return
	end

	if not self.SaltHit then
		task.wait(0.275)
	end

	self:Close()
end

function Attack:AirVariant()
	self.Animations.AerialStart:Play()
	self.Animations.AerialStart:AdjustSpeed(1.5)

	self.Thread.CancelJob:Task(self:CreateMoveSFX("Reigen", "AntiEsperDropkick"))

	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self.DropkickHit = false
	self.DropkickFinisherHit = false

	self:FireReliableVFX("Reigen/AntiEsperDropkick", "Startup", self.LuaCharacter.RootPart)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(self.Cooldown)

		self.Animations.AerialStart:Stop(0.25)

		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)
	
	local VelocityObject = self.Combat:Velocity()
	VelocityObject.Settings.Duration = 0.8
	VelocityObject.Settings.RemoveTime = 1.2
	VelocityObject.Settings.MaxForce = Vector3.one * 40000
	VelocityObject.Settings.Controllable = true
	VelocityObject.Settings.Z = -15
	VelocityObject.Settings.Y = 15
	VelocityObject:Fire()

	self.Thread.Job:Task(VelocityObject)

	self.Thread.Job:Task(self.Animations.AerialStart:GetMarkerReachedSignal("start"):Once(function()
		if VelocityObject then
			VelocityObject:Destroy()
		end 

		local FallVelocityObject = self.Combat:Velocity()
		FallVelocityObject.Settings.MaxForce = Vector3.one * 50000
		FallVelocityObject.Settings.Controllable = true
		FallVelocityObject.Settings.Z = 75
		FallVelocityObject.Settings.Y = -75
		FallVelocityObject.Settings.NeedsVelocityAttribute = true -- fixes inf slide
		FallVelocityObject:Fire()
		
		self.Thread.Job:Task(FallVelocityObject)

		self.Thread.Job:Task(task.delay(0.25, function() -- that was why animation was pausing forever with no cds, it was putting speed to 0 even after its hit
			self.Animations.AerialStart:AdjustSpeed(0)
		end))

		self:FireReliableVFX("Reigen/AntiEsperDropkick", "Drop", self.LuaCharacter.RootPart)

		local SlideHitbox = self:CreateHitbox(false);
		SlideHitbox.Params.Offset = CFrame.new(0, -0.75, -4.25)
		SlideHitbox.Params.Size = Vector3.new(5.5, 4, 7.25)

		SlideHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
			self.Combat:Afflict(NewVictimLuaPlayer, {
				Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 10 + Vector3.yAxis * 5, 0.1},
				Damage = 0.075,
				Ragdoll = 0.75,
			})

			task.delay(0.15, function()
				SlideHitbox:RemoveHumanoid(NewVictimLuaPlayer.Character.Humanoid)
			end)
		end)

		local SlamHitbox = self:CreateHitbox(true);
		SlamHitbox.Params.Offset = CFrame.new(0, 0, 0)
		SlamHitbox.Params.Size = 6
		SlamHitbox.Params.DestroyOnEndCast = false

		SlamHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Finisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= 7.5 and not self.DropkickFinisherHit)

			local Validated = self:Afflict(VictimLuaPlayer, {
				Damage = not Finisher and 3,
				--Ragdoll = 1.4,
				Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 55 + Vector3.yAxis * 5, 0.1}
			})

			if Validated then
				self.DropkickHit = true

				FallVelocityObject:Destroy()

				if Finisher then
					self.DropkickFinisherHit = true
					self:Finisher(VictimLuaPlayer, VictimLuaCharacter, VictimCombat)
				else
					self:FireReliableVFX("Reigen/AntiEsperDropkick", "Slam", self.LuaCharacter.Torso)
					self:FireReliableVFX("Reigen/AntiEsperDropkick", "Hit", VictimLuaCharacter.Torso)

					if not VictimCombat:GetState("Ragdolled") then
						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true;
							Ragdoll = 1.4;
						})
						--VictimCombat.Ragdoll:Toggle(true, 1.4)
					end
					
					local VelocityObject = self:VelocityOn(VictimCombat)
					VelocityObject.Settings.RemoveTime = 0.15
					VelocityObject.Settings.Velocity = self.LuaCharacter.RootPart.CFrame.LookVector * 15 - Vector3.yAxis * 50
					VelocityObject:Fire()

					if not self.DropkickFinisherHit then
						self:Close()
					end
				end
			end 
		end)

		local function StartSimulating()
			local KickDownConnection; KickDownConnection = self.Thread.Job:Task(RunService.PostSimulation:Connect(function()
				self.KickRaycast = workspace:Raycast(
					self.LuaCharacter.RootPart.Position, 
					(self.LuaCharacter.RootPart.CFrame * CFrame.Angles(math.rad(45), 0, 0)).UpVector * -15,
					Utility.VisualParams
				)

				if self.KickRaycast then
					KickDownConnection:Disconnect()

					SlamHitbox.Adornee = self.KickRaycast.Position
					SlamHitbox:Detect()

					if not self.DropkickHit and not self.Thread.Closed then
						self.Thread.CancelJob:Task(self:CreateMoveSFX("Reigen", "AntiEsperDropkick", "Slide"))
						self:FireReliableVFX("Reigen/AntiEsperDropkick", "Slide", self.LuaCharacter.RootPart)
						self:FireReliableVFX("Reigen/AntiEsperDropkick", "Slam", self.LuaCharacter.Torso)

						self.Animations.AerialStart:Stop(0.05)
						self.Animations.Slide:Play()

						SlideHitbox:BeginCast()
						
						local SlideVelObject = self.Combat:Velocity()
						SlideVelObject.Settings.Duration = 1.3
						SlideVelObject.Settings.RemoveTime = 1.6
						SlideVelObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
						SlideVelObject.Settings.Controllable = true
						SlideVelObject.Settings.Z = 50
						SlideVelObject:Fire()
						
						self.Thread.Job:Task(SlideVelObject)
						
						self.Thread.OnClosed:Connect(function()
							self:FireReliableVFX("Reigen/AntiEsperDropkick", "SlideEnd", self.LuaCharacter.RootPart)
						end)

						task.wait(1.1)

						SlideHitbox:EndCast()
						SlideHitbox:Destroy()

						self:FireReliableVFX("Reigen/AntiEsperDropkick", "SlideEnd", self.LuaCharacter.RootPart)

						task.wait(0.25)

						self.Animations.Slide:Stop(0.35)

						task.wait(0.25)

						self:Close()
					end
				end
			end))
		end

		task.delay(0.1, StartSimulating)
	end))
end

function Attack:Finisher(VictimLuaPlayer, VictimLuaCharacter, VictimCombat)
	VictimCombat:StackState("HitboxImmunity", true)
	self.Combat:StackState("HitboxImmunity", true)

	local StopAutoRotate = Utility.StopAutoRotate(self.LuaCharacter.Humanoid)
	local VictimStopAutoRotate = Utility.StopAutoRotate(VictimLuaCharacter.Humanoid)
	VictimLuaCharacter:StopRespawnTimer()

	self.Combat:DivideSpeed(100)

	self.Animations.AerialStart:Stop()
	self.Animations.AerialFinisher:Play()

	VictimCombat.Animations.GrabVictims.AntiEsperDropkickFinisher:Play()	

	local GrabObject

	GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -0.25))

	self:FireReliableVFX("Reigen/AntiEsperDropkick", "SFX", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)	

	self.Thread.OnClosed:Connect(function()
		StopAutoRotate:Destroy()
		VictimStopAutoRotate:Destroy()

		if GrabObject then
			GrabObject.Destroy(0)
			VictimCombat:Unstun()
		end

		self.Combat:HideUI(false)
		VictimCombat:HideUI(false)

		self.Combat:TimesSpeed(100)

		VictimLuaCharacter:RestartRespawnTimer()

		VictimCombat.Animations.GrabVictims.AntiEsperDropkickFinisher:Stop()
		self.Animations.AerialFinisher:Stop()

		VictimCombat:StackState("HitboxImmunity", false)
		self.Combat:StackState("HitboxImmunity", false)
	end)

	self.Thread.Job:Task(self.Animations.AerialFinisher:GetMarkerReachedSignal("hit"):Once(function()
		self:FireReliableVFX("Reigen/AntiEsperDropkick", "FinisherHit", VictimLuaCharacter.RootPart)

		if GrabObject then
			GrabObject.Destroy(0)
		end

		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 1.5
		VelocityObject.Settings.RemoveTime = 1.5
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 50000
		VelocityObject.Settings.Velocity = self.LuaCharacter.RootPart.CFrame.LookVector * -7.5
		VelocityObject:Fire()

		local VictimVelocityObject = self:VelocityOn(VictimCombat)
		VictimVelocityObject.Settings.Duration = 2
		VictimVelocityObject.Settings.RemoveTime = 2
		VictimVelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 50000
		VictimVelocityObject.Settings.Velocity = self.LuaCharacter.RootPart.CFrame.LookVector * 10
		VictimVelocityObject:Fire()
	end))

	self.Thread.Job:Task(VictimCombat.Animations.GrabVictims.AntiEsperDropkickFinisher:GetMarkerReachedSignal("spin"):Once(function()
		self:FireReliableVFX("Reigen/AntiEsperDropkick", "Spin", VictimLuaCharacter.RootPart)	
	end))

	self.Thread.Job:Task(VictimCombat.Animations.GrabVictims.AntiEsperDropkickFinisher:GetMarkerReachedSignal("fall1"):Once(function()
		self:FireReliableVFX("Reigen/AntiEsperDropkick", "EndSpin", VictimLuaCharacter.RootPart)
		self:FireReliableVFX("Reigen/AntiEsperDropkick", "FallAtEnd", VictimLuaCharacter.RootPart)
	end))

	self.Thread.Job:Task(VictimCombat.Animations.GrabVictims.AntiEsperDropkickFinisher:GetMarkerReachedSignal("fall2"):Once(function()
		self:FireReliableVFX("Reigen/AntiEsperDropkick", "Fall", VictimLuaCharacter.RootPart)
	end))

	self.Thread.Job:Task(self.Animations.AerialFinisher:GetMarkerReachedSignal("teleport"):Once(function()
		self:FireReliableVFX("Reigen/AntiEsperDropkick", "Teleport", self.LuaCharacter.RootPart)

		self.LuaCharacter.RootPart.CFrame = VictimLuaCharacter.RootPart.CFrame * CFrame.new(0, 0, 0.25)

		GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -0.25))
	end))

	self.Thread.Job:Task(self.Animations.AerialFinisher:GetMarkerReachedSignal("barrage"):Once(function()
		self:FireReliableVFX("Reigen/AntiEsperDropkick", "Barrage", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
	end))

	self.Thread.Job:Task(self.Animations.AerialFinisher:GetMarkerReachedSignal("endbarrage"):Once(function()
		self:FireReliableVFX("Reigen/AntiEsperDropkick", "BarrageEnd", self.LuaCharacter.RootPart)
	end))

	self.Thread.OnClosed:Connect(function()
		self:FireReliableVFX("Reigen/AntiEsperDropkick", "BarrageEnd", self.LuaCharacter.RootPart)
	end)

	self.Thread.Job:Task(self.Animations.AerialFinisher:GetMarkerReachedSignal("light"):Once(function()
		self.LuaPlayer.Replication.Attributes:SetAttribute("AntiEsperDropkickCamera", true)
		VictimLuaPlayer.Replication.Attributes:SetAttribute("AntiEsperDropkickCamera", true)

		self.Combat:HideUI(true)
		VictimCombat:HideUI(true)

		self:FireReliableVFX("Reigen/AntiEsperDropkick", "Crush", self.LuaCharacter.RootPart, VictimLuaPlayer.Player)

		self.Thread.OnClosed:Connect(function()
			self:FireReliableVFX("Reigen/AntiEsperDropkick", "CrushRemove", self.LuaCharacter.RootPart)
		end)

		VictimCombat.Animations.GrabVictims.AntiEsperDropkickFinisher:AdjustSpeed(0)
	end))

	self.Thread.Job:Task(self.Animations.AerialFinisher:GetMarkerReachedSignal("end"):Once(function()
		self:FireReliableVFX("Reigen/AntiEsperDropkick", "CrushEnd", self.LuaCharacter.RootPart, VictimLuaPlayer.Player)

		self.LuaPlayer.Replication.Attributes:SetAttribute("AntiEsperDropkickCamera", nil)
		VictimLuaPlayer.Replication.Attributes:SetAttribute("AntiEsperDropkickCamera", nil)

		if GrabObject then
			GrabObject.Destroy(0)
			VictimCombat:Unstun()
		end

		self:Afflict(VictimLuaPlayer, {
			Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 5 - Vector3.yAxis * 35, 0.1},
			FinisherKill = true,
			ExcludeAttempts = true
		})

		task.wait(0.5)

		self:Close()
	end))
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.TryToCancelMoves = true
	
	self.DropkickHit = false
	self.SaltHit = false
	
	self.DropkickFinisherHit = false
	self.SaltFinisherHit = false
	self.Cooldown = 14

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack