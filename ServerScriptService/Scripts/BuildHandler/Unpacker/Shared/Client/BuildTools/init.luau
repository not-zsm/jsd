
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local GamepadService = game:GetService("GamepadService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

-----------------------------------------------------------------------------------------------------------

local BuildPersistent = ReplicatedStorage:WaitForChild("BuildTools");
local BuildShared = BuildPersistent:WaitForChild("Shared");
local Remotes = BuildPersistent:WaitForChild("Remotes");

local BuildAssets = BuildShared:WaitForChild("Assets");
local InstancesBuild = BuildAssets:WaitForChild("Build");
local Builds = workspace:WaitForChild("Builds");
local Sounds = script:WaitForChild("Sounds");
local Player = Players.LocalPlayer;
local PlayerGui = Player:WaitForChild("PlayerGui");

-----------------------------------------------------------------------------------------------------------

local Build = require( ReplicatedStorage.BuildTools.Build )
local Math = require( ReplicatedStorage.Packages.Math )
local Maid = require( ReplicatedStorage.Packages.Maid )
local Table = require( ReplicatedStorage.Packages.Table )
local Observer = require( ReplicatedStorage.Packages.Observer )
local Stylus = require( ReplicatedStorage.Packages.Stylus )
local HelpInput = require( ReplicatedStorage.Packages.HelpInput )
local Type = require( ReplicatedStorage.Packages.Type )
local UX = require( ReplicatedStorage.Packages.UserInterface )
local BufferUtil = require( ReplicatedStorage.Packages.BufferUtil )

-- Dont try to fix these, the requires work
local PropertyTable = require( BuildShared.Data.Properties )
local PropertyCustom = require( BuildShared.Data.Properties.Custom )
local PropertyUtil = require( BuildShared.Data.Properties.Utility )
local NotificationStatus = require( BuildShared.Data.NotificationStatus )
local Products = require( BuildShared.Data.Products );
local StateIndex = require( BuildShared.Data.ModifierStateIndex );

-----------------------------------------------------------------------------------------------------------

local Selection = require( script.Selection )
local Draggers = require( script.Draggers )
local Actions = require( script.Actions )
local LoadSave = require( script.LoadSave )
local Modifiers = require( script.Modifiers )
local SpawnInsert = require( script.SpawnInsert )
local ModifierInsert = require( script.ModifierInsert )
local Preferences = require( script.Preferences )
local NumberEditor = require( script.NumberEditor )
local Toolbox = require( script.Toolbox )
local Status = require( script.Status )
local ToolWidget = require( script.ToolWidget )
local Wizards = require( script.Wizards )
local SkillBuilder = require( script.SkillBuilder )

-----------------------------------------------------------------------------------------------------------

local ModifierFrame = require( script.UI.ModifierFrame );
local Properties = require( script.Properties )
local Explorer = require( script.Explorer )
local ToolFrame = require( script.UI.ToolFrame );
local ToolBarFrame = require( script.UI.ToolBarFrame );
local SpawnBarFrame = require( script.UI.SpawnBarFrame );
local IncrementerFrame = require( script.UI.IncrementerFrame );
local AlignmentFrame = require( script.UI.AlignmentFrame )
local ChangeHistoryFrame = require( script.UI.ChangeHistoryFrame )
local Confirmations = require( script.Confirmations )
local HuePicker = require( script.UI.HuePicker )
local Inventory = require( script.Inventory )
local Placement = require( script.Placement )
local Dropdown = require( script.Dropdown )
local Searcher = require( script.UI.Searcher )
local Help = require( script.UI.Help )
local Marketplace = require( script.Marketplace )
local Schema = require( script.Schema.Keybinds )

-----------------------------------------------------------------------------------------------------------

local ALL_TOOL_MODES = {
	Enum.RibbonTool.Select;
	Enum.RibbonTool.Move;
	Enum.RibbonTool.Scale;
	Enum.RibbonTool.Rotate;
	Enum.RibbonTool.Transform;
};

-----------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------

export type ClassBuildTools = {
	__index: ClassBuildTools;

	new: (UI: typeof(script.Parent)) -> (BuildTools);
	toggle_ui: (self: BuildTools, value: boolean?) -> ();
	toggle_left: (self: BuildTools, shown: boolean) -> ();
	toggle_right: (self: BuildTools, shown: boolean) -> ();
	toggle_top: (self: BuildTools, shown: boolean) -> ();
	init_animation: (self: BuildTools) -> ();
	close_all: (self: BuildTools, to_not_close: unknown) -> ();
	init: (self: BuildTools) -> ();
	init_miscellaneous: (self: BuildTools) -> ();
	is_control_down: (self: BuildTools) -> boolean;
	is_alt_down: (self: BuildTools) -> boolean;
	unbind_action: (self: BuildTools, name: string) -> ();
	
	bind_action_permanent: (
		self: BuildTools, name: string, inputs: {Enum.KeyCode | Enum.UserInputType}, 
		callback: (action_name: string, input_state: Enum.UserInputState, input: InputObject) -> (Enum.ContextActionResult?)) -> ();
	
	bind_action: (
		self: BuildTools, name: string, inputs: {Enum.KeyCode | Enum.UserInputType}, 
		callback: (action_name: string, input_state: Enum.UserInputState, input: InputObject) -> (Enum.ContextActionResult?)) -> ();
	
	load_input_handler: (self: BuildTools) -> ();
	unload_input_handler: (self: BuildTools) -> ();
	init_modifier_displays: (self: BuildTools) -> ();
	init_add_modifier_frame: (self: BuildTools) -> ();
	init_handle_locality_frame: (self: BuildTools) -> ();
	init_tools: (self: BuildTools) -> ();
	init_load_saves: (self: BuildTools) -> ();
	notify: (self: BuildTools, status: number, description: string, duration: number?) -> ();
	load_modifier_frames: (self: BuildTools, selected: {Instance}) -> ();
	init_selection_properties: (self: BuildTools) -> ();
	init_automatic_scaling: (self: BuildTools) -> ();
	init_selection_frame: (self: BuildTools) -> ();
	init_flight: (self: BuildTools) -> ();
	init_instance_picker: (self: BuildTools) -> ();
	destroy: (self: BuildTools) -> ();
	get_instances_in_bounds_of_explorer: (self: BuildTools, rect: Rect) -> {Instance};
	begin_contextual_input: (self: BuildTools) -> ();
	begin_gap_fill_input: (self: BuildTools) -> ();
	begin_selection_input: (self: BuildTools, is_control_down: boolean, is_alt_down: boolean) -> ();
	save_selected_to_hotbar: (self: BuildTools) -> ();
	round_to_move_increment: <T>(self: BuildTools, value: T) -> number | Vector3 | CFrame;
	round_to_rotate_increment: (self: BuildTools, value: number) -> number;
	set_move_increment: (self: BuildTools, increment: number) -> ();
	set_rotate_increment: (self: BuildTools, increment: number) -> ();
	set_tool_mode: (self: BuildTools, mode: Enum.RibbonTool) -> ();
	is_gpad_interact_down: (self: BuildTools) -> boolean;
	is_interact: (self: BuildTools, input: InputObject) -> boolean;
	get_alternative_processed: (self: BuildTools) -> boolean;
	cycle_tool_mode: (self: BuildTools, value: number) -> ();
	cycle_alter_mode: (self: BuildTools, value: number) -> ();
	set_modifiers_visible: (self: BuildTools, value: boolean) -> ();
};

export type BuildTools = typeof(setmetatable({} :: {
	ui: typeof(script.Parent);
	
	maid: Maid.Maid;
	toggle_maid: Maid.Maid;
	input_maid: Maid.Maid;
	
	selection: Selection.Selection;
	draggers: Draggers.Draggers;
	hue_picker: HuePicker.HuePicker;
	actions: Actions.Actions;
	load_save: LoadSave.LoadSave;

	enabled: boolean;
	left_body_enabled: boolean;
	right_body_enabled: boolean;
	top_body_enabled: boolean;
	smaller_interface: boolean;
	
	sim_alt_down: boolean;
	sim_control_down: boolean;
	sim_mode: number;
	
	body_tween_info: TweenInfo;

	settings: {
		scale_pivot_by_axis: boolean;
	};
	
}, {} :: ClassBuildTools));

-----------------------------------------------------------------------------------------------------------

local BuildTools = {} :: ClassBuildTools;
BuildTools.__index = BuildTools;

function BuildTools.new(UI)
	assert(UI, "No UI object was passed to BuildTools");
	
	if not Build.stream.is_synchronised then
		task.spawn(Build.stream.synchronise, Build.stream);
	end;
	
	local maid = Maid.new();
	local self = setmetatable(
		{
			ui = UI;
			maid = maid;
			toggle_maid = maid:limb();
			input_maid = maid:limb();
			
			assets = script.Assets;
			sounds = script.Sounds;

			enabled = false;
			left_body_enabled = true;
			right_body_enabled = true;
			top_body_enabled = true;
			bottom_body_enabled = false;
			smaller_interface = false;
			
			sim_alt_down = false;
			sim_control_down = false;
			sim_mode = 1;
			
			body_tween_info = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut);

			settings = {
				scale_pivot_by_axis = false;
			};
		},
		BuildTools);
	
	do
		local InventoryFrame = UI.Inventory.Inventory;
		local InventoryMapPage = InventoryFrame.Menu.Body.Body.MapPage;
		local InventoryItemsPage = InventoryFrame.Menu.Body.Body.InventoryPage;
		
		local HuePicker = script.Assets.HuePicker:Clone();
		HuePicker.Visible = false;
		HuePicker.Parent = UI.Main.BodyRight.Properties.Function;
		
		self.elements = {
			UI = UI;
			Main = UI.Main;
			Shop = UI.Shop;
			Slots = UI.Slots;
			Status = UI.Status;
			Help = UI.Help;
			Left = UI.Main.BodyLeft;
			Right = UI.Main.BodyRight;
			Top = UI.Main.BodyTop;
			Bottom = UI.Inventory.Inventory;
			Explorer = UI.Main.BodyRight.Explorer.Body;
			Properties = UI.Main.BodyRight.Properties.Body;
			Modifiers = UI.Main.BodyRight.Modifiers.Body;
			LinkButtons = UI.Main.BodyLeft.Links;
			ExplorerFraming = UI.Main.BodyRight.Explorer.Body.Body.Body.Body.ScrollingFrame;
			HuePickerFrame = HuePicker;
			PropertiesScrolling = UI.Main.BodyRight.Properties.Body.Body.Body.ScrollingFrame;
			InventoryFrame = InventoryFrame;
			InventoryMapPage = InventoryMapPage;
			InventoryItemsPage = InventoryItemsPage;
		};
	end;
	
	self.modifiers = Modifiers; -- need to port
	self.selection = self.maid:add(Selection.new(self));
	self.actions = self.maid:add(Actions.new(self));
	self.load_save = self.maid:add(LoadSave.new(self));
	self.draggers = self.maid:add(Draggers.new(self, self.selection.extents_part));
	self.hue_picker = self.maid:add(HuePicker.new(self, nil, true));
	self.number_editor = self.maid:add(NumberEditor.new(self));
	self.toolbox = self.maid:add(Toolbox.new(self));
	self.marketplace = self.maid:add(Marketplace.new(self));
	self.inventory = self.maid:add(Inventory.new(self));
	self.placement = self.maid:add(Placement.new(self));
	self.dropdown = self.maid:add(Dropdown.new(self));
	self.preferences = self.maid:add(Preferences.new(self));
	self.confirmations = self.maid:add(Confirmations.new(self))
	self.spawn_insert = self.maid:add(SpawnInsert.new(self));
	self.modifier_insert = self.maid:add(ModifierInsert.new(self));
	self.properties = self.maid:add(Properties.new(self));
	self.status = self.maid:add(Status.new(self));
	self.explorer = self.maid:add(Explorer.new(self));
	self.wizards = self.maid:add(Wizards.new(self));
	self.tool_widget = self.maid:add(ToolWidget.new(self));
	self.skill_builder = self.maid:add(SkillBuilder.new(self));
	
	self.help = self.maid:add(Help.new(self));
	self.hotbar = self.inventory.hotbar;
	
	self:init();
	self:init_animation();
	
	self:toggle_ui(true);
	
	return self;
end;

function BuildTools:toggle_ui(value: boolean?): ()
	if (value == nil) then
		value = not self.enabled;
	end
	
	if self.enabled ~= value then
		self.enabled = value
		self.selection:deselect();
		self.selection:end_multi_selection();
		
		self:toggle_left(self.enabled);
		self:toggle_right(self.enabled);
		self:toggle_top(self.enabled);
		self:toggle_bottom(self.enabled);
		
		self:close_all({});
		self:unload_input_handler();
		self:toggle_context_menu(false);
		self:toggle_add_modifiers_menu(false);
		
		self:set_modifiers_visible(value);
		
		self.selection.hover = nil;
		self.selection:update_hover_box()
		
		self.toggle_maid:clean();
		
		-- Fixes Modal issues, doesn't need to be enabled anyways.
		self.ui.Enabled = false;
		
		if self.enabled then
			SoundService:PlayLocalSound(Sounds.Open);
			
			self:load_input_handler();
		else
			SoundService:PlayLocalSound(Sounds.Close);
			
			--self.toggle_maid:add(task.delay(self.body_tween_info.Time, function()
			--	if not self.enabled then
			--		self.ui.Enabled = false;
			--	end
			--end))
		end;
		
		Build.Bindables.OnToggled:Fire(value);
	end;
end

function BuildTools:get_top_frame_goal(shown: boolean): any
	if shown then
		return {Position = UDim2.new(0.5, 0, 0, 0), AnchorPoint = Vector2.new(0.5, 0)}
	else
		return {Position = UDim2.new(0.5, 0, -0.2, 0), AnchorPoint = Vector2.new(0.5, 1)}
	end
end

function BuildTools:get_bottom_frame_goal(shown: boolean): any
	if shown then
		return {Position = UDim2.new(0.5, 0, 0.975, 0), AnchorPoint = Vector2.new(0.5, 1)}
	else
		return {Position = UDim2.new(0.5, 0, 1.2, 0), AnchorPoint = Vector2.new(0.5, 0)}
	end
end

function BuildTools:get_right_frame_goal(shown: boolean): any
	if shown then
		if self.smaller_interface then
			return {Position = UDim2.new(1, 0, 0, 0), AnchorPoint = Vector2.new(1, 0)};
		end;
		
		return {Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5)}
	else
		return {Position = UDim2.new(1.2, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5)}
	end
end

function BuildTools:get_left_frame_goal(shown: boolean): any
	if shown then
		if self.smaller_interface then
			return {Position = UDim2.new(0, 0, 0, 0), AnchorPoint = Vector2.new(0, 0)};
		end;
		
		return {Position = UDim2.new(0, 0, 0.4,0), AnchorPoint = Vector2.new(0, 0.5)}
	else
		return {Position = UDim2.new(-0.2, 0, 0.4, 0), AnchorPoint = Vector2.new(1, 0.5)}
	end
end


function BuildTools:toggle_left(shown: boolean): ()
	self.left_body_enabled = if shown ~= nil then shown else not self.left_body_enabled;
	self.elements.Left.Visible = true;
	
	local tween_goal = self:get_left_frame_goal(self.left_body_enabled);
	TweenService:Create(self.elements.Left, self.body_tween_info, tween_goal):Play();
end

function BuildTools:toggle_right(shown: boolean): ()
	self.right_body_enabled = if shown ~= nil then shown else not self.right_body_enabled;
	self.elements.Right.Visible = true;
	
	local tween_goal = self:get_right_frame_goal(self.right_body_enabled);
	TweenService:Create(self.elements.Right, self.body_tween_info, tween_goal):Play();
end

function BuildTools:toggle_top(shown: boolean): ()
	self.top_body_enabled = if shown ~= nil then shown else not self.top_body_enabled;
	self.elements.Top.Visible = true;
	
	local tween_goal = self:get_top_frame_goal(self.top_body_enabled);
	TweenService:Create(self.elements.Top, self.body_tween_info, tween_goal):Play();
end

function BuildTools:toggle_bottom(shown: boolean): ()
	self.bottom_body_enabled = if shown ~= nil then shown else not self.bottom_body_enabled;
	self.elements.Bottom.Visible = true;

	local tween_goal = self:get_bottom_frame_goal(self.bottom_body_enabled);
	TweenService:Create(self.elements.Bottom, self.body_tween_info, tween_goal):Play();
end

function BuildTools:init_animation(): ()
	self.left_body_enabled = false;
	self.right_body_enabled = false;
	self.top_body_enabled = false;
	self.bottom_body_enabled = false;
	
	local right, left, top, bottom = 
		self:get_right_frame_goal(false),
		self:get_left_frame_goal(false),
		self:get_top_frame_goal(false),
		self:get_bottom_frame_goal(false)
	
	self.elements.Right.Position = right.Position;
	self.elements.Left.Position = left.Position;
	self.elements.Top.Position = top.Position;
	self.elements.Bottom.Position = bottom.Position;
	
	self.elements.Right.AnchorPoint = right.AnchorPoint;
	self.elements.Left.AnchorPoint = left.AnchorPoint;
	self.elements.Top.AnchorPoint = top.AnchorPoint;
	self.elements.Bottom.AnchorPoint = bottom.AnchorPoint;
	
	self:toggle_right(true);
	self:toggle_left(true);
	self:toggle_top(true);
	self:toggle_bottom(true);

	SoundService:PlayLocalSound(Sounds.Load);
	self:load_input_handler();
end

function BuildTools:toggle_context_menu(value: boolean)
	self.spawn_insert:toggle(value);
end

function BuildTools:toggle_add_modifiers_menu(value: boolean)
	self.modifier_insert:toggle(value);
end

function BuildTools:close_all(to_not_close)
	self.confirmations:cancel();
	
	for _, frame in {self.preferences, self.help, self.load_save, self.inventory, self.marketplace, self.spawn_insert, self.number_editor, self.toolbox, self.modifier_insert, self.skill_builder} do
		if (frame ~= to_not_close) then
			frame:toggle(false);
		end
	end
end

function BuildTools:close_all_property_docks()
	self.hue_picker:toggle(false);
	self.dropdown:unmount();
end

function BuildTools:init(): ()
	self.selection:init();
	self.actions:init();
	self.draggers:init();
	
	self.draggers:set_local_space(true);
	self:set_tool_mode(Enum.RibbonTool.Select);
	
	self:init_load_saves();
	self:init_handle_locality_frame();
	self:init_selection_frame();
	self:init_selection_properties();
	self:init_add_modifier_frame();
	self:init_modifier_displays();
	self:init_automatic_scaling();
	self:init_miscellaneous();
	self:init_instance_picker();
	
	self:bind_action_permanent("BToolsToggle", 
		{
			Schema.CLOSE_UI
		},
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin) then
				self:toggle_ui();
			end;
		end)
end

function BuildTools:init_instance_picker()
	local instance_picker_info = self.status:create_info("Instance Picker is active, select an instance!");

	local selection_box = script.Selection.Assets.HighlightInstanceBox:Clone();
	selection_box.Archivable = false;
	selection_box.Parent = self.ui;

	self.maid:add(Stylus.active_instance_box_changed:Connect(function(box, visible)
		self.selection:set_hover_instance(nil);

		if visible then
			self.status:play_sound(instance_picker_info, NotificationStatus.info);
			self.status:animate_show(instance_picker_info);

			if box.value then
				selection_box.Adornee = box.value;
			end
		else
			self.status:animate_hide(instance_picker_info);
			selection_box.Adornee = nil;
		end
	end));
end;

function BuildTools:init_miscellaneous()
	local frame = self.status:create_info("Press ] to open the build mode, other devices just use the topbar button.");
	self.status:play(frame, NotificationStatus.info, 15);
	
	self.elements.LinkButtons.ClearAll.MouseButton1Click:Connect(function()
		if self.confirmations.active_thread then
			self.confirmations:cancel();
		else
			self:close_all({});
			
			self.confirmations:make_danger("Stop!", "Are you sure you want to <font color='rgb(255,0,0)'>reset everything</font>; deleting all builds and restoring game state. You cannot reverse this action.", function(accepted)
				if not accepted then return end;
				self.actions:clear_all();
			end)
		end
	end)
	
	self.preferences:observe("visualise_modifiers", function(value)
		if self.enabled then
			self:set_modifiers_visible(true);
		end;
	end);
	
	self.preferences:observe("visualise_beams", function(value)
		if self.enabled then
			self:set_modifiers_visible(true);
		end;
	end);
	
	local function update_minimised_ui_mode()
		local camera = workspace.CurrentCamera;
		local is_small = camera.ViewportSize.Y < 720;
		
		if is_small and not self.smaller_interface then
			self.elements.Right.UIAspectRatioConstraint.AspectRatio = 0.6;
			self.elements.Left.UIAspectRatioConstraint.AspectRatio = 0.9;
			self.elements.Left.Icon.Visible = false;
			self.smaller_interface = true;
			
			self:toggle_right(self.right_body_enabled);
			self:toggle_left(self.left_body_enabled);
			
		elseif not is_small and self.smaller_interface then
			self.elements.Right.UIAspectRatioConstraint.AspectRatio = 0.45;
			self.elements.Left.UIAspectRatioConstraint.AspectRatio = 0.75;
			self.elements.Left.Icon.Visible = true;
			self.smaller_interface = false;
			
			self:toggle_right(self.right_body_enabled);
			self:toggle_left(self.left_body_enabled);
		end
	end
	
	update_minimised_ui_mode();
	self.maid:add(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update_minimised_ui_mode))
	
	self.maid:add(Observer.observe_tag("BuildToolsVisible", function(object)
		object.Visible = true;

		return function()
			object.Visible = false;
		end
	end))
end

function BuildTools:is_control_down()
	local left_control = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
	
	if self.sim_control_down and left_control then
		self:cycle_alter_mode(-4);
	end;
	
	return left_control or self.sim_control_down;
end

function BuildTools:is_alt_down()
	local left_alt = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)

	if self.sim_alt_down and left_alt then
		self:cycle_alter_mode(-4);
	end;
	
	return left_alt or self.sim_alt_down;
end

function BuildTools:is_gpad_interact_down(): boolean
	return UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA)
end

function BuildTools:is_interact(input: InputObject): boolean
	return HelpInput.IsInteract(input) and (not HelpInput.UsingGamepad or GamepadService.GamepadCursorEnabled);
end

function BuildTools:unbind_action(name: string): ()
	ContextActionService:UnbindAction(name);
end

type KeyInput = Enum.KeyCode | Enum.UserInputType;

function BuildTools:bind_action_permanent(name: string, inputs: {KeyInput} | KeyInput, callback: (action_name: string, input_state: Enum.UserInputState, input: InputObject) -> (Enum.ContextActionResult?)): ()
	if typeof(inputs) == "table" then
		ContextActionService:BindAction(name, callback, false, unpack(inputs));
	else
		ContextActionService:BindAction(name, callback, false, inputs);
	end;
end

function BuildTools:bind_action(name: string, inputs: {KeyInput} | KeyInput, callback: (action_name: string, input_state: Enum.UserInputState, input: InputObject) -> (Enum.ContextActionResult?)): ()
	if typeof(inputs) == "table" then
		ContextActionService:BindAction(name, callback, false, unpack(inputs));
	else
		ContextActionService:BindAction(name, callback, false, inputs);
	end;
	
	self.input_maid:add(function()
		self:unbind_action(name);
	end)
end

function BuildTools:unload_input_handler()
	self.input_maid:clean();
end

function BuildTools:load_input_handler()
	local handle_pressed = false;
	local is_processed = false;
	local interact_down = false;
	
	local function begin_interact_input(is_control_down, is_alt_down)
		self.selection:update_hover();
		
		if not is_processed and self.preferences:get("auto_close_widgets") then
			self:toggle_context_menu(false);
			self:toggle_add_modifiers_menu(false);
		end;
		
		if Stylus:has_active_instance_box() then
			Stylus:give_instance_buffered(self.selection.hover_instance);
			self.selection:set_hover_instance(nil);
			
			return;
		end
		
		if self.hotbar:is_active() then
			self.selection:move_to_cursor();
			self.placement:place_at_cursor()
		else
			if self.tool_mode ~= Enum.RibbonTool.Transform then
				self:begin_selection_input(is_control_down, is_alt_down);
			else
				self:begin_gap_fill_input()
			end;
		end;
		
		self.selection:update_hover_box();
	end
	
	self.input_maid:add(UserInputService.TouchLongPress:Connect(function(positions, state, processed)
		if not self.selection.is_multiselecting and state == Enum.UserInputState.Begin then
			self.selection:start_multi_selection();
		end;

		self.selection:update_selection_rectangle()
	end))
	
	self.input_maid:add(UserInputService.TouchTap:Connect(function(position, processed)
		handle_pressed = self.draggers:is_touching_handle();
		if processed or handle_pressed or not self.enabled then return end;
		
		begin_interact_input(self:is_control_down(), self:is_alt_down());
	end))
	
	local function interact(action_name, input_state, input)
		if (input_state == Enum.UserInputState.Begin)  then
			interact_down = true;
			
			self.selection:ready_multi_selection()
			self.actions:clear_commit();
			
			if not HelpInput.UsingMobile and not self.draggers:is_touching_handle() then
				local is_control_down = self:is_control_down();
				local is_alt_down = self:is_alt_down();

				begin_interact_input(is_control_down, is_alt_down);
			end;
		end;
		
		return Enum.ContextActionResult.Pass
	end;
	
	local function alter_mode_interact(action_name, input_state, input)
		self.draggers:update_handles();

		return Enum.ContextActionResult.Pass
	end;
	
	self:bind_action("BToolsListenForAlterModes", 
		{
			Enum.KeyCode.LeftControl,
			Enum.KeyCode.RightControl,
			Enum.KeyCode.LeftAlt,
			Enum.KeyCode.RightAlt,
		}, 
		alter_mode_interact)
	
	self:bind_action("BToolsInteract", 
		{
			Enum.UserInputType.MouseButton1, 
			Enum.UserInputType.Touch, 
			Enum.KeyCode.ButtonA,
		}, 
		interact);
	
	self:bind_action("BToolsGamepadToolNext",
		Schema.GPAD_TOOL_NEXT,
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin)  then
				self:cycle_tool_mode(1);
			end;
		end);
	
	self:bind_action("BToolsGamepadToolPrevious",
		Schema.GPAD_TOOL_PREV,
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin)  then
				self:cycle_tool_mode(-1);
			end;
		end);
	
	self:bind_action("BToolsGamepadHotbarNext",
		Schema.GPAD_HOTBAR_NEXT,
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin)  then
				self.hotbar:cycle_slot(1);
			end;
		end);
	
	self:bind_action("BToolsGamepadHotbarPrevious",
		Schema.GPAD_HOTBAR_PREV,
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin)  then
				self.hotbar:cycle_slot(-1);
			end;
		end);
	
	self:bind_action("BToolsGamepadInventory",
		Schema.GPAD_INVENTORY_OPEN,
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin)  then
				self.inventory:toggle();

				if self.inventory.enabled and not GamepadService.GamepadCursorEnabled then
					GamepadService:EnableGamepadCursor(self.elements.InventoryFrame.Menu);

				elseif not self.inventory.enabled and GamepadService.GamepadCursorEnabled then
					GamepadService:DisableGamepadCursor();
				end;
			end;
		end);
	
	self:bind_action("BToolsGamepadAlterSelectMode",
		Schema.GPAD_ALTER_SELECT,
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin)  then
				self:cycle_alter_mode(1);
			end;
		end);
	
	self:bind_action("BToolsGamepadDeselect",
		Schema.GPAD_DESELECT,
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin)  then
				self.selection:deselect();
			end;
		end);
	
	self:bind_action("BToolsInventory",
		Schema.INVENTORY_OPEN,
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin)  then
				self.inventory:toggle();
			end;
		end);
	
	self:bind_action("BToolsRibbonSelect",
		Schema.RIBBON_SELECT,
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin)  then
				self:set_tool_mode(Enum.RibbonTool.Select);
			end;
		end);
	
	self:bind_action("BToolsRibbonMove",
		Schema.RIBBON_MOVE,
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin)  then
				self:set_tool_mode(Enum.RibbonTool.Move);
			end;
		end);
	
	self:bind_action("BToolsRibbonScale",
		Schema.RIBBON_SCALE,
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin)  then
				self:set_tool_mode(Enum.RibbonTool.Scale);
			end;
		end);
	
	self:bind_action("BToolsRibbonRotate",
		Schema.RIBBON_ROTATE,
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin)  then
				self:set_tool_mode(Enum.RibbonTool.Rotate);
			end;
		end);
	
	self:bind_action("BToolsRibbonGapfill",
		Schema.RIBBON_GAPFILL,
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin)  then
				self:set_tool_mode(Enum.RibbonTool.Transform);
				self.selection:deselect();
			end;
		end);
	
	self:bind_action("BToolsRibbonVoxel",
		Schema.RIBBON_VOXEL,
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin)  then
				self:set_tool_mode(Enum.RibbonTool.PivotEditor);
				self.selection:deselect();
			end;
		end);
	
	self:bind_action("BToolsDeselect",
		Schema.DESELECT_ALL,
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin)  then
				self.selection:deselect();
			end;
		end);
	
	self:bind_action("BToolsDelete",
		Schema.DELETE_SELECTED,
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin)  then
				self.actions:delete( self.selection:get() )
			end;
		end);
	
	self:bind_action("BToolsRename",
		Schema.INSTANCE_RENAME,
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin) and self.selection:next() then
				local frame: GuiObject = self.properties:get_property_frame("Name");
				
				if frame then
					local stylus_box = self.properties.items[frame];
					local list: ScrollingFrame = self.properties.list;
					local offset = frame.AbsolutePosition.Y - (list.AbsolutePosition.Y + list.AbsoluteSize.Y // 2);
					
					if math.abs(offset) > list.AbsoluteSize.Y // 3 then
						list.CanvasPosition += Vector2.new(0, offset + 25);
					end;
					
					local highlight = Instance.new("Frame");
					highlight.BackgroundColor3 = Color3.fromRGB(126, 210, 255);
					highlight.BackgroundTransparency = 1;
					highlight.BorderSizePixel = 0;
					highlight.Size = UDim2.fromScale(1, 1);
					highlight.Archivable = false;
					highlight.Name = "Highlight";
					highlight.ZIndex = -1;
					highlight.Parent = stylus_box.instance;
					
					local tween_info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true);
					local tween = TweenService:Create(highlight, tween_info, {BackgroundTransparency = 0.8})
					
					tween.Completed:Once(function()
						highlight:Destroy();
					end);
					
					tween:Play();
					
					stylus_box.text_box.Text = "";
					stylus_box.text_box:CaptureFocus();
				end;
			end;
		end);
	
	local control_down = false;
	
	self:bind_action("BToolsControl",
		{
			Enum.KeyCode.LeftControl
		},
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin)  then
				control_down = true;
				
			elseif (input_state == Enum.UserInputState.End) then
				control_down = false;
			end;
			
			return Enum.ContextActionResult.Pass;
		end);
	
	self.input_maid:add(UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and control_down then
			self:begin_contextual_input();
		end;
	end));
	
	self.input_maid:add(UserInputService.InputEnded:Connect(function(input, processed)
		if HelpInput.IsInteract(input) then
			interact_down = false;
			
			if self.enabled then
				self.selection:end_multi_selection();
				self.actions:act_commit();
			end;
		end
	end))
	
	self.input_maid:add(UserInputService.InputChanged:Connect(function(input, processed)
		--is_processed = processed;
		
		if HelpInput.IsMovement(input) then
			self.selection:update_hover();
		end
	end))
	
	self.input_maid:add(RunService.PostSimulation:Connect(function(dt)
		if is_processed or self.draggers:is_touching_handle() or not self.enabled then return end;
		
		if Stylus:has_active_instance_box() then
			return self.selection:set_hover_to_stylus_instance();
		end;
		
		if self.hotbar:is_active() then
			return self.selection:move_to_cursor();
		end;
		
		if not HelpInput.UsingMobile and interact_down then
			local cursor_position = UserInputService:GetMouseLocation();
			
			if 
				(self.tool_mode == Enum.RibbonTool.Select or not self.preferences:get("only_select_tool_can_drag"))
				and not self.selection.is_multiselecting
				and not self.selection:is_drag_detector_enabled()
				and self.selection.drag_start
				and ( self.selection.allow_dragging and(cursor_position - self.selection.drag_start).Magnitude > 12 )
			then
				self.selection:move_to_cursor();
				
			elseif self.selection.is_multiselecting then
				self.selection:update_selection_rectangle()
				
			end;
		end;
		
		if self.tool_mode == Enum.RibbonTool.Transform then
			return self.selection:update_hover_edge();
		end;
	end))
end

function BuildTools:init_modifier_displays()
	
	Modifiers.bind_to_data_load(function()
		
		self.maid:add(Observer.observe_tag_at("InstanceModifier", workspace, function(modifier: Configuration)
			local modifier = Modifiers.new(self, modifier);
			
			return function()
				modifier:destroy();
				modifier = nil;
			end
		end))
	end)
end

function BuildTools:init_add_modifier_frame()
	Modifiers.request();
end

function BuildTools:init_handle_locality_frame()

end


	--do
	--	local dark_alignment_color = ColorSequence.new(Color3.fromRGB(128, 128, 128));
	--	local bright_alignment_color = ColorSequence.new(Color3.fromRGB(255, 255, 255));
	--	local dark_alignment_transparency = NumberSequence.new(0.5);
	--	local bright_alignment_transparency = NumberSequence.new(0);

	--	local function update_alignment(mode)
	--		pivot_to_alignment.UIGradient.Color = dark_alignment_color
	--		pivot_to_alignment.UIGradient.Transparency = dark_alignment_transparency;
	--		adjusted_pivot_to_alignment.UIGradient.Transparency = dark_alignment_transparency;
	--		adjusted_pivot_to_alignment.UIGradient.Color = dark_alignment_color
			
	--		if mode == "Pivot" then
	--			pivot_to_alignment.UIGradient.Color = bright_alignment_color
	--			pivot_to_alignment.UIGradient.Transparency = bright_alignment_transparency

	--		elseif mode == "FacePivot" then
	--			adjusted_pivot_to_alignment.UIGradient.Color = bright_alignment_color
	--			adjusted_pivot_to_alignment.UIGradient.Transparency = bright_alignment_transparency
	--		end
	--	end

	--	update_alignment(self.draggers.alignment_mode);
	--	self.draggers.alignment_changed:Connect(update_alignment);
	--end;

function BuildTools:init_load_saves()
	self.maid:add(Remotes.Notify.OnClientEvent:Connect(function(status, description, duration)
		self:notify(status, description, duration);
	end))
	
	self.slots = {};
	
	self.maid:add(Build.stream:observe_table({"Slots"}, function(id, slot)
		self.slots[id] = slot;
		self.load_save:create_slot(id)
	end))
end

function BuildTools:get_alternative_processed(): boolean
	local inset = GuiService:GetGuiInset();
	local position = UserInputService:GetMouseLocation() - inset;
	
	for _, frame in PlayerGui:GetGuiObjectsAtPosition(position.X, position.Y) do
		if frame:IsA("GuiObject") and frame:IsDescendantOf(self.ui) then
			return true;
		end;
	end;
	
	return false;
end

function BuildTools:notify(status, description, duration)
	if typeof(status) == "string" then
		local deb = status;
		status = NotificationStatus[status];
		assert(status, `{deb} is not a valid status string`);
	end;
	
	local frame = self.status:create_from_status(status, description);
	self.status:play(frame, status, duration or 10);
end

function BuildTools:load_modifier_frames(selected)
	local active_children = {};
	local to_listen = {};
	
	if #selected == 1 then
		for _, instance in selected[1]:GetChildren() do
			if not instance:HasTag("InstanceModifier") then
				continue;
			end;
			
			active_children[instance] = true;
			table.insert(to_listen, instance);
			
			if not ModifierFrame.frames[instance] then
				ModifierFrame.new(self, instance, {instance}, #to_listen);
			end;
		end;
		
	elseif #selected >= 2 then
		local active_frame_types: {[string]: {Instance}} = {};
		
		for _, object in selected do
			for _, instance in object:GetChildren() do
				if not instance:HasTag("InstanceModifier") then
					continue;
				end;
				
				local tag = instance:GetAttribute("Modifier") or "Unknown";
				
				if not active_frame_types[tag] then
					active_frame_types[tag] = {instance};
					active_children[instance] = true;
				else
					table.insert(active_frame_types[tag], instance);
				end;
			end;
		end;
		
		for tag_type, instances in active_frame_types do
			table.insert(to_listen, instances[1]);
			ModifierFrame.new(self, instances[1], instances, #to_listen);
		end;
	end;
	
	Remotes.Debugging.SetModifierListen:FireServer(to_listen);
	
	table.clear(ModifierFrame.listen_state_array);
	table.move(to_listen, 1, #to_listen, 1, ModifierFrame.listen_state_array);
	
	for instance in ModifierFrame.frames do
		if not active_children[instance] then
			ModifierFrame.remove_frame(instance);
		end;
	end;
	
	-- This is a fix for mobile users where the list will sink your jump input for whatever reason.
	if next(active_children) then
		self.elements.Modifiers.Canvas.List.Interactable = true;
		self.elements.Modifiers.Canvas.HelpFrame.Visible = false;
	else
		self.elements.Modifiers.Canvas.List.Interactable = false;
		self.elements.Modifiers.Canvas.HelpFrame.Visible = true;
	end
end

function BuildTools:init_automatic_scaling()
	-- Properties Frame
	do
		local PropertiesBody = self.elements.Right.Properties.Body.Body;
		
		Stylus.bind_to_resize(self.elements.Right, function(size)
			PropertiesBody.SearchBox.Size = UDim2.new(1, 0, 0, 6 + size.Y * 0.025);
			PropertiesBody.Title.Size = UDim2.new(1, -2, 0, 6 + size.Y * 0.03);
		end)
		
		Stylus.bind_to_resize(self.elements.Properties, function(size)
			PropertiesBody.SearchBox.TextSize = PropertiesBody.SearchBox.AbsoluteSize.Y * 0.6;
			PropertiesBody.Title.TextSize = PropertiesBody.Title.AbsoluteSize.Y * 0.6;
		end)
	end
	
	-- Explorer Frame
	do
		local ExplorerBody = self.elements.Explorer.Body.Body;
		
		Stylus.bind_to_resize(self.elements.Right, function(size)
			ExplorerBody.SearchBox.Size = UDim2.new(1, 0, 0, 6 + self.elements.Right.AbsoluteSize.Y * 0.025);
			ExplorerBody.Title.Size = UDim2.new(1, -2, 0, 6 + self.elements.Right.AbsoluteSize.Y * 0.03);
		end)
		
		Stylus.bind_to_resize(ExplorerBody, function(size)
			ExplorerBody.SearchBox.TextSize = ExplorerBody.SearchBox.AbsoluteSize.Y * 0.6;
			ExplorerBody.Title.TextSize = ExplorerBody.Title.AbsoluteSize.Y * 0.6;
		end)
	end
end

function BuildTools:init_selection_properties()
	do
		local PropertiesBody = self.elements.Right.Properties.Body.Body;
		
		PropertiesBody.Body.ScrollingFrame.UIPadding:AddTag("UI-Padding");
		self.maid:add(Stylus:bind_hover_highlight(PropertiesBody.SearchBox, {Transparency = 0.95}))
	end;
	
	self.maid:add(self.selection.on_selection_lost:Connect(function()
		self:set_tool_mode(self.tool_mode);
		
		self.elements.Right.Properties.Visible = false;
		self.hue_picker:toggle(false);
		self.elements.Right.Modifiers.Visible = false;
	end))

	self.maid:add(self.selection.on_selection_begin:Connect(function()
		if self.placement:is_active() then return end;
		
		self:set_tool_mode(self.tool_mode);
		
		self.elements.Right.Properties.Visible = true;
		self.elements.Right.Modifiers.Visible = true;
	end))
	
	local last_class: string?;
	local last_child: Instance?;
	
	self.maid:add(self.selection.on_selection_changed:Connect(function()
		local child: Instance? = self.selection:next();
		if not child or self.placement:is_active() then return end;
		
		if (last_child ~= child) then
			local canvas_position = Vector2.zero;
			
			if last_class and child:IsA(last_class) then
				canvas_position = self.properties.list.CanvasPosition;
			end;
			
			debug.profilebegin("Properties Refresh");
			
			self.properties:clear();
			
			for property: string in PropertyUtil.get_properties(child) do
				self.properties:create_property(child, property, child[property])
			end
			
			for isa: string, properties: {any} in pairs(PropertyCustom) do
				if not child:IsA(isa) then continue end;

				for property, data in pairs(properties) do
					self.properties:create_property(child, property, data.Get(child))
				end
			end;
			
			self.properties.list.CanvasPosition = canvas_position;
			
			if child:IsA("BasePart") then
				last_class = "BasePart";
			else
				last_class = child.ClassName;
			end;

			last_child = child;
			debug.profileend();
		end;
		
		self:load_modifier_frames( self.selection:get() );
	end))
	
	self.maid:add(Remotes.Debugging.ModifierStateChange.OnClientEvent:Connect(function(buf: buffer)
		local packet = BufferUtil.new(buf);
		local unit_size = BufferUtil.u8.size * 2;
		local count = (packet.size + 1) // unit_size;
		
		for index = 1, count do
			local identifier = BufferUtil.read_u8(packet);
			local state_value = BufferUtil.read_u8(packet);
			local value = state_value >= 128;
			local state = if value then state_value - 128 else state_value;
			
			local instance = ModifierFrame.listen_state_array[identifier];
			
			if instance then
				local modifier = ModifierFrame.frames[instance];
				local state_name = StateIndex[state];
				
				if modifier and state_name then
					modifier.debug_state[state_name] = value;
					modifier:update_debug_state();
				end;
			end;
		end;
	end))
	
	self.maid:add(self.selection.on_selection_reancestry:Connect(function()
		self:load_modifier_frames( self.selection:get() )
	end))
end

function BuildTools:init_selection_frame()
	local SelectFrame = self.elements.Top.SelectCount;
	local SelectInfo = TweenInfo.new(0.15);
	local SelectLimitInfo = TweenInfo.new(1);
	local SelectOpen = TweenService:Create(SelectFrame.Canvas, SelectInfo, {GroupTransparency = 0, AnchorPoint = Vector2.new(0.5, 0.5)});
	local SelectClose = TweenService:Create(SelectFrame.Canvas, SelectInfo, {GroupTransparency = 1, AnchorPoint = Vector2.new(0.5, 0)});
	local SelectLimit = TweenService:Create(SelectFrame.Canvas, SelectLimitInfo, {GroupColor3 = Color3.fromRGB(255, 83, 83)});
	local SelectUnlimit = TweenService:Create(SelectFrame.Canvas, SelectLimitInfo, {GroupColor3 = Color3.fromRGB(255, 255, 255)});
	
	self.maid:add(self.selection.on_selection_changed:Connect(function()
		local count, max = self.selection.count, self.selection.max;

		SelectFrame.Canvas.Count.Text = `{count}/{max}`;
		SelectFrame.Canvas.BarFrame.Bar.Size = UDim2.fromScale(math.clamp(count / max + (if count > 0 then 0.025 else 0), 0, 1), 1);

		if (count >= max) then
			SelectLimit:Play()
		else
			SelectUnlimit:Play()
		end 
		
		if (count > 0) then
			SelectOpen:Play();
		else
			SelectClose:Play();
		end
	end))
end

function BuildTools:destroy(): ()
	self:toggle_ui(false)
	
	self.selection:destroy(); -- Destroys these in order (the maid wouldve destroyed these anyways)
	self.draggers:destroy();
	self.explorer:destroy();
	
	self.maid:destroy();
	self.ui:Destroy();
	
	Stylus:tween_blur(0);
	
	ModifierFrame.clear();
	
	pcall(self.unbind_action, self, "BToolsToggle")
	
	task.defer(function()
		table.clear(self.elements);
		table.clear(self :: any);
		setmetatable(self :: any, nil);
		
		self.destroyed = true;
	end);
	
	self.destroyed = true;
	
	Build.Bindables.OnDelete:Fire();
end

function BuildTools:get_instances_in_bounds_of_explorer(rect: Rect): {Instance}
	local instances = {};
	local inset = GuiService:GetGuiInset();
	
	local search_is_selective = self.preferences:get("multiselect_only_searched") and self.explorer.is_searching;
	
	for _, item in self.explorer.items do
		if not item:get_ancestry_shown() then continue end;
		
		local pos_up = item.select.AbsolutePosition - inset;
		local pos_down = item.select.AbsolutePosition + item.select.AbsoluteSize - inset;
		
		if 	(
				(pos_up.Y >= rect.Min.Y and pos_up.Y <= rect.Max.Y) or 
				(pos_down.Y >= rect.Min.Y and pos_down.Y <= rect.Max.Y) or
				(pos_up.Y <= rect.Min.Y and pos_down.Y >= rect.Max.Y) 
			)
			and (not search_is_selective or item._searched)
		then
			table.insert(instances, item.instance);
		end;
	end;
	
	return instances;
end

function BuildTools:copy()
	self.actions:copy( self.selection:get() )
	self:notify(NotificationStatus.info, "Copied selection to clipboard", 3)
end

function BuildTools:paste()
	local into = self.selection:next();
	local coordinate = CFrame.identity;
	local result: RaycastResult?;

	if not into or not into:IsA("PVInstance") then
		local camera = workspace.CurrentCamera;
		local cursor_ray = Ray.new(camera.CFrame.Position, camera.CFrame.LookVector);

		result, coordinate = self.selection:cast_ray(cursor_ray, self.raycast_params, 128);
	else
		coordinate = into:GetPivot();
		into = into.Parent;
	end;
	
	self.actions:paste( into, coordinate );
	self:notify(NotificationStatus.info, "Pasted clipboard", 3);
end

function BuildTools:begin_contextual_input(): ()
	if UserInputService:IsKeyDown(Schema.UNDO) then
		
		self.actions:undo();

	elseif UserInputService:IsKeyDown(Schema.REDO) then
		
		self.actions:redo();
		
	elseif UserInputService:IsKeyDown(Schema.CLONE) then
		
		self.actions:clone( self.selection:get() )
		self.selection:deselect();
		
	elseif UserInputService:IsKeyDown(Schema.COPY) then

		self:copy();
		
	elseif UserInputService:IsKeyDown(Schema.PASTE) then
		
		self:paste();
		
	elseif UserInputService:IsKeyDown(Schema.GROUP) then
		
		self.actions:group(self.selection:get())

	elseif UserInputService:IsKeyDown(Schema.RESET_ORIENTATION) then
		
		local function reset(instance: Instance)
			if instance:IsA("PVInstance") then
				instance:PivotTo(CFrame.new(instance:GetPivot().Position))

				self.actions:modify(instance, {CFrame = instance:GetPivot()});
			end
		end

		for instance in self.selection.items do
			reset(instance)
		end;
		
		self.selection:update_extents();
		
	elseif UserInputService:IsKeyDown(Schema.ROTATE) then
		
		self.selection:rotate_by( CFrame.Angles(0, math.rad( self.preferences:get("rotate_shortcut_increment") ), 0) )
		self.actions:act_commit();
		
	elseif UserInputService:IsKeyDown(Schema.TILT) then
		
		self.selection:rotate_by( CFrame.Angles(0, 0, math.rad( self.preferences:get("rotate_shortcut_increment") )) )
		self.actions:act_commit();
		
	elseif UserInputService:IsKeyDown(Schema.LOCAL_SPACE) then
		
		self.draggers:set_local_space();
		
	elseif UserInputService:IsKeyDown(Schema.SAVE_TO_HOTBAR) then
		
		self:save_selected_to_hotbar();
	end;
end

function BuildTools:begin_gap_fill_input()
	if not self.selection.first_edge then
		self.selection:set_first_edge( self.selection:get_hover_edge() )
	else
		local edge_a = self.selection.first_edge;
		local edge_b = self.selection:get_hover_edge()

		if not edge_a or not edge_b then
			return;
		end;

		self.selection:set_first_edge( nil );
		self.actions:gap_fill(edge_a, edge_b, 1, nil, 1);
	end
end

function BuildTools:begin_selection_input(is_control_down: boolean, is_alt_down: boolean): ()
	if self.wizards:is_active() then 
		self.wizards:click();
		
		if self.wizards:is_selection_disabled() then
			return;
		end
	end;
	
	local hover = self.selection.hover;
	
	if hover then
		if not self.selection:is_selected(hover) and not (is_control_down) then
			self.selection:deselect();
		end;
		
		if (is_control_down) and self.selection:is_selected(hover) then
			self.selection:deselect_instance(hover);
		else
			self.selection:select({hover})
		end;
		
	elseif not (is_control_down) and not HelpInput.UsingMobile then
		self.selection:deselect();
	end;
	
	self.selection.allow_dragging = hover ~= nil;
	
	if not HelpInput.UsingMobile then
		if self.selection:is_empty() or (is_control_down) and not hover then
			self.selection:start_multi_selection()
		else
			self.selection:end_multi_selection()
		end
	end;
end

function BuildTools:save_selected_to_hotbar()
	if self.placement:is_active() then
		return self:notify(NotificationStatus.warning, "Unable to save as placement is active", 3);
	end;
	
	local slot = self.hotbar:next();
	local instance = self.selection:next();

	if instance then
		self.hotbar:equip_slot(slot, {reference = instance, model = instance:Clone()})
	else
		self:notify(NotificationStatus.warning, "No object is selected", 3);
	end;
end

function BuildTools:cycle_alter_mode(value: number): ()
	self.sim_mode = math.clamp((self.sim_mode % 4) + value, 1, 4);
	
	self.sim_control_down = self.sim_mode == 2 or self.sim_mode == 4;
	self.sim_alt_down = self.sim_mode == 3 or self.sim_mode == 4;
	
	if self.sim_mode == 1 then
		self:notify(NotificationStatus.info, "Mode: None", 3);
	elseif self.sim_mode == 2 then
		self:notify(NotificationStatus.info, "Mode: Control", 3);
	elseif self.sim_mode == 3 then
		self:notify(NotificationStatus.info, "Mode: Alt", 3);
	elseif self.sim_mode == 4 then
		self:notify(NotificationStatus.info, "Mode: Control + Alt", 3);
	end;
	
	self.draggers:update_handles();
end

function BuildTools:cycle_tool_mode(value: number): ()
	local mode_value = table.find(ALL_TOOL_MODES, self.tool_mode) or 1;
	local new_mode = ALL_TOOL_MODES[math.clamp(mode_value + value, 1, #ALL_TOOL_MODES)]
	
	if new_mode then
		self:set_tool_mode(new_mode);
	end;
end

function BuildTools:set_tool_mode(mode: Enum.RibbonTool): ()
	local last_mode = self.tool_mode;
	
	if last_mode ~= mode then
		self.tool_mode = mode;
		
		if last_mode == Enum.RibbonTool.PivotEditor and self.wizards:is_currently("VoxelBreaker") then
			self.wizards:set(nil);
		end
		
		if mode == Enum.RibbonTool.Transform then
			self:notify(NotificationStatus.info, "Using Gap Fill", 2);
			
		elseif mode == Enum.RibbonTool.PivotEditor then
			self:notify(NotificationStatus.info, "Using Voxel Tool", 2);
			self.wizards:set("VoxelBreaker");
		end;
	end;
	
	self.draggers:set_handle_visible(mode);
	self.selection:hide_hover_edge();
end;

function BuildTools:set_modifiers_visible(value: boolean)
	self.modifiers.set_all_visible(value, self.preferences:get("visualise_modifiers"), self.preferences:get("visualise_beams"));
end

table.freeze(BuildTools);

return BuildTools;