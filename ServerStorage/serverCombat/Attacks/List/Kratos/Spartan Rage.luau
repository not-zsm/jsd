local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local ServerStorage = game:GetService("ServerStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(100)

	self.Hit = false

	local Weapons = self.Combat.Attacks.Weapons

	if Weapons then
		Weapons:SetCurrent("Fists")
	end

	self.Thread.CancelJob:Task(
		self:CreateMoveSFX("Kratos", "Spartan Rage")
	)

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 1.5, -4.5)
	Hitbox.Params.Size = Vector3.new(9, 8, 11)
	Hitbox.Params.DestroyOnEndCast = false
	Hitbox.Params.MaxTargets = 1

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		self.Hit = self:Afflict(VictimLuaPlayer, {
			Damage = {Amount = 5, DontKill = true},
			BreakBlock = true,
		})

		if self.Hit then
			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0))
			
			local VictimAnimation = VictimLuaCharacter:LoadAnimation(replicatedStorage.Animations.Attacks.Kratos["Spartan Rage"].Victim)
			local FinisherVictimAnimation = VictimLuaCharacter:LoadAnimation(replicatedStorage.Animations.Attacks.Kratos["Spartan Rage"].FinisherVictim)

			self.Thread.OnCancelled:Connect(function()
				if VictimAnimation and VictimAnimation.IsPlaying then
					VictimAnimation:Stop()
				end
				
				if FinisherVictimAnimation and FinisherVictimAnimation.IsPlaying then
					FinisherVictimAnimation:Stop()
				end

				GrabObject.Destroy(0)
				VictimCombat:Unstun()
			end)
			
			local function Finisher()
				self.Combat:StackState("HitboxImmunity", true)
				VictimCombat:StackState("HitboxImmunity", true)
				
				GrabObject.SetOffset(CFrame.Angles(0, math.pi, 0))
				
				VictimLuaCharacter:StopRespawnTimer()
				
				self.Combat:HideUI(true)
				VictimCombat:HideUI(true)
				
				do
					local Weapons = self.Combat.Attacks.Weapons

					if Weapons then
						Weapons:SetCurrent("Chained Blades")
						Weapons:ToggleChainedBladeTrails(true)
					end
				end
				
				self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("final"):Once(function()
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						FinisherKill = true,
						Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 75 + Vector3.yAxis * 75, 0.1}
					})
					
					self:FireReliableVFX("Global/Elemental", "Burn", VictimLuaCharacter.Model)
					
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end))
				
				local SlashHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 1.5, -3), Vector3.new(17, 11, 32.5))

				SlashHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
					self.Combat:Afflict(NewVictimLuaPlayer, {
						DontCheckBlock = true,
						Damage = 0.75,
						TrueStun = 1,
						PlayRandomHitReaction = true,
						Velocity = {Vector3.yAxis * 2.5, 0.25}
					})
				end)
				
				self.Thread.Job:Task(SlashHitbox)
				
				local VFXMarker : RBXScriptConnection; VFXMarker = self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
					local IsSlashing = (Parameter == "6" or Parameter == "7" or Parameter == "8")
					local IsSlamming = (Parameter == "9" or Parameter == "10" or Parameter == "11" or Parameter == "12" or Parameter == "13") or (Parameter == "a1" or Parameter == "a2")
					-- jesus 😭
					
					if IsSlashing or IsSlamming then
						SlashHitbox:Reset()
						SlashHitbox:Detect()
						
					elseif (Parameter == "4") then -- head stab
						local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -1.565), Vector3.one * 10)

						AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
							self.Combat:Afflict(NewVictimLuaPlayer, {
								Damage = 1.5,
								Stun = 1.5,
								PlayRandomHitReaction = true,
								Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 5, 0.1}
							})
						end)

						AOEHitbox:Detect()
						task.defer(AOEHitbox.Destroy, AOEHitbox)
						
					elseif (Parameter == "5") then -- slam
						
						local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -4.158), Vector3.one * 20)

						AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
							self.Combat:Afflict(NewVictimLuaPlayer, {
								DontCheckBlock = true,
								Damage = 5,
								Ragdoll = 2,
								Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 10 + Vector3.yAxis * 35, 0.1}
							})
						end)

						AOEHitbox:Detect()
						task.defer(AOEHitbox.Destroy, AOEHitbox)
						
					elseif (Parameter == "6") then -- slash forward
						local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 1.5, -3), Vector3.new(10, 11, 15))

						AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
							self.Combat:Afflict(NewVictimLuaPlayer, {
								DontCheckBlock = true,
								Damage = 2.5,
								TrueStun = 2,
								PlayRandomHitReaction = true,
								Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 7.5 + Vector3.yAxis * 2.5, 0.25}
							})
						end)
		
						AOEHitbox:Detect()
						task.defer(AOEHitbox.Destroy, AOEHitbox)
						
					elseif (Parameter == "14") then
						local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -15.508), Vector3.one * 40)

						AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
							self.Combat:Afflict(NewVictimLuaPlayer, {
								DontCheckBlock = true,
								Damage = 7.5,
								TrueStun = 2.5,
								PlayRandomHitReaction = true,
								Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 7.5 + Vector3.yAxis * 7.5, 0.15}
							})
						end)

						AOEHitbox:Detect()
						task.defer(AOEHitbox.Destroy, AOEHitbox)
						
					elseif (Parameter == "15") then
						local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -5.691), Vector3.new(15, 10, 35))

						AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
							self.Combat:Afflict(NewVictimLuaPlayer, {
								DontCheckBlock = true,
								Damage = 10,
								Ragdoll = 2,
								Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 50 + Vector3.yAxis * 50, 0.1}
							})
						end)

						AOEHitbox:Detect()
						task.defer(AOEHitbox.Destroy, AOEHitbox)
					end
				end))
				
				self.Thread.Job:Task(self.Animations.Finisher.Stopped:Once(function()
					self:Close()
				end))
				
				self.Thread.OnClosed:Connect(function()
					do
						local Weapons = self.Combat.Attacks.Weapons

						if Weapons then
							Weapons:ToggleChainedBladeTrails(false)
						end
					end
					
					VictimLuaCharacter:RestartRespawnTimer()
					
					self.Combat:HideUI(false)
					VictimCombat:HideUI(false)
					
					self.Combat:StackState("HitboxImmunity", false)
					VictimCombat:StackState("HitboxImmunity", false)
				end)
				
				self.Animations.Hit:Stop(0)
				VictimAnimation:Stop(0)
				
				self.Animations.Finisher:Play(0)
				FinisherVictimAnimation:Play(0)
				
				self:FireReliableVFX("Kratos/Spartan Rage Finisher", "Start", self.LuaCharacter.Model, VictimLuaCharacter.Model)
			end

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("hit"):Connect(function(Parameter : string)
				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 0.58
				VelocityObject.Settings.RemoveTime = 0.8
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = 60
				VelocityObject:Fire()

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {Amount = 3, DontKill = true},
				})

				self.Combat.Hitbox:Destruction(CFrame.identity, Vector3.one * 8.5, 3)

				local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -4.5), Vector3.new(9, 8, 11))

				AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
					local NewVictimLuaCharacter = NewVictimLuaPlayer.Character

					local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
						Damage = 1.5,
						Stun = 0.75,
						Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 35, 0.1}
					})

					if Validated then
						NewVictimLuaCharacter.Combat:PlayRandomHitReaction(3)
					end
				end)

				AOEHitbox:BeginCast(0.05)
			end))

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("finalhit"):Once(function()
				self.Combat.Hitbox:Destruction(CFrame.identity, Vector3.one * 10, 4)

				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 0.675
				VelocityObject.Settings.RemoveTime = 0.675
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = 50
				VelocityObject:Fire()

				self.Thread.Job:Task(VelocityObject)

				if self:IsFinisherEnabled() and VictimLuaCharacter.Humanoid.Health < 15 then
					Finisher()
				else
					local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -4.5), Vector3.new(9, 8, 11))

					AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
						local NewVictimLuaCharacter = NewVictimLuaPlayer.Character

						local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
							Damage = 5,
							Ragdoll = 2,
							Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 65 + Vector3.yAxis * 30, 0.1}
						})

						if Validated then
							NewVictimLuaCharacter.Combat:PlayRandomHitReaction(3)
						end
					end)

					AOEHitbox:Detect()
					task.defer(AOEHitbox.Destroy, AOEHitbox)

					GrabObject.Destroy(0.4)
					VictimAnimation:Stop(0)

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = 6,
					})

					self.Combat:PushSkidVictim(VictimLuaPlayer, {
						TimeTilGroundDetection = 0.5,
						StartVelocityXZ = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 75,
						StartVelocityY = Vector3.yAxis * 200,
						StartDuration = 0.45,
						LandedRollVelocityZ = 90,
						LandedRollDuration = 0.8
					})
					
					VictimCombat:Unstun()

					task.wait(0.4)

					self:Close()
				end
			end))

			self.Animations.Windup:Stop(0)
			self.Animations.Hit:Play(0)

			if VictimAnimation then
				VictimAnimation:Play(0)
			end
			
			self.Thread.CancelJob:Task(
				self:CreateMoveSFX("Kratos", "Spartan Rage", "Land")
			)

			self:FireReliableVFX("Kratos/Spartan Rage", "Hit", self.LuaCharacter.Model, VictimLuaCharacter.Model)

			local VelocityObject = self.Combat:Velocity()
			VelocityObject.Settings.Duration = 0.65
			VelocityObject.Settings.RemoveTime = 0.7
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 60
			VelocityObject:Fire()
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(16)
		
		self.Combat:TimesSpeed(100)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("jump"):Once(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 1.2
		VelocityObject.Settings.RemoveTime = 1.2
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 30
		VelocityObject:Fire()

		self.Thread.Job:Task(VelocityObject)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Once(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 0.9
		VelocityObject.Settings.RemoveTime = 0.9
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 20
		VelocityObject:Fire()

		self.Thread.Job:Task(VelocityObject)

		Hitbox:BeginCast(0.15)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Once(function()
		if not self.Hit then
			self:Close()
		end
	end))
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