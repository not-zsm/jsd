local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
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

function Attack:Finisher(VictimLuaPlayer)
	local VictimLuaCharacter = VictimLuaPlayer.Character
	local VictimCombat = VictimLuaCharacter.Combat

	local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0))
	local VictimKilled = false
	
	VictimLuaCharacter:StopRespawnTimer()
	
	self.Thread.Job:Task(function()
		VictimLuaCharacter:RestartRespawnTimer()
	end)
	
	self.Thread.Job:Task(self.Animations.Finisher.User:GetMarkerReachedSignal("lift"):Connect(function()
		self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

		self.Combat:StackState("HitboxImmunity", true)
		VictimCombat:StackState("HitboxImmunity", true)
		
		self.Combat:HideUI(true)
		VictimCombat:HideUI(true)

		self.LuaCharacter:Anchor(true)
		VictimLuaCharacter:Anchor(true)

		self.Thread.OnClosed:Connect(function()
			self.LuaCharacter:Anchor(false)
			
			self.LuaCharacter.RootPart.AssemblyLinearVelocity = Vector3.zero
			self.LuaCharacter.RootPart.AssemblyAngularVelocity = Vector3.zero
			
			self.Combat:HideUI(false)
			VictimCombat:HideUI(false)
			
			if VictimKilled == false then
				VictimLuaCharacter:Anchor(false)
			end
			
			VictimCombat:StackState("HitboxImmunity", false)
			self.Combat:StackState("HitboxImmunity", false)
		end)
	end))
	
	local VictimAnimation = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Invincible["Holding Back"].Finisher.Victim)
	
	self.Thread.Job:Task(self.Animations.Finisher.User:GetMarkerReachedSignal("10"):Connect(function()
		VictimKilled = true
		
		VictimLuaCharacter:Anchor(false)
		VictimAnimation:Stop()
		GrabObject.Destroy(0)

		self:Afflict(VictimLuaPlayer, {
			ExcludeAttempts = true,
			FinisherKill = true,
		})
	end))
	
	self.Thread.OnClosed:Connect(function()
		if not VictimKilled then
			GrabObject.Destroy(0)
			
			self.Animations.Finisher.User:Stop()
			VictimAnimation:Stop()
		end
	end)

	self.Animations.Windup:Stop()
	self.Animations.Finisher.User:Play()
	VictimAnimation:Play()
	
	self:FireReliableVFX("Invincible/Holding Back Finisher", "StartBeatdown", self.LuaCharacter.Model, VictimLuaCharacter.Model)
	
	self.Thread.Job:Task(self.Animations.Finisher.User.Stopped:Connect(function()
		self:Close()
	end))
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(100)

	self.FinisherHit = false
	self.Hit = false

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -6)
	Hitbox.Params.Size = Vector3.new(8, 8.5, 12)
  	Hitbox.Params.MaxTargets = 1
	Hitbox.Params.DestroyOnEndCast = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {})

		if Validated then
			self.Hit = true

			Hitbox:EndCast()
			Hitbox:Destroy()
			
			local FinishersEnabled = self:IsFinisherEnabled();
			local Finisher = FinishersEnabled and (VictimLuaCharacter.Humanoid.Health <= 30)
			
			if Finisher then
				self:Finisher(VictimLuaPlayer)
			else
				local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart)
				local Ended = false
				
				self.Combat:StackState("HitboxImmunity", true)
				VictimCombat:StackState("HitboxImmunity", true)
				VictimCombat:StackState("CannotDash", true)

				self:FireReliableVFX("Invincible/Holding Back", "Grabbed", self.LuaCharacter.Torso)

				self.Thread.OnClosed:Connect(function()
					if not Ended then
						GrabObject.Destroy(0)
						VictimCombat:Unstun()
						
						VictimCombat.Animations.GrabVictims.InvincibleHoldingBack:Stop()
					end
					
					VictimCombat:StackState("CannotDash", false)
					
					self.Combat:StackState("HitboxImmunity", false)
					VictimCombat:StackState("HitboxImmunity", false)
				end)

				local AlignPosition = Instance.new("AlignPosition")
				AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
				AlignPosition.Attachment0 = self.LuaCharacter.RootAttachment
				AlignPosition.MaxForce = 200000
				AlignPosition.Responsiveness = 200
				AlignPosition.RigidityEnabled = true

				local VictimAlignPosition = Instance.new("AlignPosition")
				VictimAlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
				VictimAlignPosition.Attachment0 = VictimLuaCharacter.RootAttachment
				VictimAlignPosition.MaxForce = 200000
				VictimAlignPosition.Responsiveness = 200
				VictimAlignPosition.RigidityEnabled = true

				self.Thread.OnClosed:Connect(function()
					if AlignPosition then
						AlignPosition:Destroy()
					end

					if VictimAlignPosition then
						VictimAlignPosition:Destroy()
					end
				end)

				local StartCF : CFrame = self.LuaCharacter.RootPart.CFrame

				local DamageTable = {
					["1"] = 5,
					["2"] = 10,
					["3"] = 15,
				}

				self.Thread.Job:Task(self.Animations.Grab:GetMarkerReachedSignal("hit"):Connect(function(Parameter : string)
					self:FireReliableVFX("Invincible/Holding Back", "Hit", self.LuaCharacter.RootPart, Parameter)

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = {Amount = DamageTable[Parameter], DontKill = FinishersEnabled},
					})

					if Parameter == "2" then
						GrabObject.Destroy(0)
						VictimCombat:Unstun()
		
						VictimCombat.Animations.GrabVictims.InvincibleHoldingBack:Stop(0)

						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							Ragdoll = 7,
							Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 120 + Vector3.yAxis * 230, 0.1},
						})

					elseif Parameter == "3" then
						Ended = true

						VictimAlignPosition:Destroy()
	
						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							Ragdoll = 2.5,
							Velocity = {Vector3.yAxis * -1000, 0.03},
						})
						
						self.Combat:VictimImpactGround(VictimLuaPlayer)
						
						task.wait(0.75)

						self:Close()
					end
				end))

				self.Thread.Job:Task(self.Animations.Grab:GetMarkerReachedSignal("teleportup"):Once(function()
					self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
					self:FireReliableVFX("Invincible/Holding Back", "TeleportSFX", self.LuaCharacter.RootPart)

					local UpCFrame = VictimLuaCharacter.RootPart.CFrame * CFrame.new(0, 0, 3)
					local UpPosition = UpCFrame.Position

					AlignPosition.Position = UpPosition
					VictimAlignPosition.Position = UpPosition

					VictimAlignPosition.Parent = VictimLuaCharacter.RootPart
					AlignPosition.Parent = self.LuaCharacter.RootPart

					self.LuaCharacter.Model:PivotTo(UpCFrame)
				end))

				self.Thread.Job:Task(self.Animations.Grab:GetMarkerReachedSignal("teleportback"):Once(function()
					self.Combat.Hitbox:SphereDestruction(StartCF.Position, 4, 4)
					self.LuaCharacter.Model:PivotTo(StartCF)
				end))

				self.Thread.Job:Task(self.Animations.Grab:GetMarkerReachedSignal("attacker_torso"):Connect(function()
					self:FireReliableVFX("Invincible/Holding Back", "Teleport", self.LuaCharacter.Torso)
				end))

				self.Animations.Windup:Stop()
				self.Animations.Grab:Play()

				VictimCombat.Animations.GrabVictims.InvincibleHoldingBack:Play() -- fadetime, weight, speed
			end
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(15)
		self.Combat:TimesSpeed(100)
		self.Combat:StackState("Attacking", false)
	end)

	self:FireReliableVFX("Invincible/Holding Back", "Windup", self.LuaCharacter.RootPart)
	self.Animations.Windup:GetMarkerReachedSignal("hitstart"):Wait()

	--self.Thread.Job:Task(
	--	self.Combat.Hitbox:OffsetHitboxOnVelocity(Hitbox, 13.5)
	--)

	Hitbox:BeginCast()

	local VelocityObject = self.Combat:Velocity()
	VelocityObject.Settings.Duration = 1.25
	VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 100000
	VelocityObject.Settings.Controllable = true
	VelocityObject.Settings.Z = 135
	VelocityObject:Fire()

	self.Thread.Job:Task(VelocityObject)

	self.Animations.Windup:GetMarkerReachedSignal("hitend"):Once(function()
		VelocityObject:Destroy()

		Hitbox:EndCast()
		Hitbox:Destroy()
	end)

	task.wait(1.5)

	self.Animations.Windup:Stop(0.5)
	
	task.wait(0.6)
	
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