local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )

----------------------------------------------------------------------------------

local Attack = {}
Attack.__index = Attack

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Pretrigger()
	if self.UseTwicePart then
		self.TriedTwicePart = true
		self.OnTriedTwicePart:Fire()
	end
end

function Attack:ToggleUseTwicePart(Value : boolean)
	if self.UseTwicePart ~= Value then
		self.UseTwicePart = Value

		if Value then
			self.Combat:ChangeAttackDisplay(self.Name, self.DisplayName, {
				FlashColor = Color3.fromRGB(255, 255, 255),
				Tip = "[USE AGAIN]"
			})
		else
			self.Combat:ChangeAttackDisplay(self.Name, self.DisplayName, {
				FlashColor = Color3.fromRGB(255, 255, 255),
				Tip = ""
			})
		end
	end
end

function Attack:SpaceVariant()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self.Hit = false
	self.UseTwicePart = false
	self.TriedTwicePart = false
	
	self.Animations.SpaceVariant:Play()

	self:FireReliableVFX("Gojo/Ruthless Kicks", "OnStart", self.LuaCharacter.Model)
	self.Thread.CancelJob:Task(self:CreateMoveSFX("Gojo", "Ruthless Kicks"))

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -2)
	Hitbox.Params.Size = Vector3.new(6, 6, 7)
	Hitbox.Params.DestroyOnEndCast = false
	Hitbox.Params.MaxTargets = 1

	local Blocked = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated, Type = self:Afflict(VictimLuaPlayer, {
			YDifferenceValue = -2,
		})

		Blocked = (Type == "Blocked")

		if Validated then
			self.Hit = true

			local VictimAnimation : AnimationTrack = VictimLuaCharacter.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Gojo["Ruthless Beatdown"].VariantVictim)
			local VictimAnimationPush : AnimationTrack = VictimLuaCharacter.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Gojo["Ruthless Beatdown"].VictimPush)

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, 0.5))

			local BeenPushed = false

			self.Thread.OnClosed:Connect(function()
				if not BeenPushed then
					VictimAnimation:Stop(0)
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end
			end)

			local function Push(Z : number, Time : number)
				local VelocityObject = self.Combat:Velocity()

				if VelocityObject then
					VelocityObject.Settings.Duration = Time
					VelocityObject.Settings.RemoveTime = Time + 0.1
					VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
					VelocityObject.Settings.Controllable = true
					VelocityObject.Settings.Z = Z
					VelocityObject:Fire()

					self.Thread.Job:Task(VelocityObject)
				end
			end

			Push(60, 0.7)
			
			self:Afflict(VictimLuaPlayer, {
				ExcludeAttempts = true,
				Damage = 2
			})

			self.Thread.Job:Task(self.Animations.VariantHit:GetMarkerReachedSignal("hit"):Connect(function(Parameter : string)
				if Parameter == "1" then
					Push(50, 0.65)
					
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = 4
					})

				elseif Parameter == "2" then
					BeenPushed = true

					--self:ToggleUseTwicePart(true)

					--self.Thread.OnClosed:Connect(function()
					--	self:ToggleUseTwicePart(false)
					--end)

					VictimLuaCharacter.Model:PivotTo(self.Combat:GetSimulatedRoot().CFrame * CFrame.new(0, 0, -4) * CFrame.Angles(0, math.pi, 0))
					VictimAnimation:Stop(0)
					
					--local VelocityObject = self:VelocityOn(VictimCombat)
					--VelocityObject.Settings.Duration = 0.975
					--VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
					--VelocityObject.Settings.Controllable = true
					--VelocityObject.Settings.Z = -88
					--VelocityObject:Fire()

					--FlingJob:Task(VelocityObject)

					--FlingJob:Task(VictimAnimationPush.Stopped:Once(function()
					--	FlingJob:Destroy()
					--	VictimCombat:Unstun()
					--end))

					--FlingJob:Task(VictimCombat.OnStateUpdated:Connect(function(StateChanged : any, Value : any)
					--	if (StateChanged == "Stunned" or StateChanged == "Ragdolled") and Value then
					--		VictimAnimationPush:Stop(0.3)
					--	end
					--end))

					--VictimAnimationPush:Play(0)
					
					if VictimLuaCharacter.Humanoid.Health <= 7.5 then
						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							FinisherKill = true,
							Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 85  + Vector3.yAxis * 45, 0.15},
						})
					else
						self.Combat:PushSkidVictim(VictimLuaPlayer, {
							TimeTilGroundDetection = 0.35,
							StartVelocityXZ = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 100,
							StartVelocityY = Vector3.yAxis * 175,
							StartDuration = 0.46,
							LandedRollVelocityZ = 130,
							LandedRollDuration = 0.8
						})

						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							Damage = 6
						})
					end
					
					GrabObject.Destroy(0)
					VictimCombat:Unstun()

					Push(35, 0.625)

					task.wait(0.5)

					--self:ToggleUseTwicePart(false)

					if not self.TriedTwicePart then
						self.Animations.VariantHit:Stop(0.4)
						self:Close()
					end

				elseif (Parameter == "3") then
					local CF : CFrame = self.Combat:GetSimulatedRoot().CFrame

					local Hitbox = self:CreateHitbox(false);
					Hitbox.Params.Offset = CFrame.new(0, 0, -3)
					Hitbox.Params.Size = Vector3.new(6.5, 7, 9.25)
					Hitbox.Params.DestroyOnEndCast = false

					Hitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
						self.Combat:Afflict(NewVictimLuaPlayer, {
							BreakBlock = true,
							Damage = 5,
							Velocity = {CF.LookVector * 75 + -CF.RightVector * 15 + Vector3.yAxis * 30, 0.1},
							Ragdoll = 2,
						})
					end)

					Hitbox:Detect()

					task.wait(0.5)

					self:Close()
				end
			end))

			self.Thread.Job:Task(self.Animations.VariantHit:GetMarkerReachedSignal("dash"):Once(function()
				Push(100, 0.875)
			end))

			self.Thread.Job:Task(self.Animations.VariantHit:GetMarkerReachedSignal("slightpush"):Connect(function()
				Push(35, 0.625)
			end))

			----------------------------------------------------------------
			
			self.Animations.SpaceVariant:Stop(0) 
			self.Animations.VariantHit:Play(0, 1, 1.15)
			VictimAnimation:Play(0, 1, 1.15)
			
			self:FireReliableVFX("Gojo/Ruthless Kicks", "OnHit", self.LuaCharacter.Model, VictimLuaCharacter.Model)
			self.Thread.CancelJob:Task(self:CreateMoveSFX("Gojo", "Ruthless Kicks", "HitSFX"))
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(25)

		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.SpaceVariant:GetMarkerReachedSignal("hit"):Once(function()
		Hitbox:BeginCast(0.05)
	end))

	task.wait(Blocked and 1.4 or 1)

	if not self.Hit then
		self:Close()
	end
