--!strict
-- Was StarterPlayerScripts/Game/Wind.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WindShake = require(ReplicatedStorage.Shared.Utilities.WindShake)

return {
	Name = "Wind",
	Priority = 40,

	Start = function(_self, Client, Cleanup)
		local Player = Client.Player

		WindShake:Init({ MatchWorkspaceWind = true })

		local function Apply()
			if Player:GetAttribute("Foliage_Wind") then
				WindShake:Resume()
			else
				WindShake:Pause()
			end
		end

		Apply()

		Cleanup:Task(Player:GetAttributeChangedSignal("Foliage_Wind"):Connect(Apply))
	end,
}
