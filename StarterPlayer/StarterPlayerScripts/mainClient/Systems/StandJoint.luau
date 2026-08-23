--!strict
-- Was StarterPlayerScripts/Game/MiscellaneousPackages.client.luau
local replicatedStorage = game:GetService("ReplicatedStorage")

return {
	Name = "StandJoint",
	Priority = 40,

	Start = function()
		require(replicatedStorage.modules.client.standJoint)
	end,
}
