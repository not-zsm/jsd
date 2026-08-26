local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

----------------------------------------------------------------------------------



local Shared = replicatedStorage.modules.shared
local SharedUtilities = Shared.Utilities

local Utility = require( SharedUtilities.Utility )
local EventService = require( SharedUtilities.EventService )
local Job = require( SharedUtilities.Job )

local MovementReplicatorSettings = require( replicatedStorage.modules.shared.movementReplicator.Settings )

----------------------------------------------------------------------------------

local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

--function Attack:GetAnimationDirectory()
--	self:UpdateAnimationDirectory()

--	local CustomDirectory = self.Combat:HasACharacter() and self.Combat.CurrentCharacter.Info.DashAnimationDirectory

--	if CustomDirectory then
--		return CustomDirectory(self) 
--	end

--	return self.AnimationDirectory
--end

function Attack:Pretrigger(Extra : {})
	if (Extra ~= nil and typeof(Extra) == "table") then
		if (Extra.DashDirection ~= nil and typeof(Extra.DashDirection) == "string") then
			self.Direction = Extra.DashDirection
		end

		self.ClientSentWallComboRaycast = Extra.WallCombo
		self.ClientSentEvasive = Extra.Evasive
	end
end

Attack.BasinConditions = nil

function Attack:NPCCanEvasive()
	return not self.Combat:GetState("CannotDash") and not self:CertainCooldownExists("Evasive") and not self:CertainCooldownExists("Side Dash") and self.Combat:GetState("EvasiveState") 
end

function Attack:InEvasiveState()
	return not self.LuaPlayer.IsNPC and self.ClientSentEvasive and typeof(self.ClientSentEvasive) == "boolean" and self.Combat:GetState("EvasiveState")
end

function Attack:ConditionToActivate(Direction : string)
	if self:InEvasiveState() then
		return not self.Combat:GetState("Evasived")--not self.Combat:GetState(`Cannot{self.NameNoSpaces}`)
	end
	
	local Conditions = 
		not self.Combat:GetState("Stunned") and 
		not self.Combat:GetState("Attacking") and
		not self.Combat:GetState("Ragdolled") and 
		not self.Combat:GetState("Backdashing") and 
		not self.Combat:GetState("Dashing") and
		not self.Combat:GetState(`Cannot{self.NameNoSpaces}`)

	if self.LuaPlayer.IsNPC and Direction then
		return Conditions and not self:CertainCooldownExists(Direction)
	else
		if self.Direction == "Front" and self:CertainCooldownExists("AntiFrontDashExploit") then
			warn("Anti exploit triggered by:", self.LuaPlayer.PlayerName)
			return false
		end

		return Conditions
	end
end

function Attack:Evasive()
	local Was = ""

	if self.Combat:GetState("Ragdolled") then
		Was = "Ragdolled"

	elseif (self.Combat:GetState("Pushed") and self.Combat.RemoveCurrentPush ~= nil) then
		Was = "Pushed"
	end

	if self.LuaPlayer.IsNPC then
		self:AddCertainCooldown("Evasive", 30)
		self:AddCertainCooldown("Side Dash", 2)
		self:AddCertainCooldown("FrontBack Dash", 6)
	else
		network.evasiveOutput.sendTo({ direction = self.Direction, was = Was }, self.LuaPlayer.Player)
	end

	self.Combat:StackState("Evasived", true, self.EvasiveIFramesTime)
	self.Combat:StackState("GrabIFrames", true, self.EvasiveIFramesTime)
	self.Combat:ResetStun()

	if Was == "Ragdolled" then
		self.Combat.Ragdoll:_Toggle(false, true)

	elseif Was == "Pushed" then
		self.Combat.RemoveCurrentPush()
		
		if self.Combat.Animations.Push.IsPlaying then
			self.Combat.Animations.Push:Stop()
		end
	end

	task.spawn(function()
		for _, Item in ipairs(CollectionService:GetTagged("RemoveOnEvasive")) do
			local RemoveOn = Item:GetAttribute("RemoveOn")

			if RemoveOn and RemoveOn == self.LuaPlayer.Player.Name then
				Item:Destroy()
			end
		end
	end)

	task.spawn(function()
		for _, Item in ipairs(self.LuaCharacter.RootPart:GetChildren()) do
			if Item:HasTag("RemoveOnEvasive") then
				Item:Destroy()
			end
		end
	end)

	self:FireReliableVFX("Global/Dashing/Evasive", "Start", self.LuaCharacter.RootPart, self.EvasiveIFramesTime)

	return true
end

function Attack:AttemptEvasive()
	if self:InEvasiveState() then
		self:Evasive()
	end
end

function Attack:WallCombo(Raycast : RaycastResult, VictimLuaPlayer)
	local WallComboInfo = self.Combat.CurrentCharacter.Info.WallCombo
	local FinisherWallComboInfo = self.Combat.CurrentCharacter.Info.WallComboFinisher

	local VictimLuaCharacter = VictimLuaPlayer.Character
	local VictimCombat = VictimLuaCharacter.Combat

	self.Combat:StackState("Attacking", true)

	self.Combat:StackState("WallComboing", true)
	VictimCombat:StackState("WallComboed", true)
	
	VictimLuaCharacter:StopRespawnTimer()

	local Info = WallComboInfo

	if (FinisherWallComboInfo and FinisherWallComboInfo.Condition(VictimLuaPlayer) == true) then
		Info = FinisherWallComboInfo
	end

	if not Info.DontAnchor then
		if not Info.DontPutIFrames then
			self.Combat:StackState("GrabIFrames", true)
			VictimCombat:StackState("GrabIFrames", true)
		end

		VictimCombat:TrueStun()
		VictimCombat:ResetState("StunImmunity")
		VictimCombat.Ragdoll:ForceToggleOff()

		self.Thread.Job:Task(Utility.StopAutoRotate(self.LuaCharacter.Humanoid))
		self.Thread.Job:Task(Utility.StopAutoRotate(VictimLuaCharacter.Humanoid))

		self.LuaCharacter:Anchor(true, true)
		VictimLuaCharacter:Anchor(true, true)

		self.Combat:CombatTag()
		VictimCombat:CombatTag()
	end

	self.Thread.OnClosed:Connect(function()
		network.wallComboOutput.sendTo(nil, self.LuaPlayer.Player)

		VictimLuaCharacter:RestartRespawnTimer()
		
		self.Combat:StackState("WallComboing", false)
		VictimCombat:StackState("WallComboed", false)

		self.Combat:StackState("Attacking", false)
	end)
	
	local Root : BasePart = self.Combat:GetSimulatedRoot()

	local Normal = (Raycast.Normal * Vector3.new(1, 0, 1)).Unit
	local FloorRaycast = workspace:Raycast(Root.Position + (Vector3.yAxis * 3), Vector3.yAxis * -40, Utility.GroundParams)
	local AwayTheWall = (Raycast.Position + Normal * (Info.DistanceFromWall or 6))
	local Height = if FloorRaycast then FloorRaycast.Position.Y + 3 else AwayTheWall.Y;

	local WallCFrame : CFrame = Utility.VectorToRotation(-Normal) + Vector3.new(AwayTheWall.X, Height, AwayTheWall.Z)

	if not Info.DontAnchor then
		Info.VictimOffset = Info.VictimOffset or CFrame.identity

		self:FireReliableVFX("Global/Wall Combo", "Transition", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, WallCFrame, Info.VictimOffset)

		task.delay(0.2, function()
			self.LuaCharacter.RootPart.CFrame = WallCFrame
			VictimLuaCharacter.RootPart.CFrame = WallCFrame * Info.VictimOffset
		end)
	else
		self.LuaCharacter.RootPart.CFrame = WallCFrame
	end

	Info.Function(self, VictimLuaPlayer, Raycast)
end

function Attack:AttemptWallCombo()
	--if not self.Combat:GetState("WallComboAttempts") then
	--	return false
	--end

	if (self.ClientSentWallComboRaycast == nil or typeof(self.ClientSentWallComboRaycast) ~= "table" or self.Combat.CurrentCharacter.Info.WallCombo == nil) then 
		return false
	end

	local Raycast : {Position : Vector3?, Normal : Vector3?} = self.ClientSentWallComboRaycast

	if (Raycast.Position == nil or Raycast.Normal == nil) then 
		return false
	end

	local Root : BasePart = self.Combat:GetSimulatedRoot()
	local Magnitude = (Raycast.Position - Root.Position).Magnitude

	if (Magnitude > 25) then
		return false
	end

	local M1Attack, M1Matched = self.Combat:MatchAttack("M1", Enum.UserInputType.MouseButton1)

	if not M1Matched then
		return false
	end

	local WallComboVictimLuaPlayer = M1Attack.WallComboVictim

	if (WallComboVictimLuaPlayer == nil) then 
		return false
	end

	M1Attack.WallComboVictim = nil

	local WallComboVictimLuaCharacter = WallComboVictimLuaPlayer.Character
	local WallComboVictimCombat = WallComboVictimLuaCharacter.Combat

	if self.Combat.Hitbox:ValidatePlayer(WallComboVictimLuaPlayer) and not WallComboVictimCombat:Has_IFrames() then 
		return true, Raycast, WallComboVictimLuaPlayer
	else
		return false
	end
end

function Attack:Activate()
	if self.Direction == "Front" then

		if (self.ClientSentWallComboRaycast ~= nil) then

			local WallComboSuccessful, Raycast, WallComboVictimLuaPlayer = self:AttemptWallCombo()

			if WallComboSuccessful then
				self:WallCombo(Raycast, WallComboVictimLuaPlayer)
			else
				if not self.LuaPlayer.IsNPC then
					network.wallComboFail.sendTo(nil, self.LuaPlayer.Player)
				end
			end
		else
			local CharacterInfo : {}? = self.Combat:HasACharacter() and self.Combat.CurrentCharacter.Info or nil
			local UseDefault = true;
			
			if CharacterInfo and CharacterInfo.Dash and CharacterInfo.Dash.CustomFunction then
				local Result = self:ActivateCustomFunction(CharacterInfo.Dash.CustomFunction);
				
				if Result ~= "Default" then
					UseDefault = false;
				end
			end
			
			if UseDefault then
				local Stand = self.Combat:GetStand();

				if Stand and Stand.Summoned then
					self:ActivateCustomFunction("Stands/Stand FrontDash");
				else
					self:FrontDash();
				end;
			end;
		end;

	elseif self.Direction == "Back" then
		self:AttemptEvasive()

		local BackdashLength = 1.1

		if self.LuaPlayer.IsNPC and self.Animations.Back then
			self.Animations.Back:Play()
			self:AddCertainCooldown("FrontBack Dash", 6)

			local MaxForce = Vector3.new(1, 0, 1) * 80000

			local VelocityObject = self.Combat:Velocity()
			VelocityObject.Settings.Duration = 0.85
			VelocityObject.Settings.MaxForce = MaxForce
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = -60
			VelocityObject:Fire()

			self.Thread.Job:Task(task.delay(0.47, function()
				VelocityObject:Destroy()

				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 0.8
				VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
				VelocityObject.Settings.MaxForce = MaxForce
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = -110
				VelocityObject:Fire()

				self.Thread.OnCancelled:Connect(function()
					VelocityObject:Destroy()
				end)
			end))

			self.Thread.OnCancelled:Connect(function()
				VelocityObject:Destroy()
			end)
		end

		self.Combat:StackState("Backdashing", true)
		self.Combat:StackState("BackdashIFrames", true)

		self.LuaPlayer.Replication.Attributes:SetAttribute("BackwardDash", true)
		self:FireReliableVFX("Global/Dashing/Backward Dash", "Start", self.LuaCharacter.RootPart)

		self.Thread.Job:Task(task.delay(0.6, function()
			self.Combat:StackState("BackdashIFrames", false)
		end))

		self.Thread.OnCancelled:Connect(function()
			network.cancelDash.sendTo(nil, self.LuaPlayer.Player)
		end)

		self.Thread.OnClosed:Connect(function()
			self.LuaPlayer.Replication.Attributes:SetAttribute("BackwardDash", nil)
			self.Combat:StackState("BackdashIFrames", false)
			self.Combat:StackState("Backdashing", false)
		end)

		task.wait(BackdashLength - self.LuaPlayer:GetPing())

		self:Close()
	else
		self:AttemptEvasive()
		self.Combat:StackState("Dashing", true)

		if self.LuaPlayer.IsNPC then
			self.Animations[self.Direction]:Play()
			self:AddCertainCooldown("Side Dash", 2)

			local VelocityObject = self.Combat:Velocity()
			VelocityObject.Settings.Duration = 0.675
			VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration / 1.9
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.X = self.Direction == "Left" and -185 or 185
			VelocityObject:Fire()

			self.Thread.Job:Task(VelocityObject)
		end

		self.Thread.OnCancelled:Connect(function()
			network.cancelDash.sendTo(nil, self.LuaPlayer.Player)
		end)

		self.Thread.OnClosed:Connect(function()
			self.LuaPlayer.Replication.Attributes:SetAttribute("SideDash", nil)
			self.Combat:StackState("Dashing", false)
		end)

		self.LuaPlayer.Replication.Attributes:SetAttribute("SideDash", true)
		self:FireReliableVFX("Global/Dashing/Side Dash", "Start", self.LuaCharacter.RootPart)

		task.wait(0.33 - self.LuaPlayer:GetPing())

		self:Close()
	end
