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
	return self:BasicConditions() and not self.Combat:GetState("Blocking") and not self.LuaCharacter.Model:GetAttribute("Used_Temp_V")
end

local Powers = {
	["Solar Vision"] = 15,
	["Invisibility"] = 15,
	["Super Speed"] = 20,
	["Plasmatic Throw"] = 20,
	["Starflare"] = 25,
}

local function GetRandomPower()
	local TotalWeight = 0
	for _, Probability in pairs(Powers) do
		TotalWeight += Probability
	end

	local RandomWeight = math.random() * TotalWeight
	local CurrentWeight = 0

	for Power, Probability in pairs(Powers) do
		CurrentWeight += Probability
		if RandomWeight <= CurrentWeight then
			return Power
		end
	end
end

function Attack:Activate()
	local Item = self.LuaCharacter.Items.EquippedItem
	if Item.Name ~= "Temp V" then self:Close() end
	
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)
	
	self.LuaCharacter.Model:SetAttribute("FreezeHotbar", true)
	Item.Object.CanBeDropped = false
	
	self.Thread.CancelJob:Task(
		self:CreateMoveSFX("Items", "Temp V")
	)
	
	--self:FireReliableVFX("Items/Temp V", "Drink", self.LuaCharacter.Model, Item)
	
	self.Thread.OnClosed:Connect(function()
		self.Combat:TimesSpeed(self.SpeedDecrease)
		self.Combat:StackState("Attacking", false)
		self.LuaCharacter.Model:SetAttribute("FreezeHotbar", false)
		
		self.LuaCharacter.Items:Remove(Item)
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Throw"):Connect(function(Parameter)
		if Parameter == "Cap" then
			local Cap = Item.Object.Parts.Cap
			Cap.Massless = false
			Cap.CanCollide = true
			Cap.Parent = workspace.Visuals

			Item.Object.Handle.CapWeld:Destroy()
			
			Cap.AssemblyLinearVelocity = Vector3.new(-10, 30, -5)
			
			task.delay(3, FadePart, Cap)
		else
			local Base = Item.Object.Parts.Base
			Base.Massless = false
			Base.CanCollide = true
			Base.Parent = workspace.Visuals

			Item.Object.Parts.Liquid:Destroy()
			Item.Object.Handle.BaseWeld:Destroy()
			
			Base.AssemblyLinearVelocity = self.LuaCharacter.RootPart.CFrame:VectorToWorldSpace(Vector3.new(50, 10, 40))

			task.delay(3, FadePart, Base)
		end
	end))
	
	self.Thread.Job:Task(self.Animations.Windup.Stopped:Wait())
	
	local AttackName = GetRandomPower() 
	self.Combat:CreateAttack(AttackName, Enum.KeyCode.T)
	self.LuaCharacter.Model:SetAttribute("Used_Temp_V", true)
	
	self.LuaCharacter.HumanoidJob:Task(function()
		self.Combat:RemoveAttack(AttackName)
	end)
		
	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.TryToCancelMoves = true
	
	self.SpeedDecrease = 50

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack