local MarketplaceService = game:GetService("MarketplaceService")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Teams = game:GetService("Teams")

--------------------------------------------------------------

local Whitelist = require( "./Whitelist" )
local Unpacker = require( "./Unpacker" );
local Serialise = require( "./Serialise" );

local Havoc = require( "../HavocHandler/Havoc" );
local ProfileStore = require( "../Game/Modules/Utility/ProfileStore" )

local Table = require( Unpacker.Packages.Table );
local Maid = require( Unpacker.Packages.Maid );
local Type = require( Unpacker.Packages.Type );
local Instances = require( Unpacker.Packages.Instances );
local Observer = require( Unpacker.Packages.Observer );
local Signal = require( Unpacker.Packages.Signal );
local Attributes = require( Unpacker.Packages.Attributes )
local Asset = require( Unpacker.Packages.Asset );
local StreamService = require( Unpacker.Packages.StreamService );
local Debounce = require( Unpacker.Packages.Debounce );
local InstanceAllowed = require( Unpacker.Shared.Data.InstanceAllowed );

local Gamepasses = require( ReplicatedStorage.Modules.Shared.Game.Gamepasses )

--------------------------------------------------------------

local BuildShared = Unpacker.Shared;
local BuildRemotes = Unpacker.Remotes;
local BuildsFolder = workspace.Builds;
local InstanceBuild = BuildShared.Assets.Build;
local InstanceAssets =	InstanceBuild.Insert;
local InstanceInventory = InstanceBuild.Inventory;

local INVENTORY_PROFILE_TEMPLATE = {
	Saves = {};
};

-- BuildStore can just use raw datastores, but InventoryStore should use profile store as it more accurately describes.
local BuildStore: DataStore;
local InventoryStore = ProfileStore.New("inventory_store", INVENTORY_PROFILE_TEMPLATE)

xpcall(function() BuildStore = DataStoreService:GetDataStore("builds_store"); end, warn)

--------------------------------------------------------------

local GapFill = require( BuildShared.Utility.GapFill )
local Products = require( BuildShared.Data.Products );
local NotificationStatus = require( BuildShared.Data.NotificationStatus )
local PropertyTable = require( BuildShared.Data.Properties )
local PropertyCustom = require( BuildShared.Data.Properties.Custom )
local PropertyHelper = require( BuildShared.Data.Properties.Helper )
local PropertyUtil = require( BuildShared.Data.Properties.Utility );
local Preferences = require( BuildShared.Data.Preferences );

--------------------------------------------------------------

local InstanceModifiers = {};

local BustProperties = {
	Color3uint8 = true;
	NetworkIsSleeping = true;
	MaterialVariantSerialized = true;
	PropertyStatusStudio = true;
	Attributes = true;
	Tags = true;
}

local AccessPermissions = {
	load_slot = true;
	save_slot = true;
	instance_modifier = true;
	spawning = true;
	cloning = true;
	anchor = true;
	grouping = true;
	delete = true;
	clear = true;
};

local MAX_TOTAL_INV_INSTANCES = 20_000;
local MAX_SINGLE_INV_INSTANCES = 5_000;

local ClearAllMessages = {
	"No... nooooo nooooo, la policia... noooo... 🚔🚨👮";
	"Its... its all gone... noooo. 😭";
	"RAH! 🗣️🔥";
};

local voxel_breaker_overlap = OverlapParams.new();
voxel_breaker_overlap.FilterDescendantsInstances = {workspace.Builds};
voxel_breaker_overlap.FilterType = Enum.RaycastFilterType.Include;

--------------------------------------------------------------

local function iterate_local_parent(instance: Instance, best_ancestor, best_parent)
	local nparent = instance;
	local parents = 0;

	while nparent and nparent ~= BuildsFolder do
		nparent = nparent.Parent;
		parents += 1;
	end;

	if parents < best_ancestor then
		best_ancestor = parents;
		best_parent = instance.Parent;
	end;

	return best_ancestor, best_parent;
end

--------------------------------------------------------------

local Builder = {};
Builder.__index = Builder;
Builder.all_access_permissions = AccessPermissions;

function Builder.new(build_handler: any, player: Player, profile: any)
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			player = player;
			profile = profile;
			build_handler = build_handler;
			build_data = profile.Data.Builds;
			
			enabled = false;
			
			hotbar = {};
			recording = {};
			throttling = {};
			undo_stack = {};
			redo_stack = {};
			inventory_storage_failed_uids = {};
			permissions = {} :: typeof(Builder.all_access_permissions);
			clipboard = Instance.new("Model");
			
			maid = maid;
			record_maid = maid:limb();
			modifier_listen_maid = maid:limb();
			
			debounce = maid:add(Debounce.new());
		}, 
		Builder);
	
	self:create_inventory_storage();
	self:initialise_replica();
	self:initialise_slots();
	self:initialise_inventory_data(); -- Yields
	
	task.spawn(self.initialise_gamepasses, self);
	
	self.maid:add(task.spawn(self.initialise_auto_saves, self));
	
	player:SetAttribute("HasFlight", true);
	
	return self;
end;

local function get_property(instance: Instance, property: string): any
	return instance[property];
end;

local function modify_property(instance: Instance, property: string, value: any): ()
	instance[property] = value;
end;

local function get_instance_state_properties(instance: Instance)
	local properties = PropertyUtil.get_properties_of(instance);
	
	if not instance.Parent then
		properties.Parent = Table.null;
	else
		properties.Parent = instance.Parent;
	end;
	
	return properties;
end

local function no_recording_changes(recording: any)
	if not next(recording) then return true end;
	
	for instance, record in recording do
		if next(record.end_state) then
			return false;
		end;
	end;
	
	return true;
end

local function is_datastore_serialisable(value: any): boolean
	return typeof(value) == "string" or typeof(value) == "number" or typeof(value) == "boolean";
end

function Builder:initialise_replica()
	self.profile.Data.Builds.Permissions.ImportExport = Whitelist.has_import_permissions(self.player);
	
	self.stream = StreamService.new("BuildsProfile", self.profile.Data.Builds);
	self.stream:connect_listeners({self.player});
end

function Builder:initialise_auto_saves()
	-- Every 10 minutes;
	while task.wait(10 * 60) do
		self:save_slot(0);
	end
end

function Builder:initialise_inventory_data()
	self.inventory_profile = InventoryStore:StartSessionAsync(`{self.player.UserId}`, {
		Cancel = function()
			return self.player.Parent ~= Players
		end,
	})
	
	if self.inventory_profile then
		self.inventory_profile.OnSessionEnd:Connect(function()
			self.inventory_profile = nil;
			self:push_notification(NotificationStatus.info, "Inventory profile session was terminated");
		end);               
		
		if self.player.Parent ~= Players then
			self.inventory_profile:EndSession();
		else
			self.inventory_profile:Reconcile()
			self:replicate_inventory();
		end
	else
		self:push_notification(NotificationStatus.error, "Inventory failed to load! Reload the Build Tools to try again, otherwise you might lose your inventory 💔.")
	end
