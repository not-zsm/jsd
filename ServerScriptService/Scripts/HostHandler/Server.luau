--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService");
local Players = game:GetService("Players")

------------------------------------------------------------------------------------------------

local Settings = require("./Settings");
local Types = require(script.Parent.Types);

local Signal = require( ReplicatedStorage.Packages.Signal )
local Shared = ReplicatedStorage.ServerBrowser;

local Utility = require( Shared.Utility );

------------------------------------------------------------------------------------------------

local Server = {} :: Types.ClassServer;
Server.__index = Server;

function Server.new(HostHandler)
	local self = setmetatable(
		{
			host_handler = HostHandler;
			
			access_code = nil;
			reserved_server_code = nil;
			owner_id = nil;
			
			is_waiting_for_access_code = false;
			is_updating_player_count = false;
			is_shutdown = false; -- If players are prevented from joining.
			is_custom_server = false;
			is_non_custom_reserve = false;
			join_status = {}; -- The custom server data the moment someone has joined, this is never updated again.
			
			_keep_alive_thread = nil;
			_last_expiry_update = -math.huge;
			_access_code_get_attempts = 0;
			
			on_custom_status_ready = Signal.new(), -- Fires when an access code is found in the custom server itself. Use this to wait for 'owner_id'
		}, 
		Server);
	
	self:initialise();
	
	return self;
end;

------------------------------------------------------------------------------------------------

function Server.serialise_server_message(data)
	return data;
end

function Server.deserialise_server_message(data)
	return data;
end

function Server:initialise()
	-- Having an access code should mean this server is a custom server.
	task.spawn(function()
		local access_code = self:get_access_code();
		
		if access_code  then
			self:initialise_as_custom_server();
		end;
	end);
end;

function Server:get_shutdown_message_from(subscription_data)
	if subscription_data.shutdown_message then
		return subscription_data.shutdown_message
	else
		if subscription_data.moderator then
			local identifier = Utility.get_user_identifer(subscription_data.moderator);

			return `This custom server has been moderated by {identifier}.`;

		elseif subscription_data.natural then
			local identifier = Utility.get_user_identifer(self.owner_id);

			return `This custom server has been shutdown by its owner {identifier}.`;
		else
			return "This custom server has been shutdown.";
		end;
	end;
end

function Server:initialise_as_custom_server()
	MessagingService:SubscribeAsync(`CustomServer-{game.PrivateServerId}`, function(message)
		local data = Server.deserialise_server_message(message.Data);
		local sent: number = message.Sent;

		if data.shutdown then
			self.shutdown_message = self:get_shutdown_message_from(data);
			self.is_shutdown = true;

			for _, player in Players:GetPlayers() do
				player:Kick(self.shutdown_message);
			end;
		end;
	end);
	
	Players.PlayerAdded:Connect(function(player)
		if self.is_shutdown then
			return player:Kick(self.shutdown_message);
		end;

		self:batch_update_player_count(1);
	end);

	Players.PlayerRemoving:Connect(function(player)
		if self.is_shutdown then
			return;
		end;

		self:batch_update_player_count(-1);
	end);
	
	task.spawn(self.batch_update_player_count, self, 1);

	game:BindToClose(function(close_reason)
		if self.access_code then
			self.host_handler:delete_custom_server(self.access_code, game.PrivateServerId);
			task.wait(2);
		end;
	end);
end

function Server:keep_custom_server_alive()
	while self do
		task.wait(Settings.BATCH_PLAYER_COUNT_TIME)

		local time_now = tick();
		
		-- Check if custom server is about to reach its MemoryStore expiry date.
		if self.access_code and time_now - self._last_expiry_update > (Settings.SERVER_EXPIRY * 0.90 - Settings.BATCH_PLAYER_COUNT_TIME) then
			self._last_expiry_update = tick();
			self.host_handler:update_custom_server_player_count(self.access_code, #Players:GetPlayers());
		end;
	end;
end

function Server:batch_update_player_count(change_value: number): ()
	if self.is_updating_player_count or self.is_shutdown then return end;
	
	-- Retry getting the access code if somehow it failed before.
	task.spawn(self.get_access_code, self);
	
	-- Player count before PlayerAdded / PlayerRemoving fired
	local pre_player_count = #Players:GetPlayers() - change_value;
	
	self.is_updating_player_count = true;
	task.wait(Settings.BATCH_PLAYER_COUNT_TIME);	
	self.is_updating_player_count = false;
	
	-- Player count after a period of time.
	local post_player_count = #Players:GetPlayers();
	
	-- If player count somehow matches what it was (someone left/joined during the period of time), don't update to preserve quota.
	if self.access_code and (pre_player_count ~= post_player_count) then
		self._last_expiry_update = tick();
		self.host_handler:update_custom_server_player_count(self.access_code, post_player_count);
	end;
	
	if not self._keep_alive_thread then
		self._keep_alive_thread = task.spawn(self.keep_custom_server_alive, self);
	end;
end
 
function Server:bind_to_access_code(callback)
	if self.access_code then
		task.spawn(callback, self.access_code);
	else
		task.defer(self.get_access_code, self);
		
		return self.on_custom_status_ready:Once(function()
			return callback(self.access_code :: any);
		end)
	end;
	
	return nil;
end

function Server:_try_get_access_code()
	local access_information: {string}?;

	if self._access_code_get_attempts >= Settings.MAX_ACCESS_CODE_ATTEMPTS then
		warn(`Could not retrieve access code from reserved server, attempts {self._access_code_get_attempts} / {Settings.MAX_ACCESS_CODE_ATTEMPTS}`);
	else
		access_information = self.host_handler:try_get_access_information(game.PrivateServerId);
	end;

	self._access_code_get_attempts += 1;

	if access_information then
		local access_code: string = access_information[1];
		local reserved_server_code: string = access_information[2];

		self.is_custom_server = true;
		self.access_code = access_code;
		self.reserved_server_code = reserved_server_code;

		-- Let it expire, doesn't use quotas that way (as long as total storage isn't exceeded)
		-- self.host_handler:remove_access_code_map(game.PrivateServerId);

		local server_information = self.host_handler:try_get_server_from_access_code(access_code, true);

		self.join_status = server_information;
		self.owner_id = server_information.owner_id;

		Shared.ServerStatus:SetAttribute("AccessCode", access_code);

		self.on_custom_status_ready:Fire();
		
		return access_code;
	end;
	
	return nil;
end

function Server:get_access_code(): string?
	if self.access_code then
		return self.access_code;
	end;
	
	if self.is_waiting_for_access_code then
		return nil;
	end;
	
	if self:get_type() == "Reserved" and not self.is_non_custom_reserve then
		self.is_waiting_for_access_code = true;
		
		local success, access_code = pcall(self._try_get_access_code, self);
		
		self.is_waiting_for_access_code = false;
		
		if not success or not access_code then
			warn("Host Access Code Get Failure:", access_code);
			
			-- Never retry getting custom server again, because reserved may not be an actual custom server (Ranked)
			self.is_non_custom_reserve = true;
		end;
	end;
	
	return self.access_code;
end

function Server:get_type(): Types.ServerType
	if game.PrivateServerId ~= "" and not shared.IsRankedPlace then
		if game.PrivateServerOwnerId ~= 0 then
			return "Private";
		else
			return "Reserved";
		end
	else
		return "None";
	end
end

------------------------------------------------------------------------------------------------

table.freeze(Server);

return Server;