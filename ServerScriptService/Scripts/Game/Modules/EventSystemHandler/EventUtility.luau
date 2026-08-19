local EventUtility = {}
EventUtility.__index = EventUtility

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicationRemotes = ReplicatedStorage.Remotes.Replication

local HostHandler = require( ServerScriptService.Scripts.HostHandler )

local Signal = require(ReplicatedStorage.Modules.Shared.Utilities.EventService)
local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )
local Maid = require( ReplicatedStorage.Packages.Maid )

function EventUtility.new(System)
	local self = setmetatable({}, EventUtility)
	self.Ended = Signal.new()
	self.System = System

	return self
end

function EventUtility:FireReliableVFX(Module : String, Function : String, ...)
	local ChosenEvent = math.random(1, ReplicationRemotes:GetAttribute("EventAmount"))
	local Event = ReplicationRemotes.Reliable:WaitForChild(ChosenEvent)
	Event:FireAllClients(Module, Function, ...)
end

function EventUtility:Announce(Title : String, Text : String, Type : String?)
	ReplicatedStorage.Remotes.Announcement:FireAllClients(Text, Title, Type)
end

function EventUtility:AnnounceToPlayer(Player : Player, Title : String, Text : String, Type : String?)
	ReplicatedStorage.Remotes.Announcement:FireClient(Player, Text, Title, Type)
end

function EventUtility:GetLuaPlayer(Player : Player)
	local LuaPlayer = LuaPlayerList.Get(Player)
	if (LuaPlayer == nil) then return end
	
	local LuaCharacter = LuaPlayer.Character
	
	return LuaPlayer, LuaCharacter
end

function EventUtility:RewardRandomEmote(Player : Player)
	if game.PrivateServerOwnerId ~= 0 or HostHandler.server.is_custom_server then return end
	
	local LuaPlayer, LuaCharacter = self:GetLuaPlayer(Player)
	
	LuaCharacter.Emotes:GetRandom("Give")
	self:AnnounceToPlayer(Player, "World Event - Reward", "You have been awarded 1 random emote for winning the event.", "Reward")
end


return EventUtility