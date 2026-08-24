local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )
local VelocityUtil = require( replicatedStorage.modules.shared.Game.Velocity.VelocityUtil )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )


local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)


----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)

	self.Hit = false
	
	if self.LuaPlayer.IsNPC then
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 1.6
		VelocityObject.Settings.RemoveTime = 1.8
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 85000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 32.5;
		VelocityObject:Fire();
	end
	
	local GrabHitbox = self:CreateHitbox()
	GrabHitbox.Params.Offset = CFrame.new(0, 0, -6)
	GrabHitbox.Params.Size = Vector3.new(7, 9, 8)
	GrabHitbox.Params.DestroyOnEndCast = false
	GrabHitbox.Params.MaxTargets = 1
	
	GrabHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true
		})

		if Validated then
			GrabHitbox:EndCast()
			
			local function Damage(Value : number)
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {DontKill = true, Amount = Value},
				})
			end;
			
			if self.LuaPlayer.IsNPC then
				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 3.5
				VelocityObject.Settings.RemoveTime = 3.75
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 85000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = 37.5;
				VelocityObject:Fire();
			end

			self.Hit = true
			--self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
			
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat
			
			local Offset = CFrame.new(0, 0, -1.793) * CFrame.Angles(0, math.pi, 0)
			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, Offset)
			local VictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(replicatedStorage.animations.Attacks.invincible["Visceral Drive"].Victim)
			
			VictimLuaCharacter:StopRespawnTimer()
			
			local DestructionClean
			
			local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -4), Vector3.one * 14)

			AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
				self.Combat:Afflict(NewVictimLuaPlayer, {
					BreakBlock = false,
					Ragdoll = 2,
					Velocity = {self.LuaCharacter.RootPart.CFrame.RightVector * 20 + Vector3.yAxis * 10, 0.1}
				})
				
				AOEHitbox:RemoveHumanoid(NewVictimLuaPlayer.Character.Humanoid)
			end)
			
			local EndAOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -4), Vector3.one * 14)

			EndAOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
				self.Combat:Afflict(NewVictimLuaPlayer, {
					Damage = 10,
					BreakBlock = true,
					Ragdoll = 2,
					Velocity = {self.Combat:GetSimulatedRoot().CFrame.LookVector * 60 + Vector3.yAxis * 35, 0.1}
				})
			end)
			
			self.Animations.Windup:Stop()
			self.Animations.Hit:Play()
			
			if VictimAnimation then
				VictimAnimation:Play(0)
			end
			
			self:FireReliableVFX("Invincible/Visceral Drive", "Hit", self.LuaCharacter.Model)
			
			self.Thread.OnClosed:Connect(function()
				VictimLuaCharacter:RestartRespawnTimer()

				if VictimAnimation then
					VictimAnimation:Stop()
				end
				
				if not GrabObject.Destroyed then
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end
			end)
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("VFX"):Connect(function(Parameter)
				if Parameter == "7" then
					if (DestructionClean ~= nil) then
						DestructionClean()
					end
					
					if self:IsFinisherEnabled() and VictimLuaCharacter.Humanoid.Health <= 15 then
						self.Animations.Hit:Stop()
						self.Animations.UserFinisher:Play(0)
						
						local FinisherVictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(replicatedStorage.animations.Attacks.invincible["Visceral Drive"].VictimFinisher)
						
						if FinisherVictimAnimation then
							FinisherVictimAnimation:Play(0)
						end
						
						self:CreateMoveSFX("invincible", script.Name, "FinisherSFX")
		
						self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
						
						self.Combat:StackState("HitboxImmunity", true)
						VictimCombat:StackState("HitboxImmunity", true)

						self.Combat:HideUI(true)
						VictimCombat:HideUI(true)

						self.LuaCharacter:Anchor(true)

						self.Thread.OnClosed:Connect(function()
							if FinisherVictimAnimation then
								FinisherVictimAnimation:Stop()
							end
						
							self.LuaCharacter:Anchor(false)
							
							self.Combat:HideUI(false)
							VictimCombat:HideUI(false)

							VictimCombat:StackState("HitboxImmunity", false)
							self.Combat:StackState("HitboxImmunity", false)
							
							self:AddCooldown(14)
						end)
						
						self.Thread.Job:Task(self.Animations.UserFinisher:GetMarkerReachedSignal("lasthit"):Connect(function()	
							GrabObject.Destroy(0)
							
							VictimLuaCharacter.Model:PivotTo(VictimLuaCharacter.RootPart.CFrame * CFrame.new(-3.1, 6, 8))
							FinisherVictimAnimation:Stop()

							self:Afflict(VictimLuaPlayer, {
								ExcludeAttempts = true,
								FinisherKill = true,
							})

							VictimCombat:Unstun()
							
							task.wait(0.315)
							
							self.Combat:ToggleHeadMovement(false)
							
							self.Animations.UserFinisher:Stop(0)
						end))
						
						self:FireReliableVFX("Invincible/Visceral Drive", "Finisher", self.LuaCharacter.Model, VictimLuaCharacter.Model)
						
						self.Thread.Job:Task(self.Animations.UserFinisher.Stopped:Connect(function()
							self.LuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(3.2, 0, -27))
							
							self.Combat:ToggleHeadMovement(true)
							
							self:Close()
						end))
					else
						GrabObject.Destroy(0)
						
						EndAOEHitbox:BeginCast(0.1)

						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							Ragdoll = 2,
							Velocity = {self.Combat:GetSimulatedRoot().CFrame.LookVector * 70 + Vector3.yAxis * 50, 0.1},
							Damage = 10
						})

						VictimCombat:Unstun()

						task.wait(0.3)

						self.Animations.Hit:Stop(0.3)
						self:Close()
					end
				elseif Parameter == "6" then
					Damage(7)
					
					AOEHitbox:BeginCast(0.7)
					
					DestructionClean = self.Thread.Job:Task(self.Combat.Hitbox:ClientSidedDestructionLoop(CFrame.new(0, 0, -4), Vector3.one * 14, 2))
					
					task.spawn(function()
						local Rnd = Random.new();
						
						for i = 1, 7 do
							Damage(0.5)

							self.Combat.Hitbox:CreateHavocReplicated({
								parameters = {
									origin = AOEHitbox:GetCFrame(),
									shape = "Sphere", 
									radius = 7,
									block_size = 5,
								},
								debris = {
									scale = 0.9,
									velocity = function(part)
										return Rnd:NextUnitVector() * 15 + Vector3.yAxis * 20;
									end,
								},
							});
							
							task.wait(0.1)
						end
					end)
				else
					Damage(3)
				end
			end))
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(14)

		self.Combat:TimesSpeed(50)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hitboxstart"):Once(function()
		GrabHitbox:BeginCast(0.3)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hitboxstop"):Once(function()
		if not self.Hit then
			self.Animations.Windup:AdjustSpeed(0.6)
			
			task.wait(0.45)
			
			self:Close()
		end
	end))
	
	self:FireReliableVFX("Invincible/Visceral Drive", "Start", self.LuaCharacter.Model)
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