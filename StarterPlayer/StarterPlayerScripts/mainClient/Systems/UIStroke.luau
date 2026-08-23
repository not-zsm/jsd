--!strict
-- Was StarterPlayerScripts/Game/ScaleStroke.client.luau
local replicatedStorage = game:GetService("ReplicatedStorage")

local UIStrokeAdjuster = require(replicatedStorage.modules.shared.Utilities.UIStrokeAdjuster)

--- ScreenGuis whose strokes scale with resolution.
local TAGGED = { "Gifting", "Settings", "Information" }

return {
	Name = "UIStroke",
	Priority = 60,

	Start = function(_self, Client)
		for _, Name in TAGGED do
			local Gui = Client.PlayerGui:WaitForChild(Name, 100)

			if Gui then
				UIStrokeAdjuster:TagScreenGui(Gui)
			else
				warn(`[UIStroke] {Name} never appeared in PlayerGui`)
			end
		end
	end,
}
