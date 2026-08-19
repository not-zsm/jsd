
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

------------------------------------------------------------

local Pulse = require( script.Pulse );
local InstanceToucher = require( script.Toucher )

local Unpacker = require( "./Unpacker" );
local Serialise = require( "./Serialise" );

local Packages = ReplicatedStorage.Packages;

local Table = require( Packages.Table );
local Maid = require( Packages.Maid );
local Type = require( Packages.Type );
local Instances = require( Packages.Instances );
local Observer = require( Packages.Observer );
local Signal = require( Packages.Signal );
local Attributes = require( Packages.Attributes )
local Debounce = require( Packages.Debounce )
local PropertiesUtil = require( Unpacker.Shared.Data.Properties.Utility );

------------------------------------------------------------

@native local function update_powered_when_ready(self: InstanceModifier)
	if self.update_connection and self.update_connection.Connected then
		self.update_connection:Disconnect();
	end;
	
	if self.destroyed then
		return;
	end;
	
	self.update_connection = RunService.PostSimulation:Once(self._update_power_fn)
end

------------------------------------------------------------

local Vector3Type = Type.Vector3();
local StringType = Type.string();
local IntegerType = Type.integer();

local KeyCodeCycle = {
	Enum.KeyCode.E, Enum.KeyCode.R, Enum.KeyCode.T, 
	Enum.KeyCode.Y, Enum.KeyCode.G, Enum.KeyCode.H
};

local DisallowedKeyCodes = {
	[Enum.KeyCode.W] = true;
	[Enum.KeyCode.A] = true;
	[Enum.KeyCode.S] = true;
	[Enum.KeyCode.D] = true;
};

------------------------------------------------------------

export type ClassInstanceModifier = {
	__index: ClassInstanceModifier;
	
	list: {[Instance]: InstanceModifier};
	instance_modifier_map: {[Instance]: {InstanceModifier}};
	instance_output_map: {[Instance]: {InstanceModifier}};
	instance_id_map: {[number]: {InstanceModifier}};
	
	properties: {[string]: any};
	attribute_updates: {[string]: (value: any, was_init: boolean) -> ()};
	
	find: (name: string) -> ModuleScript;
	get_id_modifiers: (id: number) -> {InstanceModifier};
	get_input_modifiers: (instance: Instance) -> {InstanceModifier};
	get_name_modifiers: (name: string) -> {InstanceModifier};
	get_modifiers: (instance: Instance) -> {InstanceModifier};
	new: (build_handler: any, modifier: Configuration) -> InstanceModifier;
	rebase: (class: any) -> ();
	destroy: (self: InstanceModifier) -> ();
	init: (self: InstanceModifier) -> ();
	update_cache_output_list: (self: InstanceModifier, new: Instance?, old: Instance?) -> ();
	update_cache_instance_list: (self: InstanceModifier, new: Instance?, old: Instance?) -> ();
	get_attribute_type: (self: InstanceModifier, name: string) -> string;
	has_attribute: (self: InstanceModifier, name: string) -> boolean;
	get_list_of_attributes: (self: InstanceModifier) -> {string};
	get_combat: (self: InstanceModifier, instance: Instance) -> any;
	update_input_power_sources: (self: InstanceModifier) -> ();
	initialise_cache_output: (self: InstanceModifier) -> ();
	initialise_attribute_updaters: (self: InstanceModifier) -> ();
	initialise_attribute_listeners: (self: InstanceModifier) -> ();
	initialise_deferred: (self: InstanceModifier) -> ();
	create_active_toucher: (self: InstanceModifier, part: BasePart, touch_callback: (humanoid: Humanoid, touched: boolean) -> ()) -> ();
	create_prompt: (self: InstanceModifier) -> ();
	clear_entities: (self: InstanceModifier) -> ();
	get_pulse_targets_of: (self: InstanceModifier, object: Instance, chain: {[InstanceModifier]: number}) -> {InstanceModifier | Instance};
	get_pulse_targets: (self: InstanceModifier, chain: {[InstanceModifier]: number}?) -> {InstanceModifier | Instance};
	get_output_value: (self: InstanceModifier) -> Instance;
	unpower_from_source: (self: InstanceModifier, modifier: InstanceModifier) -> ();
	power_from_source: (self: InstanceModifier, modifier: InstanceModifier) -> ();
	get_active: (self: InstanceModifier) -> boolean;
	is_actively_powered: (self: InstanceModifier) -> (boolean);
	get_number_of_active_powers: (self: InstanceModifier) -> number;
	update_powered: (self: InstanceModifier) -> ();
	immediate_update_powering_source: (self: InstanceModifier) -> ();
	update_powering_source: (self: InstanceModifier) -> ();
	set_powering: (self: InstanceModifier, value: boolean) -> ();
	_set_powered: (self: InstanceModifier, value: boolean) -> ();
	set_always_active: (self: InstanceModifier, value: boolean) -> ();
	add_humanoid_to_signal: (self: InstanceModifier, humanoid: Humanoid) -> ();
	remove_humanoid_from_signal: (self: InstanceModifier, humanoid: Humanoid) -> ();
	refresh_power: (self: InstanceModifier) -> ();
	pulse: (self: InstanceModifier, signal: unknown, chain: unknown) -> ();
	get_signal: (self: InstanceModifier) -> Pulse.Pulse;
	prompt_trigger: (self: InstanceModifier, combat: unknown) -> ();
	create_target_pulse: (self: InstanceModifier) -> Pulse.Pulse;
	create_pulse: (self: InstanceModifier, combats: unknown) -> ();
	update_attribute: (self: InstanceModifier, attribute: string, value: any) -> ();
	update: (self: InstanceModifier) -> ();
	get_position: (self: InstanceModifier) -> Vector3;
	get_cframe: (self: InstanceModifier) -> CFrame;
	update_prompt_availabilites: (instance: Instance) -> ();
	remove_debounce: (self: InstanceModifier, instance: Instance) -> ();
	add_debounce: (self: InstanceModifier, instance: Instance, duration: number?) -> ();
	has_debounce: (self: InstanceModifier, instance: Instance) -> boolean;
	reset_debounces: (self: InstanceModifier) -> ();
	update_part: (self: InstanceModifier) -> ();
	filter_text: (self: InstanceModifier, text: string, user_id: number?, filter_context: Enum.TextFilterContext?) -> string;
	get_casting_type_dependant: (self: InstanceModifier, property_info: unknown) -> ();
	get_attribute_value: (self: InstanceModifier, attribute: string, proposed_value: any, user_id: number?) -> (boolean, any);
	set_user_attribute: (self: InstanceModifier, attribute: string, proposed_value: any, user_id: number?) -> ();
	prompt_set: (self: InstanceModifier) -> ();
	on_powering_changed: (self: InstanceModifier) -> ();
	on_powered_changed: (self: InstanceModifier) -> ();
	on_active_changed: (self: InstanceModifier) -> ();
};

export type InstanceModifier = typeof(setmetatable({} :: {
	
	build_handler: any;

	maid: Maid.Maid;
	debounces: {[Instance]: thread | boolean};
	attributes: Attributes.Attributes;

	update_maid: Maid.Maid;
	active_maid: Maid.Maid;

	active: boolean;
	powered: boolean;
	powering: boolean;
	
	destroyed: boolean;
	use_prompt: boolean;
	neutral_signal: boolean;
	signal_generator: boolean;
	always_active: boolean;
	short_powered: boolean;
	pulse_on_powered: boolean;
	carry_pulse: boolean;
	pulse_priority: number;
	conflict: boolean;
	
	casting: any;
	
	interest_id: number?;
	prompt: ProximityPrompt?;
	update_connection: RBXScriptConnection?;
	
	entities: {[Instance]: any};
	
	active_signal: Pulse.Pulse;
	active_subscribers: {[InstanceModifier]: boolean};
	active_creator: {[InstanceModifier]: boolean};

	state_changed: Signal.Signal<string, boolean>;
	
	modifier: Configuration;
	part: BasePart;
	object: Instance;
	attachment: Attachment;
	
}, {} :: ClassInstanceModifier));

------------------------------------------------------------

local InstanceModifier = {} :: ClassInstanceModifier;
InstanceModifier.__index = InstanceModifier;
InstanceModifier.list = {};
InstanceModifier.instance_modifier_map = {};
InstanceModifier.instance_output_map = {};
InstanceModifier.instance_id_map = {};
InstanceModifier.attribute_updates = {};
InstanceModifier.on_added = Signal.new();
InstanceModifier.name = string.lower(script.Name);
InstanceModifier.destroyed = false;
InstanceModifier.use_prompt = false;
InstanceModifier.neutral_signal = false;
InstanceModifier.signal_generator = false;
InstanceModifier.active = false; -- if powered will actually enable powered behaviours
InstanceModifier.powered = false; -- if it is powered from outside source
InstanceModifier.powering = false; -- if it will power linked sources
InstanceModifier.always_active = false; -- if powered is always active
InstanceModifier.short_powered = false; -- if true will seperate powering and powered behaviours
InstanceModifier.pulse_on_powered = true;
InstanceModifier.phantom_powering = false; -- Allows modifiers to think they're being powered by a non-powered modifier
InstanceModifier.carry_pulse = false;
InstanceModifier.pulse_priority = 0;
InstanceModifier.properties = {};

do
	local modifiers_list = {};
	local rename_map = {Tween = "Mover", ArrowTrap = "Projectile"};

	for _, child in script.Modifiers:GetChildren() do
		modifiers_list[string.lower(child.Name)] = child;
	end
	
	function InstanceModifier.find(name: string)
		return modifiers_list[string.lower(rename_map[name] or name)];
	end
end;

@native function InstanceModifier.get_id_modifiers(id: number): {any}
	local modifiers_list = InstanceModifier.instance_id_map[id];
	
	if modifiers_list then
		return table.clone(modifiers_list);
	else
		return {};
	end;
end;

@native function InstanceModifier.get_input_modifiers(instance: Instance): {any}
	local modifiers_list = InstanceModifier.instance_output_map[instance];
	
	if modifiers_list then
		return table.clone(modifiers_list);
	else
		return {};
	end;
end

function InstanceModifier.get_name_modifiers(name: string): {any}
	local modifiers_list = {};
	
	for _, modifier in InstanceModifier.list do
		if modifier.object and modifier.object.Name == name then
			table.insert(modifiers_list, modifier);
		end;
	end;
	
	return modifiers_list;
end

@native function InstanceModifier.get_modifiers(instance: Instance): {any}
	local modifiers_list = InstanceModifier.instance_modifier_map[instance];

	if modifiers_list then
		return table.clone(modifiers_list);
	else
		return {};
	end;
end;

function InstanceModifier.new(build_handler: any, modifier: Configuration)
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			modifier = modifier;
			build_handler = build_handler;
			
			maid = maid;
			debounces = maid:add({});
			attributes = maid:add(Attributes.new(modifier));
			
			update_maid = maid:limb();
			active_maid = maid:limb();

			-- i have been awake too long and im so faded dawg ion know whats going on anymore 💔
			active = false; -- if powered will actually enable powered behaviours
			powered = false; -- if it is powered from outside source
			powering = false; -- if it will power linked sources
			conflict = false;
			
			active_signal = Pulse.new();
			active_subscribers = {};
			active_creator = {};
			
			state_changed = maid:add(Signal.new()),
			
			part = nil;
			object = nil;
		} 
		:: any, 
		InstanceModifier);
	
	if InstanceModifier.list[modifier] then
		warn(`Created duplicate modifier for {modifier.Name}, this should not happen :(`);
	end;
	
	InstanceModifier.list[modifier] = self;
	
	maid:add(function()
		InstanceModifier.list[modifier] = nil;
	end)
	
	maid:add(modifier.Destroying:Once(function()
		self:destroy();
	end))
	
	task.defer(self.init, self);
	
	return self;
end;

function InstanceModifier.rebase(class)
	for property, info in class.properties do
		if not info.Type then
			info.Type = Type.define(info.Default);
		end;
	end;
end

function InstanceModifier:destroy(): ()
	if self.destroyed then return end;
	
	Table.nest_remove(InstanceModifier.instance_modifier_map, self.object, self);
	Table.nest_remove(InstanceModifier.instance_output_map, self.object, self);
	
	self:reset_debounces();
	self:_set_powered(false);

	for modifier in self.active_subscribers do
		self:unpower_from_source(modifier);
	end;

	for modifier in self.active_creator do
		modifier:unpower_from_source(self);
	end;

	if self.update_connection then
		self.update_connection:Disconnect();
		self.update_connection = nil;
	end

	if self.prompt then
		self.prompt.Enabled = false;
		self.prompt:Destroy();

		self.update_prompt_availabilites(self.part);
	end;

	self.active_signal:clear();
	self.maid:destroy();

	self.modifier = nil;
	self.part = nil;
	self.object = nil;
	
	table.clear(self.active_subscribers);
	table.clear(self.active_creator);
	
	self.destroyed = true;
end;

function InstanceModifier:init(): ()
	for property, info in self.properties do
		if self.attributes:get(property) == nil then
			if (info.Type._type == "Instance") then
				self.attributes:create(property);
			else
				self.attributes:set(property, info.Default);
			end
		end;
	end
	
	self:update_part();
	self:create_prompt();
	
	if not self.interest_id then
		self.interest_id = self.attributes:get("_InterestId");
	end;
	
	-- self.attributes:remove("_InterestId");
	
	do
		local parent_now = self.modifier.Parent;
		self:update_cache_instance_list(parent_now, nil);

		self.maid:add(self.modifier.AncestryChanged:Connect(function()
			if self.destroyed then return end;
			
			local parent_current = self.modifier.Parent;

			self:update_part();

			if self.prompt then
				self.prompt.Parent = self.part;
				InstanceModifier.update_prompt_availabilites(self.part);
			end;

			self:update();
			self:update_cache_instance_list(parent_current, parent_now);

			parent_now = parent_current;

			if not parent_now then
				self:destroy();
			end 
		end))
	end;
	
	self.maid:add(self.attributes.changed:Connect(function()
		self:update();
	end));
	
	do
		self.attributes:remove("_Powered");
		self.attributes:remove("_Powering");
		self.attributes:remove("_Conflict");

		self._update_power_fn = function()
			self.update_connection = nil;
			self:update_powered();
		end;
	end
	
	self:initialise_attribute_listeners();
	task.defer(self.initialise_deferred, self);
	task.defer(self.update, self);
end

function InstanceModifier:update_cache_output_list(new: Instance?, old: Instance?)
	local output_map = InstanceModifier.instance_output_map;
	
	Table.nest_remove(output_map, old, self);
	Table.nest_add(output_map, new, self);
end

function InstanceModifier:update_cache_instance_list(new: Instance?, old: Instance?)
	local output_map = InstanceModifier.instance_modifier_map;
	
	Table.nest_remove(output_map, old, self);
	Table.nest_add(output_map, new, self);
end

function InstanceModifier:get_attribute_type(name: string): string
	if self.properties[name] then
		return self.properties[name].Type._type;
	end;

	return "nil";
end

function InstanceModifier:has_attribute(name: string): boolean
	return self.properties[name] ~= nil;
end

function InstanceModifier:get_list_of_attributes(): {string}
	local keys = {};

	for key in self.casting._interface do
		table.insert(keys, key);
	end;

	return keys;
end

function InstanceModifier:get_combat(instance: Instance)
	return self.build_handler:get_combat(instance);
end

function InstanceModifier:update_input_power_sources()
	for _, modifier in InstanceModifier.get_input_modifiers(self.object) do
		if not modifier or modifier == self then
			continue; 
		end;

		if modifier.active then
			self:power_from_source(modifier);
			--task.defer(self.power_from_source, self, modifier);
		else
			self:unpower_from_source(modifier);
		end
	end
end

-- Caches output on an instance so that access is O(1)
function InstanceModifier:initialise_cache_output()
	if self:has_attribute("Output") then
		local current = self:get_output_value();
		local object_value = self.attributes:get_object("Output");

		self:update_cache_output_list(current, nil);
		
		if object_value then
			self.maid:add(object_value.Changed:Connect(function()
				local new_current = self:get_output_value();

				if (new_current ~= current) then
					self:update_cache_output_list(new_current, current);
					current = new_current;
				end;
			end))
		end;
	end
end

function InstanceModifier:initialise_attribute_updaters()
	if not self.attribute_updates then return end;

	for attribute, callback in self.attribute_updates do
		self.maid:add(self.attributes:get_changed(attribute):Connect(function(value)
			callback(self, value, false);
		end))

		task.spawn(callback, self, self.attributes:get(attribute), true);
	end
end

function InstanceModifier:initialise_attribute_listeners()
	self.maid:add(self.attributes:get_changed("Output"):Connect(function(value)
		if self.active then
			self:refresh_power();
		end
	end))
end

function InstanceModifier:initialise_deferred()
	local interest_id = self.interest_id;

	for name, property_info in self.properties do
		if interest_id and property_info.Validate then
			local validate_success = property_info.Validate(interest_id, self.attributes:get(name));

			if not validate_success then
				self.attributes:set(name, property_info.Default);
				print(`Invalid value for property {name}: {self.attributes:get(name)}`);
			end;
		end;
	end;

	self:initialise_cache_output();
	self:update_input_power_sources();
	self:initialise_attribute_updaters();
	
	task.defer(function() 
		self:refresh_power() ;
	end);
end

function InstanceModifier:create_active_toucher(part: BasePart, touch_callback: (humanoid: Humanoid, touched: boolean) -> ())
	return InstanceToucher.new(self, part, touch_callback);
end

function InstanceModifier:create_prompt()
	if not self.use_prompt or self.prompt then return end;
	
	self.prompt = self.maid:add(Instance.new("ProximityPrompt"));
	assert(self.prompt);
	
	self.prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton;
	self.prompt.RequiresLineOfSight = false;
	self.prompt.Enabled = false;
	self.prompt.Archivable = false;
	self.prompt.Parent = self.part;
	
	self.maid:add(self.prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
		if self.destroyed then return end;
		--print("yo :(")
		--self.prompt.Parent = if self.prompt.Enabled then self.part else nil;

		InstanceModifier.update_prompt_availabilites(self.part);
	end))

	self.maid:add(self.prompt.Triggered:Connect(function(player)
		if not self.modifier:IsDescendantOf(workspace) then return end;

		local humanoid = player.Character.Humanoid;
		local tag = self.attributes:get("Modifier");
		local combat = self:get_combat(player.Character);

		if combat and not self:has_debounce(humanoid) then
			local debounce = self.attributes:get("Debounce");

			if debounce then
				self:add_debounce(humanoid, debounce);
			else
				self:add_debounce(humanoid, 0.1);
			end;

			self:prompt_trigger(combat);
		end
	end))
end;

function InstanceModifier:clear_entities()
	if not self.entities then return end;

	for entity in self.entities do
		entity:Destroy()
	end;

	table.clear(self.entities);
end;

