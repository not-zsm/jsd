local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )

----------------------------------------------------------------------------------

local Attack = {}
Attack.__index = Attack

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Pretrigger()
	if self.UseTwicePart then
		self.TriedTwicePart = true
		self.OnTriedTwicePart:Fire()
	end
end

function Attack:ToggleUseTwicePart(Value : boolean)
	if self.UseTwicePart ~= Value then
		self.UseTwicePart = Value
		
		if Value then
			self.Combat:ChangeAttackDisplay(self.Name, self.DisplayName, {
				FlashColor = Color3.fromRGB(255, 255, 255),
				Tip = "[USE AGAIN]"
			})
		else
			self.Combat:ChangeAttackDisplay(self.Name, self.DisplayName, {
				FlashColor = Color3.fromRGB(255, 255, 255),
				Tip = ""
			})
		end
	end
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self.Hit = false
	self.UseTwicePart = false
	self.TriedTwicePart = false
	
	self:FireReliableVFX("Gojo/Ruthless Kicks", "OnStart", self.LuaCharacter.Model)
	self.Thread.CancelJob:Task(self:CreateMoveSFX("Gojo", "Ruthless Kicks"))
	
	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -2)
	Hitbox.Params.Size = Vector3.new(6, 6, 7)
	Hitbox.Params.DestroyOnEndCast = false
	Hitbox.Params.MaxTargets = 1
	
	local Blocked = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated, Type = self:Afflict(VictimLuaPlayer, {
			YDifferenceValue = -2,
		})
		
		Blocked = (Type == "Blocked")

		if Validated then
			self.Hit = true

			local VictimAnimation : AnimationTrack = VictimLuaCharacter.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Gojo["Ruthless Kicks"].Victim)
			local VictimAnimationPush : AnimationTrack = VictimLuaCharacter.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Gojo["Ruthless Kicks"].VictimPush)
			
			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, 0.5))
			
			local BeenPushed = false
			
			self.Thread.OnClosed:Connect(function()
				if not BeenPushed then
					VictimAnimation:Stop(0)
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end
			end)
			
			local function Push(Z : number, Time : number)
				local VelocityObject = self.Combat:Velocity()

				if VelocityObject then
					VelocityObject.Settings.Duration = Time
					VelocityObject.Settings.RemoveTime = Time + 0.1
					VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
					VelocityObject.Settings.Controllable = true
					VelocityObject.Settings.Z = Z
					VelocityObject:Fire()

					self.Thread.Job:Task(VelocityObject)
				end
			end
			
			Push(60, 0.7)
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("hit"):Connect(function(Parameter : string)
				if Parameter == "1" then
					Push(50, 0.65)

				elseif Parameter == "2" then
					BeenPushed = true
					
					self:ToggleUseTwicePart(true)
					
					self.Thread.OnClosed:Connect(function()
						self:ToggleUseTwicePart(false)
					end)
					
					local FlingJob = Job.new()
					
					VictimLuaCharacter.Model:PivotTo(self.Combat:GetSimulatedRoot().CFrame * CFrame.new(0, 0, -4) * CFrame.Angles(0, math.pi, 0))
					VictimAnimation:Stop(0)
					
					VictimCombat:TrueStun()
					FlingJob:Task(VictimLuaCharacter:StopAutoRotate())
					
					local VelocityObject = self:VelocityOn(VictimCombat)
					VelocityObject.Settings.Duration = 0.975
					VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
					VelocityObject.Settings.Controllable = true
					VelocityObject.Settings.Z = -88
					VelocityObject:Fire()
					
					FlingJob:Task(VelocityObject)
					
					FlingJob:Task(VictimAnimationPush.Stopped:Once(function()
						FlingJob:Destroy()
						VictimCombat:Unstun()
					end))

					FlingJob:Task(VictimCombat.OnStateUpdated:Connect(function(StateChanged : any, Value : any)
						if (StateChanged == "Stunned" or StateChanged == "Ragdolled") and Value then
							VictimAnimationPush:Stop(0.3)
						end
					end))
					
					VictimAnimationPush:Play(0)
				
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
					
					Push(35, 0.625)
					
					task.wait(0.5)
					
					self:ToggleUseTwicePart(false)
					
					if not self.TriedTwicePart then
						self.Animations.Hit:Stop(0.4)
						self:Close()
					end
					
				elseif (Parameter == "3") then
					local CF : CFrame = self.Combat:GetSimulatedRoot().CFrame
					
					local Hitbox = self:CreateHitbox(false);
					Hitbox.Params.Offset = CFrame.new(0, 0, -3)
					Hitbox.Params.Size = Vector3.new(6.5, 7, 9.25)
					Hitbox.Params.DestroyOnEndCast = false

					Hitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
						self.Combat:Afflict(NewVictimLuaPlayer, {
							BreakBlock = true,
							Damage = 7,
							Velocity = {CF.LookVector * 75 + -CF.RightVector * 15 + Vector3.yAxis * 30, 0.1},
							Ragdoll = 2,
						})
					end)
					
					Hitbox:Detect()
					
					task.wait(0.5)
					
					self:Close()
				end
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("dash"):Once(function()
				Push(100, 0.875)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("slightpush"):Connect(function()
				Push(35, 0.625)
			end))
			
			----------------------------------------------------------------
			
			self.Animations.Windup:Stop(0) 
			self.Animations.Hit:Play(0, 1, 1.15)
			VictimAnimation:Play(0, 1, 1.15)
			
			self:FireReliableVFX("Gojo/Ruthless Kicks", "OnHit", self.LuaCharacter.Model, VictimLuaCharacter.Model)
			self.Thread.CancelJob:Task(self:CreateMoveSFX("Gojo", "Ruthless Kicks", "HitSFX"))
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(25)
		
		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Once(function()
		Hitbox:BeginCast(0.05)
	end))

	task.wait(Blocked and 1.4 or 1)

	if not self.Hit then
		self:Close()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	
	self.UseTwicePart = false
	self.TriedTwicePart = false
	self.OnTriedTwicePart = self.Job:Task(EventService.new())
	
	--self.AnimationSettings = {
	--	FadeTime = 0.1,
	--	Weight = 1,
	--	Speed = 1.4
	--}
	
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack