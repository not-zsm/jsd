local TeleportService = game:GetService("TeleportService")
local VoiceChatService = game:GetService("VoiceChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VCServerTeleporter = {}

ReplicatedStorage.Remotes.JoinVCServer.OnServerEvent:Connect(function(Player)
	if shared.IsVCPlace then return end

	local Success, Result = pcall(function()
		return VoiceChatService:IsVoiceEnabledForUserIdAsync(Player.UserId)
	end)
	
	if not Success then
		warn(Result)
	end
	
	if Result then
		local PlaceId 
		if shared.IsTestPlace then
			PlaceId = shared.PlaceIds.TestVC
		else
			PlaceId = shared.PlaceIds.MainVC
		end

		TeleportService:Teleport(PlaceId, Player)
	end
end)

return VCServerTeleporter
