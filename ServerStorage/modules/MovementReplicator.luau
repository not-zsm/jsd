local ServerStorage = game:GetService("ServerStorage")
local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

---------------------------------------------------------------------------------

local Packages = replicatedStorage.packages

local Maid = require( Packages.Maid )
local Signal = require( Packages.Signal ) 
local BufferUtil = require( Packages.BufferUtil )

local Settings = require( replicatedStorage.modules.shared.movementReplicator.Settings )
local Util = require( replicatedStorage.modules.shared.movementReplicator.Util )
local Casting = require( replicatedStorage.modules.shared.movementReplicator.Lib.Casting )
local Metadata = require( replicatedStorage.modules.shared.movementReplicator.Metadata )

local Replicant = require( script.Replicant )
local Types = require( script.Types )
local EditWhitelist = require( script.EditWhitelist )
local Defaults = table.clone(Settings);

---------------------------------------------------------------------------------

local BoolEditWhitelist = {};

for _, id in EditWhitelist do
	BoolEditWhitelist[id] = true;
end

---------------------------------------------------------------------------------

local Shared = replicatedStorage.modules.shared.movementReplicator;
local Remotes = replicatedStorage.modules.shared.movementReplicator.Remotes;

---------------------------------------------------------------------------------

local MovementReplicator = {};
MovementReplicator.__index = MovementReplicator;

---------------------------------------------------------------------------------

function MovementReplicator.new()
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			last_replication = 0;
			pause_replication = false;

			maid = maid;
			replicants = {};
			active_replicants = {};
			identities = {};
			
			parts = {};
			cframes = {};
			
			on_player_setting_changed = maid:add(Signal.new());
		}, 
		MovementReplicator);
	
	
	if Settings.use_replicator then
		self:initialise_events();
		self:initialise_replication();
	end;
	
	return self;
end;

---------------------------------------------------------------------------------

-- Connects to player events
function MovementReplicator:initialise_events()
	
	if Settings.simulate_noisy_channel then
		self:initialise_noisy_channel();
	end
	
	self.maid:add(Remotes.ReplicateFromClient.OnServerEvent:Connect(function(player, b: buffer)
		self.replicants[player]:set_buffer_interfaced(b);
	end))
	
	self.maid:add(Remotes.ResetToDefaults.OnServerEvent:Connect(function(player)
		if self:has_edit_permissions(player) then
			for setting, value in Defaults do
				self:set_runtime_setting(setting, value);
			end;
		end
	end))
	
	self.maid:add(Remotes.UpdateSetting.OnServerEvent:Connect(function(player, setting, value)
		if self:has_edit_permissions(player) then
			local success, new_value = Casting(value, typeof(Settings[setting]))
			
			if success then
				self:set_runtime_setting(setting, new_value);
			end;
		end
	end))
	
	self.maid:add(Remotes.UpdatePlayerSetting.OnServerEvent:Connect(function(player, target_player, setting, value)
		if self:has_edit_permissions(player) then
			self.on_player_setting_changed:Fire(target_player, setting, value);
		end
	end))
	
	for _, player in Players:GetPlayers() do
		task.spawn(self.add_player, self, player);
	end

	self.maid:add(Players.PlayerAdded:Connect(function(player)
		self:add_player(player);
	end))

	self.maid:add(Players.PlayerRemoving:Connect(function(player)
		self:remove_player(player);
	end))
end


function MovementReplicator:stop_noisy_channel()

	if self.noisy_channel_thread then
		if coroutine.status(self.noisy_channel_thread) == "suspended" then
			task.cancel(self.noisy_channel_thread);
		end;

		self.noisy_channel_thread = nil;
	end;
	
	self.pause_replication = false;
end


function MovementReplicator:initialise_noisy_channel()
	self:stop_noisy_channel();
	
	self.noisy_channel_thread = task.spawn(function()
		local stutter_length = Settings.noisy_channel_drop_length;

		while task.wait(0.1) do
			if math.random() < Settings.noisy_channel_drop_alpha then
				self.pause_replication = true;
				task.wait(stutter_length.Min + math.random() * (stutter_length.Max - stutter_length.Min));

				self.pause_replication = false;
				task.wait(math.random() + 1)
			end
		end
	end)
end


function MovementReplicator:has_edit_permissions(player: Player): boolean
	if RunService:IsStudio() or BoolEditWhitelist[player.UserId] then
		return true;
	
	elseif game.CreatorType == Enum.CreatorType.User then
		if player.UserId == game.CreatorId then
			return true;
		end;
		
	elseif game.CreatorType == Enum.CreatorType.Group then
		if player:GetRankInGroup(game.CreatorId) >= 255 then
			return true;
		end
	end
	
	return false;
