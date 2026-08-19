local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

----------------------------------------------------------------------------------

local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

local function Unanchor_Model(Model : Model)
	for _, Item in ipairs(Model:GetDescendants()) do
		if Item:IsA("BasePart") then
			Item.Anchored = false
		end
	end
end

local ChainedBlades = script.ChainedBlades

function Attack:CreateChainedBlades()
	if (self.CurrentlyUsing == "Chained Blades" or self.Blades ~= nil) then return end

	local Blade1 = ChainedBlades.Blade1:Clone()
	Blade1.Weld.Part0 = self.LuaCharacter.LeftArm
	Blade1.Parent = self.LuaCharacter.Model

	local Blade2 = ChainedBlades.Blade2:Clone()
	Blade2.Weld.Part0 =  self.LuaCharacter.RightArm
	Blade2.Parent = self.LuaCharacter.Model
	
	self.Blades = {
		Objects = {Blade1, Blade2},
		Animation = self.LuaCharacter.Animator:LoadAnimation(script.ChainIdle)
	}

	self.Blades.Animation.Priority = Enum.AnimationPriority.Core
	self.Blades.Animation:Play(0) 

	self:ToggleChainedBladeTrails(false)
end

function Attack:ToggleChainedBlades(Value : boolean)
	if (self.Blades ~= nil and self.Blades.Objects ~= nil) then
		if Value then
			for _, Blade in self.Blades.Objects do
				Unanchor_Model(Blade)
				Blade.Parent = self.LuaCharacter.Model
			end

			self.Blades.Animation:Play(0)
			
			self.Combat.CurrentCharacter.Stats.M1.Speed = 1.4
			self.Combat.CurrentCharacter.Stats.M1.EndlagAfterSwing = 0.12
		else
			self:ToggleChainedBladeTrails(false)
			self.Blades.Animation:Stop()

			for _, Blade in self.Blades.Objects do
				Blade.Parent = nil
			end
		end
	end
end

function Attack:ToggleChainedBladeTrails(Value : boolean)
	if (self.Blades ~= nil and self.Blades.Objects ~= nil) then
		for _, Blade in self.Blades.Objects do
			for _, Item in ipairs(Blade:GetDescendants()) do
				if Item:IsA("Trail") then
					Item.Enabled = Value
				end
			end
		end
	end
end

----------------------------------------------------------------------------------

function Attack:CreateAxe() 
	if (self.CurrentlyUsing == "Axe" or self.Axe ~= nil) then return end
	
	local Axe = script.Axe:Clone()
	Axe.Weld.Part0 =  self.LuaCharacter.RightArm
	Axe.Weld.Part1 = Axe.PrimaryPart
	Axe.Name = "LeviathanAxe"
	Axe.Parent = self.LuaCharacter.Model
	
	self.Axe = Axe
end

function Attack:ToggleAxe(Value : boolean)
	if (self.Axe ~= nil) then
		self:ToggleIceAxe(false)
		self.Holstering:OnAxe(Value)

		if Value then
			self.Combat.CurrentCharacter.Stats.M1.Speed = 1.625
			self.Combat.CurrentCharacter.Stats.M1.EndlagAfterSwing = 0.08
		end
	end
end

function Attack:ToggleIceAxe(Value : boolean)
	if (self.Axe == nil) then return end

	self.Axe.Ice.Transparency = (Value and 0.5 or 1)

	for _, Item in ipairs(self.Axe.Ice:GetDescendants()) do
		if Item:IsA("ParticleEmitter") or Item:IsA("PointLight") or Item:IsA("Trail") then
			Item.Enabled = Value

		elseif Item:IsA("Decal") then 
			Item.Transparency = (Value and 0 or 1)
		end
	end
end

function Attack:ThrowAxe(Value : boolean) 
	if Value ~= self.ThrownAxe then
		self.ThrownAxe = Value
		self.OnAxeChanged:Fire(Value)
	end
end

----------------------------------------------------------------------------------

function Attack:CreateSpear()
	if (self.CurrentlyUsing == "Spear" or self.Spear ~= nil) then return end

	local Spear = script.Spear:Clone()
	Spear.Weld.Part0 =  self.LuaCharacter.RightArm
	Spear.Parent = self.LuaCharacter.Model

	self.Spear = Spear
end

function Attack:ToggleSpear(Value : boolean)
	if (self.Spear ~= nil) then
		self.Spear.Parent = (Value and self.LuaCharacter.Model or nil)
	end
end

----------------------------------------------------------------------------------

function Attack:HideAll()
	self:ToggleAxe(false)
	self:ToggleChainedBlades(false)
	self:ToggleSpear(false)
	
	self:ChangeCurrentlyUsing("Fists")
	self.Combat.CurrentCharacter.Stats.M1.Speed = 1.2
	self.Combat.CurrentCharacter.Stats.M1.EndlagAfterSwing = 0.135
end

function Attack:DestroyAll()
	if self.Axe then
		self.Axe:Destroy()
		self.Axe = nil
	end
	
	if self.Spear then
		self.Spear:Destroy()
		self.Spear = nil
	end

	if self.Blades then
		for _, Blade in self.Blades.Objects do
			Blade:Destroy()
		end

		self.Blades = nil
	end
end

----------------------------------------------------------------------------------

function Attack:BringBackPreviouslyUsing()
	self:SetCurrent(self.PreviouslyUsing)
end

function Attack:ChangeCurrentlyUsing(Weapon : string)
	self.PreviouslyUsing = self.CurrentlyUsing
	self.CurrentlyUsing = Weapon
end

----------------------------------------------------------------------------------

function Attack:SetCurrent(Weapon : string)
	if Weapon == "Fists" then
		return self:HideAll()
	end
	
	if Weapon == "Axe" then
		self:ToggleChainedBlades(false)
		self:ToggleSpear(false)
		
		self:CreateAxe()
		
	elseif Weapon == "Spear" then 
		self:ToggleAxe(false)
		self:ToggleChainedBlades(false)

		self:CreateSpear()
		
	elseif Weapon == "Chained Blades" then
		self:ToggleAxe(false)
		self:ToggleSpear(false)
		
		self:CreateChainedBlades()
	end
	
	self:ChangeCurrentlyUsing(Weapon)
	
	if Weapon == "Axe" then
		self:ToggleAxe(true)
		
	elseif Weapon == "Spear" then
		self:ToggleSpear(true)
		
	elseif Weapon == "Chained Blades" then
		self:ToggleChainedBlades(true)
	end
	
	-- this function so mid 😭
	-- If it works, it works.
end

----------------------------------------------------------------------------------
	
function Attack.new(...) 
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.Available = false
	self.CoreCharacter = true;
	
	self.PreviouslyUsing = "Fists"
	self.CurrentlyUsing = "Fists"
	
	self.ThrownAxe = false
	self.OnAxeChanged = self.Job:Task(EventService.new())
	
	self.Holstering = require(script.Holstering).new(self)

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack