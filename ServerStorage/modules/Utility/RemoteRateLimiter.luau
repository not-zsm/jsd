local RemoteRateLimiter = {}
local Cooldowns = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local network = require( ReplicatedStorage.modules.network )
local Remotes = ReplicatedStorage.Remotes

function RemoteRateLimiter.Check(Remote : RemoteEvent, Player : Player, Rate : number)
	if Cooldowns[Player] == nil then
		Cooldowns[Player] = {}
		Player.AncestryChanged:Once(function() Cooldowns[Player] = nil end)
	end

	if (Cooldowns[Player][Remote] == nil) then
		Cooldowns[Player][Remote] = {}
	end
	
	if Cooldowns[Player][Remote].Count then
		local TimeElapsed = tick() - Cooldowns[Player][Remote].Time

		if TimeElapsed >= 1 then
			return RemoteRateLimiter.ResetRemoteLimit(Remote, Player)
		else
			if Cooldowns[Player][Remote].Count >= Rate then
				Cooldowns[Player][Remote].Time = tick()
				
				if tick() - Cooldowns[Player][Remote].NotificationTime >= 0.5 then
					Cooldowns[Player][Remote].NotificationTime = tick()
					
					network.notify.sendTo({
						Title = "Notification",
						Text = `You have been rate limited on {Remote.Name}, please slow down your clicks.`,
						Duration = 1,
					}, Player)
				end
				
				return false
			end
			
			Cooldowns[Player][Remote].Count += 1
			return true
		end
	else
		return RemoteRateLimiter.ResetRemoteLimit(Remote, Player)
	end
end

function RemoteRateLimiter.ResetRemoteLimit(Remote : RemoteEvent, Player : Player)
	if Cooldowns[Player] and Cooldowns[Player][Remote] then 
		Cooldowns[Player][Remote].Count = 1
		Cooldowns[Player][Remote].Time = tick()
		Cooldowns[Player][Remote].NotificationTime = -1

		return true
	end
	
	return false
end

return RemoteRateLimiter
