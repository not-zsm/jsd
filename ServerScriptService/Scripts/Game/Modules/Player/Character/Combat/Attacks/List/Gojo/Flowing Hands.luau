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
	self.Combat:DivideSpeed(5)

	self.Hit = false

	self.Thread.OnClosed:Connect(function()
		self.Combat:TimesSpeed(5)
		self.Combat:StackState("Attacking", false)
	end)

	task.wait(0.425)

	if self.LuaPlayer.IsNPC then
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 0.625
		VelocityObject.Settings.RemoveTime = 0.525
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.FixScale = true;
		VelocityObject.Settings.Z = 40
		VelocityObject:Fire()
	else
		self:FireReliableVFXToSelf("Gojo/Flowing Hands", "Velocity", self.LuaCharacter.RootPart, 100, 0.525, 0.3)
	end;
	
	self.LuaCharacter.Model:SetAttribute("FlowingHands", true)

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0.5, -4)
	Hitbox.Params.Size = Vector3.new(4, 1, 5)
	Hitbox.Params.MaxTargets = 1

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local WasBlocking = VictimCombat:GetState("Blocking")

		if self.Combat:CalculateHitAngle(VictimLuaPlayer) >= math.rad(90) then
			WasBlocking = false
		end

		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true
		})

		if Validated then
			self.Hit = true
			self.Animations.Windup:Stop() self.Animations.Hit:Play()

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -2.85) * CFrame.Angles(0, math.pi, 0))

			self:FireVFX("Gojo/Flowing Hands", "Hand", self.LuaCharacter.LeftArm)
			self:FireVFX("Gojo/Flowing Hands", "Hand", self.LuaCharacter.RightArm)
			self:FireVFX("Gojo/Flowing Hands", "Start", self.LuaCharacter.RootPart)
			self:FireVFX("Gojo/Flowing Hands", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, "1")

			local VictimHits = {
				1, 2, 3, 2, 3,
			}

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("hit"):Connect(function(Count : string)
				self:FireVFX("Gojo/Flowing Hands", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, Count)

				if Count == "7" then
					GrabObject.Destroy(0.35)

					VictimLuaCharacter.RootPart.CFrame = self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0)
					
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true;
						Ragdoll = 2;
					})
					--VictimCombat.Ragdoll:Toggle(true, 2)

					local Velocity = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * (WasBlocking and 80 or 45) + Vector3.yAxis * 20
					
					local VelocityObject = self:VelocityOn(VictimCombat)
					VelocityObject.Settings.RemoveTime = 0.1
					VelocityObject.Settings.Velocity = Velocity
					VelocityObject:Fire()

					if (WasBlocking) then
						VictimCombat:StackState("GrabIFrames", true)

						task.delay(0.5, function()
							VictimCombat:StackState("GrabIFrames", false)
						end)
					end

					VictimCombat:Unstun()
					self:Close()

				elseif Count == "6" then
					self.LuaCharacter.Model:SetAttribute("FlowingHands", nil)

					VictimCombat:PlayCertainHitReaction(3)
					
					if self.LuaPlayer.IsNPC then
						local VelocityObject = self.Combat:Velocity()
						VelocityObject.Settings.Duration = 0.35
						VelocityObject.Settings.RemoveTime = 0.4
						VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
						VelocityObject.Settings.Controllable = true
						VelocityObject.Settings.FixScale = true;
						VelocityObject.Settings.Z = 40
						VelocityObject:Fire()
					else
						self:FireReliableVFXToSelf("Gojo/Flowing Hands", "Velocity", self.LuaCharacter.RootPart, 20, 0.9, 1);
					end
				else
					VictimCombat:PlayCertainHitReaction(VictimHits[tonumber(Count)])
			
					if self.LuaPlayer.IsNPC then
						local VelocityObject = self.Combat:Velocity()
						VelocityObject.Settings.Duration = 0.5
						VelocityObject.Settings.RemoveTime = 0.45
						VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
						VelocityObject.Settings.Controllable = true
						VelocityObject.Settings.FixScale = true;
						VelocityObject.Settings.Z = 50
						VelocityObject:Fire()
					else
						self:FireReliableVFXToSelf("Gojo/Flowing Hands", "Velocity", self.LuaCharacter.RootPart, 100, 0.5, 0.4);
					end
				end
			end))
		end
	end)
	
	Hitbox:BeginCast(0.175)
	
	task.wait(0.85)

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