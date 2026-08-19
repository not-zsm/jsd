if shared.IsRankedLobby or shared.IsRankedPlace then
	return {}
end

local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local Lighting = game:GetService("Lighting")

local Unpacker = require( script.Unpacker )

--------------------------------------------------------------

local BuildsFolder = workspace:FindFirstChild("Builds");

local BuildShared = Unpacker.Shared;
local Remotes = Unpacker.Remotes;
local InstanceBuild = BuildShared.Assets.Build;
local InstanceAssets = InstanceBuild.Insert;
local InstanceInventory = InstanceBuild.Inventory;

--------------------------------------------------------------

local Observer = require( Unpacker.Packages.Observer );
local Instances = require( Unpacker.Packages.Instances );
local Maid = require( Unpacker.Packages.Maid );
local StreamService = require( Unpacker.Packages.StreamService )
local StateIndex = require( Unpacker.Shared.Data.ModifierStateIndex );

local Products = require(BuildShared.Data.Products);
local GapFill = require( BuildShared.Utility.GapFill );
local Asset = require( ReplicatedStorage.Packages.Asset )

local Sections = require( script.InstanceModifier.Sections )
local InstanceModifier = require( script.InstanceModifier )
local TransactionHandler = require( script.TransactionHandler )
local SkillBuilder = require( script.SkillBuilder )
local Builder = require( script.Builder )
local Serialise = require( script.Serialise )
local Pulse = require( script.InstanceModifier.Pulse )

local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList );

local StringAllowList = { ["false"] = true, ["true"] = true, [""] = true, [" "] = true };
local DisableFilterForTypes = { ["table"] = true, ["function"] = true };
local FilterDefaultTypes = { ["string"] = true };

--------------------------------------------------------------

local BuildHandler = {}
BuildHandler.__index = BuildHandler;

--------------------------------------------------------------

local function assert_needs_initialised(self)
	assert(self.is_initialised, "You must initialise the BuildHandler before using its methods.")
end

function BuildHandler:initialise_collisions()
	local function register_collision_group(name: string)
		if not PhysicsService:IsCollisionGroupRegistered(name) then
			PhysicsService:RegisterCollisionGroup(name);
		end
	end

	local function set_collidable(group_1: string, group_2: string, collidable: boolean)
		if PhysicsService:IsCollisionGroupRegistered(group_1) then
			PhysicsService:CollisionGroupSetCollidable(group_1, group_2, collidable);
		end
	end
	
	register_collision_group("BuildPlacement");
	register_collision_group("Player");
	register_collision_group("Entity");
	
	set_collidable("BuildPlacement", "BuildPlacement", false)
	set_collidable("Entity", "BuildPlacement", false)
	set_collidable("Player", "BuildPlacement", false)
end

function BuildHandler:initialise_if_not()
	if not self.is_initialised or not self.is_replicated_initialised then
		self:initialise();
	end
end

function BuildHandler:initialise()

	print("[BuildHandler]: Initialising on demand");
	
	if not BuildsFolder then
		BuildsFolder = Instance.new("Folder");
		BuildsFolder.Name = "Builds";
		BuildsFolder.Parent = workspace;
	end
	
	if not self.is_initialised then 
		self:initialise_observers();
		self:initialise_replicated();
		
		pcall(BuildHandler.initialise_collisions, self);
		
		self.current_map = Unpacker.DefaultMap;
		
		self.game_state_properties = {
			[Lighting] = Serialise.clone_properties(Lighting);
		};
		
		self.game_state_children = {
			[Lighting] = {};
		};
		
		for _, item in Lighting:GetChildren() do
			table.insert(self.game_state_children[Lighting], item:Clone());
		end;
		
		if not next(Serialise.InstanceCache) then
			for _, instance in InstanceAssets:GetChildren() do
				Serialise.InstanceCache[instance.Name] = self:clone_instance(instance);
			end;
		end
		
		if RunService:IsStudio() then
			Serialise.error_check_inventory();
		end;

		Serialise.compile();

		self:make_hooks();
		self.is_initialised = true;
		
	elseif not self.is_replicated_initialised then
		self:initialise_replicated();
	else
		return warn("[BuildHandler] Already initialised!");
	end;
	
	print("[BuildHandler]: Now ready for use!");
end;

-- Does not fully uninitialise the BuildHandler, its too risky to do so.
function BuildHandler:uninitialise()
	warn("[BuildHandler]: Uninitialising");
	
	Unpacker.unload();
	
	self.is_replicated_initialised = false;
end

function BuildHandler:initialise_observers()
	Observer.observe_tag("ModelLocked", function(model: Model)
		local function set_descendant(descendant: Instance, value: boolean)
			if descendant:IsA("BasePart") then
				descendant.Locked = value;
			end;
		end;
		
		for _, descendant in model:GetDescendants() do
			set_descendant(descendant, true);
		end;
		local connection = model.DescendantAdded:Connect(function(descendant)
			set_descendant(descendant, true)
		end)

		return function()
			connection:Disconnect();
			
			for _, descendant in model:GetDescendants() do
				set_descendant(descendant, false);
			end;
		end
	end)
	
	-- Modifiers are loaded when parented into the workspace, and destroyed when leaving the workspace.
	-- Unless load modifier is called on a modifier that isn't already loaded, in that case the modifier will not create or destroy upon entering the workspace.
	Observer.observe_tag_at("InstanceModifier", workspace, function(config: Configuration)
		local modifier = self:load_modifier(config);
		
		-- Failed to load modifier (may be already created)
		if not modifier then
			return;
		end;
		
		return function()
			modifier:destroy();
			modifier = nil;
		end;
	end)
end;

function BuildHandler:load_modifier(instance: Instance)
	if InstanceModifier.list[instance] then return; end;

	local tag_name = instance:GetAttribute("Modifier");
	
	if tag_name then
		local module = InstanceModifier.find(tag_name);
		
		if module then
			return require(module).new(self, instance);
		end;
	end;
end;

function BuildHandler:load_modifiers(instance: Instance)
	if instance:HasTag("InstanceModifier") then
		self:load_modifier(instance);
	end;
	
	for _, object in instance:GetDescendants() do
		if object:HasTag("InstanceModifier") then
			self:load_modifier(object);
		end;
	end;
end;

function BuildHandler:initialise_replicated()
	Unpacker.load();
	
	self.is_replicated_initialised = true;
end;

function BuildHandler:clear_lighting_effects()
	-- Remove all lighting effects
	for _, item in Lighting:GetChildren() do
		if item:IsA("Atmosphere") or item:IsA("Sky") or item:IsA("BloomEffect") or item:IsA("ColorCorrectionEffect") or item:IsA("SunRaysEffect") or item:IsA("DepthOfFieldEffect") then
			item:Destroy();
		end;
	end;
end;

function BuildHandler:restore_game_state()
	if self.game_state_properties then
		for instance, properties in self.game_state_properties do
			Serialise.apply_properties(instance, properties);
		end;
	end;
	
	if self.game_state_children then
		
		for service, children in self.game_state_children do
			
			if service == Lighting then
				self:clear_lighting_effects();
				
				for _, item in children do
					local clone_item = item:Clone();
					clone_item.Parent = service;
				end;
			end;
		end;
	end
end;

function BuildHandler:get_effects_list()
	if not self._effects_list then
		self._effects_list = {};
		
		for index, effect in Unpacker.Effects:GetChildren() do
			self._effects_list[index] = effect.Name;
		end;
	end
	
	return self._effects_list;
end

-- Should support giving a Character or Player instance.
function BuildHandler:get_combat(instance)
	local lua_player = LuaPlayerList.Get(instance)

	if lua_player then
		return lua_player.Character.Combat;
	end
end

function BuildHandler:spawn_effects(source, target, parameters)
	if typeof(source) == "string" then
		source = Instances.find_directory(Unpacker.Effects, source, "/");
	end;

	if typeof(target) == "Instance" and not target:IsDescendantOf(workspace) then
		if target:IsA("PVInstance") then
			target = target:GetPivot();
			
		elseif target:IsA("Attachment") then
			target = target.WorldCFrame;
		end
	end;
	
	Remotes.Effects.SpawnEffects:FireAllClients(source, target, parameters);
end

function BuildHandler:generate_streaming_id(): string
	self.tag_stream_id += 1;
	return `_TEMP_rcs{self.tag_stream_id}`;
end

function BuildHandler:filter_text(text: string, user_id: number, filter_context: Enum.TextFilterContext?): string
	-- Simple exclusions from the filter,
	-- Including: Asset IDs such as 'rbxassetid://0'
	-- Including: Any Valid Numbers
	-- Including: True and False primitives
	if Asset.get_asset_id(text) or tonumber(text) ~= nil or StringAllowList[string.lower(text)] then
		return tostring(text);
	end;
	
	if not filter_context then 
		filter_context = Enum.TextFilterContext.PublicChat
	end;

	local success, filter = pcall(TextService.FilterStringAsync, TextService, text, user_id, filter_context)
	
	if success then
		local success, filter_string = pcall(filter.GetNonChatStringForBroadcastAsync, filter);
		
		if success then
			return filter_string;
		end;
	end
	
	return "";
end;

-- No swear words today brochacho ✅
function BuildHandler:sanitize_block(user_id: number, value: any, info_block): any
	local use_filtering = true;
	
	if info_block.ValueList then
		local list_type = typeof(info_block.ValueList);
		
		if DisableFilterForTypes[list_type] then
			use_filtering = false;
		end;
		
		-- Re-enable filtering if it not within the list
		if list_type == "table" then
			use_filtering = not info_block.ValueList[value] and table.find(info_block.ValueList, value) == nil;
			
		elseif list_type == "function" then
			use_filtering = info_block.ValueList(self, value) == nil;
		end;
	end;
	
	local normal_type = info_block.Type or typeof( info_block.Default );
	
	if typeof(value) == "string" and info_block.Filtered ~= false and ( (use_filtering and FilterDefaultTypes[normal_type]) ) then
		value = self:filter_text(value, user_id);
	end;
	
	return value;
end;

function BuildHandler:can_debug(player: Player)
	if RunService:IsStudio() then
		return true;
	end;
	
	return false;
end

function BuildHandler:give_builder_permissions(player: Player, permission)
	if permission then
		assert(Builder.all_access_permissions[permission], `No such permission {permission}`)
	end;

	local builder = self:get(player);
	assert(builder, "No builder");

	if permission then
		builder.permissions[permission] = true;
	else
		builder.permissions = table.clone(Builder.all_access_permissions)
	end
end

function BuildHandler:revoke_builder_permissions(player: Player, permission)
	assert(Builder.all_access_permissions[permission], `No such permission {permission}`)
	
	local builder = self:get(player);
	assert(builder, "No builder");
	
	if builder then
		builder.permissions[permission] = false;
	end
end

--[[
	Attributes are:
	* Title - The bold title that shows on top. 
	* SubTitle - The smaller text under the title.
	* VisibleTo - If set to a player, the message will only show for them.
	* CanClose - Whether the message can be closed.
	* Duration - How long the message lasts
]]
function BuildHandler:create_message(attributes)
	local messager = Instance.new("Configuration");
	messager.Name = "Message";
	messager.Archivable = false;
	
	local player: Player?;
	
	if attributes.VisibleTo then
		player = attributes.VisibleTo;
		attributes.VisibleTo = nil;
	end;
	
	if attributes.Duration then
		task.delay(attributes.Duration, messager.Destroy, messager);
		attributes.Duration = nil;
	end
	
	for attribute, value in attributes do
		messager:SetAttribute(attribute, value);
	end;
	
	messager:AddTag("BuildMessage");
	
	if player then
		messager.Parent = player.PlayerGui;
	else
		messager.Parent = Unpacker.BuildTools;
	end;
	
	return messager;
end

function BuildHandler:push_global_notification(status: number, message: string, duration: number?)
	for _, builder in self.builders do
		builder:push_notification(status, message, duration);
	end;
end;

function BuildHandler:start_cleanup_sequence()
	assert_needs_initialised(self);
	
	self:stop_cleanup_sequence();
	
	self.cleanup_thread = task.delay(60, function()
		warn("[BuildHandler]: Starting Automatic Uninitialisation");
		
		self:stop_cleanup_sequence();
		self:uninitialise();
	end)
end

function BuildHandler:stop_cleanup_sequence()
	assert_needs_initialised(self);
	
	if self.cleanup_thread then
		if coroutine.status(self.cleanup_thread) == "suspended" then
			task.cancel(self.cleanup_thread);
		end;
		
		self.cleanup_thread = nil;
	end;
end;

function BuildHandler:can_start_cleanup(): boolean
	if self.is_replicated_initialised and next(self.builders) == nil then
		return true;
	end;
	
	return false;
end

function BuildHandler:add_builder(player: Player, profile)
	assert(profile, "Profile was not passed");
	
	self:initialise_if_not();
	self:stop_cleanup_sequence();
	
	if not self.builders[player] then
		self.builders[player] = Builder.new(self, player, profile);
		
		self:give_builder_permissions(player);
	end;
	
	return self.builders[player];
end

function BuildHandler:remove_builder(player: Player)
	local builder = self.builders[player];
	
	if builder then
		builder:destroy();
		
		self.builders[player] = nil;
		
		if self:can_start_cleanup() then
			self:start_cleanup_sequence();
		end;
	end;
end

function BuildHandler:get_by_userid(user_id: number)
	return self:get( Players:GetPlayerByUserId(user_id) );
end

function BuildHandler:get(instance: Instance?)
	if not instance then
		return nil;
	end;
	
	local builder = 
		self.builders[instance] or
		self.builders[Players:GetPlayerFromCharacter(instance)]
	
	return builder;
end

function BuildHandler:remove_map()
	assert_needs_initialised(self);
	
	if self.current_map then
		if self.current_map ~= Unpacker.DefaultMap then
			self.current_map:Destroy()
		else
			self.current_map.Parent = ServerStorage;
		end;
		
		self.current_map = nil;
		
		BuildShared.Data.SourceMap.Value = nil;
	end;
end

function BuildHandler:set_as_map(map: Instance, source_map: Instance?): ()
	assert_needs_initialised(self);
	
	if not map then
		map = Unpacker.DefaultMap;
	end;
	
	local invisible_baseplate = Instance.new("Part");
	invisible_baseplate.Anchored = true;
	invisible_baseplate.Transparency = 1;
	invisible_baseplate.Size = Vector3.new(2048, 512, 2048);
	invisible_baseplate.Position = Vector3.new(0, -248, 0);
	invisible_baseplate.Parent = workspace.Terrain;
	task.wait(0.1);
	
	self:remove_map();
	self.current_map = map;
	
	BuildShared.Data.SourceMap.Value = source_map;
	
	map.Name = "Model";
	map.Parent = workspace.Map;
	
	task.delay(1, function()
		invisible_baseplate:Destroy();
	end);
end

