return {
	use_replicator = true; -- Master switch to enable/disable
	
	-- General
	replication_tick = 1 / 40; -- The rate at which the replicator parts update at (1 / per second). Recommended to be atleast above 20 per second.
	ragdoll_replication_tick = 1 / 40; -- The rate at which the replicator updates when ragdolled (1 / per second)
	replicator_bulk_mode = Enum.BulkMoveMode.FireCFrameChanged; -- The mode used when cframing any part
	client_spring_smoothing_speed = 45; 
	-- The client sided smoothing of other replicants, lower values will reduce sharp stuttering. 
	-- Server Hitboxes are unaffected by this. Recommended Range (25 -> 75), Default: 35
	client_spring_damping = 0.85;
	
	use_single_remote_buffer_implementation = false; 
	-- May cause issues! If there is strange behaviour, you could try setting this false.
	-- If set false, A remote event is allocated to every player which controls replication from a client, and to all clients.
	--[[ If set true, It will only fire one remote event to replicate everyone every replication tick to each client.
	 This will significantly reduce the number of remote events being fired every replication tick for high player servers, and may reduce packet loss and network stress.
	 However there is a additional network bandwidth overhead while using this. ]]
	
	-- Features
	replicate_assembly_linear_velocity = true; 
	-- Enables whether it will also replicate assembly linear velocity (only, doesn't include angular velocity), 
	-- Useful for when clients check other clients velocities.
	-- *Note* Increases sent/recv overhead. Only use if you really need this.
	
	use_ghost_linear_velocity_fix = true; 
	-- Sets the Velocities of the HumanoidRootPart to (0, 0, 0) in ghost ragdolls. 
	-- Fixes edge case where a transition between regular ragdoll would cause spazing limbs.
	-- Not strictly nessecary and may cause AssemblyLinearVelocity to be (0, 0, 0) briefly despite movement.
	
	-- Resimulation
	server_character_resimulator = true; -- Resimulates all replicant body parts on the server only. Useful for server-sided hitbox detection.
	server_persistent_resimulator_updates = true; -- Resimulator always updates the CFrames of resimulated parts even if they have not moved, best used if 'only_resimulate_root_part' is false.
	only_resimulate_root_part = false; -- Only resimulates the RootPart if 'server_character_resimulator' is enabled. May provide server performance improvements.
	resimulated_root_part_size = Vector3.zero; -- The size of the resimulated root part. Set to Vector3.zero to leave as root part default.
	resimulation_interpolation_alpha = 1; -- The alpha at which the resimulated parts will be interpolated from non-replicated to replicated positions.
	
	-- Behaviour
	use_physics_based_ragdolls = true; 
	-- Swaps the replicator to use the torso instead of the root part. Allows for possible physics to be simulated on the limbs. If this is off, make sure to disable ragdoll physics joints.
	-- When a ragdoll happens, the replicator will disable and use Roblox's default replicator.
	-- *Note* This will keep the default Roblox replicator always intact. This may increase recv and increase server network stress. Pick your poison 🥰🥀.
	
	use_physical_ghost_rig = true; 
	-- Enables whether clients will use a ghost rig to simulate physics-enabled ragdolls
	-- This also has issues. If a character is ragdolled at very high velocities, the torso may discombobulate away from the limbs for a brief moment
	-- If the velocity to TOO high, the limbs may disconnect until unragdoll.
	
	physical_ghost_rig_lerp_alpha = 0.5;
	-- Controls the smoothness of ghost ragdolls, lower values will smooth it more but motion because less accurate.
	
	replicator_anchors_root_part = true;
	-- Anchors the root part of other clients when they replicate. This fixes the issue of close proximity jittering, however makes it so that other players can much more easily move others.
	
	-- Proximity
	use_proximity = true; -- Master switch the enable/disable the proximity feature for network optimisation.
	proximity_range = 150; -- The range of player-to-player proximity will revert back to Roblox's replicator to save network resources. Recommended >150
	proximity_tick = 1; -- The server tick rate for which proximity is checked for all players.
	
	-- Debugging
	show_replicator_boxes = false; -- Shows the newly replicated server position (red box), and the default Roblox replicator position (yellow box).
	simulate_noisy_channel = false; -- Enables a client sided event dropper for all replicator remotes, allows you to test the client-sided smoothing to fix jitter.
	noisy_channel_stutter_alpha = 0.5; -- The chance (per replication_tick) of a server replication being ignored. Higher values will make other players look more stuttery.
	noisy_channel_drop_alpha = 0.1; -- The chance (per 1/10 of a second) of the replicator dropping out entirely globally.
	noisy_channel_drop_length = NumberRange.new(0.5, 1.5); -- The length of the replicator dropping out.
	
	need_permissions_for_debugger_diagnostic = true; -- Whether the diagnostics client debugger is only shown for those with edit permissions.
	need_permissions_for_replicant_diagnostic = false; -- Whether the diagnostics replicants list is only shown for those with edit permissions.
	
	-- Experimental
	unreliable_payload_byte_split_threshold = 850; -- The payload size required of a unreliable event to be split if 'use_single_remote_buffer_implementation' is enabled. DO NOT put close or above 900.
};