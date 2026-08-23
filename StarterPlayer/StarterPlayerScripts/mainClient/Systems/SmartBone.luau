--!strict
-- Was StarterPlayerScripts/Game/SmartBone.client.luau
local replicatedStorage = game:GetService("ReplicatedStorage")

local SmartBone = require(replicatedStorage.modules.shared.Game.SmartBone)

return {
	Name = "SmartBone",
	Priority = 40,

	Start = function()
		SmartBone.Start()
	end,
}
