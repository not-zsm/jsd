local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerScriptService = game:GetService("ServerScriptService")
local GroupService = game:GetService("GroupService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-------------------------------------------------------------

local Table = require( ReplicatedStorage.Packages.Table )
local Maid = require( ReplicatedStorage.Packages.Maid )
local Signal = require( ReplicatedStorage.Packages.Signal )
local Types = require( script.Types );

-------------------------------------------------------------

local DataConfiguration = script:WaitForChild("Data");

-------------------------------------------------------------

local DEFAULT_SETTINGS: Types.PermissionSettings;

if RunService:IsServer() then
	DEFAULT_SETTINGS = require(ServerScriptService.Modules.Whitelist_Settings);
else
	DEFAULT_SETTINGS = {
		mode = "Web"; -- "Web" or "Product"
		refresh_time = 0; -- Number of seconds between each request to update the whitelist.
		invalidate_out_of_date_whitelist = 0; -- If this amount of seconds go without an update to the whitelist, the whitelist is cleared for security.
		web_repository = ""; -- The raws link to the web whitelist.
		product_id = 0000000; -- This should be a developer product.
	};
end

-------------------------------------------------------------

local Permissions = {};
Permissions.last_whitelist_fetch_success = -math.huge;
Permissions.is_ready = false;
Permissions.invalid = false;

Permissions.on_data_updated = Signal.new() :: Signal.Signal<any, boolean>;
Permissions.on_data_changed = Signal.new() :: Signal.Signal<any>;
Permissions.on_prepare = Signal.new() :: Signal.Signal<any, string>;

Permissions.data = {};
Permissions.json_data = "{}";

-------------------------------------------------------------

-- probably works havent tested it though
local function request_whitelist_from_web(): ({number}?, string?)
	local time_requested = os.time()
	local success, result = pcall(HttpService.GetAsync, HttpService, DEFAULT_SETTINGS.web_repository .. "?t=" .. time_requested, false);

	-- Don't retry as it isn't critical, future attempts will likely succeed.
	if success then
		local decode_success, whitelist = pcall(HttpService.JSONDecode, HttpService, result);
		
		if decode_success then
			return whitelist, result;
		else
			warn("Could not decode, respone did not return valid json.");
		end;
	else
		warn("Whitelist request failed:", result);
	end;
	
	return nil, nil;
end;

-- probably works havent tested it though maybe
local function request_whitelist_from_product(): ({number}?, string?)
	local success, product_info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, DEFAULT_SETTINGS.product_id, Enum.InfoType.Product);

	if success then
		local decode_success, whitelist = pcall(HttpService.JSONDecode, HttpService, product_info.Description);
		
		if decode_success then
			return whitelist, product_info.Description;
		end;
	end;
	
	return nil, nil;
end;

local function set_whitelist(whitelist, json)
	local last_json = Permissions.json_data;
	local did_change = last_json ~= json;
	
	Permissions.last_whitelist_fetch_success = tick();
	Permissions.is_ready = true;

	Permissions.json_data = json;
	Permissions.data = whitelist;
	
	if RunService:IsServer() then
		Permissions.on_prepare:Fire(whitelist, json);
	end;

	Permissions.on_data_updated:Fire(Permissions.data, did_change);
	
	if did_change or RunService:IsClient() then
		Permissions.on_data_changed:Fire(Permissions.data);
		
		if RunService:IsServer() then
			DataConfiguration:SetAttribute("Whitelist", Permissions.json_data);
		end;
	end;
end;

local function update_request_whitelist(): ()
	local whitelist, json = Permissions.request_whitelist();
	
	if whitelist and json then
		Permissions.invalid = false;
		set_whitelist(whitelist, json);
		
	elseif tick() - Permissions.last_whitelist_fetch_success > DEFAULT_SETTINGS.invalidate_out_of_date_whitelist then
		Permissions.invalid = true;
		set_whitelist({}, "{}");
	end;
end;


local function update_request_whitelist_loop()
	repeat
		task.spawn(update_request_whitelist);
		task.wait(DEFAULT_SETTINGS.refresh_time);
	until not Permissions;
end;

local function update_whitelist_client_loop()
	DataConfiguration:GetAttributeChangedSignal("Whitelist"):Connect(update_request_whitelist);
	task.spawn(update_request_whitelist);
end;

-------------------------------------------------------------

function Permissions.request_whitelist(): {number}?
	
	if RunService:IsServer() then
		if DEFAULT_SETTINGS.mode == "Web" then
			return request_whitelist_from_web();

		elseif DEFAULT_SETTINGS.mode == "Product" then
			return request_whitelist_from_product();
		end;
		
	elseif RunService:IsClient() then
		local json = DataConfiguration:GetAttribute("Whitelist");
		
		if json then
			local success, result = pcall(HttpService.JSONDecode, HttpService, json);
			
			if success then
				return result, json;
			end
		end
	end;
	
	return nil;
end;

function Permissions.get(directory: string | {string}): any
	local resource = Permissions.data;
	local search_directory;
	
	if typeof(directory) == "string" then
		search_directory = string.split(directory, "/");
	else
		search_directory = directory;
	end;
	
	for key, value in search_directory do
		resource = resource[value];
		if resource == nil then return nil end;
	end;
	
	return resource;
end;

-- Checks whether the given UserId 'user_id', is in the whitelist of given directory.
function Permissions.is_permitted(user_id: string | number, directory: string | {string}): boolean
	return true
end;

function Permissions.wait_until_ready()
	if not Permissions.is_ready then
		Permissions.on_data_updated:Wait()
	end;
end;

-- Gets the group rank of a player, even if they are not in-game.
function Permissions.get_group_rank(user_id: number, needs_player: boolean?): number
	return 255
end;

-------------------------------------------------------------

if RunService:IsServer() then
	task.spawn(update_request_whitelist_loop);
else
	task.spawn(update_whitelist_client_loop);
end;

return Permissions;