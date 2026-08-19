local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer;
local BuildPersistent = ReplicatedStorage:WaitForChild("BuildTools");
local BuildShared = BuildPersistent:WaitForChild("Shared");
local Remotes = BuildPersistent:WaitForChild("Remotes");
local BuildAssets = BuildShared:WaitForChild("Assets");
local InstancesBuild = BuildAssets:WaitForChild("Build");

local NotificationStatus = require( BuildShared.Data.NotificationStatus )
local Searcher = require( script.Parent.UI.Searcher );
local Maid = require( ReplicatedStorage.Packages.Maid )
local Table = require( ReplicatedStorage.Packages.Table )
local Stylus = require( ReplicatedStorage.Packages.Stylus )

local ToolWidget = {};
ToolWidget.__index = ToolWidget;

function ToolWidget.new(build_tools)
	local maid = build_tools.maid:limb();
	
	local self = setmetatable(
		{
			maid = maid;
			build_tools = build_tools;
			enabled = false;
			current_tab = nil;
			
			top_ribbon = build_tools.elements.Top.Ribbon.Top;
			bottom_ribbon = build_tools.elements.Top.Ribbon.Bottom.ScrollingFrame;
			top_widgets = {};
		}, 
		ToolWidget);
	
	self:initialise();
	
	return self;
end;

function ToolWidget:destroy()
	Table.dispose(self);
end

function ToolWidget:add_widget_button(widget, properties)
	local asset = self.build_tools.assets:FindFirstChild(properties.asset or "RibbonItem");
	local button = asset:Clone()
	
	if properties.image then
		button.Button.Icon.Image = properties.image;
		
	elseif properties.ribbon_image then
		Stylus:set_ribbon_icon(button.Button.Icon, properties.ribbon_image);
	end;
	
	if properties.image_color then
		button.Button.Icon.ImageColor3 = properties.image_color;
	end;
	
	if (asset.Name == "RibbonItem") then
		button.Button:AddTag("UI-ButtonClick");
	end;
	
	button.Parent = widget.frame.Items;
	
	table.insert(widget.buttons, button);
	
	if properties.clicked then
		button.Button.MouseButton1Click:Connect(function()
			properties.clicked(button, widget);
		end)
	end
	
	if properties.init then
		properties.init(button, widget);
	end
	
	return button;
end

function ToolWidget:add_widget(tab_name: string, properties)
	local widget = self.top_widgets[tab_name];
	
	if not widget then return end;
	
	local button = self.build_tools.assets.RibbonTab:Clone();
	--button.Default.Image = properties.image or button.Default.Image;
	button.Title.Text = properties.title;
	button.Visible = false;
	button.LayoutOrder = #widget.widgets;
	button.Parent = self.bottom_ribbon
	
	do
		local function update_text_bounds()
			button.Title.TextSize = button.Title.AbsoluteSize.Y * 1;
		end
		
		task.defer(update_text_bounds);
		button.Title:GetPropertyChangedSignal("AbsoluteSize"):Connect(update_text_bounds);
	end
	
	local widget_info = {
		frame = button;
		buttons = {};
	};
	
	table.insert(widget.widgets, widget_info);
	
	if properties.buttons then
		for name, info in properties.buttons do
			self:add_widget_button(widget_info, info)
		end
	end
	
	return button;
end

function ToolWidget:add_widget_seperator(tab_name: string, properties)
	local widget = self.top_widgets[tab_name];

	if not widget then return end;

	local frame = self.build_tools.assets.RibbonSeperator:Clone();
	frame.LayoutOrder = #widget.widgets;
	frame.Visible = false;
	frame.Parent = self.bottom_ribbon;
	
	local widget_info = {
		frame = frame;
		seperator = true,
		buttons = {};
	};
	
	table.insert(widget.widgets, widget_info);
	
	return frame;
end

function ToolWidget:create_tab(tab_name: string, properties)
	assert(not self.top_widgets[tab_name], "Tab already exists");
	
	if not properties then properties = {} end;
	
	local widget = self.build_tools.assets.TopBarTab:Clone();
	widget.Name = tab_name;
	widget.Button.Text = tab_name;
	widget.Parent = self.top_ribbon;
	
	widget.Button:AddTag("UI-ButtonClick");
	
	widget.Button.MouseButton1Click:Connect(function()
		self:set_tab(tab_name);
	end)
	
	self.top_widgets[tab_name] = {
		frame = widget;
		widgets = {};
	}
	
	if properties.widgets then
		for name, button in properties.widgets do
			if button.seperator then
				self:add_widget_seperator(tab_name, button)
			else
				self:add_widget(tab_name, button);
			end
		end
	end
	
	return widget;
end

function ToolWidget:create_tabular_button(name: string, side: Enum.NormalId, properties)
	local widget = self.build_tools.assets.TopTabButton:Clone();
	widget.Name = name;
	--widget.Button.Text = name;
	widget.Parent = self.top_ribbon[side.Name];
	
	if properties.image then
		widget.Icon.Image = properties.image;
	end;
	
	if properties.ribbon_image then
		Stylus:set_ribbon_icon(widget.Icon, properties.ribbon_image);
	end;
	
	if properties.clicked then
		widget.Button.MouseButton1Click:Connect(function()
			properties.clicked(widget);
		end)
	end
	
	return widget;
end

function ToolWidget:set_tab(tab_name: string)
	local tab = self.top_widgets[tab_name];
	
	if not tab then return end;
	
	local current_tab = self.current_tab;
	
	if (current_tab ~= tab_name) then
		self.current_tab = tab_name;
		
		local last_tab = self.top_widgets[current_tab];
		
		if last_tab then
			for _, widget in last_tab.widgets do
				widget.frame.Visible = false;
			end;
		end;
		
		for _, widget in tab.widgets do
			widget.frame.Visible = true;
		end;
		
		task.defer(self.update_top_ribbon_size, self);
	end	
end

function ToolWidget:update_top_ribbon_size()
	local window_size = workspace.CurrentCamera.ViewportSize.X;
	local max_ballon_size = window_size / 4;
	
	if self.bottom_ribbon.AbsoluteCanvasSize.X > max_ballon_size then
		self.bottom_ribbon.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left;
	else
		self.bottom_ribbon.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
	end;

	self.bottom_ribbon.Size = UDim2.new(0, max_ballon_size, 1, 0);
end

function ToolWidget:initialise()
	
	self.bottom_ribbon:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
		self:update_top_ribbon_size();
	end);
	
	task.defer(self.update_top_ribbon_size, self);
	
	self:create_tabular_button("Undo", Enum.NormalId.Left, {
		ribbon_image = "back";
		clicked = function(item, widget)
			self.build_tools.actions:undo();
		end,
	})
	self:create_tabular_button("Redo", Enum.NormalId.Left, {
		ribbon_image = "fwd";
		clicked = function(item, widget)
			self.build_tools.actions:redo();
		end,
	})
	
	self:create_tabular_button("Copy", Enum.NormalId.Right, {
		image = "rbxassetid://96265482350413";
		clicked = function(item, widget)
			self.build_tools:copy();
		end,
	})
	self:create_tabular_button("Paste", Enum.NormalId.Right, {
		image = "rbxassetid://17109896197";
		clicked = function(item, widget)
			self.build_tools:paste();
		end,
	})
	self:create_tabular_button("AlterMode", Enum.NormalId.Right, {
		image = "rbxassetid://12684121161";
		clicked = function(item, widget)
			self.build_tools:cycle_alter_mode(1);
		end,
	})
	
	self:create_tab("Home", {
		widgets = {
			{
				title = "Select";
				buttons = {
					{
						ribbon_image = "select",
						init = function(item, widget)
							item.Button.MouseButton1Click:Connect(function()
								self.build_tools:set_tool_mode(Enum.RibbonTool.Select);
							end)
						end,
					}
				};
			};
			{
				title = "Move";
				buttons = {
					{
						ribbon_image = "move",
						init = function(item, widget)
							item.Button.MouseButton1Click:Connect(function()
								self.build_tools:set_tool_mode(Enum.RibbonTool.Move);
							end)
						end,
					}
				};
			};
			{
				title = "Scale";
				buttons = {
					{
						ribbon_image = "scale",
						init = function(item, widget)
							item.Button.MouseButton1Click:Connect(function()
								self.build_tools:set_tool_mode(Enum.RibbonTool.Scale);
							end)
						end,
					}
				};
			};
			{
				title = "Rotate";
				buttons = {
					{
						ribbon_image = "rotate",
						init = function(item, widget)
							item.Button.MouseButton1Click:Connect(function()
								self.build_tools:set_tool_mode(Enum.RibbonTool.Rotate);
							end)
						end,
					}
				};
			};
			{
				seperator = true;
			},
			{
				title = "Geometric";
				buttons = {
					{
						asset = "RibbonScaling",
						init = function(item, widget)
							item.Move.Value.Text = "-";
							item.Rotate.Value.Text = "-";
							
							self.maid:add(item.Move.Value.FocusLost:Connect(function()
								self.build_tools.draggers:set_move_increment(item.Move.Value.Text);
							end))

							self.maid:add(item.Rotate.Value.FocusLost:Connect(function()
								self.build_tools.draggers:set_rotate_increment(item.Rotate.Value.Text);
							end))
							
							self.maid:add(item.Move.Check.MouseButton1Click:Connect(function()
								self.build_tools.draggers:toggle_move_increment();
							end))

							self.maid:add(item.Rotate.Check.MouseButton1Click:Connect(function()
								self.build_tools.draggers:toggle_rotate_increment();
							end))
							
							
							self.maid:add(self.build_tools.preferences:observe("move_increment", function(value)
								item.Move.Value.Text = tostring(value);
							end))
							
							self.maid:add(self.build_tools.preferences:observe("rotate_increment", function(value)
								item.Rotate.Value.Text = tostring(math.deg(value));
							end))
							
							self.maid:add(self.build_tools.preferences:observe("move_increment_enabled", function(value)
								Stylus:set_checkbox_icon(item.Move.Check, value);
							end))
							
							self.maid:add(self.build_tools.preferences:observe("rotate_increment_enabled", function(value)
								Stylus:set_checkbox_icon(item.Rotate.Check, value);
							end))
						end,
					}
				};
			};
			{
				seperator = true;
			},
			{
				title = "Move Space";
				buttons = {
					{
						ribbon_image = "geometric";
						
						init = function(item, widget, tab)
							local function set_locality()
								if self.build_tools.draggers.local_space then
									item.Button.Icon.ImageColor3 = Color3.fromRGB(29, 146, 255);
									widget.frame.Title.Text = "Local";
								else
									item.Button.Icon.ImageColor3 = Color3.fromRGB(59, 255, 29);
									widget.frame.Title.Text = "Global";
								end
							end

							self.maid:add(item.Button.MouseButton1Click:Connect(function()
								self.build_tools.draggers:set_local_space()
							end))

							self.maid:add(self.build_tools.draggers.locality_changed:Connect(set_locality))
							set_locality();
						end,
					}
				};
			};
			{
				title = "Part Align";
				
				buttons = {
					{
						ribbon_image = "physical";
						image_color = Color3.fromRGB(172, 117, 255);
						
						clicked = function(item, widget)
							self.build_tools.draggers:set_world_aligned();
							
							if self.build_tools.draggers.world_aligned then
								self.build_tools.draggers:set_alignment_mode("Pivot");
								
								item.Button.Icon.ImageColor3 = Color3.fromRGB(255, 255, 255);
								widget.frame.Title.Text = "World Align";
							else
								self.build_tools.draggers:set_alignment_mode("FacePivot");
								
								item.Button.Icon.ImageColor3 = Color3.fromRGB(172, 117, 255);
								widget.frame.Title.Text = "Part Align";
							end
						end,
					}
				};
			};
		};
	});
	
	self:create_tab("Model", {
		widgets = {
			{
				title = "Parts";
				buttons = {
					{
						ribbon_image = "part",
						clicked = function(item, widget)
							self.build_tools.actions:spawn("Part");
						end,
					},
					{
						ribbon_image = "part_sphere",
						clicked = function(item, widget)
							self.build_tools.actions:spawn("Sphere");
						end,
					},
					{
						ribbon_image = "part_cylinder",
						clicked = function(item, widget)
							self.build_tools.actions:spawn("Cylinder");
						end,
					};
					{
						ribbon_image = "part_wedge",
						clicked = function(item, widget)
							self.build_tools.actions:spawn("Wedge");
						end,
					};
				};
			};
			{
				seperator = true;
			},
			{
				title = "Weld To Last";
				buttons = {
					{
						ribbon_image = "weldconstraint",
						clicked = function(item, widget)
							self.build_tools.actions:weld_all(self.build_tools.selection:get_ordered());
						end,
					},
				};
			};
			{
				title = "Break Welds";
				buttons = {
					{
						ribbon_image = "effect_explosion",
						clicked = function(item, widget)
							self.build_tools.actions:break_welds(self.build_tools.selection:get());
						end,
					},
				};
			};
			{
				seperator = true;
			},
			{
				title = "Group";
				buttons = {
					{
						ribbon_image = "group",
						clicked = function(item, widget)
							self.build_tools.actions:group(self.build_tools.selection:get());
						end,
					},
				};
			};
			{
				title = "Ungroup";
				buttons = {
					{
						ribbon_image = "group",
						image_color = Color3.fromRGB(255, 165, 165);
						clicked = function(item, widget)
							self.build_tools.actions:ungroup(self.build_tools.selection:get());
						end,
					},
				};
			};
			{
				seperator = true;
			},
			{
				title = "Anchor";
				buttons = {
					{
						ribbon_image = "anchor",
						image_color = Color3.fromRGB(60, 219, 255);
						clicked = function(item, widget)
							self.build_tools.actions:anchor(self.build_tools.selection:get(), true);
						end,
					},
				};
			};
			{
				title = "Unanchor";
				buttons = {
					{
						ribbon_image = "anchor",
						image_color = Color3.fromRGB(255, 114, 89);
						clicked = function(item, widget)
							self.build_tools.actions:anchor(self.build_tools.selection:get(), false);
						end,
					},
				};
			};
			{
				seperator = true;
			},
			{
				title = "Clone";
				buttons = {
					{
						ribbon_image = "group",
						image_color = Color3.fromRGB(147, 255, 219);
						clicked = function(item, widget)
							self.build_tools.actions:clone(self.build_tools.selection:get());
						end,
					},
				};
			};
		};
	});
	self:create_tab("Wizards", {
		widgets = {
			{
				title = "Voxel Breaker";
				buttons = {
					{
						ribbon_image = "terrain",
						clicked = function(item, widget)
							if not self.build_tools.wizards:is_currently("VoxelBreaker") then
								self.build_tools.wizards:set("VoxelBreaker")
							else
								self.build_tools.wizards:set(nil);
							end
						end,
					},
				};
			};
			{
				seperator = true;
			},
			{
				title = "Gap Fill";
				buttons = {
					{
						ribbon_image = "alignposition",
						clicked = function(item, widget)
							if self.build_tools.tool_mode == Enum.RibbonTool.Transform then
								self.build_tools:set_tool_mode(Enum.RibbonTool.Select);
							else
								self.build_tools:set_tool_mode(Enum.RibbonTool.Transform);
							end
						end,
					},
				};
			};
			{
				seperator = true;
			},
			{
				title = "Mesh Maker";
				buttons = {
					{
						ribbon_image = "transform",
						clicked = function(item, widget)
							if not self.build_tools.wizards:is_currently("CreateMesh") then
								self.build_tools.wizards:set("CreateMesh")
							else
								self.build_tools.wizards:set(nil);
							end
						end,
					},
				};
			};
			{
				seperator = true;
			},
			{
				title = "Text Writer";
				buttons = {
					{
						ribbon_image = "uitextsizeconstraint",
						clicked = function(item, widget)
							if not self.build_tools.wizards:is_currently("TextWriter") then
								self.build_tools.wizards:set("TextWriter")
							else
								self.build_tools.wizards:set(nil);
							end
						end,
					},
				};
			};
			{
				seperator = true;
			},
			{
				title = "Import Export";
				buttons = {
					{
						ribbon_image = "analysis",
						clicked = function(item, widget)
							if not self.build_tools.wizards:is_currently("ImportExport") then
								self.build_tools.wizards:set("ImportExport")
							else
								self.build_tools.wizards:set(nil);
							end
						end,
					},
				};
			};
			{
				seperator = true;
			};
			{
				title = "Variables";
				buttons = {
					{
						ribbon_image = "formatdocument",
						clicked = function(item, widget)
							if not self.build_tools.wizards:is_currently("Variables") then
								self.build_tools.wizards:set("Variables")
							else
								self.build_tools.wizards:set(nil);
							end
						end,
					},
				};
			};
			{
				seperator = true;
			},
			{
				title = "Skill Builder";
				buttons = {
					{
						ribbon_image = "animation",
						clicked = function(item, widget)
							if not self.build_tools.wizards:is_currently("SkillBuilder") then
								self.build_tools.wizards:set("SkillBuilder")
							else
								self.build_tools.wizards:set(nil);
							end
						end,
					},
				};
			};
			
		};
	});
	
	self:set_tab("Home");
end

table.freeze(ToolWidget);

return ToolWidget;