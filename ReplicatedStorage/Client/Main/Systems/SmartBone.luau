--!strict
-- Was StarterPlayerScripts/Game/SmartBone.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SmartBone = require(ReplicatedStorage.Shared.Game.SmartBone)

return {
	Name = "SmartBone",
	Priority = 40,

	Start = function()
		SmartBone.Start()
	end,
}
