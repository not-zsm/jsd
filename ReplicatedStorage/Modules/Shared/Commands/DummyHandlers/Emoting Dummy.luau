return function(LuaPlayer)

	task.wait()

	local LuaCharacter = LuaPlayer.Character
	local Combat = LuaCharacter.Combat

	LuaCharacter.Emotes:PlayRandomEmote()

	LuaCharacter.HumanoidJob:Task(Combat.OnStateChanged:Connect(function(State, Value)
		if (State == "Stunned" or State == "Ragdolled") and not Value then
			LuaCharacter.Emotes:PlayRandomEmote()
		end
	end))

	return function()

	end
end