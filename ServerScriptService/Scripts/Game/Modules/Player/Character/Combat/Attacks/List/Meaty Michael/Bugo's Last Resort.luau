local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(25)
		self.Combat:StackState("Attacking", false)
	end)
	
	local RootPart = self.Combat:GetSimulatedRoot();
	local Offset = CFrame.new(5, 0, 40);
	
	local SummonCoordinate = (
		Utility.VectorToRotation(RootPart.CFrame.RightVector:Cross(-Vector3.yAxis)) + RootPart.Position
	) * Offset;
	
	local Result = workspace:Raycast(SummonCoordinate.Position, -Vector3.yAxis * 512, Utility.VisualParams);
	local Coordinate = CFrame.lookAlong((SummonCoordinate * CFrame.new(0, -2.5, 0)).Position, Vector3.yAxis)
	
	if Result then
		Coordinate = CFrame.lookAlong(Result.Position, Result.Normal) + Result.Normal * 0.01;
	end;
	
	self:FireReliableVFX("Meaty Michael/Bugo's Last Resort", "BugoBoss", SummonCoordinate.Rotation + Coordinate.Position, Coordinate)

	-- 1.8 seconds is the time the bugo STRIKES !!!!!!!!!! begone cowards !!!!!!!!!!!!! 🗣️🗣️🗣️🗣️🗣️
	task.delay(1.8, function()
		local Hitbox = self:CreateHitbox(true, true);
		Hitbox.Adornee = Coordinate
		Hitbox.Params.Offset = CFrame.new(-5, 15, -50)
		Hitbox.Params.Ignore = self.KillOnUse and {} or Hitbox.Params.Ignore
		Hitbox.Params.Size = 140

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			self:Afflict(VictimLuaPlayer, {
				FinisherKill = true,
				BreakBlock = true,
				DontBypassIFrames = {},
				Velocity = {(VictimLuaCharacter.RootPart.Position - Coordinate.Position).Unit * 40 + Vector3.yAxis * 175, 0.25}
			})
		end)

		self.Combat.Hitbox:CreateHavocReplicated({
			parameters = {
				origin = Coordinate,
				shape = "Sphere", 
				radius = 110,
				block_size = 20, 
			},
		})

		Hitbox:Detect()

		task.defer(function()
			Hitbox:Destroy()
		end)
	end)
	
	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.KillOnUse = false
	self.AnimationSettings = {FadeTime = 0.1, Speed = 1}

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack