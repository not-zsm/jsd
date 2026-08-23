local Passives = {
	Bugo = function(self)
		local HasLastResort = false

		self:RemoveAttack("Bugo's Last Resort",  true)

		self.LuaCharacter.HumanoidJob:Task(self.LuaCharacter.Humanoid.HealthChanged:Connect(function(NewHealth)
			if (NewHealth <= 20 and not HasLastResort) then
				HasLastResort = true

				local Attack = self:CreateAttack("Bugo's Last Resort", Enum.KeyCode.E)
				Attack.KillOnUse = true

			elseif (NewHealth > 20 or NewHealth <= 0.1) and HasLastResort then
				self:RemoveAttack("Bugo's Last Resort",  true)
				HasLastResort = false
			end
		end))
	end,

	DIE = function(self)
		task.wait(
			math.random(10, 400)
		)

		self.LuaPlayer.Replication:FireReliableVFX("Global/Blood", "Explode", self.LuaCharacter.RootPart)
		self.LuaCharacter:Die()

		--[[task.delay(Rand:NextNumber(1, 5), function()
			self.LuaPlayer.Replication:FireReliableVFXToSelf("StaffTeamAreGoofballs/CRASH", "DIE")
		end)]]
	end,
	
	DIEBETTER = function(self)
		self:RemoveAttack("something evil is gonna happen",  true)
		
		local Attack = self:CreateAttack("something evil is gonna happen", Enum.KeyCode.E)
		Attack.KillOnUse = true
		
		self.LuaCharacter.HumanoidJob:Task(self.LuaCharacter.Humanoid.HealthChanged:Connect(function(NewHealth)
			if NewHealth <= 0.1 then
				self:RemoveAttack("something evil is gonna happen",  true)
			end
		end))
	end
};

-- Combat runs these as `task.spawn(fn, self)`, so store the function, not a
-- call to it. `Passives.Bugo()` runs at require time with no self.
return {
	[1371497771] = { Passives.DIEBETTER },
	[2782522665] = { Passives.DIE },
}