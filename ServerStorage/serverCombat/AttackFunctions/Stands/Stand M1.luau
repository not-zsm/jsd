local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )

local CustomAttack = {};

function CustomAttack.Activate(self)
	local StandHandler = self.Combat:GetStand();

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

	local CharacterName : string = self.Combat:HasACharacter() and self.Combat.CurrentCharacter.Name or nil
	local CharacterInfo : {} = self.Combat:HasACharacter() and self.Combat.CurrentCharacter.Info or nil
	local CharacterStats : {} = self.Combat:HasACharacter() and self.Combat.CurrentCharacter.Stats or nil

	local Animation : AnimationTrack
	local AttackingWith = nil

	if (StandHandler ~= nil) then
		local StandDirectory = StandHandler:GetAnimationDirectory()
		local StandM1s = StandDirectory and StandDirectory.M1

		if StandM1s then
			for _, Animation : AnimationTrack in StandM1s do
				if (Animation.Animation ~= nil and Animation.IsPlaying) then
					Animation:Stop()
				end
			end
		end

		Animation = (self.Condition ~= nil and StandM1s[self.Condition] or StandM1s[tostring(self.Count)])
		StandHandler:MoveStandByAction("Attack", 1.25)

		self.Thread.OnClosed:Connect(function()
			--self.StandReset = task.delay(self.TimeUntilCanBlock, StandHandler.MoveStandByAction, StandHandler, "Idle", 1.25)
			--local StateChanged : RBXScriptConnection;

			--local Reset = task.delay(self.TimeUntilCanBlock, function()
			--	if StateChanged and StateChanged.Connected then
			--		StateChanged:Disconnect()
			--	end

			--	StandHandler:MoveStandByAction("Idle", 1.25)
			--end)

			--StateChanged = self.Combat.OnStateChanged:Connect(function(State : string, Value : any)
			--	if (State == "Attacking" or State == "M1ing") and Value then
			--		StateChanged:Disconnect()
			--		Utility.CloseThreadSafe(Reset)
			--	end
			--end)

			StandHandler:MoveStandByAction("Idle", 1.25)
		end)

		Animation:Play()
	else
		local AnimationDirectory = self:GetAnimationDirectory()
		Animation = (self.Condition ~= nil and AnimationDirectory[self.Condition] or AnimationDirectory[tostring(self.Count)])

		self.Thread.Job:Task(Animation:GetMarkerReachedSignal("attackingwith"):Once(function(Parameter : string)
			AttackingWith = self.LuaCharacter[Parameter]
		end))

		local DefaultSpeed = 0.83

		if CharacterStats then
			local M1Speed = (CharacterStats.M1 and (CharacterStats.M1.Speed or DefaultSpeed) or DefaultSpeed)
			Animation:Play(0.1, 1, (self.Condition == nil and M1Speed or 1))
		else
			Animation:Play(0.1, 1, DefaultSpeed)
		end
	end

	local Hitbox = self:CreateHitbox()
	Hitbox.Params.DestroyOnEndCast = false

	if self.Condition == "Up" then
		Hitbox.Params.Offset = CFrame.new(0, 0, -2.65)
		Hitbox.Params.Size = Vector3.new(6, 10, 6.8)

	elseif self.Condition == "Down" then
		Hitbox.Params.Offset = CFrame.new(0, -3.5, -2.65)
		Hitbox.Params.Size = Vector3.new(5.35, 25, 6.8)
	else
		if CharacterStats and CharacterStats.M1 and CharacterStats.M1.Hitbox then
			Hitbox.Params.Offset = CharacterStats.M1.Hitbox.Offset
			Hitbox.Params.Size = CharacterStats.M1.Hitbox.Size
		else
			Hitbox.Params.Offset = CFrame.new(0, 0, -2.65) 
			Hitbox.Params.Size = Vector3.new(6, 6, 6.8)
		end
	end

	local VictimWasTimestopped = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local BlockAttack, BlockAttackMatched = self.Combat:MatchAttack("Block", Enum.KeyCode.F)
		local Parried = BlockAttackMatched and (time() - BlockAttack.PerfectBlockTime < 2)

		local Is_Normal_M1 = (self.Condition == nil)

		VictimWasTimestopped = VictimCombat:GetState("Timestopped")

		local Validated, Type : string = self:Afflict(VictimLuaPlayer, {
			DontBypassIFrames = (self.Condition ~= "Down" and {"Grab", "Backdash"}),

			BreakBlock = (StandHandler ~= nil and 
				(self.Count > 3 or Parried) or 
				(self.Condition == "Down" or Parried)
			),

			Damage = (StandHandler ~= nil and 
				(Parried and 10 or (self.Count > 2 and 6 or 5)) or 
				(Parried and 6 or (self.Count > 2 and 4 or 3)) 
			),

			CanPerfectBlock = Is_Normal_M1,
			DontHitRagdolled = Is_Normal_M1,
			YDifferenceValue = not Is_Normal_M1 and VictimLuaCharacter.HumanoidAlive and 0 or nil,
			DontHitDeadPeople = Is_Normal_M1,
			DontRestartRespawnTimer = not Is_Normal_M1,
		})

		if Type == "Blocked" then
			self.Combat:StackState("CannotM1", true, self.TimeUntilCanBlock)
			self.Combat.Values.Jump:Change(true, self.TimeUntilCanBlock)
		end

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

			if Parried then
				BlockAttack.PerfectBlockTime = -1
				BlockAttack:AddCertainCooldown("PerfectBlockCooldown", 1, nil, true)
				self:FireReliableVFX("Global/M1", "Black Flash", VictimLuaCharacter.RootPart, self.Condition)
			end

			if self.Condition == "Up" then
				self:FireReliableVFX("Global/M1", "Uppercut", VictimLuaCharacter.RootPart, CharacterName)

				local VictimVelocityObject = self:VelocityOn(VictimCombat)
				VictimVelocityObject.Settings.RemoveTime = 0.1
				VictimVelocityObject.Settings.Velocity = Vector3.yAxis * ((StandHandler ~= nil) and 70 or 57.5)
				VictimVelocityObject:Fire()

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true;
					Ragdoll = 2;
				})

				--VictimCombat.Ragdoll:Toggle(true, 2)
				VictimLuaCharacter.RootPart.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(40, -40), 0, Utility.Seed:NextNumber(40, -40))

			elseif self.Condition == "Down" then
				self.Downslammed = true

				self.Combat.Hitbox:Destruction(Hitbox.Params.Offset, Vector3.new(4, 15, 4), 1)
				self:FireReliableVFX("Global/M1", "Down Slam", VictimLuaCharacter.RootPart, CharacterName)
				VictimLuaCharacter.RootPart.CFrame *= CFrame.new(0, -0.5, 1) * CFrame.Angles(math.rad(-45), 0, 0)

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true;
					Ragdoll = 2;
				})

				--VictimCombat.Ragdoll:Toggle(true, 2)

				local VictimVelocityObject = self:VelocityOn(VictimCombat)
				VictimVelocityObject.Settings.RemoveTime = 0.1
				VictimVelocityObject.Settings.Velocity = Vector3.yAxis * -60
				VictimVelocityObject:Fire()
			else
				if Parried then
					VictimCombat.Animations.BlackFlashed:Play()

					if (StandHandler ~= nil) then
						VictimCombat:Stun(1.25)
					else
						VictimCombat:AntiTeamStun(self.LuaPlayer.Player, 1.25)
					end
				else
					self:FireReliableVFX("Stardust Crusader/Heavy Barrage", "BarrageHit", VictimLuaCharacter.Torso)

					if (self.Count == 4) then

						if CharacterStats and CharacterStats.M1 and CharacterStats.LastM1KnocksUp then
							local VictimVelocityObject = self:VelocityOn(VictimCombat)
							VictimVelocityObject.Settings.RemoveTime = 0.1
							VictimVelocityObject.Settings.Velocity = KnockbackVelocity * 40 + Vector3.yAxis * 40
							VictimVelocityObject:Fire()
						else
							local VictimVelocityObject = self:VelocityOn(VictimCombat)
							VictimVelocityObject.Settings.RemoveTime = 0.1
							VictimVelocityObject.Settings.Velocity = KnockbackVelocity * 40 + Vector3.yAxis * 8.5
							VictimVelocityObject:Fire()
						end

						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true;
							Ragdoll = 2;
						})

						--VictimCombat.Ragdoll:Toggle(true, 2)
					else
						VictimCombat:PlayRandomHitReaction()

						if (StandHandler ~= nil) then
							VictimCombat:Stun(1)
						else
							VictimCombat:AntiTeamStun(self.LuaPlayer.Player, 0.9)
						end

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
			end

			if (self.Count == 4) then
				self:Close()
			end
		end
	end)

	self.Thread.OnClosed:Connect(function()
		if self.Count > 3 then
			self:AddCooldown(0.75, true)
		end

		self.Combat:StackState("M1ing", false)
	end)

	if (self.Condition ~= nil) then
		self:FireReliableVFX("Global/M1", "SpecialSwing", self.LuaCharacter.RootPart, self.Condition, CharacterName)
	else
		self.Thread.Job:Task(Animation:GetMarkerReachedSignal("swing"):Once(function()
			if self.Combat.Attacks.Weapons then
				self:FireReliableVFX("Global/M1", "Swing", self.LuaCharacter.RootPart, self.Count, CharacterName, AttackingWith, self.Combat.Attacks.Weapons.CurrentlyUsing)
			else
				self:FireReliableVFX("Global/M1", "Swing", self.LuaCharacter.RootPart, self.Count, CharacterName, AttackingWith)
			end
		end))
	end

	self.Thread.Job:Task(Animation:GetMarkerReachedSignal("hit"):Once(function(Parameter : string?)
		self.InWindup = false
		Hitbox:BeginCast(0.1)

		if self.Count > 3 and not self.Hit then
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

		if (self.Condition ~= nil) then
			local StopAnimConnection : RBXScriptConnection; StopAnimConnection = self.Combat:GetStateChanged("Attacking"):Connect(function(Value : boolean)
				if Value then
					StopAnimConnection:Disconnect()
					Animation:Stop()
				end
			end)

			Animation.Stopped:Once(function()
				StopAnimConnection:Disconnect()
			end)
		end

		self.Combat.Values.Jump:Add(0.05)

		if (self.Condition == nil) then
			if CharacterStats and CharacterStats.M1 and CharacterStats.M1.EndlagAfterSwing then
				task.wait(CharacterStats.M1.EndlagAfterSwing)
			else
				task.wait(0.2)
			end
		else
			task.wait(0.15)
		end

		if self.Count > 3 and (not self.Hit and not VictimWasTimestopped) then
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
end

return CustomAttack;