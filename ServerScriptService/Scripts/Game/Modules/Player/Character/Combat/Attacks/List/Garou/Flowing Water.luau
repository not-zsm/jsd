local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(3)

	self.Hit = false
	
	local Push = self.Combat:Velocity()
	Push.Settings.RemoveTime = 0.15
	Push.Settings.MaxForce = Vector3.one * 80000
	self.Thread.Job:Task(Push)
	
	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -5)
	Hitbox.Params.Size = Vector3.new(7, 7, 6)
	Hitbox.Params.DestroyOnEndCast = false
	Hitbox.Params.MaxTargets = 1

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true,
			YDifferenceValue = -2
		})

		if Validated then
			self.Hit = true
			Push:Remove()

			local CurrentVictim = VictimLuaCharacter.Model
			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0))
			local Ended = false

			self.Thread.OnClosed:Connect(function()
				if not Ended then
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end
			end)
			
			local function Hit()
				if CurrentVictim == VictimLuaCharacter.Model then
					self:FireVFX("Garou/Flowing Water", "Hit", self.LuaCharacter.Model, VictimLuaCharacter.RootPart)

					local VelocityObject = self.Combat:Velocity()
					VelocityObject.Settings.Duration = 0.45
					VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
					VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
					VelocityObject.Settings.Controllable = true
					VelocityObject.Settings.Z = 110
					VelocityObject.Settings.DoesntNeedVelocityAttribute = true
					VelocityObject:Fire()
					
					VictimCombat:PlayRandomHitReaction(4)
				end

				local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -5), Vector3.one * 8)

				AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
					local NewVictimLuaCharacter = NewVictimLuaPlayer.Character

					local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
						Damage = 3,
						Stun = 1.25,
						YDifferenceValue = 0,
						Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 65, 0.1}
					})

					if Validated then
						self:FireVFX("Garou/Flowing Water", "Hit", self.LuaCharacter.Model, NewVictimLuaCharacter.RootPart)
						NewVictimLuaCharacter.Combat:PlayRandomHitReaction(4)
					end
				end)

				AOEHitbox:BeginCast(0.05)
			end

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("hit"):Connect(Hit))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("finalhit"):Once(function()
				Ended = true

				self:FireVFX("Garou/Flowing Water", "FinalHit", VictimLuaCharacter.RootPart)
				
				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 0.02
				VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				VelocityObject.Settings.Z = 10
				VelocityObject:Fire()
				
				GrabObject.Destroy(0)

				if CurrentVictim == VictimLuaCharacter.Model then
					local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, -5), Vector3.one * 8)

					AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
						local NewVictimLuaCharacter = NewVictimLuaPlayer.Character

						local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
							Damage = 5,
							Ragdoll = 2.25,
							YDifferenceValue = 0,
							Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 55 + Vector3.yAxis * 15, 0.1}
						})

						if Validated then
							self:FireVFX("Garou/Flowing Water", "Hit", self.LuaCharacter.Model, NewVictimLuaCharacter.RootPart)
						end
					end)
					
					AOEHitbox:BeginCast(0.05)
					
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = 15,
					})
					
					VictimLuaCharacter:SetCollisionGroup("NoPlayerCollision")
					VictimCombat.Ragdoll:SetCollisionGroupOfColliders("NoPlayerCollision")

					task.delay(0.3, function()
						if not VictimCombat:GetState("Grabbed") then
							VictimLuaCharacter:SetCollisionGroup("Player")
						end

						VictimCombat.Ragdoll:SetCollisionGroupOfColliders("Default")
					end)

					VictimLuaCharacter.RootPart.CFrame = self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -4.25) * CFrame.Angles(0, math.pi, 0)

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true;
						Ragdoll = 2.25;
					})
					--VictimCombat.Ragdoll:Toggle(true, 2.25)
					
					local VelocityObject = self:VelocityOn(VictimCombat)
					VelocityObject.Settings.RemoveTime = 0.1
					VelocityObject.Settings.MaxForce = Vector3.one * 80000
					VelocityObject.Settings.Velocity = self.LuaCharacter.RootPart.CFrame.LookVector * 55 + Vector3.yAxis * 15
					VelocityObject:Fire()

					VictimCombat:Unstun()
				end

				self:Close()
			end))
			
			self.Animations.Windup:Stop(); self.Animations.Hit:Play()
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(17)
		
		self.Combat:StackState("Attacking", false)
	end)

	local Connection = self.Thread.OnCancelled:Connect(function()
		self.Combat:TimesSpeed(3)
	end)

	self:FireVFX("Garou/Flowing Water", "DualHandWaterStream", self.LuaCharacter.Model, 0.75)
	self.Animations.Windup:GetMarkerReachedSignal("swing"):Wait()
	self:FireVFX("Garou/Flowing Water", "Swing", self.LuaCharacter.RootPart)
	
	Connection:Disconnect()
	
	Push.Settings.Velocity = self.Combat:GetSimulatedRoot().CFrame.LookVector * 60
	Push:Fire()

	self.Combat:TimesSpeed(3)
	
	self.Animations.Windup:GetMarkerReachedSignal("hit"):Wait()
	Hitbox:BeginCast(0.2)

	task.wait(0.5)

	if not self.Hit then
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