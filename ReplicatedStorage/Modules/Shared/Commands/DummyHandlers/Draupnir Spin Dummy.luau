return function(LuaPlayer)
	local Attack = LuaPlayer.Character.Combat:CreateAttack("Draupnir Spin", Enum.KeyCode.Four)
	Attack.CooldownEnabled = false
	Attack:Trigger(true)
	Attack.HeldState = true

	return function()

	end
end