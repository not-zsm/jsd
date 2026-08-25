local normColour = Color3.fromRGB(255, 115, 15)
local axeColour = Color3.fromRGB(166, 212, 241)

return {
	Axe = {
		[1] = { Limb = "Right Arm", Colour = axeColour, Duration = 0.35 },
		[2] = { Limb = "Right Arm", Colour = axeColour, Duration = 0.35 },
		[3] = { Limb = { "Left Arm", "Right Arm" }, Colour = axeColour, Duration = 0.35 },
		[4] = { Limb = { "Left Arm", "Right Arm" }, Colour = axeColour, Duration = 0.4 },

		Up = { Limb = "Right Arm", Colour = normColour, Duration = 0.4 },
		Down = { Limb = "Right Leg", Colour = normColour, Duration = 0.4 },
	},
	
	Fists = {
		[1] = { Limb = "Right Arm", Colour = normColour, Duration = 0.35 },
		[2] = { Limb = "Left Arm", Colour = normColour, Duration = 0.35 },
		[3] = { Limb = "Right Arm", Colour = normColour, Duration = 0.35 },
		[4] = { Limb = "Left Arm", Colour = normColour, Duration = 0.4 },

		Up = { Limb = "Right Arm", Colour = normColour, Duration = 0.4 },
		Down = { Limb = "Right Leg", Colour = normColour, Duration = 0.4 },
	},
	
	["Chained Blades"] = {
		[1] = { Limb = { "Left Arm", "Right Arm" }, Colour = normColour, Duration = 0.35 },
		[2] = { Limb = { "Left Arm", "Right Arm" }, Colour = normColour, Duration = 0.35 },
		[3] = { Limb = { "Left Arm", "Right Arm" }, Colour = normColour, Duration = 0.35 },
		[4] = { Limb = { "Left Arm", "Right Arm" }, Colour = normColour, Duration = 0.4 },

		Up = { Limb = "Right Arm", Colour = normColour, Duration = 0.4 },
		Down = { Limb = "Right Leg", Colour = normColour, Duration = 0.4 },
	},
}
