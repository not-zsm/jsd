-- this is a poor mans ReplicaService

--!strict
--!native

local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Maid = require( "./Maid" )
local Signal = require( "./Signal" )

--------------------------------------------------------------------------------------------------------

export type KeyDirectory = {any};

export type ClassStreamService = {
	__index: ClassStreamService;

	new: (channel: string, data: KeyDirectory) -> StreamService;
	destroy: (self: StreamService) -> ();
	get_channel: (channel: string) -> typeof(script.ChannelTemplate);
	connect_listeners: (self: StreamService, listeners: {Player}) -> ();
	
	get_changed: (self: StreamService, directory: KeyDirectory) -> Signal.Signal<KeyDirectory, any>;
	get_table_changed: (self: StreamService, directory: KeyDirectory) -> Signal.Signal<KeyDirectory, any>;
	get_singleton_changed: (self: StreamService, directory: KeyDirectory) -> Signal.Signal<KeyDirectory, any>;
	
	observe: (self: StreamService, directory: KeyDirectory, callback: (KeyDirectory, any) -> ()) -> Signal.Connection<KeyDirectory, any>;
	observe_table: (self: StreamService, directory: KeyDirectory, callback: (KeyDirectory, any) -> ()) -> Signal.Connection<KeyDirectory, any>;
	observe_value: (self: StreamService, directory: KeyDirectory, callback: (KeyDirectory, any) -> ()) -> Signal.Connection<KeyDirectory, any>;
	
	get: (self: StreamService, directory: KeyDirectory) -> any;
	raw_set: (self: StreamService, directory: KeyDirectory, value: any) -> boolean;
	ping: (self: StreamService, directory: KeyDirectory, value: any) -> ();
	set: (self: StreamService, directory: KeyDirectory, value: any) -> boolean;
	bulk_set: (self: StreamService, directory: KeyDirectory, entries: any) -> ();
	increment: (self: StreamService, directory: KeyDirectory, increment: number) -> ();
	decrement: (self: StreamService, directory: KeyDirectory, decrement: number) -> ();
	toggle: (self: StreamService, directory: KeyDirectory) -> ();
	insert: (self: StreamService, directory: KeyDirectory, value: any) -> number;
	raw_increment: (self: StreamService, directory: KeyDirectory, increment: number) -> ();
	raw_toggle: (self: StreamService, directory: KeyDirectory) -> ();
	bind_to_synchronise: (self: StreamService, callback: () -> ()) -> Signal.Connection<>?;
	synchronise: (self: StreamService, player: Player?) -> ();
};

export type StreamService = typeof(setmetatable({} :: {
	maid: Maid.Maid;
	channel: typeof(script.ChannelTemplate);
	data: any;
	has_synchronised: boolean;
	on_synchronised: Signal.Signal<>;
	changed_keys: any;
	changed_keys_map: { [any]: Signal.Signal<KeyDirectory, any> };
	changed_index_map: { [any]: Signal.Signal<any, any> };
	changed_singleton_map: { [any]: Signal.Signal<any> };
	listeners: {[Player]: boolean};
	synchronisations: {[Player]: boolean};
	assemble_change: {any};
	assemble_thread: thread?;
	process_client: ((key: {any}, value: any) -> ())?;
	allow_multiple_synchronisations: boolean;
	
}, {} :: ClassStreamService));

--------------------------------------------------------------------------------------------------------

local function get_directory_value_pair(set: any): (any, any)
	return {select(2, unpack(set))}, set[1];
end

--------------------------------------------------------------------------------------------------------

local StreamService = {} :: ClassStreamService;
StreamService.__index = StreamService;

local function server_init_network(self: StreamService)
	self.maid:add(self.channel.Synchronise.OnServerEvent:Connect(function(player)
		if not player.Parent then return end;
		if not self.listeners[player] then return end; -- Non listeners cannot sync (important for data hiding)
		if not self.allow_multiple_synchronisations and self.synchronisations[player] then return end; -- Cannot sync multiple times.
		
		self:synchronise(player);
	end))
	
	self.maid:add(self.channel.Replicate.OnServerEvent:Connect(function(player, ...)
		if not self.listeners[player] then return end;
		
		local data = {...};
		
		if self.process_client then
			-- With data means the client is requesting change;
			for _, value in data do
				self.process_client(get_directory_value_pair(value));
			end;
		end;
	end))
end

local function client_init_network(self: StreamService)
	self.maid:add(self.channel.Synchronise.OnClientEvent:Connect(function(data)
		self.data = data;
		
		if not self.has_synchronised then
			self.has_synchronised = true;
			self.on_synchronised:Fire();
		end;
	end))

	self.maid:add(self.channel.Replicate.OnClientEvent:Connect(function(...)
		for _, value in {...} do
			self:raw_set(get_directory_value_pair(value));
		end
	end))
end

local function create_base_stream(channel: string, data: any): StreamService
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			maid = maid;
			data = data or {};
			
			allow_multiple_synchronisations = false;
			has_synchronised = false;
			on_synchronised = maid:add(Signal.new());
			
			changed_keys = {};
			changed_keys_map = {};
			changed_index_map = {};
			changed_singleton_map = {};

			assemble_change = {};
			listeners = {};
			synchronisations = {};
		}, 
		StreamService);
	
	return self;
end

if RunService:IsServer() then

	local function assemble(self: StreamService)
		self.assemble_thread = nil;
		
		for player in self.listeners do
			if self.synchronisations[player] then
				self.channel.Replicate:FireClient(player, unpack(self.assemble_change));
			else
				self:synchronise(player);
			end
		end;
		
		table.clear(self.assemble_change);
	end

	function StreamService.new(channel: string, data)
		local self = create_base_stream(channel, data);
		
		self.channel = StreamService.get_channel(channel);
		self.has_synchronised = true;
		
		return self;
	end;
	
	function StreamService:ping(directory, value)
		if not next(self.synchronisations) then return end;

		table.insert(self.assemble_change, {value, unpack(directory)});

		if not self.assemble_thread then
			self.assemble_thread = task.defer(assemble, self);
		end
	end
	
	function StreamService:synchronise(player)
		assert(player, "Must have a player");
		
		if not self.synchronisations[player] then
			self.synchronisations[player] = true;

			player.AncestryChanged:Once(function()
				self.synchronisations[player] = nil;
			end)
		end;
		
		self.channel.Synchronise:FireClient(player, self.data);
	end

elseif RunService:IsClient() then

	local function assemble(self: StreamService)
		self.assemble_thread = nil;
		self.channel.Replicate:FireServer(unpack(self.assemble_change));
		table.clear(self.assemble_change);
	end
	
	local function wait_for_channel(self: any, channel)
		self.channel = StreamService.get_channel(channel);
		client_init_network(self);
	end;
	
	function StreamService.new(channel: string, data)
		local self = create_base_stream(channel, data);
		
		task.spawn(wait_for_channel, self, channel);
		
		return self;
	end;

	function StreamService:ping(directory, value)
		table.insert(self.assemble_change, {value, unpack(directory)});

		if not self.assemble_thread then
			self.assemble_thread = task.defer(assemble, self);
		end
	end
	
	function StreamService:synchronise()
		self.channel.Synchronise:FireServer();
	end
end

function StreamService.get_channel(channel: string): RemoteEvent
	if RunService:IsClient() then
		return script.ActiveChannels:WaitForChild(channel);
	else
		local remote_channel = script.ActiveChannels:FindFirstChild(channel);

		if not remote_channel then
			remote_channel = script.Template:Clone();
			remote_channel.Name = channel;
			remote_channel.Parent = script.ActiveChannels;
		end;
		
		return remote_channel;
	end;
end

function StreamService:destroy()
	self.maid:destroy();
end

function StreamService:connect_listeners(listeners: {Player})
	for _, player in listeners do
		if self.listeners[player] then
			continue;
		end;
		
		if not next(self.listeners) then
			task.spawn(server_init_network, self);
		end
		
		self.listeners[player] = true;
		
		player.AncestryChanged:Once(function()
			self.listeners[player] = nil;
		end)
	end;
end

local function generate_keys_map(self: StreamService, directory, mapping_table)
	local resource = self.changed_keys;

	if not mapping_table[resource] then
		mapping_table[resource] = self.maid:add(Signal.new());
	end;
	
	for key, index in directory do
		if resource[index] == nil then
			resource[index] = {};
		end;
		
		if not mapping_table[resource[index]] then
			mapping_table[resource[index]] = self.maid:add(Signal.new());
		end;

		resource = resource[index];
	end;

	return mapping_table[resource];
end

function StreamService:get_singleton_changed(directory)
	return generate_keys_map(self, directory, self.changed_singleton_map);
end

function StreamService:get_table_changed(directory)
	return generate_keys_map(self, directory, self.changed_index_map);
end

function StreamService:get_changed(directory)
	return generate_keys_map(self, directory, self.changed_keys_map);
end

function StreamService:observe_value(directory, callback)
	local connection = self:get_singleton_changed(directory):Connect(callback);
	
	self:bind_to_synchronise(function()
		if not connection.Connected then return end;
		
		local value = self:get(directory);

		if (value ~= nil) then
			callback(directory, value);
		end;
	end)
	
	return connection;
end

function StreamService:observe_table(directory, callback)
	local connection = self:get_table_changed(directory):Connect(callback);
	
	self:bind_to_synchronise(function()
		if not connection.Connected then return end;
		
		local value = self:get(directory);

		if (value ~= nil) then
			for index, item in value do
				task.spawn(callback, index, item);
			end;
		end;
	end)
	
	return connection;
end

function StreamService:observe(directory, callback)
	local connection = self:get_changed(directory):Connect(callback);
	
	self:bind_to_synchronise(function()
		if not connection.Connected then return end;
		
		local value = self:get(directory);

		if (value ~= nil) then
			callback(directory, value);
		end;
	end)
	
	return connection;
end

function StreamService:get(directory)
	local resource = self.data;
	
	for key, value in directory do
		resource = resource[value];
		if resource == nil then return nil end;
	end;
	
	return resource;
end

-- Fixes the case where a table is set directely, so that tables content is not fired under the changed signals.
local function update_deep(self: StreamService, directory: KeyDirectory, signal_tree: any, value_table: {[any]: any}): ()
	debug.profilebegin("StreamService - Deep Signals")
	
	for key, value in value_table do
		if not signal_tree then break end;
		
		local signal_branch = signal_tree[key];
		local signal = self.changed_keys_map[signal_branch];

		if typeof(value) == "table" then
			update_deep(self, directory, signal_branch, value);
		end;

		if signal then
			signal:Fire(directory, value);
		end;
	end
	
	debug.profileend();
end

local function fire_changed_signals(self: StreamService, directory, value)
	debug.profilebegin("StreamService - Changed Signals")
	
	local index = self.changed_keys;
	local last_index;
	local key_max = 1;
	
	for key = 1, #directory do
		if not index then break end;

		last_index = index;
		index = index[directory[key]];
		key_max = key;
		
		if self.changed_keys_map[index] then
			self.changed_keys_map[index]:Fire(directory, value)
		end
	end;
	
	-- Fire table index changes when the directory is the index of a listening table.
	if key_max == #directory and last_index and self.changed_index_map[last_index] then
		self.changed_index_map[last_index]:Fire(directory[#directory], value)
	end
	
	if index then
		
		-- If the table is set directly, i want all the indexes to be fired for table observers
		if self.changed_index_map[index] and typeof(value) == "table" then
			for table_key, table_value in value do
				self.changed_index_map[index]:Fire(table_key, table_value)
			end
		end
		
		if self.changed_singleton_map[index] then
			self.changed_singleton_map[index]:Fire(value)
		end
	end;
	
	debug.profileend();
	
	return index;
end

function StreamService:raw_set(directory, value)
	debug.profilebegin("StreamService - Raw Set")
	
	local resource = self.data;

	for key = 1, #directory - 1 do
		local index = directory[key];
		local res = resource[index];
		
		if res == nil then
			res = {};
			resource[index] = res;
		end;
		
		resource = res;
	end;

	local index = directory[#directory];
	local previous_value = resource[index];

	resource[index] = value;

	if previous_value ~= value then
		local signals = fire_changed_signals(self, directory, value);
	
		if typeof(value) == "table" then
			update_deep(self, directory, signals, value)
		end
		
		debug.profileend();
		
		return true;
	end;
	
	debug.profileend();
	
	return false;
end

function StreamService:set(directory, value)
	local changed = self:raw_set(directory, value);
	
	if changed then
		self:ping(directory, value);
	end
	
	return changed;
end

function StreamService:bulk_set(directory, entries)
	for index, value in entries do
		local new_directory = table.clone(directory);
		table.insert(new_directory, index);
		self:set( new_directory, value );
	end;
end

function StreamService:raw_increment(directory, increment)
	self:raw_set(directory, (self:get(directory) or 0) + increment)
end

function StreamService:raw_toggle(directory)
	self:raw_set(directory, not self:get(directory));
end

function StreamService:increment(directory, increment)
	self:set(directory, (self:get(directory) or 0) + increment)
end

function StreamService:decrement(directory, increment)
	self:set(directory, (self:get(directory) or 0) - increment)
end

function StreamService:insert(directory, value)
	local new_directory = table.clone(directory);
	local tbl = self:get(directory) or {};
	local index = #tbl + 1;
	
	table.insert(new_directory, index);
	
	self:set(new_directory, value);
	
	return index;
end

function StreamService:toggle(directory)
	self:set(directory, not self:get(directory));
end

function StreamService:bind_to_synchronise(callback)
	if self.has_synchronised then
		task.spawn(callback)
	else
		return self.on_synchronised:Once(callback);
	end;
	
	return nil;
end

table.freeze(StreamService);

return StreamService;