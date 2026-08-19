local ServerScriptService = game:GetService("ServerScriptService")
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Settings = {
	SpeedDecrease = 10
}

return {
	Template = script["Railgun"],
	Object = nil,
	
	--Equipped = function(self)
	--	print("Equipped")
	--end,
	
	--Unequipped = function(self)
	--	print("Unequipped")
	--end,
	
	Triggered = function(self)
		self:UseMove("Railgun")
	end,
}