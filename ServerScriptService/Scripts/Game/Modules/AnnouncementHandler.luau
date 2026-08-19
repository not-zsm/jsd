local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local AnnouncementHandler = {}

function AnnouncementHandler.Send(Message : {Data : string})
	for _, Player in ipairs(Players:GetPlayers()) do
		local Success, Result = pcall(TextService.FilterStringAsync, TextService, Message.Data or Message, Player.UserId)

		if Success then
			ReplicatedStorage.Remotes.Announcement:FireClient(Player, Result:GetNonChatStringForBroadcastAsync())
		end
	end
end

task.spawn(function()
	MessagingService:SubscribeAsync("Announcement", function(Message : {Data : string})
		AnnouncementHandler.Send(Message, "Global Announcement")
	end)
end)

return AnnouncementHandler
