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

local function getData(Player : Player)
	local LuaPlayer = LuaPlayerList.LuaPlayers[Player]
	local Data = LuaPlayer and LuaPlayer.Data

	return Data and Data.Profile and Data or nil
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

network.toggleSetting.listen(function(data, player)
	if not rateLimiter.check(player, "toggleSetting", 20) then return end

	local Data = getData(player)
	if not Data then return end

	Data:ToggleSetting(data.setting)
end)

network.sliderSetting.listen(function(data, player)
	if not rateLimiter.check(player, "sliderSetting", 20) then return end
	if data.value ~= data.value then return end

	local Data = getData(player)
	if not Data then return end

	Data:SetSliderSetting(data.setting, data.value)
end)

network.stringSetting.listen(function(data, player)
	if not rateLimiter.check(player, "stringSetting", 20) then return end

	local Data = getData(player)
	if not Data then return end

	Data:SetStringSetting(data.setting, data.value)
end)

--// movement and input the client reports about itself
local function onCombat(key : string, rate : number, apply : (any, any) -> ())
	return function(data, player)
		if not rateLimiter.check(player, key, rate) then return end

		local Combat = getCombat(player)
		if not Combat then return end

		apply(Combat, data)
	end
end

network.clientLanded.listen(onCombat("clientLanded", 30, function(Combat)
	Combat:OnClientLanded()
end))

network.clientJumped.listen(onCombat("clientJumped", 30, function(Combat)
	Combat:OnClientJumped()
end))

network.dashProximity.listen(onCombat("dashProximity", 5, function(Combat)
	Combat:OnDashProximity()
end))

network.spaceHeld.listen(onCombat("spaceHeld", 30, function(Combat, held)
	Combat:SetSpaceHeld(held)
end))

network.airState.listen(onCombat("airState", 30, function(Combat, state)
	Combat:SetAirState(state)
end))

network.currentDevice.listen(onCombat("currentDevice", 5, function(Combat, device)
	Combat:SetDevice(device)
end))

network.useMove.listen(function(data, player)
	if not rateLimiter.check(player, "useMove", 30) then return end

	local Combat = getCombat(player)
	local Actions = Combat and Combat.Actions
	if not Actions then return end

	Actions:UseMove(data.move, data.state, data.extra)
end)

network.tryReset.listen(function(_, player)
	if not rateLimiter.check(player, "tryReset", 5) then return end

	local LuaPlayer = LuaPlayerList.LuaPlayers[player]
	local LuaCharacter = LuaPlayer and LuaPlayer.Character
	if not LuaCharacter then return end

	LuaCharacter:TryReset()
end)

--// titles
local function getTitle(Player : Player)
	local LuaPlayer = LuaPlayerList.LuaPlayers[Player]
	local LuaCharacter = LuaPlayer and LuaPlayer.Character

	return LuaCharacter and LuaCharacter.Title
end

network.equipTitle.listen(function(name, player)
	if not rateLimiter.check(player, "equipTitle", 5) then return end

	local Title = getTitle(player)
	if not Title then return end

	Title:Equip(name)
end)

network.unequipTitle.listen(function(_, player)
	if not rateLimiter.check(player, "unequipTitle", 10) then return end

	local Title = getTitle(player)
	if not Title then return end

	Title:Unequip()
end)

--// emotes
local function getEmotes(Player : Player)
	local LuaPlayer = LuaPlayerList.LuaPlayers[Player]
	local LuaCharacter = LuaPlayer and LuaPlayer.Character

	return LuaCharacter and LuaCharacter.Emotes
end

local function onEmotes(key : string, rate : number, apply : (any, any) -> ())
	return function(data, player)
		if not rateLimiter.check(player, key, rate) then return end

		local Emotes = getEmotes(player)
		if not Emotes then return end

		apply(Emotes, data)
	end
end

network.useEmote.listen(onEmotes("useEmote", 15, function(Emotes, emote)
	Emotes:UseEmote(emote)
end))

network.claimEmote.listen(onEmotes("claimEmote", 15, function(Emotes)
	Emotes:ClaimEmote()
end))

network.buyRandomEmote.listen(onEmotes("buyRandomEmote", 15, function(Emotes)
	Emotes:BuyRandom()
end))

network.buyEmoteSlots.listen(onEmotes("buyEmoteSlots", 15, function(Emotes)
	Emotes:BuySlots()
end))

network.buyLimitedEmote.listen(onEmotes("buyLimitedEmote", 15, function(Emotes, name)
	Emotes:BuyLimited(name)
end))

network.setEmoteSlot.listen(onEmotes("setEmoteSlot", 5, function(Emotes, data)
	Emotes:SetSlot(data.slot, data.emote)
end))
