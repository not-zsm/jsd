--- ClientEffects, was a LocalScript under StarterPlayerScripts. Body unchanged.
return {
	Name = "ClientEffects",
	Priority = 100,
	Async = true,

	Start = function()
		local TweenService = game:GetService("TweenService")
		local Players = game:GetService("Players")
		local SoundService = game:GetService("SoundService")
		local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )

		local function getFunction(str)
			for i,v in script:GetChildren() do
				if v.Name:lower() == str:lower() then
					return v
				end
			end
		end

		network.respawn.listen(function()
			SoundService.NPC.Respawn:Play()
		end)

		network.removeMicrophone.listen(function(Emitter)
			Emitter:Destroy()
		end)

		replicatedStorage.Remotes.Ranked.UI.OnClientEvent:Connect(function(Data: string) 
			local Module = getFunction(Data)
			if Module then
				Module = require(Module)
			end

			if typeof(Module) ~= "table" then return end

			local New = Module.New({})

			New:Track()
			New:Fire()
		end)
	end,
}
