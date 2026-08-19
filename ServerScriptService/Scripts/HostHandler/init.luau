--[[
	aryghghhh is me gooner guy
]]

local MemoryStoreService = game:GetService("MemoryStoreService");
local MessagingService = game:GetService("MessagingService");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TeleportService = game:GetService("TeleportService");
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService");
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

------------------------------------------------------------------------------------------------

local ReverseMap = MemoryStoreService:GetHashMap("HostReserveToPrivate");
local HostServers = MemoryStoreService:GetSortedMap("HostServers");

local Replicated = ReplicatedStorage:WaitForChild("ServerBrowser");
local Remotes = Replicated:WaitForChild("Remotes");

------------------------------------------------------------------------------------------------

local Validation = require( Replicated.Validation )
local Signal = require( ReplicatedStorage.Packages.Signal )
local Server = require( script.Server )
local Hoster = require( script.Hoster )
local Types = require( script.Types )
local Utility = require( script.Utility )
local Settings = require( script.Settings );
local Whitelist = require( script.Whitelist );

------------------------------------------------------------------------------------------------

local HostHandler = {} :: Types.ClassHostHandler;
HostHandler.__index = HostHandler;

-- This is to make the servers list not update while there is no one actively looking at them.
-- Helps in not reaching the quota limits.
local function start_viewer_thread(self: Types.HostHandler)
	if tick() - self.last_refresh > Settings.REFRESH_TIME then
		self:refresh_servers();
	end
	
	while task.wait(Settings.REFRESH_TIME) do
		-- Skip refreshing servers if it was refreshed recently (I.E by a player)
		if tick() - self.last_refresh < (Settings.REFRESH_TIME // 1.50) then
			continue;
		end;
		
		self:refresh_servers();
	end;
end;

local function attempt_async(max_attempts: number, use_exponential_backoff: boolean?, async_call: (...any) -> (any), ...: any): any
	local attempts = 0;

	while attempts < max_attempts do
		attempts += 1;
		
		local success, server = pcall(async_call, ...);

		if success and server ~= nil then
			return server;
		end;
		
		-- Linear backoff
		task.wait(2 + attempts);
	end;
	
	if use_exponential_backoff then
		local backoff = 0;
		
		while backoff <= 128 do
			task.wait(backoff);
			
			-- Waiting times go from 8 -> 16 -> 32 -> 64 -> 128, until giving up.
			backoff = 2 ^ (attempts - max_attempts + 3);
			attempts += 1;
			
			local success, server = pcall(async_call, ...);

			if success and server ~= nil then
				return server;
			end;
		end
		
		warn(`Host Handler Critical Error: async call failure with exponential backoff, (attempts: {attempts}, max: {max_attempts})`)
	end
	
	return nil;
end;

------------------------------------------------------------------------------------------------

function HostHandler.new()
	local self = setmetatable(
		{
			server_list = {};
			client_server_list = {};
			server_cache = {};
			
			viewers = {};
			players = {};
			
			is_refreshing_servers = false;
			
			viewer_thread = nil;
			last_refresh = tick() - Settings.SPONTANEOUS_REFRESH_TIME // 2.0; -- So it won't instantly refresh on server startup.
			
			on_server_refresh = Signal.new();
		}, 
		HostHandler);
	
	self.server = Server.new(self);
	self:initialise();
	
	--self:delete_all_servers()
	
	return self;
end;

------------------------------------------------------------------------------------------------

function HostHandler:initialise()
	Players.PlayerRemoving:Connect(function(player)
		if self.viewers[player] then
			self:remove_viewer(player);
		end;
	end)
	
	Remotes.ViewerSubscribe.OnServerEvent:Connect(function(player)
		if player.Parent ~= Players then return end;
		
		self:add_viewer(player);
	end);
	
	Remotes.ViewerUnsubscribe.OnServerEvent:Connect(function(player)
		self:remove_viewer(player);
	end)
	
	Remotes.ModerateServer.OnServerEvent:Connect(function(player, access_code)
		local hoster = self.players[player];

		if hoster and hoster:has_administrative_permission() then
			hoster:delete_custom_server(access_code, { moderator = player.UserId });
		end 
	end)
	
	Remotes.ModerateUser.OnServerEvent:Connect(function(player, user_id, parameters)
		local hoster = self.players[player];
		local uid = tonumber(user_id);
		
		if uid and hoster then
			hoster:moderate_user(uid, parameters);
		end 
	end)
	
	Remotes.DeleteServer.OnServerEvent:Connect(function(player, access_code)
		local hoster = self.players[player];

		if hoster then
			hoster:delete_custom_server(access_code, { natural = true });
		end 
	end)
	
	Remotes.JoinServer.OnServerEvent:Connect(function(player, access_code: string)
		local hoster = self.players[player];
		
		if hoster then
			hoster:join_custom_server(access_code);
		end
	end)
	
	Remotes.EditServer.OnServerEvent:Connect(function(player, access_code: string, details: any)
		local hoster = self.players[player];

		if hoster then
			if hoster:throttle("edit", 15, 5) <= 0 then
				return;
			end;
			
			hoster:edit_custom_server(access_code, details);
		end
	end)
	
	function Remotes.RequestUserStatus.OnServerInvoke(player, user_id: string)
		local uid = tonumber(user_id);
		
		if uid then
			local hoster = self.players[player];

			if hoster and hoster:has_administrative_permission() then
				
				local success, result = pcall(Players.GetBanHistoryAsync, Players, uid);
				
				if success then
					local page = result:GetCurrentPage();
					local current_action = page[1] or { Ban = false };
					
					return {
						id = uid;
						is_banned = current_action.Ban;
					};
				end
			end ;
		end;
		
		return nil;
	end
	
	function Remotes.CreateServer.OnServerInvoke(player, info: Types.CustomServerSubmit)
		local hoster = self.players[player];
		
		if hoster then
			return hoster:create_custom_server(info);
		end 
	end;
	
	function Remotes.RequestServer.OnServerInvoke(player, access_code)
		local hoster = self.players[player];
		
		if hoster then
			if hoster:throttle("retrieve", 30, 1.50) <= 0 then
				return nil;
			end;
			
			return self:get_server_from_access_code(access_code, true);
		end;
	end;
	
	function Remotes.RequestServerList.OnServerInvoke(player, info: Types.CustomServerSubmit)
		local hoster = self.players[player];
		
		if hoster then
			if hoster:throttle("refresh", 120, 0.5) <= 0 then
				return nil;
			end;
			
			if tick() - self.last_refresh > Settings.SPONTANEOUS_REFRESH_TIME then
				local success, result = pcall(self.refresh_servers, self);
				
				if not success then
					warn("Host Handler Refresh Error:", result);
				end;
			end;
			
			return self.client_server_list;
		end;
		
		return {}
	end;
	
	function Remotes.RequestMyServers.OnServerInvoke(player)
		local hoster = self.players[player];
		
		if hoster then
			return  hoster:get_my_servers();
		end;
		
		return {};
	end
end

-- You must do this yourself elsewhere.
function HostHandler:remove_player(player: Player): ()
	if self.players[player] then
		self.players[player]:destroy();
		self.players[player] = nil;
	end
end

-- You must do this yourself elsewhere.
function HostHandler:add_player(player: Player, profile: any): ()
	if self.players[player] then return end;
	
	assert(profile, "No Profile was given");
	assert(profile.Data.Hosting, "Profile does not contain a 'Hosting' table");
	
	self.players[player] = Hoster.new(self, player, profile);
end

function HostHandler:generate_access_code(): string
	local code = HttpService:GenerateGUID(false);
	local access_code = string.sub(code, 1, 7);
	
	return access_code;
end

function HostHandler:generate_unique_access_code(): string
	local free_access_code = nil;
	local attempts = 0;
	
	while not free_access_code and attempts < Settings.ACCESS_CODE_GENERATE_ATTEMPTS do
		attempts += 1;
		
		local access_code = self:generate_access_code();
		local success, result = pcall(HostServers.GetAsync, HostServers, access_code);
		
		if success and result == nil then
			free_access_code = access_code;
			break;
		end;
		
		-- In reality a collision would be very rare.
		warn("Access Code Collision:", access_code);
		task.wait(2);
	end;
	
	return free_access_code;
end;

function HostHandler:get_server()
	return self.server;
end

function HostHandler:add_viewer(player: Player)
	self.viewers[player] = true;
	
	if not self.viewer_thread then
		self.viewer_thread = task.spawn(start_viewer_thread, self);
	end
end

function HostHandler:remove_viewer(player: Player)
	self.viewers[player] = nil;
	
	if not next(self.viewers) and self.viewer_thread then
		if coroutine.status(self.viewer_thread) == "suspended" then
			task.cancel(self.viewer_thread);
		end;
		
		self.viewer_thread = nil;
	end
end

function HostHandler.serialise_server_info(info)
	return info;
end

function HostHandler.deserialise_server_info(serial)
	return serial;
end;

function HostHandler.encode_safe_for_client(value)
	-- Exclude the reserve server id, we shouldn't expose that to the client.
	return {
		access_code = value.access_code;
		owner_id = value.owner_id;
		private_server_id = value.private_server_id;
		player_count = value.player_count,
		time = value.time;
		title = value.title;
		tier = value.tier;
	};
end

local function refresh_servers(self: Types.HostHandler): ()
	local items = self:get_servers_page(0);

	if items then
		local new_server_list = {};
		local new_client_server_list = {};

		for _, item in items do
			local key = item.key;
			local value = item.value;

			new_server_list[key] = value;
			new_client_server_list[key] = HostHandler.encode_safe_for_client(value);
		end;

		Utility.set_table(self.server_list, new_server_list);
		Utility.set_table(self.client_server_list, new_client_server_list);
	end;

	for player, hoster in self.players do
		hoster:retrieve_lost_servers();
	end;
end;

function HostHandler:refresh_servers()
	if self.is_refreshing_servers then return end;

	self:clear_stale_server_cache();

	self.last_refresh = tick();
	self.is_refreshing_servers = true;

	task.spawn(function()
		local success, result = pcall(refresh_servers, self);

		if not success then
			warn("Host Handler Regenerate Server List Error:", result);
		end;

		self.is_refreshing_servers = false;
		self.on_server_refresh:Fire();

		for player in self.viewers do
			Remotes.NotifyServerRefresh:FireClient(player);
		end;
	end)
end;

--local function regenerate_server_list_table(self: Types.HostHandler): ()
--	local items = self:get_servers_page(0);

--	if items then
--		local new_server_list = {};
--		local new_client_server_list = {};

--		for _, item in items do
--			local key = item.key;
--			local value = item.value;

--			new_server_list[key] = value;
--			new_client_server_list[key] = HostHandler.encode_safe_for_client(value);
--		end;

--		Utility.set_table(self.server_list, new_server_list);
--		Utility.set_table(self.client_server_list, new_client_server_list);
--	end;

--	for player, hoster in self.players do
--		hoster:retrieve_lost_servers();
--	end;
--end;

--function HostHandler:refresh_servers()
--	if self.is_refreshing_servers then return end;

--	self:clear_stale_server_cache();

--	self.last_refresh = tick();
--	self.is_refreshing_servers = true;

--	local success, result = pcall(regenerate_server_list_table, self);

--	if not success then
--		warn("Host Handler Regenerate Server List Error:", result);
--	end;

--	self.is_refreshing_servers = false;
--	self.on_server_refresh:Fire();

--	for player in self.viewers do
--		Remotes.NotifyServerRefresh:FireClient(player);
--	end;
--end;

--function HostHandler:refresh_servers()
--	if self.is_refreshing_servers then return end;
	
--	self:clear_stale_server_cache();
	
--	local previous_refresh = self.last_refresh;
	
--	self.is_refreshing_servers = true;
--	self.last_refresh = tick();
	
--	local items = self:get_servers_page(0);
	
--	if items then
--		local new_server_list = {};
--		local new_client_server_list = {};
		
--		for _, item in items do
--			local key = item.key;
--			local value = item.value;
			
--			new_server_list[key] = value;
--			new_client_server_list[key] = HostHandler.encode_safe_for_client(value);
--		end;
			
--		Utility.set_table(self.server_list, new_server_list);
--		Utility.set_table(self.client_server_list, new_client_server_list);
--	end;
	
--	for player, hoster in self.players do
--		hoster:retrieve_lost_servers();
--	end;
	
--	self.is_refreshing_servers = false;
--	self.on_server_refresh:Fire();
	
--	for player in self.viewers do
--		Remotes.NotifyServerRefresh:FireClient(player);
--	end;
--end

function HostHandler:set_server_access_code(access_code: string, info: any)
	local serialised = HostHandler.serialise_server_info(info);
	local success, result = pcall(HostServers.SetAsync, HostServers, access_code, serialised, Settings.SERVER_EXPIRY, 0);

	return success;
end

function HostHandler:reserve_server(access_code: string)
	assert(access_code, "No access code");
	
	local success, reserved_code, private_server_id = pcall(TeleportService.ReserveServer, TeleportService, game.PlaceId);
	
	if RunService:IsStudio() then
		local digit = math.random(0, 999);
		success, reserved_code, private_server_id = true, "JAL9AA" .. digit, "KLtwAHJFfafBNFfn8371khg2895" .. digit;
	end
	
	if success then
		-- This is the only way you can give the reserved server its own AccessCode.
		local access_information = {access_code, reserved_code};
		local success2, err = pcall(ReverseMap.SetAsync, ReverseMap, private_server_id, access_information, Settings.RESERVE_MAP_EXPRIY);
		
		if success2 then
			return reserved_code, private_server_id;
		else
			return nil, nil, "Could not reserve new server with the given reserve code, try again.";
		end;
	else
		return nil, nil, "Could not reserve a new server.";
	end;
end

function HostHandler:try_get_access_information(private_server_id: string): {string}?
	local max_attempts = 3;
	local access_information =  attempt_async(max_attempts, true, HostHandler.get_access_information, self, private_server_id);

	if access_information then
		return access_information;
	end;

	warn(`Host Server Retry Failure: max attempts reached ({max_attempts})`);
	
	return nil;
end

function HostHandler:get_access_information(private_server_id: string): {string}?
	local success, access_information = pcall(ReverseMap.GetAsync, ReverseMap, private_server_id);
	
	if success then
		return access_information;
	end;
	
	return nil;
end

function HostHandler:get_private_server_id_from_access_code(access_code: string): string?
	local info = self:get_server_from_access_code(access_code, true);
	
	if info then
		return info.private_server_id;
	end;
	
	return nil;
end

function HostHandler:remove_access_code_map(private_server_id: string): boolean
	local success = pcall(ReverseMap.RemoveAsync, ReverseMap, private_server_id);
	
	return success;
end;

function HostHandler:update_custom_server(access_code: string, new_details: any): ()
	if not access_code then
		return warn("No access code was given");
	end;
	
	local function update_async(value: any, sort_key: number): ()
		assert(value, `Access code {access_code} is invalid`);
		
		local changed = false;

		for key, element in value do
			local counter = new_details[key];

			if counter ~= nil and typeof(element) == typeof(counter) then
				changed = true;
				value[key] = counter;
			end;
		end;

		if changed then
			return value, value.player_count;
		end;
		
		return nil;
	end
	
	local success, info, sort_key = pcall(HostServers.UpdateAsync, HostServers, access_code, update_async, Settings.SERVER_EXPIRY);
	
	if not success then
		warn(info);
	end;
end;

function HostHandler:update_custom_server_player_count(access_code: string, new_player_count: number): ()
	return self:update_custom_server(access_code, {player_count = new_player_count});
end;

-- Does not validate the given info, please do that before if this was submitted by a player.
-- Returns the access code, if it fails, will return the error in the second return.
function HostHandler:create_custom_server(player: Player, info: Types.CustomServerInfo): (string?, string?)
	local access_code = self:generate_unique_access_code();
	
	if access_code then
		local reserved_code, private_server_id, err = self:reserve_server(access_code);
		
		if reserved_code then
			local success = self:set_server_access_code(access_code, {
				owner_id = player.UserId;
				access_code = access_code;
				private_server_id = private_server_id;
				reserve_code = reserved_code;
				player_count = 0,
				time = DateTime.now().UnixTimestamp;
				title = info.title or "",
				tier = info.tier or 0;
			});
			
			if success then
				return access_code;
			end;
		else
			return nil, err;
		end;
	end;
	
	return nil, "Could not create custom server"
end

-- If you supply a PrivateServerId, this function will not contribute to the GetAsync quota.
function HostHandler:delete_custom_server(access_code: string, private_server_id: string?, parameters: any): ()
	local private_server_id = private_server_id or self:get_private_server_id_from_access_code(access_code);
	
	if private_server_id then
		if not parameters then
			parameters = {};
		end;
		
		local shutdown_message = Server.serialise_server_message{
			shutdown = true, 
			moderater = parameters.moderater;
		};
		
		MessagingService:PublishAsync(`CustomServer-{private_server_id}`, shutdown_message);
		
		local success, err = pcall(HostServers.RemoveAsync, HostServers, access_code)
		
		if not success then
			warn("Host Server Remove Error:", err);
		end;
		
		self.server_cache[access_code] = nil;
		self.server_list[access_code] = nil;
	end;
end

function HostHandler:delete_all_servers()
	local min_bound = nil;
	
	while self do
		local items = HostServers:GetRangeAsync(Enum.SortDirection.Ascending, 100, min_bound)

		for _, item in ipairs(items) do
			self:delete_custom_server(item.key, HostHandler.deserialise_server_info(item.value).private_server_id);
		end
		
		if #items < 100 then
			break;
		end;

		min_bound = { key = items[#items].key, sortKey = items[#items].sortKey };
	end;
end;

function HostHandler:clear_stale_server_cache()
	local time_now = tick();
	
	for access_code, cache_info in self.server_cache do
		if time_now - cache_info.time > Settings.SERVER_CACHE_INVALIDATION_TIME then
			self.server_cache[access_code] = nil;
		end;
	end;
end

function HostHandler:get_server_from_cached(access_code: string)
	self:clear_stale_server_cache();
	
	local directly_cached = self.server_cache[access_code];
	
	if directly_cached then
		return directly_cached.value;
	end;
	
	return nil;
end;

function HostHandler:try_get_server_from_access_code(access_code: string, use_cache: boolean?): ()
	local max_attempts = 3;
	local server = attempt_async(max_attempts, true, HostHandler.get_server_from_access_code, self, access_code, use_cache);
	
	if server then
		return server;
	end;
	
	warn(`Host Server Retry Failure: max attempts reached ({max_attempts})`);
	
	return nil;
end

function HostHandler:get_server_from_access_code(access_code: string, use_cache: boolean?)
	if use_cache then
		local server = self:get_server_from_cached(access_code);
		
		if server then
			return server;
		end;
	end;
	
	local success, result = pcall(HostServers.GetAsync, HostServers, access_code);
	
	if success then
		local server = HostHandler.deserialise_server_info(result);
		local time_now = tick();
		
		self.server_cache[access_code] = { time = time_now, value = server };
		
		return server;
	end;
	
	warn("Host Server Error:", result);
	
	return nil;
end;

function HostHandler:get_servers_page()
	local success, result = pcall(HostServers.GetRangeAsync, HostServers, Enum.SortDirection.Descending, Settings.MAX_SERVERS_DISPLAYED)
	
	if success then
		self:clear_stale_server_cache();
		
		local access_code_list = {};
		local time_now = tick();
		
		for _, data_key in result do
			local server = data_key.value;
			
			if not server or not server.access_code then
				continue;
			end;
			
			-- Add to the server cache if not already in.
			if not self.server_cache[server.access_code] then
				self.server_cache[server.access_code] = { time = time_now, value = server };
			end;
			
			access_code_list[server.access_code] = server;
		end;
		
		for _, hoster in self.players do
			for _, server in hoster:get_raw_data_list() do
				if not server.access_code or access_code_list[server.access_code] then
					continue
				end
				
				--if access_code_list[server.access_code] then
				--	continue;
				--end;
				
				-- Forces into server cache, as it was not returned in the GetRangeAsync.
				self:get_server_from_access_code(server.access_code, true);
			end;
		end;
		
		if self.server.access_code and not access_code_list[self.server.access_code] then
			-- This will insert the current server into the server cache, which is processed next.
			-- Forces into server cache, as it was not returned in the GetRangeAsync.
			self:get_server_from_access_code(self.server.access_code, true);
		end;
		
		-- Adds anything that isn't in the server cache into the returned result.
		for access_code, cache_info in self.server_cache do
			if not access_code_list[access_code] and cache_info.value then
				table.insert(result, { key = access_code, sortKey = cache_info.value.player_count or 0, value = cache_info.value });
			end;
		end;
		
		-- For testing purposes, picks a random server to be the current server.
		if RunService:IsStudio() and #result > 0 then
			local random_server = result[math.random(#result)];

			if random_server and not Replicated.ServerStatus:GetAttribute("AccessCode") then
				Replicated.ServerStatus:SetAttribute("AccessCode", random_server.key);
				task.wait(0.1);
			end;
		end;
		
		return result;
	end;
	
	warn("Host Server Error:", result);
	return nil;
end

------------------------------------------------------------------------------------------------

table.freeze(HostHandler);

return HostHandler.new();