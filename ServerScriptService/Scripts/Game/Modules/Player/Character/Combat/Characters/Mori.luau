--[[
    © 2025 swrerm. All Rights Reserved.
    Author: swrerm
    Created: July 16, 2024
    Developed under the group: Jimpee's Cabin

    Licensed for use by Jimpee's Cabin only.
    Redistribution, resale, or unauthorized use of this code, 
    in whole or in part, without express permission from the author
    is strictly prohibited.

    This script is the original work of the author listed above.

    Contacts:
      wboyd4029@gmail.com
      jimpeeisbusiness@gmail.com
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage.Modules
local Remotes = ReplicatedStorage.Remotes

local CombatRemotes = Remotes.Combat

local Job = require( Modules.Shared.Utilities.Job )

local Ultimate_VFX_Module = Modules.Player.Replication.VFX.Mori.Ultimate

local Utility = require( Modules.Shared.Utilities.Utility )
local NumberStack = require( Modules.Shared.Utilities.NumberStack )

local Ultimate_Globals = "Mori/Ultimate_Globals"

local function Pole(self)
	local Pole = script.Pole:Clone()
	Pole.Weld.Part0 = self.LuaCharacter.LeftArm -- why is it left arm chimpee you SUCK
	Pole.Parent = self.LuaCharacter.Model
	
	local SecondaryPole = script.SecondaryPole:Clone()
	SecondaryPole.Name = "SecondaryStaff"
	SecondaryPole.Weld.Part0 = self.LuaCharacter.RootPart
	SecondaryPole.Parent = self.LuaCharacter.Model

	self.LuaCharacter.Mori_Pole = Pole
	self.LuaCharacter.Mori_Secondary_Pole = SecondaryPole
	
	self.OnUltimateEnded:Once(function()
		if self.LuaCharacter.Mori_Pole then
			self.LuaCharacter.Mori_Pole:Destroy()
			self.LuaCharacter.Mori_Pole = nil
		end
		
		if self.LuaCharacter.Mori_Secondary_Pole then
			self.LuaCharacter.Mori_Secondary_Pole:Destroy()
			self.LuaCharacter.Mori_Secondary_Pole = nil
		end
	end)
end

local function Outfit(self)
	local Outfit = require(Ultimate_VFX_Module.Clothes)(self.LuaCharacter.Model)

	self.OnUltimateEnded:Once(function()
		if Outfit then
			Outfit:Destroy()
		end
	end)
end

return {
	EarlyAccess = true,
	
	OnSpawn = function(LuaPlayer)
		local LuaCharacter = LuaPlayer.Character
		local Combat = LuaCharacter.Combat

		local Ultimate = Combat:GetFirstAttack("Ultimate")
		if (Ultimate == nil) then return print("how does", LuaPlayer.PlayerName, "not have an ultimate 🙏😭") end
		
		local UltimateJob = Job.Extend(Combat.SpawnJob)

		UltimateJob:Task(Ultimate.OnUltimateBegan:Connect(function()
			local StatesThatWait = {"Attacking", "M1ing", "Stunned", "Ragdolled", "CannotDrawWeapon", "Blocking"}
			local Thread

			local Rest : AnimationTrack = LuaCharacter.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Mori.Pole.Rest)
			local Rest_Loop : AnimationTrack = LuaCharacter.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Mori.Pole.Rest_Loop)

			Rest.Priority = Enum.AnimationPriority.Action4
			Rest_Loop.Priority = Enum.AnimationPriority.Action4
			
			local function StartThread()
				Thread = task.delay(3, function()
					Rest:Play(0.1)

					Rest:GetMarkerReachedSignal("idle"):Once(function()
						Rest:Stop(0)
						Rest_Loop:Play(0)
					end)
				end)
			end
			
			UltimateJob:Task(function()
				Rest:Stop(0.001)
				Rest_Loop:Stop(0.001)
				
				Rest:Destroy()
				Rest_Loop:Destroy()
				
				Utility.CloseThreadSafe(Thread)
			end)

			UltimateJob:Task(Combat.OnStateChanged:Connect(function(State : any, Value : any)
				if table.find(StatesThatWait, State) then
					
					if Value then
						Rest:Stop(0.1)
						Rest_Loop:Stop(0.1)
						
						Rest:Destroy()
						Rest_Loop:Destroy()
						
						Utility.CloseThreadSafe(Thread)
					else
						StartThread()
					end
					
				end
			end))
			
			StartThread()
		end))
		
		UltimateJob:Task(Ultimate.OnUltimateEnded:Connect(function()
			UltimateJob:Clean()
		end))
	end,

	Ultimate = {
		--Name = "TUFFNESS OVERLOAD",
		--Name = "MONKEY KING",
		Name = "HEAVEN'S EQUAL",

		--Attacks = {
		--	["Staff Whiplash"] = Enum.KeyCode.One
		--},
		
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 66, 222)),
			ColorSequenceKeypoint.new(0.15, Color3.fromRGB(171, 100, 222)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(222, 170, 66)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 227, 70)),
			ColorSequenceKeypoint.new(0.65, Color3.fromRGB(171, 100, 222)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(222, 170, 66)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 66, 222)),
		}),
		
		--Color = ColorSequence.new({ -- TIOO ORANCH.. -- GardenOfBlue
		--	ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 66, 222)),
		--	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 176, 65)),
		--	ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 66, 222)),
		--}),
		
		--Color = ColorSequence.new({ -- Original color
		--	ColorSequenceKeypoint.new(0, Color3.fromRGB(48, 84, 141)),
		--	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(84, 144, 255)),
		--	ColorSequenceKeypoint.new(1, Color3.fromRGB(48, 84, 141)),
		--}),

		ManuallyFireStartRemote = true,

		OnStart = function(self)
			self.Combat:TimesSpeed(1.1)

			self.Combat.Attacks.Ultimate.OnUltimateEnded:Once(function()
				self.Combat:DivideSpeed(1.1)
			end)
			
			if self:WillSkipIntro() then
				Pole(self)
				Outfit(self)
			end
		end,

		Function = function(self)
			Pole(self)
			
			local BigPole = script.BigPole:Clone()
			BigPole.Name = "BIGPoll" -- For animation
			BigPole.Weld.Part0 = self.LuaCharacter.RootPart
			BigPole.Parent = self.LuaCharacter.Model
			self.Thread.Job:Task(BigPole)

			local Animation : AnimationTrack = self.Animations[self.Combat.CurrentCharacter.Name].Start
			Animation:Play(0)

			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("throne_end"):Connect(function()
				Outfit(self)
			end))
			
			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("pole_land"):Connect(function()
				local Hitbox = self:CreateHitbox()
				Hitbox.Params.Offset = CFrame.new(11, 0.5, 0)
				Hitbox.Params.Size = Vector3.one * 17
				Hitbox.Params.MaxTargets = -1
				Hitbox.Params.DestroyOnEndCast = false

				Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
					self:Afflict(VictimLuaPlayer, {
						TriggerActiveCounterOverOrEqualLevel = -1,
						CannotBeAdapted = true,
						Damage = {Amount = 100, DontKill = true},
						DontBypassIFrames = {},
						Ragdoll = 3,
						Velocity = {Utility.Seed:NextUnitVector() * 50 + Vector3.yAxis * 45, 0.1}
					})
				end)

				Hitbox:Detect()
			end))
			
			self:FireReliableVFX("Mori/Ultimate", "Start", self.LuaCharacter.Model)

			self.Thread.Job:Task(Animation.Stopped:Once(function()
				self:Close()
			end))
		end,
	},

	Attacks = {
		["Renewal Taekwondo"] = Enum.KeyCode.One,
		["Whirlwind Slam"] = Enum.KeyCode.Two,
		["Dragon Dropkick"] = Enum.KeyCode.Three,
		["Triple Kick Counter"] = Enum.KeyCode.Four
	},

	Stats = {
		M1 = {
			Speed = 0.9,
			EndlagAfterSwing = 0.14,
			LastM1KnocksUp = true
		},
	},
	
	Dash = {
		CustomFunction = function(self)
			local Ultimate = self.Combat:GetFirstAttack("Ultimate");

			if Ultimate and Ultimate.InUltimate then
				self.Combat:StackState("Attacking", true)
				self.Combat:DivideSpeed(10)

				self:AddCertainCooldown("Front&Back Dash", 6)
				self.FrontDashHit = false

				local AnimationDirectory = self:GetAnimationDirectory().Ult

				local LoopAnimation : AnimationTrack = AnimationDirectory.Loop
				local HitAnimation : AnimationTrack = AnimationDirectory.Hit

				local LastLookVector : Vector3 = self.LuaCharacter.RootPart.CFrame.LookVector
				local LastPosition : Vector3 = self.LuaCharacter.RootPart.Position

				local Decay = math.rad(6.5)
				local AngleTotal = 0

				local NewJob = Job.new()
				local ValidatedType = ""

				local ProximityHitbox = self:CreateHitbox(false, true);

				local ProximitySize = Vector3.new(5.35, 4, 7.3)
				local ProximityOffset = CFrame.new(0, -0.5, -1)

				local SwingSize = Vector3.new(5.35, 3.5, 7.5)
				local SwingOffset = CFrame.new(0, -0.5, -2.3)

				ProximityHitbox.Params.Offset = ProximityOffset
				ProximityHitbox.Params.Size = ProximitySize
				ProximityHitbox.Params.DestroyOnEndCast = false

				local function DisconnectAll()
					NewJob:Clean()

					ProximityHitbox:EndCast()
					ProximityHitbox:Destroy()
					
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

					task.wait(0.05)

					if not self:ThreadAvailable() or self.Thread.Cancelled then return end

					local Hitbox = self:CreateHitbox(false);
					Hitbox.Params.Offset = SwingOffset
					Hitbox.Params.Size = SwingSize
					Hitbox.Params.DestroyOnEndCast = false

					Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
						local VictimLuaCharacter = VictimLuaPlayer.Character
						local VictimCombat = VictimLuaCharacter.Combat

						local Validated, Type : string = self:Afflict(VictimLuaPlayer, {
							DontBypassIFrames = {"Grab", "Backdash"},
							DontRestartRespawnTimer = true,
							Damage = 7, --4
							YDifferenceValue = -2,
							CannotBeAdapted = true
						})

						ValidatedType = Type

						if Validated then
							self.LastTimeFrontDashHit = os.clock()
							self.FrontDashHit = true

							self:FireReliableVFX(`{Ultimate_Globals}/Forward Dash`, "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)

							local ValuesThatCauseAPush = 
								AngleTotal > math.rad(150) or  -- if u rotate too much
								(LastPosition - VictimLuaCharacter.RootPart.Position).Magnitude < 17.5 or -- if u hit them too close
								VictimCombat:GetState("ForceDashPush") or
								VictimCombat:GetState("StunImmunity") or -- nerfs wake-up front dash
								(VictimCombat:GetState("Ragdolled") and self.Combat:CalculateYDifference(VictimLuaPlayer) > -2) -- makes uppercut front dash possible in general

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
								return (CF.LookVector * (65 + cube:GetMass() / 2)) + Random.new():NextUnitVector() * 5;
							end 
						},
					})

					Hitbox:BeginCast(0.08)

					Hitbox.Events.OnCastEnded:Connect(function()
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

				LoopAnimation:Play(0.05, 1, StartSpeed)

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
				self:FireReliableVFX(`{Ultimate_Globals}/Forward Dash`, "Start", self.LuaCharacter.Model)
	
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

				LoopAnimation:AdjustSpeed(MiddleSpeed)

				task.wait(0.125)

				ProximityHitbox:BeginCast()
				LoopAnimation:AdjustSpeed(PauseSpeed)
			else
				return "Default";
			end
		end,
	},

	M1 = {
		CustomFunction = function(self)
			local Ultimate = self.Combat:GetFirstAttack("Ultimate");
			
			if Ultimate and Ultimate.InUltimate then
				if (self.Count > 3 or time() - self.ResetTime >= self.ResetTimer) then
					self.Count = 0
				end

				local AnimationDirectory = self:GetAnimationDirectory()["Ult"]
				
				self.Combat:StackState("M1ing", true)
				self:StopCurrentAnimation(AnimationDirectory)

				self.Count += 1
				self.ResetTime = time()

				self.Hit = false
				self.Downslammed = false
				self.InWindup = true
				self.Condition = (self.Count > 3 and (if self.Combat.AirState == "" then nil else self.Combat.AirState) or nil)

				self.WallComboVictim = nil

				local IsNotFinalM1 = self.Count < 4

				local Animation_Name : string = (self.Condition ~= nil and self.Condition or tostring(self.Count))
				local Animation : AnimationTrack = AnimationDirectory[Animation_Name]
				Animation:Play()

				local Hitbox = self:CreateHitbox()
				Hitbox.Params.DestroyOnEndCast = false

				if self.Condition == "Up" then
					Hitbox.Params.Offset = CFrame.new(0, 0, -2.65)
					Hitbox.Params.Size = Vector3.new(6, 10, 6.8)

				elseif self.Condition == "Down" then
					Hitbox.Params.Offset = CFrame.new(0, -3.5, -2.65)
					Hitbox.Params.Size = Vector3.new(5.35, 25, 6.8)
				else
					if self.Count == 4 then
						Hitbox.Params.Offset = CFrame.new(0, 1, -2.65) 
						Hitbox.Params.Size = Vector3.one * 10.5
					else
						Hitbox.Params.Offset = CFrame.new(0, 0, -2.65) 
						Hitbox.Params.Size = Vector3.new(8, 6, 7.15)
					end
					
				end
				
				--local Damage = {
				--	[1] = 3,
				--	[2] = 3,
				--	[3] = 4,
				--	[4] = 6,
				--}
				
				local Damage = {
					[1] = 4,
					[2] = 4,
					[3] = 5,
					[4] = 7,
				}
				
				Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
					local VictimLuaCharacter = VictimLuaPlayer.Character
					local VictimCombat = VictimLuaCharacter.Combat

					local BlockAttack, BlockAttackMatched = self.Combat:MatchAttack("Block", Enum.KeyCode.F)
					local Parried = BlockAttackMatched and (time() - BlockAttack.PerfectBlockTime < 2)

					local Validated, Type : string = self:Afflict(VictimLuaPlayer, {
						DontBypassIFrames = (self.Condition ~= "Down" and {"Grab", "Backdash"}),
						BreakBlock = (self.Count == 3 or self.Count == 4),
						Damage = Parried and 6 or (Damage[self.Count]),
						CanPerfectBlock = (self.Condition == nil),
						DontHitRagdolled = (IsNotFinalM1),
						YDifferenceValue = not IsNotFinalM1 and VictimLuaCharacter.HumanoidAlive and 0 or nil,
						DontHitDeadPeople = (IsNotFinalM1),
						DontRestartRespawnTimer = not IsNotFinalM1,
						CannotBeAdapted = true
					})
					
					print("DontHitRagdolled:", IsNotFinalM1)
					print("YDifferenceValue:", not IsNotFinalM1 and VictimLuaCharacter.HumanoidAlive and 0 or nil)
					print("DontHitDeadPeople:", IsNotFinalM1)
					print("DontRestartRespawnTimer:", not IsNotFinalM1)

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
							self:FireReliableVFX("Global/M1", "Uppercut", VictimLuaCharacter.RootPart, "Mori")

							local VictimVelocityObject = self:VelocityOn(VictimCombat)
							VictimVelocityObject.Settings.RemoveTime = 0.05
							VictimVelocityObject.Settings.Velocity = Vector3.yAxis * 70
							VictimVelocityObject:Fire()

							self:Afflict(VictimLuaPlayer, {
								ExcludeAttempts = true;
								Ragdoll = 2;
							})

							VictimLuaCharacter.RootPart.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(30, -30), 0, Utility.Seed:NextNumber(30, -30))

						elseif self.Condition == "Down" then
							self.Downslammed = true

							self.Combat.Hitbox:Destruction(Hitbox.Params.Offset, Vector3.new(4, 15, 4), 1)
							self:FireReliableVFX("Global/M1", "Down Slam", VictimLuaCharacter.RootPart, "Mori")
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
							if Parried then
								VictimCombat.Animations.BlackFlashed:Play()
								VictimCombat:AntiTeamStun(self.LuaPlayer.Player, 1.25)
							else
								self:FireReliableVFX(`{Ultimate_Globals}/M1`, "Hit", VictimLuaCharacter.RootPart, self.Count)
								
								if (self.Count == 4) then
									local VictimVelocityObject = self:VelocityOn(VictimCombat)
									VictimVelocityObject.Settings.RemoveTime = 0.1
									VictimVelocityObject.Settings.Velocity = KnockbackVelocity * 40 + Vector3.yAxis * 8.5
									VictimVelocityObject:Fire()

									self:Afflict(VictimLuaPlayer, {
										ExcludeAttempts = true;
										Ragdoll = 2;
									})
								else
									VictimCombat:PlayRandomHitReaction()
									VictimCombat:AntiTeamStun(self.LuaPlayer.Player, 0.85)
									--VictimCombat:StackState("ForceDashPush", true, 1) -- Hell yeah.

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
					end
					
					if (self.Count == 4 and self.Condition ~= nil) then
						task.defer(self.Close, self)
					end
				end)
				
				self.Thread.OnCancelled:Connect(function()
					Animation:Stop()
				end)

				self.Thread.OnClosed:Connect(function()
					if self.Count == 4 then
						self:AddCooldown(1.25, true)
					end

					self.Combat:StackState("M1ing", false)
				end)
				
				self:FireReliableVFX(`{Ultimate_Globals}/M1`, "Start", self.LuaCharacter.Model, Animation_Name)

				local IdkWhyTsIsRunningTwice = false
				
				--self.Thread.Job:Task(function()
				--	if self.LuaCharacter.Mori_Pole then
				--		self.LuaCharacter.Mori_Pole.Handle.Poll.Transparency = 0
				--	end
					
				--	if self.LuaCharacter.Mori_Secondary_Pole then
				--		self.LuaCharacter.Mori_Secondary_Pole.Poll.Transparency = 1
				--	end
				--end)
				
				--self.Thread.Job:Task(Animation:GetMarkerReachedSignal("fake_staff"):Connect(function(Parameter : string?)
				--	if (self.LuaCharacter.Mori_Secondary_Pole == nil) then return end
					
				--	if (Parameter == "true") then
				--		if self.LuaCharacter.Mori_Pole then
				--			self.LuaCharacter.Mori_Pole.Handle.Poll.Transparency = 1
				--		end
						
				--		self.LuaCharacter.Mori_Secondary_Pole.Poll.Transparency = 0
				--	else
				--		if self.LuaCharacter.Mori_Pole then
				--			self.LuaCharacter.Mori_Pole.Handle.Poll.Transparency = 0
				--		end
						
				--		self.LuaCharacter.Mori_Secondary_Pole.Poll.Transparency = 1
				--	end
				--end))
				
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
					if (Parameter == "stun") then
						
						local StunHitbox = self:CreateHitbox()
						StunHitbox.Params.Offset = CFrame.new(0, 0, -2.65) 
						StunHitbox.Params.Size = Vector3.new(6, 6, 6.8)
						StunHitbox.Params.DestroyOnEndCast = false
						
						StunHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
							self:Afflict(NewVictimLuaPlayer, {
								Damage = 2,
								Stun = 1,
								PlayRandomHitReaction = true,
								CanPerfectBlock = true,
								DontRestartRespawnTimer = true,
								CannotBeAdapted = true
							})
						end)
						
						StunHitbox:Detect()
						
						self.Thread.Job:Task(task.delay(0.35, function()
							local VelocityObject = self.Combat:Velocity()
							VelocityObject.Settings.FixScale = true
							VelocityObject.Settings.Duration = 0.50
							VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
							VelocityObject.Settings.MaxForce = Vector3.one * 80000
							VelocityObject.Settings.Controllable = true
							VelocityObject.Settings.Z = 75
							VelocityObject:Fire()

							self.Thread.Job:Task(VelocityObject)
						end))
					else
						self.InWindup = false
						Hitbox:BeginCast(0.1)

						if self.Count == 4 then
							task.spawn(function()
								local Condition : string? = self.Condition
								local CF : CFrame = Hitbox:GetCFrame() * CFrame.new(0, 1, 0)
								local Seed = Random.new()
								local VelocityFn;

								local Power = 45
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

						--if IdkWhyTsIsRunningTwice then return end

						--IdkWhyTsIsRunningTwice = true

						--if (self.Condition ~= nil) then
						--	local StopAnimConnection : RBXScriptConnection; StopAnimConnection = self.Combat.OnStateUpdated:Connect(function(State : string, Value : boolean)
						--		if (State ~= "Attacking" or State ~= "M1ing" or State ~= "Blocking") then return end

						--		if Value then
						--			StopAnimConnection:Disconnect()
						--			Animation:Stop()
						--			print(Animation.Name)
						--		end
						--	end)

						--	Animation.Stopped:Once(function()
						--		print("stopped connection")
						--		StopAnimConnection:Disconnect()
						--	end)
						--end

						self.Combat.Values.Jump:Add(0.05)

						task.wait(0.15)

						if self.Count == 4 and not self.Thread.Closed and not self.Hit then
							task.wait(0.75)

							if not self.Hit then
								self:Close()
							end
						else
							self.Combat:StackState("CannotBlock", true)
							self.Combat:StackState("CannotRun", true)
							self:Close()

							task.delay(self.TimeUntilCanBlock, function()
								self.Combat:StackState("CannotRun", false)
								self.Combat:StackState("CannotBlock", false)
							end)
						end
					end
					
				end))
			else
				return "Default";
			end
		end,
	};

	WallCombo = {
		DistanceFromWall = 4,
		VictimOffset = CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0),

		Function = function(self, VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local UserAnimation : AnimationTrack = self.Animations.WallCombo.Mori.User
			local VictimAnimation : AnimationTrack? = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Dash.WallCombo.Mori.Victim)
			local VictimFlung = false

			self.Thread.OnClosed:Connect(function()
				UserAnimation:Stop()

				if VictimAnimation then
					VictimAnimation:Stop()
				end

				self.LuaCharacter:Anchor(false)
				VictimCombat:StackState("GrabIFrames", false)

				if not VictimFlung then
					self.Combat:StackState("GrabIFrames", false)

					VictimLuaCharacter:Anchor(false)
					VictimCombat:Unstun()
				else
					task.delay(0.5, self.Combat.StackState, self.Combat, "GrabIFrames", false)
				end
			end)

			UserAnimation:Play(0)

			if VictimAnimation then
				VictimAnimation:Play(0)
			end

			self.Thread.Job:Task(UserAnimation:GetMarkerReachedSignal("dmg"):Connect(function(Parameter : string)
				
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {Amount = tonumber(Parameter), DontKill = true},
				})
			end))

			self.Thread.Job:Task(UserAnimation:GetMarkerReachedSignal("end"):Once(function()
				VictimFlung = true

				VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -5) * CFrame.Angles(0, math.pi, 0))
				VictimLuaCharacter:Anchor(false)

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Ragdoll = 1.4,
					Velocity = {-self.LuaCharacter.RootPart.CFrame.LookVector * 50 + Vector3.yAxis * 45, 0.1},
				})

				VictimAnimation:Stop(0)
				VictimCombat:Unstun()
			end))

			self.Thread.Job:Task(UserAnimation:GetMarkerReachedSignal("end"):Once(function()
				self:Close()
			end))

			self:FireReliableVFX("Mori/Wall Combo", "Start", self.LuaCharacter.Model)
		end,
	}
}
