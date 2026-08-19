local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Player = Players.LocalPlayer;
local PlayerGui = Player:WaitForChild("PlayerGui");
local BuildPersistent = ReplicatedStorage:WaitForChild("BuildTools");
local BuildShared = BuildPersistent:WaitForChild("Shared");
local Remotes = BuildPersistent:WaitForChild("Remotes");
local BuildAssets = BuildShared:WaitForChild("Assets");
local InstancesBuild = BuildShared.Assets.Build;
local InstancesInventory = InstancesBuild.Inventory;

local Stylus = require( ReplicatedStorage.Packages.Stylus )
local Maid = require( ReplicatedStorage.Packages.Maid )
local Signal = require( ReplicatedStorage.Packages.Signal )
local Table = require( ReplicatedStorage.Packages.Table )
local PageList = require( ReplicatedStorage.Packages.PageList )
local Searcher = require( script.Parent.UI.Searcher );
local Hotbar = require( script.Hotbar )
local Item = require( script.Item )

local Inventory = {};
Inventory.__index = Inventory;

function Inventory.new(build_tools)
	local self = setmetatable(
		{
			build_tools = build_tools;
			items = {};
			maps = {};
			category = {};
			items_unowned = {};
			on_open_changed = build_tools.maid:add(Signal.new());
			current_category = nil;
			current_category_items = {};
			enabled = false;
			
			tweens = {};
			
			search_box = build_tools.elements.InventoryItemsPage.Body.Filter.Search;
			inventory_frame = build_tools.elements.InventoryFrame;
			map_page = build_tools.elements.InventoryMapPage;
			inventory_page = build_tools.elements.InventoryItemsPage;
			map_page_grid_list = build_tools.elements.InventoryMapPage.Body.Items.MapPage.ScrollingFrame;
			map_page_scroll_list = build_tools.elements.InventoryMapPage.Body.Items.ItemsPage.ScrollingFrame;
			inventory_links = build_tools.elements.InventoryFrame.Menu.Body.Links;
			inventory_page_layout = build_tools.elements.InventoryFrame.Menu.Body.Body.UIPageLayout;
			page_sections_list = build_tools.elements.InventoryItemsPage.Body.Section.Body.ScrollingFrame;
		}, 
		Inventory);
	
	self.hotbar = Hotbar.new(self);
	self:initialise();
	
	return self;
end;

function Inventory:destroy()
	for _, item in pairs(self.items) do
		self:remove_from_inventory(item);
	end
	
	for _, map in pairs(self.maps) do
		self:remove_from_maps(map);
	end
	
	table.clear(self.maps);
	table.clear(self.items);
	table.clear(self.category);
	table.clear(self.current_category_items);
	table.clear(self.tweens);
	
	Table.dispose(self);
end

function Inventory:add_to_maps(model: Instance)
	self:remove_from_maps(model);
	
	if not self.build_tools.marketplace:has_instance_owned(model) then
		self.build_tools.marketplace:get_instance_owned_callback(model, function()
			self:add_to_maps(model);
		end);
		
		return nil;
	end;
	
	local item = Item.new(self, 0, {model = model});

	self.maps[model] = item;

	item:initialise_as_item();
	item.frame.Parent =  self.map_page_grid_list;
	
	if BuildShared.Data.SourceMap.Value == model then
		item.frame.Selected.Visible = true;
	end;
	
	item.frame.Button.MouseButton1Click:Connect(function()
		self:toggle(false);
		
		self.build_tools.confirmations:make("Warning!", "Are you sure you want to load this map?", function(accepted)
			if not accepted then return self:toggle(true) end;
			
			self.build_tools.actions:load_map(model.Name);
		end);
	end)

	return item;
end

function Inventory:remove_from_maps(model: Instance)
	local item = self.maps[model];

	if item then
		item:destroy();
		self.maps[model] = nil;
	end
end

function Inventory:add_to_inventory(model: Instance)	
	if model:IsA("Folder") then
		return;
	end;
	
	self:remove_from_inventory(model);
	
	local item = Item.new(self, 0, {model = model});
	
	self.items[model] = item;
	
	item:initialise_as_item();
	item._in_storage = model:IsDescendantOf(PlayerGui);
	item.frame.Button.MouseButton1Click:Connect(function()
		if item._in_storage and self.is_trashing then
			self:remove_from_inventory(model);
			
			self.build_tools.actions:remove_from_inventory(model);
			self.page_items_list:repage();
		else
			self.hotbar:equip_slot(self.hotbar:next(), {reference = model, model = model:Clone()})
		end
	end)
	
	self.page_items_list:add_item(item.frame, item);
	
	return item;
end

function Inventory:remove_from_inventory(model: Instance)
	local item = self.items[model];
	
	if item then
		self.page_items_list:remove_item(item.frame);
		item:destroy();
		self.items[model] = nil;
	end
end

function Inventory:get_category_items(folder: Folder)
	local items = table.clone(self.category[folder]);
	
	for _, instance in folder:GetChildren() do
		if not self.category[instance] then
			continue;
		end;
		
		for _, item in self:get_category_items(instance) do
			table.insert(items, item);
		end;
	end;
	
	return items;
end

function Inventory:reset_section()
	if not self.current_category then
		self:set_section(InstancesInventory.All)
	else
		self:set_section(self.current_category);
	end
end

function Inventory:set_section(folder: Folder)
	local current_category = self.current_category;
	
	if self.category[folder] then
		self.current_category = folder;
		
		for _, item in self.page_items_list.items do
			self.page_items_list:hide_item(item.frame);
		end;
		
		for _, item in self:get_category_items(folder) do
			self.page_items_list:show_item(item.frame);
		end
		
		self.page_items_list:repage();
		self.page_items_list.layout:JumpToIndex(0);
	end
end

function Inventory:is_child_in_category(child, category): boolean
	if not category then
		category = self.current_category;
	end;
	
	if self.category[category] then
		for index, item in self.category[category] do
			if item.info.model == child then
				return true;
			end
		end;
	end;
	
	return false;
end

local function add_child_item_to_inventory(self, folder: Folder, item: Instance)
	if item:IsA("Folder") then
		self:add_folder_to_inventory(item)
	else
		local child = self:add_to_inventory(item);
		
		if child then
			table.insert(self.category[folder], child);
		end;
	end
end

function Inventory:add_folder_to_inventory(folder: Folder)
	assert(not self.category[folder], "Folder is already added");
	
	self.category[folder] = {};
	
	local attributes = folder:GetAttributes();
	local section = self.build_tools.assets.InventorySection:Clone();
	
	do
		local function update_size()
			section.Size = UDim2.new(0, self.page_sections_list.AbsoluteSize.X * 0.3, 1, 0);
		end
		
		task.spawn(update_size);
		self.page_sections_list:GetPropertyChangedSignal("AbsoluteSize"):Connect(update_size)
	end
	
	section.MouseButton1Click:Connect(function()
		self:set_section(folder);
	end);
	
	if attributes.Color then
		section.TextColor3 = attributes.Color;
	end
	
	section.LayoutOrder = attributes.LayoutOrder or 1;
	section.Text = folder.Name;
	section.Parent = self.page_sections_list;
	
	local function add_child(item: Instance)
		if self.build_tools.marketplace:has_instance_owned(item) then
			add_child_item_to_inventory(self, folder, item);
		else
			self.build_tools.marketplace:bind_to_instance_owned(item, function()
				add_child_item_to_inventory(self, folder, item);
			end)
		end;
	end
	
	for _, item in folder:GetChildren() do
		add_child(item);
	end;
	
	self.build_tools.maid:add(folder.ChildAdded:Connect(function(child)
		add_child(child);
		
		if self:is_child_in_category(child) then
			self.page_items_list:repage();
		end;
	end))
	
	return self.category[folder];
end

function Inventory:remove_folder_from_inventory(folder: Folder)
	if self.category[folder] then
		table.clear(self.category[folder]);
		self.category[folder] = nil;
	end;
	
	for _, item in folder:GetChildren() do
		self:remove_from_inventory(item);
	end
end

function Inventory:toggle(value: boolean?)
	if (value == nil) then
		value = not self.enabled;
	end;
	
	if self.enabled ~= value then
		self.build_tools:close_all(self);
		self.enabled = value;
		self.on_open_changed:Fire();
		
		self:set_trashing_mode(false);
		
		for slot, item in self.hotbar.slots do
			item:update_equipped();
		end
		
		self.inventory_frame.Menu.Visible = true;
		SoundService:PlayLocalSound(self.build_tools.sounds.Flash);
		
		if self.enabled then
			self.tweens.open:Play();
			
			if not self.build_tools.marketplace:has_gamepass( "PrivateServerPlus" ) then
				self.inventory_page.Locked.Visible = true;
			else
				self.inventory_page.Locked.Visible = false;
			end
			
			if not self.current_category then
				self:reset_section()
			end
		else
			self.tweens.close:Play();
		end
	end
end

function Inventory:set_trashing_mode(value: boolean)
	if self.is_trashing ~= value then
		self.is_trashing = value;
		
		self.inventory_links.Trash.BackgroundColor3 = if value 
			then Color3.fromRGB(255, 255, 255)
			else Color3.fromRGB(140, 24, 24)
		
		for slot, item in self.hotbar.slots do
			item:update_trashing();
		end
		
		for _, item in self.items do
			if item._in_storage then
				item:update_trashing();
			end
		end
	end
end

function Inventory:initialise()	
	do
		local items_page = self.build_tools.assets.DynamicItemsPage:Clone();
		self.page_items_list = PageList.new({
			["layout"] = items_page.Pages.UIPageLayout;
			["page_max"] = items_page.Controls.List.Page.Max;
			["page_current"] = items_page.Controls.List.Page.Current;
			["next_button"] = items_page.Controls.List.Next;
			["previous_button"] = items_page.Controls.List.Previous;
			["page_preset"] = self.build_tools.assets.DynamicPage;
		})
		items_page.Parent = self.build_tools.elements.InventoryItemsPage.Body.Items;
		
		function self.page_items_list:item_visible_changed(item, visible)
			item:set_viewport_enabled(visible);
		end
		
		self.search_box:GetPropertyChangedSignal("Text"):Connect(function()
			self.page_items_list:search(self.search_box.Text);
		end)
	end
	
	do
		self.inventory_frame.Open.Button.MouseButton1Click:Connect(function()
			self:toggle()
		end)
	end
	
	self.inventory_page.Locked.Buy.MouseButton1Click:Connect(function()
		self.build_tools.marketplace:purchase_gamepass("PrivateServerPlus");
	end)
	
	do
		local scroll = self.map_page_grid_list;
		local per_row = 3;
		
		local function update_scroll_size()
			local scale = scroll.AbsoluteSize;
			local size = scale.X / per_row - (scroll.UIGridLayout.CellPadding.X.Offset + 4)
			
			scroll.UIGridLayout.CellSize = UDim2.fromOffset(size, size);
		end
		
		update_scroll_size()
		scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(update_scroll_size)
	end

	do
		for _, child in InstancesInventory:GetChildren() do
			task.spawn(self.add_folder_to_inventory, self, child);
		end;

		self.build_tools.maid:add(InstancesInventory.ChildAdded:Connect(function(child)
			self:add_folder_to_inventory(child);
		end))

		self.build_tools.maid:add(InstancesInventory.ChildRemoved:Connect(function(child)
			self:remove_folder_from_inventory(child);
		end))
		
		self.inventory_links.Trash.MouseButton1Click:Connect(function()
			self:set_trashing_mode(not self.is_trashing);
		end)
		
		self.inventory_links.Add.MouseButton1Click:Connect(function()
			self.build_tools.actions:save_to_inventory(self.build_tools.selection:next());
		end)

		self.inventory_links.Inventory.MouseButton1Click:Connect(function()
			self.inventory_page_layout:JumpTo(self.inventory_page);
		end)
		
		self.inventory_links.Map.MouseButton1Click:Connect(function()
			self.inventory_page_layout:JumpTo(self.map_page);
			self.map_page.Body.Items.UIPageLayout:JumpTo(self.map_page.Body.Items.ItemsPage);
		end)
		
		local hotbar = self.inventory_frame.Hotbar;
		
		hotbar.Add.MouseButton1Click:Connect(function()
			self.build_tools:save_selected_to_hotbar();
		end)
		
		local function update_content()
			local content_size = hotbar.Items.UIListLayout.AbsoluteContentSize.X;
			
			if content_size > 0 then
				hotbar.Add.AnchorPoint = Vector2.new(0, 0.5);
				hotbar.Add.Position = UDim2.new(0.5, content_size / 2 + 8, 0.5, 0);
			else
				hotbar.Add.AnchorPoint = Vector2.new(0.5, 0.5);
				hotbar.Add.Position = UDim2.fromScale(0.5, 0.5);
			end
		end
		
		update_content();
		hotbar.Items.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update_content)
	end;
	
	do
		for _, child in InstancesBuild.Maps:GetChildren() do
			task.spawn(self.add_to_maps, self, child);
		end;

		self.build_tools.maid:add(InstancesBuild.Maps.ChildAdded:Connect(function(child)
			self:add_to_maps(child);
		end))

		self.build_tools.maid:add(InstancesBuild.Maps.ChildRemoved:Connect(function(child)
			self:remove_from_maps(child);
		end))
		
		local maps_section = self.build_tools.assets.InventoryCustomSection:Clone();
		maps_section.Parent = self.map_page_scroll_list;
		
		local function enter()
			self.map_page.Body.Items.UIPageLayout:JumpTo(self.map_page.Body.Items.MapPage);
		end
		
		maps_section.Expand.MouseButton1Click:Connect(enter);
		maps_section.Enter.MouseButton1Click:Connect(enter)
	end
	
	do
		local last_value = BuildShared.Data.SourceMap.Value;
		
		self.build_tools.maid:add(BuildShared.Data.SourceMap.Changed:Connect(function(value)
			if last_value then
				local item_frame = self.maps[last_value];
				item_frame.frame.Selected.Visible = false;
			end;
			
			if value then
				local item_frame = self.maps[value];
				item_frame.frame.Selected.Visible = true;
			end
			
			last_value = value;
		end))
	end
	
	Searcher.new(self.map_page.Body.Filter.Search, self.map_page.Body.Items.MapPage.ScrollingFrame);
	
	do
		self.tweens.open = TweenService:Create(self.inventory_frame.Menu.Body, TweenInfo.new(0.2), {Position = UDim2.fromScale(0.5, 0.5)})
		self.tweens.close = TweenService:Create(self.inventory_frame.Menu.Body, TweenInfo.new(0.2), {Position = UDim2.fromScale(0.5, 1.5)})

		self.tweens.close:Play();

		self.tweens.close.Completed:Connect(function(status)
			if (status == Enum.PlaybackState.Completed) then
				self.inventory_frame.Menu.Visible = false
			end;
		end);
	end;
	
	task.defer(function()
		self.hotbar:force_equip_slot(self.hotbar:next(), {reference = InstancesBuild.Insert.Part})
		self.hotbar:force_equip_slot(self.hotbar:next(), {reference = InstancesBuild.Insert.Cylinder})
		self.hotbar:force_equip_slot(self.hotbar:next(), {reference = InstancesBuild.Insert.Wedge})
	end);
	
	self.build_tools.elements.LinkButtons.Inventory.MouseButton1Click:Connect(function()
		self:toggle();
	end)
	
	local function child_added(child: Instance)
		if child.Name == "InventoryStorage" then
			local folder = child:WaitForChild("Storage");
			
			local function descendant_added(child)
				if child:IsA("Sound") then
					child.Playing = false;
				end;
			end;
			
			for _, child in folder:GetDescendants() do
				descendant_added(child);
			end;
			self.build_tools.maid:add(folder.DescendantAdded:Connect(descendant_added));
			
			self:add_folder_to_inventory(folder);
		end
	end
	
	for _, instance in PlayerGui:GetChildren() do
		task.spawn(child_added, instance);
	end
	PlayerGui.ChildAdded:Connect(child_added)
end

table.freeze(Inventory);

return Inventory;