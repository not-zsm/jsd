local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )
local Sphere = require( ReplicatedStorage.Modules.Shared.Game.Hitbox.Type.Sphere )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self:FireReliableVFX("Jimpee/Atomize", "Start", self.LuaCharacter.RootPart)
	
	for _, LuaPlayer in LuaPlayerList.LuaPlayers do
		LuaPlayer.Character.Combat:HideUI(true)
		
		self.Thread.Job:Task(function()
			LuaPlayer.Character.Combat:HideUI(false)
		end)
	end
	
	local Adornee : BasePart = self.Combat:GetSimulatedRoot()
	local Position = Adornee.Position

	local StompParams = Sphere.NewParams()
	StompParams.MaxTargets = -1
	StompParams.Offset = CFrame.identity
	StompParams.Size = 400
	StompParams.DestroyOnEndCast = false
	StompParams.Ignore = {self.LuaCharacter.Model}
	StompParams.Debug = false

	local StompHitbox = Sphere.new(Position, StompParams)
	self.Thread.Job:Task(StompHitbox)
	
	StompHitbox.Events.HumanoidHit:Connect(function(Humanoid : Humanoid)
		local VictimLuaPlayer = LuaPlayerList.Get(Humanoid)
		if (VictimLuaPlayer == nil) then return end

		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		if VictimLuaCharacter.HumanoidExists then
			local Validated = self:Afflict(VictimLuaPlayer, {
				TriggerActiveCounterOverOrEqualLevel = -1,
				Damage = 20,
				BreakBlock = true,
				CannotBeAdapted = true,
				DontBypassIFrames = {},
			})

			if Validated then
				VictimCombat:TrueStun(40)

				self.Combat:TSBPushVictim(VictimLuaPlayer, {
					LandedRollVelocityZ = 300,
					LandedRollDuration = 0.85,
					DontBeginAoeHitbox = true,
				})
			end
		end
	end)

	StompHitbox:Detect()
	
	task.delay(30, function()
		local BoomParams = Sphere.NewParams()
		BoomParams.MaxTargets = -1
		BoomParams.Offset = CFrame.identity
		BoomParams.Size = 400
		BoomParams.DestroyOnEndCast = false
		BoomParams.Ignore = {self.LuaCharacter.Model}
		BoomParams.Debug = false

		local BoomHitbox = Sphere.new(Position, BoomParams)
		self.Thread.Job:Task(BoomHitbox)
		
		BoomHitbox.Events.HumanoidHit:Connect(function(Humanoid : Humanoid)
			local VictimLuaPlayer = LuaPlayerList.Get(Humanoid)
			if (VictimLuaPlayer == nil) then return end

			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			if VictimLuaCharacter.HumanoidExists then
				self:Afflict(VictimLuaPlayer, {
					TriggerActiveCounterOverOrEqualLevel = -1,
					FinisherKill = true,
					Ragdoll = 10,
					DontCheckBlock = true,
					CannotBeAdapted = true,
					DontBypassIFrames = {},
					Velocity = {(VictimLuaCharacter.RootPart.Position - Position).Unit * 200 + Vector3.yAxis * 100, 0.1}
				})
			end
		end)

		BoomHitbox:Detect()

		self.Combat.Hitbox:CreateHavocReplicated({
			parameters = {
				origin = CFrame.new(Position),
				shape = "Sphere", 
				radius = BoomHitbox.Params.Size,
				block_size = BoomHitbox.Params.Size / 3, 
			},
		})

		self:Close()
	end)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.Uncancellable = true
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack