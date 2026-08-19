local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

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
	self.Combat:DivideSpeed(20)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(16)
		
		self.Combat:TimesSpeed(20)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Hit = false
	self.Uncancellable = false
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("glint"):Connect(function()
		self.Uncancellable = true
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("shoot"):Connect(function()
		local Root : BasePart = self.Combat:GetSimulatedRoot()

		local Hitbox = self:CreateHitbox(true)
		Hitbox.Params.Offset = CFrame.new(0, -4, -5)
		Hitbox.Params.Size = 7.5
		
		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat
			
			local Was_Ragdolled = VictimCombat:GetState("Ragdolled")
			local Is_Perfect_Time = not Was_Ragdolled and VictimCombat.Ragdoll.GettingUpArmor

			local Damage = Was_Ragdolled and 9 or 12.5
			local Dead = VictimLuaCharacter.Humanoid.Health <= Damage
			
			self.Hit = self:Afflict(VictimLuaPlayer, {
				DontCheckBlock = true,
				Damage = Damage,
				Ragdoll = (Dead or not Was_Ragdolled) and 2 or nil,
				Velocity = (Dead or not Was_Ragdolled) and {Root.CFrame.LookVector * 50 + Vector3.yAxis * 25, 0.1} or nil,
				DontRestartRespawnTimer = true
			})
			
			if self.Hit then
				if Is_Perfect_Time then
					self:FireReliableVFX(self.EffectPath, "Timed_Hit", self.LuaCharacter.Model)
					
				elseif Was_Ragdolled and not Dead then
					VictimCombat:TrueStun(1.5)
					VictimCombat.Ragdoll:Toggle(false)
					
					local Difference : Vector3 = self.Combat:GetSimulatedRoot().CFrame.LookVector
					local CF = CFrame.lookAt(Vector3.zero, -Difference * Vector3.new(1, 0, 1)) + VictimLuaCharacter.RootPart.Position
					VictimLuaCharacter.Model:PivotTo(CF)
					
					local Velocity = self:VelocityOn(VictimCombat)
					Velocity.Settings.Duration = 1
					Velocity.Settings.RemoveTime = 1.25
					Velocity.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
					Velocity.Settings.Controllable = true
					Velocity.Settings.Z = -65
					Velocity:Fire()
					
					local Animation = VictimLuaCharacter.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Edgerunner[script.Name].Push)
					Animation:Play(0)
					
					--self.Combat:TSBPushVictim(VictimLuaPlayer, {
					--	LandedRollVelocityZ = 150,
					--	LandedRollDuration = 0.865
					--})
				end
				
				self:FireReliableVFX(self.EffectPath, "Hit", VictimLuaCharacter.Model)
			end
		end)
		
		Hitbox:Detect()
		
		local Velocity = self.Combat:Velocity()
		Velocity.Settings.Duration = 0.675
		Velocity.Settings.RemoveTime = 0.675
		Velocity.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		Velocity.Settings.Controllable = true
		Velocity.Settings.Z = -45
		Velocity:Fire()
		
		self.Thread.Job:Task(Velocity)
		
		self.Uncancellable = false
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Connect(function()
		self:Close()
	end))

	self:FireReliableVFX(self.EffectPath, "Start", self.LuaCharacter.Model)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.EffectPath = `Edgerunner/{script.Name}`
	self:_Init()
	
	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack