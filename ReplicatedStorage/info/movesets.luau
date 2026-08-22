return {
	chara = { --EXAMPLE ONLY, variables in camelCase. Would preferably have tooltips also defined here. e.g. {'Onslaught', 'Air'} = Enum.KeyCode.One, or we js sort by order
		ultName = 'SINCE WHEN WERE YOU THE ONE IN CONTROL?',
		
		colour = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(181, 53, 53)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(109, 32, 32)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(181, 53, 53)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))
		}),

		--song = nil,
		dontHeal = true,
		deathUlt = true,
		manuallyFireStartRemote = true,

		moveset = {
			["Onslaught"] = Enum.KeyCode.One, 
			["Lethal Wound"] = Enum.KeyCode.Two,
			["Bloody Mary"] = Enum.KeyCode.Three,
			["Fight"] = Enum.KeyCode.Four,
		},

		ultMoveset = {
			["Cursed Remedy"] = Enum.KeyCode.One,
			["Reset"] = Enum.KeyCode.Two,
			["Atonement"] = Enum.KeyCode.Three,
			["Seven Souls"] = Enum.KeyCode.Four,
			["Special Hell"] = Enum.KeyCode.Five,
		}
	},
}