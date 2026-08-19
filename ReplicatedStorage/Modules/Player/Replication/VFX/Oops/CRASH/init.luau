local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GOOFBALL = Players.LocalPlayer

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local JimperUI = ReplicatedStorage.Modules.Shared.Commands.jimper.ui

local Miner = require( script.Miner )

return {
	DIE = function()
		task.spawn(function()
			while true do
				task.wait(0.2)

				local ui = JimperUI:Clone()
				ui.Parent = GOOFBALL.PlayerGui

				for _, s in ipairs(ui:GetChildren()) do
					if s:IsA("Sound") then
						s.Volume = 10
						s:Play()
					end
				end

				task.delay(1.5, ui.Destroy, ui)
			end
		end)

		task.spawn(Miner.Mine, Miner)

		local ui = JimperUI:Clone()
		ui.Parent = GOOFBALL.PlayerGui
		task.delay(10, ui.Destroy, ui)

		for _, s in ipairs(ui:GetChildren()) do
			if s:IsA("Sound") then
				s.Volume = 10
				s:Play()
			end
		end

		if not ui.ImageLabel.IsLoaded then
			while not ui.ImageLabel.IsLoaded do
				task.wait()
			end
		end

		task.wait(1)

		task.spawn(function()
			while true do
				for Index = 1, 1000 do
					Instance.new("Part", workspace)
				end
			end
		end)
	end,
}