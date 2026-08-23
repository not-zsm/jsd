local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

---------------------------------------------------------------------------------

local Packages = replicatedStorage.Packages
local Maid = require( Packages.Maid )
local BufferUtil = require( Packages.BufferUtil )

local Types = require( script.Parent.Types );
local Util = require( replicatedStorage.modules.shared.movementReplicator.Util )
local Settings = require( replicatedStorage.modules.shared.movementReplicator.Settings )

local Remotes = replicatedStorage.modules.shared.movementReplicator.Remotes;

---------------------------------------------------------------------------------

local Replicant = {};
Replicant.__index = Replicant;

---------------------------------------------------------------------------------

-- Removes the replicator event is a replicant has one.
local function remove_replicator(self)
	if self.replicator then
		self.replicator:Destroy()
		self.replicator = nil;
	end
end

---------------------------------------------------------------------------------

function Replicant.new(MovementReplicator: Types.MovementReplicator, player: Player)
	local maid = Maid.new();

	local self = setmetatable(
		{
			movement_replicator = MovementReplicator;
			
			character_maid = Maid.new();
			maid = maid;	
			player = player;
			
			resimulated = {};
			limbs = {};
			proximity_list = {};
			
			is_replicating = false;
			
			last_replication = -1;
			last_proximity = -1;
			replication_tick = Settings.replication_tick;
		}, 
		Replicant);

	if player.Character then
		task.defer(self.character_added, self, player.Character);
	end

	self:initialise_events();

	return self;
end;

---------------------------------------------------------------------------------


-- Initialises the player character events.
function Replicant:initialise_events()
	self.replicator = self.movement_replicator:create_replicator_remote(self.player);
	
	self.maid:add(self.replicator.OnServerEvent:Connect(function(player, b: buffer)
		if (self.player ~= player) then return end;
		
		self:set_buffer_interfaced(b);
	end))
	
	self.maid:add(self.player.CharacterAdded:Connect(function(character)
		self:character_added(character);
	end))
	
	self.maid:add(self.player.CharacterRemoving:Connect(function(character)
		self:character_removing(character);
	end))
end


function Replicant:clear_debug()
	if self.debug then
		self.debug:Destroy();
		self.debug = nil;
	end

	if self.debug_non_replicated then
		self.debug_non_replicated:Destroy();
		self.debug_non_replicated = nil;
	end
end


function Replicant:initialise_debug()
	self:clear_debug();
	
	if Settings.use_replicator then
		self.debug = Util.create_debug_part(Color3.fromRGB(255, 87, 87), "New Replicator", `{math.round(1 / Settings.replication_tick)} updates/per second.`)
		self.debug.Parent = self.root;
	end;
	
	self.debug_non_replicated = Util.create_debug_part(Color3.fromRGB(247, 255, 93), "Roblox Default", `20 updates/per second + Added Buffer`)
	self.debug_non_replicated.Parent = self.root;
end


function Replicant:refresh_settings()
	self.replication_tick = Settings.replication_tick;
end


function Replicant:update_bulk_debug(parts: {BasePart}, cframes: {CFrame})
	if self.target_cframe and self.debug then
		table.insert(parts, self.debug);
		table.insert(cframes, self.target_cframe);
	end;

	table.insert(parts, self.debug_non_replicated);
	table.insert(cframes, self.root.CFrame);
end


function Replicant:destroy()
	table.clear(self.proximity_list);
	table.clear(self.resimulated);
	table.clear(self.limbs);
	
	self.maid:destroy();
	self.character_maid:destroy();
	
	self:clear_debug();
	remove_replicator(self);
	
	self.movement_replicator.active_replicants[self] = nil;
end



function Replicant:set_buffer_interfaced(b: buffer)
	if (typeof(b) ~= "buffer" or buffer.len(b) > 128) then return end
	if self.movement_replicator.pause_replication or Settings.simulate_noisy_channel and math.random() < Settings.noisy_channel_stutter_alpha then return end
	
	self:set_buffer(b);
end


function Replicant:set_buffer(b: buffer)
	self.target_buffer = BufferUtil.new(b);
	self.target_buffer_need_use = true;
end


function Replicant:get_identity_buffer()
	local identity_buffer = BufferUtil.create(2);
	BufferUtil.write_i8(identity_buffer, self.identity);
	
	return identity_buffer.buffer;
end


function Replicant:update_proximity()
	if not Settings.use_proximity then
		table.clear(self.proximity_list);
		
		for replicant in self.movement_replicator.active_replicants do
			if (self.player == replicant.player) then continue end;
			
			self.proximity_list[replicant] = true;
		end;
		
	elseif self.target_cframe then
		local origin = self.target_cframe.Position;

		for replicant in self.movement_replicator.active_replicants do
			if (self.player == replicant.player) then continue end;

			local distance = replicant.player:DistanceFromCharacter(origin);

			if (distance < Settings.proximity_range) then
				self:enter_proximity(replicant);
			else
				self:leave_proximity(replicant);
			end
		end
	end
	
	self.last_proximity = tick();
