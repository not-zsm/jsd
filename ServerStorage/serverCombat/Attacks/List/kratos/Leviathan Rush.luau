local replicatedStorage = game:GetService("ReplicatedStorage")

local ServerStorage = game:GetService("ServerStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Beatdown()
	self.BeatdownHit = false
	self.FinisherActivated = false

	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	local Weapons = self.Combat.Attacks.Weapons

	if Weapons then
		Weapons:SetCurrent("Fists")
	end

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -4)
	Hitbox.Params.Size = Vector3.new(7, 6, 7)
	Hitbox.Params.MaxTargets = 1
	Hitbox.Params.DestroyOnEndCast = false

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(self.Cooldown)

		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		self.BeatdownHit = self:Afflict(VictimLuaPlayer, {
			Damage = {Amount = 1.5, DontKill = true}
		})

		if self.BeatdownHit then
			local VictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(replicatedStorage.animations.Attacks.kratos["Leviathan Rush"].BeatdownHitVictim)
			local FinisherVictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(replicatedStorage.animations.Attacks.kratos["Leviathan Rush"].BeatdownFinisherVictim)

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0))

			local Thrown = false
			local Rotation = nil

			self.Thread.OnClosed:Connect(function()
				if VictimAnimation and VictimAnimation.IsPlaying then
					VictimAnimation:Stop(0)
				end
				
				if FinisherVictimAnimation and FinisherVictimAnimation.IsPlaying then
					FinisherVictimAnimation:Stop()
				end

				if not Thrown then
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end
			end)

			local function OnHit()
				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 0.6
				VelocityObject.Settings.RemoveTime = 0.55
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = 17.5
				VelocityObject:Fire()
			end

			self.Thread.Job:Task(self.Animations.BeatdownHit:GetMarkerReachedSignal("hit"):Connect(function()
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {Amount = 1.5, DontKill = true},
				})

				OnHit()
			end))

			self.Thread.Job:Task(self.Animations.BeatdownHit:GetMarkerReachedSignal("uppercut"):Connect(function()
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {Amount = 3, DontKill = true},
				})

				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 1
				VelocityObject.Settings.RemoveTime = 0.5
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = -7.5
				VelocityObject:Fire()

				if self:IsFinisherEnabled() and VictimLuaCharacter.Humanoid.Health <= 12.5 then
					self.FinisherActivated = true

					self.Combat:StackState("HitboxImmunity", true)
					VictimCombat:StackState("HitboxImmunity", true)

					self.Combat:HideUI(true)
					VictimCombat:HideUI(true)

					self.Thread.OnClosed:Connect(function()
						self.Combat:HideUI(false)
						VictimCombat:HideUI(false)

						self.Combat:StackState("HitboxImmunity", false)
						VictimCombat:StackState("HitboxImmunity", false)
					end)

					GrabObject.SetOffset(CFrame.identity)

					local DamageValues = {
						["firstslam"] = 1.5,
						["slam"] = 1.5,
						["default"] = 2.5,
						["morepower"] = 4
					}

					self.Thread.Job:Task(self.Animations.BeatdownFinisher:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
						if (Parameter == "final") then
							VictimLuaCharacter:SetCollisionGroup("NoPlayerCollision")
							VictimCombat.Ragdoll:SetCollisionGroupOfColliders("NoPlayerCollision")

							FinisherVictimAnimation:Stop(0)
							VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(-0.5, 0, -0.5) * CFrame.Angles(math.rad(90), math.pi, 0))
							GrabObject.Destroy(0)

							self:Afflict(VictimLuaPlayer, {
								ExcludeAttempts = true,
								FinisherKill = true
							})

							VictimCombat:Unstun()
						else
							self:Afflict(VictimLuaPlayer, {
								ExcludeAttempts = true,
								Damage = {Amount = DamageValues[Parameter] or 3, DontKill = true}
							})
						end
					end))

					self.Thread.Job:Task(self.Animations.BeatdownFinisher:GetMarkerReachedSignal("camera"):Connect(function()
						self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
					end))

					self.Animations.BeatdownHit:Stop()
					self.Animations.BeatdownFinisher:Play()

					VictimAnimation:Stop(0)
					FinisherVictimAnimation:Play(0)

					self:FireReliableVFX("Kratos/Beatdown", "OnFinisher", self.LuaCharacter.Model, VictimLuaCharacter.Model)

					self.Thread.Job:Task(self.Animations.BeatdownFinisher.Ended:Connect(function()
						self:Close()
					end))
				else
					Rotation = self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
					GrabObject.SetBound(nil)

					task.wait(0.45)

					local VelocityObject = self.Combat:Velocity()
					VelocityObject.Settings.RemoveTime = 0.23
					VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
					VelocityObject.Settings.Velocity = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 17.5
					VelocityObject:Fire()
				end
			end))

			self.Thread.Job:Task(self.Animations.BeatdownHit:GetMarkerReachedSignal("grab"):Connect(function()
				GrabObject.SetBound(self.LuaCharacter.RootPart)

				if Rotation then
					Rotation:Destroy()
				end

				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 0.72
				VelocityObject.Settings.RemoveTime = 0.7
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = 12.5
				VelocityObject:Fire()

				task.wait(0.55)

				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 0.8
				VelocityObject.Settings.RemoveTime = 0.6
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = 40
				VelocityObject:Fire()
			end))

			self.Thread.Job:Task(self.Animations.BeatdownHit:GetMarkerReachedSignal("throw"):Connect(function()
				Thrown = true

				VictimAnimation:Stop(0)
				VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -4.5) * CFrame.Angles(0, math.pi, 0))
				GrabObject.Destroy(0)

				self:Afflict(VictimLuaPlayer, {
					Ragdoll = 2.2,
					Velocity = {self.Combat:GetSimulatedRoot().CFrame.LookVector * 55 + Vector3.yAxis * 25, 0.1},
					FinisherKill = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= 1)
				})

				VictimCombat:Unstun()

				task.wait(0.4)

				self:Close()
			end))

			self.Animations.BeatdownWindup:Stop(0)
			self.Animations.BeatdownHit:Play(0)
			VictimAnimation:Play(0)

			self:FireReliableVFX("Kratos/Beatdown", "OnHit", self.LuaCharacter.Model, VictimLuaCharacter.Model)
			self.Thread.CancelJob:Task(self:CreateMoveSFX("kratos", "Beatdown", "HitSFX"))

			OnHit()
		end
	end)

	self.Thread.Job:Task(self.Animations.BeatdownWindup:GetMarkerReachedSignal("hit"):Connect(function()
		Hitbox:BeginCast(0.075)
	end))

	self.Animations.BeatdownWindup:Play(0.2)
	self:FireReliableVFX("Kratos/Beatdown", "OnStart", self.LuaCharacter.Model)
	self.Thread.CancelJob:Task(self:CreateMoveSFX("kratos", "Beatdown", "SFX"))

	task.wait(1)

	if not self.BeatdownHit then
		self:Close()
	end
