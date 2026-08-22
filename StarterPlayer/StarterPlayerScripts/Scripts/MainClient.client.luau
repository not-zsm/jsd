--[[
	The client's entry point.

	Everything the client starts is a system registered on MainClient, which
	owns the order and isolates failures. Add a game's own systems here, before
	Start.
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local MainClient = require(ReplicatedStorage:WaitForChild("Client"):WaitForChild("Main"))

MainClient.Default():Start()