end

function Attack:Activate()
	if (self.VariantsEnabled and self.HoldingJump) or self.ForceVariant then
		return self:SpaceVariant()
	end
	
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self.Hit = false
	
	self.Animations.Start:Play(0.1, 1, 1.4)
	
	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -2)
	Hitbox.Params.Size = Vector3.new(6, 6, 7)
	Hitbox.Params.DestroyOnEndCast = false
	Hitbox.Params.MaxTargets = 1
	
	local Blocked = false
	local GiveSpeedOnCancel = true

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated, Type = self:Afflict(VictimLuaPlayer, {
			YDifferenceValue = -2,
		})
		
		Blocked = (Type == "Blocked")

		if Validated then
			self.Hit = true
			
			self.Animations.Start:Stop() 
			self.Animations.Hit:Play();
			
			self.VictimAnimations.Grab = VictimCombat.Animations.GrabVictims.RuthlessBeatdown;
			self.VictimAnimations.Grab:Play()
			
			local VictimAnimation = self.VictimAnimations.Grab;
			
			self:FireVFX("Gojo/Beatdown", "Start", self.LuaCharacter.RootPart)

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.identity)
			local Ended = false

			self.Thread.OnClosed:Connect(function()
				if not Ended then
					VictimAnimation:Stop()
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end
			end)
			
			--self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("speedup"):Connect(function(Count : string)
			--	self.Animations.Hit:AdjustSpeed(1.5)
			--	VictimCombat.Animations.GrabVictims.RuthlessBeatdown:AjustSpeed(1.5)
			--end))
			
			--self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("slowdown"):Connect(function(Count : string)
			--	self.Animations.Hit:AdjustSpeed(1)
			--	VictimCombat.Animations.GrabVictims.RuthlessBeatdown:AdjustSpeed(1)
			--end))

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("aura"):Once(function(Count : string)
				self:FireReliableVFX("Gojo/Beatdown", "Aura", self.LuaCharacter.Model)
			end))

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("hit"):Connect(function(Count : string)
				self:FireVFX("Gojo/Beatdown", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, Count)

				local Force = Vector3.new(1, 0, 1) * 80000

				if Count == "4" then
					local VelocityObject = self.Combat:Velocity()
					
					if VelocityObject then
						VelocityObject.Settings.Duration = 0.9
						VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
						VelocityObject.Settings.MaxForce = Force
						VelocityObject.Settings.Controllable = true
						VelocityObject.Settings.Z = 65
						VelocityObject:Fire()

						self.Thread.Job:Task(VelocityObject)
					end
				else
					local VelocityObject = self.Combat:Velocity()
					
					if VelocityObject then
						VelocityObject.Settings.Duration = 0.7
						VelocityObject.Settings.MaxForce = Force
						VelocityObject.Settings.Controllable = true
						VelocityObject.Settings.Z = 115
						VelocityObject:Fire()

						self.Thread.Job:Task(VelocityObject)
					end
				end

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {
						DontKill = true,
						Amount = 1.5
					}
				})

				if Count == "1" then
					GrabObject.SetOffset(CFrame.new(0, 0, 1))
				end

				local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -3), Vector3.new(10, 6, 10))

				AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
					local NewVictimLuaCharacter = NewVictimLuaPlayer.Character

					local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
						Damage = 1.25,
						Stun = 1.25,
						YDifferenceValue = 0,
						Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 100, 0.1}
					})

					if Validated then
						self:FireVFX("Gojo/Beatdown", "HitOutsiders", self.LuaCharacter.RootPart, NewVictimLuaCharacter.RootPart, Count)
						NewVictimLuaCharacter.Combat:PlayRandomHitReaction(3)
					end
				end)

				AOEHitbox:BeginCast(0.05)
			end))

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("kick"):Once(function()
				Ended = true
				
				local Finisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= 7.5)

				self:FireReliableVFX("Gojo/Beatdown", "Kick", VictimLuaCharacter.Torso, Finisher)
				VictimCombat.Animations.GrabVictims.RuthlessBeatdown:Stop(0)

				local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -1), Vector3.new(8, 6, 8))

				AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
					local NewVictimLuaCharacter = NewVictimLuaPlayer.Character

					local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
						BreakBlock = true,
						Damage = 3,
						Ragdoll = Finisher and 4 or 2,
						Velocity = {Vector3.yAxis * -100, 0.1}
					})

					if Validated then
						self:FireVFX("Global/M1", "Down Slam", NewVictimLuaCharacter.RootPart)
					end
				end)
				
				self.Combat.Hitbox:Destruction(CFrame.new(0, 0, -1), Vector3.new(8, 6, 8), 2)

				AOEHitbox:BeginCast(0.05)

				if Finisher then
					VictimCombat:StackState("HitboxImmunity", true)
					self.Combat:StackState("HitboxImmunity", true)
					
					VictimLuaCharacter:StopRespawnTimer()

					GrabObject.SetOffset(CFrame.new(0, 0, -0.25))

					self.Animations.Hit:Stop(0) self.Animations.Finisher:Play(0)
					VictimCombat.Animations.GrabVictims.RelentlessBeatdownFinisher:Play()

					self:FireReliableVFX("Gojo/Beatdown", "FinisherStart", self.LuaCharacter.RootPart)
	
					self.Thread.OnClosed:Connect(function()
						VictimLuaCharacter:RestartRespawnTimer()
						
						GrabObject.Destroy(0)
						VictimCombat:Unstun()
						
						VictimCombat.Animations.GrabVictims.RelentlessBeatdownFinisher:Stop()
						
						VictimCombat:StackState("HitboxImmunity", false)
						self.Combat:StackState("HitboxImmunity", false)
					end)

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("slam"):Connect(function()
						self:FireReliableVFX("Gojo/Beatdown", "FinisherSlam", VictimLuaCharacter.Torso)
						self.Combat.Hitbox:Destruction(CFrame.new(0, 5, -1), Vector3.new(8, 15, 8), 2)
						
						local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 5, -1), Vector3.new(8, 15, 8))

						AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
							self.Combat:Afflict(NewVictimLuaPlayer, {
								TriggerActiveCounterOverOrEqualLevel = -1,
								BreakBlock = true,
								Damage = 3,
								Ragdoll = 3,
								Velocity = {Vector3.yAxis * 35, 0.1}
							})
						end)

						AOEHitbox:BeginCast(0.05)
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("crush"):Connect(function()
						self.LuaCharacter:Anchor(true)
						VictimLuaCharacter:Anchor(true)
						
						self:FireReliableVFX("Gojo/Beatdown", "FinisherCrush", self.LuaCharacter.Torso, VictimLuaCharacter.Torso)
						
						self.Thread.OnClosed:Connect(function()
							self.LuaCharacter:Anchor(false)
							VictimLuaCharacter:Anchor(false)
							
							self:FireReliableVFX("Gojo/Beatdown", "ClearFinisherCrush", self.LuaCharacter.Torso)
						end)
						
						local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -1), Vector3.new(8, 15, 8))
					
						AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
							self.Combat:Afflict(NewVictimLuaPlayer, {
								TriggerActiveCounterOverOrEqualLevel = -1,
								BreakBlock = true,
								Damage = 3,
								Ragdoll = 3,
								Velocity = {Vector3.yAxis * 45, 0.1}
							})
						end)

						AOEHitbox:BeginCast(0.05)
					end))

					self.Animations.Finisher:GetMarkerReachedSignal("kill"):Wait()

					self.LuaCharacter:Anchor(false)
					VictimLuaCharacter:Anchor(false)

					GrabObject.Destroy(0)
	
					self:FireReliableVFX("Gojo/Beatdown", "FinisherCrushed", self.LuaCharacter.Torso, VictimLuaCharacter.Torso)

					VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -5) * CFrame.Angles(0, math.pi, 0))

					self:Afflict(VictimLuaPlayer, {
						FinisherKill = true,
						ExcludeAttempts = true
					})

					VictimCombat.Ragdoll:Toggle(true)

					local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -1), Vector3.new(15, 12.5, 15))
					self.Combat.Hitbox:Destruction(CFrame.new(0, 0, -1), Vector3.new(15, 12.5, 15), 2) 

					AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
						self.Combat:Afflict(NewVictimLuaPlayer, {
							TriggerActiveCounterOverOrEqualLevel = -1,
							BreakBlock = true,
							Damage = 7,
							Ragdoll = 3,
							Velocity = {Vector3.yAxis * 65, 0.1}
						})
					end)

					AOEHitbox:BeginCast(0.05)

					task.wait(1)

					self:Close()
				else
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Ragdoll = 1.5;
						Damage = 4
					})
					
					GrabObject.Destroy(0)
					
					VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 1.5, -5.5) * CFrame.Angles(0, math.pi, 0))

					--VictimCombat.Ragdoll:Toggle(true, 1.5)
					VictimCombat:Unstun()

					local VelocityObject = self:VelocityOn(VictimCombat)
					
					if VelocityObject then
						VelocityObject.Settings.RemoveTime = 0.1
						VelocityObject.Settings.Velocity = self.LuaCharacter.RootPart.CFrame.LookVector * 7.5 + Vector3.yAxis * 60
						VelocityObject:Fire()
					end
			
					local EndAnimation : RBXScriptConnection; EndAnimation = self.Combat.OnStateChanged:Connect(function(State : any, Value : boolean)
						if Value and (State == "Attacking" or State == "M1ing") then
							self.Animations.Hit:Stop()
						end
					end)

					self.Animations.Hit.Stopped:Once(function()
						if EndAnimation.Connected then
							EndAnimation:Disconnect()
						end
					end)

					self:Close()
				end
			end))
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(25)
		
		if GiveSpeedOnCancel then
			self.Combat:TimesSpeed(10)
		end
		
		self.Combat:StackState("Attacking", false)
	end)
	
	self:FireReliableVFX("Gojo/Beatdown", "Windup", self.LuaCharacter.RootPart)

	self.Thread.Job:Task(self.Animations.Start:GetMarkerReachedSignal("hit"):Once(function()
		Hitbox:BeginCast(0.05)
		
		Hitbox.Events.OnCastEnded:Once(function()
			if Blocked then
				self.Animations.Start:AdjustSpeed(0.9)
			end
		end)
	end))

	Hitbox.Events.OnCastEnded:Wait()
	
	task.wait(0.1)
	
	if not self.Hit and not Blocked then
		GiveSpeedOnCancel = false
		self.Combat:TimesSpeed(10)
	end

	task.wait(Blocked and 0.65 or 0.4)

	if not self.Hit then
		--if Blocked then
		--	self.Combat:TimesSpeed(10)
		--end
		
		self:Close()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	
	self.UseTwicePart = false
	self.TriedTwicePart = false
	self.OnTriedTwicePart = self.Job:Task(EventService.new())
	
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack