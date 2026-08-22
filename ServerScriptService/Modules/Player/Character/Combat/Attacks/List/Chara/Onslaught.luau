

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes
local UIRemotes = Remotes.Combat.UI

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )
local BaseAttack = require( ServerScriptService.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Onslaught()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self.NormalHit = false

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -5)
	Hitbox.Params.Size = Vector3.new(8, 8, 10)
	Hitbox.Params.DestroyOnEndCast = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local WasRagdolled = VictimLuaPlayer.Character.Combat:GetState("Ragdolled")

		local Angle = self.Combat:CalculateHitAngle(VictimLuaPlayer) 
		local ActivateSpecial = (Angle <= math.rad(90))

		local Validated = self:Afflict(VictimLuaPlayer, {
			Damage = 5,
			TrueStun = not WasRagdolled and 1 or nil,
		})

		if Validated then
			self.NormalHit = true

			if (WasRagdolled or Hitbox.HitCount > 1) then
				self:FireReliableVFX("Chara/Onslaught Normal", "Smack", VictimLuaPlayer.Character.Torso, "1")
				
				if WasRagdolled then
					self.Combat:TSBPushVictim(VictimLuaPlayer, {
						LookVectorInsteadOfDifference = (self.Combat:CalculateYDifference(VictimLuaPlayer) < -2), -- patches really overpowered tech
						DontBeginAoeHitbox = true,
						LandedRollVelocityZ = 180,
						LandedRollDuration = 0.75,
						DurationMultiplier = 0.55,
					})
				end
				
				task.wait(0.4)

				if not self.Animations.NormalHit.IsPlaying then
					self:Close()
				end
			else
				self.Combat:StackState("GrabIFrames", true)
				
				self.Thread.OnClosed:Connect(function()
					self.Combat:StackState("GrabIFrames", false)
				end)

				local Time = 0.1
				local MaxForce = Vector3.new(1, 0, 1) * 80000

				local Ended = false
				local FirstHit = false

				local function Hit(NewVictimLuaPlayer, Name : string, SFX : number)
					local NewVictimLuaCharacter = NewVictimLuaPlayer.Character
					local NewVictimCombat = NewVictimLuaCharacter.Combat

					if (Name == "Hit") then
						self:FireReliableVFX("Chara/Onslaught Normal", "Smack", NewVictimLuaCharacter.Torso, SFX)

					elseif (Name == "Stab") then
						self:FireReliableVFX("Chara/Onslaught Normal", "StabHit", NewVictimLuaCharacter.RootPart, SFX)

					elseif (Name == "Slash") then
						self:FireReliableVFX("Chara/Onslaught Normal", "SlashHit", NewVictimLuaCharacter.RootPart, SFX)
					end

					NewVictimCombat:PlayRandomHitReaction()

					local Velocity : Vector3 = (self.LuaCharacter.RootPart.CFrame.LookVector * 25)

					if NewVictimCombat:GetState("Ragdolled") or not NewVictimLuaCharacter.HumanoidAlive then
						--if not FirstHit then
						--	FirstHit = true
							
						--	self.Combat:TSBPushVictim(VictimLuaPlayer, {
						--		LookVectorInsteadOfDifference = (self.Combat:CalculateYDifference(VictimLuaPlayer) < -2), -- patches really overpowered tech
						--		DontBeginAoeHitbox = true,
						--		LandedRollVelocityZ = 180,
						--		LandedRollDuration = 0.7,
						--		DurationMultiplier = 0.475,
						--	})
							
						--	--local VelocityObject = self:VelocityOn(NewVictimCombat)
						--	--VelocityObject.Settings.RemoveTime = Time
						--	--VelocityObject.Settings.MaxForce = MaxForce
						--	--VelocityObject.Settings.Velocity = (self.LuaCharacter.RootPart.CFrame.LookVector * 50 + Vector3.yAxis * 2.5)
						--	--VelocityObject:Fire()
						--else
						local VelocityObject = self:VelocityOn(NewVictimCombat)
						VelocityObject.Settings.RemoveTime = Time
						VelocityObject.Settings.MaxForce = MaxForce
						VelocityObject.Settings.Velocity = Velocity / 1.85
						VelocityObject:Fire()
						--end
					else
						local VelocityObject = self:VelocityOn(NewVictimCombat)
						VelocityObject.Settings.RemoveTime = Time
						VelocityObject.Settings.MaxForce = MaxForce
						VelocityObject.Settings.Velocity = Velocity / 1.15
						VelocityObject:Fire()

						NewVictimCombat:PlayRandomHitReaction()
					end
				end

				local function Hitbox(Damage : number, Name : string, SFX : string)
					local Hitbox = self:CreateHitbox()
					Hitbox.Params.Offset = CFrame.new(0, 0, -3.75)
					Hitbox.Params.Size = Vector3.new(7, 7, 7)
					Hitbox.Params.DestroyOnEndCast = false

					Hitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
						local Validated = self:Afflict(NewVictimLuaPlayer, {
							--BreakBlock = true,
							Damage = Damage,
							TrueStun = 0.75
						})

						if Validated then
							Hit(NewVictimLuaPlayer, Name, SFX)
						end
					end)
					
					Hitbox:BeginCast(0.1)

					local VelocityObject = self.Combat:Velocity()
					VelocityObject.Settings.Duration = 0.55
					VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
					VelocityObject.Settings.MaxForce = MaxForce
					VelocityObject.Settings.Controllable = true
					VelocityObject.Settings.Z = 45
					VelocityObject:Fire()
				end
				
				local Count = 0

				self.Thread.Job:Task(self.Animations.NormalHit:GetMarkerReachedSignal("stab"):Connect(function()
					self:FireReliableVFX("Chara/Onslaught Normal", "Stab", self.LuaCharacter.RootPart)

					Count += 1
					Hitbox(1.5, "Stab", tostring(Count))
				end))

				self.Thread.Job:Task(self.Animations.NormalHit:GetMarkerReachedSignal("kick"):Connect(function(Type : string)
					self:FireReliableVFX("Chara/Onslaught Normal", "Kick", self.LuaCharacter.RootPart)

					if Type == "last" then
						Ended = true

						local Hitbox = self:CreateHitbox(false, true);
						Hitbox.Params.Offset = CFrame.new(0, 0, -5)
						Hitbox.Params.Size = Vector3.one * 10
						Hitbox.Params.DestroyOnEndCast = false

						Hitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
							local Validated = self:Afflict(NewVictimLuaPlayer, {
								BreakBlock = true,
								Damage = 2.5,
								--Ragdoll = 1.85,
								--Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 45 + Vector3.yAxis * 45, 0.1}
							})
							
							if Validated then
								self.Combat:PushSkidVictim(NewVictimLuaPlayer, {
									CannotEvasive = true,
									TimeTilGroundDetection = 0.35,
									StartVelocityXZ = self.LuaCharacter.RootPart.CFrame.LookVector * 35,
									StartVelocityY = Vector3.yAxis * 105,
									StartDuration = 0.55,
									LandedRollVelocityZ = 155,
									LandedRollDuration = 0.785
								})
								
								self:FireReliableVFX("Chara/Onslaught Normal", "Smack", NewVictimLuaPlayer.Character.Torso, "Last")
							end
						end)

						Hitbox:Detect()
						task.defer(Hitbox.Destroy, Hitbox)

						local VelocityObject = self.Combat:Velocity()
						VelocityObject.Settings.RemoveTime = 0.7
						VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
						VelocityObject.Settings.Controllable = true
						VelocityObject.Settings.Z = 35
						VelocityObject:Fire()

						local EndAnimation : RBXScriptConnection; EndAnimation = self.Combat.OnStateChanged:Connect(function(State : any, Value : boolean)
							if Value and (State == "Attacking" or State == "M1ing") then
								self.Animations.NormalHit:Stop()
								VelocityObject:Destroy()
							end
						end)

						self.Animations.NormalHit.Stopped:Once(function()
							self.LuaPlayer.Replication.Attributes:SetAttribute("Velocity", nil)

							if EndAnimation.Connected then
								EndAnimation:Disconnect()
							end
						end)
						
						task.wait(0.3)

						self:Close()
					else
						Count += 1
						Hitbox(1.5, "Hit", tostring(Count))
					end
				end))
	
				self.Thread.Job:Task(self.Animations.NormalHit:GetMarkerReachedSignal("kickswing"):Connect(function(Type : string)
					self:FireReliableVFX("Chara/Onslaught Normal", "KickSwing", self.LuaCharacter.RootPart, tonumber(Type))
					
					Count += 1
					Hitbox(0.75, "Hit", tostring(Count))
				end))

				self.Thread.Job:Task(self.Animations.NormalHit:GetMarkerReachedSignal("slash"):Connect(function(Type : string)
					self:FireReliableVFX("Chara/Onslaught Normal", "Slash", self.LuaCharacter.RootPart, tonumber(Type))
					
					Count += 1
					Hitbox(1.75, "Slash", tostring(Count))
				end))

				self.Thread.Job:Task(self.Animations.NormalHit:GetMarkerReachedSignal("slam"):Connect(function()
					self:FireReliableVFX("Chara/Onslaught Normal", "Slam", self.LuaCharacter.RootPart)
				end))

				self.Animations.NormalWindup:Stop()
				self.Animations.NormalHit:Play()
				
				self:FireReliableVFX("Chara/Onslaught Normal", "Hit", self.LuaCharacter.Model)

				Count += 1
				Hit(VictimLuaPlayer, "Hit", tostring(Count))
			end
		end
	end)

	--self.LuaPlayer.Replication.Attributes:SetAttribute("OnslaughtNormal", true)
	--self:FireReliableVFX("Chara/Onslaught Normal", "Start", self.LuaCharacter.RootPart)

	self.Thread.OnClosed:Connect(function()
		self.LuaPlayer.Replication.Attributes:SetAttribute("OnslaughtNormal", nil)

		self:AddCooldown(self.Cooldown)

		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.NormalWindup:GetMarkerReachedSignal("jump"):Once(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 0.935
		VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 58.5
		VelocityObject:Fire()

		self.Thread.OnClosed:Connect(function()
			self.LuaPlayer.Replication.Attributes:SetAttribute("Velocity", nil)
		end)
	end))

	self.Thread.Job:Task(self.Animations.NormalWindup:GetMarkerReachedSignal("land"):Once(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 0.4
		VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 35
		VelocityObject:Fire()
	end))

	self.Thread.Job:Task(self.Animations.NormalWindup:GetMarkerReachedSignal("hit"):Once(function()
		self.Animations.NormalWindup:AdjustSpeed(1)
		--self:FireReliableVFX("Chara/Onslaught Normal", "Swing", self.LuaCharacter.RootPart)
		
		Hitbox:BeginCast(0.1)
		
		Hitbox.Events.OnCastEnded:Once(function()
			if not self.NormalHit then
				self.Animations.NormalWindup:AdjustSpeed(0.8)
			end
		end)
	end))
	
	self.Animations.NormalWindup:Play(0.1, 1, 1.3)
	self:FireReliableVFX("Chara/Onslaught Normal", "Windup", self.LuaCharacter.Model)

	task.wait(1.75)

	if not self.NormalHit then
		self:Close()
	end
end

function Attack:SpiralingCascade()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(15)

	self.GroundHit = false
	
	local Hitbox = self:CreateHitbox(false, true);
	Hitbox.Params.Offset = CFrame.new(0, -1, self.LuaPlayer.IsNPC and 2 or -4 - self.LuaPlayer:GetPing())
	Hitbox.Params.Size = Vector3.new(7, 3, 10)
	Hitbox.Params.MaxTargets = 1
	Hitbox.Params.DestroyOnEndCast = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true,
		})

		if Validated then
			self.GroundHit = true
			Hitbox:EndCast()
		end
	end)
	
	self.Thread.Job:Task(self.Animations.GroundWindup:GetMarkerReachedSignal("jump"):Once(function()
		self.Animations.GroundWindup:AdjustSpeed(1)

		self.LuaCharacter.Torso.CanCollide = false
		self.LuaCharacter.RootPart.CanCollide = true

		self.Thread.OnClosed:Connect(function()
			self.LuaCharacter.Torso.CanCollide = true
			self.LuaCharacter.RootPart.CanCollide = false
		end)

		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 1
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 105
		VelocityObject:Fire()
		
		self.Thread.Job:Task(VelocityObject)
	end))
	
	self.Thread.Job:Task(self.Animations.GroundWindup:GetMarkerReachedSignal("hit"):Once(function()
		Hitbox:BeginCast()
	end))
	
	self.Animations.GroundWindup:Play(0.1, 1, 1.4)
