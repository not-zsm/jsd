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
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self.Hit = false
	self.Blocked = false
	
	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -12.5)
	Hitbox.Params.Size = Vector3.new(7, 8.5, 25)
	Hitbox.Params.MaxTargets = 1
	Hitbox.Params.DestroyOnEndCast = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat
		
		local Finisher = self:IsFinisherEnabled() and VictimLuaCharacter.Humanoid.Health <= 12.5
		
		local Validated, Type = self:Afflict(VictimLuaPlayer, {
			YDifferenceValue = -2
		})
		
		self.Blocked = (Type == "Blocked")

		if Validated then
			self.Hit = true
			
			self.Animations.Windup:Stop()
			
			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart)
			local Ended = false
			
			if Finisher then
				self.Combat:StackState("HitboxImmunity", true)
				VictimCombat:StackState("HitboxImmunity", true)
				
				VictimLuaCharacter:StopRespawnTimer()
			
				self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
				
				local VictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Accelerator["Accelerated Punishment"].FinisherVictim)

				self.Thread.OnClosed:Connect(function()
					if not Ended then
						GrabObject.Destroy(0)
						VictimCombat:Unstun()
					end
					
					if VictimAnimation then
						VictimAnimation:Stop()
					end
					
					VictimLuaCharacter:RestartRespawnTimer()
					
					self.Combat:StackState("HitboxImmunity", false)
					VictimCombat:StackState("HitboxImmunity", false)
				end)
				
				self.Thread.CancelJob:Task(self:CreateMoveSFX("Accelerator", "Accelerated Punishment Finisher"))

				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("hit"):Connect(function(Count : string)
					self:FireReliableVFX("Accelerator/Accelerated Punishment Finisher", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.Model, Count)
				end))
					
				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("kick"):Connect(function(Type : string)
					self:FireReliableVFX("Accelerator/Accelerated Punishment Finisher", "Kick", self.LuaCharacter.RootPart, VictimLuaCharacter.Model, Type)
					
					if Type == "impact" then
						self.LuaCharacter:Anchor(true)
						VictimLuaCharacter:Anchor(true)
						
						self.Combat:HideUI(true)
						VictimCombat:HideUI(true)
						
						self.LuaPlayer.Replication.Attributes:SetAttribute("AcceleratedPunishmentFinisher", true)
						VictimLuaPlayer.Replication.Attributes:SetAttribute("AcceleratedPunishmentFinisher", true)

						self:FireReliableVFXToSelf("Accelerator/Accelerated Punishment Finisher", "Start", self.LuaCharacter.RootPart)
						VictimLuaPlayer.Replication:FireReliableVFXToSelf("Accelerator/Accelerated Punishment Finisher", "Start", self.LuaCharacter.RootPart)

						self.Thread.OnClosed:Connect(function()
							self.Combat:HideUI(false)
							VictimCombat:HideUI(false)
							
							self.LuaCharacter:Anchor(false)
							VictimLuaCharacter:Anchor(false)
							
							self.LuaPlayer.Replication.Attributes:SetAttribute("AcceleratedPunishmentFinisher", nil)
							VictimLuaPlayer.Replication.Attributes:SetAttribute("AcceleratedPunishmentFinisher", nil)
						end)
					end
				end))
				
				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("slam"):Connect(function()
					self:FireReliableVFX("Accelerator/Accelerated Punishment Finisher", "Slam", self.LuaCharacter.RootPart)
				end))
				
				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("land"):Connect(function()
					self:FireReliableVFX("Accelerator/Accelerated Punishment Finisher", "Land", self.LuaCharacter.RootPart)
				end))
				
				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("vanish"):Connect(function()
					self:FireReliableVFX("Accelerator/Accelerated Punishment Finisher", "Vanish", self.LuaCharacter.Torso)
				end))
				
				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("punch"):Connect(function()
					self:FireReliableVFX("Accelerator/Accelerated Punishment Finisher", "Punch", self.LuaCharacter.RootPart)
				end))
				
				local EndOffset = -43.729
				local VictimEndOffset = -47.313 - 10 -- extra so we dont collide
				
				local function Fling()
					Ended = true

					VictimLuaCharacter:Anchor(false)
					GrabObject.Destroy(0.5)

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						FinisherKill = true,
						Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 125 + Vector3.yAxis * 35, 0.1},
					})

					VictimCombat:Unstun()
					self:Close()
				end
				
				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("end"):Connect(function()
					self:FireReliableVFX("Accelerator/Accelerated Punishment Finisher", "End", self.LuaCharacter.RootPart)

					if (not VictimLuaPlayer.IsNPC and VictimLuaPlayer:PlayerExists()) then
						VictimLuaPlayer.Remotes.ToggleHeadMovement:FireClient(VictimLuaPlayer.Player, false)
					end

					if not self.LuaPlayer.IsNPC then
						self.LuaPlayer.Remotes.ToggleHeadMovement:FireClient(self.LuaPlayer.Player, false)
					end;
					
					self.Animations.Finisher:Stop(0)
					
					if VictimAnimation then
						VictimAnimation:Stop(0)
					end
					
					local Raycast = workspace:Raycast(self.LuaCharacter.RootPart.Position, self.LuaCharacter.RootPart.CFrame.LookVector * -EndOffset, Utility.VisualParams)
					local VictimRaycast = workspace:Raycast(VictimLuaCharacter.RootPart.Position, VictimLuaCharacter.RootPart.CFrame.LookVector * -VictimEndOffset, Utility.VisualParams)

					if (Raycast == nil) then
						self.LuaCharacter.RootPart.CFrame *= CFrame.new(0, 0, EndOffset)
					else
						self.LuaCharacter.RootPart.CFrame *= CFrame.new(0, 0, -Raycast.Distance)
					end
					
					if (VictimRaycast == nil) then
						VictimLuaCharacter.RootPart.CFrame *= CFrame.new(0, 0, VictimEndOffset)
					else
						VictimLuaCharacter.RootPart.CFrame *= CFrame.new(0, 0, -VictimRaycast.Distance)
					end
					
					self.Animations.FinisherEnd:Play(0)
					
					task.wait(3 / 60)
					
					if not VictimLuaPlayer.IsNPC and VictimLuaPlayer:PlayerExists() then
						VictimLuaPlayer.Remotes.ToggleHeadMovement:FireClient(VictimLuaPlayer.Player, true)
					end

					if not self.LuaPlayer.IsNPC then
						self.LuaPlayer.Remotes.ToggleHeadMovement:FireClient(self.LuaPlayer.Player, true)
					end;
					
					Fling()
				end))
					
				self.Animations.Finisher:Play(0)
				
				if VictimAnimation then
					VictimAnimation:Play(0)
				end
			else
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = 2.5,
				})
				
				self.Animations.Hit:Play(0.1, 1, 1.4)
				VictimCombat.Animations.GrabVictims.AcceleratedPunishment:Play(0.1, 1, 1.4)

				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 1.5
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = 62.5
				VelocityObject:Fire()

				self.Thread.Job:Task(VelocityObject)

				self:FireReliableVFX("Accelerator/Accelerated Punishment", "Push", self.LuaCharacter.RootPart)

				self.Thread.OnClosed:Connect(function()
					if not Ended then
						GrabObject.Destroy(0)
						VictimCombat:Unstun()
						VictimCombat.Animations.GrabVictims.AcceleratedPunishment:Stop()
					end
				end)

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("throw"):Once(function()
					Ended = true

					self:FireReliableVFX("Accelerator/Accelerated Punishment", "Throw", self.LuaCharacter.RootPart)

					GrabObject.Destroy(0)
					VictimCombat.Animations.GrabVictims.AcceleratedPunishment:Stop(0)
					VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -5))

					VictimCombat:StackState("BackdashIFrames", true, 1)
					
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Ragdoll = 1.5,
						Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 85 + Vector3.yAxis * 50, 0.1},
						Damage = 4.5,
					})

					VictimCombat:Unstun()
					self:Close()
				end))
			end
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(18)
		
		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)
	
	self:FireReliableVFX("Accelerator/Accelerated Punishment", "Start", self.LuaCharacter.RootPart)
	
	self.Animations.Windup:GetMarkerReachedSignal("hit"):Wait()
	
	local VelocityObject = self.Combat:Velocity()
	VelocityObject.Settings.Duration = 0.6
	VelocityObject.Settings.RemoveTime = 0.6
	VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
	VelocityObject.Settings.Controllable = true
	VelocityObject.Settings.Z = 45
	VelocityObject:Fire()

	self.Thread.Job:Task(VelocityObject)

	self:FireReliableVFX("Accelerator/Accelerated Punishment", "Teleport", self.LuaCharacter.Torso)

	self.Combat:TeleportForward(25, function(DistanceCovered : number, CF : CFrame, HitboxAdjust : number)
		local ExtraDistance = 2.5
		DistanceCovered += ExtraDistance

		Hitbox.Params.Offset = CFrame.new(0, HitboxAdjust / 2, -(DistanceCovered / 2))
		Hitbox.Params.Size = Vector3.new(8, HitboxAdjust + 8.5, DistanceCovered)
		Hitbox:Detect()

		self.Combat.Hitbox:Destruction(Hitbox.Params.Offset, Hitbox.Params.Size, 4)
		self.LuaCharacter.Model:PivotTo(CF)
	end)
	
	if self.Blocked then
		self.Animations.Windup:AdjustSpeed(0.5)
	end
	
	task.wait(self.Blocked and 1 or 0.55)

	if not self.Hit then
		self.Animations.Windup:Stop(0.3)
		self:Close()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.AnimationSettings = {Speed = 1.3}
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack