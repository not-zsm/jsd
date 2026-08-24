local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

---------------------------------------------------------------------------------

local Player = Players.LocalPlayer;
local PlayerGui = Player:WaitForChild("PlayerGui");

local Shared = replicatedStorage.modules.shared.movementReplicator
local Remotes = Shared:WaitForChild("Remotes");
local Assets = Shared:WaitForChild("Assets");

---------------------------------------------------------------------------------

local Packages = replicatedStorage.packages

local Maid = require( Packages.Maid )
local Signal = require( Packages.Signal )
local BufferUtil = require( Packages.BufferUtil )

local Settings = require( replicatedStorage.modules.shared.movementReplicator.Settings )
local Metadata = require( replicatedStorage.modules.shared.movementReplicator.Metadata )

local Diagnostics = require( script.Diagnostics )
local Types = require( script.Types );
local Replicant = require( script.Replicant )

---------------------------------------------------------------------------------

---------------------------------------------------------------------------------

local MovementReplicator = {} :: Types.ClassMovementReplicator;
MovementReplicator.__index = MovementReplicator;

---------------------------------------------------------------------------------

function MovementReplicator.new()
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			maid = maid;
			diagnostics = nil;
			
			replicators = {};
			my_replicators = {};
			other_replicators = {};

			parts = {};
			cframes = {};
			
			identifiers = {};
			uids = {};
			replicant_identifiers = {};
			
			on_replicant_removed = maid:add(Signal.new());
			on_replicant_added = maid:add(Signal.new());
		}, 
		MovementReplicator);
	
	self.diagnostics = Diagnostics.new(self);
	
	if Settings.use_replicator then
		self:initialise_listeners();
		self:initialise_movers();
	end;
	
	return self;
end;

---------------------------------------------------------------------------------


---- Used if 'use_single_remote_buffer_implementation' is enabled
--function MovementReplicator:read_replication_buffer()
--	local replication_buffer = self.replication_buffer;
--	local identifier: number, cframe: CFrame, velocity: Vector3;
--	local formatted = {};
	
--	local cursor_bound = 16;
	
--	if Settings.replicate_assembly_linear_velocity then
--		cursor_bound += 12;
--	end;
	
--	while replication_buffer.cursor + cursor_bound < replication_buffer.size do
--		identifier = BufferUtil.read_i8(replication_buffer);
--		cframe = BufferUtil.read_cframe(replication_buffer);
		
--		if Settings.replicate_assembly_linear_velocity then
--			velocity = BufferUtil.read_vector3(replication_buffer);
--		end;
		
--		if self.identifiers[identifier] then
--			formatted[identifier] = {c = cframe, v = velocity};
--		end
--	end
	
--	self.replication_buffer = nil;
	
--	return formatted;
--end

-- Used if 'use_single_remote_buffer_implementation' is enabled
function MovementReplicator:read_replication_buffer()
	local replication_buffer = self.replication_buffer;
	local identifier: number, cframe: CFrame, velocity: Vector3;
	local formatted = {};

    --[[ 
        15 = CFrame buffer size
        1 = Identifier size
        12 = Vector3 size 
    ]]
	local cursor_bound = 15 + 1;

	if Settings.replicate_assembly_linear_velocity then
		cursor_bound += 12;
	end;

	while replication_buffer.cursor + cursor_bound <= replication_buffer.size do
		identifier = BufferUtil.read_i8(replication_buffer);
		cframe = BufferUtil.read_cframe(replication_buffer);

		if Settings.replicate_assembly_linear_velocity then
			velocity = BufferUtil.read_vector3(replication_buffer);
		end;

		if self.identifiers[identifier] then
			formatted[identifier] = {c = cframe, v = velocity};
		end
	end

	self.replication_buffer = nil;

	return formatted;
end


-- The step loop body to update every other replicants position, and to replicate my own position to the server.
function MovementReplicator:update_replication(dt: number): ()
	if not Settings.use_replicator then return end;
	
	local time_now = tick();

	local parts: {BasePart} = self.parts;
	local cframes: {CFrame} = self.cframes;

	table.clear(parts);
	table.clear(cframes);

	for player, replicant in self.other_replicators do
		-- I have HAD it !!! no more games 🔥
		local success, err = pcall(replicant.update_replication, replicant, time_now, dt, parts, cframes);

		if not success and replicant.player then
			warn(`Client error for replicator '{replicant.player.Name}':`, err);
		end
	end

	self.replication_buffer = nil;

	-- More performant than setting .CFrame on every replicator individually.
	workspace:BulkMoveTo(parts, cframes, Settings.replicator_bulk_mode);

	-- This is after the BulkMoveTo so that if this somehow errors, the replicator will still replicate others.
	for player, replicant in self.my_replicators do
		-- Replicates every replication tick and stops replication is the root hasnt moved since the last send replication.
		if replicant.is_ready and time_now - replicant.last_update > replicant.replication_tick and (replicant.need_update or not replicant.last_replicated_cframe:FuzzyEq(replicant.root.CFrame)) then
			replicant.last_update = time_now;
			replicant.need_update = false;
			replicant:replicate()
		end;
	end;
end


function MovementReplicator:initialise_movers()
	self.maid:add(RunService.PreAnimation:Connect(function(dt)
		self:update_replication(dt);
	end))
end


function MovementReplicator:update_identifiers()
	table.clear(self.replicant_identifiers);
	
	for player, replicant in self.replicators do
		local identifier = self.uids[player.UserId];

		if identifier then
			replicant.identifier = identifier;
			self.replicant_identifiers[identifier] = replicant;
		else
			replicant.identifier = nil;
		end;
	end;
end


function MovementReplicator:set_identifiers(identifiers)
	for id, user_id in self.identifiers do
		if not identifiers[id] then
			self.identifiers[id] = nil;
			self.uids[user_id] = nil;
		end;
	end;
	
	for id, user_id in identifiers do
		self.identifiers[id] = user_id;
		self.uids[user_id] = id;
	end
	
	self:update_identifiers();
end


function MovementReplicator:set_setting(setting: string, value: any): ()
	Settings[setting] = value;
	self.diagnostics:update_setting(setting, value);
	
	local metadata = Metadata[setting];
	
	if metadata.updates.replication_tick then
		for player, replicant in self.replicators do
			replicant.replication_tick = Settings.replication_tick;
		end;
	end
	
	if metadata.updates.anchor then
		for player, replicant in self.replicators do
			replicant:update_anchor(true);
		end;
	end
	
	if metadata.updates.ghost_rig then
		if Settings.use_physical_ghost_rig and Settings.use_replicator then
			for player, replicant in self.replicators do
				replicant:initialise_ghost();
			end;
		else
			for player, replicant in self.replicators do
				replicant:remove_ghost();
			end;
		end
	end
	
	if metadata.updates.proximity then
		for player, replicant in self.replicators do
			replicant:set_in_proximity(true);
		end;
	end
end


function MovementReplicator:remove_replicant(player)
	local replicant = self.replicators[player];

	if replicant then
		replicant:destroy();
		
		self.on_replicant_removed:Fire(replicant);
		self:update_identifiers();
	end;
end


function MovementReplicator:add_replicant(player)
	local all_replicators_table = self.replicators;
	local replicators_table = self.my_replicators;

	if player ~= Player then
		replicators_table = self.other_replicators;
	end
	
	local replicant = Replicant.new(self, player);
	replicators_table[player] = replicant
	all_replicators_table[player] = replicant;
	
	replicant.maid:add(function()
		replicators_table[player] = nil;
		all_replicators_table[player] = nil;
	end)
	
	self.on_replicant_added:Fire(replicant);
	self:update_identifiers();
	
	return replicant;
end


function MovementReplicator:initialise_listeners()

	for _, player in Players:GetPlayers() do
		task.defer(self.add_replicant, self, player);
	end;
	
	for attribute, value in Shared.RuntimeSettings:GetAttributes() do
		task.defer(self.set_setting, self, attribute, value);
	end
	
	self.maid:add(Players.PlayerAdded:Connect(function(player)
		self:add_replicant(player);
	end))
	
	self.maid:add(Players.PlayerRemoving:Connect(function(player)
		self:remove_replicant(player)
	end))
	
	self.maid:add(Shared.RuntimeSettings.AttributeChanged:Connect(function(attribute)
		self:set_setting(attribute, Shared.RuntimeSettings:GetAttribute(attribute))
	end))
	
	self.maid:add(Remotes.UpdateIdentifiers.OnClientEvent:Connect(function(identifiers)
		self:set_identifiers(identifiers);
	end))
	
	self.maid:add(Remotes.EnterProximity.OnClientEvent:Connect(function(identity_buffer: buffer)
		local identity = BufferUtil.read_i8(BufferUtil.new(identity_buffer));
		local replicant = self.replicant_identifiers[identity];
		
		if replicant then
			replicant:set_in_proximity(true);
		end
	end))
	
	self.maid:add(Remotes.LeaveProximity.OnClientEvent:Connect(function(identity_buffer: buffer)
		local identity = BufferUtil.read_i8(BufferUtil.new(identity_buffer));
		local replicant = self.replicant_identifiers[identity];

		if replicant then
			replicant:set_in_proximity(false);
		end
	end))
	
	self.maid:add(Remotes.ReplicateToClient.OnClientEvent:Connect(function(replication_buffer: buffer)
		self.replication_buffer = BufferUtil.new(replication_buffer);
		
		local replication_targets = self:read_replication_buffer();
		local time_now = tick();
		
		for replicator, replicant in self.other_replicators do
			local target = replication_targets[replicant.identifier]
			
			if target then
				replicant.last = time_now;
				replicant.target_cframe, replicant.target_velocity = target.c, target.v;
			end;
		end;
	end))
end

---------------------------------------------------------------------------------

table.freeze(MovementReplicator);

return MovementReplicator.new();