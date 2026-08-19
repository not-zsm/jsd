local SoundService = game:GetService("SoundService")

return {
	["Sound_Effects"] = function(_, Value : number)
		SoundService.SFX.Volume = (Value / 100)
	end,
	
	["Environment"] = function(_, Value : number)
		SoundService.Environment.Volume = (Value / 100)
	end,
	
	["Ultimate_Music"] = function(_, Value : number)
		SoundService.UltimateMusic.Volume = (Value / 100)
	end,
	
	["Kill_Sounds"] = function(_, Value : number)
		SoundService.KillSounds.Volume = (Value / 100)
	end,
	
	["UI"] = function(_, Value : number)
		SoundService.UI.Volume = (Value / 100)
	end,
	
	["Emotes"] = function(_, Value : number)
		SoundService.Emotes.Volume = (Value / 100)
	end,
	
	["Accessories"] = function(LuaPlayer, Value : number)
		LuaPlayer.Character.AccessorySetting = Value
	end,
	
	["Head_Tracking"] = function(LuaPlayer, Value : number)
		LuaPlayer.Character.HeadMovementSetting = Value
	end,
}