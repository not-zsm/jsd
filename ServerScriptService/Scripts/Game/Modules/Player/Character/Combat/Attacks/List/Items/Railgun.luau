local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking") and not self.Combat:GetState("M1ing")
end

function Attack:Activate()
	local Item = self.LuaCharacter.Items.EquippedItem
	self.LuaCharacter.Items:Remove(Item)
	
	self.Combat:StackState("HitboxImmunity", true)
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)
	
	self:FireReliableVFX("Universal/Railgun", "Start", self.LuaCharacter.Model, self.LuaPlayer.FriendTable[math.random(1, #self.LuaPlayer.FriendTable)])
	
	self.Animations.User:Play()
	
	self.Thread.CancelJob:Task(self:CreateMoveSFX("Universal", "Railgun"))
	
	local HitPlayers = {}
	
	local PiercingHitbox = self:CreateHitbox()
	PiercingHitbox.Params.Offset = CFrame.new(0, 0, -500)
	PiercingHitbox.Params.Size = Vector3.new(10, 10, 1000) 
	PiercingHitbox.Params.DestroyOnEndCast = false
	PiercingHitbox.Params.MaxTargets = 30
	PiercingHitbox.Params.TrySorting = false
	PiercingHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		if HitPlayers[VictimLuaPlayer] then return end 

		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			Ragdoll = 3,
			
			Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 350 + Vector3.yAxis * 150, 0.1},
			
			Damage = {
				Amount = 100,
				DontCountToUltimate = true
			},
			BreakBlock = true
		})
		if Validated then
			HitPlayers[VictimLuaPlayer] = true 
			self.Combat:VictimImpactGround(VictimLuaPlayer)
		end
	end)
	
	local AoeHitbox = self:CreateHitbox()
	AoeHitbox.Params.Offset = CFrame.new(0, 0, -500)
	AoeHitbox.Params.Size = Vector3.new(200, 75, 1000)
	AoeHitbox.Params.DestroyOnEndCast = false
	AoeHitbox.Params.MaxTargets = 30
	AoeHitbox.Params.TrySorting = false

	AoeHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		if HitPlayers[VictimLuaPlayer] then return end
		
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,

			Ragdoll = 3,
			Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 350 + Vector3.yAxis * 150, 0.1},

			Damage = {
				Amount = 45,
				DontCountToUltimate = true
			},

			BreakBlock = true
		})

		if Validated then
			self.Combat:VictimImpactGround(VictimLuaPlayer)
		end
	end)
	
	self.Thread.Job:Task(self.Animations.User:GetMarkerReachedSignal("ChargeReady"):Connect(function()
		self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
	end))
	
	self.Thread.Job:Task(self.Animations.User:GetMarkerReachedSignal("Shoot"):Connect(function()
		PiercingHitbox:BeginCast(0.1)
		AoeHitbox:BeginCast(0.1)
		self.Combat.Hitbox:Destruction(AoeHitbox.Params.Offset, AoeHitbox.Params.Size, 10, nil, {dont_create_debris = true})
	end))
	
	self.Thread.OnClosed:Connect(function()
		self.Combat:RemoveAttack("Railgun")
		
		self.Combat:TimesSpeed(50)
		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("HitboxImmunity", false)
	end)

	self.Animations.User.Ended:Wait()

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