if shared.IsRankedLobby then
	local TeleportService = game:GetService("TeleportService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local RankedTeleporter = {}

	ReplicatedStorage.Remotes.JoinMainPlace.OnServerEvent:Connect(function(Player)
		print("teleporting back")
		
		TeleportService:Teleport(95576587700882, Player)
	end)

	return RankedTeleporter
else
	return {}
end