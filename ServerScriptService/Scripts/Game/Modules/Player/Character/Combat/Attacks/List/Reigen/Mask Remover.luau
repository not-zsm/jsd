local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

--function Attack:ConditionToActivate()
--	return self:BasicConditions() and not self.Combat:GetState("Blocking")
--end

function Attack:ConditionToActivate()
	local Conditions = 
		not self.Combat:GetState(`Cannot{self.NameNoSpaces}`)
		and not self.Combat:GetState("Attacking") 
		and not self.Combat:GetState("WallComboed")
		and not self.Combat:GetState("Grabbed")
		and not self.Combat:GetState("Blocking")
		and not self.Combat:GetState("Backdashing") 
		and not self.OnCooldown

	return Conditions
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(30)

	local Is_Variant = self.Combat:GetState("Ragdolled") or self.ForceVariant;
	
	if Is_Variant then
		self.Combat.Ragdoll:Toggle(false)
	end
	
	task.defer(function()
		
	end)
	
	self.Hit = false
	
	self.Thread.CancelJob:Task(self:CreateMoveSFX("Reigen", "Mask Remover"))
	
	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.DestroyOnEndCast = false
	Hitbox.Params.MaxTargets = 1

	local Blocked = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true,
			YDifferenceValue = -2
		})

		if Validated then
			self.Hit = true

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart)
			local VictimAnimation : AnimationTrack = VictimLuaCharacter.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Reigen["Mask Remover"].Victim)

			local Ended = false
			
			local Magnitude = (VictimLuaCharacter.RootPart.Position - self.LuaCharacter.RootPart.Position).Magnitude
			self.LuaCharacter.RootPart.CFrame = self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -(Magnitude / 1.05))

			self.Thread.CancelJob:Task(self:CreateMoveSFX("Reigen", "Mask Remover", "Hit"))
			self:FireReliableVFX("Reigen/Mask Remover", "Grab", self.LuaCharacter.RootPart)
			
			self.Animations.Windup:Stop()
			self.Animations.Hit:Play()
			VictimAnimation:Play()

			self.Thread.OnClosed:Connect(function()
				if not Ended then
					self.Animations.Hit:Stop()
					VictimAnimation:Stop()
				end

				GrabObject.Destroy(0)
				VictimCombat:Unstun()
			end)

			local VelocityObject = self.Combat:Velocity()
			VelocityObject.Settings.Duration = 1.535
			VelocityObject.Settings.RemoveTime = 1.7
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 7
			VelocityObject:Fire()
			
			self.Thread.Job:Task(VelocityObject)
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("forward"):Once(function()
				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 1.75
				VelocityObject.Settings.RemoveTime = 2
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = 10
				VelocityObject:Fire()

				self.Thread.Job:Task(VelocityObject)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("throw"):Once(function()
				Ended = true
				
				local ThrowCF : CFrame = self.Combat:GetSimulatedRoot().CFrame
				self:FireReliableVFX("Reigen/Mask Remover", "Throw", ThrowCF)

				local Finisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= 30)
				
				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 0.85
				VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = 35
				VelocityObject:Fire()
				
				local Endlag = 1
				GrabObject.Destroy(Endlag)
				VictimCombat:Unstun()

				VictimAnimation:Stop(0)
				VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 1, -6) * CFrame.Angles(0, math.pi, 0))

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Ragdoll = 3.5,
					Velocity = {ThrowCF.LookVector * (Finisher and 400 or 250) + Vector3.yAxis * (Finisher and 85 or 75), 0.1},
					Damage = 30
				})
				
				self.Combat:VictimImpactGround(VictimLuaPlayer)
				
				if VictimLuaPlayer:PlayerExists() then
					local Offset = CFrame.identity
					local Size = 10
					
					local ThrowJob = Job.new()

					if not VictimLuaPlayer.IsNPC then
						ThrowJob:Task(VictimCombat.Hitbox:ClientSidedDestructionLoop(Offset, Size))
					end
 
					local Root : BasePart = VictimCombat:GetSimulatedRoot()
					
					ThrowJob:Task(RunService.PostSimulation:Connect(function()
						if (Root == nil) then 
							return ThrowJob:Destroy() 
						end

						VictimCombat.Hitbox:SphereDestruction(Root.Position, Size, 5, "None")
					end))
					
					task.delay(2, ThrowJob.Destroy, ThrowJob)
					
					local AOEHitbox = VictimCombat.Hitbox:AoeHitboxForGrabs(self.LuaPlayer, Offset, Vector3.one * Size)

					if AOEHitbox then
						AOEHitbox.Params.DestroyOnEndCast = false

						AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
							self:Afflict(NewVictimLuaPlayer, {
								TriggerActiveCounterOverOrEqualLevel = -1,
								DontBypassIFrames = {"Grab"},
								DontCheckBlock = true,
								Damage = 10,
								Ragdoll = 1.5,
								Velocity = { (NewVictimLuaPlayer.Character.RootPart.Position - VictimLuaPlayer.Character.RootPart.Position).Unit * 75 + Vector3.yAxis * 45, 0.1}
							})
						end)

						AOEHitbox:BeginCast()

						ThrowJob:Task(function()
							AOEHitbox:EndCast()
							AOEHitbox:Destroy()
						end)
					end
					
					ThrowJob:Task(VictimCombat:GetStateChanged("Evasived"):Connect(function()
						ThrowJob:Destroy()
					end))
				end

				task.wait(Endlag)
				
				self:Close()
			end))
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(12.5)
		
		self.Combat:TimesSpeed(30)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Animations.Windup:GetMarkerReachedSignal("walk"):Wait()
	
	local VelocityObject = self.Combat:Velocity()
	VelocityObject.Settings.Duration = 1
	VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
	VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
	VelocityObject.Settings.Controllable = true
	VelocityObject.Settings.Z = 6
	VelocityObject:Fire()

	self.Thread.Job:Task(VelocityObject)

	self.Animations.Windup:GetMarkerReachedSignal("hit"):Wait()

	self.Combat:TeleportForward(30, function(DistanceCovered : number, CF : CFrame, HitboxAdjust : number)
		local ExtraDistance = 4
		DistanceCovered += ExtraDistance

		Hitbox.Params.Offset = CFrame.new(0, HitboxAdjust / 2, -(DistanceCovered / 2))
		Hitbox.Params.Size = Vector3.new(8, HitboxAdjust + 8.5, DistanceCovered)
		Hitbox:Detect()

		if not self.Hit then
			self.Combat.Hitbox:Destruction(Hitbox.Params.Offset, Hitbox.Params.Size, 4)
			self.LuaCharacter.Model:PivotTo(CF)
		end
	end)

	task.wait(0.05)
	
	if not self.Hit then
		if Is_Variant then
			self.Animations.Windup:AdjustSpeed(1.25)
		end
		
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 2
		VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration + 0.5
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 11
		VelocityObject:Fire()

		self.Thread.Job:Task(VelocityObject)
	end
	
	task.wait(0.8)
	
	if not self.Hit then
		self:Close()
	end
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