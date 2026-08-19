if not game:IsLoaded() then
	game.Loaded:Wait()
end

if workspace:GetAttribute("IsRankedLobby") then
	script.ClientUIHandler.Enabled = true
end

if workspace:GetAttribute("IsRankedLobby") or workspace:GetAttribute("IsRankedPlace") then
	script.Weather.Enabled = false
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules", 100)
local Player = Modules:WaitForChild("Player", 100)

local MovementReplicator = ReplicatedStorage:WaitForChild("MovementReplicator", 100)
local ClientReplicator = MovementReplicator:WaitForChild("ClientReplicator", 100)

require(ClientReplicator)
require(Player).new()

local DonationBoardClient = ReplicatedStorage:WaitForChild("DonationBoardClient", 100)

if DonationBoardClient then
	require(DonationBoardClient)
end