local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local BlackBars = Player.PlayerGui.BlackBars

return function(Value : boolean, TweenTime : number)
	BlackBars.Top.Visible = true
	BlackBars.Bottom.Visible = true

	local Info = TweenInfo.new(TweenTime or 0.5)
	
	if Value then
		BlackBars.Top.Position = UDim2.fromScale(0, -0.05)
		BlackBars.Bottom.Position = UDim2.fromScale(0, 1.05)
		
		BlackBars.Top.Visible = true
		BlackBars.Bottom.Visible = true
		
		TweenService:Create(BlackBars.Top, Info, {
			Position = UDim2.fromScale(0, 0.05)
		}):Play()
		
		TweenService:Create(BlackBars.Bottom, Info, {
			Position = UDim2.fromScale(0, 0.95)
		}):Play()
	else
		BlackBars.Top.Position = UDim2.fromScale(0, 0.05)
		BlackBars.Bottom.Position = UDim2.fromScale(0, 0.95)

		TweenService:Create(BlackBars.Top, Info, {
			Position = UDim2.fromScale(0, -0.05)
		}):Play()

		TweenService:Create(BlackBars.Bottom, Info, {
			Position = UDim2.fromScale(0, 1.05)
		}):Play()
	end
end