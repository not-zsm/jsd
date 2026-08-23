local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer;
local Shared = ReplicatedStorage.modules.shared.movementReplicator;
local Remotes = Shared.Remotes;

---------------------------------------------------------------------------------

local Packages = ReplicatedStorage.Packages

local Maid = require( Packages.Maid )
local CFSpring = require( Packages.Spring.CFSpring )
local Spring = require( Packages.Spring )
local Signal = require( Packages.Signal )
local BufferUtil = require( Packages.BufferUtil )

local Util = require( ReplicatedStorage.modules.shared.movementReplicator.Util )
local Settings = require( ReplicatedStorage.modules.shared.movementReplicator.Settings )
local Ragdoll = require( ReplicatedStorage.modules.shared.movementReplicator.Lib.Ragdoll )

local Types = require( script.Parent.Types )
local PusedoRagdoll = require( script.PusedoRagdoll )
local GhostRagdoll = require( script.GhostRagdoll )

---------------------------------------------------------------------------------

local Replicant = {} :: Types.ClassReplicant;
Replicant.__index = Replicant;

---------------------------------------------------------------------------------

function Replicant.new(MovementReplicator: Types.MovementReplicator, player: Player): Types.Replicant
	local replicator = player:WaitForChild("Replicator", 60);
	assert(replicator, `Time out while waiting for player {player.Name}'s replicator`)
	
	local spring = CFSpring.new(CFrame.identity);
	spring.damping = Settings.client_spring_damping;
	spring.speed = 50;
	
	local maid = Maid.light();
	
	local self = setmetatable(
		{
			character = nil;
			player = player;
			
			movement_replicator = MovementReplicator;
			replicator = replicator;
			
			last_update = 0;
			replication_tick = Settings.replication_tick;
			
			last = tick();
			
			target_cframe = CFrame.identity;
			target_velocity = Vector3.zero;
			
			last_replicated_cframe = CFrame.identity;
			last_replicated_velocity = Vector3.zero;
			
			spring = spring;
			
			need_update = false;
			is_disabled = false;
			is_ragdolled = false;
			in_proximity = not Settings.use_proximity;
			is_other = Player ~= player;
			
			on_proximity_changed = maid:add(Signal.new());
			on_ragdoll_changed = maid:add(Signal.new());
			on_destroying = maid:add(Signal.new());
			on_ready_changed = maid:add(Signal.new());
			
			character_maid = Maid.light();
			maid = maid;
		}, 
		Replicant);
	
	self:initialise_events();
	
	return self;
end;


function Replicant:destroy(): ()
	self.on_destroying:Fire();
	self.maid:destroy();
end

---------------------------------------------------------------------------------

function Replicant:character_removing(character: Model): ()
	self:set_is_ready(false);
	
	self.character_maid:clean();
	self:remove_ghost();
end


function Replicant:character_added(character: Model): ()
	self.character_maid:clean();
	self.character = character;

	local root = character:WaitForChild("HumanoidRootPart", 15);
	assert(root, `Could not find HumanoidRootPart of {character.Name}`);

	local torso = character:WaitForChild("Torso", 15);
	assert(root, `Could not find Torso of {character.Name}`);

	local humanoid = character:WaitForChild("Humanoid", 15);
	assert(humanoid, `Could not find Humanoid of {character.Name}`);

	local root_joint = root:WaitForChild("RootJoint", 15);
	assert(root, `Could not find RootJoint of HumanoidRootPart in {character.Name}`);

	self.spring.position = root.CFrame;
	self.spring.target = root.CFrame;

	self.replicate_root = root;
	self.target_cframe = self.spring.position;

	self.root = root;
	self.root_joint = root_joint;
	self.torso = torso;
	self.humanoid = humanoid;

	self.character_maid:add(humanoid:GetAttributeChangedSignal("Ragdoll"):Connect(function()
		self:update_ragdoll();
	end))

	if not self.is_other then
		self.character_maid:add(root:GetPropertyChangedSignal("CFrame"):Connect(function()
			self.need_update = true;
		end))
	end

	self:update_anchor();
	self:initialise_ghost();

	self:set_is_ready(true);
end


function Replicant:update_anchor(unsafe)
	if not self.is_ready or not self.root then return end;
	
	if not self.is_other or not Settings.replicator_anchors_root_part then 
		if unsafe then
			self.root.Anchored = false;
		end;
		return;
	end;
	
	self.root.Anchored = self:get_using_physics();
end


function Replicant:get_should_cframe_root()
	return self:get_using_physics() --self.in_proximity and not Settings.use_physics_based_ragdolls or Settings.use_physical_ghost_rig or not self.is_ragdolled
end


function Replicant:get_using_physics()
	if not Settings.use_replicator then return false end;
	
	if Settings.use_physics_based_ragdolls and not Settings.use_physical_ghost_rig then
		return not self.is_disabled and not self.is_ragdolled and self.in_proximity;
	else
		return not self.is_disabled and self.in_proximity;
	end
end


function Replicant:set_in_proximity(value: boolean)
	if self.in_proximity ~= value then
		self.in_proximity = value;
		self.on_proximity_changed:Fire(value);
		self:update_anchor();
	end;
end


function Replicant:set_is_ready(value: boolean)
	if self.is_ready ~= value then
		self.is_ready = value;
		self.on_ready_changed:Fire(value);
	end
end


function Replicant:update_ragdoll()
	local last_ragdolled = self.is_ragdolled;
	local new_ragdolled = 
		self.replicator:GetAttribute("Ragdoll")
		or (if self.humanoid then self.humanoid:GetAttribute("Ragdoll") else false)
		or false;
	
	if (last_ragdolled == new_ragdolled) then return end;
	
	self.is_ragdolled = new_ragdolled;
	self.on_ragdoll_changed:Fire(new_ragdolled);
	
	if Settings.use_replicator and self.ghost_ragdoll then
		self.ghost_ragdoll:set_enabled(self.is_ragdolled);
	end;

	if self.is_ragdolled then
		self.replication_tick = Settings.ragdoll_replication_tick;
	else
		self.replication_tick = Settings.replication_tick;
	end

	if Settings.use_physics_based_ragdolls and self.is_other and self.root_joint then
		if self.is_ragdolled then
			self.root_joint.Enabled = false;
		else
			self.root_joint.Enabled = true;
		end
	end;

	if not Settings.use_physics_based_ragdolls and (not self.is_other or Settings.use_physical_ghost_rig) then
		if not self.ragdoll then
			self.ragdoll = PusedoRagdoll.new(self.character);
		end

		self.ragdoll:set_enabled(self.is_ragdolled);
	end;

	self:update_anchor();
end


function Replicant:update_replication(time_now: number, dt: number, parts: {BasePart}, cframes: {CFrame})
	if self.is_disabled or not self.is_ready then
		return;
	end;

	local target_cframe, target_velocity = self.target_cframe, self.target_velocity;
	local speed_prediction = Settings.client_spring_smoothing_speed -- math.clamp(Settings.client_spring_smoothing_speed - deficit * 40, 0.1, 100);

	if not self.in_proximity or not target_cframe then
		target_cframe = self.root.CFrame;

		self.target_cframe = target_cframe;
		self.spring.p_spring.position = target_cframe.Position;
		self.spring.position = target_cframe.Position;
	end

	local lp = self.spring.position;
	self.spring.damping = Settings.client_spring_damping;
	self.spring.speed = math.clamp(math.lerp(self.spring.speed, speed_prediction, math.clamp(0.05 * dt * 60, 0, 1)), 0.1, 100)
	self.spring:update(target_cframe);
	self:update_anchor()

	local is_root_cframed = self:get_should_cframe_root();

	if is_root_cframed  then
		if target_velocity then
			self.replicate_root.AssemblyLinearVelocity = target_velocity;
			self.torso.AssemblyLinearVelocity = target_velocity;
		else
			-- Estimates the velocity, bit more inaccurate then replicating it.
			local estimated_velocity : Vector3 = (lp.Position - self.spring.position.Position) / dt
			
			self.replicate_root.AssemblyLinearVelocity = estimated_velocity
			self.torso.AssemblyLinearVelocity = estimated_velocity
		end;

		table.insert(parts, self.replicate_root);
		table.insert(cframes, self.spring.position);
	end;

	if Settings.use_physical_ghost_rig and self.ghost_ragdoll then

		self.ghost_ragdoll.root.AssemblyAngularVelocity = self.replicate_root.AssemblyAngularVelocity;
		self.ghost_ragdoll.root.AssemblyLinearVelocity = self.replicate_root.AssemblyLinearVelocity;
		--self.ghost_ragdoll.rig:PivotTo( self.spring.position );
		
		table.insert(parts, self.ghost_ragdoll.root);
		table.insert(cframes, self.spring.position);

		if self.is_ragdolled then
			-- Ghost rig does not work when Roblox's replicator is enabled.
			self.ghost_ragdoll:set_enabled(is_root_cframed);

			if is_root_cframed then
				local alpha = math.clamp(Settings.physical_ghost_rig_lerp_alpha * dt * 60, 0, 1);

				for ghost_limb, limb in self.ghost_ragdoll.body_parts do
					table.insert(parts, limb);
					table.insert(cframes, limb.CFrame:Lerp(ghost_limb.CFrame, alpha));
				end
			end;
		end;
	end;
end


function Replicant:remove_ghost()
	if self.ghost_ragdoll then
		self.ghost_ragdoll:destroy();
		self.ghost_ragdoll = nil;
	end;
end


function Replicant:initialise_ghost()
	self:remove_ghost();
	
	if not Settings.use_physical_ghost_rig or not self.is_other then return end;

	self.ghost_ragdoll = GhostRagdoll.new(self.character);
end


function Replicant:initialise_events(): ()
	
	if self.player.Character then
		task.defer(self.character_added, self, self.player.Character);
	end
	
	self.maid:add(self.player.CharacterAdded:Connect(function(character)
		self:character_added(character);
	end))
	
	self.maid:add(self.player.CharacterRemoving:Connect(function(character)
		self:character_removing(character);
	end));
	
	self.maid:add(self.replicator:GetAttributeChangedSignal("Disabled"):Connect(function()
		self.is_disabled = self.replicator:GetAttribute("Disabled");
		self:update_anchor();
	end))
	
	self.maid:add(self.replicator:GetAttributeChangedSignal("Ragdoll"):Connect(function()
		self:update_ragdoll()
	end))
	
	self.maid:add(self.replicator.OnClientEvent:Connect(function(replication_buffer: buffer)
		local cframe, velocity = self:read_replicate_buffer(BufferUtil.new(replication_buffer));
		
		self.last = tick();
		self.target_velocity = velocity;
		self.target_cframe = cframe;
	end))
end


function Replicant:read_replicate_buffer(replication_buffer: BufferUtil.CursorBuffer): (CFrame, Vector3?)
	local cframe  = BufferUtil.read_cframe(replication_buffer);
	
	if Settings.replicate_assembly_linear_velocity then
		return cframe, BufferUtil.read_vector3(replication_buffer);
	end;
	
	return cframe, nil;
end


function Replicant:write_replicate_buffer(cframe: CFrame, velocity: Vector3?): BufferUtil.CursorBuffer
	local replication_buffer = BufferUtil.new(buffer.create(27))
	
	BufferUtil.write_cframe(replication_buffer, cframe);
	
	if velocity then
		BufferUtil.write_vector3(replication_buffer, velocity);
	end;
	
	return replication_buffer;
end


function Replicant:replicate(): ()
	local cframe = self.root.CFrame;
	local replication_buffer: BufferUtil.CursorBuffer;
	
	if Settings.replicate_assembly_linear_velocity then
		local velocity = self.root.AssemblyLinearVelocity;
		replication_buffer = self:write_replicate_buffer(cframe, velocity)
		self.last_replicated_cframe = cframe;
		self.last_replicated_velocity = velocity;
	else
		replication_buffer = self:write_replicate_buffer(cframe)
		self.last_replicated_cframe = cframe;
	end;
	
	self.last = tick();
	
	Remotes.ReplicateFromClient:FireServer(replication_buffer.buffer);
end

---------------------------------------------------------------------------------

table.freeze(Replicant);

return Replicant;