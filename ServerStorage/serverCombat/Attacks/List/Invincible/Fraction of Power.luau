local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:StackState("HitboxImmunity", true)
	self.Combat:DivideSpeed(10)

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 3, -3)
	Hitbox.Params.Size = Vector3.new(15, 15, 10)

	local Hit = false
	
	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		Hit = self:Afflict(VictimLuaPlayer, {
			Ragdoll = 5.5,
			Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 20 + Vector3.yAxis * 350, 0.1},
			Damage = 20,
			DontCheckBlock = true,
		})

		if Hit then
			self.Combat:VictimImpactGround(VictimLuaPlayer)
			self:FireReliableVFX("Invincible/Are You Sure", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)

			task.wait(0.5)
			
			self.Animations.Windup:Stop(0.35)
			self:Close()
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(12)
		self.Combat:TimesSpeed(10)
		
		self.Combat:StackState("HitboxImmunity", false)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Connect(function()
		self:FireReliableVFX("Invincible/Are You Sure", "Shockwave", self.LuaCharacter.RootPart)
		
		Hitbox:Detect();
		
		local Rnd = Random.new();

		self.Combat.Hitbox:CreateHavocReplicated({
			parameters = {
				origin = Hitbox:GetCFrame(),
				shape = "Sphere", 
				radius = 8,
				block_size = 4.5,
			},
			debris = {
				scale = 0.9,
				velocity = function(part)
					return Rnd:NextUnitVector() * 15 + Vector3.yAxis * Rnd:NextNumber(75, 175);
				end,
			},
		});
		
		task.defer(function()
			if not Hit then
				self.Combat:StackState("HitboxImmunity", false)
			end
		end)
		
		self.Combat.Hitbox:Destruction(Hitbox.Params.Offset, Hitbox.Params.Size, 8)
	end))

	task.wait(2)

	self:Close()
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