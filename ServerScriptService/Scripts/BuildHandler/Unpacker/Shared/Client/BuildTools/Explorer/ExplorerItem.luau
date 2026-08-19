local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

--------------------------------------------------------------------------------------------------------

local Maid = require( ReplicatedStorage.Packages.Maid );
local Table = require( ReplicatedStorage.Packages.Table );
local Type = require( ReplicatedStorage.Packages.Type );
local Stylus = require( ReplicatedStorage.Packages.Stylus )
local InstanceCache = require( ReplicatedStorage.Packages.InstanceCache )
local HelpInput = require( ReplicatedStorage.Packages.HelpInput )

--------------------------------------------------------------------------------------------------------

local BuildTools = script.Parent.Parent;
local Builds = workspace:WaitForChild("Builds");
local Assets = BuildTools:WaitForChild("Assets");

--------------------------------------------------------------------------------------------------------

local FrameSelectedHoverColor = Color3.fromRGB(62, 142, 255);
local FrameSelectedColor = Color3.fromRGB(56, 126, 230);
local FrameHoverColor = Color3.fromRGB(255, 255, 255);
local FrameDefaultColor = Color3.fromRGB(28, 28, 28);

--------------------------------------------------------------------------------------------------------

export type ClassExplorerFrame = {
	__index: ClassExplorerFrame;
	
	update_scale: (self: ExplorerFrame, scale: number) -> ();
	update_spacing: (self: ExplorerFrame, scale: number) -> ();
	update_expand_depth: (self: ExplorerFrame, scale: number) -> ();
	can_be_shown: (child: Instance) -> boolean;
	set_expanded: (self: ExplorerFrame, value: boolean) -> ();
	update_expandable: (self: ExplorerFrame) -> ();
	expand_children: (self: ExplorerFrame, dont_show: boolean?) -> ();
	unexpand_children: (self: ExplorerFrame) -> ();
	get_ancestry_shown: (self: ExplorerFrame) -> boolean;
	unghost: (self: ExplorerFrame) -> ();
	ghost: (self: ExplorerFrame) -> ();
	is_visible: (self: ExplorerFrame) -> boolean;
	hide: (self: ExplorerFrame) -> ();
	show: (self: ExplorerFrame) -> ();
	get_ancestry: (self: ExplorerFrame) -> {ExplorerFrame};
	show_with_ancestry: (self: ExplorerFrame, dont_show: boolean?) -> ();
	update_modifier_count: (self: ExplorerFrame) -> ();
	child_added: (self: ExplorerFrame, child: Instance) -> ();
	child_removed: (self: ExplorerFrame, child: Instance) -> ();
	has_children: (self: ExplorerFrame) -> boolean;
	update_highlight: (self: ExplorerFrame) -> ();
	destroy: (self: ExplorerFrame) -> ();
	set_parent: (self: ExplorerFrame, parent: Instance?) -> ();
	reparent: (self: ExplorerFrame) -> ();
	get_children: (self: ExplorerFrame) -> {Instance};
	capture_multi_selection: (self: ExplorerFrame) -> ();
	capture_click: (self: ExplorerFrame) -> ();
	capture_right_click: (self: ExplorerFrame) -> ();
	capture_expand_click: (self: ExplorerFrame) -> ();
	update_frame: (self: ExplorerFrame) -> ();
	init: (self: ExplorerFrame) -> ();
	new: (build_tools: any, instance: Instance, parent: Instance?) -> ExplorerFrame;
	get: (build_tools: any, instance: Instance, parent: Instance?) -> ExplorerFrame;
};

export type ExplorerFrame = typeof(setmetatable({} :: {
	
	parent: Instance?;

	build_tools: any;
	instance: Instance;

	instance_children: {};

	modifier_count: number;
	is_expanded: boolean;
	maid: Maid.Maid;
	
}, {} :: ClassExplorerFrame));

--------------------------------------------------------------------------------------------------------

local ExplorerFrame = {} :: ClassExplorerFrame;
ExplorerFrame.__index = ExplorerFrame;

function ExplorerFrame:update_scale(scale: number)
	if not scale or not self.frame then return end;
	
	self.frame.Body.Size = UDim2.new(1, 0, 0, scale);
	self.liner.Position = UDim2.new(0, scale / 2, 1, 0);
end

function ExplorerFrame:update_spacing(scale: number)
	if not scale or not self.frame then return end;
	
	self.children.UIListLayout.Padding = UDim.new(0, scale);
end

function ExplorerFrame:update_expand_depth(scale: number)
	if not scale or not self.frame then return end;
	
	self.children.UIPadding.PaddingLeft = UDim.new(0, scale);
end

function ExplorerFrame.can_be_shown(child: Instance): boolean
	return child.Archivable
		and not child:HasTag("SelectionIgnore") 
		and not child:HasTag("InstanceModifier") 
		and not child:IsA("TouchTransmitter");
end

function ExplorerFrame:set_expanded(value: boolean)
	if (self.is_expanded ~= value) then
		self.is_expanded = value;
		self:update_expandable();
	end
end

function ExplorerFrame:update_expandable()
	if not self.frame then return end;
	if self.ghosted then self.children.Visible = true return end;
	
	local has_children = self:has_children();
	
	Stylus:set_expand_icon(self.expand, self.is_expanded);
	
	if self.is_expanded then
		self.children.Visible = has_children;
	else
		self.children.Visible = false;
	end
	
	if has_children then
		self.expand.Visible = true;
	else
		self.expand.Visible = false;
		self.children.Visible = false;
	end
	
	self.liner.Visible = true;
end

function ExplorerFrame:expand_children(dont_show: boolean?)
	if not self.is_expanded then
		self:set_expanded(true);
		
		if not dont_show then
			for child, frame in self.instance_children do
				frame:show()
			end;
		end;
	end;
end

function ExplorerFrame:unexpand_children()
	if self.is_expanded then
		self:set_expanded(false);
		
		for child, frame in self.instance_children do
			frame:hide()
		end;
	end;
end

function ExplorerFrame:get_ancestry_shown()
	local current_frame = self;
	
	while current_frame do
		if not current_frame.frame or not current_frame.frame.Parent then
			return false;
		end;
		
		current_frame = self.explorer.items[current_frame.parent];
	end
	
	return true;
end

function ExplorerFrame:unghost()
	self:update_frame();
	
	self.ghosted = false;
	self.frame.Body.Visible = true;
	
	self:update_expand_depth(self.build_tools.preferences:get("explorer_expand_pixel_scale"));
	self:expand_children();
	self:update_expandable();
end

function ExplorerFrame:ghost()
	self:update_frame();
	
	self.ghosted = true;
	self.frame.Body.Visible = false;
	
	self:update_expand_depth(0);
	self:expand_children();
	self:update_expandable();
end

function ExplorerFrame:is_visible()
	return if self.frame then self.frame.Parent ~= nil else false;
end

function ExplorerFrame:hide()
	if not self.frame then return end;
	
	self._searched = nil;
	--self.frame.Visible = false;
	self.frame.Parent = nil;
	self:update_expandable();
end

function ExplorerFrame:show()
	--if self.frame and self.frame.Visible then return end 
	if self.frame and self.frame.Parent then return end;
	
	self:update_frame();
	--self.frame.Visible = true;
	self:reparent();
	self:update_expandable();
end

function ExplorerFrame:get_ancestry()
	local ancestor = self.explorer.items[self.parent];
	local list = {};
	
	while ancestor ~= nil do
		table.insert(list, ancestor);
		ancestor = self.explorer.items[ancestor.parent]
	end;
	
	return list;
end

function ExplorerFrame:show_with_ancestry(dont_show: boolean?)
	debug.profilebegin("Show Ancestry");
	
	local to_expand = self:get_ancestry();
	
	for index = #to_expand, 1, -1 do
		local frame = to_expand[index];
		frame:show();
		frame:expand_children(dont_show);
	end
	
	self:show();
	
	debug.profileend();
end

function ExplorerFrame:update_modifier_count()
	if not self.frame then return end;
	
	if self.modifier_count > 0 then
		self.label.TextColor3 = Color3.fromRGB(255, 236, 90);
	else
		self.label.TextColor3 = Color3.fromRGB(255, 255, 255);
	end
end

function ExplorerFrame:child_added(child: Instance)
	if string.sub(child.Name, 1, 1) == "@" then 
		self.modifier_count += 1;
		self:update_modifier_count();
	end;
	
	if not ExplorerFrame.can_be_shown(child) then return end;
	
	local frame = self.explorer:get(child, self.instance);
	
	if not self.instance_children[child] then
		self.instance_children[child] = frame;
	end
	
	local was_expanded = self.is_expanded;
	
	if was_expanded then
		frame:show();
		
	elseif frame.parent == self.instance then
		frame:hide();
	end;
	
	self:update_expandable();
	
	if self:has_children() and was_expanded then
		return self:expand_children()
	end;
	
	self:unexpand_children()
end

function ExplorerFrame:child_removed(child: Instance)
	if string.sub(child.Name, 1, 1) == "@" then 
		self.modifier_count -= 1;
		self:update_modifier_count();
	end;
	
	if not ExplorerFrame.can_be_shown(child) then return end;
	
	if self.instance_children[child] then
		if self.instance_children[child].parent == self.instance then
			self.instance_children[child]:hide();
		end;
		
		self.instance_children[child] = nil;
	end
	
	self:update_expandable();
end

function ExplorerFrame:has_children()
	return next(self.instance_children) ~= nil;
end

function ExplorerFrame:update_highlight()
	if not self.frame then return end;
	
	local background_transparency: number;
	local background_color: Color3;
	
	if self.is_hovering then
		background_transparency = 0.5;
		
		if self.is_selected then
			background_color = FrameSelectedHoverColor;
		else
			background_color = FrameHoverColor;
		end
	else
		if self.is_selected then
			background_color = FrameSelectedColor;
			background_transparency = 0.5;
		else
			background_color = FrameDefaultColor;
			background_transparency = 1;
		end
	end;
	
	if background_transparency then
		self.select.BackgroundTransparency = background_transparency;
	end
	
	if background_color then
		self.select.BackgroundColor3 = background_color;
	end
end

function ExplorerFrame:destroy()
	local parent_frame = self.explorer.items[self.parent];

	if parent_frame then
		parent_frame:child_removed(self.instance);
	end;
	
	self.explorer:remove(self.instance);
	
	if self.frame then
		self.explorer.cache:release(self.frame);
		self.frame = nil;
	end;
	
	self.maid:destroy();
end

function ExplorerFrame:set_parent(parent: Instance?)
	if self.parent ~= parent then
		local parent_frame = self.explorer.items[self.parent];

		if parent_frame then
			parent_frame:child_removed(self.instance);
		end;

		self.parent = parent;
	end;
end

function ExplorerFrame:reparent()
	if not self.frame then return end;
	
	local parent_frame = self.explorer.items[self.parent];
	local new_parent;
	
	if parent_frame then
		new_parent = parent_frame.children;
	else
		new_parent = self.build_tools.elements.ExplorerFraming;
	end;
	
	if self.frame.Parent ~= new_parent then
		self.frame.Parent = new_parent;
		
	--	local position = self.frame.Body.AbsolutePosition - ExplorerFraming.AbsolutePosition;
		local position = Vector2.new(196, 0);
		
		self.select.Size = UDim2.new(1, position.X * 2, 1, 0);
		self.select.Position = UDim2.fromOffset(-position.X, 0);
	end
end

function ExplorerFrame:get_children()
	local children = self.instance:GetChildren();
	
	-- Not needed anymore with the BTools no longer reparenting
	--[[
	for selected, info in self.build_tools.selection.items do
		if info.parent == self.instance then
			table.insert(children, selected);
		end;
	end;
	--]]
	
	return children;
end

function ExplorerFrame:capture_click()
	if Stylus:has_active_instance_box() then
		Stylus:give_instance(self.instance);
	else
		if not self.build_tools:is_control_down() then
			local selected = self.build_tools.selection:is_selected(self.instance)
			local count = self.build_tools.selection.count;
			
			self.build_tools.selection:deselect();
			
			if not selected or count >= 2 then
				self.build_tools.selection:select_instance(self.instance);
			end
		else
			self.build_tools.selection:click_select_instance(self.instance);
		end;
	end
end

function ExplorerFrame:capture_right_click()
	for instance in self.build_tools.selection.items do
		self.build_tools.actions:modify(instance, {Parent = self.instance})
	end;
end

function ExplorerFrame:capture_expand_click()
	if not self.is_expanded and self:has_children() then
		self:expand_children()

	elseif self.is_expanded then
		self:unexpand_children()
	end
end

-- Creates the frame on demand (so no major lagspikes when selecting many instances)
function ExplorerFrame:update_frame()
	if self.frame then return; end;
	if not ExplorerFrame.can_be_shown(self.instance) then return end;
	
	self.frame = self.explorer.cache:get();
	self.children = self.frame.Children;
	self.label = self.frame.Body.List.Label;
	self.select = self.frame.Body.Select;
	self.expand = self.frame.Body.List.Expand.Button;
	self.icon = self.frame.Body.List.Icon;
	self.liner = self.frame.Body.ExpandLine;
	
	self:update_scale( self.build_tools.preferences:get("explorer_instance_pixel_scale") );
	self:update_spacing( self.build_tools.preferences:get("explorer_spacing_pixel_scale") );
	self:update_expand_depth( self.build_tools.preferences:get("explorer_expand_pixel_scale") )
	
	self.frame.Name = "Frame";
	self.expand.Visible = true;
	self.children.Visible = false;
	self.frame.Visible = true;
	
	self.is_selected = self.build_tools.selection.items[self.instance] ~= nil;
	self.is_hovering = false;
	
	self:update_modifier_count();
	self:update_highlight();
	
	Stylus:set_sprite_icon(self.icon, self.instance:GetAttribute("PsuedoClassName") or self.instance.ClassName);
	Stylus:set_expand_icon(self.expand, false);
	
	self.label.Text = self.instance.Name;
	
	self.maid:add(self.children:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self.liner.Size = UDim2.new(0, 1, 0, self.children.AbsoluteSize.Y);
	end))
	
	self.maid:add(self.instance:GetPropertyChangedSignal("Name"):Connect(function()
		self.label.Text = self.instance.Name;
	end))
	
	self.maid:add(self.select.MouseEnter:Connect(function()
		self.is_hovering = true;
		self:update_highlight();
	end))
	
	self.maid:add(self.select.MouseLeave:Connect(function()
		self.is_hovering = false;
		self:update_highlight();
	end))
	
	--self.maid:add(self.select.MouseButton1Down:Connect(function()
	--	if HelpInput.UsingKeyboard then
	--		self:capture_multi_selection()
	--	end;
	--end))
	
	--self.maid:add(self.select.TouchLongPress:Connect(function()
	--	self:capture_multi_selection();
	--end))
	
	self.maid:add(self.select.MouseButton1Click:Connect(function()
		self:capture_click();
	end))
	
	self.maid:add(self.select.MouseButton2Click:Connect(function()
		self:capture_right_click();
	end));
	
	self.maid:add(self.expand.MouseButton1Click:Connect(function()
		self:capture_expand_click();
	end))
end

function ExplorerFrame:init()
	self.explorer.items[self.instance] = self;
	
	for _, child in self:get_children() do
		self:child_added(child);
	end
	
	self.maid:add(self.instance.ChildAdded:Connect(function(child)
		self:child_added(child);
	end));

	self.maid:add(self.instance.ChildRemoved:Connect(function(child)
		if child.Parent ~= self.instance and not self.build_tools.selection:is_selectable(child) then
			self:child_removed(child);
		end;
	end));
end

function ExplorerFrame.new(explorer, instance: Instance, parent: Instance?)
	local self = setmetatable(
		{
			parent = parent or instance.Parent;
			
			explorer = explorer;
			build_tools = explorer.build_tools;
			instance = instance;

			instance_children = {};

			modifier_count = 0;
			is_expanded = false;
			maid = nil;
		}, 
		ExplorerFrame);
	
	self.maid = Maid.removing(instance, function()
		self:destroy();
	end)
	
	self:init();
	
	return self;
end

table.freeze(ExplorerFrame);

return ExplorerFrame;