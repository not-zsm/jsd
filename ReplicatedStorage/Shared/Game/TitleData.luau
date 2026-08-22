local TitleSystem = {}

TitleSystem.KillTitles = {
	["STREET LEVEL"] = {requirement = 500, color = Color3.fromRGB(255, 255, 255), chatPrefix = false},
	["CITY LEVEL"] = {requirement = 1000, color = Color3.fromRGB(255, 255, 255), chatPrefix = false},
	["CONTINENTAL LEVEL"] = {requirement = 5000, color = Color3.fromRGB(255, 255, 255), chatPrefix = false},
	["PLANETARY LEVEL"] = {requirement = 10000, color = Color3.fromRGB(255, 0, 4), chatPrefix = false},
	["GALAXY LEVEL"] = {requirement = 25000, color = Color3.fromRGB(183, 0, 255), chatPrefix = false, font = {StrokeColor = Color3.fromRGB(0, 255, 149)}},
	["UNIVERSAL LEVEL"] = {requirement = 50000, color = Color3.fromRGB(0, 0, 0), chatPrefix = false, font = {StrokeColor = Color3.fromRGB(0, 255, 149)}}
}

TitleSystem.GroupTitles = {
	["CONTENT CREATOR"] = {requirement = 58, color = Color3.fromRGB(255, 0, 0), chatPrefix = true},
	["TESTER"] = {requirement = 61, color = Color3.fromRGB(39, 123, 201), chatPrefix = true},
	["CONTRIBUTOR"] = {requirement = 62, color = Color3.fromRGB(21, 21, 21), chatPrefix = true},
	["DEVELOPER"] = {requirement = {71, 200, 226}, color = Color3.fromRGB(231, 76, 60), chatPrefix = true},
	
	["MODERATOR"] = {
		requirement = 59, color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(241, 104, 104)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}), chatPrefix = true, gradient = {}
	},
	
	["SENIOR MODERATOR"] = {
		requirement = 60, color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 126, 126)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 201, 201)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 126, 126)),
		}), chatPrefix = true, gradient = {}
	},
	
	["ADMINISTRATOR"] = {
		requirement = 64, color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 202, 67)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 122, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 202, 67)),
		}), chatPrefix = true, gradient = {}
	},
	
	["HEAD ADMINISTRATOR"] = {
		requirement = 190, color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(102, 50, 245)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(45, 4, 194)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(102, 50, 245)),
		}), chatPrefix = true, gradient = {}
	},
	
	["FOUNDER"] = {requirement = 226, color = Color3.fromRGB(255, 85, 85), chatPrefix = true},
	
	["MANAGER"] = {requirement = {201, 199}, chatPrefix = true, font = {FontFace = 12187368843, FontWeight = Enum.FontWeight.Heavy, StrokeColor = Color3.fromRGB(255, 255, 255), StrokeSize = 3}, --FontFace = Enum.Font.Fantasy, FontWeight = Enum.FontWeight.Heavy
		color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(171, 176, 176)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
		}), gradient = {}
	},
	
	["OWNER"] = {requirement = 255, color = Color3.fromRGB(255, 115, 236), chatPrefix = true},
}

TitleSystem.DonatorTitles = {-- jimpee was not cooking with this
	["RICH BOY"] = {requirement = 1_000, color = Color3.fromRGB(255, 255, 255), chatPrefix = false},
	["MILLIONAIRE"] = {requirement = 10_000, color = Color3.fromRGB(255, 255, 255), chatPrefix = false},
	["VIP"] = {requirement = 100_000, color = Color3.fromRGB(255, 255, 255), chatPrefix = false},
	["BOARD OF DIRECTOR"] = {requirement = 1_000_000, color = Color3.fromRGB(255, 255, 255), chatPrefix = false},
}