end

function Attack:Rush()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self.FinisherActivated = false

	local Weapons = self.Combat.Attacks.Weapons

	if Weapons then
		Weapons:SetCurrent("Axe")
		Weapons:ToggleIceAxe(true)
	end

	self.Thread.OnClosed:Connect(function()
		if Weapons then
			Weapons:ToggleIceAxe(false)
		end

		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	if (self.VariantsEnabled and self.SlamVariant) or self.ForceSpecialVariant then
		self.SlamVariant = false
		self.Animations.Slam1:Play()
		
		self.Thread.CancelJob:Task(self:CreateMoveSFX("kratos", "Leviathan Rush", "Slam"))

		local Hitbox = self:CreateHitbox(true);
		Hitbox.Params.Offset = CFrame.new(-0.05, 0, -5.995)
		Hitbox.Params.Size = 8
		Hitbox.Params.DestroyOnEndCast = false
		
		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Validated = self:Afflict(VictimLuaPlayer, {
				DontRestartRespawnTimer = true,
				BreakBlock = true
			})

			if Validated then
				local Finisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= 10)

				if Finisher and not self.FinisherActivated then
					self.FinisherActivated = true

					local Ended = false

					local FinisherVictimAnimation : AnimationTrack = VictimLuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Attacks.kratos["Leviathan Rush"].SlamFinisherVictim)

					self.Animations.Slam1:Stop()
					self.Animations.SlamFinisher:Play()
					FinisherVictimAnimation:Play()

					self.Thread.CancelJob:Task(
						self:CreateMoveSFX("kratos", "Leviathan Slam Finisher")
					)

					VictimLuaCharacter:StopRespawnTimer()

					local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.identity)

					self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

					self.Thread.OnClosed:Connect(function()
						VictimLuaCharacter:RestartRespawnTimer()
						
						if not Ended then
							FinisherVictimAnimation:Stop(0)
							GrabObject.Destroy(0)
							VictimCombat:Unstun()
						end
					end)

					self.Thread.Job:Task(self.Animations.SlamFinisher:GetMarkerReachedSignal("slam1"):Connect(function()	
						Ended = true

						FinisherVictimAnimation:Stop(0)
						GrabObject.Destroy(0)

						VictimLuaCharacter.RootPart.CFrame = self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0.1, -8) * CFrame.Angles(-math.rad(60), math.pi, 0)

						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							Velocity = {Vector3.yAxis * -75, 0.1},
							FinisherKill = true
						})

						VictimCombat:Unstun()

						local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -6), Vector3.new(8,8,8))
						self.Combat.Hitbox:Destruction(CFrame.new(0, 0, -6), Vector3.new(8,8,8), 2) 

						AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
							self.Combat:Afflict(NewVictimLuaPlayer, {
								TriggerActiveCounterOverOrEqualLevel = -1,
								BreakBlock = true,
								Damage = 5,
								Ragdoll = 3,
								Velocity = {Vector3.yAxis * 65, 0.1}
							})
						end)

						AOEHitbox:BeginCast(0.05)

						task.wait(0.5)

						self:Close()
					end))

					self:FireReliableVFX("Kratos/Leviathan Slam Finisher", "OnStart", self.LuaCharacter.Model, VictimLuaCharacter.Model)
					
				elseif not Finisher then
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = 5,
						Ragdoll = 1.5;
					})

					local VelocityObject = self:VelocityOn(VictimCombat)
					VelocityObject.Settings.RemoveTime = 0.2
					VelocityObject.Settings.Velocity = self.LuaCharacter.RootPart.CFrame.LookVector * 40 + Vector3.yAxis * 55
					VelocityObject:Fire()

					--VictimCombat.Ragdoll:Toggle(true, 1.5)
				end
			end
		end)

		if not self.FinisherActivated then
			self.Thread.Job:Task(self.Animations.Slam1:GetMarkerReachedSignal("smoke"):Connect(function()
				self:FireReliableVFX("Kratos/Leviathan Rush", "Smoke", self.LuaCharacter.RootPart)
			end))

			self.Thread.Job:Task(self.Animations.Slam1:GetMarkerReachedSignal("slam"):Connect(function()
				self:FireReliableVFX("Kratos/Leviathan Rush", "Slam", self.LuaCharacter.RootPart)
				
				Hitbox:Detect()
				
				local Rnd = Random.new();
				
				self.Combat.Hitbox:CreateHavocReplicated({
					parameters = {
						origin = Hitbox:GetCFrame() * CFrame.new(0, 0, -1),
						shape = "Sphere", 
						radius = 7,
						block_size = 7,
					},
					debris = {
						scale = 0.9,
						radius = 10,
						velocity = function(part)
							return Rnd:NextUnitVector() * 25 + Vector3.yAxis * 35;
						end,
					},
				});
				
				self.Combat.Hitbox:SphereDestruction(Hitbox.Adornee.Position, Hitbox.Params.Size, 1)

				self.Animations.Slam1:AdjustSpeed(1.75)
			end))

			self.Thread.OnClosed:Connect(function()
				self.Combat:ChangeAttackDisplay(self.Name, self.DisplayName, { FlashColor = Color3.fromRGB(49, 176, 255) })
				self:AddCooldown(self.Cooldown)
			end)

			task.wait(1.15)
		end
	else
		self.SlamVariant = false
		self.CurrentSlash = 0

		local Hitbox = self:CreateHitbox(false);
		Hitbox.Params.Offset = CFrame.new(0, 0, -2.5)
		Hitbox.Params.Size = Vector3.new(10, 8, 10)
		Hitbox.Params.DestroyOnEndCast = false

		local MoveBlocked = false

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Validated, Type = self:Afflict(VictimLuaPlayer, {
				YDifferenceValue = -2,
				DontRestartRespawnTimer = true,
				TrueStun = 1.5,
				Damage = 2,
				Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 25, 0.2}
			})

			MoveBlocked = (Type == "Blocked")

			if Validated then
				VictimCombat:StackState("ForceDashPush", true, 2)
				
				self:FireReliableVFX("Kratos/Leviathan Rush", "SlashHit", VictimLuaCharacter.RootPart, self.CurrentSlash)
				VictimCombat:PlayRandomHitReaction()
			end
		end)

		self.Thread.OnCancelled:Connect(function() -- when i add slams
			self:AddCooldown(self.Cooldown)
		end)

		local Animation : AnimationTrack = self.Animations["Slashes" .. math.random(1, 2)]
		Animation:Play()

		self.Thread.CancelJob:Task(self:CreateMoveSFX("kratos", "Leviathan Rush"))

		self.Thread.Job:Task(Animation:GetMarkerReachedSignal("slash"):Connect(function(Count : string)
			self.CurrentSlash = tonumber(Count)

			local VelocityObject = self.Combat:Velocity()
			VelocityObject.Settings.Duration = 0.65
			VelocityObject.Settings.RemoveTime = 0.65
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 50
			VelocityObject:Fire()

			self.Thread.Job:Task(VelocityObject)

			self:FireReliableVFX("Kratos/Leviathan Rush", "Slash", self.LuaCharacter.RootPart, self.CurrentSlash)
			Hitbox:BeginCast(0.1)
		end))

		Animation:GetMarkerReachedSignal("slash"):Wait()
		Animation:GetMarkerReachedSignal("slash"):Wait() -- fire!
		Animation:GetMarkerReachedSignal("slash"):Wait()

		self.Combat:ChangeAttackDisplay(self.Name, self.VariantText, {
			FlashColor = Color3.fromRGB(49, 176, 255)
		})

		if self.VariantsEnabled then
			self.SlamVariant = true
		end;
		
		Animation:AdjustSpeed(MoveBlocked and 1.05 or 1.5)
		task.wait(MoveBlocked and 0.8 or 0.35)

		local M1Attack, M1Matched = self.Combat:MatchAttack("M1", Enum.UserInputType.MouseButton1)

		if M1Matched then
			M1Attack.ResetTime = time() 
			M1Attack:AntiM1ResetTech()
		end
	end

	if self.FinisherActivated then
		return
	end

	self:Close()
end


function Attack:Activate()
	local Weapons = self.Combat.Attacks.Weapons

	if Weapons and Weapons.ThrownAxe or self.ForceVariant then
		self:Beatdown()
	else
		self:Rush()
	end
end


function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.TryToCancelMoves = true

	self.SlamVariant = false
	self.CurrentSlash = 0

	self.Cooldown = 19
	self.VariantText = "Leviathan Slam"

	do
		local function Do()
			local Weapons = self.Combat.Attacks.Weapons

			self.Job:Task(Weapons.OnAxeChanged:Connect(function()
				local NextText = (Weapons.ThrownAxe and "Beatdown" or (self.SlamVariant and self.VariantText or self.DisplayName))

				self.Combat:ChangeAttackDisplay(self.Name, NextText, {
					FlashColor = Color3.fromRGB(255, 255, 255)
				})
			end))
		end

		if (self.Combat.Attacks.Weapons == nil) then
			self.Job:Task(self.Combat.OnAttackChanged:Connect(function(NewAttack : ({} | string), Value)
				if Value and NewAttack.NameNoSpaces == "Weapons" then
					Do()
				end
			end))
		else
			Do()
		end
	end

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack