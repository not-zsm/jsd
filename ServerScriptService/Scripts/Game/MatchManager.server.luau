local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local MessagingService = game:GetService("MessagingService")
local ServerScriptService = game:GetService("ServerScriptService")

local LuaPlayerList = require(ServerScriptService.Scripts.Game.Modules.LuaPlayerList)
require( ServerScriptService.Scripts.Game.Modules.Player ) -- I want combat stuff to load first

local EventService = require(ReplicatedStorage.Modules.Shared.Utilities.EventService)
local Job = require(ReplicatedStorage.Modules.Shared.Utilities.Job)

local MapFolder = ServerStorage.RankedAssets:WaitForChild("Maps")
local SetMatchStateEvent = ReplicatedStorage.Remotes.Ranked:WaitForChild("SetMatchState")
local UIEvent = ReplicatedStorage.Remotes.Ranked:WaitForChild("UI")

-- Settings
local CharacterSelectionDuration = 15
local IntermissionDuration = 5
local RoundsToWin = 2

-- State
local MatchData = nil
local ActiveMap = nil
local MatchStarted = false
local StartingMatch = false

local function CreateSpawnLocations(MapModel)
	local SpawnLocations = {}

	local SpawnsFolder = workspace.Map:WaitForChild("Model"):FindFirstChild("Spawns") or MapModel
	
	print("Searching for spawns in:", SpawnsFolder:GetFullName())
	
	for _, SpawnPart in ipairs(SpawnsFolder:GetChildren()) do
		if SpawnPart:IsA("BasePart") then
			local Name = SpawnPart.Name
			if not tonumber(Name) then
				if Name:match("1") then
					SpawnLocations["1"] = SpawnPart
					print("Found spawn for Team 1:", SpawnPart:GetFullName())
				end
				
				if Name:match("2") then
					SpawnLocations["2"] = SpawnPart
					print("Found spawn for Team 2:", SpawnPart:GetFullName())
				end
			else
				SpawnLocations[Name] = SpawnPart
				print("Found spawn for Team", Name, ":", SpawnPart:GetFullName())
			end
		end
	end

	print("Finished map loading. Spawn locations found:", SpawnLocations)
	
	return SpawnLocations
end

