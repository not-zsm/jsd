local runService = game:GetService('RunService')

local placeIds = {
	main = 18519254033,
	mainVC = 131330652857284,
	test = 95576587700882,
	testVC = 82685679507656,
}

return {
	-- Renaming this orphans every existing player profile.
	DATASTORE = 'test',

	groupID = 14636287,
	gameID = nil,
	placeID = nil,

	placeIds = placeIds,

	isStudio = runService:IsStudio(),
	isTestPlace = (game.PlaceId == placeIds.test or game.PlaceId == placeIds.testVC),
	isVCPlace = (game.PlaceId == placeIds.testVC or game.PlaceId == placeIds.mainVC),

	walkSpeed = 16,
	runSpeed = 24,
	jumpPower = 50,

	theBigFour = {
		1371497771, -- me
		2782522665, -- dimen
		1495854879, -- nikii
		1992311795, -- krippy
	},

	shopPrices = {
		main = {
			emotes = 250,
			titles = 100,

			item = 10,
			soda = 5
		},
	},

	gamePasses = {
		earlyAccess = nil,

		killSounds = nil,
		extraEmotes = nil,
		emotePage = nil,
		ultOutfit = nil,
	},
}
