local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local EventService = require( replicatedStorage.modules.shared.Utilities.EventService )

local LuaPlayerList = {}
LuaPlayerList.LuaPlayers = {}
LuaPlayerList.OnLuaPlayerChanged = EventService.new()

--[[
	Gets the LuaPlayer associated with the given source.
	Source can be any of the following:
	 - Player Instance
	 - Player's UserId
	 - Character Model
	 - Character's Humanoid
]]
function LuaPlayerList.Get(Source : Instance | number): any
	if Source then
		if typeof(Source) == "number" then
			return LuaPlayerList.Get( Players:GetPlayerByUserId(Source) );
			
		elseif Source:IsA("Player") then
			return LuaPlayerList.LuaPlayers[Source];
			
		elseif Source:IsA("Model") then
			return LuaPlayerList.LuaPlayers[Players:GetPlayerFromCharacter(Source) or Source]
			
		elseif Source:IsA("Humanoid") then
			return LuaPlayerList.Get(Source.Parent)
		end;
	end;
	
	warn(`Unable to get LuaPlayer, source was not a valid type (got value {Source}): {debug.traceback()}`);
	
	return nil;
end;

--[[
	Waits for the LuaPlayer associated with the given source.
	Source can be any of the following:
	 - Player Instance
	 - Player's UserId
	 - Character Model
	 - Character's Humanoid
]]
function LuaPlayerList.WaitFor(Source: Instance | number): any
	local LuaPlayer = LuaPlayerList.Get(Source);

	if LuaPlayer then
		return LuaPlayer;
	end;

	local ThreadWaiting = coroutine.running();
	local Connection;
	
	Connection = LuaPlayerList.OnLuaPlayerChanged:Connect(function(_, HasJoined)
		if HasJoined then
			local LuaPlayer = LuaPlayerList.Get(Source);

			if LuaPlayer then
				Connection:Disconnect();
				coroutine.resume(ThreadWaiting, LuaPlayer);
			end;
		end;
	end);
	
	return coroutine.yield();
end;

function LuaPlayerList.Add(LuaPlayer)
	if (LuaPlayerList.LuaPlayers[LuaPlayer.Player] == nil) then
		LuaPlayerList.LuaPlayers[LuaPlayer.Player] = LuaPlayer
		LuaPlayerList.OnLuaPlayerChanged:Fire(LuaPlayer, true)
	end
end

function LuaPlayerList.Remove(LuaPlayer)
	if (LuaPlayerList.LuaPlayers[LuaPlayer.Player] ~= nil) then
		LuaPlayerList.OnLuaPlayerChanged:Fire(LuaPlayer, false)
		LuaPlayerList.LuaPlayers[LuaPlayer.Player] = nil
	end
end

table.freeze(LuaPlayerList);

return LuaPlayerList
