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
	self.Combat:DivideSpeed(4)
	
	-- flint and STEEL
	self.Flint = script.Flint:Clone()
	self.Flint.Parent = workspace
	self.Flint.Weld.Part0 = self.LuaCharacter.LeftArm
	
	self.Steel = script.Steel:Clone()
	self.Steel.Parent = workspace
	self.Steel.Weld.Part0 = self.LuaCharacter.RightArm

	self.Thread.CancelJob:Task(self:CreateMoveSFX("Steve", "FLINT and STEEL"))
	
	self.Thread.OnClosed:Connect(function()
		self.Combat:TimesSpeed(4)
		self.Combat:StackState("Attacking", false)
	end)
	
	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -7.25)
	Hitbox.Params.Size = Vector3.new(8, 8, 8)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("spark"):Connect(function()
		self:FireReliableVFX("Steve/FLINT and STEEL", "Spark", self.Flint)

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Validated = self:Afflict(VictimLuaPlayer, {
				TrueStun = 3,
				BreakBlock = true,
				Damage = 15,
				Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 6.5, 0.05},
			})
			
			if Validated then
				VictimCombat:PlayRandomHitReaction()
			end
		end)
		
		Hitbox:Detect()
		self.Combat.Hitbox:Destruction(Hitbox.Params.Offset, Hitbox.Params.Size, 4)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("throw"):Connect(function()
		-- self:FireReliableVFX("Steve/FLINT and STEEL", "Spark", self.Flint)
		
		local Projectile = self.Combat.Projectiles:Create("Obsidian", self.LuaCharacter.RootPart.Position, self.LuaCharacter.RootPart.CFrame.LookVector * 120, {
			HeightenWithGround = true,
			Height = 5,
			MaxDistance = 2000,
			DetectionSize = 8
		})

		Projectile.Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Validated = self:Afflict(VictimLuaPlayer, {
				TriggerActiveCounterOverOrEqualLevel = -1,
				DontBypassIFrames = {},
				BreakBlock = true,
				Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 500 + Vector3.yAxis * 90, 0.2},
				Ragdoll = 2.5,
				Damage = 100
			})
			
			if Validated then
				self.Combat:VictimImpactGround(VictimLuaPlayer)
			end
		end)
		
		Projectile:Start()
	end))

	task.wait(2.2)
	
	self.Flint:Destroy()
	self.Steel:Destroy()

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