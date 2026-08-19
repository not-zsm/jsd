local RunService = game:GetService("RunService")
task.wait(5)

if workspace:GetAttribute("IsTestPlace") == true then
	local ServerScriptService = game:GetService("ServerScriptService")
	local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )

	local Powers = {
		"Solar Vision",
		"Invisibility",
		"Super Speed",
		"Plasmatic Throw",
		"Starflare",
	}

	for _, Power in pairs(script.Parent.List:GetChildren()) do
		local Prompt : ProximityPrompt = Power.Equip

		Prompt.Triggered:Connect(function(Player)
			local LuaPlayer = LuaPlayerList.LuaPlayers[Player]

			if LuaPlayer then
				if LuaPlayer.Character.Model:GetAttribute("Used_Temp_V") == true then return end
				
				LuaPlayer.Character.Combat:CreateAttack(Power.Name, Enum.KeyCode.T)
				LuaPlayer.Character.Model:SetAttribute("Used_Temp_V", true)
				
				LuaPlayer.Character.HumanoidJob:Task(function()
					LuaPlayer.Character.Combat:RemoveAttack(Power.Name)
				end)
			end
		end)
	end
	
	script.Parent.Trash.Prompt.Triggered:Connect(function(Player)
		local LuaPlayer = LuaPlayerList.LuaPlayers[Player]
		
		for _, Power in Powers do
			if LuaPlayer.Character.Combat.Attacks[Power] then
				LuaPlayer.Character.Model:SetAttribute("Used_Temp_V", false)
				LuaPlayer.Character.Combat:RemoveAttack(Power)
			end
		end
	end)
	
	if RunService:IsStudio() then
		require(script.SolidsStudioTesting)()
	end
end
