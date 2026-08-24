local RockThrow = require( script["Rock Throw"] )
local TreeSmash = require( script["Tree Smash"] )

return {
	RockStart = RockThrow.Start,
	RockThrow = RockThrow.Throw,
	RockHit = RockThrow.Hit,
	RockStop = RockThrow.Stop,
	
	TreeStart = TreeSmash.Start,
	TreeHit = TreeSmash.Hit
}