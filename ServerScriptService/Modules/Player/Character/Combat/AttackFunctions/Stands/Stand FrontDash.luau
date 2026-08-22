local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage.Remotes
local CombatRemotes = Remotes.Combat

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local CustomAttack = {};

function CustomAttack.Activate(self)
	local StandHandler = self.Combat:GetStand();

	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self:AddCertainCooldown("Front&Back Dash", 6)

	self.FrontDashHit = false

	local LoopAnimation 
	local HitAnimation

	local LastLookVector : Vector3 = self.LuaCharacter.RootPart.CFrame.LookVector
	local LastPosition : Vector3 = self.LuaCharacter.RootPart.Position

	local Decay = math.rad(6.5)
	local AngleTotal = 0

	local NewJob = Job.new()
	local ValidatedType = ""

	local ProximityHitbox = self:CreateHitbox(false, true);

	local ProximitySize = Vector3.new(5.5, 7, 10)
	local ProximityOffset = CFrame.new(0, 0, -5)

	local SwingSize = Vector3.new(5.5, 7, 10)
	local SwingOffset = CFrame.new(0, 0, -5)

	ProximityHitbox.Params.Offset = ProximityOffset
	ProximityHitbox.Params.Size = ProximitySize
	ProximityHitbox.Params.DestroyOnEndCast = false

	if (StandHandler ~= nil) then
		local StandDirectory = StandHandler:GetAnimationDirectory()
		local StandDashes = StandDirectory and StandDirectory.Dash
		local StandM1s = StandDirectory and StandDirectory.M1

		if StandM1s then
			for _, Animation : AnimationTrack in StandM1s do
				if (Animation.Animation ~= nil and Animation.IsPlaying) then
					Animation:Stop()
				end
			end
		end

		LoopAnimation = StandDashes.Stand
		HitAnimation = StandDashes.Hit

		local User = self.LuaCharacter.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks["Stardust Crusader"]["Star Platinum"].Dash.User)
		User:Play()

		StandHandler.Weld:SetAttribute("Aggression", 0)
		StandHandler:MoveStand(CFrame.identity, 0.5)

		self.Thread.OnClosed:Connect(function()
			StandHandler.Weld:SetAttribute("Aggression", 0.04)
			StandHandler:MoveStandByAction("Idle", 1.25)

			User:Stop()
			User:Destroy()
			User = nil
		end)
	else
		local AnimationDirectory = self:GetAnimationDirectory()
		LoopAnimation = AnimationDirectory.Loop
		HitAnimation = AnimationDirectory.Hit
	end

	local function DisconnectAll()
		NewJob:Clean()

		ProximityHitbox:EndCast()
		ProximityHitbox:Destroy()

		self.LuaPlayer.Replication.Attributes:SetAttribute("ForwardDash", nil)
	end

	self.Thread.OnClosed:Connect(function()
		if HitAnimation and HitAnimation.IsPlaying then
			HitAnimation:Stop(0.2)
		end

		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.OnCancelled:Connect(DisconnectAll)

	local function LungeArm(Success : boolean)
		if self.Thread.Cancelled then return end

		LoopAnimation:Stop()
		HitAnimation:Play()

		task.wait(0.05)

		if self.Thread.Cancelled then return end

		local Hitbox = self:CreateHitbox(false);
		Hitbox.Params.Offset = SwingOffset
		Hitbox.Params.Size = SwingSize
		Hitbox.Params.DestroyOnEndCast = false

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Finisher = VictimLuaCharacter.Humanoid.Health < 6

			local Validated, Type : string = self:Afflict(VictimLuaPlayer, {
				DontBypassIFrames = {"Grab", "Backdash"},
				DontRestartRespawnTimer = true,
				Damage = 6,
				Velocity = Finisher and {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 80 + Vector3.yAxis * 47.5, 0.1} or nil,
				YDifferenceValue = -2
			})

			ValidatedType = Type

			if Validated then
				self.FrontDashHit = true

				local M1Attack, M1Matched = self.Combat:MatchAttack("M1", Enum.UserInputType.MouseButton1)

				local ValuesThatCauseAPush = 
					AngleTotal > math.rad(150) or  -- if u rotate too much
					(LastPosition - VictimLuaCharacter.RootPart.Position).Magnitude < 17.5 or -- if u hit them too close
					VictimCombat:GetState("ForceDashPush") or
					VictimCombat:GetState("StunImmunity") or -- nerfs wake-up front dash
					(VictimCombat:GetState("Ragdolled") and self.Combat:CalculateYDifference(VictimLuaPlayer) > -2) -- makes uppercut front dash possible in general

				self:FireReliableVFX("Stardust Crusader/Forward Dash", "Hit", self.LuaCharacter.Model, VictimLuaCharacter.Model, ValuesThatCauseAPush)

				local function Bleed()
					local BloodSteps = 12
					local BloodTime = 0.2

					task.spawn(function()
						for Index = 1, BloodSteps do
							self.Combat:DealDamage(VictimLuaPlayer, 1.5)
							task.wait(BloodTime)
						end
					end)

					self:FireReliableVFX("Stardust Crusader/Heavy Barrage", "Bleed", VictimLuaCharacter.Torso, BloodSteps, BloodTime)
				end

				if Finisher then
					self.Combat:VictimImpactGround(VictimLuaPlayer)
					Bleed()

				elseif (ValuesThatCauseAPush == true) then 
					local RollDuration = 1.1

					local ClampedPing = math.clamp(VictimLuaPlayer:GetPing(), 0, 1)
					VictimCombat:StackState("BackdashIFrames", true, (RollDuration / 2) + ClampedPing) -- so u cant shove tech

					self.Combat:TSBPushVictim(VictimLuaPlayer, {
						OverridePrevious = true,
						LookVectorInsteadOfDifference = (self.Combat:CalculateYDifference(VictimLuaPlayer) < -2), -- patches really overpowered tech
						LandedRollVelocityZ = 175,
						LandedRollDuration = RollDuration,
					})

					Bleed()
				else
					VictimCombat:TrueStun(1)

					if self.Combat:CalculateHitAngle(VictimLuaPlayer) >= math.rad(90) then
						VictimCombat.Animations.HitReactions.Back:Play()
					else
						VictimCombat.Animations.HitReactions.Front:Play()
					end

					local KnockbackVelocity : Vector3 = (VictimLuaCharacter.RootPart.Position - self.LuaCharacter.RootPart.Position)
					local MaxForce = Vector3.new(1, 0, 1) * 80000

					local AttackerVelocityObject = self.Combat:Velocity()
					AttackerVelocityObject.Settings.RemoveTime = 0.3
					AttackerVelocityObject.Settings.MaxForce = MaxForce
					AttackerVelocityObject.Settings.Velocity = KnockbackVelocity.Unit * 5

					local VictimVelocityObject = self:VelocityOn(VictimCombat)
					VictimVelocityObject.Settings.RemoveTime = 0.3
					VictimVelocityObject.Settings.MaxForce = MaxForce
					VictimVelocityObject.Settings.Velocity = KnockbackVelocity.Unit * 5

					AttackerVelocityObject:Fire()
					VictimVelocityObject:Fire()
				end
			end
		end)

		local CF : CFrame = Hitbox:GetCFrame() * CFrame.new(0, 1, 0)

		self.Combat.Hitbox:CreateHavocReplicated({
			parameters = {
				origin = CF,
				size = SwingSize, 
				shape = "Box", 
				block_size = 4, 
			},
			crater = {},
			debris = {
				scale = 0.9,
				velocity = function(cube)
					cube.AssemblyLinearVelocity = (CF.LookVector * (70 + cube:GetMass() / 2)) + Random.new():NextUnitVector() * 5;
				end 
			},
		})

		Hitbox:BeginCast(0.08)

		Hitbox.Events.OnCastEnded:Connect(function()
			if self.ActivatedFinisher then return end

			local Endlag = 0.1

			if ValidatedType == "Blocked" or ValidatedType == "Perfect Blocked" then
				Endlag = 0.55

				self.Combat:StackState("GotDashBlocked", true, Endlag)
				HitAnimation:AdjustSpeed(0.35)

			elseif not self.FrontDashHit then
				Endlag = 0.45
				HitAnimation:AdjustSpeed(0.475)
			end

			task.delay(Endlag, self.Close, self)
		end)
	end

	ProximityHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			DontCheckBlock = true,
			DontRestartRespawnTimer = true,
			YDifferenceValue = -2
		})

		if Validated then
			DisconnectAll()
			LungeArm(true)
		end
	end)

	LoopAnimation:Play()

	if not self.LuaPlayer.IsNPC then
		CombatRemotes.FrontDashOutput:FireClient(self.LuaPlayer.Player)
	else
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 0.895
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 150
		VelocityObject:Fire()

		NewJob:Task(VelocityObject)
	end

	self.LuaPlayer.Replication.Attributes:SetAttribute("ForwardDash", true)
	self:FireReliableVFX("Global/Dashing/Forward Dash", "Start", self.LuaCharacter.RootPart, self.LuaCharacter.RightArm)
	self:FireVFX("Global/Dashing/Forward Dash", "DefaultStart", self.LuaCharacter.RootPart, self.LuaCharacter.RightArm)

	NewJob:Task(task.delay(self.FrontDashLength, function()
		LoopAnimation:AdjustSpeed(1)

		DisconnectAll()
		LungeArm(false)
	end))

	local SimulatedRoot : BasePart = self.Combat:GetSimulatedRoot()

	NewJob:Task(RunService.PostSimulation:Connect(function()
		local CF = SimulatedRoot.CFrame
		local NewLookVector = CF.LookVector

		AngleTotal += LastLookVector:Angle(NewLookVector) - Decay
		LastLookVector = NewLookVector
	end))

	task.wait(0.2)

	LoopAnimation:AdjustSpeed(0.75)

	task.wait(0.125)

	ProximityHitbox:BeginCast()
	LoopAnimation:AdjustSpeed(0.5)
end

return CustomAttack;