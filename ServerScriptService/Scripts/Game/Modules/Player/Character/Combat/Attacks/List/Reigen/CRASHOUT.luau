local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking") and self.LuaCharacter.Humanoid.Health < 50
end

function Attack:Activate()
	self.Animations.User:Play()

	self.Combat:StackState("HitboxImmunity", true)
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)

	self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
	
	local Ultimate, Matched = self.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

	local HitByDomain = {}

	local DomainPart = self.Thread.Job:Task(script.DomainCollider:Clone())
	DomainPart.CFrame = self.Combat:GetSimulatedRoot().CFrame
	DomainPart.Parent = workspace.Visuals
	
	local DomainHitbox = self:CreateHitbox(true)
	DomainHitbox.Params.Size = 24
	DomainHitbox.Params.DestroyOnEndCast = false

	DomainHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			BreakBlock = true
		})

		if Validated then
			if HitByDomain[VictimLuaPlayer] then
				return
			end
			
			HitByDomain[VictimLuaPlayer] = true

			VictimCombat:TrueStun(21)
			VictimCombat:StackState("CannotDash", true)
			VictimCombat:StackState("HitboxImmunity", true)

			VictimCombat:ToggleHeadMovement(false)
			VictimCombat:HideUI(true)
			
			self.Thread.Job:Task(VictimLuaCharacter:StopAutoRotate())
			VictimLuaPlayer.Replication:FireReliableVFXToSelf("Reigen/CRASHOUT", "Cutscene", self.LuaCharacter.Model)

			task.delay(21, function()
				VictimCombat:StackState("CannotDash", false)
				VictimCombat:StackState("HitboxImmunity", false)

				VictimCombat:ToggleHeadMovement(true)
				VictimCombat:HideUI(false)
			end)
		end
	end)

	local ExplosionHitbox = self:CreateHitbox(true)
	ExplosionHitbox.Params.Size = 26
	ExplosionHitbox.Params.DestroyOnEndCast = false

	ExplosionHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			BreakBlock = true
		})

		if Validated then
			self:Afflict(VictimLuaPlayer, {
				ExcludeAttempts = true,
				Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 85 + Vector3.yAxis * 50, 0.15},
				Damage = 100
			})
		end
	end)

	self.Thread.Job:Task(self.Animations.User:GetMarkerReachedSignal("mobexplode"):Connect(function()
		DomainPart:Destroy()
	end))

	self.Thread.Job:Task(self.Animations.User:GetMarkerReachedSignal("endexplode"):Connect(function()
		ExplosionHitbox:Detect()

		for VictimLuaPlayer in pairs(HitByDomain) do
			self:Afflict(VictimLuaPlayer, {
				ExcludeAttempts = true,
				Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 85 + Vector3.yAxis * 50, 0.15},
				Damage = 100
			})
		end

		table.clear(HitByDomain)
		HitByDomain = nil
	end))

	DomainHitbox:Detect()
	
	if Matched then
		Ultimate:StopMusic()
	end
	
	self.Combat:ToggleHeadMovement(false)
	self.Combat:HideUI(true)

	self:FireReliableVFX("Reigen/CRASHOUT", "OnStart", self.LuaCharacter.Model)
	self:FireReliableVFXToSelf("Reigen/CRASHOUT", "Cutscene", self.LuaCharacter.Model)

	self.Animations.User.Stopped:Once(function()
		self:Close()
	end)
	
	self.Thread.OnClosed:Connect(function()
		self.Combat:ToggleHeadMovement(true)
		self.Combat:HideUI(false)
		
		if Matched then
			Ultimate:SetBarPausing(false)
			Ultimate:StopUltimate()
		end

		self.Combat:TimesSpeed(50)
		self.Combat:StackState("HitboxImmunity", false)
		self.Combat:StackState("Attacking", false)
	end)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	
	task.defer(function()
		self:ChangeDisplay(self.DisplayName, {
			Tip = "NEED 50% HP"
		})
	end)
	
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack