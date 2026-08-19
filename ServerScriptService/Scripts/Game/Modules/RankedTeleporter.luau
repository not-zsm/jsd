if shared.IsTestPlace then
	local TeleportService = game:GetService("TeleportService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local RankedTeleporter = {}

	ReplicatedStorage.Remotes.JoinRankedLobby.OnServerEvent:Connect(function(Player)
		TeleportService:Teleport(122394296123463, Player)
	end)

	return RankedTeleporter
else
	return {}
end