end

--[[
	The jump cancel. It arrives as a release on useMove, which Actions routes
	to Deactivate.

	It has to come over the network. Replication.Attributes is a Configuration
	the server makes and parents to the Player, so a client writing ForwardDash
	on it changes that client's copy and nothing else -- the server never hears,
	and the hitbox it owns keeps casting. That is why the cancel looked like it
	worked: the client's own listener saw its own write and stopped the velocity.
--]]
function Attack:Deactivate()
	if (self.Direction ~= "Front") then return end
	if not self:ThreadAvailable() then return end

	self:Cancel()
end

function Attack:FrontDash()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self:AddCertainCooldown("FrontBack Dash", 6)
	self.FrontDashHit = false

	local AnimationDirectory = self:GetAnimationDirectory()

	local LoopAnimation : AnimationTrack = AnimationDirectory.CMERE
	local HitAnimation : AnimationTrack = AnimationDirectory.CMEREhit

	local FrontDashInfo = self.Combat.CurrentCharacter.Info.FrontDash

	local LastLookVector : Vector3 = self.LuaCharacter.RootPart.CFrame.LookVector
	local LastPosition : Vector3 = self.LuaCharacter.RootPart.Position

	local Decay = math.rad(6.5)
	local AngleTotal = 0

	local NewJob = Job.new()
	local ValidatedType = ""

	local ProximityHitbox = self:CreateHitbox(false, true);

	local ProximitySize = nil
	local ProximityOffset = nil

	local SwingSize = nil
	local SwingOffset = nil

	if MovementReplicatorSettings.use_replicator then
		ProximitySize = Vector3.new(5.35, 4, 7.3) -- Vector3.new(5.35, 7, 7)
		ProximityOffset = CFrame.new(0, -0.5, -1) -- -2

		SwingSize = Vector3.new(5.35, 3.5, 7.5)  -- Vector3.new(5.35, 6.5, 7.5)
		SwingOffset =  CFrame.new(0, -0.5, -3)
	else
		ProximitySize = Vector3.new(5.35, 4, 8.1) -- Vector3.new(5.35, 7, 8.1)
		ProximityOffset = CFrame.new(0, -0.5, -2.85)

		SwingSize = Vector3.new(5.35, 3.5, 7.5) -- Vector3.new(5.35, 6.5, 8.1) 
		SwingOffset = CFrame.new(0, -0.5, -3.5)
	end

	ProximityHitbox.Params.Offset = ProximityOffset
	ProximityHitbox.Params.Size = ProximitySize
	ProximityHitbox.Params.DestroyOnEndCast = false

	local function DisconnectAll()
		NewJob:Clean()

		ProximityHitbox:EndCast()
		ProximityHitbox:Destroy()

		if (FrontDashInfo ~= nil and FrontDashInfo.OnEnd ~= nil) then
			task.spawn(FrontDashInfo.OnEnd, self)
		end

		self.LuaPlayer.Replication.Attributes:SetAttribute("ForwardDash", nil)
	end

	self.Thread.OnClosed:Connect(function()
		self:AddCertainCooldown("AntiFrontDashExploit", 1)

		if HitAnimation and HitAnimation.IsPlaying then
			HitAnimation:Stop(0.2)
		end

		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.OnCancelled:Connect(DisconnectAll)

	local function LungeArm(Success : boolean)
		if not self:ThreadAvailable() or self.Thread.Cancelled then return end

		LoopAnimation:Stop()
		HitAnimation:Play()
		
		if (FrontDashInfo ~= nil and FrontDashInfo.HitAnimStarted) then
			self:FireReliableVFX(`{self.Combat.CurrentCharacter.Name}/Forward Dash`, "HitAnimStarted", self.LuaCharacter.Model)
		end

		task.wait(0.05)

		if not self:ThreadAvailable() or self.Thread.Cancelled then return end

		local Hitbox = self:CreateHitbox(false);
		Hitbox.Params.Offset = SwingOffset
		Hitbox.Params.Size = SwingSize
		Hitbox.Params.DestroyOnEndCast = false

		if not MovementReplicatorSettings.use_replicator then
			self.Thread.Job:Task(self.Combat.Hitbox:OffsetHitboxOnVelocity(Hitbox, 25))
		end

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			--self.ActivatedFinisher = VictimLuaCharacter.Humanoid.Health <= 4

			local Validated, Type : string = self:Afflict(VictimLuaPlayer, {
				DontBypassIFrames = {"Grab", "Backdash"},
				DontRestartRespawnTimer = true,
				Damage = not self.ActivatedFinisher and 4,
				YDifferenceValue = -2,
				CannotBeAdapted = true
			})

			ValidatedType = Type

			if Validated then
				self.LastTimeFrontDashHit = os.clock()
				self.FrontDashHit = true

				if (FrontDashInfo ~= nil and FrontDashInfo.TryCustomHit) then
					self:FireReliableVFX(self.Combat.CurrentCharacter.Name .. "/Forward Dash", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
				else
					self:FireReliableVFX("Global/Dashing/Forward Dash", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
				end

				if self.ActivatedFinisher then
					HitAnimation:Stop(0.3)

					if (self.Animations.Finisher == nil) then return end

					self.Animations.Finisher:Play(0.3)

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("throw"):Connect(function()
						self:Close()
					end))
				else
					local M1Attack, M1Matched = self.Combat:MatchAttack("M1", Enum.UserInputType.MouseButton1)

					local ValuesThatCauseAPush = 
						AngleTotal > math.rad(150) or  -- if u rotate too much
						(LastPosition - VictimLuaCharacter.RootPart.Position).Magnitude < 17.5 or -- if u hit them too close
						VictimCombat:GetState("ForceDashPush") or
						VictimCombat:GetState("StunImmunity") or -- nerfs wake-up front dash
						(VictimCombat:GetState("Ragdolled") and self.Combat:CalculateYDifference(VictimLuaPlayer) > -2) -- makes uppercut front dash possible in general
						--(M1Matched and time() - M1Attack.HitTime <= 1.5) -- nerfs 3 m1 front dash
						
					if (ValuesThatCauseAPush == true) then 
						local RollDuration = 0.9

						local ClampedPing = math.clamp(VictimLuaPlayer:GetPing(), 0, 1)
						VictimCombat:StackState("BackdashIFrames", true, (RollDuration / 2) + ClampedPing) -- so u cant shove tech

						self.Combat:TSBPushVictim(VictimLuaPlayer, {
							OverridePrevious = true,
							LookVectorInsteadOfDifference = (self.Combat:CalculateYDifference(VictimLuaPlayer) < -2), -- patches really overpowered tech
							DontBeginAoeHitbox = true,
							LandedRollVelocityZ = 160,
							LandedRollDuration = RollDuration,
							DurationMultiplier = 0.8, -- nerfs stun a little
							AntiWallCombo = true
						})
					else
						VictimCombat:TrueAntiTeamStun(self.LuaPlayer.Player, 1)

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
			end
		end)

		local CF : CFrame = Hitbox:GetCFrame() * CFrame.new(0, 1, 0)

		self.Combat.Hitbox:CreateHavocReplicated({
			parameters = {
				origin = CF,
				size = SwingSize, 
				shape = "Box", 
				--block_size = 4, 
			},
			crater = {},
			debris = {
				scale = 0.9,
				velocity = function(cube)
					return (CF.LookVector * (65 + cube:GetMass() / 2)) + Random.new():NextUnitVector() * 5;
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
				Endlag = 0.4
				HitAnimation:AdjustSpeed(0.5)
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
			YDifferenceValue = -2,
			CannotBeAdapted = true
		})

		if Validated then
			DisconnectAll()
			LungeArm(true)
		end
	end)

	local StartSpeed = LoopAnimation.Animation:GetAttribute("StartSpeed") or 1.5
	local MiddleSpeed = LoopAnimation.Animation:GetAttribute("MiddleSpeed") or 0.75
	local PauseSpeed = LoopAnimation.Animation:GetAttribute("PauseSpeed") or 0.1

	LoopAnimation:Play(0.05, 1, FrontDashInfo and (FrontDashInfo.StartSpeed or StartSpeed) or StartSpeed)

	if not self.LuaPlayer.IsNPC then
		network.frontDashOutput.sendTo(nil, self.LuaPlayer.Player)
	else
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true

		--[[
			Full speed for the first 60%, then off a cliff.

			Z is the peak now rather than 84.5% of it, so 144/1.67 x 0.845 keeps
			the launch exactly as it was. Duration comes down because it has to:
			this shape over the old 0.845 would have carried 55 studs against the
			26 it does now.
		--]]
		VelocityObject.Settings.Duration = 0.4
		VelocityObject.Settings.Hold = 0.6
		VelocityObject.Settings.Falloff = 3
		VelocityObject.Settings.Z = (144/1.67) * 0.845

		VelocityObject:Fire()

		NewJob:Task(VelocityObject)
	end

	self.LuaPlayer.Replication.Attributes:SetAttribute("ForwardDash", true)
	self:FireReliableVFX("Global/Dashing/Forward Dash", "Start", self.LuaCharacter.RootPart)

	if (FrontDashInfo ~= nil and FrontDashInfo.TryCustomStart) then
		self:FireReliableVFX(self.Combat.CurrentCharacter.Name .. "/Forward Dash", "Start", self.LuaCharacter.RootPart)
	else
		self:FireVFX("Global/Dashing/Forward Dash", "DefaultStart", self.LuaCharacter.RootPart, self.LuaCharacter.RightArm)
	end

	if (FrontDashInfo ~= nil and FrontDashInfo.OnStart ~= nil) then
		coroutine.wrap(FrontDashInfo.OnStart)(self)
	end

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

	if not MovementReplicatorSettings.use_replicator and not self.LuaPlayer.IsNPC and self.LuaPlayer.Data.Profile.Data.Settings.Dash_Hitbox_Compensate == true then
		NewJob:Task(
			self.Combat.Hitbox:OffsetHitboxOnVelocity(ProximityHitbox, 20)
		)
	end

	task.wait(FrontDashInfo and (FrontDashInfo.MiddleTime or 0.2) or 0.2)

	LoopAnimation:AdjustSpeed(FrontDashInfo and (FrontDashInfo.MiddleSpeed or MiddleSpeed) or MiddleSpeed)

	task.wait(0.125)

	ProximityHitbox:BeginCast()
	LoopAnimation:AdjustSpeed(FrontDashInfo and (FrontDashInfo.PauseSpeed or PauseSpeed) or PauseSpeed)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.DontBuffer = true

	self.AnimationSource = "combat"

	self.FrontDashHit = false
	self.FrontDashLength = 0.825

	self.ClientSentEvasive = false
	self.EvasiveIFramesTime = 0.8
	
	self.LastTimeFrontDashHit = -1

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack