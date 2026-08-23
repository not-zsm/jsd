return function(LuaPlayer)
	local Attack = LuaPlayer.Character.Combat:MatchAttack("Block", Enum.KeyCode.F)
	Attack:Trigger(true)
	Attack.HeldState = true

	return function()

	end
end