end

function Builder:write_mesh_text(text: string)
	if self:throttle("text_writer", 10) == 0 then 
		return;
	end;
	
	if #text > 512 then
		return self:push_notifcation(NotificationStatus.error, `Your text length exceeds 512 characters! ({#text})`)
	end;
	
	local filtered_text = self:filter_text(text);
	
	local meshes = {};
	local coordinate = self:get_spawning_cframe() * CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(270), 0, math.pi);
	local spawn_offset = #filtered_text / 2;
	local offset = 0;
	local spacing = 1.5;
	
	local model = Instance.new("Model");
	model.Name = "Text";
	
	for index = 1, #filtered_text do
		local character = string.sub(filtered_text, index, index);
		local mesh = Unpacker.get_character_from_font("Arial", character);
		
		if mesh then
			offset += (0.5 + mesh.Size.X / 5);
			local new_mesh = Instance.fromExisting(mesh);
			new_mesh:PivotTo(coordinate * CFrame.new((spawn_offset - offset) * spacing, 0, 0))
			new_mesh.Parent = model;
			offset += 0.5 + mesh.Size.X / 5;
			
			table.insert(meshes, new_mesh);
		else
			offset += 1;
		end;
	end;
	
	self:record_instance(model);
	model.Parent = BuildsFolder;
	
	self:commit();
	self:select_yielding({model});
end

function Builder:import(data_string: string)
	if self:throttle("import", 10) == 0 then 
		return;
	end;
	
	if not self.profile.Data.Builds.Permissions.ImportExport then
		--return self:push_notification(NotificationStatus.warning, "Sorry, this feature is disabled 😟")
	end
	
	local success, instances = pcall(Serialise.deserialise, data_string);

	if success and instances and instances[1] then
		for _, instance in instances do
			self:record_instance(instance);
			instance.Parent = BuildsFolder;
		end;
		
		self:select_yielding(instances);
		self:commit();
		
		self:push_notification(NotificationStatus.success, `Successfully imported instance{if #instances == 1 then "" else "s"}`);
	else
		self:push_notification(NotificationStatus.error, "Unable to import data")
	end
end

function Builder:export(instances: {Instance})
	if self:throttle("export", 10) == 0 then 
		return;
	end;
	
	if not self.profile.Data.Builds.Permissions.ImportExport then
		--return self:push_notification(NotificationStatus.warning, "Sorry, this feature is disabled 😟")
	end
	
	for _, instance in instances do
		if not (self:can_modify(instance) and self:can_remove(instance)) then
			return self:push_notification(NotificationStatus.error, "Unable to export instance(s), you are lacking permissions for an instance.")
		end
	end
	
	local success, data_string = pcall(Serialise.serialise, instances, {UserId = self.player.UserId });
	
	if success then
		BuildRemotes.Operations.Export:FireClient(self.player, data_string);
	else
		self:push_notification(NotificationStatus.error, "Unable to export data")
	end;
end;

function Builder:create_inventory_storage()
	local player_gui = self.player:WaitForChild("PlayerGui");
	local inventory_storage = player_gui:FindFirstChild("InventoryStorage");
	
	if not inventory_storage then
		inventory_storage = Instance.new("ScreenGui");
		inventory_storage.ResetOnSpawn = false;
		inventory_storage.Name = "InventoryStorage";
		inventory_storage.Parent = player_gui;
	end
	
	local folder_storage = inventory_storage:FindFirstChild("Storage");
	
	if not folder_storage then
		folder_storage = Instance.new("Folder");
		folder_storage:SetAttribute("LayoutOrder", -1);
		folder_storage:SetAttribute("Color", Color3.fromRGB(255, 237, 166));
		
		folder_storage.Name = "Storage";
		folder_storage.Parent = inventory_storage;
	end;
	
	self.inventory_storage = inventory_storage;
	self.inventory_storage_folder = folder_storage;
	
	self.maid:add(inventory_storage);
end

do
	local function replicate_inventory(self)
		local uid_to_model = {};

		for _, model in self.inventory_storage_folder:GetChildren() do
			uid_to_model[model:GetAttribute("uid")] = model;
		end
		
		local failed_to_load = 0;
		
		for index, save in self.inventory_profile.Data.Saves do
			local model = uid_to_model[save.uid];

			if not model then
				local success, instances = pcall(Serialise.deserialise, save.data, {UserId = self.player.UserId});
				
				if not success then
					warn(instances);
					local fallback_instance = Instance.new("Model");
					fallback_instance.Name = "*Failed to load*";
					fallback_instance:SetAttribute("Thumbnail", "rbxassetid://88315346204643");
					
					failed_to_load += 1;
					instances = {fallback_instance};
					
					self.inventory_storage_failed_uids[save.uid] = true;
				end;
				
				for _, instance in instances do
					instance:SetAttribute("uid", save.uid);
					instance:SetAttribute("index", index);
					instance.Parent = self.inventory_storage_folder;
				end;

				task.wait();
			end;
		end;
		
		if failed_to_load >= 1 then
			self:push_notification(NotificationStatus.warning, `Unable to load ({failed_to_load}) item{if failed_to_load == 1 then "" else "s"} in your inventory!`, 10);
		end
	end;
	
	function Builder:replicate_inventory()
		if self:is_replicating_inventory() then return end;
		
		self.replicating_inventory_thread = task.spawn(function()
			local success, err = pcall(replicate_inventory, self);
			
			if not success then
				warn("Replicating inventory error:", err);
			end;
			
			self.replicating_inventory_thread = nil;
		end)
	end;
	
	function Builder:stop_replicating_inventory()
		if self.replicating_inventory_thread then
			if coroutine.status(self.replicating_inventory_thread) == "suspended" then
				task.cancel(self.replicating_inventory_thread);
			end;
			
			self.replicating_inventory_thread = nil;
		end
	end
	
	function Builder:is_replicating_inventory(): boolean
		return self.replicating_inventory_thread ~= nil and coroutine.status(self.replicating_inventory_thread) ~= "dead";
	end
end;

function Builder:get_inventory_uid()
	local uid_taken = true;
	local uid: string;
	
	while uid_taken do
		uid_taken = false;
		uid = string.sub(HttpService:GenerateGUID(false), 1, 16);
		
		for index, slot in self.inventory_profile.Data.Saves do
			if slot.uid == uid then
				uid_taken = true;
				break;
			end;
		end;
	end;
	
	return uid;
end

function Builder:is_inventory_capacity_maxed(topple_threshold: number?): boolean
	local total_instances = topple_threshold or 0;
	
	for index, slot in self.inventory_profile.Data.Saves do
		total_instances += slot.instance_count;
	end;
	
	return total_instances > MAX_TOTAL_INV_INSTANCES;
end

function Builder:remove_from_inventory(instance: Instance)
	if not self.inventory_profile then return end;
	if not self:can_copy(instance) then return end;
	if not instance:IsDescendantOf(self.inventory_storage_folder) then return end;
	
	local uid = instance:GetAttribute("uid");
	
	if not uid then
		return warn("No UID exists for instance:", instance.Name);
	end;
	
	for index, save in self.inventory_profile.Data.Saves do
		if save.uid == uid then
			self.inventory_storage_failed_uids[save.uid] = nil;
			table.remove(self.inventory_profile.Data.Saves, index);
			break;
		end;
	end;
	
	instance:Destroy();
end

function Builder:save_to_inventory(instance: Instance)
	if self:throttle("save_to_inventory", 20) == 0 then 
		return;
	end;
	
	if not self.inventory_profile then return end;
	if not self:can_copy(instance) then return end;
	
	local instance_count = #instance:GetDescendants() + 1;
	
	if instance_count > MAX_SINGLE_INV_INSTANCES then
		return self:push_notification(NotificationStatus.warning, 
			`Could not save instance to inventory, the provided instance contains more than {Asset.pretty_number(MAX_SINGLE_INV_INSTANCES)} instances. 💔`)
	end
	
	if self:is_inventory_capacity_maxed(instance_count) then
		return self:push_notification(NotificationStatus.warning, 
			`Could not save instance to inventory, you've reached the max limit of {Asset.pretty_number(MAX_TOTAL_INV_INSTANCES)} combined instances in your inventory. 💔`)
	end
	
	local success, result = pcall(Serialise.serialise, instance, {UserId = self.player.UserId});
	
	if success then
		local uid = self:get_inventory_uid();
		
		if not self:is_replicating_inventory() then
			table.insert(self.inventory_profile.Data.Saves, {
				uid = uid;
				timestamp = tick();
				instance_count = instance_count;
				data = result;
			})
			
			self:push_notification(NotificationStatus.info, "Saving instance ...");
			self:replicate_inventory();
			self:push_notification(NotificationStatus.success, "Saved selected to inventory 👍");
		else
			self:push_notification(NotificationStatus.error, "Your inventory is still loading 😡💢", 5);
		end;
	else
		self:push_notification(NotificationStatus.info, "Could not save instance to inventory 💔");
	end
end

function Builder:has_gamepass(pass_id: any)
	local gamepass_id = Products.get_pass_id(pass_id);
	
	return self.profile.Data.Builds.Gamepass[tostring(gamepass_id)] or MarketplaceService:UserOwnsGamePassAsync(self.player.UserId, gamepass_id)
end

function Builder:initialise_gamepasses()
	-- Grants gamepass in the table if they own it.

	for pass_id, info in Products.Gamepass do
		if not self.profile.Data.Builds.Gamepass[tostring(pass_id)] and MarketplaceService:UserOwnsGamePassAsync(self.player.UserId, pass_id) then
			self:give_gamepass(pass_id);
		end
	end;

	for pass_name in self.profile.Data.OwnedGamepasses do
		local pass = Gamepasses[pass_name]
		if (pass == nil) then continue end

		if not self.profile.Data.Builds.Gamepass[tostring(pass.ID)] then
			self:give_gamepass(pass.ID);
		end
	end
end

function Builder:give_gamepass(pass_id: number)
	if not Products.Gamepass[pass_id] then return end;
	
	self.stream:set({"Gamepass", tostring(pass_id)}, true);
	
	BuildRemotes.Transactions.SaleGranted:FireClient(self.player, 2, pass_id);
end

function Builder:can_purchase_gamepass(pass_id: number): (boolean, number?)
	local product = Products.Gamepass[pass_id];
	local product_id_str = tostring(pass_id);

	if not product then
		return false, 2;
	end;

	if self.profile.Data.Builds.Gamepass[product_id_str] then
		return false, 1;
	end;
	
	return true, nil;
end;