end


function Replicant:sync_replicate(replicant)
	-- self.target_cframe = self.root.CFrame;
	
	if not self.target_cframe then return end;
	
	local replicate_buffer = BufferUtil.create(32);
	
	if Settings.use_single_remote_buffer_implementation then
		self:write_single_buffer_replicate(replicate_buffer);
		Remotes.ReplicateToClient:FireClient(replicant.player, replicate_buffer.buffer);
	else
		self:write_multi_buffer_replicate(replicate_buffer);
		self.replicator:FireClient(replicant.player, replicate_buffer.buffer);
	end
end


function Replicant:enter_proximity(replicant)
	if not self.proximity_list[replicant] and Settings.use_proximity and replicant ~= self then
		self.proximity_list[replicant] = true;
		self:sync_replicate(replicant);
		
		Remotes.EnterProximity:FireClient(self.player, replicant:get_identity_buffer());
	end;
end


function Replicant:leave_proximity(replicant)
	if self.proximity_list[replicant] and Settings.use_proximity and replicant ~= self then
		self.proximity_list[replicant] = nil;
		
		Remotes.LeaveProximity:FireClient(self.player, replicant:get_identity_buffer());
	end;
end


function Replicant:write_single_buffer_replicate(replicate_buffer: BufferUtil.CursorBuffer)
	BufferUtil.write_i8(replicate_buffer, self.identity);
	BufferUtil.write_cframe(replicate_buffer, self.target_cframe);

	if Settings.replicate_assembly_linear_velocity then
		BufferUtil.write_vector3(replicate_buffer, self.target_velocity);
	end;
end


function Replicant:write_multi_buffer_replicate(replicate_buffer: BufferUtil.CursorBuffer)
	BufferUtil.write_cframe(replicate_buffer, self.target_cframe);

	if Settings.replicate_assembly_linear_velocity then
		BufferUtil.write_vector3(replicate_buffer, self.target_velocity);
	end;
end


function Replicant:read_buffer_target(): ()
	if not Settings.use_replicator then self.target_cframe = self.root.CFrame end;
	if not self.target_buffer then return end;

	local cframe = BufferUtil.read_cframe(self.target_buffer);

	self.target_cframe = cframe;

	if Settings.replicate_assembly_linear_velocity then
		local velocity = BufferUtil.read_vector3(self.target_buffer);
		self.target_velocity = velocity;
	end;
	
	self.target_buffer = nil;
end


function Replicant:update_bulk_resimulation(parts: {BasePart}, cframes: {CFrame})
	if not Settings.server_character_resimulator then return end;
	
	if Settings.replicate_assembly_linear_velocity then
		self.resimulated.HumanoidRootPart.AssemblyLinearVelocity = self.target_velocity;
	end;
	
	table.insert(parts, self.resimulated.HumanoidRootPart)
	table.insert(cframes, self.target_cframe)

	local root = self.root :: BasePart;
	local offset = (self.target_cframe.Position - root.Position) * Settings.resimulation_interpolation_alpha;

	for name, resim in self.resimulated do
		if name == "HumanoidRootPart" then
			continue;
		end;

		local limb = self.limbs[name];

		table.insert(parts, resim)
		table.insert(cframes, limb.CFrame + offset);
	end
end


function Replicant:initialise_character_resimulation(character: Model)
	local camera, resimulated = self.movement_replicator:create_resimulated(character);

	table.clear(self.resimulated);

	for name, limb in resimulated do
		self.resimulated[name] = limb;
	end;

	for _, limb in self.character:GetChildren() do
		if Util.limb_names[limb.Name] and limb:IsA("BasePart") then
			self.limbs[limb.Name] = limb;
		end;
	end

	self.resimulate_camera = camera;
	self.resimulate_camera.Parent = character;
end


function Replicant:character_removing(character)
	self:clear_debug();
	self.character_maid:clean();
	
	for _, replicant in self.movement_replicator.replicants do
		replicant:leave_proximity(self);
	end
	
	self.movement_replicator.active_replicants[self] = nil;
	self.is_replicating = false;
end


function Replicant:character_added(character)
	self:clear_debug();
	self.character_maid:clean();

	self.character = character;
	self.humanoid = character:WaitForChild("Humanoid")
	self.root = character:WaitForChild("HumanoidRootPart", 5);
	
	self.replicator:SetAttribute("Ragdoll", false);
	
	if Settings.server_character_resimulator then
		self:initialise_character_resimulation(character);
	end

	if Settings.show_replicator_boxes then
		self:initialise_debug();
	end;
	
	self.movement_replicator.active_replicants[self] = true;
	self.is_replicating = true;
end

---------------------------------------------------------------------------------

table.freeze(Replicant);

return Replicant;