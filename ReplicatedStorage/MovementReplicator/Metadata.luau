local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require( ReplicatedStorage.MovementReplicator.Settings )

local sections = {
	replication = {title = "--- Replicator ---", order = 1,};
	proximity = {title = "--- Proximity ---", order = 2,};
	resimulator = {title = "--- Resimulator ---", order = 3,};
	ragdoll = {title = "--- Ragdoll ---", order = 4,};
	debugging = {title = "--- Debugging ---", order = 5,};
	miscellaneous = {title = "--- Miscellaneous ---", order = 6,};
};

local data = {
	use_replicator = {
		order = 1;
		can_edit = true;
		section = sections.replication;
		updates = {replication_tick = true, anchor = true, replicator_boxes = true, ghost_rig = true};
	};
	replication_tick = {
		order = 2;
		can_edit = true;
		section = sections.replication;
		updates = {replication_tick = true, replicator_boxes = true};
	};
	ragdoll_replication_tick = {
		order = 3;
		can_edit = true;
		section = sections.replication;
		updates = {replication_tick = true, replicator_boxes = true};
	};
	replicator_bulk_mode = {
		section = sections.replication;
		updates = {replication_tick = true};
	};
	client_spring_smoothing_speed = {
		can_edit = true;
		section = sections.replication;
		updates = {replication_tick = true};
	};
	client_spring_damping = {
		can_edit = true;
		section = sections.replication;
		updates = {replication_tick = true};
	};
	use_single_remote_buffer_implementation = {
		can_edit = true;
		section = sections.miscellaneous;
	};
	replicate_assembly_linear_velocity = {
		can_edit = true;
		section = sections.replication;
	};
	use_ghost_linear_velocity_fix = {
		can_edit = true,
		section = sections.miscellaneous;
	};
	server_character_resimulator = {
		section = sections.resimulator;
	};
	server_persistent_resimulator_updates = {
		can_edit = true;
		section = sections.resimulator;
	};
	only_resimulate_root_part = {
		section = sections.resimulator;
	};
	resimulated_root_part_size = {
		can_edit = true;
		section = sections.resimulator;
	};
	resimulation_interpolation_alpha = {
		can_edit = true;
		section = sections.resimulator;
	};
	use_physics_based_ragdolls = {
		can_edit = true;
		section = sections.ragdoll;
	};
	use_physical_ghost_rig = {
		can_edit = true;
		section = sections.ragdoll;
		updates = {ghost_rig = true};
	};
	physical_ghost_rig_lerp_alpha = {
		can_edit = true;
		section = sections.ragdoll;
		updates = {ghost_rig = true};
	};
	replicator_anchors_root_part = {
		can_edit = true;
		section = sections.replication;
		updates = {anchor = true};
	};
	use_proximity = {
		order = 1;
		can_edit = true;
		section = sections.proximity;
		updates = {proximity = true};
	};
	proximity_range = {
		can_edit = true;
		section = sections.proximity;
	};
	proximity_tick = {
		can_edit = true;
		section = sections.proximity;
	};
	show_replicator_boxes = {
		order = 1;
		can_edit = true;
		section = sections.debugging;
		updates = {replicator_boxes = true};
	};
	simulate_noisy_channel = {
		order = 2;
		can_edit = true;
		section = sections.debugging;
		updates = {noisy_channel = true};
	};
	noisy_channel_stutter_alpha = {
		can_edit = true;
		section = sections.debugging;
		updates = {noisy_channel = true};
	};
	noisy_channel_drop_alpha = {
		can_edit = true;
		section = sections.debugging;
		updates = {noisy_channel = true};
	};
	noisy_channel_drop_length = {
		can_edit = true;
		section = sections.debugging;
		updates = {noisy_channel = true};
	};
	need_permissions_for_debugger_diagnostic = {
		can_edit = true;
		section = sections.debugging;
	};
	need_permissions_for_replicant_diagnostic = {
		can_edit = true;
		section = sections.debugging;
	};
	unreliable_payload_byte_split_threshold = {
		section = sections.miscellaneous;
	};
};

local auto_headers_list = {
	replicat = sections.replication;
	proximity = sections.proximity;
	resimulat = sections.resimulator;
	noisy = sections.debugging;
	ragdoll = sections.ragdoll;
	physic = sections.ragdoll;
};

local function get_best_header(setting: string)
	for header, title in auto_headers_list do
		if string.find(setting, header) then
			return title;
		end
	end
	
	return sections.miscellaneous;
end

for setting, value in Settings do
	local dataset = data[setting];
	
	if not data[setting] then
		dataset = {};
		data[setting] = dataset;
	end;
	
	if not dataset.section then
		dataset.section = get_best_header(setting);
	end
	
	if not dataset.updates then
		dataset.updates = {};
	end;
end

return data;