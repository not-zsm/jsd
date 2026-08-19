local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
	self.Combat:DivideSpeed(10)
	
	self:FireVFX("Accelerator/Bio Electric Burst", "Startup", self.LuaCharacter.RootPart)

	self.Hit = false
	
	local Force = (Vector3.new(1, 0, 1) * 80000)
	
	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 1.05, -2)
	Hitbox.Params.Size = Vector3.new(6, 10.5, 8)
	Hitbox.Params.MaxTargets = 1
	Hitbox.Params.DestroyOnEndCast = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			YDifferenceValue = -2
		})

		if Validated then
			self.Hit = true

			self.Animations.Windup:Stop() self.Animations.Hit:Play()
			VictimCombat.Animations.GrabVictims.BioElecticBurst:Play()
			
			local WasRagdolled = VictimCombat:GetState("Ragdolled")

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -3.5) * CFrame.Angles(0, math.pi, 0))
			local Ended = false
			
			self.Thread.OnClosed:Connect(function()
				if not Ended then
					GrabObject.Destroy(0)
					VictimCombat:Unstun()

					VictimCombat.Animations.GrabVictims.BioElecticBurst:Stop()
				end
			end)

			local function Hit(Index : number)
				self:FireReliableVFX("Accelerator/Bio Electric Burst", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.Model, Index)
				
				if Index ~= 4 then
					local VelocityObject = self.Combat:Velocity()
					VelocityObject.Settings.Duration = 0.5
					VelocityObject.Settings.RemoveTime = 0.4
					VelocityObject.Settings.MaxForce = Vector3.one * 80000
					VelocityObject.Settings.Controllable = true
					VelocityObject.Settings.Z = Index == 1 and 90 or 75
					VelocityObject:Fire()

					self.Thread.Job:Task(VelocityObject)
				end
				
				local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -3), Vector3.new(9, 6, 10))

				AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
					local NewVictimLuaCharacter = NewVictimLuaPlayer.Character
					local NewVictimCombat = NewVictimLuaCharacter.Combat

					local Validated = self:Afflict(NewVictimLuaPlayer, {
						BreakBlock = (Index == 4),
						Damage = 2,
						YDifferenceValue = 0
					})

					if Validated then
						if Index == 4 then
							self.Combat:TSBPushVictim(NewVictimLuaPlayer, {
								DontBeginAoeHitbox = true,
								LandedRollVelocityZ = 95,
								LandedRollDuration = 0.825
							})
						else
							NewVictimCombat:Stun(Index == 3 and 1.5 or 0.5)
							NewVictimCombat:PlayRandomHitReaction(3)
						end

						self:FireVFX("Accelerator/Bio Electric Burst", "HitOutsider", NewVictimLuaCharacter.Model)
					end
				end)

				AOEHitbox:BeginCast(0.05)
			end

			Hit(1)

			self:Afflict(VictimLuaPlayer, {
				ExcludeAttempts = true,
				Damage = {
					DontKill = true,
					Amount = 2
				}
			})

			for Index = 1, 2 do
				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("swing" .. Index):Once(function()
					self:FireVFX("Accelerator/Bio Electric Burst", "Swing", self.LuaCharacter.RootPart, Index)
				end))
			end

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("hit"):Once(function()
				Hit(2)

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {
						DontKill = true,
						Amount = 2
					}
				})
			end))

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("grab"):Once(function()
				Hit(3)

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {
						DontKill = true,
						Amount = 2
					}
				})
			end))

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("shock"):Once(function()
				self:FireReliableVFX("Accelerator/Bio Electric Burst", "Shock", self.LuaCharacter.RightArm, VictimLuaCharacter.Model)

				for Index = 1, 15 do
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = {
							DontKill = true,
							Amount = (2 / 15)
						}
					})

					task.wait(0.01)
				end
			end))

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("explosion"):Once(function()
				VictimCombat.Animations.GrabVictims.BioElecticBurst:Stop(0)
				
				local Finisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= 10)

				if Finisher then
					VictimCombat:StackState("HitboxImmunity", true)
					self.Combat:StackState("HitboxImmunity", true)
					
					GrabObject.SetOffset(CFrame.new(0, 0, -0.2))
					
					self.Animations.Hit:Stop(0) self.Animations.Finisher:Play(0)
					VictimCombat.Animations.GrabVictims.BioElecticBurstFinisher:Play()
					
					VictimLuaCharacter:StopRespawnTimer()
					
					self.Thread.OnClosed:Connect(function()
						VictimLuaCharacter:RestartRespawnTimer()
						
						VictimCombat:StackState("HitboxImmunity", false)
						self.Combat:StackState("HitboxImmunity", false)
						
						self:FireReliableVFX("Accelerator/Bio Electric Burst", "ScreenFXEnd", self.LuaCharacter.RootPart, VictimLuaCharacter.Model)
						
						VictimCombat.Animations.GrabVictims.BioElecticBurstFinisher:Stop()
					end)
					
					self:FireReliableVFX("Accelerator/Bio Electric Burst", "Start", self.LuaCharacter.RootPart)
					self:FireReliableVFX("Accelerator/Vector Punch", "Charge", self.LuaCharacter.RightArm)
					
					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("1"):Once(function()
						self:FireReliableVFX("Accelerator/Bio Electric Burst", "FinisherExplosion", self.LuaCharacter.RootPart)
						self:FireReliableVFX("Accelerator/Vector Punch", "Uncharge", self.LuaCharacter.RightArm)
					end))
					
					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("2"):Once(function()
						self:FireReliableVFX("Accelerator/Bio Electric Burst", "FinisherRipping", self.LuaCharacter.RootPart, VictimLuaCharacter.Model)
					end))
					
					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("3false"):Once(function()
						self:FireReliableVFX("Accelerator/Bio Electric Burst", "FinisherRip", self.LuaCharacter.RootPart, VictimLuaCharacter.Model)
						
						GrabObject.Destroy()
						VictimCombat:Unstun()

						VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -3.5) * CFrame.Angles(0, math.pi, 0))
						
						self:Afflict(VictimLuaPlayer, {
							FinisherKill = true,
							ExcludeAttempts = true,
							Velocity = {Vector3.yAxis * -15, 0.1},
						}) 
						
						task.wait(0.5)
						
						self:Close()
					end))
				else
					VictimCombat.Animations.ShakeOoaoa:Play(0.1, 0.05, 1.75)
					self:FireVFX("Global/Tasered", "Yeowch", VictimLuaCharacter.RootPart)

					task.delay(2, function()
						VictimCombat.Animations.ShakeOoaoa:Stop()
					end)
					
					Ended = true
					Hit(4); GrabObject.Destroy()
					
					if WasRagdolled then
						VictimCombat:StackState("ForceDashPush", true, 1.25)
						
						self.Combat:TSBPushVictim(VictimLuaPlayer, {
							LookVectorInsteadOfDifference = true,
							DontBeginAoeHitbox = true,
							LandedRollVelocityZ = 150,
							LandedRollDuration = 0.785
						})
						
						VictimCombat:StackState("EvasiveState", true)

						task.delay(0.785 + math.clamp(VictimLuaPlayer:GetPing(), 0, 1), function()
							VictimCombat:StackState("EvasiveState", false)
						end)
					else
						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							Damage = 5,
							Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 40 + Vector3.yAxis * 50, 0.1},
							Ragdoll = 2
						})
					end
					
					VictimCombat:Unstun()
					self:Close()
				end
			end))
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(19)
		
		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Once(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 0.6
		VelocityObject.Settings.RemoveTime = 0.6
		VelocityObject.Settings.MaxForce = Force
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 60
		VelocityObject:Fire()

		self.Thread.Job:Task(VelocityObject)
		
		Hitbox:BeginCast(0.2)
		
		Hitbox.Events.OnCastEnded:Once(function()
			if not self.Hit then
				self.Animations.Windup:AdjustSpeed(0.5)
			end
		end)
	end))

	task.wait(0.35 / self.AnimationSettings.Speed)

	local VelocityObject = self.Combat:Velocity()
	VelocityObject.Settings.Duration = 0.9
	VelocityObject.Settings.RemoveTime = 0.9
	VelocityObject.Settings.MaxForce = Force
	VelocityObject.Settings.Controllable = true
	VelocityObject.Settings.Z = 80
	VelocityObject:Fire()

	self.Thread.Job:Task(VelocityObject)

	task.wait(1.5 / self.AnimationSettings.Speed)
	
	if not self.Hit then
		self:Close()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	
	self.AnimationSettings = {
		FadeTime = 0.05,
		Weight = 1,
		Speed = 1.25
	}
	
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack