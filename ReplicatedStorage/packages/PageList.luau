--!strict

--[[
	I have finally made a good solution to the paged-searching that I was wondering how to do efficiently.
]]

local replicatedStorage = game:GetService("ReplicatedStorage")

local Maid = require( replicatedStorage.packages.Maid )

-------------------------------------------------------------------------------------------------

export type PagedFrame = any;
export type PageListFrame = any;
export type SortCallback = (GuiObject, GuiObject) -> (boolean);

export type ClassPageList = {
	__index: ClassPageList;

	new: (parameters: PageListParameters) -> PageList;
	initialise: (self: PageList) -> ();
	destroy: (self: PageList) -> ();
	item_visible_changed: (self: PageList, item: any, visible: boolean) -> ();
	get_current_page: (self: PageList) -> number;
	get_max_pages: (self: PageList) -> number;
	get_number_of_items_on_page: (self: PageList, page: number) -> number;
	update_page_leave: (self: PageList, page: GuiObject) -> ();
	update_page_enter: (self: PageList, page: GuiObject) -> ();
	get_page_at_count: (self: PageList, value: number) -> number;
	resize_layout: (self: PageList, per_row: number, per_column: number?) -> ();
	update_grid_layout: (self: PageList, grid_layout: UIGridLayout) -> ();
	create_page: (self: PageList, page: number) -> PagedFrame;
	get_new_page: (self: PageList) -> PagedFrame;
	show_item: (self: PageList, item: GuiObject) -> ();
	hide_item: (self: PageList, item: GuiObject) -> ();
	search: (self: PageList, text: string) -> ();
	sort: (self: PageList, callback: SortCallback) -> ();
	repage: (self: PageList) -> ();
	add_item: (self: PageList, item: GuiObject, value: any, page_num: number?) -> ();
	remove_item: (self: PageList, item: GuiObject) -> ();
	remove_all: (self: PageList) -> ();
};

export type PageList = typeof(setmetatable({} :: {
	
	maid: Maid.Maid;
	sorting: SortCallback?;
	
	per_page: number;
	per_row: number;
	per_column: number?;
	cell_padding: UDim2?;
	layout: UIPageLayout,
	next_button: GuiButton,
	previous_button: GuiButton,
	page_current: TextBox;
	page_max: TextLabel;
	page_preset: any;
	
	current_page: number;
	max_pages: number;
	
	items: {[GuiObject]: any};
	item_index: {[number]: GuiObject};
	pages: {[number]: PagedFrame};
	
}, {} :: ClassPageList));

export type PageListParameters = {
	per_page: number?, 
	per_row: number?,
	
	layout: UIPageLayout,
	next_button: GuiButton,
	previous_button: GuiButton,
	page_current: TextBox;
	page_max: TextLabel;
	page_preset: any;
};

-------------------------------------------------------------------------------------------------

local PageList = {} :: ClassPageList;
PageList.__index = PageList;

function PageList.new(parameters)
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			maid = maid;
			
			per_page = parameters.per_page or 8;
			per_row = parameters.per_row or 4;
			per_column = nil;
			layout = parameters.layout;
			next_button = parameters.next_button;
			previous_button = parameters.previous_button;
			page_current = parameters.page_current;
			page_max = parameters.page_max;
			page_preset = parameters.page_preset;
			
			current_page = 0;
			max_pages = 0;
			
			items = {};
			pages = {};
			item_index = {};
		}, 
		PageList);
	
	self:initialise();
	
	return self;
end;

function PageList:initialise()
	self.maid:add(self.layout.PageEnter:Connect(function(page)
		self:update_page_enter(page :: GuiObject);
	end))

	self.maid:add(self.layout.PageLeave:Connect(function(page)
		self:update_page_leave(page :: GuiObject);
	end))

	self.maid:add(self.page_current.FocusLost:Connect(function(was_enter_pressed)
		local current_page = tonumber(self.page_current.Text) or 1;
		
		if was_enter_pressed then
			self.layout:JumpToIndex( current_page - 1 )
		else
			self.page_current.Text = tostring(self:get_current_page() + 1);
		end
	end))

	self.maid:add(self.next_button.MouseButton1Click:Connect(function()
		self.layout:Next();
	end));

	self.maid:add(self.previous_button.MouseButton1Click:Connect(function()
		self.layout:Previous();
	end));
end

function PageList:destroy()
	for _, page in self.pages do
		page:Destroy();
	end;
	
	self.maid:destroy();
	
	table.clear(self.pages);
	table.clear(self.items);
end

function PageList:get_current_page(): number
	if self.current_page then
		return self.current_page;
	end;
	
	local page = tonumber(self.page_current.Text);
	
	if page then
		return page - 1;
	end;
	
	return 0;
end

function PageList:item_visible_changed(item, visible)
	-- print("override my functions ...")
end

function PageList:get_max_pages(): number
	return self.max_pages or tonumber(self.page_max.Text) or 1;
end

function PageList:get_number_of_items_on_page(page: number)
	local count = 0;
	
	for _, instance in self.pages[page].ScrollingFrame:GetChildren() do
		if self.items[instance] then
			count += 1;
		end
	end;
	
	return count;
end

function PageList:update_page_leave(page: GuiObject): ()
	local index = page.LayoutOrder;
	
	if not self.pages[index] then return end;
	
	for _, instance in self.pages[index].ScrollingFrame:GetChildren() do
		local item = self.items[instance];
		
		if item then
			self:item_visible_changed(item, false);
		end
	end
end

function PageList:update_page_enter(page: GuiObject): ()
	local index = page.LayoutOrder;
	
	if not self.pages[index] then return end;
	
	self.current_page = index - 1;
	self.page_current.Text = tostring(index);
	
	for _, instance in self.pages[index].ScrollingFrame:GetChildren() do
		local item = self.items[instance];
		
		if item and instance.Visible then
			self:item_visible_changed(item, true);
		end
	end
end

function PageList:get_page_at_count(value: number): number
	if self.per_page == 0 then
		return #self.pages + 1;
	end;
	
	return value // self.per_page + 1;
end;

function PageList:resize_layout(per_row: number, per_column: number?)
	self.per_row = per_row;
	self.per_column = per_column;
	
	for page, frame in self.pages do
		local scrolling_frame = frame.ScrollingFrame;
		local grid_layout = scrolling_frame:FindFirstChild("UIGridLayout");
		
		if grid_layout then
			self:update_grid_layout(grid_layout);
		end;
	end;
end

function PageList:update_grid_layout(grid_layout)
	local scrolling_frame = grid_layout.Parent :: ScrollingFrame;
	local scale = scrolling_frame.AbsoluteSize;
	
	if self.cell_padding then
		grid_layout.CellPadding = self.cell_padding;
	end;
	
	local size_x = scale.X / self.per_row - grid_layout.CellPadding.X.Offset - 2
	local size_y = if self.per_column then scale.Y / self.per_column + 4 else size_x;
	
	grid_layout.CellSize = UDim2.fromOffset(size_x, size_y);
end;

function PageList:create_page(page: number): PagedFrame
	if self.pages[page] then return self.pages[page] end;
	
	local page_frame = self.page_preset:Clone()
	page_frame.Visible = true;
	page_frame.Name = `Page{page}`;
	page_frame.LayoutOrder = page;
	page_frame.Parent = self.layout.Parent;
	
	local scrolling_frame = page_frame.ScrollingFrame;
	local grid_layout = scrolling_frame:FindFirstChild("UIGridLayout");
	
	if grid_layout then
		self:update_grid_layout(grid_layout);
		
		scrolling_frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			self:update_grid_layout(grid_layout);
		end)
	end
	
	self.pages[page] = page_frame;
	
	return page_frame;
end

function PageList:get_new_page(): PagedFrame
	return self:create_page( self:get_page_at_count(#self.item_index) );
end

function PageList:show_item(item: GuiObject): ()
	if self.items[item] then
		item.Visible = true;
	end;
end

function PageList:hide_item(item: GuiObject): ()
	if self.items[item] then
		item.Visible = false;
		
		self:item_visible_changed(self.items[item], false);
	end;
end

function PageList:search(text: string): ()
	local search_text = string.lower(text);
	local show_all = search_text == "";
	local has_changed = false;
	
	for frame: GuiObject in self.items do
		if show_all or string.match(string.lower(frame.Name), search_text) then
			if not frame.Visible then
				has_changed = true;
				frame.Visible = true;
			end;
			
		elseif frame.Visible then
			has_changed = true;
			frame.Visible = false;
		end
	end
	
	if has_changed then
		self:repage();
	end;
end;

function PageList:sort(callback): ()
	self.sorting = callback;
	self:repage();
end

function PageList:repage()
	local layout = {};
	
	for index, item in self.item_index do
		if item.Visible then
			table.insert(layout, item);
		end;
	end;
	
	if self.sorting then
		table.sort(layout, function(frame1, frame2)
			return self.sorting(frame1, frame2);
		end);
	end
	
	local max_page = 1;
	
	for index, item in layout do
		max_page = self:get_page_at_count( index - 1 );
		
		local page = self:create_page( max_page );
		
		page.ScrollingFrame.CanvasPosition = Vector2.new(0, 0);
		
		item.Visible = true;
		item.LayoutOrder = index;
		
		if item.Parent ~= page.ScrollingFrame then
			item.Parent = page.ScrollingFrame;
		end;
	end
	
	self.max_pages = max_page;
	self.page_max.Text = tostring(max_page);
	
	for max = 1, #self.pages do
		self.pages[max].Visible = max <= max_page;
	end
	
	local current_page = self.layout.CurrentPage;
	
	if not current_page then
		self.layout:JumpToIndex(0);
	else
		self:update_page_enter(current_page);
	end
end

function PageList:add_item(item: GuiObject, value: any, page_num: number?): ()
	if self.items[item] then return end;
	
	self.items[item] = value;
	table.insert(self.item_index, item);
	
	local page_frame = if page_num then self:create_page(page_num) else self:get_new_page();
	item.Visible = true;
	item.Parent = page_frame.ScrollingFrame;
end

function PageList:remove_all(): ()
	table.clear(self.item_index);
	table.clear(self.items);
	
	self:repage();
end

function PageList:remove_item(item: GuiObject): ()
	if not self.items[item] then return end;
	
	local index = table.find(self.item_index, item);
	
	if index then
		table.remove(self.item_index, index);
	end
	
	self.items[item] = nil;
	
	item.Parent = nil;
end

table.freeze(PageList);

return PageList;