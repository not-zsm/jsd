local ServerScriptService = game:GetService("ServerScriptService")
local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )

local CharaSpawner = require( ServerScriptService.Scripts.Game.Modules.CharaSpawner )

return {
	[3348046631] = {
		Name = "Spawn Cursed Child",
		PurchaseText = "You have spawned the Cursed Child.",
		
		Function = function(ReceivingPlayer : Player)
			local LuaPlayer = LuaPlayerList.WaitFor(ReceivingPlayer)

			if (LuaPlayer == nil) then 
				return false
			end

			local Profile = LuaPlayer.Data.Profile

			if (Profile == nil) then
				LuaPlayer.Data.OnDataLoaded:Wait()
			end
			
			if (Profile == nil) then
				return false
			end

			if (CharaSpawner.Spawned or CharaSpawner.TimerThread == nil) then
				return false
			end
			
			task.defer(CharaSpawner.Spawn, CharaSpawner.SpawnCF)

			return true
		end
	},
	
	[2657712724] = {
		Name = "Random Emote",
		PurchaseText = "You have purchased a Random Emote.",

		Function = function(ReceivingPlayer : Player) -- random emote
			local LuaPlayer = LuaPlayerList.WaitFor(ReceivingPlayer)

			if (LuaPlayer == nil) then 
				return false
			end

			local Profile = LuaPlayer.Data.Profile
			
			if (Profile == nil) then
				LuaPlayer.Data.OnDataLoaded:Wait()
			end

			if (Profile == nil) then
				return false
			end

			local Success : boolean, EmoteName : string = LuaPlayer.Character.Emotes:GetRandom("Purchase")

			if Success then
				print(ReceivingPlayer.Name, "bought a random emote:", EmoteName or "Error getting emote name")
			end

			return Success
		end
	},
	
	--[6275120808] = {
	--	Name = "2 Random Emotes",
	--	PurchaseText = "You have purchased 2 Random Emotes.",

	--	Function = function(ReceivingPlayer : Player) -- random emote
	--		local LuaPlayer = LuaPlayerList.WaitFor(ReceivingPlayer)

	--		if (LuaPlayer == nil) then 
	--			return false
	--		end

	--		local Profile = LuaPlayer.Data.Profile

	--		if (Profile == nil) then
	--			return false
	--		end

	--		if not Profile:IsActive() then
	--			return false
	--		end

	--		local Success : boolean, EmoteName : string = LuaPlayer.Character.Emotes:GetRandom("Purchase")

	--		if Success then
	--			print(ReceivingPlayer.Name, "bought a random emote:", EmoteName or "Error getting emote name")
	--		end

	--		return Success
	--	end
	--},

	[3272071021] = {
		Name = "Combat Gods + Isagi",
		PurchaseText = "You have purchased the Combat Gods + Isagi bundle.",
		
		Function = function(ReceivingPlayer : Player) -- combat gods + isagi
			local LuaPlayer = LuaPlayerList.WaitFor(ReceivingPlayer)

			if (LuaPlayer == nil) then 
				return false
			end

			local Profile = LuaPlayer.Data.Profile

			if (Profile == nil) then
				LuaPlayer.Data.OnDataLoaded:Wait()
			end

			if (Profile == nil) then
				return false
			end
			
			if not Profile:IsActive() then
				return false
			end

			local IsagiSuccess : boolean = LuaPlayer.Character.Emotes:Purchase("Isagi")
			local CombatGodsSuccess : boolean = LuaPlayer.Character.Emotes:Purchase("Combat Gods")

			if IsagiSuccess and CombatGodsSuccess then
				print(ReceivingPlayer.Name, "got the combat god + isagi emotes bundle")
			end

			return IsagiSuccess and CombatGodsSuccess
		end
	},
	
	[3288190056] = {
		Name = "Love Train",
		PurchaseText = "You have purchased the Love Train emote.",

		Function = function(ReceivingPlayer : Player) -- love train
			local LuaPlayer = LuaPlayerList.WaitFor(ReceivingPlayer)

			if (LuaPlayer == nil) then 
				return false
			end

			local Profile = LuaPlayer.Data.Profile
			
			if (Profile == nil) then
				LuaPlayer.Data.OnDataLoaded:Wait()
			end

			if (Profile == nil) then
				return false
			end
			
			if not Profile:IsActive() then
				return false
			end

			local LoveTrainSuccess : boolean = LuaPlayer.Character.Emotes:Purchase("Love Train")

			if LoveTrainSuccess then
				print(ReceivingPlayer.Name, "got the love train limited emote")
			end

			return LoveTrainSuccess
		end
	},
	
	[3328246177] = {
		Name = "Final Matchup",
		PurchaseText = "You have purchased the Final Matchup emote.",

		Function = function(ReceivingPlayer : Player)
			local LuaPlayer = LuaPlayerList.WaitFor(ReceivingPlayer)

			if (LuaPlayer == nil) then 
				return false
			end

			local Profile = LuaPlayer.Data.Profile

			if (Profile == nil) then
				LuaPlayer.Data.OnDataLoaded:Wait()
			end

			if (Profile == nil) then
				return false
			end
			
			if not Profile:IsActive() then
				return false
			end

			local FinalMatchupSuccess : boolean = LuaPlayer.Character.Emotes:Purchase("Final Matchup")

			if FinalMatchupSuccess then
				print(ReceivingPlayer.Name, "got the Final Matchup limited emote")
			end

			return FinalMatchupSuccess
		end
	},
	
	[3401278666] = {
		Name = "The Final Showdown",
		PurchaseText = "You have purchased The Final Showdown emote.",

		Function = function(ReceivingPlayer : Player)
			local LuaPlayer = LuaPlayerList.WaitFor(ReceivingPlayer)

			if (LuaPlayer == nil) then 
				return false
			end

			local Profile = LuaPlayer.Data.Profile

			if (Profile == nil) then
				LuaPlayer.Data.OnDataLoaded:Wait()
			end

			if (Profile == nil) then
				return false
			end

			if not Profile:IsActive() then
				return false
			end

			local TheFinalShowdownSuccess : boolean = LuaPlayer.Character.Emotes:Purchase("The Final Showdown")

			if TheFinalShowdownSuccess then
				print(ReceivingPlayer.Name, "got The Final Showdown limited emote")
			end

			return TheFinalShowdownSuccess
		end
	},
}