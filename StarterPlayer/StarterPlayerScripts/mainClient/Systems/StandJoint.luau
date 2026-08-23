--!strict
-- Was StarterPlayerScripts/Game/MiscellaneousPackages.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
	Name = "StandJoint",
	Priority = 40,

	Start = function()
		require(ReplicatedStorage.modules.client.standJoint)
	end,
}
