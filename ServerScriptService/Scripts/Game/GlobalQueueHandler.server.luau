local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local GlobalQueue = require(ServerScriptService.Scripts.Game.Modules.GlobalQueue)
local LuaPlayerList = require(ServerScriptService.Scripts.Game.Modules.LuaPlayerList)

local PlayerTemp = {}

local function PlayerAdded(Player)
	local InternalParty = {
		{
			UserId = Player.UserId,
			JobId = game.JobId,
		}
	}

	PlayerTemp[Player] = {
		Connections = {},
		SentPartyRequests = {},
		InternalParty = InternalParty,
		PartyRequests = {},
		PartyInstance = GlobalQueue.MakeParty(table.unpack(InternalParty)),
		PartyRequestDebounce = 0,
		OwnsCurrentParty = true,
		MatchmakingThread = nil,
		QueueToken = 0,
	}

	PlayerTemp[Player].Connections.PartyMasterSignal = MessagingService:SubscribeAsync("PARTY_" .. Player.UserId, function(Data)
		local Response = Data.Data

		if Response.Leaving then
			local Index
			for I, PData in ipairs(InternalParty) do
				if PData.UserId == Response.Leaving then
					Index = I
					break
				end
			end
			if Index then
				table.remove(InternalParty, Index)
			end

		elseif Response.Joining then
			if not PlayerTemp[Player].OwnsCurrentParty then
				return GlobalQueue.PublishAsync("PARTY_" .. Response.Joining, { Kicked = "This player is in another party!" })
			end
			if #InternalParty >= 4 then
				return GlobalQueue.PublishAsync("PARTY_" .. Response.Joining, { Kicked = "This party is too large (max members is 4!)" })
			end
			for _, DataEntry in ipairs(InternalParty) do
				if DataEntry.UserId == Response.Joining then
					return warn("already exists.")
				end
			end
			table.insert(InternalParty, { UserId = Response.Joining, JobId = Response.From })

		elseif Response.UpdatePlayers then
			InternalParty = Response.UpdatePlayers

		elseif Response.Kicked then
			InternalParty = { { UserId = Player.UserId, JobId = game.JobId } }
			PlayerTemp[Player].OwnsCurrentParty = true
			ReplicatedStorage.Remotes.Queue.Error:FireClient(Player, Response.Kicked)

		elseif Response.JoinedMatch then
			if Response.JoinedMatch == "" then
				GlobalQueue.Status[Player.UserId] = nil
				return
			end
			return GlobalQueue.HandleJoiningCrossServ({
				Data = { Joining = Player.UserId, From = Response.JoinedFrom, Id = Response.JoinedMatch }
			})

		elseif Response.Requesting then
			if not table.find(PlayerTemp[Player].PartyRequests, Response.Requesting) then
				table.insert(PlayerTemp[Player].PartyRequests, Response.Requesting)

				task.delay(12, function()
					local Index = table.find(PlayerTemp[Player].PartyRequests, Response.Requesting)
					if Index then
						table.remove(PlayerTemp[Player].PartyRequests, Index)
					end
					if PlayerTemp[Player].OwnsCurrentParty then
						ReplicatedStorage.Remotes.Queue.NotifyPartyRequest:FireClient(Player, PlayerTemp[Player].PartyRequests)
					end
				end)

				if PlayerTemp[Player].OwnsCurrentParty then
					ReplicatedStorage.Remotes.Queue.NotifyPartyRequest:FireClient(Player, PlayerTemp[Player].PartyRequests)
				end
			end
		end

		PlayerTemp[Player].PartyInstance = GlobalQueue.MakeParty(table.unpack(InternalParty))
		ReplicatedStorage.Remotes.Queue.UpdatePartyStatus:FireClient(Player, InternalParty, PlayerTemp[Player].OwnsCurrentParty)

		if PlayerTemp[Player].OwnsCurrentParty then
			for _, UserData in ipairs(InternalParty) do
				if UserData.UserId ~= Player.UserId then
					GlobalQueue.PublishAsync("PARTY_" .. UserData.UserId, { UpdatePlayers = InternalParty })
				end
			end
		else
			PlayerTemp[Player].OwnsCurrentParty = false
		end
	end)
end

local function PlayerRemoving(Player: Player)
	if PlayerTemp[Player] then
		for _, Connection in pairs(PlayerTemp[Player].Connections) do
			Connection:Disconnect()
		end
		PlayerTemp[Player] = nil
	end
end

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)

for _, Player in ipairs(Players:GetPlayers()) do
	task.defer(PlayerAdded, Player)
end

