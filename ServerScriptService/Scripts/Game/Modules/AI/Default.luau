local Default = {
	TargetSorting = "Nearest",
	
	--[ Values Calculated in Studs ]--
	
	Range = 50,

	TargetDistancing = 4,
	
	PatrolRange = 25,
	
	----------------------------------
	
	--[ Values Calculated in Seconds ]--
	
	RepathingDelay = 0.65,
	ChargeTowardTargetThreshold = 0.5,
	JumpWhenSightChaseThreshold = 0.5,
	DisengageAfterSightLost = 6,
	StartPathingAfterSightLostThreshold = 0.05;
	
	PatrolIdlePeriod = NumberRange.new(1, 5),
	
	------------------------------------
	
	--[ Behaviour ]--
	
	OnlyPathWithTargetSight = true,
	UseAntiSticking = false,
	
	------------------------------------
	
	PatrolPoints = {	},
	
	MoveProcedures = {},
	
	DebugMode = false,
	-- Shows critical information about the entity
	
	AgentRadius = 4,
	AgentHeight = 4,
	AgentCanJump = true,
	AgentCanClimb = true,
	AgentWaypointSpacing = 10,
}

export type Type = typeof(Default)

Default.__index = Default

return Default