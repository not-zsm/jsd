local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local BaseStand = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseStand )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Preloading = require( ReplicatedStorage.Modules.Preloading )

local Stand = setmetatable({}, BaseStand)
Stand.__index = Stand

----------------------------------------------------------------------------------

function Stand:Initialise()
	local Summon = self.Combat:CreateAttack("Stand Summon", Enum.KeyCode.Z);
	Summon.UnsummonCooldown = 0.1
	Summon.SummonCooldown = 0.1
	
	Summon.DontBuffer = true
	
	Summon.RemoveOnSpawn = true;
	
	BaseStand.Initialise(self);
end

function Stand.new(...)
	local self = setmetatable(BaseStand.new(...), Stand)
	
	self.IdleCF = CFrame.new(-1.5, -1, -1.5);
	self.NameVFX = "Stardust Crusader/Stand";
	self.Assets = script;
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Stand)

return Stand