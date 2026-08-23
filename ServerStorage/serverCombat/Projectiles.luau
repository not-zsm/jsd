

local UserInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------


local Job = require( replicatedStorage.modules.shared.Utilities.Job )

local Projectile = require( script.Projectile )

----------------------------------------------------------------------------------

local Projectiles = {}
Projectiles.__index = Projectiles	

function Projectiles:Destroy()
	for Projectile in self.ActiveProjectiles do
		Projectile:Destroy()
	end
	
	self.Job:Destroy()
end

function Projectiles:_Init()
	self.Job:Task(RunService.PostSimulation:Connect(function(Delta)
		for Projectile in self.ActiveProjectiles do
			Projectile:Update(Delta)
		end
	end))
end

function Projectiles:Create(...)
	return Projectile.new(self, ...)
end

function Projectiles.new(Combat)
	local self = setmetatable({}, Projectiles)

	self.Combat = Combat
	self.LuaCharacter = Combat.LuaCharacter
	self.LuaPlayer = Combat.LuaPlayer

	self.ActiveProjectiles = {}
	self.Job = Job.new()

	self:_Init()

	return self
end

table.freeze(Projectiles)

return Projectiles