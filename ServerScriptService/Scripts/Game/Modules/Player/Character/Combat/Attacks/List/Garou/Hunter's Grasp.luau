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
	self.Combat:DivideSpeed(4)

	self.GraspedOne = false
	
	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, -4, -3.5)
	Hitbox.Params.Size = Vector3.new(4, 5, 5.5)
	Hitbox.Params.DestroyOnEndCast = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true
		})

		if Validated then
			local WasRagdolled = VictimCombat:GetState("Ragdolled")

			if not self.GraspedOne then
				self.GraspedOne = true

				local GrabbedVictimLuaPlayer = nil
				local GrabObject = nil
				
				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("grab"):Once(function()
					local GrabHitbox = self:CreateHitbox(false);
					GrabHitbox.Params.Offset = CFrame.new(0, 0, -3)
					GrabHitbox.Params.Size = Vector3.new(3, 9, 6)
					GrabHitbox.Params.MaxTargets = 1
					
					GrabHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
						local NewVictimLuaCharacter = NewVictimLuaPlayer.Character
						local NewVictimCombat = NewVictimLuaCharacter.Combat

						local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
							BreakBlock = true
						})
						
						if Validated then
							GrabHitbox:EndCast()
							
							GrabObject = self.Combat:GrabVictim(NewVictimLuaPlayer, self.LuaCharacter.LeftArm, CFrame.new(0, -1.25, 1.5) * CFrame.Angles(-math.pi / 2, math.pi, 0))
							GrabbedVictimLuaPlayer = NewVictimLuaPlayer
						end
					end)
					
					GrabHitbox:BeginCast(0.25)
				end))
				
				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("throw"):Once(function()
					if GrabbedVictimLuaPlayer and GrabObject then
						local GrabbedVictimLuaCharacter = GrabbedVictimLuaPlayer.Character
						local GrabbedVictimCombat = GrabbedVictimLuaCharacter.Combat
						
						GrabObject.Destroy(0.3)
						GrabbedVictimLuaCharacter.RootPart.CFrame = self.Combat:GetSimulatedRoot().CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0)
						
						if not WasRagdolled then
							GrabbedVictimCombat:StackState("StunImmunity", true, 1) -- so u cant m1
						end
						
						self.Combat:TSBPushVictim(GrabbedVictimLuaPlayer, {
							LandedRollVelocityZ = WasRagdolled and 110 or 160,
							LandedRollDuration = WasRagdolled and 0.775 or 0.925
						})

						GrabbedVictimCombat:Unstun()
						
						self:Close()
					else
						task.wait(0.3)
						
						self:Close()
					end
				end))
				
				self.Animations.Windup:Stop(); self.Animations.Hit:Play()
			end
			
			local VelocityObject = self:VelocityOn(VictimCombat)
			VelocityObject.Settings.RemoveTime = 0.1
			VelocityObject.Settings.MaxForce = Vector3.one * 80000
			VelocityObject.Settings.Velocity = Vector3.yAxis * 25
			VelocityObject:Fire()

			self:Afflict(VictimLuaPlayer, {
				ExcludeAttempts = true;
				Ragdoll = 1.5;
			})
			
			VictimCombat:StackState("CannotDash", true, 1.5)
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(17)

		self.Combat:TimesSpeed(4)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Animations.Windup:GetMarkerReachedSignal("stomp"):Wait()
	
	self:FireVFX("Garou/Hunter's Grasp", "Stomp", self.LuaCharacter.RootPart)
	Hitbox:BeginCast(0.1)
	
	Hitbox.Events.OnCastEnded:Once(function()
		if not self.GraspedOne then
			self.Combat:DivideSpeed(10)
			
			self.Thread.OnCancelled:Connect(function()
				self.Combat:TimesSpeed(10)
			end)
		end
	end)

	task.wait(0.7)

	if not self.GraspedOne then
		self.Combat:TimesSpeed(10)
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