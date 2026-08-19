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
	self.Combat:DivideSpeed(10)
	
	self.Countered = false

	self.Combat:CreateCounter(1, function(VictimLuaPlayer)
		self.Countered = true
		
		self.Combat:StackState("GrabIFrames", true)
		self.Thread.OnClosed:Connect(function()
			self.Combat:StackState("GrabIFrames", false)
		end)
		
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat
		
		VictimCombat:TrueStun(3)
		--VictimCombat.Ragdoll:Toggle(true, 2)
		
		self:Afflict(VictimLuaPlayer, {
			Ragdoll = 2;
		})
		
		local HitCount = 0
		
		self.Thread.Job:Task(self.Animations.Counter:GetMarkerReachedSignal("hit"):Connect(function()
			HitCount += 1
			
			local Hitbox = self:CreateHitbox(false);
			Hitbox.Params.Offset = CFrame.new(0, 2, -3)
			Hitbox.Params.Size = Vector3.new(8, 12, 8)

			Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat

				local Validated = self:Afflict(VictimLuaPlayer, {
					BreakBlock = true,
					Damage = 2,
					Ragdoll = 2,
					Velocity = {Vector3.yAxis * 42.5 / (HitCount * 1.35), 0.1}
				})
				
				if Validated then
					self:FireVFX("Garou/Flowing Water", "Hit", self.LuaCharacter.Model, VictimLuaCharacter.RootPart)
				end
			end)
			
			Hitbox:BeginCast(0.1)
		end))
		
		self.Thread.Job:Task(self.Animations.Counter:GetMarkerReachedSignal("finalhit"):Once(function()
			local Hitbox = self:CreateHitbox(false);
			Hitbox.Params.Offset = CFrame.new(0, 2, -3)
			Hitbox.Params.Size = Vector3.new(8, 12, 8)

			Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat

				local Validated = self:Afflict(VictimLuaPlayer, {
					BreakBlock = true,
					Damage = 6,
					Ragdoll = 2,
					Velocity = {(VictimLuaPlayer.Character.RootPart.Position - self.LuaCharacter.RootPart.Position).Unit * 130 + Vector3.yAxis * 25, 0.1}
				})
				
				if Validated then
					self:FireVFX("Garou/Flowing Water", "FinalHit", VictimLuaCharacter.RootPart)
				end
			end)

			Hitbox:BeginCast(0.1)
		end))
	
		self.Animations.Windup:Stop(); self.Animations.Counter:Play()
		
		self.Thread.Job:Task(self.Animations.Counter.Stopped:Once(function()
			self:Close()
		end))
	end)
	
	self.Thread.OnClosed:Connect(function()
		self.Combat:RemoveActiveCounter()
		
		self:AddCooldown(10)
		
		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	task.wait(0.6)

	self.Combat:RemoveActiveCounter()
	
	task.wait(1)
	
	if not self.Countered then
		self:Close()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.Countered = false

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack