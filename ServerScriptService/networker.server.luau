local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local info = require( ReplicatedStorage.info )
local network = require( ReplicatedStorage.modules.network )
local rateLimiter = require( ReplicatedStorage.modules.shared.Utilities.rateLimiter )

local LuaPlayerList = require( ServerStorage.modules.LuaPlayerList )

local function getCombat(Player : Player)
	local LuaPlayer = LuaPlayerList.LuaPlayers[Player]
	local LuaCharacter = LuaPlayer and LuaPlayer.Character

	return LuaCharacter and LuaCharacter.Combat
end

--// CLIENT -> SERVER
network.switchCharacter.listen(function(data, player)
	-- The icon picker sends the module name ("Chara"), the select screen sends the
	-- moveset key ("chara"). info.movesets is keyed by the latter.
	if not info.movesets[string.lower(data.character)] then return end
	if not rateLimiter.check(player, "switchCharacter", 10) then return end

	local Combat = getCombat(player)
	if not Combat then return end

	Combat:SwitchCharacter(data.character, data.icon)
end)

network.purchase.listen(function(data, player)
	if not rateLimiter.check(player, "purchase", 20) then return end

	local price = info.shopPrices.main[data.item]
	if not price then return end
	if data.count < 1 then return end

	-- There is no currency in player data yet, so nothing can be debited and
	-- nothing granted. Validated and logged until one exists.
	warn(`purchase: {player.Name} wants {data.count}x {data.item} for {price * data.count}`)
end)
