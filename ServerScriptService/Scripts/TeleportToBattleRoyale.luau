local TeleportService = game:GetService("TeleportService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Teleport = {}
local ID = 78271377586096

local DataStore = DataStoreService:GetGlobalDataStore()
local ServerCode = DataStore:GetAsync("BattleRoyaleServer")

if typeof(ServerCode) ~= "string" then
	ServerCode = TeleportService:ReserveServer(ID)
	DataStore:SetAsync("BattleRoyaleServer", ServerCode)
end

function Teleport.Player(Player : Player)
	TeleportService:TeleportToPrivateServer(ID, ServerCode, {Player})
end

return Teleport