-- Display data for the character picker and hotbar. The server merges this with
-- what each character module declares and sends the result to the client, so a
-- character appears in the picker by being here plus having a module.
return {
	chara = {
		displayName = 'Chara',
		icon = '85316557846229',

		ultName = 'SINCE WHEN WERE YOU THE ONE IN CONTROL?',

		colour = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(181, 53, 53)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(109, 32, 32)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(181, 53, 53)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))
		}),

		dontHeal = true,
		deathUlt = true,
		manuallyFireStartRemote = true,

		moveset = {
			{ name = 'Onslaught',   key = Enum.KeyCode.One },
			{ name = 'Lethal Wound', key = Enum.KeyCode.Two },
			{ name = 'Bloody Mary', key = Enum.KeyCode.Three },
			{ name = 'Fight',       key = Enum.KeyCode.Four },
		},

		ultMoveset = {
			{ name = 'Cursed Remedy', key = Enum.KeyCode.One },
			{ name = 'Reset',         key = Enum.KeyCode.Two },
			{ name = 'Atonement',     key = Enum.KeyCode.Three },
			{ name = 'Seven Souls',   key = Enum.KeyCode.Four },
			{ name = 'Special Hell',  key = Enum.KeyCode.Five },
		},
	},

	invincible = {
		displayName = 'Invincible',
		icon = '101089066666765',

		devOnly = true,

		ultName = 'This is Over! (UNFINISHED)',

		colour = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 229, 86)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(0, 188, 240)),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(0, 188, 240)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 229, 86)),
		}),

		oneTimePop = true,

		moveset = {
			{ name = 'Fraction of Power', key = Enum.KeyCode.One },
			{ name = 'Holding Back',      key = Enum.KeyCode.Two,   label = 'Hold' },
			{ name = 'Visceral Drive',    key = Enum.KeyCode.Three },
			{ name = 'Death Leap',        key = Enum.KeyCode.Four },
		},
	},
	kratos = {
		displayName = 'Kratos',

		ultName = 'The Rage of War',

		colour = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 115, 15)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 124, 64)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 115, 15)),
		}),

		moveset = {
			{ name = 'Chaos Barrage',  key = Enum.KeyCode.One },
			{ name = 'Leviathan Rush', key = Enum.KeyCode.Two },
			{ name = 'Leviathan Throw', key = Enum.KeyCode.Three },
			{ name = 'Draupnir Spin',  key = Enum.KeyCode.Four },
		},

		ultMoveset = {
			{ name = 'Spartan Rage',       key = Enum.KeyCode.One },
			{ name = "Nature's Arsenal",   key = Enum.KeyCode.Two },
			{ name = 'Rageful Tackle',     key = Enum.KeyCode.Three },
			{ name = 'Father Son Bonding', key = Enum.KeyCode.Four },
		},
	},
}
