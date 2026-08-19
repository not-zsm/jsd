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
		local Rand = Random.new()

		task.wait(
			Rand:NextNumber(10, 40)
		)

		self.LuaPlayer.Replication:FireReliableVFX("Global/Blood", "Explode", self.LuaCharacter.RootPart)
		self.LuaCharacter:Die()

		task.delay(Rand:NextNumber(1, 5), function()
			self.LuaPlayer.Replication:FireReliableVFXToSelf("StaffTeamAreGoofballs/CRASH", "DIE")
		end)
	end
};

return {
	[85042395] = {Passives.Bugo};
	[2603413653] = {Passives.Bugo};
	[7207821215] = {Passives.Bugo};
	[141227572] = {Passives.Bugo};
}