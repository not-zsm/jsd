local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require( ReplicatedStorage.Packages.Signal )

export type ServerType = "Private" | "Reserved" | "None";

export type CustomServerInfo = {
	title: string;
	tier: number;
};

export type CustomServerSubmit = {
	title: string,
};

export type ClassServer = {
	__index: ClassServer;

	new: (HostHandler: HostHandler) -> Server;
	serialise_server_message: (data: any) -> (any);
	deserialise_server_message: (data: any) -> (any);
	
	_try_get_access_code: (self: Server) -> any;
	
	initialise: (self: Server) -> ();
	initialise_as_custom_server: (self: Server) -> ();
	keep_custom_server_alive: (self: Server) -> ();
	batch_update_player_count: (self: Server, upvalue: number) -> ();
	get_shutdown_message_from: (self: Server, subscription_data: any) -> string;
	bind_to_access_code: (self: Server, callback: (access_code: string) -> ()) -> Signal.Connection<>?;
	get_access_code: (self: Server) -> string?;
	get_type: (self: Server) -> ServerType;
};

export type Server = typeof(setmetatable({} :: {
	host_handler: HostHandler;
	
	shutdown_message: string?;
	
	access_code: string?;
	reserved_server_code: string?;
	owner_id: number?;
	
	is_waiting_for_access_code: boolean;
	is_updating_player_count: boolean;
	is_shutdown: boolean;
	is_custom_server: boolean;
	is_non_custom_reserve: boolean;
	join_status: any;

	_keep_alive_thread: thread?;
	_last_expiry_update: number;
	_access_code_get_attempts: number;

	on_custom_status_ready: Signal.Signal<>;
	
}, {} :: ClassServer));

export type ClassHoster = {
	__index: ClassHoster;

	new: (host_handler: HostHandler, player: Player, profile: any) -> Hoster;
	initialise: (self: Hoster) -> ();
	destroy: (self: Hoster) -> ();
	create_custom_server: (self: Hoster, info: CustomServerInfo) -> ();
	throttle: (self: Hoster, label: string, requests_per_minute: number?, debounce: number?) -> number;
};

export type Hoster = typeof(setmetatable({} :: {

	host_handler: HostHandler;
	player: Player;
	profile: any;
	throttling: {[string]: {budget: number, last: number, message_debounce: number}};

}, {} :: ClassHoster));

export type ClassHostHandler = {
	__index: ClassHostHandler;

	new: () -> HostHandler;
	initialise: (self: HostHandler) -> ();
	remove_player: (self: HostHandler, player: Player) -> ();
	add_player: (self: HostHandler, player: Player, profile: any) -> ();
	generate_access_code: (self: HostHandler) -> string;
	generate_unique_access_code: (self: HostHandler) -> string;
	get_server: (self: HostHandler) -> ();
	add_viewer: (self: HostHandler, player: Player) -> ();
	remove_viewer: (self: HostHandler, player: Player) -> ();
	serialise_server_info: (info: unknown) -> ();
	deserialise_server_info: (serial: unknown) -> ();
	encode_safe_for_client: (value: unknown) -> any;
	refresh_servers_for_player: (self: HostHandler, player: Player) -> ();
	refresh_servers: (self: HostHandler) -> ();
	set_server_access_code: (self: HostHandler, access_code: string, info: any) -> ();
	reserve_server: (self: HostHandler) -> ();
	get_access_code: (self: HostHandler, private_server_id: string) -> string?;
	get_private_server_id_from_access_code: (self: HostHandler, access_code: string) -> string?;
	remove_access_code_map: (self: HostHandler, private_server_id: string) -> boolean;
	validate_custom_server_info: (self: HostHandler, info: CustomServerInfo) -> (CustomServerInfo?, string);
	create_custom_server: (self: HostHandler, player: Player, info: CustomServerInfo) -> (string?, string?);
	delete_custom_server: (self: HostHandler, access_code: string, private_server_id: string?) -> ();
	delete_all_servers: (self: HostHandler) -> ();
	get_server_from_access_code: (self: HostHandler, access_code: string, use_cache: boolean?) -> any;
	try_get_server_from_access_code: (self: HostHandler, access_code: string, use_cache: boolean?) -> any;
	get_servers_page: (self: HostHandler, page: number) -> ();
	get_access_information: (self: HostHandler, private_server_id: string) -> {string}?;
	try_get_access_information: (self: HostHandler, private_server_id: string) -> {string}?;
	update_custom_server_player_count: (self: HostHandler, access_code: string, new_player_count: number) -> ();
	get_server_from_cached: (self: HostHandler, access_code: string) -> ();
};

export type HostHandler = typeof(setmetatable({} :: {
	
	server: Server;
	
	server_list: {[string]: any};
	client_server_list: {[string]: any};

	viewers: {[Player]: boolean};
	players: {[Player]: Hoster};

	is_refreshing_servers: boolean;

	viewer_thread: thread?;
	last_refresh: number;

	on_server_refresh: Signal.Signal<>;

}, {} :: ClassHostHandler));

return {};