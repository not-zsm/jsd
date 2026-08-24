local replicatedStorage = game:GetService("ReplicatedStorage")
local Packages = replicatedStorage.packages

local Maid = require( Packages.Maid )
local CFSpring = require( Packages.Spring.CFSpring )
local Signal = require( Packages.Signal )

local BufferUtil = require( Packages.BufferUtil )
local Assets = replicatedStorage.modules.shared.movementReplicator.Assets;

export type ClassReplicant = {
	__index: ClassReplicant;

	new: (MovementReplicator: MovementReplicator, replicator: UnreliableRemoteEvent) -> Replicant;
	destroy: (self: Replicant) -> ();
	initialise_events: (self: Replicant) -> ();
	replicate: (self: Replicant) -> ();
	
	character_added: (self: Replicant, character: Model) -> ();
	read_replicate_buffer: (self: Replicant, replication_buffer: BufferUtil.CursorBuffer) -> (CFrame, Vector3?);
	write_replicate_buffer: (self: Replicant, cframe: CFrame, velocity: Vector3?) -> BufferUtil.CursorBuffer;
};

export type Replicant = typeof(setmetatable({} :: {

	movement_replicator: MovementReplicator;
	last_update: number;
	replication_tick: number;
	last: number;
	spring: CFSpring.CFSpring;
	target_cframe: CFrame;
	target_velocity: Vector3;
	last_replicated_cframe: CFrame;
	last_replicated_velocity: Vector3;
	ragdoll_tp_back: boolean;
	is_disabled: boolean;
	is_ragdolled: boolean;
	in_proximity: boolean;
	root: BasePart;
	torso: BasePart;
	player: Player;
	character: Model;
	replicator: UnreliableRemoteEvent;
	maid: Maid.Maid;
	character_maid: Maid.Maid;
	on_proximity_changed: Signal.Signal<boolean>;
	on_ragdoll_changed: Signal.Signal<boolean>;
	on_destroying: Signal.Signal<>;

}, {} :: ClassReplicant));

export type ClassDiagnostics = {
	__index: ClassDiagnostics;
	
	active_color: Color3;
	inactive_color: Color3;
	info_color: Color3;
	auto_headers_list: {[string]: string};
	header_layout_order: {string};
	
	new: (ClientReplicator: MovementReplicator) -> Diagnostics;
	destroy: (self: Diagnostics) -> ();
	initialise_ui: (self: Diagnostics) -> ();
	destroy_ui: (self: Diagnostics) -> ();
	hook: (self: Diagnostics) -> ();
	toggle: (self: Diagnostics) -> ();
	update_setting: (self: Diagnostics, setting: string, value: any) -> ();
	set_enabled: (self: Diagnostics, value: boolean) -> ();
	
	get_replicant_thumbnail: (self: Diagnostics, replicant: Replicant) -> string?;
	add_replicant: (self: Diagnostics, replicant: Replicant) -> ();
	initialise_replica_stats: (self: Diagnostics) -> ();
	initialise_debugger_stats: (self: Diagnostics) -> ();
	add_proximities_replicant: (self: Diagnostics, replicant: Replicant) -> ();
	set_proximities_enabled: (self: Diagnostics, value: boolean) -> ();
};

export type Diagnostics = typeof(setmetatable({} :: {
	
	client_replicator: MovementReplicator;

	enabled: boolean;
	edit_enabled: boolean;
	proximities_enabled: boolean;
	
	ui: typeof(Assets.UI.Diagnostics);
	
	stat_elements: {[string]: typeof(Assets.UI.Stat)};
	header_elements: {[string]: typeof(Assets.UI.Header)};
	proximity_elements: {[string]: typeof(Assets.UI.ProximityPlayer)};

	maid: Maid.Maid;
	enable_maid: Maid.Maid;
	proximities_maid: Maid.Maid;
	
	on_enabled_changed: Signal.Signal<boolean>;
	
}, {} :: ClassDiagnostics));

export type ClassMovementReplicator = {
	__index: ClassMovementReplicator;

	new: () -> MovementReplicator;
	update_replication: (self: MovementReplicator, dt: number) -> ();
	initialise_movers: (self: MovementReplicator) -> ();
	initialise_listeners: (self: MovementReplicator) -> ();
	
	read_replication_buffer: (self: MovementReplicator) -> {c: CFrame, v: Vector3};
	set_identifiers: (self: MovementReplicator, identifiers: {number}) -> ();
	remove_replicant: (self: MovementReplicator, replicator: Player) -> ();
	add_replicant: (self: MovementReplicator, replicator: Player) -> ();
	update_identifiers: (self: MovementReplicator) -> ();
	set_setting: (self: MovementReplicator, setting: string, value: any) -> ();
};

export type MovementReplicator = typeof(setmetatable({} :: {
	
	replicators: {[Player]: Replicant};
	my_replicators: {[Player]: Replicant};
	other_replicators: {[Player]: Replicant};

	maid: Maid.Maid;
	diagnostics: Diagnostics;

	identifiers: {[number]: number};
	replicant_identifiers: {[number]: Replicant};

	on_replicant_removed: Signal.Signal<Replicant>;
	on_replicant_added: Signal.Signal<Replicant>;

}, {} :: ClassMovementReplicator));

export type KnockerInfo = {
	limb_name: string, 
	tween_info: TweenInfo,
	knock_table: {[string]: number}, 
	property: string;
	value: number;
	debounce: number?;
};

export type ClassPsuedoRagdoll = {
	__index: ClassPsuedoRagdoll;

	new: (character: Model) -> PsuedoRagdoll;
	destroy: (self: PsuedoRagdoll) -> ();
	initialise_joints: (self: PsuedoRagdoll) -> ();
	disable: (self: PsuedoRagdoll) -> ();
	connect_limb_knocker: (self: PsuedoRagdoll, info_table: KnockerInfo) -> ();
	enable: (self: PsuedoRagdoll) -> ();
	set_enabled: (self: PsuedoRagdoll, value: boolean) -> ();
};

export type PsuedoRagdoll = typeof(setmetatable({} :: {

	enabled: boolean;
	character: Model;
	torso: BasePart;
	root: BasePart;
	maid: Maid.Maid;

}, {} :: ClassPsuedoRagdoll));

return {};