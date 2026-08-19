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
	self.Combat:DivideSpeed(20)

	local Bottle = script.Soap:Clone()
	Bottle.Base.SoapBaseJoint.Part0 = self.LuaCharacter.RightArm;
	Bottle.Parent = workspace.Visuals

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(10)
		Bottle:Destroy()
		
		self.Combat:TimesSpeed(20)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("LastOil"):Once(function()
		self:FireReliableVFX("Meaty Michael/The Last Oil", "LastOil", self.LuaCharacter.RootPart)
		
		local Hitbox = self:CreateHitbox(true, true);
		Hitbox.Params.Size = 40

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			self:Afflict(VictimLuaPlayer, {
				Damage = 7.5,
				BreakBlock = true,
				TrueStun = 1,
				Velocity = {Vector3.yAxis * 25, 0.01}
			})
		end)

		Hitbox:Detect()
		
		task.defer(function()
			Hitbox:Destroy()
		end)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("BottleStretchStart"):Once(function()
		self:FireReliableVFX("Meaty Michael/The Last Oil", "BottleStretchStart", Bottle, self.LuaCharacter.RootPart)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("BottleStretchEnd"):Once(function()
		self:FireReliableVFX("Meaty Michael/The Last Oil", "BottleStretchEnd", Bottle)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Cusp"):Once(function()
		self:FireReliableVFX("Meaty Michael/The Last Oil", "Cusp", self.LuaCharacter.RootPart)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Clap"):Once(function()
		self:FireReliableVFX("Meaty Michael/The Last Oil", "Clap", self.LuaCharacter.RootPart)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("BottleOpen"):Once(function()
		self:FireReliableVFX("Meaty Michael/The Last Oil", "BottleOpen", Bottle)
		
		self.Combat:StackState("HitboxImmunity", true)
		
		self.Thread.OnClosed:Connect(function()
			self.Combat:StackState("HitboxImmunity", false)
		end)
	end))

	self.Animations.Windup.Stopped:Wait()
	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.AnimationSettings = {Speed = 1.135}
	self.TryToCancelMoves = true

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack