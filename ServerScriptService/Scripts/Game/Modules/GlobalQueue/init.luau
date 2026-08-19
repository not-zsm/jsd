local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local LuaPlayerList = require(ServerScriptService.Scripts.Game.Modules.LuaPlayerList)

local ThisJobId = game.JobId
local GlobalDataStore = DataStoreService:GetGlobalDataStore()
local RegionUTCDiff = os.time(os.date("*t")) - DateTime.now().UnixTimestamp

export type ModeData = {
	Identifier: string,
	Teams: { string },
	MaxPlayers: number,
	MaxPlayersPerTeam: { [string]: number },
	PlaceId: number,
}

export type Match_PlayerData = {
	UserId: number,
	JobId: string,
	Team: "1" | "2",
	Party: string,
}

export type Match_GlobalQueueEntry = {
	CreationTime: number,
	RegionUTCDiff: number,
	Mode: string,
	Players: { Match_PlayerData },
	ELO: number,
	OriginatingServerId: string,
	Id: string,
}

local CONSTANTS = {
	MATCH_ELO_TOLERANCE = 100,
	MATCH_TIME_ZONE_TOLERANCE = 7200,
	MATCH_REFRESH_TIMER = 10,
	MATCH_REQUEST_TIMEOUT = 15,
	MATCH_ATTEMPT_REJOIN = 15,
}

local GlobalQueue = {
	Status = {},
}

local HandlingQueues = {}
local OutgoingRequests = {}
local PlayersInMatches = {}
local CachedMatches = {}
local MatchesByKey = {}
local LastUpdatedTime = os.clock()
local UpdatedMatches = false
local CurrentTokens = {}

local MatchLocks = {}
local Teleporting = {}

local function AcquireMatchLock(Id: string)
	print("Acquiring lock for match:", Id)
	while MatchLocks[Id] do
		task.wait()
	end
	MatchLocks[Id] = true
	print("Lock acquired for match:", Id)
end

local function ReleaseMatchLock(Id: string)
	print("Releasing lock for match:", Id)
	MatchLocks[Id] = nil
end

local function PublishAsync(Topic, Data)
	local Success = false
	while not Success do
		Success = pcall(function()
			print("Publishing to topic:", Topic)
			MessagingService:PublishAsync(Topic, Data)
		end)
		if not Success then
			task.wait(5)
		end
	end
end

GlobalQueue.PublishAsync = PublishAsync

function GlobalQueue.UpdateToken(UserId: number, Token: number)
	CurrentTokens[UserId] = Token
end

local function RebuildLocalCaches()
	print("Rebuilding local caches.")
	table.clear(MatchesByKey)
	table.clear(CachedMatches)

	for MatchId, MatchEntry in pairs(HandlingQueues) do
		MatchEntry.OriginatingServerId = ThisJobId
		MatchEntry.Id = MatchId
		MatchesByKey[MatchId] = MatchEntry
		table.insert(CachedMatches, MatchEntry)
	end

	table.sort(CachedMatches, function(a, b)
		return a.CreationTime > b.CreationTime
	end)

	LastUpdatedTime = os.clock()
end

local function BuildClientMatchData(Player, Match)
	if not Match then
		return nil
	end

	local ClientMatchData = table.clone(Match)
	local Mode = GlobalQueue.GetModeData(ClientMatchData.Mode)

	for Field, Value in pairs(Mode) do
		ClientMatchData[Field] = Value
	end

	local PartyLeaderId = tonumber(tostring(Player.UserId):split("|")[1])
	local PartyLeader = Players:GetPlayerByUserId(PartyLeaderId)
	local PartyElo = 0

	if PartyLeader then
		local LuaPlayer = LuaPlayerList.Get(PartyLeader)
		if LuaPlayer and LuaPlayer.Data and LuaPlayer.Data.Profile then
			PartyElo = LuaPlayer.Data.Profile.Data.Elo or 0
		end
	end

	return ClientMatchData, PartyElo
end

local function PushStatusFor(Player)
	if not Player then
		return
	end

	local StatusEntry = GlobalQueue.Status[Player.UserId]
	print("Pushing status for player:", Player.UserId)

	if StatusEntry and StatusEntry.Match then
		local Match = HandlingQueues[StatusEntry.Match.Id] or MatchesByKey[StatusEntry.Match.Id]
		if Match then
			local ClientMatchData, PartyElo = BuildClientMatchData(Player, Match)
			if ClientMatchData then
				local ServerNow = DateTime.now().UnixTimestamp
				print("Firing UpdateMatchmakingStatus for", Player.UserId, "with match data.")
				ReplicatedStorage.Remotes.Queue.UpdateMatchmakingStatus:FireClient(Player, ClientMatchData, PartyElo, ServerNow)
				return
			end
		end
	end
	
	print("Firing UpdateMatchmakingStatus for", Player.UserId, "with nil match data.")
	ReplicatedStorage.Remotes.Queue.UpdateMatchmakingStatus:FireClient(Player)
end

local function PushStatusForMatch(Id)
	local Match = HandlingQueues[Id] or MatchesByKey[Id]
	
	if not Match then
		return
	end
	
	for _, PlayerData in ipairs(Match.Players) do
		local P = Players:GetPlayerByUserId(PlayerData.UserId)
		
		if P then
			PushStatusFor(P)
		end
	end
end

local function PublishMatchesUpdated()
	PublishAsync("MATCHES_UPDATED", { From = ThisJobId })
end

local function CanJoinMatch(Match: Match_GlobalQueueEntry, ELO: number, PlayersToJoin: number)
	local ModeData = GlobalQueue.GetModeData(Match.Mode)
	local CanJoin = (#Match.Players + PlayersToJoin) <= ModeData.MaxPlayers and math.abs(Match.RegionUTCDiff - RegionUTCDiff) <= CONSTANTS.MATCH_TIME_ZONE_TOLERANCE and math.abs(Match.ELO - ELO) <= CONSTANTS.MATCH_ELO_TOLERANCE
	print("CanJoinMatch check. Result:", CanJoin)
	
	return CanJoin
end

function GlobalQueue.FetchMatches(ForceFetch: boolean?)
	if not ForceFetch and (os.clock() - LastUpdatedTime) <= CONSTANTS.MATCH_REFRESH_TIMER then
		return CachedMatches
	end
	
	print("Fetching all matches from GlobalDataStore.")
	local AllServersMatches = GlobalDataStore:GetAsync("OngoingMatches") or {}
	AllServersMatches[ThisJobId] = HandlingQueues

	table.clear(CachedMatches)
	table.clear(MatchesByKey)

	for JobId, HandlingMatches in pairs(AllServersMatches) do
		for ThisId, MatchEntry in pairs(HandlingMatches) do
			MatchEntry.OriginatingServerId = JobId
			MatchEntry.Id = ThisId
			MatchesByKey[ThisId] = MatchEntry
			table.insert(CachedMatches, MatchEntry)
		end
	end

	table.sort(CachedMatches, function(a, b)
		return a.CreationTime > b.CreationTime
	end)

	LastUpdatedTime = os.clock()
	return CachedMatches
end

function GlobalQueue.GetModeData(Mode: string): ModeData
	return require(assert(script:FindFirstChild(Mode), "Unknown mode: " .. Mode))
end

function GlobalQueue.MakeParty(...: { UserId: number, JobId: string })
	local UserIds = {}
	local From = {}

	for _, PlayerData in { ... } do
		table.insert(UserIds, PlayerData.UserId)
		From[tostring(PlayerData.UserId)] = PlayerData.JobId
	end

	return {
		UserId = table.concat(UserIds, "|"),
		From = From,
	}
end

function GlobalQueue._TeleportPlayers(Id)
	if Teleporting[Id] then
		return
	end
	print("Attempting to teleport players for match:", Id)
	local Data = HandlingQueues[Id]
	if Data == nil then
		return
	end

	local ModeData = GlobalQueue.GetModeData(Data.Mode)

	local Unique = {}
	for _, P in ipairs(Data.Players) do
		Unique[P.UserId] = true
	end
	local Count = 0
	for _ in pairs(Unique) do
		Count += 1
	end
	if Count ~= ModeData.MaxPlayers then
		print("Match not full. Aborting teleport.")
		return
	end

	print("Match is full. Reserving server and teleporting.")
	Teleporting[Id] = true
	HandlingQueues[Id] = nil
	UpdatedMatches = true

	local Code = TeleportService:ReserveServer(ModeData.PlaceId)
	local TeleportData = { Teams = {}, OriginatingServerId = ThisJobId }

	for _, PlayerData in ipairs(Data.Players) do
		table.insert(TeleportData.Teams, { PlayerId = PlayerData.UserId, Team = PlayerData.Team })
	end

	local LocalPlayers = {}
	local RemoteByJob = {}

	for _, PlayerData in ipairs(Data.Players) do
		local P = Players:GetPlayerByUserId(PlayerData.UserId)
		if P then
			table.insert(LocalPlayers, P)
		else
			local J = PlayerData.JobId
			RemoteByJob[J] = RemoteByJob[J] or {}
			table.insert(RemoteByJob[J], PlayerData.UserId)
		end
	end

	RebuildLocalCaches()
	PushStatusForMatch(Id)
	PublishMatchesUpdated()

	pcall(function()
		if #LocalPlayers > 0 then
			TeleportService:TeleportToPrivateServer(ModeData.PlaceId, Code, LocalPlayers, nil, TeleportData)
		end
		for Job, Ids in pairs(RemoteByJob) do
			for _, U in ipairs(Ids) do
				PublishAsync("MATCH_" .. Job, {
					Method = "MATCH_START",
					PlaceId = ModeData.PlaceId,
					Code = Code,
					TeleportData = TeleportData,
					Joining = U,
				})
			end
		end
	end)

	Teleporting[Id] = nil
end

function GlobalQueue._RemovePlayer(Id: string, UserId: number)
	local Match = HandlingQueues[Id] or MatchesByKey[Id]
	if Match then
		print("Removing player", UserId, "from match", Id)
		UpdatedMatches = true

		for i, PlayerData in ipairs(Match.Players) do
			if PlayerData.UserId == UserId then
				table.remove(Match.Players, i)
				break
			end
		end

		if #Match.Players == 0 then
			print("Match", Id, "is now empty. Removing.")
			HandlingQueues[Id] = nil
		end

		RebuildLocalCaches()
		PushStatusForMatch(Id)
		PublishMatchesUpdated()
	end
end

function GlobalQueue.PlayerLeaving(Player)
	local Uid = Player.UserId
	local Status = GlobalQueue.Status[Uid]
	if not Status then
		return
	end
	print("Player", Uid, "is leaving.")

	PublishAsync("MATCH_" .. Status.From, {
		Method = "MATCH_LEAVE_LISTENER",
		Joining = Uid,
		Id = Status.Id,
	})

	GlobalQueue.Status[Uid] = nil

	if Status.Match and Status.Match.Id then
		for i = #Status.Match.Players, 1, -1 do
			if Status.Match.Players[i].UserId == Uid then
				table.remove(Status.Match.Players, i)
			end
		end
		if #Status.Match.Players == 0 then
			HandlingQueues[Status.Match.Id] = nil
		end
		UpdatedMatches = true
		RebuildLocalCaches()
		PublishMatchesUpdated()
	end

	PublishAsync("PARTY_" .. Uid, {
		JoinedMatch = "",
		JoinedFrom = ThisJobId,
	})
end

function GlobalQueue._ResolveTeams(Id: string)
	print("Resolving teams for match:", Id)
	local PartyTeams = {}

	local ModeData = GlobalQueue.GetModeData(HandlingQueues[Id].Mode)
	local AvailableTeams = table.clone(ModeData.MaxPlayersPerTeam)

	for _, PlayerData in ipairs(HandlingQueues[Id].Players) do
		if PartyTeams[PlayerData.Party] then
			continue
		end

		local TeamToAssign, MostSpaces = "", 0

		for TeamName, Spaces in pairs(AvailableTeams) do
			if Spaces > MostSpaces then
				MostSpaces = Spaces
				TeamToAssign = TeamName
			end
		end

		for _, PartyUser in ipairs(PlayerData.Party:split("|")) do
			if MostSpaces > 0 then
				MostSpaces -= 1
				for _, PData in ipairs(HandlingQueues[Id].Players) do
					if PData.UserId == tonumber(PartyUser) then
						PData.Team = TeamToAssign
						break
					end
				end
			else
				AvailableTeams[TeamToAssign] = 0
				MostSpaces, TeamToAssign = 0, ""
				for TeamName, Spaces in pairs(AvailableTeams) do
					if Spaces > MostSpaces then
						MostSpaces = Spaces
						TeamToAssign = TeamName
					end
				end
			end
		end

		AvailableTeams[TeamToAssign] = MostSpaces
		PartyTeams[PlayerData.Party] = true
	end
end

local function AddPlayersCapped(Id: string, UserIdList: { string }, From: { [number]: string } | { [string]: string })
	local ModeData = GlobalQueue.GetModeData(HandlingQueues[Id].Mode)
	local PartyHash = table.concat(UserIdList, "|")

	local Existing = {}
	for _, P in ipairs(HandlingQueues[Id].Players) do
		Existing[P.UserId] = true
	end
	
	print("Adding players to match", Id, ". Capped at", ModeData.MaxPlayers)

	for _, User in ipairs(UserIdList) do
		local Num = tonumber(User)
		if not Existing[Num] then
			table.insert(HandlingQueues[Id].Players, {
				UserId = Num,
				Party = PartyHash,
				JobId = From[User] or From[tonumber(User)],
				Team = "",
			})
			Existing[Num] = true
		end
		if #HandlingQueues[Id].Players >= ModeData.MaxPlayers then
			break
		end
	end

	GlobalQueue._ResolveTeams(Id)
end

function GlobalQueue._AddPlayersToMatch(Id: string, UserIdList: { string }, From: { [number]: string } | { [string]: string })
	UpdatedMatches = true

	AddPlayersCapped(Id, UserIdList, From)

	RebuildLocalCaches()
	PushStatusForMatch(Id)
	PublishMatchesUpdated()

	local ModeData = GlobalQueue.GetModeData(HandlingQueues[Id].Mode)
	if #HandlingQueues[Id].Players == ModeData.MaxPlayers then
		GlobalQueue._TeleportPlayers(Id)
	end
end

function GlobalQueue.AttemptJoinMatch(Player: Player, PartyData: table, Mode: string, EntryId: string?, Token: number)
	local LuaPlayer = LuaPlayerList.Get(Player)
	
	if not LuaPlayer or not LuaPlayer.Data or not LuaPlayer.Data.Profile then
		return
	end

	local Matches = GlobalQueue.FetchMatches(true)
	local UserId = tostring(PartyData.UserId)
	local PartyMembers = UserId:split("|")

	for _, MatchEntry in ipairs(Matches) do
		if MatchEntry.Id == EntryId and MatchEntry.OriginatingServerId == ThisJobId then
			continue
		end

		if EntryId and HandlingQueues[EntryId] and #HandlingQueues[EntryId].Players > 1 then
			continue
		end

		local Invalid = false

		for _, P in ipairs(MatchEntry.Players) do
			if tostring(P.UserId) == PartyMembers[1] then
				Invalid = true
				break
			end
		end

		if Invalid then
			continue
		end

		if MatchEntry.Mode == Mode and CanJoinMatch(MatchEntry, LuaPlayer.Data.Profile.Data.Elo, #PartyMembers) and #MatchEntry.Players > 0 then
			local Host = tonumber(PartyMembers[1])

			PublishAsync("MATCH_" .. MatchEntry.OriginatingServerId, {
				Method = "MATCH_JOIN_LISTENER",
				Id = MatchEntry.Id,
				Joining = PartyData,
				From = ThisJobId,
				Elo = LuaPlayer.Data.Profile.Data.Elo,
				Token = Token,
			})

			OutgoingRequests[Host] = {
				To = MatchEntry.Id,
				Thread = coroutine.running(),
				Token = Token,
			}

			local TimeoutThread = task.delay(CONSTANTS.MATCH_REQUEST_TIMEOUT, function()
				local Req = OutgoingRequests[Host]
				
				if Req and coroutine.status(Req.Thread) == "suspended" then
					coroutine.resume(Req.Thread, false)
				end
			end)

			local Response, Id = coroutine.yield()

			pcall(task.cancel, TimeoutThread)

			OutgoingRequests[Host] = nil

			if Response then
				if EntryId then
					HandlingQueues[EntryId] = nil
					UpdatedMatches = true
					RebuildLocalCaches()
					PublishMatchesUpdated()
				end

				PlayersInMatches[Player.UserId] = MatchEntry.Id

				return true
			end
		end
	end
end

function GlobalQueue.JoinPlayer(Player: Player, PartyData: table, Mode: string, Token: number)
	print("Player", Player.UserId, "is joining the queue for mode", Mode)
	
	if GlobalQueue.AttemptJoinMatch(Player, PartyData, Mode, nil, Token) then
		print("Player", Player.UserId, "found an existing match to join.")
		return
	end
	
	print("No existing match found. Creating a new one.")
	
	local LuaPlayer = LuaPlayerList.Get(Player)
	if not LuaPlayer or not LuaPlayer.Data or not LuaPlayer.Data.Profile then
		return
	end

	local PartyMembers = tostring(PartyData.UserId):split("|")
	local Id = HttpService:GenerateGUID(false)

	local Entry = {
		CreationTime = DateTime.now().UnixTimestamp,
		RegionUTCDiff = RegionUTCDiff,
		Mode = Mode,
		Players = {},
		ELO = LuaPlayer.Data.Profile.Data.Elo,
	}

	HandlingQueues[Id] = Entry

	GlobalQueue._AddPlayersToMatch(Id, PartyMembers, PartyData.From)

	for _, UserIdStr in ipairs(PartyMembers) do
		local Uid = tonumber(UserIdStr)
		
		if not Players:GetPlayerByUserId(Uid) then
			PublishAsync("PARTY_" .. Uid, {
				JoinedMatch = Id,
				JoinedFrom = ThisJobId,
			})
		else
			GlobalQueue.Status[Uid] = {
				Id = Id,
				From = ThisJobId,
				Match = Entry,
				Token = Token,
			}
			
			GlobalQueue.UpdateToken(Uid, Token)
			
			local P = Players:GetPlayerByUserId(Uid)
			
			if P then
				PushStatusFor(P)
			end
		end
	end

	local Retries = 0

	while HandlingQueues[Id] and Retries < 10 do
		task.wait(1)
		Retries += 1
		if #Entry.Players == #PartyMembers then
			GlobalQueue.AttemptJoinMatch(Player, PartyData, Mode, Id, Token)
		end
	end
end

function GlobalQueue.HandleJoiningCrossServ(Data)
	local Request = Data.Data

	if Players:GetPlayerByUserId(Request.Joining) == nil then
		return PublishAsync("MATCH_" .. Request.From, {
			Method = "MATCH_LEAVE_LISTENER",
			Joining = Request.Joining,
			Id = Request.Id,
		})
	end

	if OutgoingRequests[Request.Joining] and OutgoingRequests[Request.Joining].To == Request.Id then
		GlobalQueue.Status[Request.Joining] = {
			Id = Request.Id,
			From = Request.From,
			Match = MatchesByKey[Request.Id],
		}

		local P = Players:GetPlayerByUserId(Request.Joining)
		
		if P then
			PushStatusFor(P)
		end
	else
		local Timeout = 60
		
		repeat
			Timeout -= task.wait(1)
			GlobalQueue.FetchMatches(true)
		until Timeout < 0 or MatchesByKey[Request.Id]

		GlobalQueue.Status[Request.Joining] = {
			Id = Request.Id,
			From = Request.From,
			Match = MatchesByKey[Request.Id],
		}

		local P = Players:GetPlayerByUserId(Request.Joining)
		
		if P then
			PushStatusFor(P)
		end
	end
end

MessagingService:SubscribeAsync("MATCH_" .. ThisJobId, function(Data)
	local Method = Data.Data.Method
	print("Received message on topic MATCH_", ThisJobId, "with method:", Method)
	
	if Method == "MATCH_JOIN_ACCEPT" then
		local Request = Data.Data
		
		if CurrentTokens[Request.Joining] ~= Request.Token then
			return
		end
		
		local Out = OutgoingRequests[Request.Joining]
		
		if Out and Out.To == Request.Id and Out.Token == Request.Token and Players:GetPlayerByUserId(Request.Joining) then
			GlobalQueue.Status[Request.Joining] = {
				Id = Request.Id,
				From = Request.From,
				Match = MatchesByKey[Request.Id],
				Token = Request.Token,
			}
			
			local P = Players:GetPlayerByUserId(Request.Joining)
			
			if P then
				PushStatusFor(P)
			end
			
			coroutine.resume(Out.Thread, true, Request.Id)
		end

	elseif Method == "MATCH_JOIN_DENY" then
		local Request = Data.Data
		local Out = OutgoingRequests[Request.Joining]
		
		if Out and Out.To == Request.Id and Players:GetPlayerByUserId(Request.Joining) then
			GlobalQueue.Status[Request.Joining] = nil
			if coroutine.status(Out.Thread) == "suspended" then
				coroutine.resume(Out.Thread, false, Request.Id)
			end
		end
	elseif Method == "MATCH_START" then
		local Request = Data.Data
		local Player = Players:GetPlayerByUserId(Request.Joining)
		
		if Player then
			pcall(function()
				TeleportService:TeleportToPrivateServer(Request.PlaceId, Request.Code, { Player }, nil, Request.TeleportData)
			end)
		end
	elseif Method == "MATCH_LEFT_LISTENER" then
		if GlobalQueue.Status[Data.Data.Id] then
			GlobalQueue.Status[Data.Data.Id] = nil
		end
	elseif Method == "MATCH_LEAVE_LISTENER" then
		local Request = Data.Data
		
		if HandlingQueues[Request.Id] then
			local CompoundPlayers = tostring(Request.Joining):split("|")
			for _, UserId in ipairs(CompoundPlayers) do
				GlobalQueue._RemovePlayer(Request.Id, tonumber(UserId))
			end
		end
	elseif Method == "MATCH_JOIN_LISTENER" then
		local Request = Data.Data
		local CompoundPlayers = tostring(Request.Joining.UserId):split("|")
		local Now = DateTime.now().UnixTimestamp
		
		print("Handling MATCH_JOIN_LISTENER for match", Request.Id)
		
		AcquireMatchLock(Request.Id)

		local Accept = false
		
		repeat
			if not HandlingQueues[Request.Id] then
				break
			end
			
			if math.abs(Now - Data.Sent) > CONSTANTS.MATCH_REQUEST_TIMEOUT then
				break
			end
			
			local ModeData = GlobalQueue.GetModeData(HandlingQueues[Request.Id].Mode)
			local CurrentCount = #HandlingQueues[Request.Id].Players
			local Proposed = CurrentCount + #CompoundPlayers
			
			if Proposed > ModeData.MaxPlayers then
				break
			end
			
			if not CanJoinMatch(HandlingQueues[Request.Id], Request.Elo, #CompoundPlayers) then
				break
			end
			
			Accept = true
		until true

		if Accept then
			for _, PlayerId in ipairs(CompoundPlayers) do
				local OriginatingJobId = Request.Joining.From[PlayerId]
				if OriginatingJobId then
					PublishAsync("MATCH_" .. OriginatingJobId, {
						Method = "MATCH_JOIN_ACCEPT",
						Joining = tonumber(PlayerId),
						Id = Request.Id,
						From = ThisJobId,
						Token = Request.Token,
					})
				end
			end

			AddPlayersCapped(Request.Id, CompoundPlayers, Request.Joining.From)

			UpdatedMatches = true
			RebuildLocalCaches()
			PushStatusForMatch(Request.Id)
			PublishMatchesUpdated()

			local ModeData = GlobalQueue.GetModeData(HandlingQueues[Request.Id].Mode)
			if #HandlingQueues[Request.Id].Players == ModeData.MaxPlayers then
				GlobalQueue._TeleportPlayers(Request.Id)
			end
		else
			PublishAsync("MATCH_" .. Request.From, {
				Method = "MATCH_JOIN_DENY",
				Joining = tonumber(CompoundPlayers[1]),
				Id = Request.Id,
				From = ThisJobId,
			})
		end

		ReleaseMatchLock(Request.Id)
	end
end)

MessagingService:SubscribeAsync("MATCHES_UPDATED", function()
	GlobalQueue.FetchMatches()
end)

Players.PlayerRemoving:Connect(GlobalQueue.PlayerLeaving)

game:BindToClose(function()
	GlobalDataStore:UpdateAsync("OngoingMatches", function(AllMatches)
		AllMatches = AllMatches or {}
		AllMatches[ThisJobId] = nil
		
		return AllMatches
	end)

	for _, MatchEntry in pairs(HandlingQueues) do
		for _, PlayerData in ipairs(MatchEntry.Players) do
			PublishAsync("MATCH_" .. PlayerData.JobId, { Method = "MATCH_LEFT_LISTENER", Id = PlayerData.UserId })
		end
	end
end)

task.spawn(function()
	while true do
		while not UpdatedMatches do
			task.wait()
		end

		for Id, Match in pairs(HandlingQueues) do
			if #Match.Players == 0 then
				HandlingQueues[Id] = nil
			end
		end

		GlobalDataStore:UpdateAsync("OngoingMatches", function(AllMatches)
			UpdatedMatches = false
			AllMatches = AllMatches or {}
			AllMatches[ThisJobId] = HandlingQueues
			
			return AllMatches
		end)

		task.wait(CONSTANTS.MATCH_REFRESH_TIMER)
	end
end)

return GlobalQueue
