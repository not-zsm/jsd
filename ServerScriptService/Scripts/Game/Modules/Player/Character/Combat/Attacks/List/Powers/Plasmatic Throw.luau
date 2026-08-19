local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Signal = require( ReplicatedStorage.Packages.Signal )

local RocksFolder = workspace.Map.Model.Props.Rocks

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)


----------------------------------------------------------------------------------

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(self.SpeedDecrease)
	
	self:FireReliableVFX("Powers/Plasmatic Throw", "Start", self.LuaCharacter.Model)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(self.Cooldown)
		self.Combat:TimesSpeed(self.SpeedDecrease)
		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("HitboxImmunity", false)
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Charge"):Connect(function(Parameter)
		if Parameter == "2" then
			self.Combat:StackState("HitboxImmunity", true)
		end
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Throw"):Connect(function()
		self.Combat:StackState("HitboxImmunity", false)
		
		local Projectile = self.Combat.Projectiles:Create("Plasma", self.LuaCharacter.RootPart.Position, self.LuaCharacter.RootPart.CFrame.LookVector * 120, {
			HeightenWithGround = false,
			Height = 5,
			MaxDistance = 100,
			DetectionSize = 6,
			DestructionPower = 4,
		})
		
		self.Thread.Job:Task(Projectile)
		
		local function Explode(Position : Vector3)
			self:FireReliableVFX("Powers/Plasmatic Throw", "Hit", Position)
			
			local AoeHitbox = self:CreateHitbox(true, true);
			AoeHitbox.Params.Size = 15
			AoeHitbox.Adornee = Position
			AoeHitbox.Params.DestroyOnEndCast = false

			AoeHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat

				local Difference : Vector3 = (VictimLuaCharacter.RootPart.Position - self.LuaCharacter.RootPart.Position)

				local Validated = self:Afflict(VictimLuaPlayer, {
					DontBypassIFrames = {},
					BreakBlock = true,
					Damage = 15,
					TriggerActiveCounterOverOrEqualLevel = -1,
					Ragdoll = 2,
					Velocity = {Difference.Unit * 50 + Vector3.yAxis * 10, 0.1}
				})
				
				if Validated then
					self:FireReliableVFX("Powers/Plasmatic Throw", "HitPlayer", VictimLuaCharacter.RootPart)
				end
			end)
			AoeHitbox:BeginCast(0.05)

			Projectile:Destroy()
		end

		Projectile.Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			Explode(Projectile.Position)
		end)
		
		Projectile.OnMapHit:Connect(function(Raycast : RaycastResult)
			Explode(Raycast.Position)
		end)
		
		Projectile.OnExpire:Connect(function()
			Explode(Projectile.Position)
		end)

		Projectile:Start()
	end))
	
	self.Thread.Job:Task(self.Animations.Windup.Stopped:Wait())
	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.TryToCancelMoves = true
	self.SpeedDecrease = 10
	self.Cooldown = 40

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack