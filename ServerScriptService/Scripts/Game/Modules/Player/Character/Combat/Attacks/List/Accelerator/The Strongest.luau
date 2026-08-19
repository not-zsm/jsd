local RunService = game:GetService("RunService")
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
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(100)
	
	self.Thread.CancelJob:Task(self:CreateMoveSFX("Accelerator", "The Strongest"))

	self.Hit = false

	local Hitbox = self:CreateHitbox(true);
	Hitbox.Params.Offset = CFrame.new(0, 0, -20)
	Hitbox.Params.Size = 13
	Hitbox.Params.MaxTargets = 1

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat
		
		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = 2,
			DontHitDeadPeople = true,
			BreakBlock = true
		})

		if Validated then
			self.Hit = true
			
			self.Combat:StackState("HitboxImmunity", true)
			VictimCombat:StackState("HitboxImmunity", true)
			
			self.LuaCharacter:Anchor(true)
			VictimLuaCharacter:Anchor(true)

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -25) * CFrame.Angles(0, math.pi, 0))
			local VictimAnimation : AnimationTrack = VictimLuaCharacter.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Accelerator["The Strongest"].Victim)
			self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

			self.LuaPlayer.Replication.Attributes:SetAttribute("AcceleratorTheStrongest", true)
			VictimLuaPlayer.Replication.Attributes:SetAttribute("AcceleratorTheStrongest", true)

			self:FireReliableVFXToSelf("Accelerator/The Strongest", "Start", self.LuaCharacter.RootPart)
			VictimLuaPlayer.Replication:FireReliableVFXToSelf("Accelerator/The Strongest", "Start", self.LuaCharacter.RootPart)
			
			local Ultimate, Matched = self.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

			if Matched then
				Ultimate:SetBarPausing(true)

				self.Thread.OnClosed:Connect(function()
					Ultimate:SetBarPausing(false)
				end)
			end
			
			self.Combat:HideUI(true)
			VictimCombat:HideUI(true)
			
			local RemovedGrab = false

			self.Thread.OnClosed:Connect(function()
				self.LuaCharacter:Anchor(false)
				VictimLuaCharacter:Anchor(false)
				
				self.LuaPlayer.Replication.Attributes:SetAttribute("AcceleratorTheStrongest", nil)
				VictimLuaPlayer.Replication.Attributes:SetAttribute("AcceleratorTheStrongest", nil)
				
				self.Animations.Hit:Stop()
				VictimAnimation:Stop()

				if not RemovedGrab then
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end
				
				self.Combat:HideUI(false)
				VictimCombat:HideUI(false)

				self.Combat:StackState("HitboxImmunity", false)
				VictimCombat:StackState("HitboxImmunity", false)
			end)
			
			local EndOffset = -58.657
			local VictimEndOffset = 62.283
			
			local TornadoHitbox = self:CreateHitbox(false);
			local TornadoCF = self.LuaCharacter.RootPart.CFrame

			TornadoHitbox.Adornee = TornadoCF
			TornadoHitbox.Params.Offset = CFrame.new(0, 30, -60.7)
			TornadoHitbox.Params.Size = Vector3.new(72.5, 80, 72.5)
			TornadoHitbox.Params.DestroyOnEndCast = true
			TornadoHitbox.Params.MaxTargets = -1

			TornadoHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
				local Validated = self:Afflict(NewVictimLuaPlayer, {
					DontCheckBlock = true,
					Damage = 20,
					Velocity = NewVictimLuaPlayer == VictimLuaPlayer and {(NewVictimLuaPlayer.Character.RootPart.Position - TornadoHitbox.Adornee.Position).Unit * 125 + Vector3.yAxis * 200, 0.1} or nil
				})

				if Validated and NewVictimLuaPlayer ~= VictimLuaPlayer then	
					self.Combat:PushSkidVictim(NewVictimLuaPlayer, {
						TimeTilGroundDetection = 0.5,
						StartVelocityXZ = (NewVictimLuaPlayer.Character.RootPart.Position - TornadoHitbox.Adornee.Position).Unit * 125,
						StartVelocityY = Vector3.yAxis * 200,
						StartDuration = 0.8,
						LandedRollVelocityZ = 160,
						LandedRollDuration = 0.7825
					})
				end
			end)
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("attacker_root_vfx"):Connect(function(Type : string)
				self:FireReliableVFX("Accelerator/The Strongest", "AttackerRoot", self.LuaCharacter.RootPart, tonumber(Type))
				
				if Type == "5" then
					self:FireReliableVFX("Accelerator/The Strongest", "ImpactFrame", "Punch", self.LuaPlayer.Player, VictimLuaPlayer.Player)
					
				elseif Type == "10" then
					self:FireReliableVFX("Accelerator/The Strongest", "ImpactFrame", "Bomb", self.LuaPlayer.Player, VictimLuaPlayer.Player)
				end
				
				if Type == "12" then
					TornadoHitbox:BeginCast()
				end
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("background"):Connect(function()
				self:FireReliableVFXToSelf("Accelerator/The Strongest", "Background", self.LuaCharacter.RootPart)
				VictimLuaPlayer.Replication:FireReliableVFXToSelf("Accelerator/The Strongest", "Background", self.LuaCharacter.RootPart)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("attacker_torso_vfx"):Connect(function(Type : string)
				self:FireReliableVFX("Accelerator/The Strongest", "AttackerTorso", self.LuaCharacter.Torso, tonumber(Type))
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("attacker_rightarm_vfx"):Connect(function(Type : string)
				self:FireReliableVFX("Accelerator/The Strongest", "AttackerRightArm", self.LuaCharacter.RightArm, tonumber(Type))
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("victim_torso_vfx"):Connect(function(Type : string)
				self:FireReliableVFX("Accelerator/The Strongest", "VictimTorso", VictimLuaCharacter.Torso, tonumber(Type))
			end))
			
			self.Thread.Job:Task(VictimAnimation:GetMarkerReachedSignal("end"):Connect(function()
				-- Slam
				local AoeSlamHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, 
					CFrame.new(-1.737, 0, -62.283),
					Vector3.new(75, 40, 75)
				)
				
				AoeSlamHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
					self:Afflict(NewVictimLuaPlayer, {
						Damage = 15,
						BreakBlock = true,
						Ragdoll = 2.5,
						Velocity = {self.Combat:CalculateUnitDifference(NewVictimLuaPlayer) * 30 + Vector3.yAxis * 65, 0.1}
					})
				end)
				
				AoeSlamHitbox:Detect()
				
				self.Thread.OnClosed:Connect(function()
					AoeSlamHitbox:Destroy()
				end)
				
				VictimLuaPlayer.Replication.Attributes:SetAttribute("AcceleratorTheStrongest", nil)
				
				if not VictimLuaPlayer.IsNPC and VictimLuaPlayer:PlayerExists() then
					VictimLuaPlayer.Remotes.ToggleHeadMovement:FireClient(VictimLuaPlayer.Player, false)
				end
				
				task.wait()
				
				RemovedGrab = true
				
				GrabObject.Destroy(0)
				VictimAnimation:Stop(0)

				local Raycast = workspace:Raycast(VictimLuaCharacter.RootPart.Position, VictimLuaCharacter.RootPart.CFrame.LookVector * -VictimEndOffset, Utility.VisualParams)

				if (Raycast ~= nil) then
					VictimLuaCharacter.RootPart.CFrame = VictimLuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -Raycast.Distance)
				else
					VictimLuaCharacter.RootPart.CFrame = VictimLuaCharacter.RootPart.CFrame * CFrame.new(0, 0, VictimEndOffset)
				end
			
				VictimLuaCharacter:Anchor(false)
				
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Ragdoll = 3,
					FinisherKill = true
				})
				
				VictimCombat:Unstun()
				VictimCombat:StackState("HitboxImmunity", false)

				task.wait(4 / 60)

				if not VictimLuaPlayer.IsNPC and VictimLuaPlayer:PlayerExists() then
					VictimLuaPlayer.Remotes.ToggleHeadMovement:FireClient(VictimLuaPlayer.Player, true)
				end
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("end"):Connect(function()
				TornadoHitbox:EndCast()
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("end"):Connect(function()
				self.LuaPlayer.Replication.Attributes:SetAttribute("AcceleratorTheStrongest", nil)
				
				if not self.LuaPlayer.IsNPC then
					self.LuaPlayer.Remotes.ToggleHeadMovement:FireClient(self.LuaPlayer.Player, false)
				end
				
				task.wait()

				self.Animations.Hit:Stop(0)
				
				local Raycast = workspace:Raycast(self.LuaCharacter.RootPart.Position, self.LuaCharacter.RootPart.CFrame.LookVector * -EndOffset, Utility.VisualParams)

				if (Raycast ~= nil) then
					self.LuaCharacter.RootPart.CFrame = self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -Raycast.Distance)
				else
					self.LuaCharacter.RootPart.CFrame = self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, EndOffset)
				end

				task.wait(10 / 60)

				self.LuaCharacter:Anchor(false)
				
				if not self.LuaPlayer.IsNPC then
					self.LuaPlayer.Remotes.ToggleHeadMovement:FireClient(self.LuaPlayer.Player, true)
				end
				
				self:Close()
			end))
			
			self.Animations.Windup:Stop(0)
			self.Animations.Hit:Play(0)
			VictimAnimation:Play(0)

			self:FireReliableVFX("Accelerator/The Strongest", "HitSFX", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(100)
		
		self.Combat:TimesSpeed(100)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Animations.Windup:GetMarkerReachedSignal("hit"):Wait()
	
	self:FireReliableVFX("Accelerator/The Strongest", "AttackerRoot", self.LuaCharacter.RootPart, 1)
	Hitbox:Detect()
	
	task.wait(1)
	
	if not self.Hit then
		self.Animations.Windup:Stop(0.3)
		self:Close()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.AnimationSettings = {Speed = 0.65}
	self.TornadoAligns = {}
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack