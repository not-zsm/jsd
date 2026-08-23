if not game:IsLoaded() then
	game.Loaded:Wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = ReplicatedStorage.Client

local MovementReplicator = ReplicatedStorage:WaitForChild("MovementReplicator", 100)
local ClientReplicator = MovementReplicator:WaitForChild("ClientReplicator", 100)

require(ClientReplicator)
require(Player).new()

local DonationBoardClient = ReplicatedStorage:WaitForChild("DonationBoardClient", 100)

if DonationBoardClient then
	require(DonationBoardClient)
end