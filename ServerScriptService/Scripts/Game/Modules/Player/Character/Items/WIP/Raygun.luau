local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Settings = {
	SpeedDecrease = 10
}

return {
	Template = if math.random(1, 10) == 1 then script["Raygun2"] else script["Raygun"],
	
	Object = nil,
	SpawnOffset = CFrame.Angles(0, math.rad(90), 0),
	-- MovementAnimations = true,
	Name = "Raygun",
	
	OnCooldown = false,
	
	Equipped = function(self)
		print("Equipped")
	end,
	
	--Unequipped = function(self)
	--	print("Unequipped")
	--end,
	
	Triggered = function(self)
		self:UseMove("Raygun")
	end,
}