end


function MovementReplicator:add_player(player: Player)
	local replicant = Replicant.new(self, player);

	self.replicants[player] = replicant
	self:register_replicant(replicant);
	
	if self:has_edit_permissions(player) then
		Remotes.UpdateWhitelist:FireClient(player);
	end
end


function MovementReplicator:remove_player(player: Player)
	local replicant = self.replicants[player];

	self.replicants[player] = nil;
	self.active_replicants[replicant] = nil;
	
	self:unregister_replicant(replicant);
	-- This is after incase of errors that will cause memory leaks.
	replicant:destroy();
end


-- Same concept that betterReplication employs
function MovementReplicator:register_replicant(replicant)
	local player_identifier = 1;

	for identifier = 1, 255 do
		if not self.identities[identifier] then
			player_identifier = identifier;
			break;
		end;
	end;
	
	self.identities[player_identifier] = replicant.player.UserId;
	
	replicant.identity = player_identifier;
	Remotes.UpdateIdentifiers:FireAllClients(self.identities)
end


function MovementReplicator:get_replicant_identifier_from_identities(replicant): number?
	for identifier, user_id in self.identities do
		if user_id == replicant.player.UserId then
			return identifier;
		end;
	end;

	return nil;
end


function MovementReplicator:unregister_replicant(replicant)
	local player_identifier = self:get_replicant_identifier_from_identities(replicant);

	if player_identifier then
		self.identities[player_identifier] = nil;
	end

	Remotes.UpdateIdentifiers:FireAllClients(self.identities)
end


function MovementReplicator:replicate(parts: {BasePart}, cframes: {CFrame}): ()
	if Settings.use_single_remote_buffer_implementation then
		
		for replicant in self.active_replicants do
			local replicate_buffers = { BufferUtil.create(32) };
			local current_buffer = 1;
			local is_replication_necessary = false;
			
			for replicant2 in replicant.proximity_list do
				local this_buffer = replicate_buffers[current_buffer];
				
				-- Unreliables have a max payload size of 900 bytes. So I have to split them up if somehow it is reached I.E 25 players all within proximity of each other.
				if this_buffer.size > Settings.unreliable_payload_byte_split_threshold then
					current_buffer += 1;
					replicate_buffers[current_buffer] = BufferUtil.create(32);
					this_buffer = replicate_buffers[current_buffer];
				end;
				
				if replicant2.target_buffer_need_use and replicant2.target_cframe then
					is_replication_necessary = true;
					replicant2:write_single_buffer_replicate(this_buffer);
				end;
			end
			
			if is_replication_necessary then
				for index, replicate_buffer in ipairs(replicate_buffers) do
					Remotes.ReplicateToClient:FireClient(replicant.player, replicate_buffer.buffer);
				end;
			end;
		end
	else
		for replicant in self.active_replicants do
			if replicant.target_buffer_need_use and replicant.target_cframe then
				local replicate_buffer = BufferUtil.create(32);

				replicant:write_multi_buffer_replicate(replicate_buffer);

				for replicant2 in replicant.proximity_list do
					replicant.replicator:FireClient(replicant2.player, replicate_buffer.buffer);
				end
			end;
		end
	end
end


function MovementReplicator:initialise_replication()
	local last_replication = tick();
	local last_proximity = tick();
	
	self.maid:add(RunService.PreSimulation:Connect(function(dt: number)
		local time_now = tick();

		local parts: {BasePart} = self.parts;
		local cframes: {CFrame} = self.cframes;
		
		table.clear(parts);
		table.clear(cframes);
		
		for replicant in self.active_replicants do
			replicant:read_buffer_target();

			if (Settings.server_persistent_resimulator_updates or replicant.target_buffer_need_use) and replicant.target_cframe then
				replicant:update_bulk_resimulation(parts, cframes);
			end;
		end
		
		if time_now - last_proximity > Settings.proximity_tick then
			for replicant in self.active_replicants do
				replicant:update_proximity();
			end
		end
		
		-- Resimulation and debug boxes.
		if Settings.show_replicator_boxes then
			for replicant in self.active_replicants do
				replicant:update_bulk_debug(parts, cframes)
			end;
		end;
		
		self:replicate(parts, cframes);
		
		for _, replicant in self.replicants do
			replicant.target_buffer_need_use = false;
		end;

		workspace:BulkMoveTo(parts, cframes, Settings.replicator_bulk_mode);
	end))
end


function MovementReplicator:set_runtime_setting(setting: string, value: any): ()
	if typeof(setting) ~= "string" or typeof(value) ~= typeof(Settings[setting]) then
		return
	end
	
	Shared.RuntimeSettings:SetAttribute(setting, value);
	Settings[setting] = value;
	
	local metadata = Metadata[setting];
	
	if metadata.updates.replicator_boxes then
		if Settings.show_replicator_boxes then
			for player, replicant in self.replicants do
				replicant:initialise_debug();
			end;
		else
			for player, replicant in self.replicants do
				replicant:clear_debug();
			end;
		end
	end
	
	if metadata.updates.noisy_channel then
		if Settings.simulate_noisy_channel then
			self:initialise_noisy_channel();
		else
			self:stop_noisy_channel();
		end
	end
	
	if metadata.updates.proximity then
		for player, replicant in self.replicants do
			replicant:update_proximity();
		end
	end
	
	for player, replicant in self.replicants do
		replicant:refresh_settings();
	end
end


function MovementReplicator:toggle_replicator_boxes_visible()
	self:set_replicator_boxes_visible(not Settings.show_replicator_boxes);
end


function MovementReplicator:set_replicator_boxes_visible(visible: boolean)
	self:set_runtime_setting("show_replicator_boxes", not not visible);
end


-- Returns the resimulated limb for a player if it exists. 
-- Will only work if 'server_character_resimulator' is enabled, and will only work with HumanoidRootPart if 'only_resimulate_root_part' is enabled.
function MovementReplicator:get_relimb(player: Player, limb_name: string): BasePart
	if self.replicants[player] then
		return self.replicants[player].resimulated[limb_name];
	end
end


-- Returns the resimulated Humanoid Root Part of a the player.
-- Will only work if 'server_character_resimulator' is enabled.
function MovementReplicator:get_root_part(player: Player): BasePart
	if self.replicants[player] then
		return self.replicants[player].resimulated.HumanoidRootPart;
	end
end


function MovementReplicator:get(player: Player): Types.Replicant
	return self.replicants[player];
end

function MovementReplicator:get_from_humanoid(humanoid : Humanoid): Types.Replicant?
	local character = humanoid.Parent
	
	if character then
		local player = Players:GetPlayerFromCharacter(character)
		
		if player then
			return self.replicants[player];
		end
	end
end



-- Use this function to get the replicated position of a character part of a player.
function MovementReplicator:get_cframe(player: Player, character_part: BasePart): CFrame
	local replicant = self.replicants[player];

	if replicant and replicant.target_cframe then
		return character_part.CFrame + (replicant.target_cframe.Position - replicant.root.Position) * Settings.resimulation_interpolation_alpha;
	end;

	return character_part.CFrame;
end



function MovementReplicator:create_resimulated(character: Model, dummy_mode: boolean?)
	local resimulate_camera = Instance.new("Camera");
	resimulate_camera.Archivable = false;
	resimulate_camera.Name = "ResimulatedCharacter";
	
	local char_root = character:FindFirstChild("HumanoidRootPart");
	local root_part = script.Replicant.ResimulatedPart:Clone();
	local resimulated = {};

	if dummy_mode then
		root_part.Size = Vector3.new(4, 5.5, 2);
		root_part.CFrame = char_root.CFrame;
		
		local weld = Instance.new("WeldConstraint");
		weld.Part0 = root_part;
		weld.Part1 = char_root;

		root_part.Anchored = false;
		weld.Parent = root_part;
	else
		if Settings.resimulated_root_part_size ~= Vector3.zero then
			root_part.Size = Settings.resimulated_root_part_size;
		else
			root_part.Size = char_root.Size;
		end
	end
	
	local attachment = Instance.new("Attachment");
	attachment.Name = "RootAttachment";
	attachment.Parent = root_part;
	
	resimulated.HumanoidRootPart = root_part;

	if not Settings.only_resimulate_root_part and not dummy_mode then
		for _, limb in character:GetChildren() do
			if Util.limb_names[limb.Name] and limb:IsA("BasePart") then
				local limb_part = script.Replicant.ResimulatedPart:Clone();
				limb_part.Name = limb.Name;
				limb_part.Size = limb.Size;
				limb_part.Parent = resimulate_camera;

				resimulated[limb.Name] = limb_part;
			end;
		end
	end
	
	root_part.Name = "HumanoidRootPart"
	root_part.Parent = resimulate_camera;

	return resimulate_camera, resimulated;
end


-- Creates a replicator event with a tag. It doesnt need to be named.
function MovementReplicator:create_replicator_remote(parent: Instance)
	local replicator = Instance.new("UnreliableRemoteEvent")
	replicator.Archivable = false;
	replicator.Name = "Replicator";
	replicator.Parent = parent;

	return replicator;
end

---------------------------------------------------------------------------------

table.freeze(MovementReplicator);

return MovementReplicator.new();