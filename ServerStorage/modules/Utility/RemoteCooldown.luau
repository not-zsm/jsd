local RemoteAntiSpam = {}
local Cooldowns = {}

function RemoteAntiSpam.CanFire(Player : Player)
	return (Cooldowns[Player] == nil)
end

function RemoteAntiSpam.Cooldown(Player : Player)
	if (Cooldowns[Player] ~= nil) then return end
	
	Cooldowns[Player] = true
	
	task.delay(1, function()
		Cooldowns[Player] = nil
	end)
end

function RemoteAntiSpam.OnServerEvent(Remote : RemoteEvent, Callback : (Player, any) -> ())
	local Connection : RBXScriptConnection;
	
	Connection = Remote.OnServerEvent:Connect(function(Player, ...)
		if RemoteAntiSpam.CanFire(Player) then
			RemoteAntiSpam.Cooldown(Player)
			Callback(Player, ...)
		end
	end)
	
	return Connection
end

return RemoteAntiSpam