ReplicatedStorage.Remotes.Queue.StartMatchmake.OnServerInvoke = function(Player: Player, Mode)
	local Party = PlayerTemp[Player].PartyInstance

	local Success, GameMode = pcall(GlobalQueue.GetModeData, Mode)
	if not Success then
		return false, "Unknown mode: " .. Mode
	end

	if not PlayerTemp[Player].OwnsCurrentParty then
		return false, "Only the party host can start matchmaking."
	end

	if GameMode.CanEnter then
		local CanEnter, Reason = GameMode.CanEnter(Player, Party)
		if not CanEnter then
			return false, Reason
		end
	end

	PlayerTemp[Player].QueueToken = (PlayerTemp[Player].QueueToken or 0) + 1
	GlobalQueue.UpdateToken(Player.UserId, PlayerTemp[Player].QueueToken)

	PlayerTemp[Player].MatchmakingThread = task.spawn(function()
		local Ok, Err = pcall(GlobalQueue.JoinPlayer, Player, Party, Mode, PlayerTemp[Player].QueueToken)
		if not Ok then
			warn(Err, "while matchmaking.")
		end
	end)

	return true
end

ReplicatedStorage.Remotes.Queue.CancelMatchmake.OnServerEvent:Connect(function(Player: Player)
	PlayerTemp[Player].QueueToken = (PlayerTemp[Player].QueueToken or 0) + 1
	GlobalQueue.UpdateToken(Player.UserId, PlayerTemp[Player].QueueToken)

	PlayerTemp[Player].MatchmakingThread = nil
	GlobalQueue.PlayerLeaving(Player)
end)

ReplicatedStorage.Remotes.Queue.KickPlayer.OnServerEvent:Connect(function(Player: Player, UserId)
	if not PlayerTemp[Player].OwnsCurrentParty then
		return
	end

	local Party = PlayerTemp[Player].InternalParty

	for I, PData in ipairs(Party) do
		if PData.UserId == UserId then
			GlobalQueue.PublishAsync("PARTY_" .. UserId, { Kicked = "You have been kicked from this party!" })
			table.remove(Party, I)
			PlayerTemp[Player].PartyInstance = GlobalQueue.MakeParty(table.unpack(Party))
			ReplicatedStorage.Remotes.Queue.UpdatePartyStatus:FireClient(Player, Party)
			break
		end
	end
end)

ReplicatedStorage.Remotes.Queue.PartyRequest.OnServerInvoke = function(Player: Player, OtherPlayer: number)
	if Player.UserId == OtherPlayer then
		return false, "You cant invite yourself silly."
	end

	if os.clock() < PlayerTemp[Player].PartyRequestDebounce then
		return false, "You are sending requests too fast!\nWait " .. math.ceil(PlayerTemp[Player].PartyRequestDebounce - os.clock()) .. "s before trying again."
	end

	if os.clock() < (PlayerTemp[Player].SentPartyRequests[OtherPlayer] or 0) then
		return false, "You are sending requests too fast to this user!\nWait " .. math.ceil(PlayerTemp[Player].SentPartyRequests[OtherPlayer] - os.clock()) .. "s before trying again."
	end

	if not PlayerTemp[Player].OwnsCurrentParty then
		return false, "You cannot send party requests if you're in a party."
	end

	if #PlayerTemp[Player].InternalParty >= 4 then
		return false, "Max party limit is 4 players."
	end

	PlayerTemp[Player].SentPartyRequests[OtherPlayer] = os.clock() + 30
	PlayerTemp[Player].PartyRequestDebounce = os.clock() + 5

	GlobalQueue.PublishAsync("PARTY_" .. OtherPlayer, { Requesting = Player.UserId })

	return true
end

ReplicatedStorage.Remotes.Queue.JoinParty.OnServerInvoke = function(Player: Player, JoinPlayer: number)
	if Player.UserId == JoinPlayer then
		return false, "You cant join yourself silly."
	end

	local Index = table.find(PlayerTemp[Player].PartyRequests, JoinPlayer)
	if not Index then
		return false, "Party request not found."
	end

	PlayerTemp[Player].OwnsCurrentParty = nil

	GlobalQueue.PublishAsync("PARTY_" .. JoinPlayer, {
		Joining = Player.UserId,
		From = game.JobId,
	})

	local Timeout = 15

	repeat
		Timeout -= task.wait(0.5)
	until PlayerTemp[Player].OwnsCurrentParty ~= nil or Timeout <= 0

	if PlayerTemp[Player].OwnsCurrentParty == nil then
		PlayerTemp[Player].OwnsCurrentParty = true
		return false, "Party request timed out."
	else
		return true
	end
end
