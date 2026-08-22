local Players = game:GetService("Players")
local info = require(game.ReplicatedStorage.info)

local rand = math.random(1, 24) / 6

local Success, Result = pcall(Players.GetHumanoidDescriptionFromUserId, Players, info.theBigFour[math.round(rand)])

if Success then
	script.Parent.Humanoid:ApplyDescription(Result)
end