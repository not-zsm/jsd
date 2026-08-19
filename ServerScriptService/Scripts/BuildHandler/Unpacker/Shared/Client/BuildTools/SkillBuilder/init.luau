local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-----------------------------------------------------------------------------------------------------------

local BuildPersistent = ReplicatedStorage:WaitForChild("BuildTools");
local BuildShared = BuildPersistent:WaitForChild("Shared");

local Remotes = BuildPersistent.Remotes;

local Signal = require( ReplicatedStorage.Packages.Signal )
local Maid = require( ReplicatedStorage.Packages.Maid )
local Math = require( ReplicatedStorage.Packages.Math )
local Type = require( ReplicatedStorage.Packages.Type )
local Stylus = require( ReplicatedStorage.Packages.Stylus )
local HelpInput = require( ReplicatedStorage.Packages.HelpInput )
local Asset = require( ReplicatedStorage.Packages.Asset )
local PageList = require( ReplicatedStorage.Packages.PageList )
local StreamService = require( ReplicatedStorage.Packages.StreamService )
local Instances = require( ReplicatedStorage.Packages.Instances )
local Build = require( BuildPersistent.Build );

local HuePicker = require( "./UI/HuePicker" );
local ValueList = require( "./ValueList" );
local HelperWidget = require( "./UI/HelperWidget" );

local Retrieval = require( script.Retrieve );
local ValueViewer = require( script.Viewers.ValueViewer );
local AnimationViewer = require( script.Viewers.AnimationViewer );

local BaseBlock = require( script.BaseBlock );
local Branch = require( script.Branch )

-----------------------------------------------------------------------------------------------------------

local SkillBuilder = {};
SkillBuilder.__index = SkillBuilder;

function SkillBuilder.new(build_tools)
	local maid = Maid.new();

	local self = setmetatable(
		{
			build_tools = build_tools;
			ui = build_tools.ui.SkillBuilder;
			body = build_tools.ui.SkillBuilder.Body.Builder.Body;
			import_body = build_tools.ui.SkillBuilder.Import.Builder.Body;
			hues_body = build_tools.ui.SkillBuilder.Hues.Builder.Body;
			loading = build_tools.ui.SkillBuilder.Body.Builder.Loading;
			panel_pages = build_tools.ui.SkillBuilder.Body.Builder.Body.Body.Pages;
			build_page = build_tools.ui.SkillBuilder.Body.Builder.Body.Body.Pages.BuildPage,
			build_items = build_tools.ui.SkillBuilder.Body.Builder.Body.Body.Pages.BuildPage.Items;
			overview_page = build_tools.ui.SkillBuilder.Body.Builder.Body.Body.Pages.OverviewPage;
			overview_panel =  build_tools.ui.SkillBuilder.Body.Builder.Body.Body.Pages.OverviewPage.Panel;
			timeline_panel = build_tools.ui.SkillBuilder.Body.Builder.Body.Body.Pages.BuildPage.Items.Timeline.Panel;
			edit_block_frame = build_tools.ui.SkillBuilder.Body.Builder.Body.Body.Pages.BuildPage.Items.Timeline.Panel.EditBlock;
			add_block_frame = build_tools.ui.SkillBuilder.Body.Builder.Body.Body.Pages.BuildPage.Items.Timeline.Panel.AddBlock;
			assets = build_tools.assets;

			hues_enabled = false;
			import_enabled = false;
			enabled = false;
			active = false;
			show_deprecated = false;
			
			slots = {};
			branches = {};
			skill_properties = {};
			branch_properties = {};
			tweens = {};
			
			on_apply = maid:add(Signal.new());
			on_cancel = maid:add(Signal.new());
			closed = maid:add(Signal.new());
			opened = maid:add(Signal.new());

			maid = maid;
			import_maid = maid:limb();
			hues_maid = maid:limb();
			loading_maid = maid:limb();
			active_loading = 0;
			is_loading = false;
			active_transparent = 0,
			edit_changes = 0;
			
			stream = Build.skills_stream;
		}, 
		SkillBuilder)

	self:initialise();

	return self;
end

function SkillBuilder:destroy()
	self.maid:destroy();
end

function SkillBuilder:initialise()
	local picker_frame = self.build_tools.assets.HuePicker:Clone();
	picker_frame.Visible = true;
	picker_frame.AnchorPoint = Vector2.new(0.5, 0.5);
	picker_frame.Position = UDim2.fromScale(0.5, 0.5);
	picker_frame.Parent = self.hues_body.Body.Picker;
	
	self.block_help = HelperWidget.new(self.build_tools);
	self.block_help:set_done_visible(false);
	self.block_help:toggle(false);
	self.block_help.title.Text = "Help";
	self.block_help.frame.UIAspectRatioConstraint.AspectRatio = 1.2;
	self.block_help.frame.Parent = self.ui;
	
	self.block_help.closed:Connect(function()
		if self.enabled then
			self.tweens.open:Play();
		end;
	end)
	
	self.hue_picker = HuePicker.new(self.build_tools, picker_frame, false);
	self.hue_picker:toggle(false);
	
	self.hue_picker.opened:Connect(function()
		self:show_color_picker();
	end)
	
	self.hue_picker.closed:Connect(function()
		self:hide_color_picker();
	end)
	
	self.value_list = ValueList.new(self.build_tools, true);
	self.value_list.widget:set_done_visible(false);
	self.value_list.widget.frame.Parent = self.ui;
	
	self.value_list.on_selected:Connect(function(value)
		if self.value_list.affector_instance then
			self.value_list.affector_instance:set_value( value );
			self.value_list:toggle(false);
		end;
	end);
	
	self.value_list.widget.closed:Connect(function()
		self.value_list.affector_instance = nil;
		self.tweens.open:Play();
	end)
	
	Stylus:set_ribbon_icon(self.build_tools.elements.LinkButtons.SkillBuilder.Icon, "animation");
	
	self.build_tools.elements.LinkButtons.SkillBuilder.MouseButton1Click:Connect(function()
		self:toggle();
	end)
	
	do
		self.tweens.hues_open = TweenService:Create(self.ui.Hues.Builder, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {GroupTransparency = 0, AnchorPoint = Vector2.new(0.5, 0.5)});
		self.tweens.hues_close = TweenService:Create(self.ui.Hues.Builder, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {GroupTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.4)});
		self.tweens.import_open = TweenService:Create(self.ui.Import.Builder, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {GroupTransparency = 0, AnchorPoint = Vector2.new(0.5, 0.5)});
		self.tweens.import_close = TweenService:Create(self.ui.Import.Builder, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {GroupTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.4)});
		self.tweens.open = TweenService:Create(self.ui.Body.Builder, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {GroupTransparency = 0, AnchorPoint = Vector2.new(0.5, 0.5)});
		self.tweens.close = TweenService:Create(self.ui.Body.Builder, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {GroupTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.4)});
		self.tweens.ghost = TweenService:Create(self.ui.Body.Builder, TweenInfo.new(0.2, Enum.EasingStyle.Cubic), {GroupTransparency = 0.925}) --, AnchorPoint = Vector2.new(0.5, 0.48)});
		self.tweens.transparent = TweenService:Create(self.ui.Body.Builder, TweenInfo.new(0.1, Enum.EasingStyle.Cubic), {GroupTransparency = 0.5});
		
		self.tweens.close:Play();
		self.tweens.import_close:Play();
		self.tweens.hues_close:Play();
		
		self.tweens.hues_close.Completed:Connect(function(status)
			if (status == Enum.PlaybackState.Completed) then
				self.ui.Hues.Visible = false;
			end
		end)
		
		self.tweens.import_close.Completed:Connect(function(status)
			if (status == Enum.PlaybackState.Completed) then
				self.ui.Import.Visible = false;
			end
		end)

		self.tweens.close.Completed:Connect(function(status)
			if (status == Enum.PlaybackState.Completed) then
				self.ui.Enabled = false;
			end
		end)
	end

	self.body.Title.Close.MouseButton1Click:Connect(function()
		self:toggle(false);
	end)

	self.body.MouseEnter:Connect(function()
		self.active = true;
	end)

	self.body.MouseLeave:Connect(function()
		self.active = false;
	end)

	self.body.Body.Side.Overview.Button.MouseButton1Click:Connect(function()
		self.panel_pages.UIPageLayout:JumpTo( self.panel_pages.OverviewPage )
	end)

	self.body.Body.Side.Create.Button.MouseButton1Click:Connect(function()
		if not self.editing_slot then
			return self.build_tools:notify(2, `No skill is currently being edited`);
		end;

		self.panel_pages.UIPageLayout:JumpTo( self.panel_pages.BuildPage )
	end)

	self.body.Body.Side.Help.Button.MouseButton1Click:Connect(function()
		self.panel_pages.UIPageLayout:JumpTo( self.panel_pages.HelpPage )
	end);

	self.build_page.Categories.Properties.Button.MouseButton1Click:Connect(function()
		self:set_data_page( "Properties" );
	end)

	self.build_page.Categories.Branch.Button.MouseButton1Click:Connect(function()
		self:set_data_page( "Branch" );
	end)
	
	self.build_page.Categories.Timeline.Button.MouseButton1Click:Connect(function()
		self:set_data_page( "Timeline" );
	end);

	self.overview_page.Timeline.Workspace.Import.Button.MouseButton1Click:Connect(function()
		if self.import_enabled then
			return self:hide_import();
		end;

		self:prompt_import( {
			text = "";
			box_title = "Data goes here",
			button_tip = "Import",
			button_color = Color3.fromRGB(122, 255, 120),
			can_edit = true;
			callback = function(proceed, value)
				if proceed then
					local slot = Remotes.Skills.ImportSkill:InvokeServer(value);
					
					if slot then
						task.wait(0.2); -- 🥀
						
						self.build_tools:notify(3, `Successfully imported skill`);
						self:select_slot(slot);
					end;
				end;
			end,
		} )
	end)
	
	self.add_block_frame.Deprecated.Button.MouseButton1Click:Connect(function()
		self:toggle_deprecated();
	end)
	
	self.edit_block_frame.Info.Button.MouseButton1Click:Connect(function()
		if not self.selected_skill_block or not self.enabled then
			return;
		end;
		
		self.block_help.title.Text = self.selected_skill_block.name;
		self.tweens.ghost:Play();
		
		self.block_help:set_description( self.selected_skill_block.block_data.HelpDescription or "No description is available for this block" );
		self.block_help:toggle(true);
	end);
	
	self.overview_page.Timeline.Workspace.Create.Button.MouseButton1Click:Connect(function()
		local slot = #self.slots + 1;
		local data = {
			EditTime = DateTime.now().UnixTimestamp,
			Properties = {SkillName = { Value = "Unnamed Skill" }} 
		};
		
		Remotes.Skills.CreateSkill:FireServer(slot, data);

		--self:create_slot(slot, data);
		--self:select_slot(slot);
	end)

	self.overview_panel.ActionsFrame.Export.Button.MouseButton1Click:Connect(function()
		local export_data = Remotes.Skills.ExportSkill:InvokeServer( self.selected_slot );

		if typeof(export_data) == "string" then
			self:hide_import();

			self:prompt_import({
				text = export_data;
				box_title = "Export data goes here",
				button_tip = "I have copied the text 👍",
				button_color = Color3.fromRGB(66, 195, 255),
				can_edit = false;
				callback = function(proceed, value)
					
				end,
			})
		end
	end)

	self.overview_panel.ActionsFrame.Obtain.Button.MouseButton1Click:Connect(function()
		if self:has_unsaved_changes() and self.editing_slot == self.selected_slot then
			self:confirm("Unsaved Changes", "You have yet to save this skill, do you still wish to obtain the last version?", function(accepted)
				if accepted then
					Remotes.Skills.ObtainSkill:FireServer( self.selected_slot );
				end;
			end);
		else
			Remotes.Skills.ObtainSkill:FireServer( self.selected_slot );
		end;
	end)

	self.overview_panel.ActionsFrame.Delete.Button.MouseButton1Click:Connect(function()
		self:confirm("Delete Skill", "Are you sure you want to delete this skill <b>permenantly</b>?", function(accepted)
			if accepted then
				Remotes.Skills.DeleteSkill:FireServer( self.selected_slot );
			end
		end)
	end)

	self.overview_panel.ActionsFrame.Edit.Button.MouseButton1Click:Connect(function()
		
		if self.editing_slot == self.selected_slot then
			self.panel_pages.UIPageLayout:JumpTo( self.panel_pages.BuildPage )
			
		elseif self.editing_slot then
			self:confirm("Cancel Editing", "You are editing another skill, do you wish to continue? any unsaved changes will be lost.", function(accepted)
				if accepted then
					self:edit_slot( self.selected_slot );
				end
			end)
		else
			self:edit_slot( self.selected_slot );
		end;
	end);

	self.build_items.Timeline.Panel.Actions.Apply.Button.MouseButton1Click:Connect(function()
		self:confirm("Save", "Are you sure you want to save?", function(accepted)
			if accepted then
				self:increment_loading(1);
				
				local to_submit = self:generate_edit_data();
				Remotes.Skills.SubmitSkill:FireServer( self.editing_slot, to_submit );
				
				task.wait(0.3);
				
				self:increment_loading(-1);
				
				self.build_tools:notify(4, `Successfully saved skill {to_submit.Properties.SkillName.Value}`);
				self.edit_changes = 0;
			end
		end)
	end)

	self.build_items.Timeline.Panel.Actions.Cancel.Button.MouseButton1Click:Connect(function()
		local function return_to_overview()
			self:edit_slot(nil);
			self.panel_pages.UIPageLayout:JumpTo( self.panel_pages.OverviewPage );
		end;
		
		if self:has_unsaved_changes() then
			self:confirm("Unsaved Changes", "Are you sure you cancel without saving? All progress will be lost.", function(accepted)
				if accepted then
					return_to_overview();
				end
			end)
		else
			return_to_overview();
		end;
	end);

	do
		local resize_dragger: UIDragDetector = self.body.Body.Resize.UIDragDetector;
		local dragStartScaleX
		local dragStartScaleY
		local dragStartWidthX = 1
		local dragStartWidthY = 1

		local minScale = Vector2.new(0.15, 0.15)
		local maxScale = Vector2.new(0.45, 0.45)

		resize_dragger.DragStart:Connect(function()
			local ui = self.ui.Body;

			dragStartScaleX = ui.Size.X.Scale
			dragStartWidthX = ui.AbsoluteSize.X
			dragStartScaleY = ui.Size.Y.Scale
			dragStartWidthY = ui.AbsoluteSize.Y
		end)

		resize_dragger.DragContinue:Connect(function()
			local ui = self.ui.Body;
			
			local widthDragged = resize_dragger.DragUDim2.X.Offset / dragStartWidthX * 2
			local heightDragged = resize_dragger.DragUDim2.Y.Offset / dragStartWidthY * 2
			local scaleToApplyX = dragStartScaleX * (1 + widthDragged)
			local scaleToApplyY = dragStartScaleY * (1 + heightDragged)

			scaleToApplyX = math.clamp(scaleToApplyX, minScale.X, maxScale.X)
			scaleToApplyY = math.clamp(scaleToApplyY, minScale.Y, maxScale.Y)

			ui.Size = UDim2.new(scaleToApplyX, 150, scaleToApplyY, 150);
		end)
	end
	
	self.build_items.Timeline.Timeline.Skills.Create.Button.MouseButton1Down:Connect(function()
		self:create_branch( "Branch" );
	end);
	
	self.build_items.Timeline.Timeline.Skills.Delete.Button.MouseButton1Down:Connect(function()
		local branch = self.selected_branch;

		if branch then
			local position = branch:get_position();
			
			if position == 1 then
				return self.build_tools:notify(1, "You can't delete the default branch 🥀")
			end;
			
			self:select_branch( self.branches[position - 1] );
			table.remove(self.branches, position);
			
			branch:destroy();
		end;
	end);
	
	self.build_items.Timeline.Timeline.Action.Copy.Button.MouseButton1Down:Connect(function()
		self:copy_to_clipboard();
	end);
	
	self.build_items.Timeline.Timeline.Action.Paste.Button.MouseButton1Down:Connect(function()
		self:paste_from_clipboard();
	end);
	
	self.build_items.Timeline.Timeline.Action.MoveDown.Button.MouseButton1Down:Connect(function()
		local block = self.selected_skill_block;
		
		if block then
			block.branch:shuffle_block( block.position, 1 );
		else
			self:shuffle_branch( self.selected_branch:get_position(), 1 )
		end;
	end);

	self.build_items.Timeline.Timeline.Action.MoveUp.Button.MouseButton1Down:Connect(function()
		local block = self.selected_skill_block;

		if block then
			block.branch:shuffle_block( block.position, -1 );
		else
			self:shuffle_branch( self.selected_branch:get_position(), -1 )
		end;
	end);

	self.build_items.Timeline.Timeline.Action.Delete.Button.MouseButton1Down:Connect(function()
		local to_delete = self.selected_skill_block;

		if to_delete then
			self:select_block( to_delete.branch.blocks[to_delete.position + 1] );
			to_delete:destroy();
		end;
	end);

	self.maid:add(self.stream:observe_table({"Slots"}, function(id, slot)
		self:create_slot(id, slot);
	end));

	task.spawn(function()
		print("[Skill Builder]: Requesting Skill Properties");
		self.skills_data = BuildPersistent.Remotes.Skills.RequestProperties:InvokeServer();
	end)

	Stylus.bind_to_resize(self.body, function(abs_size)
		local scale = abs_size.X * 0.028;

		self.overview_panel.InfoFrame.DisplayName.TextSize = scale;
		self.overview_panel.InfoFrame.EditTime.TextSize = scale;
		self.overview_panel.InfoFrame.CreateTime.TextSize = scale;
	end)

	self.overview_panel.Visible = false;
	self:set_data_page( "Timeline" );
	
	--UserInputService.TouchTap:Connect(function()
	--	if not self:get_interact_active() then
	--		self:toggle(false);
	--	end
	--end)

	--UserInputService.InputBegan:Connect(function(input, processed)
	--	if input.UserInputType == Enum.UserInputType.MouseButton1 and not self:get_interact_active() then
	--		self:toggle(false);
	--	end
	--end)
end

function SkillBuilder:push_transparent_mode()
	local last_transparent = self.active_transparent;
	
	self.active_transparent += 1;
	
	if last_transparent == 0 and self.enabled then
		self.tweens.transparent:Play();
		Stylus:tween_blur(0, "SkillBuilder");
	end;
end;

function SkillBuilder:pop_transparent_mode()
	local last_transparent = self.active_transparent;

	self.active_transparent = math.max(0, self.active_transparent - 1);

	if last_transparent == 1 and self.enabled then
		self.tweens.open:Play();
		Stylus:tween_blur(20, "SkillBuilder");
	end;
end;

function SkillBuilder:clear_clipboard()
	if self.copied_skill_block then
		self.copied_skill_block:destroy();
		self.copied_skill_block = nil;
	end;
	
	if self.copied_branch then
		self.copied_branch:destroy();
		self.copied_branch = nil;
	end;
end

function SkillBuilder:copy_to_clipboard()
	local block = self.selected_skill_block;
	local branch = self.selected_branch;
	
	if block then
		self:clear_clipboard();
		self.copied_skill_block = block:clone();
		self.build_tools:notify(3, "Copied selected block to clipboard", 3);
		
	elseif branch then
		self:clear_clipboard();
		self.copied_branch = branch:clone();
		self.build_tools:notify(3, "Copied selected branch to clipboard", 3);
		
	else
		self.build_tools:notify(2, "No block or branch was copied", 2);
	end;
end;

function SkillBuilder:paste_from_clipboard()
	local block = self.copied_skill_block;
	local branch = self.copied_branch;
	
	if block then
		local select_block = self.selected_skill_block;
		local position: number?;

		if select_block then
			position = select_block.position + 1;
		end;

		local paste = block:clone();
		paste:set_branch(self.selected_branch, position);
		
	elseif branch then
		local select_branch = self.selected_branch;
		local position: number?;

		if select_branch then
			position = select_branch.position + 1;
		end;

		local paste = branch:clone();
		self:add_branch(paste, position);
		paste:set_seated(true);
		
	else
		self.build_tools:notify(2, "No block or branch is copied", 2);
	end;
end

function SkillBuilder:confirm(title, subtitle, callback)
	self:hide_import();
	self.tweens.ghost:Play();

	self.build_tools.confirmations:make(title, subtitle, function(accepted)
		self.tweens.open:Play();
		callback(accepted);
	end)
end;

function SkillBuilder:toggle_deprecated(value: boolean?): ()
	if (value == nil) then
		value = not self.show_deprecated;
	end;
	
	local current_value = self.show_deprecated;
	
	if current_value ~= value then
		self.show_deprecated = value;
		
		for _, block_frame in self.add_block_frame.ScrollingFrame.Blocks:GetChildren() do
			local data = self.skills_data.blocks[block_frame.Name];
			
			if data and data.Deprecated then
				block_frame.Visible = value;
			end;
		end;
		
		if value then
			self.build_tools:notify("info", "Showing deprecated blocks", 3);
			self.add_block_frame.Deprecated.Icon.ImageColor3 = Color3.fromRGB(166, 255, 98);
		else
			self.add_block_frame.Deprecated.Icon.ImageColor3 = Color3.fromRGB(255, 255, 255);
		end;
	end;
end;

function SkillBuilder:set_data_page(page_name: string)
	local page = self.build_items[page_name];
	local button = self.build_page.Categories[page_name];
	
	local current_page = self.build_items.UIPageLayout.CurrentPage;
	local last_button = self.build_page.Categories[current_page.Name];

	local info = TweenInfo.new(0.15);
	
	TweenService:Create(button.Button, info, { BackgroundTransparency = 0.65 }):Play();
	TweenService:Create(button.Button.UIStroke, info, { Transparency = 0.6, Thickness = 2 }):Play();
	
	if last_button ~= button then
		TweenService:Create(last_button.Button, info, { BackgroundTransparency = 0.85 }):Play();
		TweenService:Create(last_button.Button.UIStroke, info, { Transparency = 0.8, Thickness = 1 }):Play();
	end;
	
	self.build_items.UIPageLayout:JumpTo( page );
end;

function SkillBuilder:done_changes(): ()
	self.edit_changes += 1;
end;

function SkillBuilder:has_unsaved_changes(): boolean
	return self.edit_changes >= 1;
end

function SkillBuilder:create_universal_property(name: string, value: any, data, ratio, text_scale)
	local y_scale = 0.105;
	
	local property = self.assets.SkillProperty:Clone();
	property.Size = UDim2.fromScale(1, y_scale);
	property.LayoutOrder = data.Order or 1;

	if data.Hidden then
		property.Visible = false;
	end

	local value_type = data.Type or typeof(value);
	local box;

	if value_type == "boolean" then
		box = Stylus:new_checkbox({
			text = name;
			toggled = value;
			parent = property;
			theme = "bg_transparent";
			ratio = ratio or 0.65;
			text_scale = text_scale or 0.75;
			grayboxed = data.Grayboxed;
		});

	elseif value_type == "Instance" then
		box = Stylus:new_instancebox({
			text = name;
			value = value;
			parent = property;
			theme = "bg_transparent";
			ratio = ratio or 0.65;
			text_scale = text_scale or 0.75;
			grayboxed = data.Grayboxed;
		});
		
	elseif value_type == "Color3" then
		box = Stylus:new_colorbox({
			text = name;
			value = Type.string:cast(value);
			parent = property;
			theme = "bg_transparent";
			ratio = ratio or 0.65;
			text_scale = text_scale or 0.75;
			grayboxed = data.Grayboxed;
		});
		
		box:set_color( value );
		
		self.hue_picker:bind_colorbox(box, function(color) 
			--box:set_value( color );
		end);

	elseif data.Format and data.Format.Type == "Slider" then
		box = Stylus:new_sliderbox({
			text = name;
			value = value;
			range = data.Format.Range,
			increment = data.Format.Increment,
			parent = property;
			theme = "bg_transparent";
			ratio = ratio or 0.65;
			text_scale = text_scale or 0.75;
			grayboxed = data.Grayboxed;
		});
	else
		local button_based = value_type == "NumberSequence";
		local enum_based = value_type == "EnumItem";
		
		box = Stylus:new_stringbox({
			text = name;
			value = Type.stringenum:cast(value);
			parent = property,
			theme = "bg_transparent";
			dropdown_visible = if enum_based or data.AssetType or data.ValueList then true else false;
			button_based = button_based;
			ratio = ratio or 0.65;
			text_scale = text_scale or 0.75;
			variable = button_based;
			grayboxed = data.Grayboxed;
		});
		
		if data.ValueList then
			box:bind_to_dropdown(function()
				if self.value_list.widget.enabled then
					self:hide_value_list();
				else
					if data.ValueList == "Branch" then
						self.value_list:clear_items();
						
						for _, branch in self.branches do
							self.value_list:create_item({ value = branch.name })
						end
					else
						self.value_list:load_items(data.ValueList);
					end;
					
					self.value_list.affector_instance = box;
					
					self:show_value_list();
				end;
			end);
			
		elseif enum_based then
			box:bind_to_dropdown(function()
				if self.value_list.widget.enabled then
					self:hide_value_list();
				else
					self.value_list:load_items(value.EnumType:GetEnumItems());
					self.value_list.affector_instance = box;
					self:show_value_list();
				end;
			end);
		end;
		
		if button_based then
			if value_type == "NumberSequence" then
				box.instance.Button.MouseButton1Click:Connect(function()
					
					self.build_tools.number_editor.closed:Once(function()
						if not self.enabled and self.build_tools.enabled then
							self:toggle(true);
						end;
					end)
				end);
				
				self.build_tools.number_editor:bind_stringbox(box, function(sequence)
					box:set_value( sequence );
					self:toggle(true);
				end)
				
				box.focus_start:Connect(function()
					self.build_tools.number_editor:set_sequence( box:get_value() );
				end)
			end;
		else
			box.interacted:Connect(function(new_value)
				local data_typeof = typeof(value);
				local formatted = Type.format_string(new_value, data_typeof);
				
				if value_type == "string" and (data.Filtered == nil or data.Filtered) and (not data.ValueList or data.ValueList[new_value]) and data_typeof == "string" then
					self:increment_loading(1);
					local error_success, success, result = pcall(Remotes.Skills.FilterString.InvokeServer, Remotes.Skills.FilterString, formatted);
					self:increment_loading(-1);
					
					if error_success then
						if not success then
							self.build_tools:notify(2, result);
						end;
					end;
				end;
				
				box:set_value( formatted )
			end);
		end;
		
		if data.AssetType ~= nil then
			
			if data.AssetType == Enum.AssetType.Audio then
				property.Size = UDim2.fromScale(1, property.Size.Y.Scale + y_scale);
				property.UIListLayout.Padding = UDim.new(0.05, 0);
				property.UIListLayout.VerticalFlex = Enum.UIFlexAlignment.Fill;
				
				local musicbox = Stylus:new_musicbox({
					text = "";
					value = value,
					parent = property,
					theme = "bg_transparent";
					ratio = 0.1;
					text_scale = text_scale or 0.75;
				});
				
				musicbox.layout.TextLabel.Visible = false;
				musicbox:set_audio(data._Sound)
				
				box.maid:add(musicbox);
			end;
			
			local reopen = false;

			local function open_toolbox()
				if self.build_tools.toolbox.affector_instance ~= box.instance then
					reopen = true;

					self.build_tools.toolbox:toggle(true, data.AssetType);
					self.build_tools.toolbox.affector_instance = box.instance;
				else
					self.build_tools.toolbox:toggle(false);
				end;
			end

			box:bind_to_dropdown(open_toolbox);

			self.build_tools.toolbox:bind_stringbox(box, function(asset_id: number)
				box:set_value( tostring(asset_id) )
			end);
			
			box.maid:add(self.build_tools.toolbox.on_apply:Connect(function()
				if self.build_tools.toolbox.affector_instance == box.instance then
					task.wait(1 / 60);

					self:toggle(true);
				end;
			end))

			box.maid:add(self.build_tools.toolbox.closed:Connect(function()
				if reopen then
					reopen = false;

					self:toggle(true);
				end;
			end))
		end;
	end;
	
	if box then
		box.value_changed:Connect(function()
			self:done_changes();
		end);
		
		if box.gray_changed then
			box.gray_changed:Connect(function()
				self:done_changes();
			end);
		end
	end

	if box and data.TitleColor then
		box.layout.TextLabel.TextColor3 = data.TitleColor;
	end;

	return property, box;
end;


function SkillBuilder:create_slot(slot: number, data)
	-- Server stores slots as strings (DataStores do not like sparse arrays)
	if typeof(slot) == "string" then
		slot = tonumber(slot) :: any;
	end;

	if self.slots[slot] then
		if self.selected_slot == slot then
			self:select_slot(nil);
		end

		self.slots[slot].maid:destroy();
		self.slots[slot].frame:destroy();
		self.slots[slot] = nil;
	end;

	if data then
		local frame = self.assets.SlotSkillBlock:Clone();
		local maid = Maid.new();

		maid:add(self.stream:observe_table({"Slots", tostring(slot), "Properties"}, function(key, value)
			if self.editing_slot == slot then
				self:update_editing();
			end;
			
			if key == "SkillName" then
				frame.Button.Text = value.Value;
			end;
		end))

		self.slots[slot] = {
			frame = frame;
			data = data;
			maid = maid;
		};

		frame.Button.MouseButton1Click:Connect(function()
			if self.selected_slot == slot then
				self:select_slot( nil );
			else
				self:select_slot(slot);
			end;
		end);
		
		frame.Parent = self.overview_page.Timeline.Workspace.ScrollingFrame;
		self:sort_slot_order();
	end;
end;

function SkillBuilder:create_block(name: string, position: number?)
	local branch = self.selected_branch or self.branches[1];
	assert(branch, "No branch?");

	self:done_changes();
	
	return branch:create_block(name, position);
end;

function SkillBuilder:create_branch(name: string, position: number?)
	if not position then
		position = #self.branches + 1;
	end;
	
	local branch = Branch.new(self, name, position);
	
	self.branches[position] = branch;
	
	self:done_changes();
	
	return branch;
end;

function SkillBuilder:shuffle_branch(position_1: number, value: number)
	self:swap_branch( position_1, position_1 + value );
end

function SkillBuilder:swap_branch(position_1, position_2)
	-- Cannot swap with the default branch, that should always be first.
	if position_1 == 1 or position_2 == 1 then
		return;
	end;
	
	local this_position = math.clamp( position_1, 1, #self.branches );
	local new_position = math.clamp( position_2, 1, #self.branches );

	local this_branch = self.branches[this_position]
	local other_branch = self.branches[new_position];
	
	if this_branch ~= other_branch then
		-- Swaps the two indexes in the array.
		self.branches[this_position], self.branches[new_position] = self.branches[new_position], self.branches[this_position];
		
		this_branch:update_position(new_position);
		other_branch:update_position(this_position);
		
		self:done_changes();
	end;
end;

function SkillBuilder:add_branch(branch, position: number)
	if not position then
		position = #self.branches + 1;
	end;

	table.insert(self.branches, position, branch);

	for index = position, #self.branches do
		self.branches[index]:update_position(index);
	end;
end;

function SkillBuilder:sort_slot_order()
	local list = {};

	for index, slot_data in self.slots do
		table.insert(list, slot_data);
	end;

	table.sort(list, function(a, b)
		return a.data.CreateTime < b.data.CreateTime;
	end);

	for index, slot_data in list do
		slot_data.frame.LayoutOrder = index;
	end;
end

function SkillBuilder:generate_edit_data()
	local edit_data = {};
	edit_data.Properties = {};
	edit_data.BranchBlocks = {};

	for name, field in self.skill_properties do
		edit_data.Properties[name] = { Value = field:get_value(), Gray = field.is_grayboxed }
	end;

	for branch_index, branch in self.branches do
		edit_data.BranchBlocks[branch_index] = branch:generate_edit_data();
	end
	
	return edit_data;
end;

function SkillBuilder:parse_animation(animation: Animation): string
	return Instances.get_directory(animation, ReplicatedStorage.Animations, "/") or "None";
end

function SkillBuilder:unparse_animation(animation: string): Animation?
	return Instances.find_directory(ReplicatedStorage.Animations, animation, "/");
end

function SkillBuilder:unselect()
	self:select_branch(nil);
	self:select_block(nil);
end

function SkillBuilder:clear_builder()
	self:unselect();
	self.selected_branch = nil;
	
	for name, field in self.skill_properties do
		local property = self.skills_data.properties[name];

		field:set_value(property.Default);
	end;

	-- Iterate backwards to avoid incompatibility with spontaneous table.remove
	for index = #self.branches, 1, -1 do
		local branch = self.branches[index];
		branch:destroy();
	end;
	
	table.clear(self.branches);
end;

function SkillBuilder:load_builder(data)
	
	if data then
		for name, field in self.skill_properties do
			local property = self.skills_data.properties[name];
			local data = data.Properties[name];

			if ( data.Value ~= nil ) then
				field:set_value(data.Value);
			else
				field:set_value(property.Default);
			end;
		end;

		if data.BranchBlocks then
			for branch_index, branch in data.BranchBlocks do
				local name = branch.Properties.BranchName.Value;
				local branch_block = self:create_branch( name, branch_index );
				
				for index, data in branch.Properties do
					branch_block:set_property_data(index, data)
				end;
				
				for index, block in branch.Blocks do
					local skill_block = branch_block:create_block( block.Name );
					
					for property, data in block.Properties do
						skill_block:set_property_data(property, data);
					end;
				end;
				
				if not self.selected_branch then
					self:select_branch(branch_block);
				end
			end;
		end;
	end;
	
	task.defer(function()
		self.edit_changes = 0;
		self.build_tools:notify(3, `Successfully loaded skill`);
	end);
end;

function SkillBuilder:get_serialised_skill_data(slot: number)
	local slot_data = Remotes.Skills.RequestSkillData:InvokeServer(slot);

	return slot_data;
end

function SkillBuilder:update_editing()
	local slot_data = self.slots[self.editing_slot];

	if slot_data then
		self.body.Title.Text = `Skill Builder (<font color='rgb(200,200,255)'>{slot_data.data.Properties.SkillName.Value}</font>)`;
	else
		self.body.Title.Text = "Skill Builder";
	end
end

local function load_build_sequence(self, slot)
	self:increment_loading(1);

	local success, data =pcall(function()
		return self:get_serialised_skill_data(slot);
	end);
	
	if not success then
		warn("SkillBuilder Exception:", data);
		self.build_tools:notify(1, "Unable to load slot: error retrieving skills data.");
	else
		local success, result = pcall(function() 
			return self:load_builder( data );
		end);

		if not success then
			warn("SkillBuilder Exception:", result);
			self.build_tools:notify(1, "Unable to load slot: error loading and displaying skills data");
		end;
	end;
	
	task.wait(0.5);
	self:increment_loading(-1)
end;

function SkillBuilder:edit_slot( slot: number )
	local last_edit_slot = self.editing_slot;

	if last_edit_slot ~= slot then
		local slot_data = self.slots[slot];

		self:unselect();
		self.editing_slot = slot;
		self.edit_changes = 0;
		
		if last_edit_slot then
			self:clear_builder();
		end

		if slot_data then
			task.spawn(load_build_sequence, self, slot);
		end;

		self:update_editing();
		self.panel_pages.UIPageLayout:JumpTo( self.panel_pages.BuildPage );
	end
end

function SkillBuilder:select_slot( slot: number )
	local last_slot = self.selected_slot;

	if last_slot ~= slot then
		self.selected_slot = slot;
		self.overview_panel.Visible = (slot ~= nil);

		if last_slot and self.slots[last_slot] then
			local slot_info = self.slots[last_slot];
			local data = slot_info.data;
			
			local stroke = slot_info.frame.Button.UIStroke
			stroke.Transparency = 0.8;
			stroke.Thickness = 1;
			stroke.Color = Color3.fromRGB(255, 255, 255);
		end

		if slot and self.slots[slot]  then
			local slot_info = self.slots[slot];
			local data = slot_info.data;
			
			local stroke = slot_info.frame.Button.UIStroke
			stroke.Transparency = 0.1;
			stroke.Thickness = 2;
			stroke.Color = Color3.fromRGB(197, 215, 255);
			
			self.overview_panel.InfoFrame.DisplayName.Text = `<b>Skill Name</b>: { data.Properties.SkillName.Value }`;
			self.overview_panel.InfoFrame.EditTime.Text = `<b>Edited</b>: { DateTime.fromUnixTimestamp(data.EditTime):FormatLocalTime("lll", "en-us") }`;
			self.overview_panel.InfoFrame.CreateTime.Text = `<b>Created</b>: { DateTime.fromUnixTimestamp(data.CreateTime):FormatLocalTime("lll", "en-us") }`;
		end
	end
end

function SkillBuilder:select_block( block )
	local last_skill_block = self.selected_skill_block;

	self.selected_skill_block = block;

	self.add_block_frame.Visible = true;
	self.edit_block_frame.Visible = false;
	self.edit_block_frame.Title.Text = "...";

	if last_skill_block then
		last_skill_block:set_as_panel(false);
	end;

	if block then
		block:set_as_panel(true);
		block:update_subtitle();
		
		self.build_items.Timeline.Timeline.Action.MoveDown.Icon.Rotation = 180;
		self.build_items.Timeline.Timeline.Action.MoveUp.Icon.Rotation = 0;
		self.add_block_frame.Visible = false;
		self.edit_block_frame.Visible = true;
		self.edit_block_frame.Title.Text = Asset.pretty_string(block.name);
	else
		self.build_items.Timeline.Timeline.Action.MoveDown.Icon.Rotation = 90;
		self.build_items.Timeline.Timeline.Action.MoveUp.Icon.Rotation = -90;
	end;
end;

function SkillBuilder:update_branch_details()
	local branch = self.selected_branch;
	local branch_name = "Branch";
	
	if branch then
		branch_name = branch:get_value("BranchName");
	end;
	
	self.build_page.Categories.Branch.Button.Text = branch_name;
end

function SkillBuilder:select_branch( branch )
	self:select_block(nil);
	
	local last_branch = self.selected_branch;
	
	if not branch then
		branch = self.branches[1];
	end;
	
	if branch ~= last_branch then
		self.selected_branch = branch;
		
		if last_branch and not last_branch.destroyed then
			last_branch:set_selected(false);
		end
		
		if branch then
			branch:set_selected(true);
			
			for property, field in self.branch_properties do
				local data = branch:get_property(property);
				
				if data ~= nil then
					field:set_value( data.Value );
					
					if data.Gray ~= nil then
						field:set_grayboxed( data.Gray );
					end
				end;
			end;
		end;
		
		self:update_branch_details();
	end;
end;

function SkillBuilder:get_animation_from_name(name: string)
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://180426354";

	return animation;
end

function SkillBuilder:initialise_open()
	for name, data in self.skills_data.blocks do

		local skill_block = self.assets.InsertSkillBlock:Clone();
		skill_block.Button.Display.Icon.Image = Asset.get_rbx_asset(data.Icon);
		skill_block.Button.Title.Title.Text = data.DisplayName or Asset.pretty_string(name);
		skill_block.Button.Title.SubTitle.Text = data.Description or "No Description";
		skill_block.Button.Highlight.BackgroundColor3 = data.Color;
		skill_block.LayoutOrder = data.Order;
		skill_block.Name = name;
		
		if data.Deprecated and not self.show_deprecated then
			skill_block.Visible = false;
		end;
		
		skill_block.Parent = self.add_block_frame.ScrollingFrame.Blocks;
		
		local function resize_block()
			local size = skill_block.Button.AbsoluteSize;

			skill_block.Size = UDim2.new(1, 0, 0, size.Y);

			-- Automatic Size is not reliable, this is a workaround.
			skill_block.Button.Title.SubTitle.Size = UDim2.new(1, 0, 0, skill_block.Button.Title.SubTitle.TextBounds.Y);
			skill_block.Button.Title.Title.Size = UDim2.new(1, 0, 0, skill_block.Button.Title.Title.TextBounds.Y);
		end;

		skill_block.Button.Title.Title:GetPropertyChangedSignal("TextBounds"):Connect(resize_block)
		skill_block.Button.Title.SubTitle:GetPropertyChangedSignal("TextBounds"):Connect(resize_block)
		Stylus.bind_to_resize(skill_block.Button, resize_block);

		skill_block.Button.MouseButton1Click:Connect(function()
			local block = self:create_block( name );
			
			if block then
				block:scroll_to_position();
			end;
		end);
	end;

	for name, data in self.skills_data.branches do
		local display_name = data.DisplayName or Asset.pretty_string(name);
		
		local box, field = self:create_universal_property( display_name, data.Default, data, nil, 0.55 );
		box.Size = UDim2.fromScale(1, 0.065); -- 0.0525
		box.Parent = self.build_items.Branch.ScrollingFrame;

		field.value_changed:Connect(function(value)
			if not self.selected_branch then return end;
			
			self.selected_branch:set_property(name, value);
		end)

		if field.gray_changed then
			field.gray_changed:Connect(function(value)
				if not self.selected_branch then return end;
				
				local data = self.selected_branch:get_property(name);
				
				if data and data.Gray ~= value then
					data.Gray = value;
					self:done_changes();
				end
			end);
		end;
		
		self.branch_properties[name] = field;
	end;
	
	for name, data in self.skills_data.properties do
		local display_name = data.DisplayName or Asset.pretty_string(name);
		
		local box, field = self:create_universal_property( display_name, data.Default, data, nil, 0.55 );
		box.Size = UDim2.fromScale(1, 0.065);
		box.Parent = self.build_items.Properties.ScrollingFrame;
		
		self.skill_properties[name] = field;
	end;

	self.stream:synchronise()
end;

function SkillBuilder:get_interact_active()
	return self.active or Stylus:is_hovering_over_any{self.affector_instance};
end

function SkillBuilder:clear()
	for _, item in self.items do
		item:destroy();
	end;

	table.clear(self.items);
end;

function SkillBuilder:increment_loading(value: number)
	self.active_loading = math.max(self.active_loading + value, 0);

	if self.is_loading and self.active_loading == 0 then
		self:set_loading(false);

	elseif not self.is_loading and self.active_loading > 0 then
		self:set_loading(true);
	end
end

function SkillBuilder:set_loading(value: boolean)
	self.loading_maid:clean();

	local loading = self.loading;
	local info = TweenInfo.new(0.25);
	
	if value then
		self.is_loading = true;
		
		loading.LoadingBackdrop.BackgroundTransparency = 1;
		loading.Loading.ImageTransparency = 1;
		
		loading.Loading.Visible = true;
		loading.LoadingBackdrop.Visible = true;
		
		local tween = TweenService:Create(loading.LoadingBackdrop, info, {BackgroundTransparency = 0.4});
		tween:Play();
		
		local tween = TweenService:Create(loading.Loading, info, {ImageTransparency = 0});
		tween:Play();
		
		self.loading_maid:add(RunService.PreRender:Connect(function(dt)
			loading.Loading.Rotation += 360 * dt;
		end))
	else
		self.is_loading = false;
		
		local tween = TweenService:Create(loading.LoadingBackdrop, info, {BackgroundTransparency = 1});
		tween:Play();
		
		local tween = TweenService:Create(loading.Loading, info, {ImageTransparency = 1});
		tween:Play();
		
		tween.Completed:Once(function(status)
			if status == Enum.PlaybackState.Completed then
				loading.Loading.Visible = false;
				loading.LoadingBackdrop.Visible = false;
			end;
		end);
	end;
end;

function SkillBuilder:show_value_list()
	if self.value_list.widget.enabled then return end;
	
	self.value_list:toggle(true);
	self.tweens.ghost:Play();
end

function SkillBuilder:hide_value_list()
	if not self.value_list.widget.enabled then return end;

	self.value_list:toggle(false);
	
	if self.enabled then
		self.tweens.open:Play();
	end
end

function SkillBuilder:hide_color_picker()
	if not self.hues_enabled then return end;
	
	self.ui.Hues.Interactable = false;

	self.hues_enabled = false;
	self.hues_maid:clean();

	self.tweens.hues_close:Play();
	
	if self.hue_picker.visible then
		self.hue_picker:toggle(false);
	end;
	
	if self.enabled then
		self.tweens.open:Play();
	end
end;

function SkillBuilder:show_color_picker()
	if self.hues_enabled or not self.build_tools.enabled then return end;

	self.tweens.ghost:Play();

	self.ui.Hues.Interactable = true;
	self.ui.Hues.Visible = true;
	
	self.hues_enabled = true;
	self.hues_maid:clean();

	self.tweens.hues_open:Play();
	
	if not self.hue_picker.visible then
		self.hue_picker:toggle(true);
	end
	
	self.hues_maid:add(self.hues_body.Body.Accept.Button.MouseButton1Click:Once(function()
		self:hide_color_picker();
	end));

	self.hues_maid:add(self.hues_body.Title.Close.MouseButton1Click:Once(function()
		self:hide_color_picker();
	end))
end

function SkillBuilder:hide_import()
	if not self.import_enabled then return end;

	self.ui.Import.Interactable = false;

	self.import_enabled = false;
	self.import_maid:clean();

	if self.current_import_callback then
		self.current_import_callback( false );
		self.current_import_callback = nil;
	end

	self.tweens.import_close:Play();

	if self.enabled then
		self.tweens.open:Play();
	end
end

function SkillBuilder:prompt_import(data)
	if self.import_enabled or not self.build_tools.enabled then return end;

	self.tweens.ghost:Play();

	self.ui.Import.Interactable = true;
	self.ui.Import.Visible = true;
	
	self.import_enabled = true;
	self.import_maid:clean();

	self.tweens.import_open:Play();
	self.current_import_callback = data.callback;

	self.import_body.Body.TextBox.TextEditable = if data.can_edit ~= nil then data.can_edit else true;
	self.import_body.Body.TextBox.Text = data.text or "";
	self.import_body.Body.TextBox.PlaceholderText = data.box_title or "Data goes here";
	self.import_body.Body.Accept.Button.Text = data.button_tip or "Import";
	self.import_body.Body.Accept.Button.BackgroundColor3 = data.button_color or Color3.fromRGB(102, 255, 125);
	
	local function activate_import(value: boolean)
		if self.current_import_callback == data.callback then
			self.current_import_callback = nil;
			self.import_maid:clean();
		end;

		self:hide_import();

		data.callback( value, self.import_body.Body.TextBox.Text );
	end;

	self.import_maid:add(self.import_body.Body.Accept.Button.MouseButton1Click:Once(function()
		activate_import( true );
	end));

	self.import_maid:add(self.import_body.Title.Close.MouseButton1Click:Once(function()
		activate_import( false );
	end))
end

function SkillBuilder:toggle(value: boolean?, asset_type: Enum.AssetType)
	if (value == nil) then
		value = not self.enabled;
	end;

	if value and not self.build_tools.enabled then return end;

	if (value ~= self.enabled) then
		self:hide_import();
		self.block_help:toggle(false);
		
		self.build_tools:close_all(self);
		self.enabled = value;

		if (value) then
			if not self.skills_data then
				return warn("Skills data has not yet been fetched, could not open the skill builder.");
			end;

			self.opened:Fire();
			self.tweens.open:Play();
			self.ui.Enabled = true;

			if not self.init_enabled then
				self.init_enabled = true;
				self:initialise_open();
			end;

			Stylus:tween_blur(20, "SkillBuilder");
			SoundService:PlayLocalSound(self.build_tools.sounds.DockToggle);
		else
			if self.build_tools.wizards:is_currently("SkillBuilder") then
				self.build_tools.wizards:set(nil);
			end

			self.closed:Fire();
			self.tweens.close:Play();

			Stylus:tween_blur(0, "SkillBuilder");
		end	
	end;
end

table.freeze(SkillBuilder);

return SkillBuilder;