function Builder:can_purchase_product(product_id: number): (boolean, number?)
	local product = Products.DeveloperProduct[product_id];
	local product_id_str = tostring(product_id);
	
	if not product then
		return false, 2;
	end;
	
	local purchases = self.profile.Data.Builds.Purchases;
	
	if product.one_time and (purchases[product_id_str] and #purchases[product_id_str] > 0) then
		return false, 1;
	end;
	
	return true, nil;
end

function Builder:destroy()
	self:clear_history();
	table.clear(self.throttling);
	
	self.maid:destroy();
	self.record_maid:destroy();
	
	BuildRemotes.DeleteBuildTools:FireClient(self.player);
	
	self:stop_replicating_inventory();
	
	if self.inventory_profile then
		self.inventory_profile:EndSession();
	end;
end

function Builder:clear_history()
	self.record_maid:clean();
	
	table.clear(self.recording);
	table.clear(self.undo_stack);
	table.clear(self.redo_stack);
end

function Builder:filter_text(text: string, filter_context: Enum.TextFilterContext?): (boolean, string)
	return self.build_handler:filter_text(text, self.player.UserId, filter_context);
end

do
	local index_status = {};
	
	for name, index in NotificationStatus do
		index_status[index] = name;
	end;
	
	function Builder:push_notification(status: (string | number), description: string, duration: number?)
		local raw_status = status;
		
		if typeof(status) == "string" then
			status = NotificationStatus[status];
		end;
		
		if not index_status[status] then
			return warn(`{raw_status} is not a valid status`);
		end;
		
		BuildRemotes.Notify:FireClient(self.player, status, description, duration);
	end
end;

function Builder:can_edit_property(instance: Instance, property: string): boolean
	for class, properties in PropertyTable do
		if instance:IsA(class) and table.find(properties, property) then
			return true;
		end
	end
	
	return false;
end

function Builder:cleanse_instances(instances: {Instance}, isA: string?)
	local cleansed = table.create(#instances);
	
	for index, instance in instances do
		if self:can_modify(instance) and (not isA or instance:IsA(isA)) then
			table.insert(cleansed, instance);
		end;
	end;
	
	return cleansed;
end

-----------------------------------------------------------------------------------
-- This is just for compatibility (it should use a combat instead of builder) --
-----------------------------------------------------------------------------------

function Builder:get_root_attachment()
	return self.player.Character.HumanoidRootPart.RootAttachment;
end

function Builder:get_character()
	return self.player.Character;
end

function Builder:get_humanoid()
	return self.player.Character.Humanoid;
end

function Builder:get_player()
	return self.player;
end

-- Oh my goodness !!!! genius !!!
function Builder:get_builder()
	return self;
end

function Builder:spawn_effects_by_builder(source, target)
	self.build_handler:spawn_effects(source, target or self:get_root_attachment());
end;

function Builder:stun_by_builder()
	
end

function Builder:damage_by_builder()
	
end

function Builder:heal_by_builder()
	
end

-----------------------------------------------------------------------------------

function Builder:get_preferences()
	return self.build_data.Preferences;
end

function Builder:make_preferences()
	local list = table.clone(Preferences.defaults);
	
	for name, value in self:get_preferences() do
		list[name] = value;
	end;
	
	return list;
end

function Builder:sanitise_asset(asset: Instance): ()
	for _, instance in asset:GetDescendants() do
		if instance:IsA("LuaSourceContainer") then
			instance:Destroy();
		end;
	end;
end

function Builder:load_map(name: string)
	if self.debounce:has("load_map") then
		return self:push_notification(NotificationStatus.info, `Please wait before inserting map!`, 4);
	end
	
	self.debounce:add("load_map", 10);
	
	local map = InstanceBuild.Maps:FindFirstChild(name);
	
	if not map then
		return self:push_notification(NotificationStatus.error, `{name} is not a valid map.`);
	end;
	
	local attributes = map:GetAttributes();
	
	if attributes.DefaultMap then
		self.build_handler:set_as_map(nil, map);
		
	elseif attributes.InsertAsset then
		local success, asset = pcall(InsertService.LoadAsset, InsertService, attributes.InsertAsset);
		
		if success then
			self:sanitise_asset(asset);
			
			local children = asset:GetChildren();
			
			if #children > 1 then
				warn("Inserted asset contains multiple instances.");
				
			elseif #children == 0 then
				warn("Inserted asset contains no instances.");
				
			else
				self.build_handler:set_as_map(children[1]:Clone(), map);
			end;
		else
			warn("InsertService error:", asset);
			return self:push_notification(NotificationStatus.error, `Something went wrong while trying to load map '{name}', please try again later.`);
		end
	else
		self.build_handler:set_as_map(map:Clone(), map);
	end
	
	self:push_notification(NotificationStatus.success, `Successfully loaded map '{name}'.`);
end

function Builder:set_preference(name: string, value: any)
	if not Preferences.data[name] then
		return self:push_notification(NotificationStatus.warning, `{name} is not a valid preference, bud.`);
	end;
	
	local default = Preferences.defaults[name];
	local caster = Type.define(default);
	
	if not caster or typeof(value) == "table" then
		return;
	end
	
	local new_value, success = caster:cast(value);
	
	if success and is_datastore_serialisable(new_value) then
		self.stream:set({"Preferences", name}, new_value);
	end;
end

function Builder:remove_btools()
	if self.enabled then
		self.enabled = false;
		self:clear_history();
	end;
	
	BuildRemotes.ToggleBuildTools:FireClient(self.player, false);
end

function Builder:give_btools()
	if not self.enabled then
		self.enabled = true;
		self:clear_history();
	end;
	
	BuildRemotes.ToggleBuildTools:FireClient(self.player, true);
end

function Builder:toggle_btools()
	if self.enabled then
		self:remove_btools();
	else
		self:give_btools();
	end;
end

function Builder:save_to_hotbar(slot: number, model: (Instance | string)?)
	if typeof(model) == "Instance" and not self:has_gamepass("PrivateServerPlus") and not model:IsDescendantOf(InstanceAssets) then
		return;
	end;
	
	if (slot >= 1 and slot <= 9) then
		if self.hotbar[slot] then
			local item = self.hotbar[slot];
			
			if not self:is_copy_reference(item) then
				item:Destroy();
			end;
			
			table.remove(self.hotbar, slot); -- oh mein gott !!!!!!
		end;
		
		if typeof(model) == "string" then
			model = BuildShared.Inventory:FindFirstChild(model);
		end;
		
		if self:can_copy(model) then 
			assert(typeof(model) == "Instance", "Model is not an Instance");
			assert(model, "No Instance");
			
			local clone = model;
			
			if not self:is_copy_reference(model) then
				clone = model:Clone();
			end;
			
			self.hotbar[slot] = clone;
		end;
	end
end

function Builder:load_from_hotbar(slot: number, coordinate: CFrame)
	if self.hotbar[slot] then
		self.build_handler:clone_instance(self.hotbar[slot], coordinate, true, BuildsFolder, self);
	end
end

function Builder:throttle(label: string, requests_per_minute: number?, debounce: number?, no_message: boolean?): number
	if not requests_per_minute then
		return math.huge;
	end;

	if not self.throttling[label] then
		self.throttling[label] = {budget = requests_per_minute, last = 0, message_debounce = 0, debounce = 0};
	end;

	local time_now = tick();
	local budgets = self.throttling[label];
	local data = self._data;

	if debounce and time_now - budgets.debounce < debounce then
		return 0;
	end;
	
	local time_elapsed = time_now - budgets.last;
	local added_budget = if time_elapsed < 0.5 then 0 else time_elapsed * (requests_per_minute / 60);

	budgets.debounce = time_now;
	budgets.budget = math.clamp(budgets.budget + added_budget - 1, 0, requests_per_minute);
	budgets.last = time_now;

	local value = math.floor(budgets.budget);

	if not no_message and value == 0 and time_now - budgets.message_debounce > 0.5 then
		budgets.message_debounce = time_now;
		self:push_notification(NotificationStatus.warning, "You have been rate limited, slowdown partner.", 3);
	end
	
	return value;
end

function Builder:clear_clipboard()
	self.clipboard:ClearAllChildren();
end

-- Instances that are clone at demand and are statically presevered (so no deletion of the instance occurs)
function Builder:is_copy_reference(instance: Instance): boolean
	return typeof(instance) == "Instance" and ( instance:IsDescendantOf(InstanceInventory) or instance:IsDescendantOf(InstanceAssets) )
end

function Builder:can_copy(instance: Instance): boolean
	return typeof(instance) == "Instance" and ( InstanceAllowed.can_copy(instance) or instance:IsDescendantOf(self.inventory_storage_folder) );
end

function Builder:can_modify(instance: Instance): boolean
	return typeof(instance) == "Instance" and InstanceAllowed.can_modify(instance);
end

function Builder:can_remove(instance: Instance): boolean
	return typeof(instance) == "Instance" and InstanceAllowed.can_remove(instance);
end

function Builder:voxel_break(info)
	if info.among then
		info.overlap = OverlapParams.new();
		
		local filter = {};
		
		for _, instance in info.among do
			if self:can_modify(instance) then
				table.insert(filter, instance);
			end;
		end;
		
		info.overlap.FilterDescendantsInstances = filter;
		info.overlap.FilterType = Enum.RaycastFilterType.Include;
	else
		info.overlap = voxel_breaker_overlap;
	end;
	
	info.radius = math.clamp(info.radius, 0.5, 250);
	info.block_size = math.clamp(info.block_size, 0.5, 100);
	info.greedy_batch_size = 500;
	info.greedy_opportunistic_batch_size = 250;
	info.size = info.size:Max(Vector3.one):Min(Vector3.one * 250);
	
	local divided, intersecting = Havoc.havoc(info);
	
	for base, cube_list in divided do
		for index, slice in cube_list do
			local cube = base:Clone();
			cube.Size = slice.size;
			cube.CFrame = slice.coordinate;

			self:record_instance(cube);
			cube.Parent = base.Parent;
		end;
		
		self:record_instance(base);
		base.Parent = nil;
	end;
	
	self:commit();
end;

function Builder:edit_instance_modifier(instances, attribute, value)
	for _, instance: Instance in instances do
		if not self:can_modify(instance) then
			continue;
		end;
		
		local modifier = self.build_handler.modifiers.list[instance];
		
		if modifier then
			local last_value = modifier.attributes:get(attribute);
			
			local function set_value(new_value)
				modifier:set_user_attribute(attribute, new_value, self.player.UserId);
			end
			
			set_value(value);
			
			local new_value = modifier.attributes:get(attribute);
			
			if (last_value ~= new_value) then
				self:manual_record_change(instance, "AttributeModifier", {
					prestate = function() set_value(last_value) end,
					poststate = function() set_value(new_value) end,
				})
			end
		end;
	end;
	
	self:commit();
end

function Builder:add_instance_modifier(instances, modifier_tag)
	if self:throttle("add_modifier", 50) == 0 then 
		return;
	end;
	
	local did_add_modifier = false;
	
	for _, instance: Instance in instances do
		if not self:can_modify(instance) then
			continue;
		end;

		if instance:IsA("BasePart") or instance:IsA("Configuration") then
			did_add_modifier = true;
			
			local modifier = Instance.new("Configuration");
			modifier.Name = `@{modifier_tag}`;
			
			modifier:SetAttribute("_InterestId", self.player.userId);
			modifier:SetAttribute("Modifier", modifier_tag);
			modifier:AddTag("InstanceModifier");
			
			self:record_instance(modifier);
			modifier.Parent = instance;
		end;
	end;
	
	if #instances ~= 0 and not did_add_modifier then
		self:push_notification(NotificationStatus.info, "You can only add modifiers on Parts, or Configurations that are a descendant of a Part.")
	end
	
	self:commit();
end;

function Builder:ungroup(instances)
	local children = {};

	local function reparent(instance: Instance)
		for _, child in ipairs(instance:GetChildren()) do
			self:record_instance(instance);
			child.Parent = instance.Parent;
			table.insert(children, child);
		end

		instance.Parent = nil;
	end;

	for _, instance: Instance in self:cleanse_instances(instances, "Model") do
		self:record_instance(instance);
		pcall(reparent, instance);
	end;

	self:commit();
	self:select_yielding(children);
end

function Builder:group(instances)
	local group = Instance.new("Model");
	group.Name = "Group";
	
	local best_parent = BuildsFolder;
	local best_ancestor = math.huge;

	local function reparent(instance: Instance)
		instance.Parent = group;
	end
	
	for _, instance: Instance in self:cleanse_instances(instances) do
		best_ancestor, best_parent = iterate_local_parent(instance, best_ancestor, best_parent);
		
		self:record_instance(instance);
		pcall(reparent, instance);
	end;
	
	self:record_instance(group);
	group.Parent = best_parent;
	
	self:commit();
	self:select_yielding({group})	
end

function Builder:create_mesh(mesh_id: string, texture_id: string, collision_fidelity: Enum.CollisionFidelity): MeshPart?
	mesh_id = Asset.get_rbx_asset(mesh_id);
	texture_id = Asset.get_rbx_asset(texture_id);
	
	local mesh_part = Serialise.create_mesh_part(mesh_id, texture_id, collision_fidelity);
	
	if mesh_part then
		mesh_part.CFrame = self:get_spawning_cframe();
		mesh_part.Anchored = true;
		
		self:record_instance(mesh_part);
		mesh_part.Parent = BuildsFolder;
		
		return mesh_part;
	end;
	
	return nil;
end;

function Builder:weld(instances)
	local instances: {BasePart} = self:cleanse_instances(instances, "BasePart");
	local target: BasePart? = table.remove(instances);
	
	if not target then return end;
	
	for _, instance in instances do
		assert(instance:IsA("BasePart"));
		
		local weld = Instance.new("Weld");
		weld.Part0 = instance;
		weld.Part1 = target;
		weld.C0 = instance.CFrame:ToObjectSpace(target.CFrame);
		
		self:record_instance(instance);
		self:record_instance(weld);
		
		instance.Anchored = false;
		weld.Parent = instance;
	end;
	
	self:commit();
end;

function Builder:unweld(instances)
	local instances: {Instance} = self:cleanse_instances(instances);
	
	local function unweld_instance(instance: Weld): ()
		self:record_instance(instance);
		
		if instance.Part0 and instance.Part1 then
			self:record_instance(instance.Part0);

			instance.Part0.Anchored = true;
		end;
		
		instance.Parent = nil;
	end;
	
	for _, instance in instances do
		if instance:IsA("Weld") then
			unweld_instance(instance);
		else
			for _, child in instance:GetDescendants() do
				if child:IsA("Weld") then
					unweld_instance(instance);
				end
			end
		end
	end

	self:commit();
end

function Builder:anchor_to(instances, value)
	local instances: {Instance} = self:cleanse_instances(instances);
	local anchor = not not value

	local function anchor_all(instance: Instance)
		if instance:IsA("BasePart") then
			self:record_instance(instance);

			instance.Anchored = anchor;
		end
	end

	for _, instance in instances do
		anchor_all(instance);
		for _, child in instance:GetDescendants() do
			anchor_all(child);
		end
	end

	self:commit();
end

function Builder:get_instance_count(instances): number
	local count = 0;
	
	for _, instance in instances do
		count += 1;
		
		for _, child in instance:GetDescendants() do
			count += 1;
		end;
	end;
	
	return count;
end

function Builder:retrieve_slot_history(slot: any)
	local data = {};
	
	if self:throttle("get_slot_history", 45, 3, true) == 0 then 
		self:push_notification(NotificationStatus.warning, `Please wait before refreshing versions`);
		return data;
	end;

	local history = self:get_slot_version_history(slot, 10);
	
	for _, item in history do
		table.insert(data, {CreatedTime = item.CreatedTime, Version = item.Version})
	end
	
	return data;
end

function Builder:copy(instances)
	if self:throttle("cloning", 75) == 0 then 
		return;
	end;
	
	local count = self:get_instance_count(instances);

	if (count > 20_000) then
		return self:push_notification(NotificationStatus.error, `Cannot copy more than {Asset.pretty_number(20_000)} instances.`);
	end;
	
	self:clear_clipboard();
	
	for _, instance: Instance in self:cleanse_instances(instances) do
		local cloned = instance:Clone();
		self:record_instance(cloned);
		cloned.Parent = self.clipboard;
	end;
	
	self.clipboard.WorldPivot = self.clipboard:GetBoundingBox();
end

function Builder:paste(into: Instance?, coordinate: CFrame)
	if self:throttle("cloning", 75) == 0 then 
		return;
	end;
	
	if not into then
		into = BuildsFolder;
	end;
	
	if not coordinate then
		coordinate = CFrame.identity;
	end;
	
	if self:can_modify(into) or into == BuildsFolder then
		self.clipboard:PivotTo(coordinate);
		
		for _, instance in self.clipboard:GetChildren() do
			local clone_instance = instance:Clone();
			self:record_instance(clone_instance);
			clone_instance.Parent = into;
		end;
	end;
end

function Builder:clone(instances)
	if self:throttle("cloning", 75) == 0 then 
		return;
	end;
	
	local cloned = {};

	local function clone(instance: Instance)
		local clone = instance:Clone()
		self:record_instance(clone);
		clone.Parent = instance.Parent;

		table.insert(cloned, clone);
	end;

	for _, instance: Instance in self:cleanse_instances(instances) do
		pcall(clone, instance);
	end;

	self:select_yielding(cloned);
end

function Builder:delete(instances)
	local function delete(instance: Instance)
		instance.Parent = nil;
	end;

	for _, instance: Instance in self:cleanse_instances(instances) do
		if not self:can_remove(instance) then
			continue;
		end;
		
		self:record_instance(instance);

		pcall(delete, instance);
	end

	self:commit();
end


do
	local function modify_property(self, instance: Instance, property: string, value: any, record: boolean, parts: {BasePart}, cframes: {CFrame}): ()
		if typeof(property) ~= "string" then return end;
		if (value == Table.null) then value = nil end;

		for isa: string, properties in pairs(PropertyCustom) do
			if properties[property] and instance:IsA(isa) then
				return properties[property].Set(instance, value);
			end
		end

		for isa: string, properties: {[string]: (any) -> (any)} in pairs(PropertyHelper) do
			if properties[property] and instance:IsA(isa) then
				value = properties[property](value);
			end
		end
		
		if property == "Parent" then
			if self:can_remove(instance) or (value == BuildsFolder or self:can_modify(value)) then
				instance.Parent = value;
			end
			
		elseif property == "Name" then
			
			-- We don't want people to rename services, that's a big compatibility no-no.
			if (instance.Parent ~= game) then
				instance.Name = self:filter_text(value);
			end;
			
		elseif typeof(value) ~= "Instance" or self:can_remove(value) then
			
			if self:can_edit_property(instance, property) then
				if property == "CFrame" and instance:IsA("BasePart") then
					parts[#parts + 1] = instance;
					cframes[#cframes + 1] = value :: CFrame;
					
				elseif typeof(value) == "string" then
					instance[property] = self:filter_text(value);
				else
					instance[property] = value;
				end
				
			elseif instance:IsA("Model") then
				if property == "CFrame" then
					local initial_pivot = instance:GetPivot();
					--local bounding_origin = instance:GetBoundingBox();
					local new_pivot = (value :: CFrame) -- * bounding_origin:ToObjectSpace(initial_pivot); -- CFrame that ignores pivots
					
					if record then
						self:manual_record_change(instance, "PivotTo", {
							prestate = function() instance:PivotTo(initial_pivot); end,
							poststate = function() instance:PivotTo(new_pivot); end,
						})
					end;

					instance:PivotTo(new_pivot);
					
				elseif property == "Size" then
					local new_value = value :: number;
					local previous = instance:GetScale();

					if record then
						self:manual_record_change(instance, "ScaleTo", {
							prestate = function() instance:ScaleTo(previous); end,
							poststate = function() instance:ScaleTo(new_value); end,
						})
					end;
					
					instance:ScaleTo(new_value);
				end
			end
		end
	end
	
	function Builder:modify_instances(instances: {Instance}, properties: {[string]: {any}}, record: boolean?): ()
		local parts: {BasePart};
		local cframes: {CFrame};
		
		if properties.CFrame then
			parts, cframes = {}, {};
		end
		
		for index, instance in instances do
			if not self:can_modify(instance) then
				continue;
			end;
			
			if record then
				self:record_instance(instance);
			end;
			
			for property, dictionary in properties do
				local value = dictionary[index];
				
				if value ~= nil then
					pcall(modify_property, self, instance, property, value, record or false, parts, cframes);
				end;
			end
		end;
		
		if parts and cframes then
			workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged);
		end;
		
		self:commit()
	end
end;

function Builder:get_spawning_cframe(coordinate: CFrame?)
	if typeof(coordinate) ~= "CFrame" then
		if self.player.Character then
			coordinate = self.player.Character:GetPivot() * CFrame.new(0, 0, -8);
		else
			coordinate = CFrame.identity;
		end;
	end;
	
	return coordinate;
end

function Builder:spawn(name, count, parent, coordinate, auto_select)
	if self:throttle("spawn", 125) == 0 then 
		return;
	end;
	
	if not self:can_modify(parent) and parent ~= BuildsFolder then
		return;
	end;
	
	local coordinate = self:get_spawning_cframe(coordinate);
	local instances = {};
	
	for count = 1, math.clamp(count or 1, 1, 5) do
		table.insert(instances, self:spawn_instance(name, coordinate, true, true, parent));
	end;
	
	if auto_select and #instances > 0 then
		self:select(instances);
	end;
	
	self:commit()
end

function Builder:clear_all()
	if self:throttle("clear_all", 5) == 0 then
		return;
	end;
	
	BuildsFolder:ClearAllChildren();
	
	for _, builder in self.build_handler.builders do
		builder:clear_history();
		builder:select({});
	end
	
	self.build_handler:restore_game_state();
	
	self:push_notification(NotificationStatus.success, ClearAllMessages[math.random(#ClearAllMessages)], 5);
	self.build_handler:push_global_notification(NotificationStatus.info, `Player '{self.player.Name}' has cleared the workspace.`, 10);
end

function Builder:spawn_instance(name: string, coordinate: CFrame?, record: boolean?, deploy: boolean?, parent: Instance?): Instance
	return self.build_handler:spawn_instance(name, coordinate, deploy, parent, if record then self else nil);
end

function Builder:get_slot_key(slot: string)
	return `user_{self.player.UserId}_{slot}`
end

function Builder:is_slot_name_valid(name: unknown)
	if typeof(name) ~= "string" then
		return false;
	end;
	
	if string.len(name) > 64 then 
		self:push_notification(NotificationStatus.error, "Slot Label is too long in length!");
		
		return false;
	end;
	
	return true;
end

function Builder:initialise_slots()
	for slot = 1, self.build_data.SlotAmount do
		self:get_profile_slot(slot);
	end;
end

function Builder:get_profile_slot(slot: number)
	if self:has_slot(slot) then
		local slot_index = tostring(slot);
		local data = self.build_data.Slots[slot_index];
		
		if not data then
			data = {Label = nil};
			self.stream:set({"Slots", slot_index}, data);
		end;
		
		return data;
	end;
	
	return nil;
end

function Builder:has_slot(slot: any): boolean
	local num_slot = tonumber(slot)
	
	if num_slot then
		return num_slot >= 0 and num_slot <= self.build_data.SlotAmount;
	end;
	
	return false;
end;

function Builder:get_slot_version_history(slot: any, amount: number)
	if not self:has_slot(slot) then 
		return self:push_notification(NotificationStatus.error, `You do not have access to this slot!`)
	end;
	
	local list_success, pages = pcall(function()
		return BuildStore:ListVersionsAsync(self:get_slot_key(slot), Enum.SortDirection.Descending, nil, nil, amount)
	end)
	
	if list_success then
		local items = pages:GetCurrentPage();
		
		return items;
	end;
	
	return {};	
end

function Builder:load_slot(slot: number, version_number: any)
	if self.debounce:has("load") then
		return self:push_notification(NotificationStatus.info, `Please wait before attempting to load ...`) 
	end
	
	if not self:has_slot(slot) then 
		return self:push_notification(NotificationStatus.error, `You do not have access to this slot!`)
	end
	
	self.debounce:add("load");
	
	local message = self.build_handler:create_message({
		Title = "Loading Build", 
		SubTitle = "Retrieving from Datastore",
		CanClose = true;
	})
	
	local success, result = pcall(function()
		local key = self:get_slot_key(slot);
		
		if version_number then
			return BuildStore:GetVersionAsync(key, version_number);
		else
			return BuildStore:GetAsync(key);
		end
	end);
	
	self.debounce:add("load", 10);
	
	if not success then
		warn("BuildStore Error: ", result);
		self:push_notification(NotificationStatus.error, `Unable to load slot {slot} (Datastore Failure)`);
		
	elseif result then
		local success, builds = self:load_build(message, result);
		
		if success then
			if builds and builds[1] then
				self:push_notification(NotificationStatus.success, `Successfully loaded slot {slot}`);
				self.build_handler:push_global_notification(NotificationStatus.info, `{self.player.Name} has loaded a slot`);
			else
				self:push_notification(NotificationStatus.warning, `Unable to load slot {slot}, no instances were returned.`);
			end;
		end;
	else
		self:push_notification(NotificationStatus.warning, `Unable to load slot {slot} (No Data)`);
	end;
	
	message:Destroy();
end

local ONE_FRAME = 1 / 60;

function Builder:load_build(message, serialised)
	local success = true;
	local builds;
	
	local function deserialise_instances(instances_string: string, form: string)
		local parameters = { UserId = self.player.UserId };
		
		if message then
			parameters.InstanceIterator = function(token_map, instance, step, max_step)
				if step % 2_000 == 0 then
					task.wait(ONE_FRAME);
				end;

				message:SetAttribute("SubTitle", `{form}Instances {step * 100 // max_step}%`)
			end

			parameters.PropertyIterator = function(token_map, instance, step, max_step)
				if step % 1_000 == 0 then
					task.wait(ONE_FRAME);
				end;

				message:SetAttribute("SubTitle", `{form}Properties {step * 100 // max_step}%`)
			end

			parameters.DecompressIterator = function(step, max_step)
				message:SetAttribute("SubTitle", `Zlib Decompress {step * 100 // max_step}%`);
				task.wait(ONE_FRAME);
			end;
		end;
		
		local serial_success, instances, non_instantiable = pcall(Serialise.deserialise, instances_string, parameters);
		local children = {};
		local properties = {};
		
		if not serial_success then
			local error_line_index = string.find(instances, "%d");

			if error_line_index then
				self:push_notification(NotificationStatus.info, string.sub(instances, error_line_index, -1));
			end;
			
			success = false;
			
		elseif serial_success and not instances then
			self:push_notification(NotificationStatus.warning, `Unable to load (no data)`);
			
		else
			children = instances;
			properties = non_instantiable;
		end;
		
		return children, properties;
	end
	
	if typeof(serialised) == "table" and serialised.version == 1 then
		-- Newer format that supports lighting and teams saving
		builds = deserialise_instances(serialised.instances.builds, "Builds ");
		local builds_folder = builds[1];
		
		if builds_folder then
			for _, instance in builds_folder:GetChildren() do
				instance.Parent = BuildsFolder;
			end
			
			builds_folder:Destroy();
		end;
		
		if serialised.instances.lighting then
			self.build_handler:clear_lighting_effects();
			
			local lighting_instances, properties = deserialise_instances(serialised.instances.lighting, "Lighting ");
			local lighting_config = lighting_instances[1];
			
			for _, instance in lighting_config:GetChildren() do
				instance.Parent = Lighting;
			end;
			
			if properties[lighting_config] then
				Serialise.apply_properties(Lighting, properties[lighting_config]);
			end;
		end;
		
		if serialised.instances.teams then
			local team_instances = deserialise_instances(serialised.instances.teams, "Teams ");

			for _, instance in team_instances do
				instance.Parent = Teams;
			end;
		end
	else
		-- Raw build data to unpack inside the builds folder
		
		builds = deserialise_instances(serialised, "");
		local builds_folder = builds[1];
		
		if builds_folder then
			for _, instance in builds_folder:GetChildren() do
				instance.Parent = BuildsFolder;
			end;

			builds_folder:Destroy();
		end;
	end;
	
	return success, builds;
end

function Builder:save_build(message)
	local success = true;
	local total_size = 0;
	
	local function serialise_instances(instance: Instance, form: string)
		local parameters = {
			UserId = self.player.UserId;
		};
		
		if message then
			parameters.InstanceIterator = function(token_map, instance, step, max_step)
				if step % 2_000 == 0 then
					task.wait(ONE_FRAME);
					message:SetAttribute("SubTitle", `{form}Instances {step * 100 // max_step}%`)
				end;
			end

			parameters.PropertyIterator = function(token_map, instance, step, max_step)
				if step % 1_000 == 0 then
					task.wait(ONE_FRAME);
					message:SetAttribute("SubTitle", `{form}Properties {step * 100 // max_step}%`)
				end;
			end

			parameters.CompressIterator = function(step, max_step)
				task.wait(ONE_FRAME);
				message:SetAttribute("SubTitle", `{form}Zlib Compress {step * 100 // max_step}%`)
			end;
		end;
		
		local serial_success, data, size = pcall(Serialise.serialise, instance, parameters);
		
		if not serial_success then
			success = false;
		else
			total_size += size;
			
			return data;
		end;
	end;
	
	local data = {
		version = 1,
		instances = {
			builds = serialise_instances(BuildsFolder, "Builds ");
			lighting = serialise_instances(Lighting, "Lighting ");
			teams = serialise_instances(Teams:GetChildren(), "Teams ");
		};
	};
	
	return success, data, total_size;
end

function Builder:save_slot(slot: number)
	if self.debounce:has("save") then 
		return self:push_notification(NotificationStatus.info, `Please wait before attempting to save ...`) 
	end
	
	if not self:has_slot(slot) then 
		return self:push_notification(NotificationStatus.error, `You do not have access to this slot!`)
	end
	
	self.debounce:add("save");
	
	local message = self.build_handler:create_message({
		Title = "Saving Build", 
		SubTitle = "-",
		CanClose = true;
	})
	
	local message_used = message;
	
	-- Auto Save slot doesn't show message
	if slot == 0 then
		message_used = nil;
		message:Destroy();
	end;
	
	local serial_success, data, size = self:save_build(message_used);
	
	if not serial_success then
		warn("Serialiser Error:", data);
		
		message:Destroy();
		self.debounce:add("save", 5);
		
		return self:push_notification(NotificationStatus.error, `Unable to save to slot {slot}, serialiser could not serialise Instance.`);
	end;
	
	message:SetAttribute("Title", "Writing to Datastore");
	message:SetAttribute("SubTitle", `Finishing up`)
	
	local success, result = pcall(function()
		BuildStore:SetAsync(self:get_slot_key(slot), data, {self.player.UserId});
	end);
	
	message:Destroy();
	
	self.debounce:add("save", 10);
	
	if size then
		local megabytes = string.format("%.1f", size / 1_000 / 1_000);

		self:push_notification(NotificationStatus.info, `Using {megabytes}/4 MB`, 8)
	end;
	
	if not success then
		warn("BuildStore Error:", result);
		
		local error_code = string.match(result, "^%d+");
		
		if (error_code == "105") then
			self:push_notification(NotificationStatus.error, `Unable to save to slot {slot} because you have exceeded the 4MB limit!`, 25)
			self:push_notification(NotificationStatus.info, `Try deleting some things from your build and try again.`, 25)
			
		elseif (error_code == "104") then
			self:push_notification(NotificationStatus.error, `Unable to save to slot {slot} because of a bad UTF-8 character`, 25)
			self:push_notification(NotificationStatus.info, `Some instance or thing may be incompatiable. We're sorry!`, 25)
			
		elseif error_code then
			self:push_notification(NotificationStatus.error, `Unable to save to slot {slot} ({error_code})`);
		else
			self:push_notification(NotificationStatus.error, `Unable to save to slot {slot} as an unknown error occured.`);
		end;
	else
		self:push_notification(NotificationStatus.success, `Successfully saved to slot {slot}`)
	end;
end

function Builder:record_instances(instances: {Instance})
	for _, instance in instances do
		self:record_instance(instance);
	end
end


function Builder:record_instance(instance: Instance)
	if self.recording[instance] then
		return self.recording[instance];
	end;
	
	local recording = {
		begin_state = get_instance_state_properties(instance);
		end_state = {};
	};
	
	self.record_maid:add(instance.Changed:Connect(function(property)
		if BustProperties[property] then return end;
		
		local success, value = pcall(get_property, instance, property);
		
		if success then
			if value == nil then
				value = Table.null;
			end;
			
			recording.end_state[property] = value;
		end;
	end))
	
	self.recording[instance] = recording;
	
	return recording;
end

function Builder:manual_record_change(instance: Instance, state: string, state_changes: any)
	local recording = self.recording[instance];
	
	if not recording then
		recording = self:record_instance(instance);
	end;
	
	if recording then
		recording.begin_state[state] = state_changes.prestate;
		recording.end_state[state] = state_changes.poststate;
	end;
end

function Builder:select(instances: {Instance})
	BuildRemotes.CaptureSelection:FireClient(self.player, instances);
end

function Builder:select_yielding(instances: {Instance})
	local uid = self.build_handler:generate_streaming_id()
	
	for _, instance in instances do
		instance:AddTag(uid);
	end;
	
	BuildRemotes.ReliableCaptureSelection:FireClient(self.player, uid, #instances);
	
	task.delay(20, function()
		for _, instance in instances do
			instance:RemoveTag(uid);
		end;
	end)
end

local function commit(self, as_undo)
	if no_recording_changes(self.recording) then return; end;

	if #self.undo_stack >= 150 then
		-- This is going to be SLOW
		table.remove(self.undo_stack, 1);
	end

	table.insert(self.undo_stack, self.recording);

	self.record_maid:clean();
	self.recording = {};
end

function Builder:commit(as_undo)
	task.defer(commit, self, as_undo);
end

function Builder:is_history_selectable(instance: Instance)
	return instance.Archivable and not instance:HasTag("InstanceModifier") and not instance:HasTag("SelectionIgnore")
end;

function Builder:redo()
	if not next(self.redo_stack) then
		return;
	end;
	
	local changes = table.remove(self.redo_stack);
	table.insert(self.undo_stack, changes);
	
	local selection = {};
	local messages = {};
	
	for instance, props in changes do
		if self:is_history_selectable(instance) then
			table.insert(selection, instance);
		else
			local message = `Special Instance redone was {instance.Name}`;

			if not messages[message] then
				messages[message] = true;
			end
		end;
		
		for property, value in props.end_state do
			if (value == Table.null) then
				value = nil;
			end;
			
			if typeof(value) == "function" then
				pcall(value);
			else
				pcall(modify_property, instance, property, value);
			end
		end;
	end
	
	for message in messages do
		self:push_notification(NotificationStatus.info, message, 2.5)
	end;
	
	if #selection >= 1 then
		self:select(selection)
	end
end

function Builder:undo()
	if not next(self.undo_stack) then
		return;
	end;
	
	local changes = table.remove(self.undo_stack);
	table.insert(self.redo_stack, changes);
	
	local selection = {};
	local messages = {};
	
	for instance, props in changes do
		if self:is_history_selectable(instance) then
			table.insert(selection, instance);
		else
			local message = `Special Instance undone was {instance.Name}`;
			
			if not messages[message] then
				messages[message] = true;
			end
		end;
		
		for property, value in props.begin_state do
			if (value == Table.null) then
				value = nil;
			end;
			
			if typeof(value) == "function" then
				pcall(value);
			else
				pcall(modify_property, instance, property, value);
			end
		end;
	end;
	
	for message in messages do
		self:push_notification(NotificationStatus.info, message, 2.5)
	end;
	
	if #selection >= 1 then
		self:select(selection)
	end
end

table.freeze(Builder);

return Builder;