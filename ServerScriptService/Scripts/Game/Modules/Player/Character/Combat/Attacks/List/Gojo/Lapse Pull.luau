local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local Modules = ReplicatedStorage.Modules
local Remotes = ReplicatedStorage.Remotes

local HotbarRemotes = Remotes.Combat.UI.Hotbar

local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )
local Utility = require( Modules.Shared.Utilities.Utility )

----------------------------------------------------------------------------------

local Attack = {}
Attack.__index = Attack

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:CheckPullOnTarget(TargetLuaPlayer, CustomRange : number)
	if self.Combat.Hitbox:ValidatePlayer(TargetLuaPlayer) and not TargetLuaPlayer.Character.Combat:GetState("GrabIFrames") and self.Combat:CalculateMagnitude(TargetLuaPlayer) < (CustomRange or self.Range) then
		return true
	end

	return false
end

function Attack:Pretrigger()
	if (self.InKick and self.PressedKey == nil) then
		self.PressedKey = time()
	end
end

local function NormalPull(self)
	self.PullHitbox = self:CreateHitbox(true);
	self.PullHitbox.Params.Size = (self.Range - 2)
	self.PullHitbox.Params.MaxTargets = 5;
	
	local GotTarget = false;
	
	self.PullHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		if not GotTarget and self:Afflict(VictimLuaPlayer, {DontCheckBlock = true, CannotBeAdapted = true}) then
			GotTarget = true;
			self.CurrentTarget = VictimLuaPlayer
		end
	end)
	
	self.PullHitbox:Detect()
end;

function Attack:ConditionToActivate()
	local NormalConditions = (self:BasicConditions() and not self.Combat:GetState("Blocking"))
	
	self.CurrentTarget = nil

	if (self.KickPhaseTime == nil) then
		
		if self.Combat.CurrentDevicePlayingOn == "Keyboard" then
			if (self.Combat.Mouse.Target == nil or self.Combat.Mouse.Target == self.LuaCharacter.Model) then
				return false
			end

			local TargetLuaPlayer = LuaPlayerList.Get(self.Combat.Mouse.Target)--LuaPlayerList.LuaPlayers[Players:GetPlayerFromCharacter(self.Combat.Mouse.Target) or self.Combat.Mouse.Target]

			if TargetLuaPlayer and self:CheckPullOnTarget(TargetLuaPlayer) then
				self.CurrentTarget = TargetLuaPlayer
				self.Combat.Mouse.Target = nil

				return NormalConditions
			end
		else
			if NormalConditions then
				NormalPull(self);
			end

			return (NormalConditions and self.CurrentTarget ~= nil)
		end;

		return false
	else
		return NormalConditions
	end
end

function Attack:ResetKickTimer(DontChangeText : boolean)
	if (self.KickPhaseTime == nil) then return end

	if (coroutine.status(self.KickPhaseTime) == "suspended") then
		task.cancel(self.KickPhaseTime)
	end

	self.KickPhaseTime = nil

	if (self.M1HitConnection ~= nil and self.M1HitConnection.Connected) then
		self.M1HitConnection:Disconnect()
	end

	if not DontChangeText then
		self:ChangeDisplay(self.DisplayName, {
			FlashColor = Color3.fromRGB(0, 135, 255)
		})
	end

	self:AddCooldown(self.Cooldown)
end

function Attack:Kick()
	self:ResetKickTimer(true)

	self.KickLanded = false
	self.InKick = true
	self.FinisherHit = false

	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(5)

	self.Thread.OnClosed:Connect(function()
		self:ChangeDisplay(self.DisplayName, {
			FlashColor = Color3.fromRGB(0, 135, 255)
		})
		
		self.InKick = false
		self.PressedKey = nil

		self.Combat:TimesSpeed(5)
		self.Combat:StackState("Attacking", false)
	end)

	self.Animations.Pull:Stop()
	self.Animations.KickWindup:Play()

	self:FireVFX("Gojo/Pull&Kick", "Kick", self.LuaCharacter.LeftLeg)

	self.Thread.Job:Task(self.Animations.KickWindup:GetMarkerReachedSignal("hit"):Connect(function()
		local Hitbox = self:CreateHitbox(false);
		Hitbox.Params.Offset = CFrame.new(0, -1.5, -2)
		Hitbox.Params.Size = Vector3.new(6, 8, 7)

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local FinisherActivate = self:IsFinisherEnabled() and VictimLuaCharacter.Humanoid.Health <= 10
			
			local Validated = self:Afflict(VictimLuaPlayer, {
				--BreakBlock = true,
				--YDifferenceValue = -2
			})

			if Validated then
				local hit = false
				local finshr = false
				
				if not self.KickLanded then
					self:ChangeDisplay("Kick");
					
					local M1Attack, M1Matched = self.Combat:MatchAttack("M1", Enum.UserInputType.MouseButton1)

					if M1Matched then
						M1Attack.ResetTime = time() 
					end
				end
			
				if FinisherActivate and not self.FinisherHit and not finshr then
					self.FinisherHit = true
					finshr = true

					VictimCombat:StackState("HitboxImmunity", true)
					self.Combat:StackState("HitboxImmunity", true)

					VictimLuaCharacter:StopRespawnTimer()

					self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

					self.Animations.KickWindup:Stop(0); self.Animations.KickFinisher:Play(0)
					VictimCombat.Animations.GrabVictims.PullKickFinisher:Play()

					local Offset = CFrame.new(0, 0, -3.5) * CFrame.Angles(0, math.pi, 0)
					local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, Offset)
					local CurrentVictim = VictimLuaCharacter.Model

					self.Thread.OnClosed:Connect(function()
						GrabObject.Destroy(0)
						VictimCombat:Unstun()

						VictimCombat.Animations.GrabVictims.PullKickFinisher:Stop()
						VictimLuaCharacter:RestartRespawnTimer()

						VictimCombat:StackState("HitboxImmunity", false)
						self.Combat:StackState("HitboxImmunity", false)
					end)

					self:FireReliableVFX("Gojo/Pull&Kick", "KickFinisher", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)

					self.Thread.Job:Task(self.Animations.KickFinisher:GetMarkerReachedSignal("pullwindup1"):Once(function()
						self:FireReliableVFX("Gojo/Pull&Kick", "KickFinisherPullWindup1", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
					end))

					self.Thread.Job:Task(self.Animations.KickFinisher:GetMarkerReachedSignal("kickfreeze1"):Once(function()
						self:FireReliableVFX("Gojo/Pull&Kick", "KickFinisherKickPause1", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
					end))

					self.Thread.Job:Task(self.Animations.KickFinisher:GetMarkerReachedSignal("kickresume1"):Once(function()
						self:FireReliableVFX("Gojo/Pull&Kick", "KickFinisherKickResume1", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
					end))

					self.Thread.Job:Task(self.Animations.KickFinisher:GetMarkerReachedSignal("pullwindup2"):Once(function()
						self:FireReliableVFX("Gojo/Pull&Kick", "KickFinisherPullWindup2", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
					end))

					self.Thread.Job:Task(self.Animations.KickFinisher:GetMarkerReachedSignal("kickfreeze2"):Once(function()
						self:FireReliableVFX("Gojo/Pull&Kick", "KickFinisherKickPause2", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
					end))

					self.Thread.Job:Task(self.Animations.KickFinisher:GetMarkerReachedSignal("kickresume2"):Once(function()
						self:FireReliableVFX("Gojo/Pull&Kick", "KickFinisherKickResume2", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
					end))

					self.Thread.Job:Task(self.Animations.KickFinisher:GetMarkerReachedSignal("punchfreeze"):Once(function()
						self:FireReliableVFX("Gojo/Pull&Kick", "KickFinisherPunchFreeze", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
					end))

					self.Thread.Job:Task(self.Animations.KickFinisher:GetMarkerReachedSignal("punchresume"):Once(function()
						self:FireReliableVFX("Gojo/Pull&Kick", "KickFinisherPunchResume", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
						GrabObject.Destroy(0)

						if CurrentVictim == VictimLuaCharacter.Model then
							self:Afflict(VictimLuaPlayer, {
								FinisherKill = true,
								ExcludeAttempts = true
							})

							VictimCombat.Animations.GrabVictims.PullKickFinisher:Stop(0)
							VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * Offset)

							VictimCombat.Ragdoll:Toggle(true)

							local VelocityObject = VictimCombat:Velocity()

							if VelocityObject then
								VelocityObject.Settings.RemoveTime = 0.025
								VelocityObject.Settings.Velocity = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 175 + Vector3.yAxis * 55
								VelocityObject:Fire()
							end

							self.Combat:VictimImpactGround(VictimLuaPlayer)
						end

						task.wait(0.75)

						self:Close()
					end))
				end
				
				hit = true
				self.KickLanded = true
				
				if not finshr then
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = 5,
						Ragdoll = 1.25;
					})

					self:FireVFX("Gojo/Pull&Kick", "KickHit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)

					local VelocityObject = self:VelocityOn(VictimCombat)
					VelocityObject.Settings.RemoveTime = 0.1
					VelocityObject.Settings.Velocity = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 25 + Vector3.yAxis * 45
					VelocityObject:Fire()
					
					--VictimCombat.Ragdoll:Toggle(true, 1.25)
				end
			end
		end)

		Hitbox:Detect()
		
		task.defer(function()
			task.delay(0.25, function()
				self.Animations.KickWindup:Stop(0.4)
			end)
			
			if self.KickLanded and not self.FinisherHit then
				self:Close()
				
				task.delay(2 / 60, function()
					if self.Combat:GetState("Blocking") or self.Combat:GetState("M1ing") then
						self.Animations.KickWindup:Stop(0.25)
					end
				end)
			end
		end)
	end))

	task.wait(1)

	if not self.KickLanded then
		self:Close()
	end
end

function Attack:Pull()
	self.Combat:StackState("Attacking", true)
	self.Pulled = false

	self.Animations.Pull:Play(0.1, 1, 0.5)
	self.Combat:DivideSpeed(4)

	self.Thread.OnClosed:Connect(function()
		if self.PullHitbox then
			self.PullHitbox:Destroy()
		end

		self.Combat:TimesSpeed(4)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.OnCancelled:Connect(function()
		self:AddCooldown(self.Cooldown)
	end)

	if self.LuaPlayer.IsNPC or not self.CurrentTarget then
		if not self.LuaPlayer.IsNPC then
			warn("No target was given, using hitbox instead.");
		end;
		
		self.CurrentTarget = nil;
		NormalPull(self);
	end;
	
	local TargetLuaPlayer = self.CurrentTarget
	local TargetLuaCharacter = TargetLuaPlayer.Character
	local TargetCombat = TargetLuaCharacter.Combat
	local CurrentVictim = TargetLuaCharacter.Model

	self:FireReliableVFX("Gojo/Pull&Kick", "Charge", self.LuaCharacter.RightArm)

	self.Animations.Pull:GetMarkerReachedSignal("aim"):Wait()

	self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

	self:FireReliableVFX("Gojo/Pull&Kick", "Indicator", TargetLuaCharacter.Torso)

	self:FireReliableVFXToSelf("Gojo/Pull&Kick", "AimToTarget", self.LuaCharacter.RootPart, TargetLuaCharacter.RootPart)
	self:FireReliableVFXToSelf("Gojo/Pull&Kick", "Chosen", TargetLuaCharacter.RootPart)

	if not TargetLuaPlayer.IsNPC then
		TargetLuaPlayer.Replication:FireReliableVFXToSelf("Gojo/Pull&Kick", "Chosen", TargetLuaCharacter.RootPart)
	end

	self.Animations.Pull:GetMarkerReachedSignal("pull"):Wait()

	if self:CheckPullOnTarget(TargetLuaPlayer, self.Range + 10) then
		local Validated = self:Afflict(TargetLuaPlayer, {
			BlockAngle = math.rad(180),
			CannotBeAdapted = true,
		})

		if Validated and CurrentVictim == TargetLuaCharacter.Model then
			self.Pulled = true

			self.Animations.Pull:AdjustSpeed(0.8)

			local M1Attack, M1Matched = self.Combat:MatchAttack("M1", Enum.UserInputType.MouseButton1)

			if M1Matched then
				M1Attack.ResetTime = time() 
				M1Attack.Count = 3
				
				--if (time() - M1Attack.ResetTime >= M1Attack.ResetTimer) then
				--	M1Attack.Count = 0
				--else
				--	M1Attack.Count = 3
				--end
			end 

			TargetCombat:StackState("StunImmunity", false)
			TargetCombat.Ragdoll:ForceToggleOff()

			self:FireVFX("Gojo/Pull&Kick", "Pull", self.LuaCharacter.RootPart, TargetLuaCharacter.Torso)

			self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
			TargetLuaCharacter:SetCollisionGroup("NoPlayerCollision")

			local Info = TweenInfo.new(0.25)

			self.Combat.Hitbox:Destruction(CFrame.new(0, 0, -7), Vector3.new(4, 6, 15), 2)

			TweenService:Create(TargetLuaCharacter.RootPart, Info, 
				{CFrame = self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -3.75) * CFrame.Angles(0, math.pi, 0)}
			):Play()

			task.delay(Info.Time, function()
				self.LuaCharacter:SetCollisionGroup("Player")
				TargetLuaCharacter:SetCollisionGroup("Player")
			end)

			TargetCombat.Animations.HitReactions.Back:Play()
			TargetCombat:TrueStun(1)
			
			self:ChangeDisplay("Kick", {FlashColor = Color3.new(1, 1, 1)})

			if (M1Matched) then
				self.M1HitConnection = M1Attack.OnHit:Connect(function()
					if (self.KickPhaseTime ~= nil) then
						task.cancel(self.KickPhaseTime)
						self.KickPhaseTime = nil
					end

					self.KickPhaseTime = task.delay(self.HaveKickTime, self.ResetKickTimer, self)
				end)
			end

			self.KickPhaseTime = task.delay(self.HaveKickTime, self.ResetKickTimer, self)

			task.wait(0.25)

			self:Close()

			--if (TargetLuaCharacter.Humanoid.Health <= 2.5 and CurrentVictim == TargetLuaCharacter.Model) then
			--	self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

			--	self.Combat:StackState("HitboxImmunity", true)
			--	TargetCombat:StackState("HitboxImmunity", true)

			--	local Ended = false

			--	TargetCombat:TrueStun()
			--	self.Combat:DivideSpeed(10)
			--	TargetLuaCharacter.RootPart.Anchored = true

			--	local GrabObject

			--	self.Animations.Pull:Stop(0); self.Animations.Finisher:Play(0.1, 1, 0.75)
			--	TargetCombat.Animations.GrabVictims.PullFinisherSlide:Play()

			--	self.Thread.OnClosed:Connect(function()
			--		self:AddCooldown(self.Cooldown)

			--		if not Ended then
			--			TargetCombat:StackState("HitboxImmunity", false)
			--		end

			--		if GrabObject then
			--			GrabObject.Destroy(0)
			--			TargetCombat:Unstun()
			--		end

			--		TargetLuaCharacter.RootPart.Anchored = false
			--		TargetCombat:Unstun() -- not on accident he gets true stunned

			--		self.Combat:TimesSpeed(10)
			--		self.Combat:StackState("HitboxImmunity", false)
			--	end)

			--	self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("grab"):Once(function()
			--		self.Animations.Finisher:AdjustSpeed(1)

			--		if CurrentVictim ~= TargetLuaCharacter.Model then return end

			--		TargetCombat.Animations.GrabVictims.PullFinisherSlide:Stop()
			--		TargetCombat.Animations.GrabVictims.PullFinisherGrab:Play(0.1, 1, 0.86)

			--		TargetLuaCharacter.RootPart.Anchored = false
			--		GrabObject = self.Combat:GrabVictim(TargetLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -4) * CFrame.Angles(0, math.pi, 0))

			--		self:FireVFX("Gojo/Pull&Kick", "FinisherGrab", self.LuaCharacter.RootPart, TargetLuaCharacter.Head)

			--		self.Thread.OnClosed:Connect(function()
			--			TargetCombat.Animations.GrabVictims.PullFinisherGrab:Stop()
			--		end)
			--	end))

			--	self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("slam"):Once(function()
			--		GrabObject.Destroy(0)

			--		if CurrentVictim == TargetLuaCharacter.Model then
			--			Ended = true

			--			local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(TargetLuaPlayer, CFrame.new(0, 3, 0), Vector3.new(20, 12, 20))

			--			AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
			--				local NewVictimLuaCharacter = NewVictimLuaPlayer.Character
			--				local NewVictimCombat = NewVictimLuaCharacter.Combat

			--				local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
			--					BreakBlock = true,
			--					Damage = 5,
			--					Ragdoll = 2.25,
			--					Velocity = {Vector3.yAxis * 65, 0.1}
			--				})

			--				if Validated then
			--					NewVictimLuaCharacter.RootPart:ApplyAngularImpulse(Vector3.new(Utility.Seed:NextNumber(-100, 100), Utility.Seed:NextNumber(-100, 100), Utility.Seed:NextNumber(-100, 100)))
			--				end
			--			end)

			--			AOEHitbox:BeginCast(0.05)

			--			self.Combat:Afflict(TargetLuaPlayer, {
			--				FinisherKill = true,
			--				ExcludeAttempts = true
			--			})

			--			TargetCombat:Velocity(Vector3.yAxis * -50, 0.1)

			--			if TargetLuaPlayer.IsNPC then
			--				TargetCombat.Ragdoll:Toggle(true, 3)
			--			else
			--				TargetCombat.Ragdoll:Toggle(true)
			--			end

			--			TargetCombat.Animations.GrabVictims.PullFinisherGrab:Stop()
			--			self:FireVFX("Gojo/Pull&Kick", "FinisherSlam", TargetLuaCharacter.Head)
			--		end

			--		TargetCombat:Unstun()

			--		task.wait(0.5)

			--		self:Close()
			--	end))
			--else

			--end
		else
			self:AddCooldown(self.Cooldown)
		end
	else
		self:AddCooldown(self.Cooldown)
	end

	if not self.Pulled then
		self.Animations.Pull:AdjustSpeed(0.85)
	end

	task.wait(0.75)

	if not self.Pulled then
		self:Close()
	end
end

function Attack:Activate()
	if (self.KickPhaseTime ~= nil) or self.ForceVariant then
		self:Kick()
	else
		self:Pull()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.TryToCancelMoves = true
	self.BeginRequestingMouseOnBuffer = true

	self.KickPhaseTime = nil
	self.M1HitConnection = nil

	self.Range = 30
	self.Cooldown = 17.5
	self.HaveKickTime = 1.5 

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack