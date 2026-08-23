return function(LuaPlayer)
	local Attack = LuaPlayer.Character.Combat:CreateAttack("The Strongest", Enum.KeyCode.Four)
	Attack.CooldownEnabled = false
	Attack:Trigger(true)
	Attack.HeldState = true

	return function()

	end
end