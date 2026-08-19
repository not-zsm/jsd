--!native
--!strict

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

---------------------------------------------------------------------

local IsStudio = RunService:IsStudio();
local WeakKeys = {__mode = "k"};

---------------------------------------------------------------------

export type ClassPulse = {
	__index: ClassPulse;
	
	build_handler: any;
	
	new: (combats: {any}?) -> Pulse;
	copy: (Pulse) -> Pulse;
	destroy: (self: Pulse) -> ();
	clear: (self: Pulse) -> ();
	neutral_clear: (self: Pulse) -> ();
	combine: (self: Pulse, other_pulse: Pulse, neutral: boolean?) -> ();
	
	notify_builders: (self: Pulse, status: string | number, description: string, duration: number?) -> ();
	
	get_players: (self: Pulse) -> {Player};
	get_humanoids: (self: Pulse) -> {Humanoid};
	get_combats: (self: Pulse) -> {any};
	
	add_humanoid: (self: Pulse, humanoid: Humanoid) -> ();
	add_combat: (self: Pulse, combat: any) -> ();
	
	remove_humanoid: (self: Pulse, humanoid: Humanoid) -> ();
	remove_combat: (self: Pulse, combat: any) -> ();
};

export type Pulse = typeof(setmetatable({} :: {
	coordinate: CFrame?,
	combats: {[any]: boolean};
	combat_count: number;
	humanoid_cache: typeof(setmetatable({} :: {[Humanoid]: any}, WeakKeys))?;
	
}, {} :: ClassPulse));

---------------------------------------------------------------------

local Pulse = {} :: ClassPulse;
Pulse.__index = Pulse;
Pulse.build_handler = nil :: any;

function Pulse.new(combats)
	local self: Pulse = setmetatable(
		{
			coordinate = nil;
			humanoid_cache = nil;
			combats = {};
			combat_count = 0;
		} :: any, 
		Pulse);
	
	if combats then
		for _, combat in combats do
			self:add_combat(combat);
		end;
	end;
	
	return self;
end;

function Pulse.copy(pulse)
	local self = setmetatable(
		{
			coordinate = pulse.coordinate;
			combats = table.clone(pulse.combats);
			combat_count = pulse.combat_count;
		},
		Pulse);
	
	return self;
end

---------------------------------------------------------------------

function Pulse:destroy()
	self:clear();
end

function Pulse:clear(): ()
	self.coordinate = nil;
	self:neutral_clear();
end;

function Pulse:neutral_clear(): ()
	self.combat_count = 0;
	
	table.clear(self.combats);
	
	if self.humanoid_cache then
		table.clear(self.humanoid_cache :: any);
		self.humanoid_cache = nil;
	end
end

function Pulse:add_humanoid(humanoid: Humanoid): ()
	local combat = Pulse.build_handler:get_combat(humanoid.Parent);
	
	if combat then
		if not self.humanoid_cache then
			self.humanoid_cache = setmetatable({}, WeakKeys);
		end;
		
		assert(self.humanoid_cache, "No humanoid cache");
		
		self.humanoid_cache[humanoid] = combat;
		self:add_combat(combat);
	end;
end;

function Pulse:remove_humanoid(humanoid: Humanoid): ()
	if self.humanoid_cache and self.humanoid_cache[humanoid] then
		self:remove_combat( self.humanoid_cache[humanoid] );
	else
		self:remove_combat( Pulse.build_handler:get_combat(humanoid.Parent) );
	end;
end;

function Pulse:add_combat(combat): ()
	if combat and not self.combats[combat] then
		self.combat_count += 1;
		self.combats[combat] = true;
	end;
end;

function Pulse:remove_combat(combat: any): ()
	if combat and self.combats[combat] then
		self.combat_count -= 1;
		self.combats[combat] = nil;
	end;
end;

function Pulse:combine(other_pulse: Pulse, neutral: boolean?): ()
	if not self.coordinate then
		self.coordinate = other_pulse.coordinate;
	end;
	
	if not neutral then
		for combat in other_pulse.combats do
			self:add_combat(combat);
		end;
	end;
end;

function Pulse:get_players(): {Player}
	local players = table.create(self.combat_count) :: {Player};
	
	for _, combat in self:get_combats() do
		local player: Player = combat:get_player();
		
		if player then
			table.insert(players, player);
		end;
	end;
	
	return players;
end;

function Pulse:get_humanoids(): {Humanoid}
	local humanoids = table.create(self.combat_count) :: {Humanoid};
	
	for combat in self.combats do
		local humanoid: Humanoid = combat:get_humanoid();
		
		if humanoid then
			table.insert(humanoids, humanoid);
		end;
	end;
	
	return humanoids;
end;

function Pulse:get_combats(): {any}
	assert(Pulse.build_handler, "No BuildHandler :3");
	
	local combats: {any} = table.create(self.combat_count);
	
	for combat in self.combats do
		table.insert(combats, combat);
	end;
	
	return combats;
end;

function Pulse:notify_builders(status: string | number, description: string, duration: number?): ()
	for combat in self.combats do
		combat:notify_builder(status, description, duration);
	end;
end;

---------------------------------------------------------------------

--table.freeze(Pulse);

return Pulse;