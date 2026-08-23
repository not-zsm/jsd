local replicatedStorage = game:GetService("ReplicatedStorage")

local DonationRemote = replicatedStorage.Remotes.RequestDonation

local Observer = require(replicatedStorage.modules.shared.Utilities.Observer)

local Connections = {}

Observer("DonationButton", function(Button : Frame & {Request : ImageButton})
	Connections[Button.Name] = Button.Request.MouseButton1Click:Connect(function()
		DonationRemote:FireServer(tonumber(Button.Name))
	end)
	
	return function()
		if Connections[Button.Name].Connected then
			Connections[Button.Name]:Disconnect()
		end
		
		Connections[Button.Name] = nil
	end
end)

return nil