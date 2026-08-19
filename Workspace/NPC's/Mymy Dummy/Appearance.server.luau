local Players = game:GetService("Players")

local Success, Result = pcall(Players.GetHumanoidDescriptionFromUserId, Players, 465427335)

if Success then
	script.Parent.Humanoid:ApplyDescription(Result)
end