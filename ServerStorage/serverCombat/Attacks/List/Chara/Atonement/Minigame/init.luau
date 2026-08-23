--== Imports ==--
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local Players           = game:GetService("Players")

local Session  = require(script.Session)
local EventService = require(replicatedStorage.modules.shared.Utilities.EventService)

--== Module ==--
local Module = {}
Module.__index = Module

Module.Sessions = {} :: { [Player]: any }

local DamageMultiplier = 1.65

--== Public ==--
function Module.Start(player: Player)
	print("Started Session")
	
	if Module.Sessions[player] then return end
	
	local EndSignal = EventService.new()

	Module.Sessions[player] = Session.new(player, function(p: Player, _reason: string, who)
		if Module.Sessions[p] == who then
			if _reason == "fail" or _reason == "success" then
				EndSignal:Fire(p, _reason)
				EndSignal:Destroy()
			end

			Module.Sessions[p] = nil
		end
	end)
	
	return EndSignal
end

function Module.Stop(player: Player, reason: string?)
	print("Stopped Session")
	
	local s = Module.Sessions[player]
	if not s then return end
	s:Finish(reason or "server_stop")
end

--== Hooks ==--
Players.PlayerRemoving:Connect(function(player: Player)
	local s = Module.Sessions[player]
	if s then
		s:Finish("leaving")
	end
end)

network.minigameInput.listen(function(data, player)
	local s = Module.Sessions[player]
	if not s then return end

	if data.action == "Damage" then
		if not data.value then return end
		s:ApplyDamage(data.value * DamageMultiplier)
	elseif data.action == "Complete" then
		s:RequestComplete()
	end
end)

--== Return ==--
return Module