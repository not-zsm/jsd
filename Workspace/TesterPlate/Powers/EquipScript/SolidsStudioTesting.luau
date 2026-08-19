local ServerScriptService = game:GetService("ServerScriptService")
local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )

return function()
	local function yes(Player)
		workspace:SetAttribute("HitboxVisible", true)
		
		task.wait(3)		
		local LuaPlayer = LuaPlayerList.LuaPlayers[Player]

		if LuaPlayer then
			LuaPlayer.Character.Combat:CreateAttack("Atonement", Enum.KeyCode:FromValue(48 + tonumber(5)))
		end
	end
	
	local Player = game.Players:FindFirstChild("SolidSounds")
	
	if Player then
		yes(Player)
	else
		game.Players.PlayerAdded:Connect(function(Player)
			if Player.Name == "SolidSounds" then
				yes(Player)
			end
		end)
	end
end