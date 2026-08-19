local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService");
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

------------------------------------------------------------------------------------------------

local Replicated = ReplicatedStorage:WaitForChild("ServerBrowser");
local Remotes = Replicated:WaitForChild("Remotes");

------------------------------------------------------------------------------------------------

local Types = require("./Types");
local Utility = require("./Utility");
local Whitelist = require("./Whitelist");
local Settings = require("./Settings");

------------------------------------------------------------------------------------------------

local Validation = require( ReplicatedStorage.ServerBrowser.Validation )

------------------------------------------------------------------------------------------------

local Hoster = {} :: Types.ClassHoster;
Hoster.__index = Hoster;

function Hoster.new(host_handler, player: Player, profile: any)
	local self = setmetatable(
		{
			host_handler = host_handler;
			player = player;
			profile = profile;
			throttling = {};
			
			my_servers = {};
			my_client_servers = {};
		}, 
		Hoster);
	
	self:initialise();
	
	return self;
end;

------------------------------------------------------------------------------------------------

function Hoster:initialise()
	if self:has_administrative_permission() then
		Remotes.SetAdmin:FireClient(self.player);
	end;
end

function Hoster:destroy()
	table.clear(self.throttling);
	table.clear(self);
end

function Hoster:message(message: string)
	Remotes.Message:FireClient(self.player, message);
end

function Hoster:refresh_servers_list()
	Remotes.UpdateServerList:FireClient(self.player, self.host_handler.client_server_list);
end

function Hoster:retrieve_lost_servers()
	local owner_id = self.player.UserId;
	local access_codes = {};
	
	for _, server in self.profile.Data.Hosting.MyServers.List do
		if server.access_code then
			access_codes[server.access_code] = true;
		end;
	end;
	
	for access_code, server in self.host_handler.server_list do
		if server.owner_id == owner_id and not access_codes[access_code] then
			table.insert(self.profile.Data.Hosting.MyServers.List, { access_code = access_code });
		end;
	end;
end;

function Hoster:get_raw_data_list()
	return self.profile.Data.Hosting.MyServers.List;
end

function Hoster:validate_my_servers()
	self:retrieve_lost_servers();
	self.profile.Data.Hosting.MyServers.Validated.Time = tick();

	local servers = {};
	local client_servers = {};
	local to_remove = {};
	
	for index, item in self.profile.Data.Hosting.MyServers.List do
		local server = self.host_handler:get_server_from_access_code(item.access_code, true);
		
		if server then
			servers[server.access_code] = server;
			client_servers[server.access_code] = server;
		else
			-- Server does not exist anymore
			table.insert(to_remove, index);
		end;
	end;
	
	for index = #to_remove, 1, -1 do
		table.remove(self.profile.Data.Hosting.MyServers.List, to_remove[index]);
	end;
	
	Utility.set_table(self.my_servers, servers);
	Utility.set_table(self.my_client_servers, client_servers);
end

function Hoster:get_my_servers()
	local last_validation = self.profile.Data.Hosting.MyServers.Validated;
	local time_now = tick();
	
	if not last_validation.Pending and (time_now - last_validation.Time) < Settings.MY_SERVER_VALIDATION_DEBOUNCE then
		return self.my_client_servers;
	end;
	
	self.profile.Data.Hosting.MyServers.Validated.Pending = false;
	self:validate_my_servers();
	
	return self.my_client_servers;
end

function Hoster:can_create_custom_server(info: Types.CustomServerInfo)
	local my_servers = self:get_my_servers() -- Revalidates my servers;
	local server_count = 0;
	
	for _ in my_servers do
		server_count += 1;
	end;
	
	return server_count == 0;
end;

function Hoster:has_administrative_permission(): boolean
	if Whitelist.is_permitted(self.player.UserId) then
		return true;
	end;
	
	return false;
end;

function Hoster:has_edit_permissions_of_server(access_code: string): boolean
	if self.my_servers[access_code] ~= nil then
		return true;
	end;
	
	if self:has_administrative_permission() then
		return true;
	end
	
	return false;
end;

function Hoster:validate_custom_server_info(info: Types.CustomServerInfo): (Types.CustomServerInfo?, string)
	local new_info = {};

	for key, value in Validation.custom_server_info do
		if not info[key] then continue end;

		if value.type ~= typeof(info[key]) then 
			return nil, `Incorrect type used for {key}`;
		end;

		if value.min_length and not (#info[key] >= value.min_length and #info[key] <= value.max_length) then 
			return nil, `{key} is not between {value.min_length} and {value.max_length}!`;
		end;

		new_info[key] = info[key];
	end;

	if new_info.title then
		local filter_result = TextService:FilterStringAsync(new_info.title, self.player.UserId, Enum.TextFilterContext.PublicChat);
		local filtered_title = filter_result:GetNonChatStringForBroadcastAsync();
		
		if filtered_title ~= new_info.title then
			return nil, "Could not validate as title was filtered 😢";
		end;
		
		new_info.title = filtered_title;
	end
	
	return new_info, "";
end

-- Below the commented code for whatever reason doesn't work, it immediately kicks the player when they join.
--[[
	local teleport_options = Instance.new("TeleportOptions");
	
	teleport_options:SetTeleportData({
		ReservedServerAccessCode = server.reserve_code;
		ShouldReserveServer = true;
	});
	
	TeleportService:TeleportAsync(game.PlaceId, {self.player}, teleport_options);
]]
function Hoster:join_custom_server(access_code: string): ()
	local server = self.host_handler:get_server_from_access_code(access_code);
	
	if server then
		TeleportService:TeleportToPrivateServer(game.PlaceId, server.reserve_code, {self.player});
	else
		warn("No server exists with access code:", access_code);
	end
end

function Hoster:moderate_user(user_id: number, parameters: any): ()
	if self:throttle("moderate_user", 120, 1) <= 0 then
		return self:message("Please wait before moderating another user");
	end;
	
	if not self:has_administrative_permission() then
		return self:message("Lacking permissions");
	end;
	
	if Whitelist:is_permitted(user_id) then
		return self:message("Cannot ban another moderator");
	end;
	
	if parameters.unban then
		local success, err = pcall(Players.UnbanAsync, Players, user_id);
		
		if not success then
			self:message("Failed to unban user.");
		else
			self:message("Successfully unbanned user.");
		end
	else
		local config: BanConfigType = {
			["DisplayReason"] = parameters.reason,
			["Duration"] = parameters.duration,
			["UserIds"] = {user_id};
			["PrivateReason"] = `Moderator (UID: {self.player.UserId})`;
			["ApplyToUniverse"] = true;
			["ExcludeAltAccounts"] = false;
		};
		
		local success, err = pcall(Players.BanAsync, Players, config);
		
		if not success then
			self:message("Failed to ban user.");
		else
			self:message("Successfully banned user.");
		end
	end
end

function Hoster:delete_custom_server(access_code: string, parameters: any)
	if self:has_edit_permissions_of_server(access_code) then
		local server = self.my_servers[access_code];
		
		if server then
			self.host_handler:delete_custom_server(access_code, server.private_server_id, parameters);
		else
			self.host_handler:delete_custom_server(access_code, nil, parameters);
		end
		
		-- Delete them from ever, ever existing ever again ever
		self.my_servers[access_code] = nil;
		self.my_client_servers[access_code] = nil;
		
		self:validate_my_servers();
	end;
end;

function Hoster:edit_custom_server(access_code: string, details: any)
	if self:has_edit_permissions_of_server(access_code) then
		-- Can only edit title, we don't want any spoofing.
		local new_info, err = self:validate_custom_server_info({title = details.title});
		
		if new_info then
			self.host_handler:update_custom_server(access_code, new_info);
		else
			self:message(err);
		end
	end
end

function Hoster:create_custom_server(info: Types.CustomServerInfo)
	if self:throttle("create_server_start", 120) <= 0 then
		self:message("Please stop spamming the button 🙏");

		return false;
	end;
	
	if not self:can_create_custom_server(info) then
		self:message("You cannot create more than 1 server.");
		
		return false;
	end
	
	local new_info, err = self:validate_custom_server_info(info);
	
	if not new_info then
		self:message(err);
		
		return false;
	end;
	
	if self:throttle("create_server", 10, 5) <= 0 then
		self:message("Please wait before trying again.");
		
		return false;
	end;
	
	local access_code, err = self.host_handler:create_custom_server(self.player, new_info);
	
	if not access_code then
		self:message(err);
		
		return false;
	end;
	
	self.profile.Data.Hosting.MyServers.Validated.Pending = true;
	
	table.insert(self.profile.Data.Hosting.MyServers.List, {
		access_code = access_code;
	});
	
	return true;
end

function Hoster:throttle(label: string, requests_per_minute: number?, debounce: number?): number
	if not requests_per_minute then
		return math.huge;
	end;
	
	if not self.throttling[label] then
		self.throttling[label] = {budget = requests_per_minute, last = -1, message_debounce = 0};
	end;

	local time_now = tick();
	local budgets = self.throttling[label];
	local time_elapsed = time_now - budgets.last;
	local added_budget = if time_elapsed < 0.5 then 0 else time_elapsed * (requests_per_minute / 60);
	
	if debounce and time_elapsed < debounce then
		return 0;
	end;
	
	budgets.budget = math.clamp(budgets.budget + added_budget - 1, 0, requests_per_minute);
	budgets.last = time_now;
	
	local value = math.floor(budgets.budget);

	if value == 0 and time_now - budgets.message_debounce > 0.5 then
		budgets.message_debounce = time_now;
	end
	
	return value;
end

table.freeze(Hoster);

return Hoster;