@native function InstanceModifier:get_pulse_targets_of(object: Instance, chain: {[InstanceModifier]: number}): {InstanceModifier | Instance}
	if not chain then chain = {} end;
	
	local targets: {InstanceModifier | Instance} = {};
	local list = InstanceModifier.get_modifiers(object);
	
	if #list == 0 and (PropertiesUtil.is_property(object, "Enabled") :: boolean) then
		table.insert(targets, object);
	else
		for _, modifier in pairs(list) do
			local chain_depth: number = 0;
			
			if not modifier then continue end;
			if chain[modifier] then chain_depth = chain[modifier]; end;
			
			if chain_depth <= 2 then
				chain[modifier] = chain_depth + 1;
				table.insert(targets, modifier);
			end;
		end;
	end;

	return targets;
end

@native function InstanceModifier:get_pulse_targets(chain)
	return self:get_pulse_targets_of(self:get_output_value(), chain);
end

@native function InstanceModifier:get_output_value()
	local output = self.attributes:get("Output");

	if output then
		return output;
	end;

	return self.object;
end

@native function InstanceModifier:unpower_from_source(modifier)
	if (modifier ~= self) then
		local subscriber = self.active_subscribers[modifier];

		if subscriber then
			modifier.active_creator[self] = nil;
			self.active_subscribers[modifier] = nil;
			
			update_powered_when_ready(self);
		end;
	end;
end

@native function InstanceModifier:power_from_source(modifier): ()
	if (modifier ~= self) then
		if self.active_subscribers[modifier] then
			return;
		end;
		
		modifier.active_creator[self] = true;
		self.active_subscribers[modifier] = true;
		
		if not modifier.neutral_signal then
			self.active_signal:combine(modifier.active_signal);
		end;
		
		task.defer(update_powered_when_ready, self);
	end;
end

@native function InstanceModifier:get_active(): boolean
	return self.active or self.always_active;
end

@native local function being_actively_powered(self: InstanceModifier): boolean
	for other in self.active_subscribers do
		if other.powering or other.phantom_powering then
			return true;
		end;
	end;
	
	return false;
end

@native function InstanceModifier:is_actively_powered(): (boolean)
	-- Just to make sure
	for other in self.active_subscribers do
		if other.destroyed and not other.phantom_powering then
			self.active_subscribers[other] = nil;
		end;
	end;

	return self.always_active or (not self.signal_generator and being_actively_powered(self));
end

@native function InstanceModifier:get_number_of_active_powers(): number
	local count = 0;

	for _ in self.active_subscribers do
		count += 1;
	end;
	
	return count;
end

function InstanceModifier:update_powered(): ()
	local powered = self:is_actively_powered();

	if self.signal_generator then
		local last_conflict = self.conflict;
		local new_conflict = not powered and being_actively_powered(self);

		if last_conflict ~= new_conflict then
			self.conflict = new_conflict;
			self.state_changed:Fire("conflict", new_conflict);
		end;
	end;

	if self.active ~= powered then
		self.active = powered;
		self.active_maid:clean();

		self:_set_powered(powered);
		self:on_active_changed();
	end
end

function InstanceModifier:immediate_update_powering_source()
	self:update_powering_source();
	
	for modifier in self.active_creator do
		if modifier.update_connection then
			modifier.update_connection:Disconnect();
			modifier.update_connection = nil;
		end;
		
		modifier:update_powered();
	end;
end

@native function InstanceModifier:update_powering_source()
	local targets = self:get_pulse_targets();
	local lookup = {};
	
	-- Create fast lookup
	for _, modifier in targets do
		lookup[modifier] = true;
	end;

	-- Unpowers modifiers that are no longer in the pulse targets.
	for modifier in self.active_creator do
		-- Ignore unpowering things that will be powered
		if lookup[modifier] then
			continue;
		end;

		if typeof(modifier) == "Instance" then
			(modifier :: any).Enabled = false;
		else
			modifier:unpower_from_source(self);
		end;
	end;

	for _, modifier in targets do
		if typeof(modifier) == "Instance" then
			(modifier :: any).Enabled = self.powering;
		else
			if self.powering then
				modifier:power_from_source(self)
			else
				modifier:unpower_from_source(self);
			end
		end
	end
end

