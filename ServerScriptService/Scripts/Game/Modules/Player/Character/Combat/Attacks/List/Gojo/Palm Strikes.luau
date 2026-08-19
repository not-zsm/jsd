local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

----------------------------------------------------------------------------------

local Attack = {}
Attack.__index = Attack

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self.Hit = false

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
			YDifferenceValue = -2
		})

		Blocked = (Type == "Blocked")

		if Validated then
			self.Hit = true

			self.Animations.Windup:Stop() self.Animations.Hit:Play()
			VictimCombat.Animations.GrabVictims.PalmStrikesVictim:Play()

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.Angles(0, math.pi, 0))
			local CurrentVictim = VictimLuaCharacter.Model

			local HitCount = 0
			local Ended = false

			self.Thread.OnClosed:Connect(function()
				if Ended then return end

				GrabObject.Destroy(0)
				VictimCombat:Unstun()
				VictimCombat.Animations.GrabVictims.PalmStrikesVictim:Stop()
			end)

			self:FireReliableVFX("Gojo/Palm Strikes", "Land", self.LuaCharacter.RootPart)

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("hit"):Connect(function()
				HitCount += 1

				if CurrentVictim == VictimLuaCharacter.Model then
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = {
							DontKill = true,
							Amount = 1.5,--1
						}
					})

					if (VictimLuaCharacter.Humanoid.Health <= 8) then
						self:FireReliableVFX("Gojo/Palm Strikes", "FinisherHit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, HitCount)
					else
						self:FireReliableVFX("Gojo/Palm Strikes", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, HitCount)
					end

					local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -2), Vector3.one * 8)

					AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
						local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
							Damage = 1,
							Stun = 0.6
						})

						if Validated then
							NewVictimLuaPlayer.Character.Combat:PlayRandomHitReaction()
						end
					end)

					AOEHitbox:BeginCast(0.05)
				end
			end))

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("finalhit"):Once(function()
				Ended = true

				local Endlag = 0.25
				GrabObject.Destroy(Endlag)
			
				if CurrentVictim == VictimLuaCharacter.Model then
					VictimCombat.Animations.GrabVictims.PalmStrikesVictim:Stop(0)

					VictimLuaCharacter.RootPart:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0))
					VictimLuaCharacter.RootPart.AssemblyLinearVelocity = Vector3.zero
					VictimLuaCharacter.RootPart.AssemblyAngularVelocity = Vector3.zero

					local Finisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= 8)
					local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -2), Vector3.one * 8)

					AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
						self.Combat:Afflict(NewVictimLuaPlayer, {
							BreakBlock = true,
							Damage = 3,
							Ragdoll = 2,
							Velocity = {self.LuaCharacter.RootPart.CFrame.RightVector * -27.5 + Vector3.yAxis * 50, 0.1}
						})
					end)

					AOEHitbox:BeginCast(0.05)

					if Finisher then
						local StopAutoRotate = self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
						local CF = self.LuaCharacter.RootPart.CFrame

						self.Combat:StackState("HitboxImmunity", true)
						VictimCombat:StackState("HitboxImmunity", true)
						VictimCombat:StackState("CannotDash", true)
						VictimCombat:TrueStun()
						
						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							Velocity = {self.LuaCharacter.RootPart.CFrame.RightVector * -85 + Vector3.yAxis * 125, 0.1},
							Ragdoll = 3;
						})
						
						VictimLuaCharacter:StopRespawnTimer()

						self.Thread.OnClosed:Connect(function()
							VictimLuaCharacter:RestartRespawnTimer()
							
							VictimCombat:StackState("CannotDash", false)
							
							self.Combat:StackState("HitboxImmunity", false)
							VictimCombat:StackState("HitboxImmunity", false)

							VictimCombat:Unstun()
						end)

						self:FireReliableVFX("Gojo/Palm Strikes", "FinisherHit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, 4)
						
						--VictimCombat.Ragdoll:Toggle(true, 3)

						self.Thread.Job:Task(task.delay(0.1, function()
							VictimLuaCharacter:SetCollisionGroup("NoPlayerCollision")
							VictimCombat.Ragdoll:SetCollisionGroupOfColliders("NoPlayerCollision")

							local Raycast = workspace:Raycast(CF.Position, -self.LuaCharacter.RootPart.CFrame.RightVector * 70, Utility.VisualParams)
							local UpCFrame = CF * CFrame.new(-70, 37.5, 5)

							if Raycast and Raycast.Instance.CanCollide then
								UpCFrame = CF * CFrame.new(-(Raycast.Distance - 4), 37.5, 5)
							end

							local UpPosition = UpCFrame.Position

							local AlignPosition = Instance.new("AlignPosition")
							AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
							AlignPosition.Attachment0 = self.LuaCharacter.RootAttachment
							AlignPosition.MaxForce = 200000
							AlignPosition.Responsiveness = 200
							AlignPosition.RigidityEnabled = true
							AlignPosition.Position = UpPosition
							AlignPosition.Parent = self.LuaCharacter.RootPart

							self.LuaCharacter.Model:PivotTo(UpCFrame)
							self:FireReliableVFX("Gojo/Palm Strikes", "ChargeRed", self.LuaCharacter.RootPart)
							
							local RunHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -8), Vector3.new(8, 8, 12))

							RunHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
								self.Combat:Afflict(NewVictimLuaPlayer, {
									DontCheckBlock = true,
									TriggerActiveCounterOverOrEqualLevel = -1,
									Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 35 + Vector3.yAxis * 25, 0.1},
									Damage = 1,
									Ragdoll = 2,
								})

								task.delay(0.1, function()
									RunHitbox:RemoveHumanoid(NewVictimLuaPlayer.Character.Humanoid)
								end)
							end)

							local GrabObject = nil

							self.Thread.OnClosed:Connect(function()
								AlignPosition:Destroy()

								RunHitbox:EndCast()
								RunHitbox:Destroy()
								
								if not VictimCombat:GetState("Grabbed") then
									VictimLuaCharacter:SetCollisionGroup("Player")
								end
								
								self:FireReliableVFXToSelf("Gojo/Palm Strikes", "Fix")
								
								self.LuaCharacter:Anchor(false)
								VictimLuaCharacter:Anchor(false)
								
								VictimCombat.Ragdoll:SetCollisionGroupOfColliders("Default")

								if GrabObject then
									GrabObject.Destroy(0)
									VictimCombat:Unstun()
								end
							end)

							self.Animations.Hit:Stop(0)
							self.Animations.Finisher:Play()

							self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("shoot"):Connect(function()
								AlignPosition:Destroy()

								self:FireReliableVFX("Gojo/Palm Strikes", "ShootRed", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
								VictimCombat.Ragdoll:ForceToggleOff()
								
								self.LuaCharacter:Anchor(true)
								VictimLuaCharacter:Anchor(true)

								VictimCombat.Animations.GrabVictims.PalmStrikesFinisher:Play()
								VictimCombat.Animations.GrabVictims.PalmStrikesFinisher.TimePosition = (58/60) -- right when he gets shot
								
								self.Thread.OnClosed:Connect(function()
									VictimCombat.Animations.GrabVictims.PalmStrikesFinisher:Stop()
								end)
								
								local Offset = CFrame.Angles(0, math.pi, 0)
								VictimLuaCharacter.Model:PivotTo(UpCFrame * CFrame.new(0, -3, -10) * Offset)
								
								local EndCF = UpCFrame * CFrame.new(0, -37.5, -10) * Offset

								TweenService:Create(VictimLuaCharacter.RootPart, TweenInfo.new(0.3, Enum.EasingStyle.Linear),
									{CFrame = EndCF}
								):Play()
								
								TweenService:Create(self.LuaCharacter.RootPart, TweenInfo.new(0.65, Enum.EasingStyle.Linear),
									{CFrame = UpCFrame * CFrame.new(0, -35, -3)}
								):Play()
							end))

							self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("slam"):Connect(function()
								self.LuaCharacter:Anchor(false)
								VictimLuaCharacter:Anchor(false)
								
								if StopAutoRotate then
									StopAutoRotate:Destroy()
								end
							
								GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -8) * CFrame.Angles(0, math.pi, 0))
								
								self:FireReliableVFX("Gojo/Palm Strikes", "FinisherSlide", self.LuaCharacter.RootPart, VictimLuaCharacter.Torso)
								self:FireReliableVFX("Gojo/Palm Strikes", "Slam", self.LuaCharacter.RootPart)
								
								self.Thread.OnClosed:Connect(function()
									self:FireReliableVFX("Gojo/Palm Strikes", "FinisherSlideEnd", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
								end)
								
								RunHitbox:BeginCast()

								local VelocityObject = self.Combat:Velocity()
								VelocityObject.Settings.Duration = 2.5
								VelocityObject.Settings.RemoveTime = 2.5
								VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
								VelocityObject.Settings.Controllable = true
								VelocityObject.Settings.Z = 42.5
								VelocityObject:Fire()

								self.Thread.Job:Task(VelocityObject)
								
								self.Thread.Job:Task(self.Combat.Hitbox:ClientSidedDestructionLoop(CFrame.new(0, 0, -4.5), Vector3.new(5, 6, 7), 2))
							end))

							self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("throw"):Connect(function()
								GrabObject.Destroy(0)
								VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -5) * CFrame.Angles(0, math.pi, 0))

								self:Afflict(VictimLuaPlayer, {
									FinisherKill = true,
									ExcludeAttempts = true,
									Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 65 + Vector3.yAxis * 25, 0.1},
								})

								self:FireReliableVFX("Gojo/Palm Strikes", "FinisherSlideEnd", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
								VictimCombat.Ragdoll:Toggle(true)
								
								RunHitbox:EndCast()
								RunHitbox:Destroy()

								task.wait(0.5)

								self:Close()
							end))

						end))
					else
						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							Damage = 5.5,
							Ragdoll = 2;
							Velocity = {-self.Combat:GetSimulatedRoot().CFrame.RightVector * 65 + Vector3.yAxis * 85, 0.1}
						})
						
						self:FireReliableVFX("Gojo/Palm Strikes", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, 4)

						VictimCombat:StackState("BackdashIFrames", true, 1)
						--VictimCombat.Ragdoll:Toggle(true, 2)
						
						self.Combat:VictimImpactGround(VictimLuaPlayer)
						
						task.wait(Endlag)
						
						self:Close()
					end
				end
				
				VictimCombat:Unstun()
			end))
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(19)

		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Once(function()
		Hitbox:BeginCast(0.05)

		Hitbox.Events.OnCastEnded:Once(function()
			if Blocked then
				self.Animations.Windup:AdjustSpeed(0.7)
			end
		end)
	end))

	self:FireReliableVFX("Gojo/Palm Strikes", "Start", self.LuaCharacter.RootPart)

	Hitbox.Events.OnCastEnded:Wait()

	task.wait(Blocked and 0.75 or 0.5)

	if not self.Hit then
		self:Close()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true

	self.AnimationSettings = {
		FadeTime = 0.1,
		Weight = 1,
		Speed = 1.4
	}

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack