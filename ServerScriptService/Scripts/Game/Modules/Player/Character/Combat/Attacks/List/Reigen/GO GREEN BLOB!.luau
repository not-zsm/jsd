local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	local Conditions = self:BasicConditions() and not self.Combat:GetState("Blocking")
	local HasCloseTarget = false

	if Conditions then
		self.DetectHitbox = self:CreateHitbox(true, true);
		self.DetectHitbox.Params.Size = self.Range
		self.DetectHitbox.Params.MaxTargets = 1
		self.DetectHitbox:Detect()

		HasCloseTarget = (self.DetectHitbox.HitCount > 0)
		
		if not HasCloseTarget and not self.WarnedAboutNoTarget then
			self.WarnedAboutNoTarget = true

			self.Combat:ChangeAttackDisplay(self.Name, self.DisplayName, {
				FlashColor = Color3.fromRGB(0, 255, 128),
				Tip = "[NEEDS TARGET]"
			})

			task.delay(0.5, function()
				self.Combat:ChangeAttackDisplay(self.Name, self.DisplayName, {
					Tip = ""
				})

				self.WarnedAboutNoTarget = false
			end)
		end
	end

	return Conditions and HasCloseTarget

	--return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)

	self.Thread.CancelJob:Task(self:CreateMoveSFX("Reigen", "GO GREEN BLOB!"))
	self:FireReliableVFX("Reigen/GO GREEN BLOB!", "Start", self.LuaCharacter.Model)

	local WasntThrown = false

	self.Thread.OnClosed:Once(function()
		if self.DetectHitbox then
			self.DetectHitbox:Destroy()
		end
		
		if not WasntThrown then
			self:AddCooldown(20)
		end

		self.Combat:TimesSpeed(50)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("slide"):Once(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 1.45
		VelocityObject.Settings.RemoveTime = 0.75
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true 
		VelocityObject.Settings.Z = 9
		VelocityObject:Fire()
	end)) 

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("throw"):Once(function() 
		task.spawn(function()
			local Target = nil

			local DetectionHitbox = self:CreateHitbox(true);
			DetectionHitbox.Params.Offset = CFrame.new(0, 0, -((self.Range + 5) / 5)) -- more likely to hit people in front
			DetectionHitbox.Params.Size = (self.Range + 5)
			DetectionHitbox.Params.MaxTargets = 1

			DetectionHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				if not VictimLuaPlayer.Character.Combat:GetState("HitboxImmunity") and self:Afflict(VictimLuaPlayer, {DontCheckBlock = true, DontBypassIFrames = {}, CannotBeAdapted = true}) then
					Target = VictimLuaPlayer
				end
			end)

			DetectionHitbox:Detect()
			WasntThrown = (Target == nil)

			if WasntThrown then 
				return
			end

			local TargetLuaCharacter = Target.Character
			local TargetCombat = TargetLuaCharacter.Combat

			local VictimRoot : BasePart = TargetCombat:GetSimulatedRoot()
			local Root : BasePart = self.Combat:GetSimulatedRoot()

			local StartPosition = Root.Position
			local Speed = 7.25
			
			local Duration = (VictimRoot.Position - StartPosition).Magnitude / (Speed * 10)
			
			local Ping = (Target:GetPing() + 0.95)
			--local ClampedPing = math.clamp(Ping, 1, 3)
			
			local TimeUntilDodgeAvailable = (Duration * Ping) / 1.275

			self:FireReliableVFX("Reigen/GO GREEN BLOB!", "Go", StartPosition, Duration, TargetLuaCharacter.RootPart)
			
			local Dodged = false
			local PossessJob = Job.new()

			task.delay(TimeUntilDodgeAvailable, function()
				if TargetCombat:GetState("Backdashing") then
					Dodged = true
				else
					local StateChanged : RBXScriptConnection; StateChanged = PossessJob:Task(TargetCombat.OnStateUpdated:Connect(function(State, Value)
						if (State == "Backdashing") and Value then
							StateChanged:Disconnect()
							Dodged = true
						end
					end))
				end
				
				self:FireReliableVFX("Reigen/GO GREEN BLOB!", "DodgeFrames", TargetLuaCharacter.Model,
					TimeUntilDodgeAvailable / Duration
				)
			end)
			
			task.wait(Duration)
			
			local function Possess()
				if not TargetCombat:GetState("HitboxImmunity") and self:Afflict(Target, {DontCheckBlock = true}) then
					task.delay(1.35, function()
						self:FireReliableVFX("Reigen/GO GREEN BLOB!", "Flee", TargetLuaCharacter.Head)
					end)

					local PossessAnimation : AnimationTrack = TargetLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Reigen["GO GREEN BLOB!"].Possess)
					
					if PossessAnimation then
						PossessAnimation.Priority = Enum.AnimationPriority.Movement -- smooths out gameplay
						
						TargetCombat:TrueStun()

						PossessJob:Task(TargetLuaCharacter:StopAutoRotate())
						TargetCombat.Ragdoll:ForceToggleOff()

						PossessJob:Task(function()
							PossessAnimation:Stop(0)
							task.defer(TargetCombat.Unstun, TargetCombat)
						end)

						PossessJob:Task(PossessAnimation.Stopped:Once(function()
							PossessJob:Destroy()
						end))

						PossessJob:Task(TargetCombat.OnStateUpdated:Connect(function(State, Value)
							if (State == "Ragdolled" or State == "Grabbed") and Value then
								PossessJob:Destroy()
							end
						end))

						PossessJob:Task(PossessAnimation:GetMarkerReachedSignal("smack"):Connect(function()
							local Finisher = self:IsFinisherEnabled() and TargetLuaCharacter.Humanoid.Health <= 10 

							if Finisher then
								Target.Replication:FireReliableVFX("Reigen/GO GREEN BLOB!", "Finisher", TargetLuaCharacter.RootPart)

								self:Afflict(Target, {
									FinisherKill = true,
									Velocity = {-VictimRoot.CFrame.LookVector * 1000 + Vector3.yAxis * 50, 0.1}
								})
							else
								self:Afflict(Target, {
									Damage = 7.5,
									Ragdoll = 1.5,
									Velocity = {-VictimRoot.CFrame.LookVector * 20, 0.1}
								})
							end
						end))

						local VelocityObject = TargetCombat:Velocity()
						VelocityObject.Settings.Duration = 0.745
						VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
						VelocityObject.Settings.Controllable = true 
						VelocityObject.Settings.Z = -8
						VelocityObject:Fire()

						PossessJob:Task(VelocityObject)
						PossessAnimation:Play()

						TargetCombat:CreateMoveSFX("Reigen", "GO GREEN BLOB!", "PossessSFX")
						Target.Replication:FireReliableVFX("Reigen/GO GREEN BLOB!", "Possessed", TargetLuaCharacter.Model)
					end
				end
			end
			
			if not Dodged then
				Possess()
			else
				self:FireReliableVFX("Reigen/GO GREEN BLOB!", "Flee", TargetLuaCharacter.Head)
			end
		end)

		task.wait(0.6)
		
		self.Animations.Windup:Stop(0.35)
		self:Close()
	end))
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.Range = 80
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack