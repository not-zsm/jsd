local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = ReplicatedStorage.Remotes
local HotbarRemotes = Remotes.Combat.UI.Hotbar

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	local Pass = self:BasicConditions() and not self.Combat:GetState("Blocking")

	if self.Variant then
		return (Pass and self.VariantVictim ~= nil)
	end

	return Pass
end

function Attack:BlinkStrike()
	local TeleportVictimLuaPlayer = self.VariantVictim
	local TeleportVictimLuaCharacter = TeleportVictimLuaPlayer.Character
	local TeleportVictimCombat = TeleportVictimLuaCharacter.Combat

	self:DoVariant(false)
	self.VariantHit = false

	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)

	self.Thread.Job:Task(self.Animations.Variant:GetMarkerReachedSignal("tp"):Connect(function()
		self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")

		self.Thread.OnClosed:Connect(function()
			if not self.Combat:GetState("Grabbed") then
				self.LuaCharacter:SetCollisionGroup("Player")
			end
		end)

		local PreviousCF : CFrame = self.Combat:GetSimulatedRoot().CFrame
		local VictimCFrame : CFrame = TeleportVictimCombat:GetSimulatedRoot().CFrame
		local Direction = (VictimCFrame.Position - PreviousCF.Position)
		
		local CF : CFrame = nil
		local Raycast = workspace:Raycast(VictimCFrame.Position + Vector3.yAxis * 1.5, Vector3.yAxis * -12.5, Utility.VisualParams)

		if Raycast then
			CF = CFrame.lookAlong(Raycast.Position - Direction.Unit * 4, Direction) + Vector3.yAxis * Raycast.Distance
		else
			CF = CFrame.lookAlong(VictimCFrame.Position - Direction.Unit * 4, Direction)
		end

		if not TeleportVictimCombat:GetState("Evasived") then
			local VictimAlignPosition = Instance.new("AlignPosition")
			VictimAlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
			VictimAlignPosition.Attachment0 = TeleportVictimLuaCharacter.RootAttachment
			VictimAlignPosition.MaxForce = 200000
			VictimAlignPosition.Responsiveness = 200
			VictimAlignPosition.RigidityEnabled = true
			VictimAlignPosition.Position = Vector3.new(VictimCFrame.Position.X, PreviousCF.Position.Y, VictimCFrame.Position.Z)
			VictimAlignPosition:AddTag("RemoveOnEvasive")
			VictimAlignPosition.Parent = TeleportVictimLuaCharacter.RootPart

			self.VictimAlignPosition = VictimAlignPosition
			
			task.delay(1, function()
				VictimAlignPosition:Destroy()
			end)
		end

		self.LuaCharacter.Model:PivotTo(CF)
		self.Animations.Variant:AdjustSpeed(1.5)

		task.wait(1.6)

		if not self.VariantHit then
			self:Close()
		end
	end))

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -4)
	Hitbox.Params.Size = Vector3.new(9, 6, 12)
	Hitbox.Params.MaxTargets = 1
	
	Hitbox.Events.OnCastEnded:Connect(function()
		if not self.VariantHit then
			self.Animations.Variant:AdjustSpeed(0.95)
		end
	end)

	Hitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
		local NewVictimLuaCharacter = NewVictimLuaPlayer.Character
		local NewVictimCombat = NewVictimLuaCharacter.Combat

		self.VariantHit = self:Afflict(NewVictimLuaPlayer, {
			CanPerfectBlock = true,
			BreakBlock = true,
			Damage = 1,
		})

		if self.VariantHit then

			local VictimAnimation : AnimationTrack = NewVictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Accelerator["Tectonic Control"].VariantHitVictim)
			local FlingAnimation : AnimationTrack = NewVictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Accelerator["Tectonic Control"].VariantVictimFling)

			local GrabObject = self.Combat:GrabVictim(NewVictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -3.6) * CFrame.Angles(0, math.pi, 0))

			self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

			if self.VictimAlignPosition then
				self.VictimAlignPosition:Destroy()
				self.VictimAlignPosition = nil
			end

			self.Thread.OnClosed:Connect(function()
				if VictimAnimation then
					VictimAnimation:Stop()
				end
				
				GrabObject.Destroy(0)
				NewVictimCombat:Unstun()
			end)

			self.Thread.Job:Task(self.Animations.VariantHit:GetMarkerReachedSignal("fling"):Once(function()
				GrabObject.Destroy(0)

				self:Afflict(NewVictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = 4
				})

				NewVictimLuaCharacter.Model:PivotTo(self.Combat:GetSimulatedRoot().CFrame * CFrame.new(0, 0, -4.5) * CFrame.Angles(0, math.pi, 0))

				VictimAnimation:Stop(0)
				NewVictimCombat:TrueStun()

				local FlingJob = Job.new()
				FlingJob:Task(NewVictimLuaCharacter:StopAutoRotate())

				FlingJob:Task(FlingAnimation:GetMarkerReachedSignal("land1"):Connect(function()
					local VelocityObject = self:VelocityOn(NewVictimCombat)
					VelocityObject.Settings.Duration = 0.85
					VelocityObject.Settings.RemoveTime = 0.85
					VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
					VelocityObject.Settings.Controllable = true
					VelocityObject.Settings.Z = -85
					VelocityObject:Fire()

					FlingJob:Task(VelocityObject)
				end))

				FlingJob:Task(FlingAnimation:GetMarkerReachedSignal("land2"):Connect(function()
					local VelocityObject = self:VelocityOn(NewVictimCombat)
					VelocityObject.Settings.Duration = 1.25
					VelocityObject.Settings.RemoveTime = 1.25
					VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
					VelocityObject.Settings.Controllable = true
					VelocityObject.Settings.Z = -14
					VelocityObject:Fire()

					FlingJob:Task(VelocityObject)
				end))

				local VelocityObject = self:VelocityOn(NewVictimCombat)
				VelocityObject.Settings.Duration = 0.7
				VelocityObject.Settings.RemoveTime = 0.675
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = -175
				VelocityObject:Fire()

				FlingJob:Task(VelocityObject)

				FlingJob:Task(FlingAnimation.Stopped:Once(function()
					NewVictimCombat:StackState("Pushed", false)
					
					FlingJob:Destroy()
					NewVictimCombat:Unstun()
				end))

				FlingJob:Task(NewVictimCombat.OnStateUpdated:Connect(function(StateChanged : any, Value : any)
					if (StateChanged == "Stunned" or StateChanged == "Ragdolled") and Value then
						FlingAnimation:Stop(0.3)
					end
				end))
				
				NewVictimCombat.RemoveCurrentPush = function()
					NewVictimCombat.RemoveCurrentPush = nil
					FlingAnimation:Stop(0)
				end
				
				local Length = FlingAnimation.Length > 0 and FlingAnimation.Length or 1
				
				FlingAnimation:Play(0)
				NewVictimLuaPlayer.Replication:FireReliableVFX("Accelerator/Blink Strike", "OnFling", NewVictimLuaCharacter.Model)
				FlingJob:Task(NewVictimCombat:CreateMoveSFX("Accelerator", "Blink Strike", "FlingSFX"))
				
				NewVictimCombat:StackState("Pushed", true)
				NewVictimCombat:StackState("EvasiveState", true)
				
				task.delay(Length + math.clamp(NewVictimLuaPlayer:GetPing(), 0, 1), function()
					NewVictimCombat:StackState("EvasiveState", false)
				end)

				task.wait(0.5)

				self:Close()
			end))

			self:FireReliableVFX("Accelerator/Blink Strike", "OnHit", self.LuaCharacter.Model)
			self.Thread.CancelJob:Task(self:CreateMoveSFX("Accelerator", "Blink Strike", "HitSFX"))

			self.Animations.Variant:Stop(0)
			self.Animations.VariantHit:Play(0)
			VictimAnimation:Play(0)
		end
	end)

	self.Thread.Job:Task(self.Animations.Variant:GetMarkerReachedSignal("hit"):Connect(function()
		Hitbox:BeginCast(0.1)

		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 0.65
		VelocityObject.Settings.RemoveTime = 0.65
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 40
		VelocityObject:Fire()

		self.Thread.Job:Task(VelocityObject)

		--local Hitbox = self.Combat.Hitbox:Create()
		--Hitbox.Params.Offset = CFrame.new(0, 0, -3.5)
		--Hitbox.Params.Size = Vector3.new(8.5, 6, 8.5)

		--local HitDireciton = self.LuaCharacter.RootPart.CFrame.RightVector * 75

		--Hitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
		--	local NewVictimLuaCharacter = NewVictimLuaPlayer.Character
		--	local NewVictimCombat = NewVictimLuaCharacter.Combat

		--	local Validated = self:Afflict(NewVictimLuaPlayer, {
		--		BreakBlock = true,
		--		Damage = 5
		--	})

		--	if Validated then
		--		self:FireReliableVFX("Accelerator/Tectonic Control", "Kick", NewVictimLuaCharacter.Model)

		--		self.Combat:PushSkidVictim(NewVictimLuaPlayer, {
		--			TimeTilGroundDetection = 0.35,
		--			StartVelocityXZ = HitDireciton,
		--			StartVelocityY = Vector3.yAxis * 152,
		--			StartDuration = 0.43,
		--			LandedRollVelocityZ = 140,
		--			LandedRollDuration = 0.75,
		--			LandedRollDurationMultiplier = 0.75
		--		})
		--	end
		--end)

		--Hitbox:Detect()
		--task.defer(Hitbox.Destroy, Hitbox)

		--self:Close()
	end))

	self.Thread.OnClosed:Connect(function()
		self.VariantVictim = nil
		
		self.Combat:TimesSpeed(50)
		self.Combat:StackState("Attacking", false)
	end)

	self.Animations.Variant:Play(0.05, 1, 1)
	self:FireReliableVFX("Accelerator/Blink Strike", "OnWindup", self.LuaCharacter.Model)
	self.Thread.CancelJob:Task(self:CreateMoveSFX("Accelerator", "Blink Strike"))
end

function Attack:Control()
	self.Animations.Control:Play(0.1, 1, 0.8)

	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self.VariantVictim = nil
	self.Finisher = nil
	self.Hit = false

	self.Thread.OnClosed:Connect(function()
		if not self.Variant then
			self:AddCooldown(self.Cooldown)
		end

		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("HitboxImmunity", false) -- bandaid fix for now im just checking if this fixes the invincibility bug
	end)

	self:FireVFX("Accelerator/Tectonic Control", "Start", self.LuaCharacter.RightLeg)

	self.Thread.CancelJob:Task(self:CreateMoveSFX("Accelerator", "Tectonic Control"))
	
	self.Animations.Control:GetMarkerReachedSignal("stomp"):Wait()

	self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
	local StartLookVector = self.LuaCharacter.RootPart.CFrame.LookVector

	self.Animations.Control:AdjustSpeed(0.5)
	self:FireReliableVFX("Accelerator/Tectonic Control", "Stomp", self.LuaCharacter.RightLeg)

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.identity
	Hitbox.Params.Size = Vector3.one * 12.5

	local CurrentIndex = 0

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Finisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= 7.5)
		--local YDifference = self.Combat:CalculateYDifference(VictimLuaPlayer)

		--local PushState = VictimCombat:GetState("Ragdolled") and YDifference > 2

		local Validated = self:Afflict(VictimLuaPlayer, {
			Damage = not Finisher and 3,
		})

		if Validated then
			self.Hit = true

			if (Finisher and self.Finisher == nil) then
				self.Finisher = VictimLuaPlayer

				VictimCombat:StackState("HitboxImmunity", true)
				self.Combat:StackState("HitboxImmunity", true)

				VictimCombat:TrueStun()
				VictimCombat:StackState("CannotDash", true)

				self.Thread.OnClosed:Connect(function()
					VictimCombat:StackState("HitboxImmunity", false)
					VictimCombat:StackState("CannotDash", false)
					VictimCombat:Unstun()
					
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true;
						Ragdoll = 1;
					})

					self.Combat:StackState("HitboxImmunity", false)
				end)

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true;
					Ragdoll = 4;
				})
				--VictimCombat.Ragdoll:Toggle(true, 4)

				local VelocityObject = self:VelocityOn(VictimCombat)
				VelocityObject.Settings.RemoveTime = 0.05
				VelocityObject.Settings.Velocity = self.LuaCharacter.RootPart.CFrame.LookVector * 100 + Vector3.yAxis * 15
				VelocityObject:Fire()
			else
				local VelocityObject = self:VelocityOn(VictimCombat)
				VelocityObject.Settings.RemoveTime = 0.05
				VelocityObject.Settings.Velocity = self.LuaCharacter.RootPart.CFrame.LookVector * 100 + Vector3.yAxis * 15
				VelocityObject:Fire()

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true;
					Ragdoll = 1.5;
				})
				
				VictimCombat:StackState("CannotDash", true, 1)

				if (self.VariantVictim == nil) then
					self.VariantVictim = VictimLuaPlayer
					self:DoVariant(true, VictimLuaPlayer)

					self.Thread.OnCancelled:Connect(function()
						self:DoVariant(false)
					end)
				end
			end
		end
	end)

	local Range = 9.25 --12.5

	for Index = 1, 5 do
		CurrentIndex = Index

		local Offset = CFrame.lookAlong(self.LuaCharacter.RootPart.Position, StartLookVector) * CFrame.new(0.5, 0, -(Index * Range))
		self:FireReliableVFX("Accelerator/Tectonic Control", "GroundBurst", Offset, Index)

		Hitbox.Adornee = Offset
		Hitbox:Detect()

		self.Combat.Hitbox:DestructionAt(Offset, Hitbox.Params.Size, 1)

		task.wait(0.05)
	end

	if (self.Finisher ~= nil) then
		local VictimLuaPlayer = self.Finisher
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
		self.Thread.Job:Task(VictimLuaCharacter:StopAutoRotate())
		VictimLuaCharacter:StopRespawnTimer()

		local GrabObject = nil
		local Ended = false

		self.Thread.OnClosed:Connect(function()
			if (GrabObject ~= nil) then
				GrabObject.Destroy(0)
				VictimCombat:Unstun()
			end

			VictimLuaCharacter:RestartRespawnTimer()
		end)

		self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("hand"):Once(function()
			self.LuaCharacter.Model:PivotTo(CFrame.lookAt(self.LuaCharacter.RootPart.Position, VictimLuaCharacter.RootPart.Position))
			self:FireReliableVFX("Accelerator/Tectonic Control", "FinisherHand", self.LuaCharacter.RightArm)

			self.Thread.OnClosed:Connect(function()
				self:FireReliableVFX("Accelerator/Tectonic Control", "RemoveFinisherHand", self.LuaCharacter.RightArm)
			end)
		end))

		self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("pull"):Once(function()
			local Distance = (VictimLuaCharacter.RootPart.Position - self.LuaCharacter.RootPart.Position).Magnitude / 115

			self:FireReliableVFX("Accelerator/Tectonic Control", "FinisherPull", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, Distance)

			VictimCombat.Ragdoll:ForceToggleOff()
			VictimLuaCharacter.Model:PivotTo(CFrame.lookAt(VictimLuaCharacter.RootPart.Position, self.LuaCharacter.RootPart.Position))

			VictimCombat.Animations.GrabVictims.StompFinisher:Play()

			self.Thread.OnClosed:Connect(function()
				VictimCombat.Animations.GrabVictims.StompFinisher:Stop()
				self:FireReliableVFX("Accelerator/Tectonic Control", "RemoveFinisherPull", VictimLuaCharacter.RootPart)
				VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -2.5) * CFrame.Angles(0, math.pi, 0))
			end)

			self.Thread.Job:Task(task.delay(Distance / 1.25, function()
				self.Animations.Finisher:AdjustSpeed(1)
				VictimCombat.Animations.GrabVictims.StompFinisher:AdjustSpeed(1)
				self.Animations.Finisher.TimePosition = (107 / 60) -- directly on grab marker
				VictimCombat.Animations.GrabVictims.StompFinisher.TimePosition = (47 / 60)
			end))
		end))

		self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("pause"):Once(function()
			self.Animations.Finisher:AdjustSpeed(0)
			VictimCombat.Animations.GrabVictims.StompFinisher:AdjustSpeed(0)
		end))

		self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("grab"):Once(function()
			GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.Angles(0, math.pi, 0))
			self:FireReliableVFX("Accelerator/Tectonic Control", "FinisherGrab", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
		end))

		self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("slam"):Once(function()
			self:FireReliableVFX("Accelerator/Tectonic Control", "FinisherSlam", self.LuaCharacter.RightArm, self.LuaCharacter.RootPart)

			local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 2, -4), Vector3.new(30, 13, 30))

			AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
				self:Afflict(NewVictimLuaPlayer, {
					TriggerActiveCounterOverOrEqualLevel = -1,
					Damage = 4,
					Ragdoll = 1.5,
					Velocity = {Vector3.yAxis * 65, 0.1}
				})
			end)

			AOEHitbox:BeginCast(0.05)
		end))

		self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("rocks"):Once(function()
			self:FireReliableVFX("Accelerator/Tectonic Control", "FinisherRocks", self.LuaCharacter.RootPart)

			self.Thread.OnClosed:Connect(function()
				self:FireReliableVFX("Accelerator/Tectonic Control", "RemoveFinisherRocks", self.LuaCharacter.RootPart)
			end)
		end))

		self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("pop"):Once(function()
			Ended = true

			VictimCombat.Animations.GrabVictims.StompFinisher:Stop(0)
			self:FireReliableVFX("Accelerator/Tectonic Control", "FinisherPop", self.LuaCharacter.RootPart, VictimLuaCharacter.Model)

			GrabObject.Destroy(0)
			VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 3, -6) * CFrame.Angles(0, math.pi, 0))

			self:Afflict(VictimLuaPlayer, {
				ExcludeAttempts = true,
				FinisherKill = true,
				Velocity = {Vector3.yAxis * 35, 0.1}
			})

			VictimCombat.Ragdoll:Toggle(true)

			task.wait(0.75)

			self:Close()
		end))

		self.Animations.Control:Stop(0.2)
		self.Animations.Finisher:Play(0.2)
		self.Animations.Finisher.TimePosition = 0.5
	else
		if not self.Hit then
			self.Animations.Control:AdjustSpeed(0.3)
			task.wait(1.2)
		else
			self.Animations.Control:Stop()
		end

		self:Close()
	end
end

function Attack:DoVariant(Value : boolean, VictimLuaPlayer)
	if self.Variant ~= Value then
		if self.Timer and coroutine.status(self.Timer) == "suspended" then
			task.cancel(self.Timer)
			self.Timer = nil
		end

		if Value then
			self.Combat:ChangeAttackDisplay(self.Name, "Blink Strike", {
				Tip = "[PRESS AGAIN]",
				FlashColor = Color3.fromRGB(138, 55, 255)
			})

			self.Timer = task.delay(1, function()
				self.Timer = nil
				self:DoVariant(false)
			end)
		else
			self:AddCooldown(self.Cooldown)

			self.Combat:ChangeAttackDisplay(self.Name, self.DisplayName, {
				Tip = "",
				FlashColor = Color3.fromRGB(138, 55, 255)
			})
		end

		self.Variant = Value
	end
end

function Attack:Activate()
	if (self.VariantsEnabled and self.Variant) or self.ForceVariant then
		self:BlinkStrike()
	else
		self:Control()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true

	self.Cooldown = 21

	self.Finisher = nil

	self.Variant = false
	self.VariantVictim = nil

	self.Timer = nil

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack