--- ClickToStrike, was a LocalScript nested under Weather. Body unchanged.
return {
	Name = "ClickToStrike",
	Priority = 100,
	Async = true,

	Start = function()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local UserInputService = game:GetService("UserInputService")
		local Players = game:GetService("Players")
		local Player = Players.LocalPlayer
		local Character = Player.Character or Player.CharacterAdded:Wait()
		local Mouse = Player:GetMouse()

		Player:GetAttributeChangedSignal("ClickStrike"):Once(function()
			Mouse.Button1Down:Connect(function()
				if Player:GetAttribute("ClickStrike") == true then
					ReplicatedStorage.Remotes.Commands.ClickStrike:FireServer(Mouse.Hit.Position)
				end
			end)
		end)
	end,
}