function InstanceModifier:set_powering(value: boolean)
	--if self.short_powered then return end;

	if self.powering ~= value then
		self.powering = value;
		self.state_changed:Fire("powering", value);

		self:on_powering_changed();
		self:update_powering_source();
	end
end

@native function InstanceModifier:_set_powered(value: boolean)
	if self.powered ~= value then
		self.powered = value;
		self.state_changed:Fire("powered", value);
		
		if not value then
			self.active_signal:clear();
		end;
		
		if not self.short_powered then
			self:set_powering(value);
		end;

		self:update_powered();

		if self.pulse_on_powered and value then
			self:pulse(self:create_target_pulse());
		end;

		self:on_powered_changed();
	end;
end

function InstanceModifier:set_always_active(value: boolean)
	if self.always_active ~= value then
		self.always_active = value;
		self:update_powered();
	end
end

function InstanceModifier:add_humanoid_to_signal(humanoid: Humanoid)
	self.active_signal:add_humanoid(humanoid);
end

function InstanceModifier:remove_humanoid_from_signal(humanoid: Humanoid)
	self.active_signal:remove_humanoid(humanoid);
end

function InstanceModifier:refresh_power()
	self:update_powering_source();
	self:update_powered();
end

@native local function foreach_pulse(self: InstanceModifier, signal: Pulse.Pulse, chain: any)
	for _, modifier in self:get_pulse_targets(chain) do
		modifier:pulse(signal, chain);
	end;
end;

function InstanceModifier:pulse(signal, chain) 
	if not self.carry_pulse then return end;
	if not chain then chain = {}; end;
	
	if self.neutral_signal then
		signal:neutral_clear();
	end
	
	task.defer(foreach_pulse, self, signal, chain);
end;

@native function InstanceModifier:get_signal()
	local pulse = Pulse.copy(self.active_signal);
	
	local seen: {[InstanceModifier]: boolean} = {[self] = true};
	local stack: {InstanceModifier} = {self};
	
	while #stack ~= 0 do
		local item = table.remove(stack);
		
		if not item then break end;
		
		for modifier in item.active_subscribers do
			if seen[modifier] then
				continue;
			end;
			
			seen[modifier] = true;
			
			pulse:combine(modifier.active_signal, modifier.neutral_signal);
			table.insert(stack, modifier);
		end;
	end;
	
	return pulse;
end;

function InstanceModifier:prompt_trigger(combat)
	self:pulse(Pulse.new({combat}));
end

function InstanceModifier:create_target_pulse()
	--local active_signal = self:get_signal();
	
	--local new_pulse = Pulse.new();
	--new_pulse:combine(active_signal);
	
	return self:get_signal();
end

function InstanceModifier:create_pulse(combats)
	return Pulse.new(combats);
end

function InstanceModifier:update_attribute(attribute, value)
	self:update();
end

function InstanceModifier:update()
	self.update_maid:clean();

	local always_active = self.attributes:get("AlwaysActive");

	if always_active ~= nil and self.always_active ~= always_active then
		self:set_always_active(always_active);
	end;
	
	if self.prompt then
		task.spawn(self.prompt_set, self);
	end;
	
	InstanceModifier.update_prompt_availabilites(self.part);
end

function InstanceModifier:get_position()
	return self:get_cframe().Position;
end

function InstanceModifier:get_cframe()
	if self.attachment then
		return self.attachment.WorldCFrame;
	else
		return self.part:GetPivot();
	end;
end

function InstanceModifier.update_prompt_availabilites(instance)
	if not instance then return end;
	assert(instance);
	
	local num_of_prompts = 0;
	
	for _, prompt in instance:GetChildren() do
		if prompt:IsA("ProximityPrompt") and prompt.Enabled then
			num_of_prompts += 1;
			
			local key = KeyCodeCycle[num_of_prompts];
			
			if key then
				prompt.KeyboardKeyCode = key;
				prompt.UIOffset = Vector2.new(0, (num_of_prompts - 1) * 75);
			end;
		end
	end
end

function InstanceModifier:remove_debounce(instance: Instance): ()
	local debounce = self.debounces[instance];
	
	self.debounces[instance] = nil;
	
	if typeof(debounce) == "thread" and coroutine.status(debounce) == "suspended" then
		task.cancel(debounce);
	end;
end

function InstanceModifier:add_debounce(instance: Instance, duration: number?): ()
	self:remove_debounce(instance);
	
	if (duration) then
		duration = math.clamp(duration, 1 / 30, 10_000);
		
		self.debounces[instance] = task.delay(duration, self.remove_debounce, self, instance);
	else
		self.debounces[instance] = true;
	end
end

function InstanceModifier:has_debounce(instance: Instance): boolean
	return self.debounces[instance] ~= nil;
end

function InstanceModifier:reset_debounces(): ()
	for instance in pairs(self.debounces) do
		self:remove_debounce(instance);
	end
end

function InstanceModifier:update_part()
	if not self.modifier then
		return;
	end;
	
	self.part = self.modifier:FindFirstAncestorWhichIsA("BasePart");
	self.object = self.modifier.Parent;
	
	local attachment = self.modifier:FindFirstAncestorWhichIsA("Attachment");
	
	if attachment and self.part and attachment:IsDescendantOf(self.part) then
		self.attachment = attachment;
	else
		self.attachment = nil;
	end
end

function InstanceModifier:filter_text(text: string, user_id: number?, filter_context: Enum.TextFilterContext?): string
	return self.build_handler:filter_text(text, user_id or self.interest_id, filter_context);
end

function InstanceModifier:get_casting_type_dependant(property_info)
	local output = self:get_output_value();
	local depends_on_value = self.attributes:get(property_info.TypeDependant);
	local default_property = Serialise.get_default_property(output.ClassName, depends_on_value);

	return Type.define(default_property);
end

@native function InstanceModifier:get_attribute_value(attribute: string, proposed_value: any, user_id: number?): (boolean, any)
	local property_info = self.properties[attribute];
	local new_value = proposed_value;
	
	if not property_info then
		return false, new_value;
	end
	
	local default_value: any = property_info.Default;
	local caster: any = property_info.Type;

	if property_info.TypeDependant then
		local success, new_caster = pcall(self.get_casting_type_dependant, self, property_info);
		
		if success then
			caster = new_caster;
		end;
	end;

	if not caster then
		return false, new_value;
	end;
	
	if caster._type == "Instance" and (proposed_value == nil) then
		return true, new_value;
	end;
	
	local success, err;
	new_value, success, err = caster:cast(proposed_value)
	
	if success then
		new_value = self.build_handler:sanitize_block(user_id, new_value, property_info);
	else
		new_value = default_value;
	end;
	
	if property_info.Validate then
		local validate_success = property_info.Validate(self.interest_id or user_id, new_value);
		
		if not validate_success then
			return false, new_value;
		end;
	end;
	
	return true, new_value;
end

function InstanceModifier:set_user_attribute(attribute: string, proposed_value: any, user_id: number?): ()
	self:reset_debounces();
	
	local is_valid, new_value = self:get_attribute_value(attribute, proposed_value, user_id);
	
	if not is_valid and user_id then
		local builder = self.build_handler:get_by_userid(user_id);
		
		if builder then
			builder:push_notification(3, `Invalid value`);
		end;
	end;
	
	if is_valid and new_value ~= self.attributes:get(attribute) then
		self.attributes:set(attribute, new_value);
		
		self:update_attribute(attribute, new_value);
		self:update();
	end;
end;

-- Methods that are meant to be overriden by derived classes
function InstanceModifier:prompt_set() end;
function InstanceModifier:on_active_changed() end;
function InstanceModifier:on_powered_changed() end;
function InstanceModifier:on_powering_changed() end;

---------------------------------------------------------------------

for _, module in script.Modifiers:GetChildren() do
	task.defer(require, module);
end

table.freeze(InstanceModifier);

return InstanceModifier;