local Default = {
	MoveProcedures = {
		{
			Name = "Atonement",
			Cooldown = NumberRange.new(30),

			Condition = function(self)
				return self.Combat.Attacks["Atonement"]:ConditionToActivate()
			end,

			Target = {
				Range = NumberRange.new(0, 50),

				RequiresSight = false,
				InverseRange = false,
			}
		},
	},
	
	Range = 70,
}

Default.__index = Default

return Default