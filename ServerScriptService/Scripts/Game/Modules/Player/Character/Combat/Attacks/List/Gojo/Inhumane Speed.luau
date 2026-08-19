local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage.Remotes
local UIRemotes = Remotes.Combat.UI
local HotbarRemotes = UIRemotes.Hotbar

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self.Hit = false
	self.Boosted = false
	
	self.LuaCharacter.Model:SetAttribute("MaxRed", true)
	self:FireReliableVFX("Gojo/Max Red", "Start", self.LuaCharacter.RootPart)

	local RunHitbox = self:CreateHitbox(false);
	--RunHitbox.Params.Offset = CFrame.new(0, 1.5, -6)
	--RunHitbox.Params.Size = Vector3.one * 10
	
	RunHitbox.Params.Offset = CFrame.new(0, 1.5, -4)
	RunHitbox.Params.Size = Vector3.new(10, 9, 12)
	
	RunHitbox.Params.DestroyOnEndCast = false

	local StartTime = time()
	
	RunHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat
		
		local Finisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= (if self.Boosted then 1.5 else 0.5))

		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = 2,
			BreakBlock = true,
			Damage = self.Boosted and 1.5 or 0.5,
			Stun = self.Boosted and 0.8 or 0.5,
		})

		if Validated then
			if Finisher then
				local ValidFinisher = self:Afflict(VictimLuaPlayer, {
					FinisherKill = true,
					ExcludeAttempts = true
				})
				
				if ValidFinisher then
					self:FireReliableVFX("Gojo/Max Red", "Finisher", VictimLuaCharacter.Model)
				end
			end
			
			if self.Boosted then
				self:FireReliableVFX("Gojo/Max Red", "RunCriticalHit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
				VictimCombat.Animations.BlackFlashed:Play()
			else
				self:FireReliableVFX("Global/M1", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, math.random(1, 2))
				VictimCombat:PlayRandomHitReaction(3)
			end
		end
		
		task.delay(0.1, function()
			RunHitbox:RemoveHumanoid(VictimLuaCharacter.Humanoid)
		end)
	end)

	self.Thread.OnClosed:Once(function()
		self:AddCooldown(14)
		
		self.LuaCharacter.Model:SetAttribute("MaxRed", nil)
		
		if not self.Combat:GetState("Grabbed") then
			self.LuaCharacter:SetCollisionGroup("Player")
		end
		
		self.Combat:TimesSpeed(10)

		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("GrabIFrames", false)
	end)
	
	self.Animations.Windup:GetMarkerReachedSignal("run"):Wait()
	
	self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
	self:FireReliableVFXToSelf("Gojo/Max Red", "Velocity", self.LuaCharacter.RootPart)

	self.Combat:StackState("GrabIFrames", true)
	RunHitbox:BeginCast()

	self.Thread.Job:Task(self.Combat.Hitbox:ClientSidedDestructionLoop(CFrame.new(0, 0, -8), Vector3.new(4, 6, 5), 2))

	local VelocityObject = self.Combat:Velocity()
	VelocityObject.Settings.Duration = 2
	VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
	VelocityObject.Settings.Controllable = true
	VelocityObject.Settings.Z = 75
	VelocityObject:Fire()

	self.Thread.Job:Task(VelocityObject)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("boost"):Once(function()
		self.Boosted = true
		
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 2
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 90
		VelocityObject:Fire()

		self.Thread.Job:Task(VelocityObject)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("lunge"):Once(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 1
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 80
		VelocityObject:Fire()

		self.Thread.Job:Task(VelocityObject)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Once(function()
		RunHitbox:EndCast()
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Once(function()
		self.LuaPlayer.Replication.Attributes:SetAttribute("DestructibleDestroyLoop", nil)
		
		coroutine.wrap(function()
			local Hitbox = self:CreateHitbox(false);
			--Hitbox.Params.Offset = CFrame.new(0, 1.5, -9)
			--Hitbox.Params.Size = Vector3.new(12.5, 9, 15)
			
			Hitbox.Params.Offset = CFrame.new(0, 1.5, -3.65)
			Hitbox.Params.Size = Vector3.new(10, 9, 14)
			
			Hitbox.Params.MaxTargets = 1

			Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat

				local Validated = self:Afflict(VictimLuaPlayer, {
					TriggerActiveCounterOverOrEqualLevel = 2,
					BreakBlock = true,
					Damage = {
						DontKill = true,
						Amount = 10
					}
				})

				if Validated then
					self.Hit = true
					
					local CurrentVictim = VictimLuaCharacter.Model

					VictimCombat:StackState("HitboxImmunity", true)
					self.Combat:StackState("HitboxImmunity", true)
					
					VictimLuaCharacter:StopRespawnTimer()
					
					local VelocityObject = self.Combat:Velocity()
					VelocityObject.Settings.RemoveTime = 0.5
					VelocityObject.Settings.Controllable = true
					VelocityObject.Settings.Z = -45
					VelocityObject:Fire()
					
					self.LuaCharacter.Model:SetAttribute("MaxRed", nil)
					self:FireVFX("Gojo/Max Red", "Hit", self.LuaCharacter.RootPart)

					self.Animations.Windup:Stop(); self.Animations.Hit:Play()
					VictimCombat.Animations.GrabVictims.MaxRed:Play()

					local StopAutoRotate = Utility.StopAutoRotate(self.LuaCharacter.Humanoid)
					local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.identity)

					local Thread = coroutine.create(function()
						task.wait(2)

						self:FireVFX("Gojo/Max Red", "Red", self.LuaCharacter.RootPart, self.LuaCharacter.RightArm)

						task.wait(2.5)

						self:FireVFX("Gojo/Max Red", "Blast", self.LuaCharacter.RootPart)

						GrabObject.Destroy()
						
						self.Combat.Hitbox:Destruction(CFrame.new(0, 0, -37.5), Vector3.new(15, 10, 75), 10)

						if CurrentVictim == VictimLuaCharacter.Model then
							local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -25), Vector3.new(50, 10, 50))

							AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
								self.Combat:Afflict(NewVictimLuaPlayer, {
									BreakBlock = true,
									Damage = 12.5,
									Ragdoll = 2,
									TriggerActiveCounterOverOrEqualLevel = -1,
									Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 115 + Vector3.yAxis * 45, 0.1}
								})
							end)

							AOEHitbox:BeginCast(0.05)
							
							self:Afflict(VictimLuaPlayer, {
								FinisherKill = (VictimLuaCharacter.Humanoid.Health <= 30),
								ExcludeAttempts = true,
								Damage = 30
							})

							VictimCombat.Animations.GrabVictims.MaxRed:Stop(0)

							VictimLuaCharacter.RootPart.AssemblyLinearVelocity = Vector3.zero
							VictimLuaCharacter.RootPart.AssemblyAngularVelocity = Vector3.zero

							VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -5) * CFrame.Angles(0, math.pi, 0))

							local VelocityObject = self:VelocityOn(VictimCombat)
							
							if VelocityObject then
								VelocityObject.Settings.RemoveTime = 0.1
								VelocityObject.Settings.Velocity = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 175 + Vector3.yAxis * 75
								VelocityObject:Fire()
							end
							
							self:Afflict(VictimLuaPlayer, {
								ExcludeAttempts = true;
								Ragdoll = 3;
							})

							self.Combat:VictimImpactGround(VictimLuaPlayer)
						end

						task.wait(0.5)

						StopAutoRotate:Destroy()
						self:Close()
					end)

					self.Thread.OnClosed:Connect(function()
						if coroutine.status(Thread) == "suspended" then
							task.cancel(Thread)
						end; Thread = nil
						
						local Purple, Matched = self.Combat:MatchAttack("Maximum Output - Purple", Enum.KeyCode.Five)

						if Matched then
							if Purple.CompletedStep1 and Purple.HitBlue then
								Purple:CompleteStep2()
							else
								Purple.HitRed = true
								Purple:CompleteStep1()
							end
						end
						
						VictimLuaCharacter:RestartRespawnTimer()
						
						VictimCombat:StackState("HitboxImmunity", false)
						self.Combat:StackState("HitboxImmunity", false)

						self.Animations.Hit:Stop()
						VictimCombat.Animations.GrabVictims.MaxRed:Stop()

						StopAutoRotate:Destroy()
						GrabObject.Destroy(0)
						VictimCombat:Unstun()
					end)

					coroutine.resume(Thread)
				end
			end)

			Hitbox:BeginCast(0.1)

			Hitbox.Events.OnCastEnded:Once(function()
				if not self.Hit then
					self.Combat:StackState("GrabIFrames", false)
				end
			end)
		end)()
	end))
	
	task.wait(7)

	if not self.Hit then
		self.Animations.Windup:Stop(0.3)
		self:Close()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack