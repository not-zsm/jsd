local Default = {
	MoveProcedures = {
		{
			Name = "Evasive",
			Cooldown = NumberRange.new(30),

			Condition = function(self)
				return self.Combat.Attacks.Dash:NPCCanEvasive()
			end,

			Target = {
				Range = NumberRange.new(0, math.huge),

				RequiresSight = false,
				InverseRange = false,
			}
		},
		
		{
			Name = "Boss Special Hell",
			Cooldown = NumberRange.new(40),

			Condition = function(self)
				return self.Combat.Attacks["Boss Special Hell"]:ConditionToActivate() and self.Combat.AngryStage and self.CurrentTargetCount > 2
			end,

			Target = {
				Range = NumberRange.new(0, 10),

				RequiresSight = true,
				InverseRange = false,
			}
		},
		
		{
			Name = "Shatter Slashes",
			Cooldown = NumberRange.new(20),

			Condition = function(self)
				return self.Combat.Attacks["Shatter Slashes"]:ConditionToActivate() and self.Combat.AngryStage
			end,

			Target = {
				Range = NumberRange.new(0, 10),

				RequiresSight = true,
				InverseRange = false,
			}
		},
		
		{
			Name = "DefensiveAgainstM1",
			Cooldown = NumberRange.new(0),
			
			Condition = function(self)
				return self.Target.Character.Combat:GetState("M1ing") and self.Combat.Attacks.Block:ConditionToActivate()
			end,

			Target = {
				Range = NumberRange.new(0, 8),

				RequiresSight = true,
				InverseRange = false,
			}
		},
		
		{
			Name = "DefensiveAgainstAttack",
			Cooldown = NumberRange.new(2),

			Condition = function(self)
				return self.Target.Character.Combat:GetState("Attacking") and self.Combat.Attacks.Block:ConditionToActivate()
			end,

			Target = {
				Range = NumberRange.new(0, 60),

				RequiresSight = true,
				InverseRange = false,
			}
		},
		
		--{ -- was kinda weird, didn't fit chara
		--	Name = "DefensiveAgainstBlock",
		--	Cooldown = NumberRange.new(0),

		--	Condition = function(self)
		--		return self.Target.Character.Combat:GetState("Blocking") and self.Combat.Attacks.Dash:ConditionToActivate("Side Dash")
		--	end,

		--	Target = {
		--		Range = NumberRange.new(0, 5),

		--		RequiresSight = true,
		--		InverseRange = false,
		--	}
		--},
		
		{
			Name = "DefensiveBackDash",
			Cooldown = NumberRange.new(7.5),

			Condition = function(self)
				return self.Target.Character.Combat:GetState("M1ing") and self.Combat.Attacks.Dash:ConditionToActivate("Front&Back Dash")
			end,

			Target = {
				Range = NumberRange.new(0, 10),

				RequiresSight = true,
				InverseRange = false,
			}
		},

		{
			Name = "SideDash",
			Cooldown = NumberRange.new(2),

			Condition = function(self)
				return self.Combat.Attacks.Dash:ConditionToActivate("Side Dash")
			end,

			Target = {
				Range = NumberRange.new(0, 12.5),

				RequiresSight = true,
				InverseRange = false,
			}
		},
		
		{
			Name = "M1",
			Cooldown = NumberRange.new(0),

			Condition = function(self)
				return self.Combat.Attacks.M1:ConditionToActivate() and not self:IsTargetRagdolled()
			end,

			Target = {
				Range = NumberRange.new(0, 7.5),

				RequiresSight = false, --true, -- nullifies cheese
				InverseRange = false,
			}
		},
		
		{
			Name = "FrontDash",
			Cooldown = NumberRange.new(7.5),

			Condition = function(self)
				return self.Combat.Attacks.Dash:ConditionToActivate("Front&Back Dash") and not self:IsTargetRagdolled()
			end,

			Target = {
				Range = NumberRange.new(6, 30),

				RequiresSight = true,
				InverseRange = false,
			}
		},
		
		{
			Name = "Seven Souls",
			Cooldown = NumberRange.new(100),

			Condition = function(self)
				return self.Combat.Attacks["Seven Souls"]:ConditionToActivate() and self.Combat.AngryStage
			end,

			Target = {
				Range = NumberRange.new(0, 100),

				RequiresSight = true,
				InverseRange = false,
			}
		},

		{
			Name = "Atonement",
			Cooldown = NumberRange.new(100),

			Condition = function(self)
				return self.Combat.Attacks["Atonement"]:ConditionToActivate() and self.Combat.AngryStage
			end,

			Target = {
				Range = NumberRange.new(0, 50),

				RequiresSight = true,
				InverseRange = false,
			}
		},
		
		{
			Name = "Fight",
			Cooldown = NumberRange.new(4),

			Condition = function(self)
				return self.Combat.Attacks["Fight"]:ConditionToActivate() and self.Combat.Attacks.M1.Count > 3
			end,

			Target = {
				Range = NumberRange.new(2, 13),

				RequiresSight = true,
				InverseRange = false,
			}
		},
		
		{
			Name = "Bloody Mary",
			Cooldown = NumberRange.new(3),

			Condition = function(self)
				return self.Combat.Attacks["Bloody Mary"]:ConditionToActivate() and self.Combat:GetState("M1ing")
			end,

			Target = {
				Range = NumberRange.new(2, 13),

				RequiresSight = true,
				InverseRange = false,
			}
		},

		{
			Name = "Lethal Wound",
			Cooldown = NumberRange.new(4),

			Condition = function(self)
				return self.Combat.Attacks["Lethal Wound"]:ConditionToActivate()
			end,

			Target = {
				Range = NumberRange.new(7.5, 37.5),

				RequiresSight = true,
				InverseRange = false,
			}
		},

		{
			Name = "Onslaught",
			Cooldown = NumberRange.new(2),

			Condition = function(self)
				return self.Combat.Attacks["Onslaught"]:ConditionToActivate() and self:IsTargetRagdolled()
			end,

			Target = {
				Range = NumberRange.new(2, 10),

				RequiresSight = true,
				InverseRange = false,
			}
		},
	},
	
	Range = 100,
	PatrolRange = 300,
	
	PatrolPoints = {
		workspace.Terrain["Chara_PatrolPoints"]["1"].WorldPosition,
		workspace.Terrain["Chara_PatrolPoints"]["2"].WorldPosition,
		workspace.Terrain["Chara_PatrolPoints"]["3"].WorldPosition,
		workspace.Terrain["Chara_PatrolPoints"]["4"].WorldPosition,
		workspace.Terrain["Chara_PatrolPoints"]["5"].WorldPosition
	},
	
	--PatrolPoints = {
	--	Vector3.new(116.577, 68.725, 275.498),
	--	Vector3.new(174.577, 68.725, 258.498),
	--	Vector3.new(156.577, 68.725, 310.498),
	--	Vector3.new(137.577, 68.725, 236.498),
	--	Vector3.new(198.577, 68.725, 293.498),
	--},
}

Default.__index = Default

return Default