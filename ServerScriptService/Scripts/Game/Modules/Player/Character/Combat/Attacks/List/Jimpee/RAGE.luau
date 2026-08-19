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
	self:FireReliableVFX("Jimpee/RAGE", "Start", self.LuaCharacter.RootPart)
	
	local Position : Vector3 = self.Combat:GetSimulatedRoot().Position

	local StompHitbox = self:CreateHitbox(true)
	StompHitbox.Params.MaxTargets = -1
	StompHitbox.Params.Offset = CFrame.identity
	StompHitbox.Params.Size = 400
	
	StompHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			Damage = 20,
			BreakBlock = true,
			CannotBeAdapted = true,
			DontBypassIFrames = {},
		})

		if Validated then
			VictimCombat:TrueStun(30)

			self.Combat:TSBPushVictim(VictimLuaPlayer, {
				LandedRollVelocityZ = 300,
				LandedRollDuration = 0.85,
				DontBeginAoeHitbox = true,
			})
		end
	end)
	
	StompHitbox:Detect()
	
	task.delay(20.75, function()
		print("boom.")

		local Hitbox = self:CreateHitbox(true)
		Hitbox.Adornee = Position
		Hitbox.Params.MaxTargets = -1
		Hitbox.Params.Offset = CFrame.identity
		Hitbox.Params.Size = 400

		Hitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
			self:Afflict(NewVictimLuaPlayer, {
				TriggerActiveCounterOverOrEqualLevel = -1,
				FinisherKill = true,
				Ragdoll = 10,
				DontCheckBlock = true,
				CannotBeAdapted = true,
				DontBypassIFrames = {},
				Velocity = {(NewVictimLuaPlayer.Character.RootPart.Position - Position).Unit * 200 + Vector3.yAxis * 100, 0.1}
			})
		end)

		Hitbox:Detect()

		self.Combat.Hitbox:CreateHavocReplicated({
			parameters = {
				origin = CFrame.new(Position),
				shape = "Sphere", 
				radius = Hitbox.Params.Size,
				block_size = Hitbox.Params.Size / 3, 
			},
		})
		
		task.wait(8)

		print("closed")

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