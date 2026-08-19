local Players = game:GetService("Players")

local Success, Result = pcall(Players.GetHumanoidDescriptionFromUserId, Players, 1203375699)

if Success then
	script.Parent.Humanoid:ApplyDescription(Result)
end