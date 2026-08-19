local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-----------------------------------------------------------------------------------------------------------

local Signal = require( ReplicatedStorage.Packages.Signal )
local Maid = require( ReplicatedStorage.Packages.Maid )
local Type = require( ReplicatedStorage.Packages.Type )
local Stylus = require( ReplicatedStorage.Packages.Stylus )
local HelpInput = require( ReplicatedStorage.Packages.HelpInput )
local Asset = require( ReplicatedStorage.Packages.Asset )
local PageList = require( ReplicatedStorage.Packages.PageList )
local AssetQuery = require( script.AssetQuery )

local Item = require( script.Parent.Inventory.Item )

-----------------------------------------------------------------------------------------------------------

export type DecalAsset = {
	Name: string,
	AssetId: number,
	AssetVersionId: number,
	CreatorName: string;
};

export type FreeDecals = {
	CurrentStartIndex: number,
	TotalCount: number,
	Results: {
		[number]: DecalAsset,
	},
};

export type ClassToolbox = {
	__index: ClassToolbox;

	new: (build_tools: any) -> Toolbox;
	initialise: (self: Toolbox) -> ();
	create_entry: (self: Toolbox, asset: DecalAsset) -> any;
	clear: (self: Toolbox) -> ();
	set_loading: (self: Toolbox, value: boolean) -> ();
	search: (self: Toolbox, text: string, page: number?) -> ();
	search_async: (self: Toolbox, text: string, page: number?) -> ();
	bind_stringbox: (self: Toolbox, stringbox: any, callback: (asset_id: number) -> ()) -> ();
	destroy: (self: Toolbox) -> ();
	toggle: (self: Toolbox, value: boolean?) -> ();
};

export type Toolbox = typeof(setmetatable({} :: {
	
	build_tools: any;
	tool_ui: any;
	body: any;
	items_frame: any;
	maid: Maid.Maid;
	
	active_text: string;
	search_debounce: boolean;
	is_loading: boolean;
	active: boolean;
	enabled: boolean;
	affector_instance: Instance;
	tweens: {[string]: Tween};
	items: {any};

	on_apply: Signal.Signal<>;
	on_cancel: Signal.Signal<>;
	closed: Signal.Signal<>;
	opened: Signal.Signal<>;
	
}, {} :: ClassToolbox));

-----------------------------------------------------------------------------------------------------------

local Toolbox = {} :: ClassToolbox;
Toolbox.__index = Toolbox;
Toolbox.asset_type = Enum.AssetType.Decal;

function Toolbox.new(build_tools)
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			build_tools = build_tools;
			tool_ui = build_tools.ui.Toolbox;
			body = build_tools.ui.Toolbox.Body.Toolbox.Body;
			items_frame = build_tools.ui.Toolbox.Body.Toolbox.Body.Items;
			page_layout = build_tools.ui.Toolbox.Body.Toolbox.Body.Items.Body.UIPageLayout;
			maid = maid;
			loading_maid = maid:limb();
			
			active_loading = 0;
			active_text = "";
			search_debounce = false;
			is_loading =  false;
			active = false;
			enabled = false;
			affector_instance = nil;
			tweens = {};
			items = {};
			
			on_apply = Signal.new();
			on_cancel = Signal.new();
			closed = Signal.new();
			opened = Signal.new();
			
			audio_search_params = Instance.new("AudioSearchParams");
		}, 
		Toolbox)
	
	self:initialise();
	
	return self;
end

function Toolbox:initialise()
	do
		self.tweens.open = TweenService:Create(self.tool_ui.Body.Toolbox, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {GroupTransparency = 0, AnchorPoint = Vector2.new(0.5, 0.5)});
		self.tweens.close = TweenService:Create(self.tool_ui.Body.Toolbox, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {GroupTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.25)});

		self.tweens.close:Play();

		self.tweens.close.Completed:Connect(function(status)
			if (status == Enum.PlaybackState.Completed) then
				self.tool_ui.Enabled = false;
			end
		end)
	end

	self.body.Title.Close.MouseButton1Click:Connect(function()
		self:toggle(false);
	end)
	
	local items_page = self.build_tools.assets.DynamicItemsPage:Clone();
	items_page.Parent = self.items_frame.Body;
	
	self.items_page = PageList.new({
		["per_page"] = 21;
		["per_row"] = 4;
		["layout"] = items_page.Pages.UIPageLayout;
		["page_max"] = items_page.Controls.List.Page.Max;
		["page_current"] = items_page.Controls.List.Page.Current;
		["next_button"] = items_page.Controls.List.Next;
		["previous_button"] = items_page.Controls.List.Previous;
		["page_preset"] = self.build_tools.assets.DynamicPage;
	})
	
	self.items_page.next_button.MouseButton1Click:Connect(function()
		
		if self.items_page:get_current_page() + 1 >= self.items_page:get_max_pages() then
			self:next_page()
		end
	end)
	
	local function activate_search()
		self:clear();
		self:search({ 
			Text = self.body.Filter.Search.Box.Text, 
			AssetType = self.asset_type,
			AudioSearchParams = self.audio_search_params
		});
	end
	
	self.items_frame.Body.Filter.Control.Apply.Button.MouseButton1Click:Connect(activate_search)
	
	do
		local defaults = Instance.new("AudioSearchParams");
		
		self.items_frame.Body.Filter.Control.Reset.Button.MouseButton1Click:Connect(function()
			for _, property in {"MaxDuration", "MinDuration", "AudioSubtype", "Artist"} do
				self.audio_search_params[property] = defaults[property];
			end;
			
			activate_search();
		end)
	end
	
	self.body.Filter.Search.Box.FocusLost:Connect(function(enter_pressed: boolean)
		if enter_pressed then
			activate_search();
		end;
	end)
	
	self.body.Filter.Filter.Button.MouseButton1Click:Connect(function()
		if self.asset_type ~= Enum.AssetType.Audio then
			return self.build_tools:notify("info", `No filtering options are provided for {self.asset_type.Name}s` , 4)
		end;
		
		if self.page_layout.CurrentPage == self.items_frame.Body.Filter then
			self.page_layout:JumpToIndex(0);
		else
			self.page_layout:JumpTo(self.items_frame.Body.Filter);
		end;
	end)
	
	self.body.MouseEnter:Connect(function()
		self.active = true;
	end)
	
	self.body.MouseLeave:Connect(function()
		self.active = false;
	end)
	
	UserInputService.TouchTap:Connect(function()
		if not self:get_interact_active() then
			self:toggle(false);
		end
	end)
	
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and not self:get_interact_active() then
			self:toggle(false);
		end
	end)
	
	self:initialise_audio_filter();
end

function Toolbox:initialise_audio_filter()
	local scrolling_frame = self.items_frame.Body.Filter.Body.ScrollingFrame;

	local audio_subtype = Stylus:new_stringbox({
		text = "Audio Type";
		value = "Music";
		parent = scrolling_frame;
		theme = "bg_transparent";
		button_based = true;
		ratio = 0.6;
		height = 0.065;
	});

	audio_subtype.interacted:Connect(function()
		local value = self.audio_search_params.AudioSubtype.Value;
		local next_enum = Enum.AudioSubType:FromValue(value + 1);

		if not next_enum then
			next_enum = Enum.AudioSubType:FromValue(1);
		end;

		self.audio_search_params.AudioSubtype = next_enum;
	end)

	self.audio_search_params:GetPropertyChangedSignal("AudioSubtype"):Connect(function()
		audio_subtype:set_text(Asset.pretty_string(self.audio_search_params.AudioSubtype.Name));
	end)

	do
		local artist = Stylus:new_stringbox({
			text = "Author";
			value = "";
			parent = scrolling_frame;
			theme = "bg_transparent";
			ratio = 0.6;
			height = 0.065;
		});

		artist.interacted:Connect(function(value)
			self.audio_search_params.Artist = value;
		end)

		self.audio_search_params:GetPropertyChangedSignal("Artist"):Connect(function()
			artist:set_text(self.audio_search_params.Artist);
		end)
	end;
	do
		local tag = Stylus:new_stringbox({
			text = "Tag";
			value = "";
			parent = scrolling_frame;
			theme = "bg_transparent";
			ratio = 0.6;
			height = 0.065;
		});

		tag.interacted:Connect(function(value)
			self.audio_search_params.Tag = value;
		end)

		self.audio_search_params:GetPropertyChangedSignal("Tag"):Connect(function()
			tag:set_text(self.audio_search_params.Tag);
		end)
	end;
	do
		local title = Stylus:new_stringbox({
			text = "Title";
			value = "";
			parent = scrolling_frame;
			theme = "bg_transparent";
			ratio = 0.6;
			height = 0.065;
		});

		title.interacted:Connect(function(value)
			self.audio_search_params.Title = value;
		end)

		self.audio_search_params:GetPropertyChangedSignal("Title"):Connect(function()
			title:set_text(self.audio_search_params.Title);
		end)
	end;

	local duration = Stylus:new_stringbox({
		text = "Duration (/s)";
		value = "0, 360";
		parent = scrolling_frame;
		theme = "bg_transparent";
		ratio = 0.6;
		height = 0.065;
	});
	local duration_value = NumberRange.new(0, 2^31);

	duration.interacted:Connect(function(value)
		local range, success = Type.NumberRange:cast(value);

		if success then
			duration_value = range;
		end;

		self.audio_search_params.MaxDuration = duration_value.Max;
		self.audio_search_params.MinDuration = duration_value.Min;
	end)

	local function update_durations()
		duration:set_text(`{self.audio_search_params.MinDuration}, {math.min(self.audio_search_params.MaxDuration, 480)}`);
	end

	self.audio_search_params:GetPropertyChangedSignal("MaxDuration"):Connect(update_durations)
	self.audio_search_params:GetPropertyChangedSignal("MinDuration"):Connect(update_durations)
end

function Toolbox:get_interact_active()
	return self.active or Stylus:is_hovering_over_any{self.affector_instance};
end

function Toolbox:set_playing_audio(audio: Sound?)
	local last_audio = self.current_audio;
	
	self.current_audio = audio;
	
	if last_audio then
		last_audio:Stop();
	end;
	
	if audio then
		audio:Play();
	end;
end

function Toolbox:create_audio_entry(asset: AudioAsset)
	local item = self.build_tools.assets.AudioItem:Clone();
	local sound;
	
	Stylus.bind_to_resize(item, function(absolute_size)
		item.Button.Title.TextSize = absolute_size.Y * 0.5;
		item.Button.Length.TextSize = absolute_size.Y * 0.6;
	end);

	item.Button.Title.Text = asset.Title;
	item.Button.Length.Text = Asset.pretty_time(asset.Duration);
	
	item.Button.MouseButton1Click:Connect(function()
		self.on_apply:Fire(asset);
		self.build_tools:notify("info", "Sound Id was applied to selected", 3);
	end)
	
	item.Button.Play.MouseButton1Click:Connect(function()
		if not sound then
			sound = Instance.new("Sound");
			sound.Volume = 2;
			sound.SoundId = Asset.get_rbx_asset(asset.Id);
			sound.Parent = item;
			
			local function show_to_stop()
				item.Button.Play.BackgroundColor3 = Color3.fromRGB(127, 72, 72);
				item.Button.Play.Icon.Image = "rbxassetid://8517320975";
			end;
			
			local function show_to_play()
				item.Button.Play.BackgroundColor3 = Color3.fromRGB(81, 127, 74);
				item.Button.Play.Icon.Image = "rbxassetid://12099513379";
			end;
			
			sound.Played:Connect(show_to_stop);
			sound.Ended:Connect(show_to_play);
			sound.Stopped:Connect(show_to_play);
		end;
		
		if not sound.IsPlaying then
			self:set_playing_audio(sound)
		else
			self:set_playing_audio(nil)
		end
	end);
	
	self.items_page:add_item(item);
	
	table.insert(self.items, item);
	
	return item;
end

function Toolbox:create_decal_entry(asset: DecalAsset)
	local item = Item.new(self, 0, {})
	
	item:set_icon(Asset.get_thumbnail(asset.AssetId, 420, 420));
	item:initialise_as_item();
	
	item.frame.Button.MouseButton1Click:Connect(function()
		self.on_apply:Fire(asset);
		self.build_tools:notify("info", "Image was applied to selected", 3);
	end);
	
	self.items_page:add_item(item.frame, item);
	
	table.insert(self.items, item);
	
	return item;
end

function Toolbox:clear()
	self.active_text = "";
	self.items_page:remove_all();
	
	for _, item in self.items do
		item:destroy();
	end;
	
	table.clear(self.items);
end

function Toolbox:increment_loading(value: number)
	self.active_loading = math.max(self.active_loading + value, 0);
	
	if self.is_loading and self.active_loading == 0 then
		self:set_loading(false);
		
	elseif not self.is_loading and self.active_loading > 0 then
		self:set_loading(true);
	end
end

function Toolbox:set_loading(value: boolean)
	self.loading_maid:clean();
	
	local loading = self.items_frame.Loading;
	
	if value then
		self.is_loading = true;
		loading.Loading.Visible = true;
		loading.LoadingBackdrop.Visible = true;

		self.loading_maid:add(RunService.PreRender:Connect(function(dt)
			loading.Loading.Rotation += 360 * dt;
		end))
	else
		self.is_loading = false;
		loading.Loading.Visible = false;
		loading.LoadingBackdrop.Visible = false;
	end
end

function Toolbox:next_page(): ()
	if not self.pager then return end;
	if self.search_debounce or self.is_loading then return end;
	
	self:increment_loading(1);
	pcall(self.pager.AdvanceToNextPageAsync, self.pager);
	self:update_search_results();
	self:increment_loading(-1);
end

function Toolbox:load_audio_results(results)
	for _, asset in results do
		self:create_audio_entry(asset);
	end

	self.items_page.per_page = #results;
end

function Toolbox:load_decal_results(results)
	local items: any = results[1];

	if math.round(items.TotalCount) > 0 then
		for _, asset in items.Results do
			self:create_decal_entry(asset);
		end

		self.items_page.per_page = math.round(items.TotalCount);
	end;
end

function Toolbox:update_search_results(): ()
	if not self.pager then
		return warn("No active pager?");
	end;
	
	local results = self.pager:GetCurrentPage();
	
	if results then
		if self.pager.Query.AssetType == Enum.AssetType.Audio then
			self.items_page.cell_padding = UDim2.fromOffset(8, 2);
			self.items_page:resize_layout(1, 8);
			
			self:load_audio_results(results);
		else
			self.items_page.cell_padding = UDim2.fromOffset(4, 4);
			self.items_page:resize_layout(4);
			
			self:load_decal_results(results);
		end;
		
		self.items_page:repage();
		
		task.defer(function()
			self.items_page.layout:JumpToIndex(self.items_page:get_max_pages() - 1);
		end)
		
		self.items_page.page_max.Text = "-";
	end;
end

function Toolbox:search(query: any): ()
	task.spawn(self.search_async, self, query);
end

function Toolbox:search_async(query): ()
	if self.is_loading or self.search_debounce then return end;
	
	self.page_layout:JumpToIndex(0);
	
	self:increment_loading(1);
	self:clear();
	
	self.search_debounce = true;
	self.active_text = query.Text;
	self.pager = AssetQuery.search(query)
	
	self:update_search_results();
	self:increment_loading(-1);
	
	task.delay(0.5, function()
		self.search_debounce = false;
	end);
end

function Toolbox:bind_stringbox(stringbox, callback)
	
	if callback then
		stringbox.maid:add(self.on_apply:Connect(function(asset: any)
			if self.affector_instance == stringbox.instance then
				callback( tostring(asset.AssetId or asset.Id) );
			end;
		end))
	end;
end

function Toolbox:destroy()
	self.maid:destroy();
end

function Toolbox:toggle(value: boolean?, asset_type: Enum.AssetType)
	if (value == nil) then
		value = not self.enabled;
	end;

	if (value ~= self.enabled) then
		self.build_tools:close_all(self);
		self.enabled = value;
		
		if (value) then
			local last_asset_type = self.asset_type;
			local go_to_home_page = self.items_page:get_max_pages() == 0;
			
			if last_asset_type ~= asset_type then
				go_to_home_page = true;
				self.asset_type = asset_type;
			end;
			
			self.opened:Fire();
			self.tweens.open:Play();
			self.tool_ui.Enabled = true;
			
			Stylus:tween_blur(15);
			SoundService:PlayLocalSound(self.build_tools.sounds.DockToggle);
			
			if go_to_home_page then
				self:search({Text = "", AssetType = self.asset_type});
			end
			
			self.page_layout:JumpToIndex(0);
		else
			self.affector_instance = nil;
			self.closed:Fire();
			self.tweens.close:Play();
			
			Stylus:tween_blur(0);
		end	
	end;
end

table.freeze(Toolbox);

return Toolbox;