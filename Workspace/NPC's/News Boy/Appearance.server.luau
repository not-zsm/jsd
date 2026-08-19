local Players = game:GetService("Players")

local NewsDivisionIDs = {
	289049081,
	1393880146,
	1844535785,
	1641288799,
	73830428,
	2028177126,
	422034301
}

local Success, Result = pcall(Players.GetHumanoidDescriptionFromUserId, Players, NewsDivisionIDs[math.random(1, #NewsDivisionIDs)])

if Success then
	script.Parent.Humanoid:ApplyDescription(Result)
end