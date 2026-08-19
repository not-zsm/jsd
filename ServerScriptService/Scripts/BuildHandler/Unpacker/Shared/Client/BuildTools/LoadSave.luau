local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local BuildShared = ReplicatedStorage:WaitForChild("BuildTools");

local Maid = require( ReplicatedStorage.Packages.Maid )
local Stylus = require( ReplicatedStorage.Packages.Stylus )

local BuildShared = ReplicatedStorage.BuildTools;
local Remotes = BuildShared.Remotes;

type SlotObject = {
	instance: GuiObject;
	slot: number;
	maid: Maid.Maid;
	update: () -> ();
}

local LoadSave = {};
LoadSave.__index = LoadSave;

function LoadSave.new(build_tools)
	local ui = build_tools.elements.Slots;
	local main_body = ui.Main.Body.Body;
	local side_body = ui.Main.Side.Body;
	
	local self = setmetatable(
		{
			build_tools = build_tools;
			selected_slot = nil;
			
			side_enabled = false;
			enabled = false;
			
			slots = {};
			tweens = {};
			versions = {};
			
			slots_ui = ui;
			main_canvas = main_body.Parent;
			main_body = main_body;
			side_canvas = side_body.Parent;
			side_body = side_body;
			control_list = side_body.Control;
			slots_list =  main_body.List.ItemsFrame
		}, 
		LoadSave);
	
	self:initialise();
	
	return self;
end;

export type LoadSave = typeof(LoadSave.new(...))

function LoadSave:initialise()
	do
		local info = TweenInfo.new(0.15);
		local info2 = TweenInfo.new(0.1);
		
		do
			local open_info = {GroupTransparency = 0, AnchorPoint = Vector2.new(0.5, 0.5)};
			local close_info = {GroupTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.25)};
			
			self.tweens.open = TweenService:Create(self.main_canvas, info, open_info);
			self.tweens.close = TweenService:Create(self.main_canvas, info, close_info);
		end;
		
		do
			local open_info = {Position = UDim2.fromScale(0, 0)};
			local close_info = {Position = UDim2.fromScale(-1.1, 0)};
			
			self.tweens.open_side = TweenService:Create(self.side_body, info, open_info);
			self.tweens.close_side = TweenService:Create(self.side_body, info, close_info);
			
			self.tweens.open_side_canvas = TweenService:Create(self.side_canvas, info2, { GroupTransparency = 0 });
			self.tweens.close_side_canvas = TweenService:Create(self.side_canvas, info2, { GroupTransparency = 1 });
		end;
		
		self.tweens.close_side_canvas:Play();
		self.tweens.close_side:Play();
		self.tweens.close:Play();

		self.tweens.close.Completed:Connect(function(status)
			if (status == Enum.PlaybackState.Completed) then
				self.slots_ui.Enabled = false;
				self.main_body.Position = UDim2.fromScale(0.5, 0.5);
			end;
		end)
	end
	
	self.main_body.Bottom.Buy.MouseButton1Click:Connect(function()
		self.build_tools.marketplace:purchase_product("AddBuildSaveSlot")
	end)
	
	self.build_tools.maid:add(self.control_list.Load.MouseButton1Click:Connect(function()
		self:toggle(false);
		
		self.build_tools.confirmations:make("Warning!", "Are you sure you want to <font color='rgb(130,180,255)'><b>load</b></font>? This action cannot be reversed.", function(accepted)
			if accepted then
				self.build_tools.actions:load_slot( self:get_slot_id(), self:get_slot_version() )
			else
				self:toggle(true);
			end;
		end)
	end))

	self.build_tools.maid:add(self.control_list.Save.MouseButton1Click:Connect(function()
		self:toggle(false);
		
		self.build_tools.confirmations:make("Warning!", "Are you sure you want to <font color='rgb(145,255,0)'><b>save</b></font>? This action cannot be reversed.", function(accepted)
			if accepted then
				self.build_tools.actions:save_slot( self:get_slot_id(), self:get_slot_description() )
			else
				self:toggle(true);
			end
		end)
	end))
	
	self.side_body.Slot.SlotName.FocusLost:Connect(function()
		local selected_slot = self.selected_slot;
		local text = self.side_body.Slot.SlotName.Text;
		
		if selected_slot then
			self.build_tools.slots[selected_slot.id].label = text;
			
			Remotes.Serialisation.ModifySlot:FireServer(selected_slot.id, {name = text});
			
			self:update_slot_details();
		end;
	end)
	
	self.side_body.Body.NotLoaded.Load.MouseButton1Click:Connect(function()
		self:load_versions(self.selected_slot);
	end);
	
	self.side_body.Body.Refresh.Load.MouseButton1Click:Connect(function()
		self:load_versions(self.selected_slot, true);
	end)
	
	self.build_tools.elements.LinkButtons.SaveSlots.MouseButton1Click:Connect(function()
		self:toggle();
	end)

	self.main_body.Title.Close.MouseButton1Click:Connect(function()
		self:toggle(false);
	end)
end

function LoadSave:destroy()
	table.clear(self.tweens);
	
	table.clear(self.slots);
	table.clear(self);
end;

function LoadSave:update_versions()
	
	local slot = self.selected_slot;
	
	if slot then
		local version_slot = self.versions[slot.id];
		
		if version_slot and version_slot.loaded then
			self:load_versions(slot);
		end;
	end
end

function LoadSave:load_versions(slot, update: boolean?)
	if not self.versions[slot.id] then
		self.versions[slot.id] = {
			frames = {};
			loaded = false;
		};
	end;
	
	local version_slot = self.versions[slot.id];
	
	self:unload_versions(slot);
	self.side_body.Body.NotLoaded.Visible = false;
	
	if version_slot.loaded and not update then
		for index, object in version_slot.frames do
			object.instance.Visible = true;
		end
	else
		for index, object in version_slot.frames do
			object.maid:destroy();
			object.instance:Destroy();
		end;
		
		table.clear(version_slot.frames);
		
		local versions = Remotes.Serialisation.RequestSlotHistory:InvokeServer(slot.id);

		for index, ver_slot in versions do
			local object = self:create_version(index, ver_slot);

			version_slot.frames[index] = object;
			
			object.instance.Visible = true;
			object.instance.Parent = self.side_body.Body.Versions;
		end;
		
		version_slot.loaded = true;
	end;
end;

function LoadSave:unload_versions(slot)
	local version_slot = self.versions[slot.id];
	
	self.side_body.Body.NotLoaded.Visible = true;
	
	if version_slot then
		for _, object in version_slot.frames do
			object.instance.Visible = false;
		end;
	end;
end;

function LoadSave:get_slot_version(): string?
	if self.selected_version then
		return self.selected_version.data.Version;
	end;
	
	return nil;
end

function LoadSave:select_version(version_slot)
	local last_version = self.selected_version;
	
	if last_version then
		last_version.instance.UIStroke.Transparency = 0.9;
	end;
	
	if version_slot then
		version_slot.instance.UIStroke.Transparency = 0.2;
	end;
	
	self.selected_version = version_slot;
end

function LoadSave:create_version(index: number, version_data)
	local slot = self.build_tools.assets.VersionSlot:Clone();
	local timestamp = DateTime.fromUnixTimestampMillis(version_data.CreatedTime);
	
	slot.UIStroke.Transparency = 0.9;
	slot.Name = `Version{index}`
	slot.VersionTitle.Text = `Version {index}`;
	slot.Timestamp.Text = `{timestamp:FormatLocalTime("L", "en-us")} at {timestamp:FormatLocalTime("LTS", "en-us")}`;
	slot.LayoutOrder = index;
	slot.Visible = true;

	local object = {
		maid = Maid.new();
		instance = slot;
		data = version_data;
		index = index;
	};

	slot.Button.MouseButton1Click:Connect(function()
		if self.selected_version == object then
			self:select_version(nil);
		else
			self:select_version(object);
		end;
	end)
	
	return object;
end

function LoadSave:create_slot_object(slot_id: string)

	local slot = self.build_tools.assets.SaveSlot:Clone();
	
	slot.UIStroke.Transparency = 0.9;
	slot.Name = `Slot{slot_id}`
	slot.SlotTitle.Text = `Slot {slot_id}`;
	slot.Title.Text = "-";
	slot.LayoutOrder = slot_id;
	slot.Visible = true;
	slot.Parent = self.slots_list;
	
	local object = {
		maid = Maid.new();
		instance = slot;
		id = slot_id;
	};

	return object;
end;

function LoadSave:toggle_side(value: boolean?)
	if value == nil then
		value = not self.side_enabled;
	end;
	
	if self.side_enabled ~= value then
		self.side_enabled = value;
		
		if value then
			self.tweens.open_side:Play();
			self.tweens.open_side_canvas:Play();
		else
			self.tweens.close_side:Play();
			self.tweens.close_side_canvas:Play();
		end
	end
end

function LoadSave:toggle(value: boolean?)
	if value == nil then
		value = not self.enabled
	end;

	if self.enabled ~= value then
		self.build_tools:close_all(self);
		self.enabled = value;
		
		if value then
			self.slots_ui.Enabled = true;
			self.tweens.open:Play();
			
			if self.selected_slot then
				self:toggle_side(true);
			end;
			
			Stylus:tween_blur(15);
			SoundService:PlayLocalSound(self.build_tools.sounds.Flash);
		else
			self.tweens.close:Play();
			self:toggle_side(false);
			
			Stylus:tween_blur(0);
		end;
	end;
end;

function LoadSave:get_slot_data(slot_id: number)
	return self.build_tools.slots[slot_id];
end

function LoadSave:get_slot_id(): number?
	if self.selected_slot then
		return self.selected_slot.id;
	end;
	
	return nil;
end

function LoadSave:get_slot_description(): string?
	if self.selected_slot then
		return self.selected_slot.instance.Title.Text;
	end
	
	return nil;
end

function LoadSave:select_slot(slot)
	if self.selected_slot then
		self.selected_slot.instance.UIStroke.Transparency = 0.9;
		self:unload_versions( self.selected_slot );
	end
	
	self:select_version(nil);
	
	if self.selected_slot == slot then
		self.selected_slot = nil;
		
		self.control_list.Visible = false;
		self:toggle_side(false);
	else
		self.selected_slot = slot;
		self.selected_slot.instance.UIStroke.Transparency = 0.2;
		
		self.control_list.Visible = true;
		
		self:update_slot_details();
		self:update_versions();
		self:toggle_side(true);
	end;
end;

function LoadSave:update_slot_details()
	local slot = self.selected_slot;
	
	if slot then
		local slot_title = self.build_tools.slots[slot.id].label or "";
		
		slot.instance.Title.Text = slot_title;
		
		self.side_body.Slot.SlotNumber.Text = `Slot {slot.id}`;
		self.side_body.Slot.SlotName.Text = slot_title;
	end;
end

function LoadSave:delete_slot(slot_id: number): ()
	assert(typeof(slot_id) == "string", "Slot ID must be a string");
	
	if self.slots[slot_id] then
		if self.selected_slot == self.slots[slot_id] then
			self.selected_slot = nil;
		end;
		
		self.slots[slot_id].maid:destroy();
		self.slots[slot_id].instance:Destroy();
		self.slots[slot_id] = nil;
	end
end

function LoadSave:create_slot(slot_id: string)
	assert(typeof(slot_id) == "string", "Slot ID must be a string");
	
	self:delete_slot(slot_id);
	
	local object = self:create_slot_object(slot_id)
	
	object.instance.Button.MouseButton1Click:Connect(function()
		self:select_slot(object);
	end)
	
	object.instance.Title.Text = self.build_tools.slots[slot_id].label or "";
	
	self:update_slot_details();
	self.slots[slot_id] = object;
	
	return object;
end

table.freeze(LoadSave);

return LoadSave;