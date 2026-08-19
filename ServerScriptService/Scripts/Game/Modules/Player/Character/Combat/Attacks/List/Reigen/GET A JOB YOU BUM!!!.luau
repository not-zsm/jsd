local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

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
	self.Combat:DivideSpeed(7)

	self.Hit = false

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -4)
	Hitbox.Params.Size = Vector3.new(7, 10, 8)
	Hitbox.Params.DestroyOnEndCast = false
	Hitbox.Params.MaxTargets = 1

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Finisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= 7.5)

		self.Hit = self:Afflict(VictimLuaPlayer, {
			Damage = not Finisher and 2.5,
			BreakBlock = true,
			DontBypassIFrames = {"Grab", "Backdash"}
		})

		if self.Hit then
			self.Animations.Windup:Stop()
			self.Animations.Hit:Play(0.1, 1, 0.65)
			VictimCombat.Animations.GrabVictims.ReigenUppercut:Play(0.05, 1, 0.65)

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0))
			local Ended = false

			self.Thread.OnClosed:Connect(function()
				self.Animations.Finisher:Stop()
				VictimCombat.Animations.GrabVictims.ReigenUppercut:Stop()

				if not Ended then
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end
			end)

			self:FireReliableVFX("Reigen/GetAJobYouBum", "Hit", self.LuaCharacter.RootPart)
			self:FireReliableVFX("Global/M1", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, 3)

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("up"):Connect(function()
				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 1
				VelocityObject.Settings.RemoveTime = 0.1
				VelocityObject.Settings.MaxForce = Vector3.one * 30000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Y = 60
				VelocityObject.Settings.Z = -10
				VelocityObject.Settings.DoesntNeedVelocityAttribute = true
				VelocityObject:Fire()

				self.Thread.Job:Task(VelocityObject)
				
				self.Animations.Hit:AdjustSpeed(1)
				
				task.delay(0.3, function()
					self.Animations.Hit:AdjustSpeed(0.5)

					self.Combat.ClientLanded:Once(function()
						self.Animations.Hit:AdjustSpeed(1.1)
					end)
				end)

				if Finisher then
					self.Combat:StackState("HitboxImmunity", true)
					VictimCombat:StackState("HitboxImmunity", true)

					local CurrentVictim = VictimLuaCharacter.Model

					self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
					self:FireReliableVFX("Reigen/GetAJobYouBum", "FinisherHit", self.LuaCharacter.RootPart, VictimLuaCharacter.Torso)

					self.Animations.Finisher:Play()

					VictimLuaCharacter:StopRespawnTimer()
					
					VictimCombat.Animations.GrabVictims.ReigenUppercut:Stop(0)
					VictimCombat.Animations.GrabVictims.ReigenUppercutFinisher:Play()

					self.Thread.OnClosed:Connect(function()
						self.Combat:StackState("HitboxImmunity", false)
						VictimCombat:StackState("HitboxImmunity", false)
						
						VictimLuaCharacter:RestartRespawnTimer()
						VictimCombat.Animations.GrabVictims.ReigenUppercutFinisher:Stop(0)
					end)
					
					self:FireReliableVFX("Reigen/GetAJobYouBum", "CreateFriend", self.LuaCharacter.RootPart)
					
					--task.spawn(function()
					--	local Friend = self.Combat:GetRandomFriend()

					--	if Friend then
					--		self:FireReliableVFX("Reigen/GetAJobYouBum", "CreateFriend", self.LuaCharacter.RootPart, Friend)
					--	end
					--end)

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("friendappear"):Connect(function()
						self:FireReliableVFX("Reigen/GetAJobYouBum", "AppearFriend", self.LuaCharacter.RootPart)

						self.Thread.OnClosed:Connect(function()
							self:FireReliableVFX("Reigen/GetAJobYouBum", "FriendBye", self.LuaCharacter.RootPart, VictimLuaCharacter.Model)
						end)
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("friendland"):Connect(function()
						self:FireReliableVFX("Reigen/GetAJobYouBum", "FriendLand", self.LuaCharacter.RootPart)
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("pull"):Connect(function()
						self:FireReliableVFX("Reigen/GetAJobYouBum", "FinisherPull", self.LuaCharacter.RootPart, VictimLuaCharacter.Model)
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("startcrushing"):Connect(function()
						self:FireReliableVFX("Reigen/GetAJobYouBum", "FinisherStartCrushing", self.LuaCharacter.RootPart, VictimLuaCharacter.Model)
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("crush"):Connect(function()
						self:FireReliableVFX("Reigen/GetAJobYouBum", "FinisherCrush", self.LuaCharacter.RootPart, VictimLuaCharacter.Model)
						
						GrabObject.Destroy(0)
						
						if CurrentVictim == VictimLuaCharacter.Model then
							self:Afflict(VictimLuaPlayer, {
								FinisherKill = true,
								ExcludeAttempts = true
							})
						end
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("frienddisappear"):Once(function()
						self:FireReliableVFX("Reigen/GetAJobYouBum", "FriendBye", self.LuaCharacter.RootPart, VictimLuaCharacter.Model)

						task.wait(0.5)

						self:Close()
					end))
				else
					Ended = true
					
					GrabObject.Destroy(0)
	
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = 5
					})

					self:FireReliableVFX("Global/M1", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, 4)
					VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 14, -7) * CFrame.Angles(0, math.pi, 0))

					--self.Combat:PushSkidVictim(VictimLuaPlayer, {
					--	TimeTilGroundDetection = 0.5,
					--	StartVelocityXZ = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 70,
					--	StartVelocityY = Vector3.yAxis * 125,
					--	StartDuration = 0.45,
					--	LandedRollVelocityZ = 120,
					--	LandedRollDuration = 0.735
					--})
					
					self.Combat:PushSkidVictim(VictimLuaPlayer, {
						TimeTilGroundDetection = 0.5,
						StartVelocityXZ = self.LuaCharacter.RootPart.CFrame.LookVector * 30,
						StartVelocityY = Vector3.yAxis * 75,
						StartDuration = 0.45,
						LandedRollVelocityZ = 150,
						LandedRollDuration = 0.775
					})

					self:FireReliableVFX("Reigen/GetAJobYouBum", "Spin", VictimLuaCharacter.RootPart)
					
					VictimCombat:Unstun()
					self:Close()
				end
			end))
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(21)

		self.Combat:TimesSpeed(7)
		self.Combat:StackState("Attacking", false)
	end)

	self:FireReliableVFX("Reigen/GetAJobYouBum", "Windup", self.LuaCharacter.RootPart)

	self.Animations.Windup:GetMarkerReachedSignal("hit"):Wait()

	local VelocityObject = self.Combat:Velocity()
	VelocityObject.Settings.Duration = 1
	VelocityObject.Settings.RemoveTime = 0.15
	VelocityObject.Settings.MaxForce = Vector3.one * 30000
	VelocityObject.Settings.Controllable = true
	VelocityObject.Settings.Z = 25
	VelocityObject.Settings.Y = 50
	VelocityObject:Fire()

	self.Thread.Job:Task(VelocityObject)
	
	self.Thread.Job:Task(task.delay(0.3, function()
		self.Animations.Windup:AdjustSpeed(0.5)

		self.Thread.Job:Task(self.Combat.ClientLanded:Once(function()
			self.Animations.Windup:AdjustSpeed(1.1)
		end))
	end))
	
	Hitbox:BeginCast()

	task.wait(0.1)

	Hitbox:EndCast()
	self.Animations.Windup:AdjustSpeed(1.1)

	task.wait(0.9)

	if not self.Hit then
		self:Close()
	end
end


function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.TryToCancelMoves = true
	self.Hit = false

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack