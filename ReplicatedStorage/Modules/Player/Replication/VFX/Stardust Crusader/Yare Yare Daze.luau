local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TekrinnDialogue = require( ReplicatedStorage.Modules.TekrinnDialogue )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

return {
	Start = function(Model : Model)
		local Head = Model:FindFirstChild("Head")
		if (Head == nil) then return end
		
		EffectUtility.AddSFX(script.SFX, Head)
		
		if EffectUtility.Distance_Close(Model, 150) then
			TekrinnDialogue.Speak(Model, 

				{
					Text = "Yare Yare Daze.",
					TextStrokeColor = Color3.new(0, 0, 0),
					Color = ColorSequence.new(Color3.fromRGB(92, 0, 172)),
					Shake = {
						Lifetime = 0.5,
						Enabled = true,
						Intensity = 1.5,
					},
					HigherUp = true,
					TypeSpeed = 0.075,
				}, 

				{
					StrokeColor = Color3.new(0, 0, 0),
					Color = ColorSequence.new(Color3.fromRGB(92, 0, 172)),
				}, 

				1.6
			)
		end
	end,
}