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
	self.Animations.Startup:Play()
	
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(6)
	
	self.Animations.Startup:AdjustSpeed(1.5)

	self.Hit = false

	local Weapons = self.Combat.Attacks.Weapons
	
	if Weapons then
		Weapons:SetCurrent("Chained Blades");
	else
		Weapons = {Blades = {Objects = {}}}; -- lol
	end;
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(12)

		self.Combat:TimesSpeed(6)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Startup:GetMarkerReachedSignal("left"):Once(function()
		self:FireReliableVFX("kratos/Chaos Run", "LeftStartup", self.LuaCharacter.RootPart)
	end))

	self.Thread.Job:Task(self.Animations.Startup:GetMarkerReachedSignal("right"):Once(function()
		self:FireReliableVFX("kratos/Chaos Run", "RightStartup", self.LuaCharacter.RootPart)
	end))

	self.Thread.Job:Task(self.Animations.Startup:GetMarkerReachedSignal("hit"):Once(function()
		self.Animations.Startup:AdjustSpeed(1)
		
		self:FireReliableVFX("kratos/Chaos Run", "FrontStartup", self.LuaCharacter.RootPart)

		local Hitbox = self:CreateHitbox(false);
		Hitbox.Params.Offset = CFrame.new(0, 0, -7)
		Hitbox.Params.Size = Vector3.new(10, 8, 14)
		Hitbox.Params.DestroyOnEndCast = false
		Hitbox.Params.MaxTargets = 1
		
		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Validated, Type = self:Afflict(VictimLuaPlayer, {
				Damage = 2,
			})

			if Validated then
				self.Hit = true

				local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -6) * CFrame.Angles(0, math.pi, 0))

				self.Thread.OnClosed:Connect(function()
					VictimCombat.Animations.GrabVictims.ChaosRun:Stop()
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end)

				self:FireReliableVFX("kratos/Chaos Run", "EnableFlames", self.LuaCharacter.RootPart, Weapons.Blades.Objects)

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("spinslash"):Once(function()
					self:FireReliableVFX("kratos/Chaos Run", "SpinSlash", self.LuaCharacter.RootPart)

					local VelocityObject = self.Combat:Velocity()
					VelocityObject.Settings.Duration =  0.75
					VelocityObject.Settings.RemoveTime = 0.8
					VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
					VelocityObject.Settings.Controllable = true
					VelocityObject.Settings.Z = 65
					VelocityObject:Fire()

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = {
							DontKill = true,
							Amount = 3
						}
					})

					self.Thread.Job:Task(VelocityObject)
				end))

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("startrun"):Once(function()
					self:FireReliableVFX("kratos/Chaos Run", "DisableFlames", self.LuaCharacter.RootPart)

					local VelocityObject = self.Combat:Velocity()
					VelocityObject.Settings.Duration = 2.2
					VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
					VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
					VelocityObject.Settings.Controllable = true
					VelocityObject.Settings.Z = 20
					VelocityObject:Fire()

					self.Thread.Job:Task(VelocityObject)
				end))

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("sparksstart"):Once(function()
					self:FireReliableVFX("kratos/Chaos Run", "SparksStart", Weapons.Blades.Objects)
				end))

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("sparksend"):Once(function()
					self:FireReliableVFX("kratos/Chaos Run", "SparksEnd", Weapons.Blades.Objects)
					self:FireReliableVFX("kratos/Chaos Run", "EnableFlames", self.LuaCharacter.RootPart, Weapons.Blades.Objects)
				end))

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("startspin"):Once(function()
					self:FireReliableVFX("kratos/Chaos Run", "StartSpin", self.LuaCharacter.RootPart)

					local SpinVelocity = self.Combat:Velocity()
					SpinVelocity.Settings.Duration = 1.5 
					SpinVelocity.Settings.RemoveTime = 1.8
					SpinVelocity.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
					SpinVelocity.Settings.Controllable = true
					SpinVelocity.Settings.Z = 45
					SpinVelocity:Fire()

					self.Thread.Job:Task(SpinVelocity)

					self.Thread.Job:Task(task.spawn(function()
						for Index = 1, 10 do
							self:FireReliableVFX("kratos/Chaos Run", "Hit", self.LuaCharacter.RootPart)
							
							self:Afflict(VictimLuaPlayer, {
								ExcludeAttempts = true,
								Damage = {
									DontKill = true,
									Amount = 0.25
								}
							})
							
							task.wait(0.1)
						end
					end))

					self.Thread.OnClosed:Connect(function() -- so it doesn't keep vfx on forever if attacker leaves mid spin o thx
						self:FireReliableVFX("kratos/Chaos Run", "StopSpin", self.LuaCharacter.RootPart)
						self:FireReliableVFX("kratos/Chaos Run", "DisableFlames", self.LuaCharacter.RootPart)
					end)
				end))

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("stopspin"):Once(function()
					self:FireReliableVFX("kratos/Chaos Run", "StopSpin", self.LuaCharacter.RootPart)
				end))

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("slash"):Once(function()
					self:FireReliableVFX("kratos/Chaos Run", "Slash", self.LuaCharacter.RootPart)

					local VelocityObject = self.Combat:Velocity()
					VelocityObject.Settings.Duration =  0.75
					VelocityObject.Settings.RemoveTime = 0.8
					VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
					VelocityObject.Settings.Controllable = true
					VelocityObject.Settings.Z = 65
					VelocityObject:Fire()

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = {
							DontKill = true,
							Amount = 1.25
						}
					})

					self.Thread.Job:Task(VelocityObject)
				end))

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("uppercut"):Once(function()
					self:FireReliableVFX("kratos/Chaos Run", "Uppercut", self.LuaCharacter.RootPart)

					local VelocityObject = self.Combat:Velocity()
					VelocityObject.Settings.Duration = 1.6
					VelocityObject.Settings.RemoveTime = 1.3
					VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 40000
					VelocityObject.Settings.Controllable = true
					VelocityObject.Settings.Z = 25
					VelocityObject:Fire()

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = {
							DontKill = true,
							Amount = 1.25
						}
					})

					self.Thread.Job:Task(VelocityObject)
				end))
				
				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("jump"):Once(function()
					self:FireReliableVFX("kratos/Chaos Run", "Jump", self.LuaCharacter.RootPart)
				end))

				local Endlag = 0.25

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("slam"):Once(function()
					self:FireReliableVFX("kratos/Chaos Run", "Slam", self.LuaCharacter.RootPart)
					self:FireReliableVFX("kratos/Chaos Run", "DisableFlames", self.LuaCharacter.RootPart)

					VictimCombat.Animations.GrabVictims.ChaosRun:Stop(0)
					GrabObject.Destroy(Endlag)

					--VictimCombat.Ragdoll:Toggle(true, 2 + Endlag)

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = 2.5,
						Ragdoll = 2 + Endlag,
					})

					VictimLuaCharacter.RootPart.CFrame *= CFrame.new(0, -0.5, 1) * CFrame.Angles(math.rad(45), 0, 0)

					local VelocityObject = self:VelocityOn(VictimCombat)
					VelocityObject.Settings.RemoveTime = 0.1
					VelocityObject.Settings.Velocity = self.LuaCharacter.RootPart.CFrame.LookVector * 5 - Vector3.yAxis * 25
					VelocityObject:Fire()

					VictimCombat:Unstun() 

					task.wait(Endlag)

					self:Close()
				end))

				self.Animations.Startup:Stop()
				self.Animations.Hit:Play()
				VictimCombat.Animations.GrabVictims.ChaosRun:Play()
			end
		end)

		Hitbox:BeginCast(0.1)
	end))

	task.wait(2)

	if self.Hit then
		return
	end

	self:Close()
end


function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.Hit = false
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack