local Players = game:GetService("Players")

local Success, Result = pcall(Players.GetHumanoidDescriptionFromUserId, Players, 341579096)

if Success then
	script.Parent.Humanoid:ApplyDescription(Result)
end