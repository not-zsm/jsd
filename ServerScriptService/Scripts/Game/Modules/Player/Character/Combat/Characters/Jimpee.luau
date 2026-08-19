local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

return {
	GitHubWhitelist = "Jimpee",
	RestrictSetCharacter = true,

	Attacks = {
		["RAGE"] = Enum.KeyCode.One,
		["Atomize"] = Enum.KeyCode.Two
	},
	
	Stats = {
		M1 = {
			Speed = 1.3,
			EndlagAfterSwing = 0.125,
		},
	},
	
	M1 = {
		CustomFunction = function(self)
			if (self.Count > 3 or time() - self.ResetTime >= self.ResetTimer) then
				self.Count = 0
			end

			self.Combat:StackState("M1ing", true)
			self:StopCurrentAnimation()

			self.Count += 1

			self.ResetTime = time()

			self.Hit = false
			self.Downslammed = false
			self.InWindup = true
			self.Condition = (self.Count > 3 and (if self.Combat.AirState == "" then nil else self.Combat.AirState) or nil)

			self.WallComboVictim = nil

			local Is_Normal_M1 = self.Count < 4

			local AnimationDirectory = self:GetAnimationDirectory()
			
			local Animation : AnimationTrack = (self.Condition ~= nil and AnimationDirectory[self.Condition] or AnimationDirectory[tostring(self.Count)])
			Animation:Play(0)
			
			self:FireReliableVFX("Jimpee/M1", "Start", self.LuaCharacter.Model, self.Count)

			local Hitbox = self:CreateHitbox()
			Hitbox.Params.DestroyOnEndCast = false

			if self.Condition == "Up" then
				Hitbox.Params.Offset = CFrame.new(0, 0, -2.65)
				Hitbox.Params.Size = Vector3.new(6, 10, 6.8)

			elseif self.Condition == "Down" then
				Hitbox.Params.Offset = CFrame.new(0, -3.5, -2.65)
				Hitbox.Params.Size = Vector3.new(5.35, 25, 6.8)
			else
				Hitbox.Params.Offset = CFrame.new(0, 0, -2.65) 
				Hitbox.Params.Size = Vector3.new(9, 9, 9)
			end

			local Damage = {
				[1] = 10,
				[2] = 10,
				[3] = 10,
				[4] = 100,
			}

			Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat

				local Validated = self:Afflict(VictimLuaPlayer, {
					DontBypassIFrames = {},
					DontCheckBlock = true,
					Damage = Damage[self.Count],
					CannotBeAdapted = true
					
					--CanPerfectBlock = (self.Condition == nil),
					--DontHitRagdolled = false,
					--DontHitDeadPeople = false,
					--DontRestartRespawnTimer = false,
				})

				if Validated then
					self.Hit = true
					self.HitTime = time()
					self.OnHit:Fire(VictimLuaPlayer)

					if (self.Count == 4) then
						self.WallComboVictim = VictimLuaPlayer

						task.delay(0.4, function()
							self.WallComboVictim = nil
						end)
					end
					
					local KnockbackVelocity : Vector3 = self.Combat:CalculateUnitDifference(VictimLuaPlayer)

					self:FireReliableVFX("Jimpee/M1", "Hit", VictimLuaCharacter.RootPart, self.Count)

					if self.Condition == "Up" then
						self:FireReliableVFX("Global/M1", "Uppercut", VictimLuaCharacter.RootPart, "Jimpee")

						local VictimVelocityObject = self:VelocityOn(VictimCombat)
						VictimVelocityObject.Settings.RemoveTime = 0.1
						VictimVelocityObject.Settings.Velocity = Vector3.yAxis * 500
						VictimVelocityObject:Fire()

						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true;
							Ragdoll = 5;
						})
						
						self.Combat:VictimImpactGround(VictimLuaPlayer)

						VictimLuaCharacter.RootPart.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(180, -180), 0, Utility.Seed:NextNumber(180, -180))

					elseif self.Condition == "Down" then
						self.Downslammed = true

						self.Combat.Hitbox:Destruction(Hitbox.Params.Offset, Vector3.new(4, 15, 4), 1)
						self:FireReliableVFX("Global/M1", "Down Slam", VictimLuaCharacter.RootPart, "Jimpee")
						VictimLuaCharacter.RootPart.CFrame *= CFrame.new(0, -0.5, 1) * CFrame.Angles(math.rad(-45), 0, 0)

						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true;
							Ragdoll = 2;
						})

						local VictimVelocityObject = self:VelocityOn(VictimCombat)
						VictimVelocityObject.Settings.RemoveTime = 0.1
						VictimVelocityObject.Settings.Velocity = Vector3.yAxis * -60
						VictimVelocityObject:Fire()
					else
						if (self.Count == 4) then
							local VictimVelocityObject = self:VelocityOn(VictimCombat)
							VictimVelocityObject.Settings.RemoveTime = 0.1
							VictimVelocityObject.Settings.Velocity = KnockbackVelocity * 250 + Vector3.yAxis * 75
							VictimVelocityObject:Fire()

							self:Afflict(VictimLuaPlayer, {
								ExcludeAttempts = true;
								Ragdoll = 5;
							})

							self.Combat:VictimImpactGround(VictimLuaPlayer)
						else
							VictimCombat.Animations.BlackFlashed:Play(0, 1, 0.65)
							VictimCombat:TrueStun(2)

							if not VictimCombat:GetState("StunImmunity") then
								local MaxForce = Vector3.new(1, 0, 1) * 10000

								local VictimVelocityObject = self:VelocityOn(VictimCombat)
								VictimVelocityObject.Settings.RemoveTime = 0.2
								VictimVelocityObject.Settings.MaxForce = MaxForce
								VictimVelocityObject.Settings.Velocity = KnockbackVelocity * 5
								VictimVelocityObject:Fire()

								local AttackerVelocityObject = self.Combat:Velocity()
								AttackerVelocityObject.Settings.Name = "M1PullIn"
								AttackerVelocityObject.Settings.Z = 5
								AttackerVelocityObject.Settings.RemoveTime = 0.2
								AttackerVelocityObject.Settings.MaxForce = MaxForce
								AttackerVelocityObject.Settings.Controllable = true
								AttackerVelocityObject:Fire()
							end
						end
					end

					if (self.Count == 4) then
						task.defer(self.Close, self)
					end
				end
			end)

			self.Thread.OnClosed:Connect(function()
				if self.Count > 3 then
					self:AddCooldown(0.5, true)
				end

				self.Combat:StackState("M1ing", false)
			end)

			local StopAnimConnection : RBXScriptConnection; StopAnimConnection = self.Combat.OnStateUpdated:Connect(function(State : string, Value : boolean)
				if (State == "Attacking" or State == "M1ing" or State == "Blocking") and Value then
					StopAnimConnection:Disconnect()
					Animation:Stop()
				end
			end)

			Animation.Stopped:Once(function()
				StopAnimConnection:Disconnect()
			end)

			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("hit"):Connect(function(Parameter : string?)
				self.InWindup = false
				Hitbox:BeginCast(0.1)

				if self.Count > 3 then
					task.spawn(function()
						local Condition : string? = self.Condition
						local CF : CFrame = Hitbox:GetCFrame() * CFrame.new(0, 1, 0)
						local Seed = Random.new()
						local VelocityFn;

						local Power = 150
						local MassDivide = 2

						if Condition == "Up" then
							function VelocityFn(cube)
								return (CF.UpVector * (Power + cube:GetMass() / MassDivide)) + Seed:NextUnitVector() * 5;
							end

						elseif Condition == "Down" then
							function VelocityFn(cube)
								return (CF.UpVector * (Power + cube:GetMass() / MassDivide)) + Seed:NextUnitVector() * 5;
							end
						else
							function VelocityFn(cube)
								return (CF.LookVector * (Power + cube:GetMass() / MassDivide)) + Seed:NextUnitVector() * 5;
							end
						end

						local havoc, destructed, crater, debris = self.Combat.Hitbox:CreateHavocReplicated({
							parameters = {
								origin = CF,
								size = Hitbox.Params.Size, 
								shape = "Box", 
								block_size = 4, 
								seperate_islands = true,
							},
							crater = {},
							debris = {
								scale = 0.9,
								velocity = VelocityFn
							},
						})
					end)

					if not self.Hit then
						if self.Combat:HasACharacter() then
							self.Combat:StackState("CannotUse" .. self.Combat.CurrentCharacter.Name, true)
						end

						self.Combat:StackState("CannotDash", true)
						self.Combat:DivideSpeed(20)

						self.Thread.OnClosed:Connect(function()
							self.Combat:StackState("CannotDash", false)
							self.Combat:TimesSpeed(20)

							if self.Combat:HasACharacter() then
								self.Combat:StackState("CannotUse" .. self.Combat.CurrentCharacter.Name, false)
							end
						end)
					end
				end

				self.Combat.Values.Jump:Add(0.05)

				if (self.Condition == nil) then
					task.wait(0.2)
				else
					task.wait(0.15)
				end

				if self.Count > 3 and not self.Hit then
					task.wait(0.7)
					self:Close()
				else
					self.Combat:StackState("CannotBlock", true)
					self.Combat:StackState("CannotRun", true)
					self:Close()

					task.delay(self.TimeUntilCanBlock, function()
						self.Combat:StackState("CannotRun", false)
						self.Combat:StackState("CannotBlock", false)
					end)
				end
			end))
		end,
	}
}
