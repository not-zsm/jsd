local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(3)

	self.Hit = false
	
	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -5)
	Hitbox.Params.Size = Vector3.new(4, 5, 5)
	Hitbox.Params.DestroyOnEndCast = false
	Hitbox.Params.MaxTargets = 1

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			YDifferenceValue = -2
		})

		if Validated then
			self.Hit = true

			local CurrentVictim = VictimLuaCharacter.Model
			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RightArm, CFrame.new(0, -1, 0) * CFrame.Angles(0, math.pi, 0))
			local Ended = false
			
			self.Combat:DivideSpeed(4)

			self.Thread.OnClosed:Connect(function()
				self.Combat:TimesSpeed(4)
				
				if not Ended then
					VictimCombat.Animations.GrabVictims.LethalWhirlwindStream:Stop()
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end
			end)
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("slam"):Connect(function()
				if CurrentVictim == VictimLuaCharacter.Model then
					self:FireVFX("Garou/Lethal Whirlwind Stream", "Slam", VictimLuaCharacter.Torso)
					GrabObject.SetOffset(CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(45), math.pi, 0))
					
					local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -1), Vector3.one * 7)

					AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
						local NewVictimLuaCharacter = NewVictimLuaPlayer.Character
						local NewVictimCombat = NewVictimLuaCharacter.Combat
						
						local Blocking = NewVictimCombat:GetState("Blocking")
						
						local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
							BreakBlock = true,
							Velocity = {Vector3.yAxis * 35, 0.1}
						})
						
						if not Blocking then
							self.Combat:DealDamage(VictimLuaPlayer, 2)
							self:Afflict(NewVictimLuaPlayer, {
								ExcludeAttempts = true;
								Ragdoll = 2.25;
							})
							--NewVictimCombat.Ragdoll:Toggle(true, 2.25)
						end
					end)
					
					AOEHitbox:BeginCast(0.05)
				end
			end))
			
			self.Thread.Job:Task(task.delay(1.35, function()
				if CurrentVictim == VictimLuaCharacter.Model then
					GrabObject.SetOffset(CFrame.new(0, -1, 0) * CFrame.Angles(0, math.pi, 0))
				end
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("run"):Once(function()
				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 1.1
				VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = 85
				VelocityObject:Fire()
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("finalslam"):Once(function()
				local Finisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= 10 and CurrentVictim == VictimLuaCharacter.Model)
				local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -1), Vector3.new(17, 8, 17))

				AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
					local NewVictimLuaCharacter = NewVictimLuaPlayer.Character
					local NewVictimCombat = NewVictimLuaCharacter.Combat

					local Blocking = NewVictimCombat:GetState("Blocking")

					local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
						BreakBlock = true,
						Velocity = {Vector3.yAxis * 75, 0.1}
					})

					if not Blocking then
						self.Combat:DealDamage(VictimLuaPlayer, 5)
						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true;
							Ragdoll = 2.25;
						})
						--NewVictimCombat.Ragdoll:Toggle(true, 2.25)
					end
				end)
				
				AOEHitbox:BeginCast(0.05)
				
				self:FireVFX("Garou/Lethal Whirlwind Stream", "FinalSlam", VictimLuaCharacter.Torso)
				VictimCombat.Animations.GrabVictims.LethalWhirlwindStream:Stop(0)
				
				if Finisher then
					GrabObject.SetBound(self.LuaCharacter.RootPart)
					GrabObject.SetOffset(CFrame.new(0, 0, -4))

					self.Animations.Hit:Stop(); self.Animations.Finisher:Play()
					VictimCombat.Animations.GrabVictims.LethalWhirlwindStreamFinisher:Play()
					
					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("bodyslam"):Once(function()
						Ended = true
						GrabObject.Destroy(0)
						
						local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -1), Vector3.new(21, 12, 21))

						AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
							local NewVictimLuaCharacter = NewVictimLuaPlayer.Character
							local NewVictimCombat = NewVictimLuaCharacter.Combat

							local Blocking = NewVictimCombat:GetState("Blocking")

							local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
								BreakBlock = true,
								Velocity = {Vector3.yAxis * 100, 0.1}
							})

							if not Blocking then
								self.Combat:DealDamage(VictimLuaPlayer, 8)
								self:Afflict(VictimLuaPlayer, {
									ExcludeAttempts = true;
									Ragdoll = 2.25;
								})
								--NewVictimCombat.Ragdoll:Toggle(true, 2.25)
							end
						end)

						AOEHitbox:BeginCast(0.05)
						
						self:FireVFX("Garou/Lethal Whirlwind Stream", "BodySlam", VictimLuaCharacter.Torso)
						
						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							FinisherKill = true
						})
						
						self:Close()
					end))
				else
					GrabObject.Destroy(0)

					if CurrentVictim == VictimLuaCharacter.Model then
						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							Damage = 10,
							Ragdoll = 2.25;
						})

						VictimLuaCharacter:SetCollisionGroup("NoPlayerCollision")
						VictimCombat.Ragdoll:SetCollisionGroupOfColliders("NoPlayerCollision")

						task.delay(0.3, function()
							if not VictimCombat:GetState("Grabbed") then
								VictimLuaCharacter:SetCollisionGroup("Player")
							end

							VictimCombat.Ragdoll:SetCollisionGroupOfColliders("Default")
						end)

						VictimLuaCharacter.RootPart.CFrame = self.LuaCharacter.RootPart.CFrame * CFrame.new(0, -1, -2) * CFrame.Angles(-math.pi / 2, math.pi, -math.pi / 2)
						--VictimCombat.Ragdoll:Toggle(true, 2.25)
						
						local VelocityObject = self:VelocityOn(VictimCombat)
						VelocityObject.Settings.RemoveTime = 0.05
						VelocityObject.Settings.MaxForce = Vector3.one * 80000
						VelocityObject.Settings.Velocity = Vector3.yAxis * 75
						VelocityObject:Fire()

						VictimCombat:Unstun()
					end

					Ended = true
					self:Close()
				end
			end))
			
			self.Animations.Windup:Stop(); self.Animations.Hit:Play()
			VictimCombat.Animations.GrabVictims.LethalWhirlwindStream:Play()
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(17)

		self.Combat:StackState("Attacking", false)
	end)

	local Connection = self.Thread.OnCancelled:Connect(function()
		self.Combat:TimesSpeed(3)
	end)
	
	self:FireVFX("Garou/Flowing Water", "WaterStream", self.LuaCharacter.RightArm, 0.75)
	self.Animations.Windup:GetMarkerReachedSignal("swing"):Wait()

	Connection:Disconnect()
	
	local VelocityObject = self.Combat:Velocity()
	VelocityObject.Settings.RemoveTime = 0.1
	VelocityObject.Settings.MaxForce = Vector3.one * 80000
	VelocityObject.Settings.Velocity = self.Combat:GetSimulatedRoot().CFrame.LookVector * 35
	VelocityObject:Fire()
	
	self.Thread.Job:Task(VelocityObject)
	
	self.Combat:TimesSpeed(3)
	
	self.Animations.Windup:GetMarkerReachedSignal("hit"):Wait()
	Hitbox:BeginCast(0.15)

	task.wait(0.4)

	if not self.Hit then
		self:Close()
	end
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