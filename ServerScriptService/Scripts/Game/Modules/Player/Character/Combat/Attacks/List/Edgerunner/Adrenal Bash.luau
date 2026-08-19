local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(5)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(13)
		
		self.Combat:TimesSpeed(5)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Hit = false
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("lunge"):Connect(function()
		local Root : BasePart = self.Combat:GetSimulatedRoot()

		local Hitbox = self:CreateHitbox()
		Hitbox.Params.Offset = CFrame.new(0, 0.5, -2.5)
		Hitbox.Params.Size = vector.create(6, 6.75, 8.5)
		
		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat
			
			local Dead = VictimLuaCharacter.Humanoid.Health <= 7.5
			local Was_Ragdolled = VictimCombat:GetState("Ragdolled")
			
			self.Hit = self:Afflict(VictimLuaPlayer, {
				YDifferenceValue = -2,
				Damage = 7.5,
				Ragdoll = Dead and 2 or nil,
				Velocity = Dead and {Root.CFrame.LookVector * 50 + Vector3.yAxis * 25, 0.1} or nil,
				DontRestartRespawnTimer = true
			})
			
			if self.Hit then
				self:FireReliableVFX(self.EffectPath, "GROW A HIT", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
				
				if not Dead then

					if Was_Ragdolled then
						local TimeUntilCheckStun = 0.5
						VictimCombat:StackState("EvasiveState", true)

						task.delay(TimeUntilCheckStun, function()
							local Thread = task.delay((1.5 - TimeUntilCheckStun) + math.clamp(self.LuaPlayer:GetPing(), 0, 1), function()
								VictimCombat:StackState("EvasiveState", false)
							end)

							local Connection : RBXScriptConnection; Connection = VictimCombat:GetStateChanged("Stunned"):Connect(function(Value : boolean)
								if Value then
									Connection:Disconnect()
									Utility.CloseThreadSafe(Thread)
									VictimCombat:StackState("EvasiveState", false)
								end
							end)
						end)
					end

					self.Combat:TSBPushVictim(VictimLuaPlayer, {
						VerticalLeak = 0.9,
						LandedRollVelocityZ = Was_Ragdolled and 150 or 200,
						LandedRollDuration = Was_Ragdolled and 0.865 or 0.9,
						DurationMultiplier = Was_Ragdolled and 1.5 or 1
					})
				end
			end
		end)
		
		Hitbox:BeginCast(0.1)
		
		Hitbox.Events.OnCastEnded:Connect(function()
			if not self.Hit then
				self.Animations.Windup:AdjustSpeed(0.75)
			end
		end)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Connect(function()
		self:Close()
	end))

	self:FireReliableVFX(self.EffectPath, "Start", self.LuaCharacter.Model)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.AnimationSettings = {Speed = 1.25}
	self.EffectPath = `Edgerunner/{script.Name}`
	self:_Init()
	
	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack