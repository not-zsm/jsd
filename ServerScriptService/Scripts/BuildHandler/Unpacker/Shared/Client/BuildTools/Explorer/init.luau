local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local BuildTools = script.Parent;
local Builds = workspace:WaitForChild("Builds");
local Assets = BuildTools:WaitForChild("Assets");
local Sounds = BuildTools:WaitForChild("Sounds");
local BuildShared = ReplicatedStorage:WaitForChild("BuildTools");
local Remotes = BuildShared:WaitForChild("Remotes");

local InstanceCache = require( ReplicatedStorage.Packages.InstanceCache )
local Stylus = require( ReplicatedStorage.Packages.Stylus )
local Maid = require( ReplicatedStorage.Packages.Maid )
local HelpInput = require( ReplicatedStorage.Packages.HelpInput )
local Type = require( ReplicatedStorage.Packages.Type )
local ExplorerItem = require( script.ExplorerItem )

local Explorer = {};
Explorer.__index = Explorer;

function Explorer.new(build_tools)
	local self = setmetatable(
		{
			build_tools = build_tools;
			enabled = false;
			is_searching = false;
			
			maid = build_tools.maid:limb();
			items = {};
			cache = InstanceCache.new(15, build_tools.assets.ExplorerItem);
			
			explorer_body = build_tools.elements.Explorer.Body.Body;
			select_bounds = build_tools.elements.Explorer.Body.SelectBounds;
		}, 
		Explorer);
	
	self:initialise();
	
	return self;
end;

local function name_match_query(child: Instance, search: string): boolean
	return string.match(string.lower(child.Name), string.lower(search)) ~= nil;
end

local function isa_match_query(child: Instance, search: string): boolean
	return child:IsA(search);
end

local operators = {
	["="] = function(value1, value2)
		return value1 == value2;
	end,
	[">="] = function(value1, value2)
		return value1 >= value2;
	end,
	["<="] = function(value1, value2)
		return value1 <= value2;
	end,
	[">"] = function(value1, value2)
		return value1 > value2;
	end,
	["<"] = function(value1, value2)
		return value1 < value2;
	end,
};

local function get_property(instance: Instance, property: string): any
	return instance[property];
end

-- Does not allow for chaining multiple queries.
local function get_sub_query(text: string): (string, (Instance, string) -> (boolean))
	local query_text = text;
	local query_match = name_match_query;

	if string.sub(string.lower(text), 1, 3) == "is:" then
		query_text = string.sub(text, 4, -1);
		query_match = isa_match_query;
	else
		local property, operator, value = string.match(text, "(%w+)([=><]+)(.+)" );

		if property and operators[operator] then
			local calculate = operators[operator];

			query_match = function(child: Instance, search: string): boolean
				local exists, value1 = pcall(get_property, child, property);

				if exists then
					local caster = Type[typeof(value1)];

					if caster then
						return calculate(value1, caster:cast(value))
					end;
				end;

				return false;
			end
		end
	end
	
	return query_text, query_match;
end

function Explorer:update_explorer_query(instances: {Instance}, text: string): ()
	self.items[Builds]:unexpand_children();
	self.items[Builds]:expand_children();
	
	if (text == "") then
		self.is_searching = false;
		
		for _, child in instances do
			local frame = self.items[child];

			if frame then
				frame:unexpand_children();
			end
		end
	else
		local query_text, query_match = get_sub_query(text);
		
		self.is_searching = true;
		
		for _, child in instances do
			local frame = self.items[child];

			if frame then
				frame:hide();
			end;
		end;
		
		local do_work_later = 0;

		for index, child in instances do
			local frame = self.items[child];

			if frame and query_match(child, query_text) then
				do_work_later += 1;
				
				frame._searched = true;
				frame:show_with_ancestry(true);
				
				if (do_work_later > 4) then
					do_work_later = 0;
					task.wait();
				end;
			end;
		end;
	end;
end

function Explorer:initialise()
	local loading_maid = Maid.new();

	self.maid:add(Stylus:bind_hover_highlight(self.explorer_body.SearchBox, {Transparency = 0.95}))

	self.maid:add(self.explorer_body.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local text = self.explorer_body.SearchBox.Text;
		local instances = Builds:GetDescendants();

		loading_maid:clean();
		loading_maid:add(task.spawn(self.update_explorer_query, self, instances, text));
	end));
	
	self.maid:add(self.build_tools.elements.Explorer.SideContext.Bottom.Deselect.MouseButton1Click:Connect(function()
		self.build_tools.selection:deselect();
	end))
	
	self.maid:add(self.build_tools.elements.Explorer.SideContext.Bottom.Delete.MouseButton1Click:Connect(function()
		self.build_tools.actions:delete( self.build_tools.selection:get() )
	end))
	
	self:get(game.Lighting):show()
	self:get(game.Teams):show()
	
	do
		local frame = self:get(Builds)
		
		task.defer(function()
			frame:expand_children()
		end);

		frame:show()
		Stylus:set_sprite_icon(frame.icon, "Workspace");
		
		self.maid:add(self.build_tools.preferences:observe("hide_builds_folder", function(value)
			if value then
				frame:ghost();
			else
				frame:unghost();
			end
		end));

		self.maid:add(self.build_tools.preferences:observe("explorer_instance_pixel_scale", function(value)
			for _, frame in self.items do
				frame:update_scale(value);
			end;
		end));

		self.maid:add(self.build_tools.preferences:observe("explorer_spacing_pixel_scale", function(value)
			for _, frame in self.items do
				frame:update_spacing(value);
			end;
		end));

		self.maid:add(self.build_tools.preferences:observe("explorer_expand_pixel_scale", function(value)
			for _, frame in self.items do
				if frame.ghosted then continue end;

				frame:update_expand_depth(value);
			end;
		end));
	end;
	
	self.maid:add(self.build_tools.selection.on_selection_changed:Connect(function(first_child, select_count, was_selected)
		if not was_selected then return end;

		debug.profilebegin("Update Explorer Position");

		local frame = self.items[first_child];

		if frame then
			frame:show_with_ancestry();

			if select_count == 1 then
				local inset = GuiService:GetGuiInset();
				local scrolling = self.explorer_body.Body.ScrollingFrame;

				local scroll_position = scrolling.AbsolutePosition - inset;
				local previous_position = frame.select.AbsolutePosition.Y - inset.Y;

				if previous_position > scroll_position.Y + scrolling.AbsoluteSize.Y or previous_position < scroll_position.Y then
					scrolling.CanvasPosition = Vector2.zero;

					task.defer(function()
						scrolling.CanvasPosition = Vector2.new(0, frame.select.AbsolutePosition.Y - scroll_position.Y - scrolling.AbsoluteSize.Y / 3);
					end);
				end;
			end;
		end

		debug.profileend();
	end))

	self.maid:add(self.build_tools.selection.on_selection_added:Connect(function(child)
		self.build_tools.actions:clear_commit();

		task.defer(function()
			local frame = self.items[child];

			if frame then
				frame.is_selected = true;
				frame:update_highlight();
			end;
		end);
	end))

	self.maid:add(self.build_tools.selection.on_selection_removed:Connect(function(child)

		task.defer(function()
			local frame = self.items[child];

			if frame then
				frame.is_selected = false;
				frame:update_highlight();
			end;
		end);
	end))
	
	local down_position: Vector2?;
	local down_connection;
	
	local function update_selection(dt: number)
		if not self.build_tools.selection.is_multiselecting then
			local next_position = UserInputService:GetMouseLocation();

			if (next_position - down_position).Magnitude >= 3 then
				self.build_tools.selection:start_multi_selection(true);
			end
		else
			self.build_tools.selection:update_selection_rectangle();
		end
	end
	
	local function disconnect_all()
		down_position = nil;

		if down_connection and down_connection.Connected then
			down_connection:Disconnect();
		end;
	end;
	
	self.maid:add(UserInputService.InputEnded:Connect(function(input, processed)
		if HelpInput.IsInteract(input) then
			disconnect_all();
		end
	end))
	
	self.maid:add(UserInputService.InputBegan:Connect(function(input, processed)
		if HelpInput.IsInteract(input) and Stylus:is_hovering_over(self.select_bounds) then
			down_position = UserInputService:GetMouseLocation();
			down_connection = RunService.PostSimulation:Connect(update_selection);
		end;
	end))
	
	self.maid:add(disconnect_all)
end

function Explorer:get(instance: Instance, parent: Instance?): ExplorerItem.ExplorerFrame
	if instance == self.build_tools.selection.model then return end;

	local frame = self.items[instance]

	if frame then 
		frame:set_parent(parent);
		return frame
	end;

	return ExplorerItem.new(self, instance, parent);
end

function Explorer:clear()
	for _, frame in self.items do
		frame:destroy();
	end

	table.clear(self.items);
end

function Explorer:remove(instance: Instance)
	if self.items[instance] then
		self.items[instance] = nil;
	end
end

function Explorer:destroy()
	self:clear();
	table.clear(self);
end

table.freeze(Explorer);

return Explorer;