return function(LuaPlayer)
	local Attack = LuaPlayer.Character.Combat:CreateAttack("GO GREEN BLOB!", Enum.KeyCode.Four)
	Attack.CooldownEnabled = false
	Attack:Trigger(true)
	Attack.HeldState = true

	return function()

	end
end