local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end;

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self.Hit = false
	self.FinisherHit = false
	
	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 1, -10)
	Hitbox.Params.Size = Vector3.new(20, 12.5, 20)
	
	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Difference : Vector3 = (VictimLuaCharacter.RootPart.Position - self.LuaCharacter.RootPart.Position)

		--local Magnitude = math.sqrt(Difference.X ^ 2 + Difference.Y ^ 2 + Difference.Z ^ 2)
		--local Unit = Difference / Magnitude

		local YDifference = self.Combat:CalculateYDifference(VictimLuaPlayer)

		if Difference.Magnitude <= 10 and YDifference > -2 then
			local Finisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= 15)

			local Validated = self:Afflict(VictimLuaPlayer, {
				BreakBlock = true,
				Damage = not Finisher and 15
			})

			if Validated then
				self.Hit = true

				if Finisher and not self.FinisherHit then
					self.FinisherHit = true

					VictimCombat:StackState("HitboxImmunity", true)
					self.Combat:StackState("HitboxImmunity", true)

					local StopAutoRotate = Utility.StopAutoRotate(self.LuaCharacter.Humanoid)
					local VictimStopAutoRotate = Utility.StopAutoRotate(VictimLuaCharacter.Humanoid)
					VictimLuaCharacter:StopRespawnTimer()

					VictimCombat.Animations.GrabVictims.VectorPunchFinisher:Play(0.1, 1, 0)
					self.Animations.Windup:Stop(0.3)
					self.Animations.Finisher:Play(0.3)

					self.Thread.Job:Task(task.delay(0.325, function()
						VictimCombat.Animations.GrabVictims.VectorPunchFinisher:AdjustSpeed(1)
					end))

					local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.Angles(0, math.pi, 0))

					self.Thread.OnClosed:Connect(function()
						StopAutoRotate:Destroy()
						VictimStopAutoRotate:Destroy()

						if GrabObject then
							GrabObject.Destroy(0)
							VictimCombat:Unstun()
						end
						
						VictimLuaCharacter:RestartRespawnTimer()
						
						self:FireReliableVFX("Accelerator/Vector Punch", "ScreenFXEnd", self.LuaCharacter.RootPart)
						self:FireReliableVFX("Accelerator/Vector Punch", "ScreenFXEnd", VictimLuaCharacter.RootPart)
						
						VictimCombat:StackState("HitboxImmunity", false)
						self.Combat:StackState("HitboxImmunity", false)
						
						if VictimCombat.Animations.GrabVictims and VictimCombat.Animations.GrabVictims.VectorPunchFinisher then
							VictimCombat.Animations.GrabVictims.VectorPunchFinisher:Stop()
						end
					end)

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("swingdown"):Once(function()
						self:FireReliableVFX("Accelerator/Vector Punch", "FinisherSwingDown", self.LuaCharacter.RootPart)
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("throwdown"):Once(function()
						self:FireReliableVFX("Accelerator/Vector Punch", "FinisherThrowDown", self.LuaCharacter.RootPart)
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("kickdownpause"):Once(function()
						self:FireReliableVFX("Accelerator/Vector Punch", "FinisherKickDownPause", self.LuaCharacter.RootPart)
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("kickdownresume"):Once(function()
						self:FireReliableVFX("Accelerator/Vector Punch", "FinisherKickDownResume", self.LuaCharacter.RootPart)
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("stomp"):Once(function()
						self:FireReliableVFX("Accelerator/Vector Punch", "FinisherStomp", self.LuaCharacter.RootPart,  VictimLuaCharacter.RootPart)
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("position"):Once(function()
						self:FireReliableVFX("Accelerator/Vector Punch", "FinisherPosition", self.LuaCharacter.RootPart)
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("punchpause"):Once(function()
						self:FireReliableVFX("Accelerator/Vector Punch", "FinisherPunchPause", self.LuaCharacter.RootPart,  VictimLuaCharacter.RootPart)
					end))

					self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("punchresume"):Once(function()
						self:FireReliableVFX("Accelerator/Vector Punch", "FinisherPunchResume", self.LuaCharacter.RootPart,  VictimLuaCharacter.RootPart)

						GrabObject.Destroy(1.5); GrabObject = nil
						VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0))

						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							FinisherKill = true,
							Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 165 + Vector3.yAxis * 115, 0.05}
						})

						VictimCombat.Ragdoll:Toggle(true)
						self.Combat:VictimImpactGround(VictimLuaPlayer)

						VictimCombat:Unstun()

						task.wait(0.4)

						self.Animations.Finisher:Stop(0.4)
						self.Animations.FinisherFadeFix:Play()

						task.delay(0.4, function()
							self.Animations.FinisherFadeFix:Stop(0.6)
						end)

						task.wait(0.5)

						self:Close()
					end))
					
					self:FireReliableVFX("Accelerator/Vector Punch", "FinisherHit", self.LuaCharacter.RootPart)
				else
					VictimCombat:TrueStun()
					VictimCombat.Ragdoll:ForceToggleOff()

					VictimLuaCharacter.RootPart.AssemblyAngularVelocity = Vector3.zero
					VictimLuaCharacter.RootPart.AssemblyAngularVelocity = Vector3.zero
					VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0))

					self:FireVFX("Accelerator/Vector Punch", "Hit", VictimLuaCharacter.RootPart)
					
					local VelocityObject = self:VelocityOn(VictimCombat);
					VelocityObject.Settings.RemoveTime = 0.035
					VelocityObject.Settings.Velocity = (self.LuaCharacter.RootPart.CFrame.LookVector * 90 + Vector3.yAxis * 62.5)
					VelocityObject.Settings.NeedsVelocityAttribute = true
					VelocityObject:Fire()

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true;
						Ragdoll = 1.5;
					})
			
					self.Combat:VictimImpactGround(VictimLuaPlayer)
					VictimCombat:Unstun() 

					task.delay(0.2, function()
						if not self.FinisherHit then
							self.Animations.Windup:Stop(0.3)
							self:Close()
						end
					end)
				end
			end
		else
			local Validated = self:Afflict(VictimLuaPlayer, {
				Damage = 3,
			})

			if Validated then
				if VictimCombat:GetState("Ragdolled") then
					local VelocityObject = self:VelocityOn(VictimCombat)
					VelocityObject.Settings.RemoveTime = 0.1
					VelocityObject.Settings.Velocity = Difference.Unit * 50 + Vector3.yAxis * 60
					VelocityObject:Fire()
				else
					self.Combat:TSBPushVictim(VictimLuaPlayer, {
						DurationMultiplier = 0.85,
						LookVectorInsteadOfDifference = true,
						LandedRollVelocityZ = 130,
						LandedRollDuration = 0.855
					})
				end
			end
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(15)
		
		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	self.Animations.Windup:GetMarkerReachedSignal("charge"):Wait()
	
	self.Animations.Windup:AdjustSpeed(1)

	self:FireVFX("Accelerator/Vector Punch", "Charge", self.LuaCharacter.RightArm)
	
	self.Animations.Windup:GetMarkerReachedSignal("shoot"):Wait()
	
	local StopAutoRotate = Utility.StopAutoRotate(self.LuaCharacter.Humanoid)
	
	self.Thread.OnClosed:Connect(function()
		StopAutoRotate:Destroy()
	end)
	
	local Rnd = Random.new();
	
	self.Combat.Hitbox:CreateHavocReplicated({
		parameters = {
			origin = Hitbox:GetCFrame(),
			shape = "Sphere", 
			radius = 9,
			block_size = 6,
		},
		debris = {
			scale = 0.9,
			radius = 17,
			velocity = function(part)
				return self.LuaCharacter.RootPart.CFrame.LookVector * math.random(35, 45) + Rnd:NextUnitVector() * 30 + Vector3.yAxis * 25;
			end,
		},
	});
	
	Hitbox:Detect()
	
	self.Combat.Hitbox:Destruction(Hitbox.Params.Offset, Hitbox.Params.Size, 2, nil, {
		debris_velocity = Hitbox.Adornee.CFrame.LookVector * 50 + Vector3.yAxis * 35
	})

	self:FireReliableVFX("Accelerator/Vector Punch", "Uncharge", self.LuaCharacter.RightArm)
	self:FireVFX("Accelerator/Vector Punch", "Shoot", self.LuaCharacter.RootPart, self.LuaCharacter.RootPart.CFrame * CFrame.new(0, -0.5, -4), self.Hit)

	self.Animations.Windup:AdjustSpeed(0.8)

	task.wait(1.05)

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