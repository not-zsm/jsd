local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Data = require(ReplicatedStorage.Modules.Player.Replication.VFX.Kratos["Axe Throw"].Data)

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	local Weapons = self.Combat.Attacks.Weapons

	if (self.AxeThrown or Weapons and Weapons.ThrownAxe) or self.ForceVariant then
		if Weapons then
			Weapons:SetCurrent("Fists");
		end;
		
		self:Recall()
	else
		self.Animations.Throw:Play(0.05, 1, 1.075)
		self:CreateMoveSFX("Kratos", "Axe Throw", "Throw")

		self.Combat:StackState("Attacking", true)
		self.Combat:DivideSpeed(10)

		self.FinisherHit = false

		self.Thread.OnClosed:Connect(function()
			if Weapons and not Weapons.ThrownAxe then
				Weapons:ToggleIceAxe(false)
			end

			self.Combat:TimesSpeed(10)
			self.Combat:StackState("Attacking", false)
		end)
		
		self.Thread.OnCancelled:Once(function()
			self:AddCooldown(self.Cooldown)
		end)

		if Weapons then
			Weapons:SetCurrent("Axe")
			Weapons:ToggleIceAxe(true)
		end

		self.Thread.Job:Task(self.Animations.Throw:GetMarkerReachedSignal("step"):Connect(function()
			local VelocityObject = self.Combat:Velocity()
			VelocityObject.Settings.Duration = 0.75
			VelocityObject.Settings.RemoveTime = 8
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
			VelocityObject.Settings.Controllable = true 
			VelocityObject.Settings.Z = 9
			VelocityObject:Fire()

			self.Thread.Job:Task(VelocityObject)
		end))

		self.Thread.Job:Task(self.Animations.Throw:GetMarkerReachedSignal("swing"):Connect(function()
			local VelocityObject = self.Combat:Velocity()
			VelocityObject.Settings.Duration = 0.75
			VelocityObject.Settings.RemoveTime = 8
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 14
			VelocityObject:Fire()

			self.Thread.Job:Task(VelocityObject)

			self:CreateMoveSFX("Kratos", "Axe Throw", "Throw Voiceline")
		end))

		self.Thread.Job:Task(self.Animations.Throw:GetMarkerReachedSignal("throw"):Connect(function()
			local MaxDistance = Data.MaxDistance
			local StartFallingAt =  Data.StartFallingAt
			local Gravity = Data.Gravity 

			local Root : BasePart = self.Combat:GetSimulatedRoot()
			local CF = Root.CFrame

			local StartCF = CF * CFrame.new(0.5, 1.25, -2) * CFrame.Angles(0, math.pi, 0)
			local Velocity : Vector3 = CF.LookVector * 250 -- 225

			self.AxeCF = StartCF

			self.AxeProjectileHitbox = self:CreateHitbox(false, true);
			self.AxeProjectileHitbox.Adornee = self.AxeCF
			self.AxeProjectileHitbox.Params.Offset = CFrame.identity
			self.AxeProjectileHitbox.Params.Size = Vector3.new(1.3, 4.75, 3) * 1.2

			local Torso : BasePart? = nil

			self.AxeProjectileHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat

				local Validated, Type = self:Afflict(VictimLuaPlayer, {
					TriggerActiveCounterOverOrEqualLevel = 0.1,
					YDifferenceValue = -2,
					BreakBlock = true,
					Projectile = true,
					Ragdoll = 1,
					Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 30, 0.1},
				})

				local Finisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= 7.5)

				if Type == "Countered" then
					if VictimLuaPlayer.Replication.Attributes:GetAttribute("Vector Reflection") then
						self:StopProjectileRunner()
					else
						self.AxeCF *= CFrame.Angles(0, math.pi, 0)
						self.AxeProjectileHitbox.Params.Ignore = {}
					end
				else
					if Validated then
						local Distance = (self.LuaCharacter.RootPart.Position - VictimLuaCharacter.RootPart.Position).Magnitude

						if Finisher and Distance <= 10 and not self.Thread.Closed then
							self.FinisherHit = true

							self.Combat:ChangeAttackDisplay(self.Name, self.DisplayName, {
								FlashColor = Color3.fromRGB(255, 255, 255),
								Tip = ""
							})

							self:StopProjectileRunner()
							self:FireReliableVFX("Kratos/Axe Throw", "StickToVictim", self.LuaCharacter.Model, VictimLuaCharacter.Head, CFrame.new(0, -1, -2) * CFrame.Angles(math.rad(45), 0, 0))

							local Ended = false
							local FinisherVictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Kratos["Leviathan Throw"].CloseVictimFinisher)

							self.Animations.CloseUserFinisher:Play()
							
							if FinisherVictimAnimation then
								FinisherVictimAnimation:Play()
							end
							
							VictimLuaCharacter:StopRespawnTimer()

							local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(-0.25, 0, -5) * CFrame.Angles(0, math.pi, 0))

							self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

							self.Thread.CancelJob:Task(
								self:CreateMoveSFX("Kratos", "Axe Close Finisher")
							)
							
							self.Combat:HideUI(true)
							VictimCombat:HideUI(true)
							
							self.Thread.OnClosed:Connect(function()
								self.Combat:HideUI(false)
								VictimCombat:HideUI(false)
								
								VictimLuaCharacter:RestartRespawnTimer()
								
								if not Ended then
									if FinisherVictimAnimation then
										FinisherVictimAnimation:Stop(0)
									end
									
									GrabObject.Destroy(0)
									VictimCombat:Unstun()

									if Weapons then
										Weapons:ThrowAxe(false)
										Weapons:SetCurrent("Axe")

										task.delay(0.75, function()
											if Weapons.CurrentlyUsing == "Axe" then
												Weapons:ToggleIceAxe(false) 
											end
										end)
									end
								end
							end)

							self.Thread.Job:Task(self.Animations.CloseUserFinisher:GetMarkerReachedSignal("pullaxe"):Once(function()
								self:StopProjectileRunner()
								self:FireReliableVFX("Kratos/Axe Throw", "Remove", self.LuaCharacter.Model) 

								if Weapons then
									Weapons:ThrowAxe(false)
									Weapons:SetCurrent("Axe")

									task.delay(0.75, function()
										if Weapons.CurrentlyUsing == "Axe" then
											Weapons:ToggleIceAxe(false) 
										end
									end)
								end
							end))

							self.Thread.Job:Task(self.Animations.CloseUserFinisher:GetMarkerReachedSignal("finalhit"):Once(function()
								Ended = true

								FinisherVictimAnimation:Stop(0)
								GrabObject.Destroy(0)

								self:Afflict(VictimLuaPlayer, {
									ExcludeAttempts = true,
									Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 50, 0.1},
									FinisherKill = true
								})

								VictimCombat:Unstun()

								task.wait(0.5)

								self:AddCooldown(self.Cooldown)
								self:Close()
							end))

							self:FireReliableVFX("Kratos/Axe Close Finisher", "OnStart", self.LuaCharacter.Model, VictimLuaCharacter.Model)
						else
							self.Combat:DealDamage(VictimLuaPlayer, 5)
							self.AxeVictim = VictimLuaPlayer

							self.AntiRecallOnRespawn = self.AxeVictim.Character.OnHumanoidAvailabilityChanged:Connect(function()
								if not self.HumanoidExists then
									if self.AntiRecallOnRespawn and self.AntiRecallOnRespawn.Connected then
										self.AntiRecallOnRespawn:Disconnect()
									end

									self.AxeVictim = nil
								end
							end)

							Torso = VictimLuaCharacter.Torso
						end
					end
				end
			end)

			@native local function RunKratosAxeProjectile()
				self.AxeProjectileConnection = self.Job:Task(RunService.PreSimulation:Connect(function(Delta : number)
					local AxeCF : CFrame = self.AxeCF
					local AxePosition : Vector3 =  AxeCF.Position

					local DistanceFromStart : number = (StartCF.Position - AxePosition).Magnitude

					if DistanceFromStart > MaxDistance then
						return self:StopProjectileRunner("Distance")
					end

					local NewAxePosition = AxePosition + Velocity.Unit * (Velocity.Magnitude * Delta)

					self.AxeProjectileHitbox.Adornee = CFrame.lookAlong(NewAxePosition, AxeCF.LookVector)
					self.AxeProjectileHitbox:Detect()

					if (Torso ~= nil) then
						self:StopProjectileRunner("Stick")
						self:FireReliableVFX("Kratos/Axe Throw", "StickToVictim", self.LuaCharacter.Model, Torso)

						return
					end

					local Raycast = workspace:Raycast(AxePosition, NewAxePosition - AxePosition, Utility.VisualParams)

					if Raycast and Raycast.Instance.CanCollide then
						return self:StopProjectileRunner("Hit")
					end

					if (DistanceFromStart > StartFallingAt) then
						Velocity += Gravity * Delta
					end

					self.AxeCF = AxeCF + Velocity * Delta
				end))

				self:FireReliableVFX("Kratos/Axe Throw", "Create", self.LuaCharacter.Model, StartCF, Velocity)
			end

			RunKratosAxeProjectile()

			if self.LuaPlayer.IsNPC and not Weapons then
				self.AxeThrown = true;
			end;
			
			if Weapons then
				Weapons:ThrowAxe(true)
				Weapons:SetCurrent("Fists")
			end

			self.Combat:ChangeAttackDisplay(self.Name, "Recall", {
				FlashColor = Color3.fromRGB(255, 255, 255)
			})
		end))

		task.wait(1)

		self.Animations.Throw:Stop(0.3)

		if self.Combat.Attacks.M1 then
			self.Combat.Attacks.M1.Count = 0
		end

		if self.FinisherHit then
			return
		end

		self:Close()
	end
end

function Attack:StopProjectileRunner(Type : string)
	if self.AxeProjectileConnection and self.AxeProjectileConnection.Connected then
		self.AxeProjectileConnection:Disconnect()
	end

	if self.AxeProjectileHitbox then
		self.AxeProjectileHitbox:Destroy()
	end

	--self:FireReliableVFX("Kratos/Axe Throw", "Obstruct", self.LuaCharacter.Model, Type)

	self.AxeProjectileConnection = nil
	self.AxeProjectileHitbox = nil
end

function Attack:Pretrigger()
	if self.TryAssaultVariantPhase and not self.AssaultVariant then
		self.AssaultVariant = true
	end
end

function Attack:TryAssaultVariant(Value : boolean)
	if Value ~= self.TryAssaultVariantPhase then
		self.TryAssaultVariantPhase = Value

		if Value then
			self.AssaultVariant = false

			self.Combat:ChangeAttackDisplay(self.Name, "Recall", {
				FlashColor = Color3.fromRGB(255, 255, 255),
				Tip = "[PRESS AGAIN]"
			})
		else
			self.Combat:ChangeAttackDisplay(self.Name, self.DisplayName, {
				FlashColor = Color3.fromRGB(255, 255, 255),
				Tip = ""
			})
		end
	end
end

function Attack:Recall()
	self.AxeThrown = false;
	
	self.Animations.Recall:Play()
	self.Combat:StackState("Attacking", true)

	self.Thread.OnClosed:Connect(function()
		self:TryAssaultVariant(false)
		self:AddCooldown(self.Cooldown)
		self.Combat:StackState("Attacking", false)
	end)

	local Pause : RBXScriptConnection = self.Thread.Job:Task(self.Animations.Recall:GetMarkerReachedSignal("pause"):Connect(function()
		self.Animations.Recall:AdjustSpeed(0)
	end))

	self:TryAssaultVariant(true)

	self.Animations.Recall:GetMarkerReachedSignal("point"):Wait()

	self:CreateMoveSFX("Kratos", "Axe Throw", "Call")
	self:StopProjectileRunner()

	local Magnitude = (self.LuaCharacter.RootPart.Position - self.AxeCF.Position).Magnitude

	local RecallX = math.clamp(Magnitude / 3, 1, 120)

	local TrajectoryX = math.random(1, 2) == 1 and -RecallX or RecallX
	local TrajectoryY = math.clamp(Magnitude / 3, 5, 30)

	local Trajectory = Vector3.new(TrajectoryX, TrajectoryY, 0) -- trajectory server sided so it looks the same for all clients

	local Seconds = 0.35
	local Time = math.clamp(Magnitude / (100 / Seconds), Seconds / 2, 1)

	self:FireReliableVFX("Kratos/Axe Throw", "Recall", self.LuaCharacter.Model, Magnitude, Time, Trajectory)

	if self.AntiRecallOnRespawn then
		if self.AntiRecallOnRespawn.Connected then
			self.AntiRecallOnRespawn:Disconnect()
		end

		self.AntiRecallOnRespawn = nil
	end

	if self.AxeVictim then
		if not self.AxeVictim.Character.Combat.Ragdoll.GettingUpArmor then --not self.AxeVictim.Character.Combat:GetState("StunImmunity") then
			local Validated = self:Afflict(self.AxeVictim, {
				TriggerActiveCounterOverOrEqualLevel = -1,
				BreakBlock = true,
				Velocity = {self.Combat:CalculateUnitDifference(self.AxeVictim) * -20, 0.1},
				Damage = 2.5
			})

			if Validated and not self.AxeVictim.Character.Combat:GetState("Ragdolled") then
				self.AxeVictim.Character.Combat.Ragdoll:Toggle(true, 1)
			end
		end

		self.AxeVictim = nil
	end

	task.wait(Time)

	self:TryAssaultVariant(false)

	local Weapons = self.Combat.Attacks.Weapons

	if Pause and Pause.Connected then
		Pause:Disconnect()
	end

	self:CreateMoveSFX("Kratos", "Axe Throw", "Throw Catch")

	if self.AssaultVariant or self.ForceSpecialVariant then
		if Weapons then
			Weapons:ThrowAxe(false)
			Weapons:SetCurrent("Axe")
			Weapons:ToggleIceAxe(true)
		end

		self.Animations.Recall:Stop()

		local cur = 0

		self.Thread.Job:Task(self.Animations.Assault:GetMarkerReachedSignal("slash"):Connect(function(param)
			cur = tonumber(param)

			local Hitbox = self:CreateHitbox(false);
			Hitbox.Params.Offset = CFrame.new(0, 0, -2.75)
			Hitbox.Params.Size = Vector3.new(7.5, 8, 8.35)
			Hitbox.Params.DestroyOnEndCast = false

			local look_vector : Vector3 = self.Combat:GetSimulatedRoot().CFrame.LookVector

			Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat

				local Validated = self:Afflict(VictimLuaPlayer, {
					DontRestartRespawnTimer = true,
					TrueStun = cur ~= 4 and 1 or nil,
					Ragdoll = cur == 4 and 1.25 or nil,
					Damage = 1.25,
					Velocity = {cur == 4 and (look_vector * 60 + Vector3.yAxis * 15) or look_vector * 20, 0.15}
				})

				if Validated then
					self:FireReliableVFX("Kratos/Recall Assault", "SlashHit", VictimLuaCharacter.RootPart, cur)
					VictimCombat:PlayRandomHitReaction()
				end
			end)

			Hitbox:Detect()
			self:FireReliableVFX("Kratos/Recall Assault", "Slash", self.LuaCharacter.RootPart, cur)

			local AttackerVelocityObject = self.Combat:Velocity()
			AttackerVelocityObject.Settings.Z = 20
			AttackerVelocityObject.Settings.RemoveTime = 0.2
			AttackerVelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 40000
			AttackerVelocityObject.Settings.Controllable = true
			AttackerVelocityObject:Fire()
		end))

		self.Combat:DivideSpeed(5)

		self.Thread.OnClosed:Connect(function()
			if Weapons then
				Weapons:ToggleIceAxe(false)
			end

			self.Combat:TimesSpeed(5)
		end)

		self.Thread.CancelJob:Task(self:CreateMoveSFX("Kratos", "Recall Assault"))
		self.Animations.Assault:Play(0.05, 1, 1.15)

		self.Thread.Job:Task(task.delay(0.5, function()
			self.Animations.Assault:AdjustSpeed(1)
		end))

		task.wait(2.35)

		self:Close()
	else
		if Weapons then
			Weapons:ThrowAxe(false)
			Weapons:SetCurrent("Axe")

			task.delay(0.75, function()
				if Weapons.CurrentlyUsing == "Axe" then
					Weapons:ToggleIceAxe(false)
				end
			end)
		end

		self.Animations.Recall.TimePosition = 0.567
		self.Animations.Recall:AdjustSpeed(1)

		self:Close()
	end

	--local Path = PathfindingService:CreatePath({
	--	AgentRadius = 2,
	--	AgentHeight = 2,
	--	AgentCanJump = true,
	--	AgentCanClimb = true
	--})

	--local Target : Attachment = self.LuaCharacter.RightArm.RightGripAttachment
	--Path:ComputeAsync(self.AxeCF.Position, Target.WorldPosition)

	--if Path.Status == Enum.PathStatus.Success then
	--	local Waypoints : {PathWaypoint} = Path:GetWaypoints()
	--	local Time = 0.01

	--	self:FireReliableVFX("Kratos/Axe Throw", "Recall", self.LuaCharacter.Model, Waypoints, Target, Time)

	--	task.wait(Utility.TableCount(Waypoints) * Time)

	--	self.Animations.Recall:AdjustSpeed(1)
	--	self.Animations.Recall:GetMarkerReachedSignal("catch"):Wait()

	--	local Weapons = self.Combat.Attacks.Weapons	

	--	if Weapons then
	--		Weapons:ThrowAxe(false)
	--		Weapons:SetCurrent("Axe")
	--	end

	--	self:Close()
	--else
	--	warn("axe recall pathfinding failed")
	--end
end

function Attack.new(...) 
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.AssaultVariant = false
	self.Recalling = false

	self.Cooldown = 17.5

	self.AxeCF = CFrame.identity

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack