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

		network.respawn.listen(function()
			SoundService.NPC.Respawn:Play()
		end)

		network.removeMicrophone.listen(function(Emitter)
			Emitter:Destroy()
		end)
	end,
}
