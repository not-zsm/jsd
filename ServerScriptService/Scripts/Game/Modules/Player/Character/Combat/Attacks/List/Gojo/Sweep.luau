local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes
local HotbarRemotes = Remotes.Combat.UI.Hotbar

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:AirVariant()
	self.Animations.AirVariant:Play()

	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)
	
	local VelocityObject = self.Combat:Velocity()
	VelocityObject.Settings.Duration = 0.8
	VelocityObject.Settings.RemoveTime = 1.3
	VelocityObject.Settings.MaxForce = Vector3.one * 30000
	VelocityObject.Settings.Controllable = true
	VelocityObject.Settings.Z = -55
	VelocityObject.Settings.Y = 62.5
	VelocityObject:Fire()
	
	self.Thread.Job:Task(VelocityObject)

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, -8, -10) * CFrame.Angles(math.rad(-45), 0, 0)
	Hitbox.Params.Size = Vector3.new(13, 13, 45)
	Hitbox.Params.DestroyOnEndCast = false

	local Hit = false
	
	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Finisher = self:IsFinisherEnabled() and VictimLuaCharacter.Humanoid.Health <= 5
		
		Hit = self:Afflict(VictimLuaPlayer, {
			DontBypassIFrames = {"Grab", "Backdash"},
			BreakBlock = true,
			Damage = 5
		})
	
		if Hit then
			if Finisher then
				self:FireReliableVFX("Gojo/Max Red", "Finisher", VictimLuaCharacter.Model)
				
			elseif VictimCombat:GetState("Ragdolled") then
				self.Combat:TSBPushVictim(VictimLuaPlayer, {
					LandedRollVelocityZ = 75,
					LandedRollDuration = 0.9,
					DurationMultiplier = 1.25,
				})
				
				VictimCombat:StackState("EvasiveState", true)

				task.delay(1.25 + math.clamp(self.LuaPlayer:GetPing(), 0, 1), function()
					VictimCombat:StackState("EvasiveState", false)
				end)
			else
				local VelocityObject = self:VelocityOn(VictimCombat)
				VelocityObject.Settings.RemoveTime = 0.1
				VelocityObject.Settings.Velocity = self.LuaCharacter.RootPart.CFrame.LookVector * 30 - Vector3.yAxis * 25
				VelocityObject:Fire()

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true;
					Ragdoll = 1.5;
				})
				
				--VictimCombat.Ragdoll:Toggle(true, 1.5)
			end
		end
	end)

	self:FireReliableVFX("Gojo/Sweep", "AirVariantSFX", self.LuaCharacter.RootPart)

	self.Thread.OnClosed:Once(function()
		self:AddCooldown(25)

		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(task.delay(0.2, function()
		self:FireReliableVFX("Gojo/Sweep", "Hand", self.LuaCharacter.RightArm)

		self.Thread.OnClosed:Once(function()
			self:FireReliableVFX("Gojo/Sweep", "RemoveHand", self.LuaCharacter.RightArm)
		end)
	end))

	self.Animations.AirVariant:GetMarkerReachedSignal("fire"):Wait()

	self.Combat.Hitbox:Destruction(CFrame.new(0, -8, -10) * CFrame.Angles(math.rad(-45), 0, 0), Vector3.new(8, 8, 45), 3)
	self:FireReliableVFX("Gojo/Sweep", "AirBlast", self.LuaCharacter.RightArm)

	Hitbox:BeginCast(0.15)
	
	local VelocityObject = self.Combat:Velocity()
	VelocityObject.Settings.Duration = 1
	VelocityObject.Settings.RemoveTime = 0.25
	VelocityObject.Settings.MaxForce = Vector3.one * 30000
	VelocityObject.Settings.Controllable = true
	VelocityObject.Settings.Y = 100
	VelocityObject:Fire()
	
	local VelocityObject2 = self.Combat:Velocity()
	VelocityObject2.Settings.Duration = 1
	VelocityObject2.Settings.RemoveTime = 0.4
	VelocityObject2.Settings.MaxForce = Vector3.one * 30000
	VelocityObject2.Settings.Controllable = true
	VelocityObject2.Settings.Z = -37.5
	VelocityObject2:Fire()

	self.Thread.Job:Task(VelocityObject)
	self.Thread.Job:Task(VelocityObject2)

	task.wait(0.35) --0.2
	
	if not Hit then
		self.Animations.AirVariant:Stop()
		self.Animations.AirVariant_Loop:Play(0.3)
		
		self.Thread.Job:Task(self.Combat.ClientLanded:Once(function()
			self.Animations.AirVariant_Loop:Stop(0)
			self.Animations.AirVariant_Land:Play(0, 1, 1.23)
			
			self:FireReliableVFX("Gojo/Sweep", "Land", self.LuaCharacter.Model)
			
			local Hitbox = self:CreateHitbox(true)
			Hitbox.Params.Offset = CFrame.identity
			Hitbox.Params.Size = 7

			Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				self:Afflict(VictimLuaPlayer, {
					Damage = 5,
					DontCheckBlock = true,
					Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 45 + Vector3.yAxis * 20, 0.1},
					Ragdoll = 1.5
				})
			end)
			
			Hitbox:Detect()
			
			self.Thread.Job:Task(self.Animations.AirVariant_Land:GetMarkerReachedSignal("end"):Once(function()
				self:Close()
			end))
		end))
	else
		self.Animations.AirVariant:AdjustSpeed(3)
		self:Close()
	end