TitleSystem.CustomTitles = {
	------------------------------------------------------------------------------
	
	["MASTER BUILDER"] = {
		--       #1: Nether11MilesAway, thekitty_kingdogs, endergame_segunda #2: 0ppperq, Woonzly #3: Creepy_4411 
		accessIds = {384289084, 129230243, 3774891419}, 
		color = Color3.fromRGB(255, 179, 0)
	},
	
	["ART COMPETITION WINNER"] = {access = {"Eryth_Zelenii", "TroubleBread"}, color = Color3.fromRGB(255, 213, 0)},

	["BUGO 🤩"] = {access = {"GamingAllTheWomen"}, color = Color3.fromRGB(97, 166, 61)},
	["FAKE BUGO 😈"] = {access = {"GamingAIITheWomen"}, color = Color3.fromRGB(0, 0, 0)},

	["BILLY 🤣"] = {access = {"Aenoir"}, color = Color3.fromRGB(40, 40, 40), gradient = true, chatPrefix = false},

	["REAL MYMY32100"] = {access = {"mymy32100"}, color = Color3.fromRGB(255, 202, 44)},

	["yellow man"] = {access = {"Thera72v3"}, color = Color3.fromRGB(255, 247, 10)},
	
	["YEEYEEJUICEMAN"] = {access = {"sk3tchyt"}, color = Color3.fromRGB(255, 200, 0)},
	
	["ccum man"] = {access = {"CarefulsmilePC", "Bigman47620"}, color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(178, 218, 255)),
		ColorSequenceKeypoint.new(0.3333333333333333, Color3.fromRGB(224, 241, 255)),
		ColorSequenceKeypoint.new(0.6666666666666666, Color3.fromRGB(224, 241, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(178, 218, 255)),
	}), gradient = {offsetTime = 2}, chatPrefix = true},

	["SOLID"] = {access = {"SolidSounds"}, chatPrefix = true, font = {FontFace = 12187368843, FontWeight = Enum.FontWeight.Heavy, StrokeColor = Color3.fromRGB(255, 255, 255), StrokeSize = 3}, --FontFace = Enum.Font.Fantasy, FontWeight = Enum.FontWeight.Heavy
		color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(171, 176, 176)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
		}), gradient = {}
	},
	
	["News Boy"] = {
		accessIds = {289049081, 1393880146, 1844535785, 1641288799, 73830428, 2028177126, 422034301, 429888448}, -- all the news division members
		color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 157)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(223, 255, 242)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 157)),
		}),
		font = {FontFace = 12187607722, FontWeight = Enum.FontWeight.Heavy, StrokeColor = Color3.fromRGB(255, 255, 255), StrokeSize = 3},
		chatPrefix = true
	},
	
	------------------------------------------------------------------------------

	["HEAD OF STAFF"] = {
		access = {"ash_zno", "SinguAppleman"}, color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 213)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(9, 119, 101)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 213)),
		}), gradient = {}, chatPrefix = true
	},
	
	["LEAD SCRIPTER"] = {access = {"swrerm"}, color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(157, 170, 255)),
		ColorSequenceKeypoint.new(0.3333333333333333, Color3.fromRGB(0, 26, 255)),
		ColorSequenceKeypoint.new(0.6666666666666666, Color3.fromRGB(0, 26, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(157, 170, 255)),
	}), gradient = {offsetTime = 2}, chatPrefix = true},
	
	["FOUNDER / LEAD PROGRAMMER"] = {access = {"swrerm"}, color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(121, 115, 186)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(49, 136, 190)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(121, 115, 186)),
	}), 
		font = {FontFace = 12187360881, FontWeight = Enum.FontWeight.Medium, StrokeColor = Color3.fromRGB(0, 1, 13), StrokeSize = 1}, 
		gradient = {offsetTime = 2}, 
		chatPrefix = true
	},
	
	["An elephant 🐘 never forgets."] = {access = {"swrerm"}, color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(63, 78, 89)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(170, 182, 190)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(63, 78, 89)),
	}), 
		font = {FontFace = 12187365977, FontWeight = Enum.FontWeight.Medium, StrokeColor = Color3.fromRGB(0, 0, 0), StrokeSize = 1}, 
		chatPrefix = true
	},
	
	["LEAD DEVELOPER"] = {access = {"swrerm"}, color = Color3.fromRGB(0, 73, 231), chatPrefix = true},
	["SCRIPTER"] = {access = {"swrerm", "erykos05"}, color = Color3.fromRGB(0, 63, 255), chatPrefix = true},

	------------------------------------------------------------------------------

	["BUILDER"] = {accessIds = {462646322}, color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.3333333333333333, Color3.fromRGB(255, 139, 119)),
		ColorSequenceKeypoint.new(0.6666666666666666, Color3.fromRGB(255, 139, 119)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
	}), gradient = {offsetTime = 2}, chatPrefix = true},	

	["LEAD VFX DESIGNER"] = {access = {"Arc_Devs"}, color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 187, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(207, 50, 157)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 187, 255)),
	}), gradient = {offsetTime = 1.5}, chatPrefix = true},

	["LEAD ANIMATOR"] = {access = {"precisionOfPlayer", "Binx_zz", "SolidSounds"}, color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 119, 1)),
		ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(39, 86, 135)),
		ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 119, 1)),
	}), gradient = {offsetTime = 1.5}, font = {FontFace = Enum.Font.PermanentMarker}, chatPrefix = true},
	
	["ANIMATOR"] = {accessIds = {143901924, 119987926, 242509995, 1074272775, 550251603, 1242679803}, color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 78, 34)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 170, 0)),
	}), gradient = {offsetTime = 1.5}, chatPrefix = true},
	
	["LEAD SFX DESIGNER"] = {accessIds = {166263406}, color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(107, 78, 165)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(96, 122, 172)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(107, 78, 165)),
	}), gradient = {offsetTime = 1.25}, chatPrefix = true},
	
	["SFX DESIGNER"] = {accessIds = {699372072, 2912663972}, color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(177, 171, 229)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(184, 204, 229)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(177, 171, 229)),
	}), gradient = {offsetTime = 2}, chatPrefix = true},
	
	["JIMPEE"] = {access = {"Jimpeewastaken"}, color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(225, 0, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(102, 0, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 0, 255)),
	}), gradient = {offsetTime = 1.5}, chatPrefix = true},
}

TitleSystem.DefaultSettings = {
	font = {
		FontFace = Enum.Font.Antique,
		FontWeight = Enum.FontWeight.Bold,
		StrokeColor = Color3.fromRGB(0, 0, 0),
		StrokeSize = 3
	}
}

return TitleSystem