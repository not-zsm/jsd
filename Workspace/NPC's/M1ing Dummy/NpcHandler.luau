return function(LuaPlayer)
	local Attack = LuaPlayer.Character.Combat:MatchAttack("M1", Enum.UserInputType.MouseButton1)
	Attack:Trigger(true)
	Attack.HeldState = true
	
	return function()

	end
end