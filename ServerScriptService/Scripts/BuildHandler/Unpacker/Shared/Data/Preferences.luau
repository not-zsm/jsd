local sections = {
	behaviour = {
		title = "Behaviour";
		order = 0;
	};
	explorer = {
		title = "Explorer";
		order = 1;
	};
	keybinds = {
		title = "Keybinds";
		order = 2;
	};
	viewport = {
		title = "Viewport";
		order = 3;
	};
	miscellaneous = {
		title = "Miscellaneous";
		order = 4;
	};
};

local data = {
	rotate_shortcut_increment = {
		title = "Rotate Bind Increment";
		default = 45;
		section = sections.miscellaneous;
		description = "Changes how much using the rotate keybind (default ctrl+r) will rotate the selection in the Y-axis.";
	};
	use_drag_detectors = {
		title = "Use Drag Detectors";
		default = false;
		section = sections.behaviour;
		description = "Enables the use of drag detectors instead, allows mobile to be able to drag objects, however now requires two clicks for dragging.";
	};
	no_selection_collision = {
		title = "No Selection Collision";
		default = false;
		section = sections.behaviour;
		description = "Disables the collision of your selection with your player character. The default is OFF because this causes selecting to have massive frame hitching depending on the size of what you've selected.";
	};
	only_select_tool_can_drag = {
		title = "Only Select Tool Can Drag",
		default = true;
		section = sections.behaviour;
		description = "Only works on PC and if 'Use Drag Detectors' is OFF. This will allow you use mouse dragging in any ribbon tool mode."
	};
	auto_close_widgets = {
		title = "Auto Close Widgets",
		default = false;
		section = sections.behaviour;
		description = "Enables the automatic closing of Modifier and Insert widgets when clicking off of them.";
	};
	real_time_updates = {
		title = "Real-time Updates",
		default = true;
		section = sections.behaviour;
		description = "Enables the real-time (1/15 of a second) replication to other players of your selection while you are dragging, moving, or scaling objects.";
	};
	hide_builds_folder = {
		title = "Hide Workspace",
		default = false;
		layout_order = 3;
		section = sections.explorer;
		description = "Hides the 'Builds' folder from being displayed in your explorer. This will give you more space in your explorer.";
	};
	multiselect_only_searched = {
		title = "Multi-select affects only searched",
		default = true;
		layout_order = 2;
		section = sections.explorer;
		description = "When using multi-select drag, only instances that match your search will be selected, ignoring unrelated ancestors.";
	};
	explorer_instance_pixel_scale = {
		title = "Pixel Scale",
		default = 16;
		section = sections.explorer;
		description = "Changes how much pixels each explorer instance will take up in your explorer. Lower values will make them smaller, higher values will make them larger.";
	};
	explorer_spacing_pixel_scale = {
		title = "Spacing Scale",
		default = 0;
		section = sections.explorer;
		description = "Changes the spacing of each explorer instance.";
	};
	explorer_expand_pixel_scale = {
		title = "Expand Depth",
		default = 16;
		section = sections.explorer;
		description = "Changes the depth of which children of instance will right shifted along in pixels.";
	};
	move_increment = {
		default = 0.5;
	};
	rotate_increment = {
		default = math.rad(5.625);
	};
	move_increment_enabled = {
		default = true;
	};
	rotate_increment_enabled = {
		default = true;
	};
	visualise_modifiers = {
		title = "Visualise Modifiers",
		default = true;
		layout_order = 10;
		section = sections.viewport;
		description = "Adds visuals on the parts affected by modifiers, just like a certain jujustu game.";
	};
	visualise_beams = {
		title = "Visualise Flow",
		default = true;
		layout_order = 11;
		section = sections.viewport;
		description = "Adds beams on modifiers with 'Output' property to show the direction of flow.";
	};
	compact_scrolling_modifiers = {
		title = "Modifier Scrolling",
		default = false;
		layout_order = 2;
		section = sections.miscellaneous;
		description = "Makes the modifier widgets more compact by enabling scrolling if there is many properties.";
	};
};

---------------------------------------------------------------------------

local defaults = {};

for name, value in data do
	defaults[name] = value.default;
end

return {
	sections = sections;
	data = data,
	defaults = defaults;
}