local function CreateMap() : Instance?
	local MapContainer = workspace:WaitForChild("Map") 
	local MapModel = MapContainer:WaitForChild("Model")
	
	MapModel:ClearAllChildren()

	local AvailableMaps = MapFolder:GetChildren()
	if #AvailableMaps == 0 then
		warn("No maps found in ServerStorage/RankedAssets/Maps.")
		return nil
	end

	local SelectedMapTemplate = AvailableMaps[math.random(#AvailableMaps)]
	ActiveMap = SelectedMapTemplate:Clone()

	local AtmosphereFolder = ActiveMap:FindFirstChild("Atmosphere")
	
	if AtmosphereFolder then
		for _, Setting in ipairs(AtmosphereFolder:GetChildren()) do
			local Clone = Setting:Clone()
			Clone.Parent = Lighting
		end
	end

	local SourceModel = ActiveMap:FindFirstChild("Model")
	if SourceModel then
		for _, Item in ipairs(SourceModel:GetChildren()) do
			Item.Parent = MapModel
		end
	else
		for _, Item in ipairs(ActiveMap:GetChildren()) do
			if Item.Name ~= "Atmosphere" then
				Item.Parent = MapModel
			end
		end
	end

	return MapModel
end

local function RunMatch(CurrentMatchData, PlayerObjects, SpawnLocations)
	MatchStarted = true

	print("RunMatch called.")

	if not SpawnLocations or not SpawnLocations["1"] or not SpawnLocations["2"] then
		warn("RunMatch cannot continue, missing spawn locations for one or both teams.")
		return
	end

	local RoundEnded = EventService.new()
	local MatchStartJob = Job.new()

	local MainConnections = {}
	local RoundWins = {}

	local MatchWinner = nil
	local RoundWinnerId = nil

	local RoundNumber = 1

	for UserId, PlayerData in pairs(PlayerObjects) do
		task.spawn(function()
			RoundWins[UserId] = 0
			
			print(PlayerData.Object.Name)
			
			local SpawnPartLocal = SpawnLocations[tostring(PlayerData.Team)]

			PlayerData.LuaPlayer.Character.Combat.Actions:SetEnabled(false)

			MatchStartJob:Task(task.spawn(function()
				while true do
					if PlayerData.LuaPlayer.Character.HumanoidExists then
						PlayerData.LuaPlayer.Character.RootPart.Anchored = true
					end

					task.wait(0.1)
				end
			end))
			
			if PlayerData.LuaPlayer.Character.HumanoidExists then 
				PlayerData.LuaPlayer.Character.RootPart.CFrame = SpawnPartLocal.CFrame
			end

			MainConnections[#MainConnections + 1] = PlayerData.LuaPlayer.Character.OnHumanoidAvailabilityChanged:Connect(function(Value)
				if Value then
					PlayerData.LuaPlayer.Character.RootPart.CFrame = SpawnPartLocal.CFrame
				end
			end)

			MainConnections[#MainConnections + 1] = PlayerData.LuaPlayer.Character.OnHumanoidDied:Connect(function() 
				if RoundWinnerId then return end

				for OtherUserId in pairs(PlayerObjects) do
					if OtherUserId ~= UserId then
						RoundWinnerId = OtherUserId
						break
					end
				end

				RoundEnded:Fire()
			end)

			SetMatchStateEvent:FireClient(PlayerData.Object, "CharacterSelection")
		end)
	end

	MainConnections[#MainConnections + 1] = Players.PlayerRemoving:Connect(function(LeavingPlayer)
		if PlayerObjects[LeavingPlayer.UserId] then
			print("A player in the match is leaving:", LeavingPlayer.Name)
			for OtherUserId, Data in pairs(PlayerObjects) do
				if OtherUserId ~= LeavingPlayer.UserId then
					MatchWinner = Data.Object
					print("Match winner determined by forfeit:", MatchWinner.Name)
					
					break
				end
			end
			
			RoundEnded:Fire()
		end
	end)

	print("Entering CharacterSelection phase for", CharacterSelectionDuration, "seconds.")
	
	task.wait(CharacterSelectionDuration)
	
	UIEvent:FireAllClients("startcounting")
	
	task.wait(IntermissionDuration)
	
	print("CharacterSelection phase ended.")
	
	ReplicatedStorage.Remotes.Ranked.ClearSelectionDisplays:FireAllClients()
	
	MatchStartJob:Clean()

	for _, Data in pairs(PlayerObjects) do
		local LuaPlayer = Data.LuaPlayer

		if LuaPlayer.PendingCharacterName then
			print("Player", Data.Object.Name, "selected character:", LuaPlayer.PendingCharacterName)
			LuaPlayer.Data.Profile.Data.CurrentCharacter = LuaPlayer.PendingCharacterName
			LuaPlayer.PendingCharacterName = nil
		end
		
		LuaPlayer.Character:Respawn()
	end

	local Sounds = workspace.RankedMusic.Arena:GetChildren()
	local Music
	
	if #Sounds > 0 then
		local RandomSound = Sounds[math.random(1, #Sounds)]
		print("Playing random music:", RandomSound.Name)
		Music = RandomSound
		Music:Play()
	else
		warn("No music found in workspace.Music")
	end

	while not MatchWinner do
		print("Starting Round", RoundNumber)
		
		RoundWinnerId = nil
		
		for _, Data in pairs(PlayerObjects) do
			SetMatchStateEvent:FireClient(Data.Object, "Fighting")
			
			Data.LuaPlayer.Character.Combat.Actions:SetEnabled(true)
			
			print("Set state to 'Fighting' for", Data.Object.Name)
		end

		print("Waiting for round to end...")
		
		RoundEnded:Wait()
		
		print("RoundEnded event fired.")

		if MatchWinner then
			print("Match winner was decided mid-round (player left). Breaking loop.")
			break
		end

		if RoundWinnerId then
			RoundWins[RoundWinnerId] = (RoundWins[RoundWinnerId] or 0) + 1
			local WinnerName = PlayerObjects[RoundWinnerId].Object.Name
			print("Round", RoundNumber, "winner:", WinnerName, "| Total wins:", RoundWins[RoundWinnerId])

			if RoundWins[RoundWinnerId] >= RoundsToWin then
				MatchWinner = PlayerObjects[RoundWinnerId].Object

				print("Match winner declared:", MatchWinner.Name)
			end
		end

		if not MatchWinner then
			print("Entering Intermission for", IntermissionDuration, "seconds.")
			for _, Data in pairs(PlayerObjects) do
				SetMatchStateEvent:FireClient(Data.Object, "Intermission")
				Data.LuaPlayer.Character.Combat.Actions:SetEnabled(false)
			end

			task.wait(IntermissionDuration)
		end

		RoundNumber += 1
	end

	if MatchWinner and MatchWinner:IsA("Player") then
		print("Processing match end results for winner:", MatchWinner.Name)
		local WinnerLuaPlayer = nil
		local LoserLuaPlayer = nil
		
		for _, Data in pairs(PlayerObjects) do
			if Data.Object == MatchWinner then
				WinnerLuaPlayer = Data.LuaPlayer
			else
				LoserLuaPlayer = Data.LuaPlayer
				LoserLuaPlayer.Character.RespawningEnabled = false
			end
		end

		if WinnerLuaPlayer ~= nil and LoserLuaPlayer ~= nil then
			WinnerLuaPlayer.Character.Combat.Actions:SetEnabled(false)
			
			local WinnerData = WinnerLuaPlayer.Data
			local LoserData = LoserLuaPlayer.Data
			
			local WinnerElo = WinnerData.Profile.Data.Elo
			local LoserElo = LoserData.Profile.Data.Elo
			
			print("Winner Elo:", WinnerElo, "| Loser Elo:", LoserElo)

			local EloChange = WinnerData:CalculateEloChange(WinnerElo, LoserElo)
			print("Calculated Elo change:", EloChange)

			WinnerData:AddElo(EloChange)
			LoserData:AddElo(-EloChange)

			SetMatchStateEvent:FireClient(WinnerLuaPlayer.Player, "Victory", { EloChange = EloChange })
			SetMatchStateEvent:FireClient(LoserLuaPlayer.Player, "Defeat", { EloChange = -EloChange })
			print("Sent Victory/Defeat states to clients.")
		end
	end
	
	if Music ~= nil then
		Music:Stop()
	end

	print("Waiting 10 seconds before teleporting players.")
	task.wait(10)

	print("Cleaning up match connections.")
	for _, Connection in pairs(MainConnections) do
		Connection:Disconnect()
	end

	print("Teleporting players back to lobby.")
	for _, Data in pairs(PlayerObjects) do
		local Player = Data.Object
		if Player and Player.Parent then
			print("Teleporting player:", Player.Name)
			TeleportService:Teleport(122394296123463, Player)
		end
	end
	print("Match cleanup complete.")
end

local function AttemptToStartMatch()
	print("AttemptToStartMatch called.")
	if MatchStarted then
		print("Match already started. Aborting.")
		return
	end
	
	local MapModel = CreateMap()
	
	local SpawnLocations = CreateSpawnLocations(MapModel)
	
	if not MatchData or not MatchData.Teams then
		print("MatchData or MatchData.Teams is nil. Aborting.")
		return
	end
	
	if #Players:GetPlayers() < #MatchData.Teams then
		print("Not enough players in the server yet. Have:", #Players:GetPlayers(), "Need:", #MatchData.Teams)
		return
	end

	for _, TeamData in ipairs(MatchData.Teams) do
		if not Players:GetPlayerByUserId(TeamData.PlayerId) then
			print("Player with ID", TeamData.PlayerId, "is not in the server. Aborting.")
			return
		end
	end

	StartingMatch = true
	
	print("All checks passed, proceeding to start match.")

	local PlayerObjects = {}
	
	for _, TeamData in ipairs(MatchData.Teams) do
		if PlayerObjects[TeamData.PlayerId] then
			continue
		end
		
		local Player = Players:GetPlayerByUserId(TeamData.PlayerId)
		
		if Player then 
			
			local LuaPlayer = LuaPlayerList.WaitFor(Player)
			
			if LuaPlayer then
				PlayerObjects[Player.UserId] = {
					Object = Player,
					Team = TeamData.Team,
					LuaPlayer = LuaPlayer,
				}
				
				print("Successfully created PlayerObject for:", Player.Name)
			else
				warn("LuaPlayer object not found for", Player.Name, "after waiting. Match cannot start.")
			end
		end
	end
	
	print("All players have a LuaPlayer object. Calling RunMatch.")

	RunMatch(MatchData, PlayerObjects, SpawnLocations)
	
	StartingMatch = false
end

local function OnPlayerAdded(Player : Player)
	print("OnPlayerAdded called for player:", Player.Name)

	local JoinData = Player:GetJoinData()
	if not JoinData or not JoinData.TeleportData then
		print("Kicking", Player.Name, "for having no JoinData/TeleportData.")
		Player:Kick("You are not authorized to join this server.")
		return
	end

	if not MatchData then
		MatchData = JoinData.TeleportData
		print("MatchData set from first player's JoinData.")
	end

	if not MatchData or not MatchData.Teams then
		print("Kicking", Player.Name, "because MatchData is invalid.")
		Player:Kick("Match data is invalid.")
		return
	end

	AttemptToStartMatch()
end

local function OnPlayerRemoving(Player : Player) -- wat
	print("OnPlayerRemoving called for player:", Player.Name)
	
	if not MatchStarted and MatchData then
		print("Player", Player.Name, "left before the match started. Kicking remaining players.")
		for _, OtherPlayer in ipairs(Players:GetPlayers()) do
			if OtherPlayer ~= Player then
				print("Kicking", OtherPlayer.Name)
				OtherPlayer:Kick("An opponent left the match before it started.")
			end
		end
	end
end

--LuaPlayerList.OnLuaPlayerChanged:Connect(function(LuaPlayer, Value : boolean) 
--	if Value then
--		OnPlayerAdded(LuaPlayer)
--	else
--		OnPlayerRemoving(LuaPlayer)
--	end
--end)

for _, Player in ipairs(Players:GetPlayers()) do
	task.defer(OnPlayerAdded, Player)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

