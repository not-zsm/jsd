
local LeaderboardModule = require(script.LeaderboardModule)
local LeaderboardsFolder = workspace:WaitForChild("Leaderboards")

local Leaderboards = {}
local Handler = {}

function Handler.CreateLeaderboard(Type : string, Object, UpdateInterval : number)
	if Leaderboards and Leaderboards[Type] == nil then
		local Leaderboard = LeaderboardModule.new({
			datastoreKey = Type .. "-Leaderboard",
			leaderboardIconParent = Object.LeaderboardGui.Holder.Templates,
			format = "Abbreviate",
			lines = 50,
			descendingOrder = false,
			displayNamesEnabled = true,
			thumbnailsEnabled = true,
			frontPrefix = "",
			backPrefix = " " .. Type
		})

		Leaderboards[Type] = Leaderboard

		Leaderboard:AutoUpdate(UpdateInterval or 300)
		Leaderboard:AttachRefreshTimer(Object.LeaderboardGui.Timer)
		
		Object.LeaderboardGui.Timer:SetAttribute("Prefix", "Leaderboard")
	end
end

function Handler.UpdateLeaderboard(Player : Player, LeaderboardType : string, NewValue)
	local Success, Error = pcall(function()
		Leaderboards[LeaderboardType]:Append(Player.UserId, NewValue)
	end)

	if not Success then
		warn("Error updating ".. LeaderboardType .." leaderboard for ".. Player.Name..": ".. Error)
	end
end

for _, LeaderboardObject in pairs(LeaderboardsFolder:GetChildren()) do
	if LeaderboardObject:GetAttribute("Type") then
		local LeaderboardType = LeaderboardObject:GetAttribute("Type")
		Handler.CreateLeaderboard(LeaderboardType, LeaderboardObject)
	end
end

table.freeze(Handler)

return Handler
