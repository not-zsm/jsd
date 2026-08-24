local replicatedStorage = game:GetService("ReplicatedStorage")
local Packages = replicatedStorage.packages

local Maid = require( Packages.Maid )

export type ClassMovementReplicator = {
	__index: ClassMovementReplicator;

	new: () -> MovementReplicator;
	initialise_events: (self: MovementReplicator) -> ();
	stop_noisy_channel: (self: MovementReplicator) -> ();
	initialise_noisy_channel: (self: MovementReplicator) -> ();
	has_edit_permissions: (self: MovementReplicator, player: Player) -> boolean;
	add_player: (self: MovementReplicator, player: Player) -> ();
	remove_player: (self: MovementReplicator, player: Player) -> ();
	register_replicant: (self: MovementReplicator, replicant: Replicant) -> ();
	unregister_replicant: (self: MovementReplicator, replicant: Replicant) -> ();
	replicate: (self: MovementReplicator, parts: {BasePart}, cframes: {CFrame}) -> ();
	initialise_replication: (self: MovementReplicator) -> ();
	set_runtime_setting: (self: MovementReplicator, setting: string, value: any) -> ();
	toggle_replicator_boxes_visible: (self: MovementReplicator) -> ();
	set_replicator_boxes_visible: (self: MovementReplicator, visible: boolean) -> ();
	get_relimb: (self: MovementReplicator, player: Player, limb_name: string) -> BasePart;
	get_root_part: (self: MovementReplicator, player: Player) -> BasePart;
	get: (self: MovementReplicator, player: Player) -> Replicant;
	get_cframe: (self: MovementReplicator, player: Player, character_part: BasePart) -> CFrame;
	create_resimulated: (self: MovementReplicator, character: Model, dummy_mode: boolean?) -> ();
	create_replicator_remote: (self: MovementReplicator, parent: Instance) -> UnreliableRemoteEvent;
};

export type MovementReplicator = typeof(setmetatable({} :: {
	maid: Maid.Maid;
	replicants: {[Player]: Replicant};
	active_replicants: {[Player]: Replicant};
	identities: {[number]: number};
	
	last_replication: number;
	pause_replication: boolean;
	
}, {} :: ClassMovementReplicator));

export type ClassReplicant = {
	__index: ClassReplicant;

	new: (MovementReplicator: MovementReplicator, player: Player) -> Replicant;
	initialise_events: (self: Replicant) -> ();
	initialise_debug: (self: Replicant) -> ();
	destroy: (self: Replicant) -> ();
	disable: (self: Replicant) -> ();
	enable: (self: Replicant) -> ();
	is_enabled: (self: Replicant) -> ();
	character_added: (self: Replicant, character: Model) -> ();
};

export type Replicant = typeof(setmetatable({} :: {
	character_maid: Maid.Maid;
	maid: Maid.Maid;	
	player: Player;
	movement_replicator: MovementReplicator;
	
	target_cframe: CFrame;
	target_velocity: Vector3;
	identity: number;

	resimulated: {[string]: BasePart};
	limbs: {[string]: BasePart};
	proximity_list: {[Replicant]: boolean};

	is_replicating: boolean;

	last_replication: number;
	last_proximity: number;
	replication_tick: number;
	
}, {} :: ClassReplicant));

return {};