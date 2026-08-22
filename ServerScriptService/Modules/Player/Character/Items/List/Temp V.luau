local ServerScriptService = game:GetService("ServerScriptService")
local BaseAttack = require( ServerScriptService.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Settings = {
	SpeedDecrease = 10
}

return {
	Template = script["Temp V"],
	Object = nil,
	
	--Equipped = function(self)
	--	print("Equipped")
	--end,
	
	--Unequipped = function(self)
	--	print("Unequipped")
	--end,
	
	Triggered = function(self)
		self:UseMove("Temp V")
	end,
}