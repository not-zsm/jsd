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

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

local function FadePart(Part)
	TweenService:Create(Part, TweenInfo.new(3), {Transparency = 1}):Play()
	task.delay(3, Part.Destroy, Part)
end

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	local Item = self.LuaCharacter.Items.EquippedItem
	if (not Item) or (Item.Name ~= "Raygun") then return false end
	
	return self:BasicConditions() and not self.Combat:GetState("Blocking") and not Item.OnCooldown
end

function Attack:Activate()
	local Item = self.LuaCharacter.Items.EquippedItem
	if Item.Name ~= "Raygun" then self:Close() end
	
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(self.SpeedDecrease)
	
	self.LuaCharacter.Model:SetAttribute("FreezeHotbar", true)
	Item.Object.CanBeDropped = false
	
	self:FireReliableVFX("Items/Raygun", "Start", self.LuaCharacter.Model, Item)
	
	self.Thread.OnClosed:Connect(function()
		self.Combat:TimesSpeed(self.SpeedDecrease)
		self.Combat:StackState("Attacking", false)
		self.LuaCharacter.Model:SetAttribute("FreezeHotbar", false)
		
		Item.OnCooldown = true
		task.delay(self.ShootCooldown, function()
			Item.OnCooldown = false
		end)
	end)
	
	local FireAttachment = self.Thread.Job:Task(script.FireAttachment:Clone())
	FireAttachment.Parent = self.LuaCharacter.RootPart
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Shoot"):Connect(function(Parameter) -- Vector3.new(0.658, 1.108, -3.612)
		local Projectile = self.Combat.Projectiles:Create("Raygun", FireAttachment.WorldPosition, self.LuaCharacter.RootPart.CFrame.LookVector * 300, {
			HeightenWithGround = false,
			Height = 0,
			MaxDistance = 300,
			DetectionSize = 1,
			DestructionPower = 1,
		})

		task.delay(3, Projectile.Destroy, Projectile)
		
		Projectile.Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			self:Afflict(VictimLuaPlayer, {
				BreakBlock = false,
				Damage = 5
			})
			
			Projectile:Destroy()
		end)

		Projectile.OnMapHit:Connect(function(Raycast : RaycastResult)
			Projectile:Destroy()
		end)

		Projectile.OnExpire:Connect(function()
			Projectile:Destroy()
		end)
		
		Projectile:Start()
	end))
	
	self.Thread.Job:Task(self.Animations.Windup.Stopped:Wait())
		
	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.TryToCancelMoves = true
	
	self.SpeedDecrease = 5
	self.ShootCooldown = 0.5

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack