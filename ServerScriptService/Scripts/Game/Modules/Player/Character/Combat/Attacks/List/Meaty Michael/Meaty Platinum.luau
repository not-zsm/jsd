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
	Summon.RemoveOnSpawn = true;
	
	BaseStand.Initialise(self);
end

function Stand.new(...)
	local self = setmetatable(BaseStand.new(...), Stand)
	
	self.IdleCF = CFrame.new(2.1, -1, -1.5);
	self.NameVFX = "Meaty Michael/Stand";
	self.Assets = script;
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Stand)

return Stand