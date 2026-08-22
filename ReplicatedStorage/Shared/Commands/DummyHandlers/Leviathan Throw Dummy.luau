return function(LuaPlayer)
	local Attack = LuaPlayer.Character.Combat:CreateAttack("Leviathan Throw", Enum.KeyCode.Three)
	Attack.CooldownEnabled = false
	Attack:Trigger(true)
	Attack.HeldState = true

	return function()

	end
end