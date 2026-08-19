local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getFunction(str)
	for i,v in script:GetChildren() do
		if v.Name:lower() == str:lower() then
			return v
		end
	end
end

ReplicatedStorage.Remotes.Commands.Respawn.OnClientEvent:Connect(function()
	SoundService.NPC.Respawn:Play()
end)

ReplicatedStorage.Remotes.RemoveMicrophone.OnClientEvent:Connect(function(Emitter)
	Emitter:Destroy()
end)

ReplicatedStorage.Remotes.Ranked.UI.OnClientEvent:Connect(function(Data: string) 
	local Module = getFunction(Data)
	if Module then
		Module = require(Module)
	end

	if typeof(Module) ~= "table" then return end

	local New = Module.New({})

	New:Track()
	New:Fire()
end)