end

function Attack:FeralTakedown()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(15)
	
	self.AerialHit = false

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, -4, -3)
	Hitbox.Params.Size = Vector3.new(8, 20, 8)
	Hitbox.Params.MaxTargets = 1
	Hitbox.Params.DestroyOnEndCast = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true,
			Damage = {Amount = 1.5, DontKill = true},
			TrueStun = 0.75,
		})

		if Validated then
			self.AerialHit = true
			Hitbox:EndCast()
			
			self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 5, 0), "CharaOnslaughtAerial")
			local VictimAnimation : AnimationTrack = VictimLuaCharacter.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Chara.Onslaught.AerialVictim)
			
			local Ended = false
			
			self.Thread.Job:Task(self.Animations.AerialHit:GetMarkerReachedSignal("drop"):Connect(function()
				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.RemoveTime = 0.15
				VelocityObject.Settings.MaxForce = Vector3.new(0, 1, 0) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Y = 27.5
				VelocityObject:Fire()

				self:FireReliableVFX("Chara/Onslaught Aerial", "Drop", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)

				--task.wait(0.6)
				
				--local VelocityObject = self.Combat:Velocity()
				--VelocityObject.Settings.MaxForce = Vector3.new(0, 1, 0) * 80000
				--VelocityObject.Settings.Controllable = true
				--VelocityObject.Settings.Y = -22.5
				--VelocityObject:Fire()
			end))
			
			self.Thread.Job:Task(self.Animations.AerialHit:GetMarkerReachedSignal("jump"):Connect(function()
				Ended = true
				
				VictimAnimation:Stop(0)
				
				VictimLuaCharacter.Model:PivotTo(VictimLuaCharacter.RootPart.CFrame * CFrame.new(0, -4, -1))
				self.LuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 2.5, 0))
				
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Ragdoll = 1.9,
					Damage = 1.5,
					Velocity = {Vector3.yAxis * 55, 0.15}
				})
				
				self:FireReliableVFX("Chara/Onslaught Aerial", "Drop", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
				
				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.RemoveTime = 0.15
				VelocityObject.Settings.MaxForce = Vector3.new(0, 1, 0) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Y = 80
				VelocityObject.Settings.Z = -30
				VelocityObject:Fire()

				self:Close()
			end))
			
			self.Thread.Job:Task(self.Animations.AerialHit:GetMarkerReachedSignal("stab"):Connect(function()
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,

					Damage = {
						DontKill = true,
						Amount = 6.5
					}
				})
				
				self:FireReliableVFX("Chara/Onslaught Aerial", "Stab", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
			end))

			self.Animations.AerialWindup:Stop(0)
			self.Animations.AerialHit:Play(0)
			VictimAnimation:Play(0)

			self.Thread.OnClosed:Connect(function()
				if not Ended then
					VictimAnimation:Stop()
					self.Animations.AerialHit:Stop()
				end

				GrabObject.Destroy(0)
				VictimCombat:Unstun()
			end)
			
			self:FireReliableVFX("Chara/Onslaught Aerial", "Hit", self.LuaCharacter.Model, VictimLuaCharacter.Model)
		end
	end)
	
	self.Thread.Job:Task(self.Animations.AerialWindup:GetMarkerReachedSignal("hit"):Once(function()
		Hitbox:BeginCast(0.1)
	end))
	
	self.Thread.Job:Task(self.Animations.AerialWindup:GetMarkerReachedSignal("jump"):Once(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 0.65
		VelocityObject.Settings.RemoveTime = 1
		VelocityObject.Settings.MaxForce = Vector3.new(0, 1, 0) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Y = 25
		VelocityObject:Fire()
	end))
	
	self.Thread.Job:Task(self.Animations.AerialWindup:GetMarkerReachedSignal("spin"):Once(function()
		self:FireReliableVFX("Chara/Onslaught Aerial", "Spin", self.LuaCharacter.Model)
	end))
	
	self.Thread.Job:Task(self.Animations.AerialWindup:GetMarkerReachedSignal("lunge"):Once(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 0.75
		VelocityObject.Settings.RemoveTime = 0.25
		VelocityObject.Settings.MaxForce = Vector3.one * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Y = -70
		VelocityObject.Settings.Z = 30
		VelocityObject:Fire()
	end))

	self.Animations.AerialWindup:Play()
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(self.Cooldown)

		self.Combat:TimesSpeed(15)
		self.Combat:StackState("Attacking", false)
	end)
	
	self:FireReliableVFX("Chara/Onslaught Aerial", "Start", self.LuaCharacter.RootPart)
	
	task.wait(1.5)

	if not self.AerialHit then
		self:Close()
	end
end

function Attack:Activate()
	if (self.VariantsEnabled and self.GroundVariant) or self.ForceSpecialVariant then
		return self:SpiralingCascade()
	end
	
	if (self.VariantsEnabled and self.HoldingJump) or self.ForceVariant then
		self:FeralTakedown()
	else
		self:Onslaught()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	
	self.TryToCancelMoves = true
	--self.Cooldown = 19 -- when bloody mary extended
	self.Cooldown = 17
	
	self.GroundVariant = false
	
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack