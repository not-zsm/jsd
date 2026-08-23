--== Imports ==--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Session  = require(script.Session)
local Event    = ReplicatedStorage.PlayerRemotes.Atonement:WaitForChild("Main")
local EventService = require(ReplicatedStorage.modules.shared.Utilities.EventService)

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

Event.OnServerEvent:Connect(function(player: Player, action: string, value: number?)
	local s = Module.Sessions[player]
	if not s then return end

	if action == "Damage" then
		s:ApplyDamage(value * DamageMultiplier)
	elseif action == "Complete" then
		s:RequestComplete()
	end
end)

--== Return ==--
return Module