function BuildHandler:make_hooks()
	-- Helper wrapper so i dont need to do this for every remote
	local function wrap(callback: (builder: any, ...any) -> ())
		return function(player: Player, ...: any)
			if not self.is_replicated_initialised then
				return;
			end;
			
			local builder = self:get(player)
			
			if builder and builder.enabled then
				return callback(builder, ...)
			end
		end;
	end;
	
	do
		local returned = self:make_modifiers_list();
		
		function Remotes.RequestInstanceModifiers.OnServerInvoke()
			return returned;
		end;
	end;
	
	Remotes.Serialisation.RequestSlotHistory.OnServerInvoke = wrap(function(builder, slot: any)
		return builder:retrieve_slot_history(slot, 25);
	end)
	
	Remotes.Serialisation.LoadMap.OnServerEvent:Connect(wrap(function(builder, name: string)
		builder:load_map(name);
	end))
	
	Remotes.Serialisation.RemoveFromInventory.OnServerEvent:Connect(wrap(function(builder, instance: Instance)
		builder:remove_from_inventory(instance);
	end))
	
	Remotes.Serialisation.SaveToInventory.OnServerEvent:Connect(wrap(function(builder, instance: Instance)
		builder:save_to_inventory(instance);
	end))
	
	Remotes.Operations.Move.OnServerEvent:Connect(wrap(function(builder, now, parts, cframes)
		if typeof(parts) ~= "table" or typeof(cframes) ~= "table" then return end;
		
		for _, player in Players:GetPlayers() do
			if (player == builder.player) then
				continue;
			end;
			
			Remotes.Operations.Move:FireClient(player, parts, cframes);
		end
	end))
	
	Remotes.Operations.Size.OnServerEvent:Connect(wrap(function(builder, now, parts, sizes)
		if typeof(parts) ~= "table" or typeof(sizes) ~= "table" then return end;
		
		for _, player in Players:GetPlayers() do
			if (player == builder.player) then
				continue;
			end;
			
			Remotes.Operations.Size:FireClient(player, parts, sizes);
		end
	end))
	
	Remotes.SetPreference.OnServerEvent:Connect(wrap(function(builder, name, value)
		builder:set_preference(name, value)
	end))
	
	Remotes.Debugging.SetModifierListen.OnServerEvent:Connect(wrap(function(builder, instances: {Instance})
		builder.modifier_listen_maid:clean();
		
		local queue = {};
		local thread_queue = nil;
		local BufferUtil = require( ReplicatedStorage.Packages.BufferUtil )
		
		local function send_queue()
			local buf = BufferUtil.create(128);
			
			for index, data in queue do
				for state, value in data do
					assert(state < 128, "Modifier state queue too long");
					
					BufferUtil.write_u8(buf, index);
					BufferUtil.write_u8(buf, state + if value then 128 else 0); -- State Index (0-127) encoded with a boolean (>=128)
				end;
			end;
			
			Remotes.Debugging.ModifierStateChange:FireClient(builder.player, BufferUtil.truncate(buf));
			
			thread_queue = nil;
			table.clear(queue);
		end;
		
		local function update_queue_for(index: number, state: number, value: boolean)
			if not queue[index] then
				queue[index] = {[state] = value};
			else
				queue[index][state] = value;
			end 
			
			if not thread_queue then
				thread_queue = task.delay(1 / 60, send_queue);
			end
		end
		
		for index, instance in instances do
			local modifier = InstanceModifier.list[instance];
			
			if modifier then
				builder.modifier_listen_maid:add(modifier.state_changed:Connect(function(state, value)
					update_queue_for(index, table.find(StateIndex, state) or 0, value);
				end));
				
				for state_index, state in StateIndex do
					local value = modifier[state];
					
					if value ~= nil then
						update_queue_for(index, state_index, value);
					end;
				end
			end;
		end;
	end));
	
	Remotes.Debugging.DumpModifierStat.OnServerEvent:Connect(function(player, instance)
		if self:can_debug(player) then
			local modifier = InstanceModifier.list[instance];
			
			if modifier then
				print("");
				print("=================================")
				print(`{modifier.modifier.Name}:`, modifier);
				print("This is powering: {");
				for creator in modifier.active_creator do
					warn(`   {creator.name} ({creator.modifier.object.Name}):`, creator);
				end;
				print("}");
				print("Powered by: {");
				for creator in modifier.active_subscribers do
					warn(`	{creator.name} ({creator.modifier.object.Name}):`, creator);
				end;
				print("}");
				print("=================================")
			end;
		end;
	end);
	
	Remotes.Debugging.PowerModifier.OnServerEvent:Connect(wrap(function(builder, instance: Instance, value: boolean)
		local modifier = InstanceModifier.list[instance];
		
		if modifier then
			modifier:set_always_active(value)
		end;
	end));
	
	Remotes.Serialisation.ModifySlot.OnServerEvent:Connect(wrap(function(builder, slot: string, change: any)
		local slot = builder:get_profile_slot(slot);
		
		if slot then
			if builder:is_slot_name_valid(change.name) then
				slot.label = change.name
			end;
		end
	end))

	Remotes.Serialisation.LoadFromSlot.OnServerEvent:Connect(wrap(function(builder, slot: string, version_number: string?)
		if not builder.permissions.load_slot then return end;

		builder:load_slot(tonumber(slot), version_number);
	end))

	Remotes.Serialisation.SaveToSlot.OnServerEvent:Connect(wrap(function(builder, slot: string)
		if not builder.permissions.save_slot then return end;

		builder:save_slot(tonumber(slot));
	end))
	
	Remotes.Operations.Import.OnServerEvent:Connect(wrap(function(builder, data_string: string)
		if not builder.permissions.load_slot then return end;
		
		builder:import(data_string)
	end))
	
	Remotes.Operations.Export.OnServerEvent:Connect(wrap(function(builder, instance: Instance?)
		if not builder.permissions.load_slot then return end;

		builder:export(instance)
	end))
	
	Remotes.Operations.WriteText.OnServerEvent:Connect(wrap(function(builder, text: string)
		if not builder.permissions.spawning then return end;
		
		builder:write_mesh_text(text)
	end))
	
	Remotes.Operations.GapFill.OnServerEvent:Connect(wrap(function(builder, edge_a, edge_b, extrude_direction_modifier, thickness_override, force_factor)
		if not builder:can_modify(edge_a.part) or not builder:can_modify(edge_b.part) then
			return;
		end;
		
		GapFill(edge_a, edge_b, extrude_direction_modifier, thickness_override, force_factor, function(instance)
			builder:record_instance(instance);
		end)

		builder:commit();
	end))
	
	Remotes.Operations.VoxelBreak.OnServerEvent:Connect(wrap(function(builder, info)
		if typeof(info) ~= "table" then return end;
		
		builder:voxel_break(info);
	end))
	
	Remotes.Operations.CreateMesh.OnServerEvent:Connect(wrap(function(builder, mesh_id, texture_id, collision_fidelity)
		builder:create_mesh(mesh_id, texture_id, collision_fidelity);
	end))
	
	Remotes.Operations.Modify.OnServerEvent:Connect(wrap(function(builder, instances, properties, record)
		builder:modify_instances(instances, properties, record);
	end))

	Remotes.Operations.AddModifier.OnServerEvent:Connect(wrap(function(builder, instances, properties)
		if not builder.permissions.instance_modifier then return end;
		
		builder:add_instance_modifier(instances, properties);
	end))

	Remotes.Operations.EditModifier.OnServerEvent:Connect(wrap(function(builder, instances, attribute, value)
		if not builder.permissions.instance_modifier then return end;

		builder:edit_instance_modifier(instances, attribute, value);
	end))

	Remotes.Operations.Ungroup.OnServerEvent:Connect(wrap(function(builder, instances)
		if not builder.permissions.grouping then return end;

		builder:ungroup(instances);
	end))

	Remotes.Operations.Group.OnServerEvent:Connect(wrap(function(builder, instances)
		if not builder.permissions.grouping then return end;

		builder:group(instances);
	end))
	
	Remotes.Operations.Weld.OnServerEvent:Connect(wrap(function(builder, instances)
		builder:weld(instances);
	end))
	
	Remotes.Operations.Unweld.OnServerEvent:Connect(wrap(function(builder, instances)
		builder:unweld(instances);
	end))

	Remotes.Operations.Anchor.OnServerEvent:Connect(wrap(function(builder, instances)
		if not builder.permissions.anchor then return end;

		builder:anchor_to(instances, true);
	end))

	Remotes.Operations.Unanchor.OnServerEvent:Connect(wrap(function(builder, instances)
		if not builder.permissions.anchor then return end;

		builder:anchor_to(instances, false);
	end))

	Remotes.Operations.Cloning.OnServerEvent:Connect(wrap(function(builder, instances)
		if not builder.permissions.cloning then return end;

		builder:clone(instances);
	end))
	
	Remotes.Operations.Copy.OnServerEvent:Connect(wrap(function(builder, instances)
		if not builder.permissions.cloning then return end;

		builder:copy(instances);
	end))
	
	Remotes.Operations.Paste.OnServerEvent:Connect(wrap(function(builder, into, coordinate)
		if not builder.permissions.cloning then return end;

		builder:paste(into, coordinate);
	end))

	Remotes.Operations.Delete.OnServerEvent:Connect(wrap(function(builder, instances)
		if not builder.permissions.delete then return end;

		builder:delete(instances);
	end))

	Remotes.Operations.Spawn.OnServerEvent:Connect(wrap(function(builder, instance, count, parent, coordinate: CFrame?, auto_select: boolean?)
		if not builder.permissions.spawning then return end;
		
		builder:spawn(instance, count, parent or BuildsFolder, coordinate, auto_select);
	end))

	Remotes.Operations.Undo.OnServerEvent:Connect(wrap(function(builder)
		builder:undo();
	end))

	Remotes.Operations.Redo.OnServerEvent:Connect(wrap(function(builder)
		builder:redo();
	end))

	Remotes.Operations.Clear.OnServerEvent:Connect(wrap(function(builder)
		if not builder.permissions.clear then return end;

		builder:clear_all();
	end))
	
	Remotes.Serialisation.LoadFromHotbar.OnServerEvent:Connect(wrap(function(builder, slot: number, coordinate: CFrame)
		builder:load_from_hotbar(slot, coordinate);
	end))
	
	Remotes.Serialisation.SaveToHotbar.OnServerEvent:Connect(wrap(function(builder, slot: number, model: Instance | string)
		builder:save_to_hotbar(slot, model);
	end))
end

function BuildHandler:make_modifiers_list()
	local instance_modifiers_list = {};

	for _, modifier in script.InstanceModifier.Modifiers:GetChildren() do
		local success, info = pcall(require, modifier);
		
		if not success then
			warn(`InstanceModifier {modifier.Name} could not load: {info}`);
			continue;
		end;
		
		local properties = {};
		
		for name, info in info.properties do
			properties[name] = {
				Default = info.Default,
				AssetType = info.AssetType,
				DisplayName = info.DisplayName,
				ValueList = info.ValueList,
				Hides = info.Hides;
				Shows = info.Shows;
				Hidden = info.Hidden;
				Order = info.Order;
			};
		end
		
		table.insert(instance_modifiers_list, {
			Title = modifier.Name or "Unknown";
			Description = info.description;
			Icon = info.icon;
			Color = info.color;
			Section = info.section;
			NeedsProduct = info.needs_product;
			NeedsGamepass = info.needs_gamepass;
			Hidden = info.hidden;
			Properties = properties;
		})
	end

	table.sort(instance_modifiers_list, function(a, b)
		return a.Title < b.Title;
	end)
	
	return {
		sections = Sections;
		list = instance_modifiers_list
	}
end

function BuildHandler.new(game_handler)
	local self = setmetatable(
		{
			modifiers = InstanceModifier;
			game_handler = game_handler;
			builders = {};
			is_initialised = false;
			is_replicated_initialised = false;
			initialisation_maid = Maid.new();
			tag_stream_id = 0;
		},
		BuildHandler)
	
	self.transaction_handler = TransactionHandler.new(self);
	self.skill_builder = SkillBuilder.new(self);
	
	Pulse.build_handler = self;
	StreamService.get_channel("BuildsProfile");
	
	return self;
end

--------------------------------------------------------------

function BuildHandler:destroy()
	
end

function BuildHandler:clone_instance(instance: Instance, coordinate: CFrame?, deploy: boolean?, parent: Instance?, recorder: any): Instance
	local clone = instance:Clone();
	local attributes = clone:GetAttributes();
	
	clone:SetAttribute("Deployment", nil);
	clone:SetAttribute("StaticDeployment", nil);
	clone:SetAttribute("BuildInstance", nil);
	
	if coordinate and clone:IsA("PVInstance") then
		clone:PivotTo( coordinate );
	end;
	
	if attributes.Ungroup then
		local folder = Instance.new("Folder");
		folder.Name = clone.Name;

		for attribute, value in clone:GetAttributes() do
			folder:SetAttribute(attribute, value);
		end;

		for _, item in clone:GetChildren() do
			item.Parent = folder;
		end

		clone:Destroy();
		clone = folder;
	end
	
	if recorder then
		recorder:record_instance(clone);
	end
	
	if deploy then
		if not parent or attributes.StaticDeployment then
			local location = attributes.Deployment;

			if location then
				clone.Parent = Instances.locate(location);
			else
				clone.Parent = BuildsFolder;
			end
		else
			clone.Parent = parent;
		end
	end;

	return clone;
end

function BuildHandler:spawn_instance(name: string, coordinate: CFrame?, deploy: boolean?, parent: Instance?, recorder: any): Instance
	local asset = InstanceAssets:FindFirstChild(name);
	
	if (name == "Attachment") then
		asset = Instance.new("Attachment");
	end;
	
	if asset then
		return self:clone_instance(asset, coordinate, deploy, parent, recorder);
	else
		error(`Asset '{name}' does not exist in the insert list!`);
	end
end

--------------------------------------------------------------

return BuildHandler.new();