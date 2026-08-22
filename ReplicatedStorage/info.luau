local runService = game:GetService('RunService')

return {
	DATASTORE = 'test',
	
	groupID = 312681295,
	gameID = nil,
	placeID = nil,
	
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
	
	isStudio = runService:IsStudio(),
	
	gamePasses = {
		earlyAccess = nil,

		killSounds = nil,
		extraEmotes = nil,
		emotePage = nil,
		ultOutfit = nil,
	},
	
	
}