end

function Attack:Activate()
	if (self.VariantsEnabled and (self.HoldingJump or self.FreeFalling)) or self.ForceVariant then
		return self:AirVariant()
	end

	--self.Animations.Sweep:Play(0.1, 1, 0.6)
	self.Animations.Sweep:Play()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self.Hit = false

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -1)
	Hitbox.Params.Size = Vector3.new(8, 8, 9)
	Hitbox.Params.DestroyOnEndCast = false
	Hitbox.Params.MaxTargets = 3

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		if (Hitbox.HitCount > 1) then 
			local Validated = self:Afflict(VictimLuaPlayer, {
				BreakBlock = true,
				Ragdoll = 1,
				Velocity = {Vector3.yAxis * 25, 0.1}
			})

			if Validated then
				VictimLuaCharacter.RootPart:ApplyAngularImpulse(Vector3.new(Utility.Seed:NextNumber(-100, 100), Utility.Seed:NextNumber(-100, 100), Utility.Seed:NextNumber(-100, 100)))
			end

			return 
		end

		local AirVariant = VictimCombat:GetState("Ragdolled") or self.ForceSpecialVariant

		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true
		})

		if Validated then
			self.Hit = true
			
			local Finisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= 10)
			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -5) * CFrame.Angles(0, math.pi, 0))

			self.Animations.Sweep:Stop()

			local HitAnimation : AnimationTrack =
				(Finisher and self.Animations.Finisher) or
				(AirVariant and self.Animations.HitAirVariant or self.Animations.Hit)
			
			HitAnimation:Play()

			local VictimAnimation : AnimationTrack = 
				(Finisher and VictimCombat.Animations.GrabVictims.SweepFinisher) or
				(AirVariant and VictimCombat.Animations.GrabVictims.RedAirVariant or VictimCombat.Animations.GrabVictims.Red)
			VictimAnimation:Play()

			self:FireReliableVFX("Gojo/Sweep", "Start", VictimLuaCharacter.RootPart, self.LuaCharacter.RootPart)

			local Ended = false

			self.Thread.OnClosed:Connect(function()
				if not Ended then
					VictimAnimation:Stop()
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end
			end)

			self.Thread.Job:Task(HitAnimation:GetMarkerReachedSignal("hit"):Connect(function(Count : string)
				if Count == "2" then
					self:FireReliableVFX("Gojo/Sweep", "Hand", self.LuaCharacter.LeftArm)

					self.Thread.OnClosed:Connect(function()
						self:FireReliableVFX("Gojo/Sweep", "RemoveHand", self.LuaCharacter.LeftArm)
					end)
				end

				local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -3), Vector3.new(9, 6, 10))

				AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
					local NewVictimLuaCharacter = NewVictimLuaPlayer.Character
					local NewVictimCombat = NewVictimLuaCharacter.Combat

					local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
						Damage = 4,
						TrueStun = Count == "1" and 0.5 or 1,
					})

					if Validated then
						if NewVictimCombat:GetState("Ragdolled") then
							NewVictimCombat.Ragdoll:Toggle(false)
						end

						self:FireVFX("Gojo/Sweep", "Hit", self.LuaCharacter.RootPart, NewVictimLuaCharacter.RootPart, Count)
						NewVictimCombat:PlayRandomHitReaction()
					end
				end)

				AOEHitbox:BeginCast(0.05)

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {
						DontKill = true,
						Amount = 1.5
					}
				})

				self:FireVFX("Gojo/Sweep", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, Count)
			end)) 

			self.Thread.Job:Task(HitAnimation:GetMarkerReachedSignal("blast"):Once(function(Count : string)
				local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -8), Vector3.new(10, 6, 25))

				AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
					local NewVictimLuaCharacter = NewVictimLuaPlayer.Character

					local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
						BreakBlock = true,
						Damage = 4,
						YDifferenceValue = 0
					})

					if Validated then
						self.Combat:PushSkidVictim(NewVictimLuaPlayer, {
							TimeTilGroundDetection = 0.35,
							StartVelocityXZ = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 70,
							StartVelocityY = Vector3.yAxis * 175,
							StartDuration = 0.46,
							LandedRollVelocityZ = 130,
							LandedRollDuration = 0.8
						})
					end
				end)

				AOEHitbox:BeginCast(0.05)

				if Finisher then
					local FinisherEnded = false

					VictimCombat:StackState("HitboxImmunity", true)
					self.Combat:StackState("HitboxImmunity", true)

					VictimLuaCharacter:StopRespawnTimer()

					local StopAutoRotate = Utility.StopAutoRotate(self.LuaCharacter.Humanoid)
					local RunHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -7), Vector3.new(10, 8, 13))

					RunHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
						self.Combat:Afflict(NewVictimLuaPlayer, {
							TriggerActiveCounterOverOrEqualLevel = -1,
							BreakBlock = true,
							Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 60 + Vector3.yAxis * 5, 0.1},
							Damage = 1,
							Ragdoll = 2,
						})

						task.delay(0.2, function()
							RunHitbox:RemoveHumanoid(NewVictimLuaPlayer.Character.Humanoid)
						end)
					end)

					self.Thread.OnClosed:Connect(function()
						GrabObject.Destroy(0)
						VictimCombat:Unstun()

						RunHitbox:EndCast()
						RunHitbox:Destroy()

						StopAutoRotate:Destroy()
						VictimLuaCharacter:RestartRespawnTimer()

						VictimCombat:StackState("HitboxImmunity", false)
						self.Combat:StackState("HitboxImmunity", false)
					end)

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("pull"):Connect(function()
						self:FireReliableVFX("Gojo/Sweep", "FinisherPull", self.LuaCharacter.Torso, VictimLuaCharacter.Torso)
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("run"):Once(function()
						StopAutoRotate:Destroy()

						local VelocityObject = self.Combat:Velocity()
						VelocityObject.Settings.Duration = 2.5
						VelocityObject.Settings.RemoveTime = 2.5
						VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
						VelocityObject.Settings.Controllable = true
						VelocityObject.Settings.Z = 37.5
						VelocityObject:Fire()
						
						self.Thread.Job:Task(VelocityObject)

						if not self.LuaPlayer.IsNPC then
							self.LuaPlayer.Replication.Attributes:SetAttribute("DestructibleDestroyLoop", true)
							self.LuaPlayer.Remotes.DestructibleDestroyLoop:FireClient(self.LuaPlayer.Player, CFrame.new(0, 0, -8), Vector3.new(4, 6, 5))

							self.Thread.OnClosed:Connect(function()
								self.LuaPlayer.Replication.Attributes:SetAttribute("DestructibleDestroyLoop", nil)
							end)
						end
		
						self:FireReliableVFX("Gojo/Sweep", "FinisherRun", self.LuaCharacter.Torso, VictimLuaCharacter.Torso)

						self.Thread.OnClosed:Connect(function()
							self:FireReliableVFX("Gojo/Sweep", "RemoveRunEffects", self.LuaCharacter.Torso)
						end)

						RunHitbox:BeginCast()
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("push"):Once(function()
						local VelocityObject = self.Combat:Velocity()
						VelocityObject.Settings.Duration = 0.85
						VelocityObject.Settings.RemoveTime = 0.65
						VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
						VelocityObject.Settings.Controllable = true
						VelocityObject.Settings.Z = 200
						VelocityObject:Fire()

						self.Thread.Job:Task(VelocityObject)
						
						local VelocityObject = self.Combat:Velocity()
						VelocityObject.Settings.Duration = 2.5
						VelocityObject.Settings.RemoveTime = 2.5
						VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
						VelocityObject.Settings.Controllable = true
						VelocityObject.Settings.Z = 37.5
						VelocityObject:Fire()

						self.Thread.Job:Task(VelocityObject)
						self:FireReliableVFX("Gojo/Sweep", "FinisherPush", self.LuaCharacter.Torso, VictimLuaCharacter.Torso)
						self.LuaPlayer.Replication.Attributes:SetAttribute("DestructibleDestroyLoop", nil)

						RunHitbox:EndCast()
						RunHitbox:Destroy()
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("step"):Once(function()
						local VelocityObject = self.Combat:Velocity()
						VelocityObject.Settings.Duration = 0.8
						VelocityObject.Settings.RemoveTime = 0.8
						VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
						VelocityObject.Settings.Controllable = true
						VelocityObject.Settings.Z = 95
						VelocityObject:Fire()

						self.Thread.Job:Task(VelocityObject)
						
						self:FireReliableVFX("Gojo/Sweep", "FinisherSlide", VictimLuaCharacter.Torso, 10)
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("slide"):Once(function()
						local VelocityObject = self.Combat:Velocity()
						VelocityObject.Settings.Duration = 1
						VelocityObject.Settings.RemoveTime = 1
						VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
						VelocityObject.Settings.Controllable = true
						VelocityObject.Settings.Z = 50
						VelocityObject:Fire()

						self.Thread.Job:Task(VelocityObject)
						
						self:FireReliableVFX("Gojo/Sweep", "FinisherSlide", VictimLuaCharacter.Torso, 20)
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("grabbed"):Once(function()
						self:FireReliableVFX("Gojo/Sweep", "FinisherGrabbed", VictimLuaCharacter.Torso)
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("slam"):Once(function()
						Ended = true

						GrabObject.Destroy(0)

						self:FireReliableVFX("Gojo/Sweep", "FinisherSlam", VictimLuaCharacter.Torso)

						self.Combat.Hitbox:Destruction(CFrame.new(0, 0, -2.5), Vector3.new(12, 10, 7.5), 2)

						local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -5), Vector3.new(25, 15, 25))

						AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
							self.Combat:Afflict(NewVictimLuaPlayer, {
								TriggerActiveCounterOverOrEqualLevel = -1,
								BreakBlock = true,
								Damage = 5,
								Ragdoll = 3,
								Velocity = {Vector3.yAxis * 55, 0.1}
							})
						end)

						AOEHitbox:BeginCast(0.05)

						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							FinisherKill = true
						})

						VictimCombat.Ragdoll:Toggle(true)
						
						self:Close()
					end))

					self:FireReliableVFX("Gojo/Sweep", "FinisherStart", self.LuaCharacter.RootPart, self.LuaCharacter.LeftArm)
				else
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = 4.5
					})

					Ended = true

					GrabObject.Destroy(0)
					VictimAnimation:Stop(0)

					self:FireReliableVFX("Gojo/Sweep", "Blast", self.LuaCharacter.LeftArm, AirVariant)

					if AirVariant then
						VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 1, -5) * CFrame.Angles(0, math.pi, 0))

						self.Combat:PushSkidVictim(VictimLuaPlayer, {
							CannotEvasive = true,
							TimeTilGroundDetection = 0.35,
							StartVelocityXZ = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 37.5,
							StartVelocityY = Vector3.yAxis * 95,
							StartDuration = 0.55,
							LandedRollVelocityZ = 130,
							LandedRollDuration = 0.7875,
							DurationMultiplier = 0.95,
						})
						
						local Time = (0.55 + (0.7875 * 0.95))
	
						VictimCombat:StackState("EvasiveState", true)

						local Thread = task.delay(Time + math.clamp(self.LuaPlayer:GetPing(), 0, 1), function()
							VictimCombat:StackState("EvasiveState", false)
						end)

						local Connection : RBXScriptConnection; Connection = VictimCombat:GetStateChanged("Stunned"):Connect(function(Value : boolean)
							if Value then
								Connection:Disconnect()
								Utility.CloseThreadSafe(Thread)
								VictimCombat:StackState("EvasiveState", false)
							end
						end)
						
						--local Time = 1
						--local TimeUntilCheckStun = 0.5

						--VictimCombat:StackState("EvasiveState", true)

						--task.delay(TimeUntilCheckStun, function()
						--	local Thread = task.delay((Time - TimeUntilCheckStun) + math.clamp(self.LuaPlayer:GetPing(), 0, 1), function()
						--		VictimCombat:StackState("EvasiveState", false)
						--	end)

						--	local Connection : RBXScriptConnection; Connection = VictimCombat:GetStateChanged("Stunned"):Connect(function(Value : boolean)
						--		if Value then
						--			Connection:Disconnect()
						--			Utility.CloseThreadSafe(Thread)
						--			VictimCombat:StackState("EvasiveState", false)
						--		end
						--	end)
						--end)
					else	
						self.Combat:TSBPushVictim(VictimLuaPlayer, {
							LandedRollVelocityZ = 155,
							LandedRollDuration = 1,
							DurationMultiplier = 0.7
						})

						VictimCombat:StackState("EvasiveState", true)
		
						task.delay(0.5 + math.clamp(self.LuaPlayer:GetPing(), 0, 1), function()
							VictimCombat:StackState("EvasiveState", false)
						end)
					end

					VictimCombat:Unstun()

					if not AirVariant then
						task.wait(0.3)
					end

					self:Close()
				end
			end))
		end
	end)

	self.Thread.OnClosed:Once(function()
		--self:AddCooldown(25)
		self:AddCooldown(30)
		
		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Sweep:GetMarkerReachedSignal("sweep"):Once(function()
		self:FireVFX("Gojo/Sweep", "Sweep", self.LuaCharacter.RootPart)
	end))

	self.Thread.Job:Task(self.Animations.Sweep:GetMarkerReachedSignal("hit"):Once(function()
		--self.Animations.Sweep:AdjustSpeed(1)
		Hitbox:BeginCast(0.05)
	end))
	
	self.Thread.Job:Task(self.Animations.Sweep.Stopped:Once(function()
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