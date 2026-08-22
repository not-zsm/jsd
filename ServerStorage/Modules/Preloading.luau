local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )

local Preloading = {}
local PlayersUsing = {}

function Preloading.Add(Player : Player, Item : Folder | Animation)
	PlayersUsing[Item] = PlayersUsing[Item] or {}
	
	PlayersUsing[Item][Player] = true
	Item:AddTag("InUse")
end

function Preloading.Remove(Player : Player, Item : Folder | Animation)
	if (PlayersUsing[Item] == nil) then return end
	
	PlayersUsing[Item][Player] = nil
	
	if Utility.TableCount(PlayersUsing[Item]) == 0 then
		Item:RemoveTag("InUse")
		PlayersUsing[Item] = nil
	end
end

Players.PlayerRemoving:Connect(function(PlayerLeaving)
	for Item, Player in PlayersUsing do
		if PlayerLeaving == Player then
			Preloading.Remove(PlayerLeaving, Item)
		end
	end
end)

return Preloading
