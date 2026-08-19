local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes
local UIRemotes = Remotes.Combat.UI

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("GrabIFrames", true)
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)
	
	self.Thread.CancelJob:Task(self:CreateMoveSFX("Accelerator", "Vector Grasp"))

	self.Hit = false

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.MaxTargets = 1
	Hitbox.Params.DestroyOnEndCast = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat
		
		local Validated = self:Afflict(VictimLuaPlayer, {
			DontHitDeadPeople = true,
			BreakBlock = true
		})

		if Validated then
			self.Hit = true
			
			local ThrowOffsetFromRoot = -17.795
			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -3.2) * CFrame.Angles(0, math.pi, 0))
			
			self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
			
			self.Thread.OnClosed:Connect(function()
				self.Animations.Hit:Stop()
				VictimCombat.Animations.GrabVictims.Walk:Stop()
				
				GrabObject.Destroy(0.5)
				VictimCombat:Unstun()
			end)
			
			local Magnitude = (VictimLuaCharacter.RootPart.Position - self.LuaCharacter.RootPart.Position).Magnitude
			self.LuaCharacter.RootPart.CFrame = self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -(Magnitude / 1.05))
			
			self.Thread.CancelJob:Task(self:CreateMoveSFX("Accelerator", "Vector Grasp", "HitSFX"))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("hit"):Connect(function()
				self:FireReliableVFX("Accelerator/Vector Grasp", "Hit", self.LuaCharacter.RootPart)
				
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {
						DontKill = true,
						Amount = 2.5,
					},
				})
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("slam"):Once(function()
				self:FireReliableVFX("Accelerator/Vector Grasp", "Slam", self.LuaCharacter.RootPart)
				
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {
						DontKill = true,
						Amount = 8,
					},
				})
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("tphit"):Connect(function(Parameter : string)
				self:FireReliableVFX("Accelerator/Vector Grasp", "TpHit", self.LuaCharacter.RootPart, Parameter)
				
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {
						DontKill = true,
						Amount = 2,
					},
				})
			end))

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("kick"):Once(function()
				self:FireReliableVFX("Accelerator/Vector Grasp", "Kick", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart.Parent)
				
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {
						DontKill = true,
						Amount = 3,
					},
				})
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("grab"):Once(function()
				self:FireReliableVFX("Accelerator/Vector Grasp", "Grab", self.LuaCharacter.RootPart)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("grabcrack"):Once(function()
				self:FireReliableVFX("Accelerator/Vector Grasp", "GrabCrack", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart.Parent)
				
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {
						DontKill = true,
						Amount = 7.5,
					},
				})
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("victimshock"):Once(function() 
				self:FireReliableVFX("Accelerator/Vector Grasp", "TorsoShock", VictimLuaCharacter.Torso)
				
				task.spawn(function()
					for Index = 1, 7 do
						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							Damage = {
								DontKill = true,
								Amount = 0.5,
							},
						})

						task.wait(0.1)
					end
				end)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("throw"):Once(function()
				GrabObject.Destroy(0.5)
				
				VictimCombat.Animations.GrabVictims.Walk:Stop(0)
				VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, ThrowOffsetFromRoot - 6))
				
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Ragdoll = 2,
					Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 130 + Vector3.yAxis * 40, 0.1},
					Damage = 10
				})
				
				self:FireReliableVFX("Accelerator/Vector Grasp", "Throw", self.LuaCharacter.RootPart)
				
				VictimCombat:Unstun()
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("end"):Once(function()
				if not self.LuaPlayer.IsNPC then
					self.LuaPlayer.Remotes.ToggleHeadMovement:FireClient(self.LuaPlayer.Player, false)
				end
	
				task.wait()
				
				self.Animations.Hit:Stop(0)
				self.LuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, ThrowOffsetFromRoot))
				self:Close()
				
				task.wait(3 / 60)
				
				if not self.LuaPlayer.IsNPC then
					self.LuaPlayer.Remotes.ToggleHeadMovement:FireClient(self.LuaPlayer.Player, true)
				end
			end))
			
			self.Animations.Windup:Stop(0)
			self.Animations.Hit:Play()
			VictimCombat.Animations.GrabVictims.Walk:Play()
		end
	end)
	
	local StunHitbox = self:CreateHitbox(true);
	StunHitbox.Params.Size = self.Radius + 2
	StunHitbox.Params.Offset = CFrame.identity
	StunHitbox.Params.DestroyOnEndCast = false

	StunHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			DontHitDeadPeople = true,
			BreakBlock = true,
			TrueStun = 0.075,
		})
		
		if Validated then
			VictimCombat:DivideSpeed(5)
			
			local VelocityObject = self:VelocityOn(VictimCombat)
			VelocityObject.Settings.RemoveTime = 0.085
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
			VelocityObject.Settings.Velocity = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * -5
			VelocityObject:Fire()
			
			task.delay(0.125, function()
				VictimCombat:TimesSpeed(5)
			end)
		end
		
		task.delay(0.15, StunHitbox.RemoveHumanoid, StunHitbox, VictimLuaCharacter.Humanoid)
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(10)

		self.Combat:TimesSpeed(50)
		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("GrabIFrames", false)
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("footstep"):Connect(function(Parameter : string)
		self:FireReliableVFX("Accelerator/Vector Grasp", "Footstep", Parameter == "Left Leg" and self.LuaCharacter.LeftLeg.LeftFootAttachment or self.LuaCharacter.RightLeg.RightFootAttachment)
	end))

	self.Animations.Windup:GetMarkerReachedSignal("walk"):Wait()

	self:FireReliableVFX("Accelerator/Vector Grasp", "Walk", self.LuaCharacter.RootPart, self.Radius)
	
	self.Thread.OnClosed:Connect(function()
		self:FireReliableVFX("Accelerator/Vector Grasp", "StopWalk", self.LuaCharacter.RootPart)
	end)

	local VelocityObject = self.Combat:Velocity()
	VelocityObject.Settings.Duration = 2.25
	VelocityObject.Settings.RemoveTime = 2.25
	VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
	VelocityObject.Settings.Controllable = true
	VelocityObject.Settings.Z = 5
	VelocityObject:Fire()

	self.Thread.Job:Task(VelocityObject)

	local Clean = self.Combat.Hitbox:ClientSidedDestructionLoop(CFrame.new(0, 0, -2), Vector3.new(self.Radius, 8, self.Radius), 3)
	
	if not self.LuaPlayer.IsNPC and Clean then
		self.Thread.Job:Task(Clean)
	end
	
	StunHitbox:BeginCast()

	self.Animations.Windup:GetMarkerReachedSignal("hit"):Wait()
	
	StunHitbox:EndCast()
	self:FireReliableVFX("Accelerator/Vector Grasp", "StopWalk", self.LuaCharacter.RootPart)

	if (Clean ~= nil) then
		Clean()
	end
	
	VelocityObject:Destroy()
	
	self.Combat:TeleportForward(7.5, function(DistanceCovered : number, CF : CFrame, HitboxAdjust : number)
		local ExtraDistance = 5
		DistanceCovered += ExtraDistance
		
		Hitbox.Params.Offset = CFrame.new(0, HitboxAdjust / 2, -(DistanceCovered / 2))
		Hitbox.Params.Size = Vector3.new(8, HitboxAdjust + 8.5, DistanceCovered)
		Hitbox:Detect()

		if not self.Hit then
			self.Combat.Hitbox:Destruction(Hitbox.Params.Offset, Hitbox.Params.Size, 4)
			self.LuaCharacter.Model:PivotTo(CF)
		end
	end)
	
	local VelocityObject = self.Combat:Velocity()
	VelocityObject.Settings.Duration = 1
	VelocityObject.Settings.RemoveTime = 1
	VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
	VelocityObject.Settings.Controllable = true
	VelocityObject.Settings.Z = 20
	VelocityObject:Fire()

	self.Thread.Job:Task(VelocityObject)

	task.wait(0.75)

	if not self.Hit then
		self.Animations.Windup:Stop(0.3)
		self:Close()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.AnimationSettings = {Speed = 1.05}
	self.Radius = 16
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack