
local XZ_AXIS = Vector3.new(1, 0, 1);

---------------------------------------------------------------------

local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

---------------------------------------------------------------------

local Havoc = script.Parent;
local Remotes = Havoc.Remotes;
local Player = Players.LocalPlayer;

---------------------------------------------------------------------

local BufferUtil = require( replicatedStorage.packages.BufferUtil )
local AenoirEmit = require( replicatedStorage.modules.client.replication.EffectUtility.AenoirEmit )
local Effects = require( script.Effects );
local PartCache = require("./PartCache");
local Presets = require("./Presets");
local Settings = require("./Settings");

---------------------------------------------------------------------

local RepSettings = Settings.ReplicationSettings;
local Cache = PartCache.new(Instance.new("Part"));

-- The top bit of a debris size id carries the wedge flag, leaving 32767 sizes per blast.
local WedgeFlag = 0x8000;
local WedgeMask = 0x7FFF;

local function get_havoc()
	if Havoc:FindFirstChild("Havoc") then
		return require("./Havoc");
	end;
end

---------------------------------------------------------------------

local Replication = {};
Replication.__index = Replication;

function Replication.new()
	local self = setmetatable(
		{
			debris_pool = {};
			debris_update_payloads = {};

			active_havoc = {};
			register_queue = {};
			unregister_queue = {};
			
			debris_interpolation_info = TweenInfo.new(1);
		}, 
		Replication);

	self:initialise();

	return self;
end;

---------------------------------------------------------------------

function Replication:get_debris_folder()
	return workspace.Havoc.Dynamic;
end

function Replication:initialise()
	Remotes.Client.RegisterHavoc.OnClientEvent:Connect(function(havocs, was_join)
		table.insert(self.register_queue, { havocs = havocs, was_join = was_join })
	end)

	Remotes.Client.UnregisterHavoc.OnClientEvent:Connect(function(havocs, restores)
		table.insert(self.unregister_queue, { havocs = havocs, restores = restores });
	end)

	RunService.Heartbeat:Connect(function(dt)
		self:spindle(dt);
	end)

	Remotes.CreateEffects.OnClientEvent:Connect(function(volumes)
		for _, volume in volumes do
			self:create_effects_in_volume(volume, "Particles");
		end
	end);
	
	Remotes.CreateDebrisHitEffects.OnClientEvent:Connect(function(volumes)
		for _, volume in volumes do
			self:create_effects_in_volume(volume, "Hit");
		end;
	end);
	
	Remotes.Replicated.CollapseStructure.OnClientEvent:Connect(function(source_part: BasePart)
		if not source_part then
			return warn("Unable to collapse structure because source part is nil");
		end;
		
		self:collapse_structure_from_source(source_part);
	end)

	Remotes.Replicated.CreateDebris.OnClientEvent:Connect(function(instances: {Instance}, debris: {buffer})
		self:create_replicated_debris(instances, debris);
	end)

	Remotes.Replicated.UpdateTimestep.OnClientEvent:Connect(function(timestep)
		self.debris_interpolation_info = TweenInfo.new(timestep * 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end)
	
	Remotes.Replicated.UpdateDebris.OnClientEvent:Connect(function(data)
		table.insert(self.debris_update_payloads, data);
		
		if not self.debris_update_thread then
			self.debris_update_thread = task.defer(self.update_replicated_debris, self);
		end
	end)

	Remotes.Replicated.DeleteDebris.OnClientEvent:Connect(function(data)		
		self:delete_replicated_debris(data);
	end)
end

function Replication:collapse_structure_from_source(source_part: BasePart)
	local weld_assembly: {BasePart} = {};
	
	table.insert(weld_assembly, source_part);
	
	for _, weld in source_part:GetChildren() do
		if weld:IsA("WeldConstraint") and weld.Part1 then
			table.insert(weld_assembly, weld.Part1);
		end;
	end;
	
	for _, part in weld_assembly do
		local size = part.Size;
		local inner_volume = size.X * size.Y * size.Z / math.min(size.X, size.Y, size.Z);
		local heuristic_volume = 0.5 * math.sqrt(inner_volume);
		
		task.delay(math.random() * 0.1, function()
			local scale = math.clamp(heuristic_volume * 0.045, 1, 5);
			local tint = Color3.new(math.lerp(part.Color.R, 0, 0.5), math.lerp(part.Color.G, 0, 0.5), math.lerp(part.Color.B, 0, 0.5));
			local density = 1 + heuristic_volume * 0.7;
			
			if heuristic_volume > 2 then
				AenoirEmit.Emit(script.BigCollapse, part, {
					Scale = scale;
					Tint = tint;
					Density = density;
					Volume = 1.5;
				});
			end;
			
			AenoirEmit.Emit(script.StructureCollapse, part, {
				Scale = scale;
				Tint = tint;
				Density = density;
			});
		end);
	end;
end;

function Replication:update_replicated_debris()
	self.debris_update_thread = nil;

	local update_count = 0;
	local payload_size_track = 0;
	
	local size1 = BufferUtil.u16.size + BufferUtil.small_cframe.size;
	local parts: {BasePart} = {};
	local cframes: {CFrame} = {};
	
	for _, data in self.debris_update_payloads do
		local update = BufferUtil.new(data);
		payload_size_track += update.size;
		
		while update.cursor + size1 <= update.size do 
			local id = BufferUtil.read_u16(update);
			local coordinate = BufferUtil.read_small_cframe(update);
			local part = self.debris_pool[id];
			
			if not (part and not Cache.parts[part]) then
				continue;
			end;
			
			update_count += 1;
			table.insert(parts, part);
			table.insert(cframes, coordinate);
		end;
	end;
	
	if RepSettings.ClientByteDebugPrint then
		print(`[🆙] {payload_size_track} bytes | {payload_size_track / 1000} KB`);
	end;
	
	local interpolation_enabled = Player:GetAttribute("Voxel_Interpolation");
	
	local max_tweens = RepSettings.MaxClientTweenBeforeDropoff;
	local parts_tweened = if interpolation_enabled then math.min(update_count, max_tweens * 2 - update_count) else 0;
	
	if (parts_tweened > 0) then
		for index = 0, parts_tweened do
			TweenService:Create(parts[index], self.debris_interpolation_info, { CFrame = cframes[index] }):Play();
		end;
	end;
	
	if (parts_tweened < update_count) then
		local new_parts = table.move(parts, parts_tweened + 1, update_count, 1, {});
		local new_cframes = table.move(cframes, parts_tweened + 1, update_count, 1, {});
		
		workspace:BulkMoveTo(new_parts, new_cframes, Enum.BulkMoveMode.FireCFrameChanged);
	end;
	
	table.clear(self.debris_update_payloads);
end

function Replication:create_replicated_debris(instances: {Instance}, debris: {buffer})
	local client_parts = {};
	local replicated_parts = {};
	local payload_size_track = #instances * 8;
	
	local size_payload = BufferUtil.new(debris[1]);
	local vector_sizes: {[number]: Vector3} = {};
	local vector_unit_size = BufferUtil.u16.size + BufferUtil.small_vector3.size;
	
	while size_payload.cursor + vector_unit_size <= size_payload.size do
		local id = BufferUtil.read_u16(size_payload);
		local size = BufferUtil.read_small_vector3(size_payload);
		
		vector_sizes[id] = size;
		payload_size_track += vector_unit_size;
	end
	
	for index, instance in instances do
		if not instance then continue end;

		local debris_payload = BufferUtil.new(debris[index + 1]);
		payload_size_track += debris_payload.size;
		
		local client_debris_start: number = BufferUtil.read_u16(debris_payload);
		local transparency: number = BufferUtil.read_alpha8(debris_payload);
		
		local function create_part(coordinate: CFrame, size: Vector3, wedge: boolean?)
			local part = Instance.fromExisting(instance);
			part.CFrame = coordinate;
			part.Size = size;
			part.Transparency = transparency;
			part.CanCollide = true;
			
			if part:IsA("Part") then
				part.Shape = if wedge then Enum.PartType.Wedge else Enum.PartType.Block;
			end;
			
			part.AssemblyLinearVelocity = Vector3.zero;
			part.AssemblyAngularVelocity = Vector3.zero;
			
			if part:GetAttribute("NoCollideDebris") then
				part.CollisionGroup = "NoPlayerCollision";
				part:SetAttribute("NoCollideDebris", nil);
			else
				part.CollisionGroup = "HavocDebree";
			end;
			
			part.Parent = self:get_debris_folder();

			return part;
		end;

		local size1 = BufferUtil.u16.size + BufferUtil.small_cframe.size + BufferUtil.u16.size;
		local size2 = BufferUtil.small_cframe.size + BufferUtil.u16.size;
		
		local array_part_offset = BufferUtil.u16.size + BufferUtil.alpha8.size;
		local to_array_part = math.min(array_part_offset + client_debris_start * size1, debris_payload.size);
		
		while debris_payload.cursor + size1 <= to_array_part do
			local id = BufferUtil.read_u16(debris_payload);
			local coordinate = BufferUtil.read_small_cframe(debris_payload);
			local packed = BufferUtil.read_u16(debris_payload);
			
			local part = create_part(coordinate, vector_sizes[bit32.band(packed, WedgeMask)], bit32.btest(packed, WedgeFlag));
			part.Anchored = true;
			
			table.insert(replicated_parts, part);
			self.debris_pool[id] = part;
		end;
		
		while debris_payload.cursor + size2 <= debris_payload.size do
			local coordinate = BufferUtil.read_small_cframe(debris_payload);
			local packed = BufferUtil.read_u16(debris_payload);
			
			local part = create_part(coordinate, vector_sizes[bit32.band(packed, WedgeMask)], bit32.btest(packed, WedgeFlag));
			part.Anchored = false;
			
			table.insert(client_parts, part);
		end;
	end;
	
	if RepSettings.ClientByteDebugPrint then
		print(`[🧱] {payload_size_track} bytes | {payload_size_track / 1000} KB`);
	end;
	
	if replicated_parts[1] then
		local function guess_velocities(part: BasePart, other_part: BasePart)
			local elapsed = 0;
			local duration = 3 + math.random() * 2;

			while elapsed < duration do
				local origin = other_part.Position;
				local dt = task.wait(RepSettings.ClientMimicDebrisUpdateFrequency);
				elapsed += dt;
				local target = other_part.Position;
				local guess_velocity = (target - origin) / dt;
				
				if (part.AssemblyLinearVelocity * XZ_AXIS).Magnitude < (guess_velocity * XZ_AXIS).Magnitude + 1 and guess_velocity.Magnitude > 1 then
					part.AssemblyLinearVelocity += guess_velocity * 0.2 + Vector3.yAxis * guess_velocity.Y * 0.1;
				end;
			end;
			
			part.CanCollide = false;
			part.Anchored = true;

			local tween = TweenService:Create(part, TweenInfo.new(1), {Size = Vector3.zero})
			tween:Play();
			tween.Completed:Wait();
			part:Destroy();
		end;

		-- Naively guesses the client debris velocity. Works well enough.
		for _, part in client_parts do
			local other_part = replicated_parts[math.random(#replicated_parts)];

			task.spawn(guess_velocities, part, other_part);
		end;
	end;

	table.clear(replicated_parts);
	table.clear(client_parts);
end

function Replication:delete_replicated_debris(data)
	local delete = BufferUtil.new(data);
	local size1 = BufferUtil.u16.size;

	while delete.cursor + size1 <= delete.size do
		local id = BufferUtil.read_u16(delete);
		local part = self.debris_pool[id];

		if part then
			self.debris_pool[id] = nil;
			part:Destroy();
		end;
	end;
end

-- Proper sorting of havoc
function Replication:spindle(dt: number)
	local havoc = get_havoc();

	if not havoc then return end;

	local register_queue = table.clone(self.register_queue);
	table.clear(self.register_queue);

	local unregister_queue = table.clone(self.unregister_queue);
	table.clear(self.unregister_queue);

	for _, queue in register_queue do
		table.sort(queue.havocs, function(a, b)
			return a.time < b.time;
		end);

		for _, havoc in queue.havocs do
			self:register_havoc(havoc, queue.was_join)
		end
	end

	for _, queue in unregister_queue do
		for _, id in queue.havocs do
			self:unregister_havoc(self.active_havoc[id]);
		end;

		for _, part in queue.restores do
			havoc.restore_destructed(part);
		end;
	end;
end;

function Replication:create_effects_in_volume(material_volume, directory: string)
	local origin, size = material_volume.origin, material_volume.size;

	local inner_volume = size.X * size.Y * size.Z;
	local heuristic_volume = 0.5 * math.sqrt(inner_volume);

	-- Support for Volumetric Audio, please enable it in SoundService
	-- Makes it sound much better than the sound emitting at just one point.
	local volume = Cache:get();
	volume.Name = "AudioDestruction";
	volume.CanCollide = false;
	volume.CanQuery = false;
	volume.CanTouch = false;
	volume.Locked = true;
	volume.Anchored = true;
	volume.Transparency = 1;
	volume.Size = size * 0.99;
	volume.CFrame = material_volume.origin;
	volume.Parent = workspace.Terrain;
	
	local folder = Effects.get_from_material(material_volume.material, directory);
	local ready_to_destroy = false;
	local offload_destroy = false;
	
	local color = Color3.new(0.5, 0.5, 0.5);
	local sound_volume = math.clamp(1 + heuristic_volume * 0.1, 0.5, 1.5);
	
	if material_volume.part then
		color = material_volume.part.Color;
	end
	
	AenoirEmit.Emit(folder, volume, {
		Scale = math.clamp(heuristic_volume * 0.05, 1, 3);
		Tint = color;
		Density = 1 + heuristic_volume * 0.25;
		Volume = 1 + sound_volume;
		
		Finished = function()
			if offload_destroy then
				Cache:give(volume);
			else
				ready_to_destroy = true;
			end;
		end
	});
	
	if directory == "Particles" then
		local sound = Effects.create_audio(material_volume.material);
		sound.Volume *= sound_volume
		sound.Playing = true;
		sound.Parent = volume;

		sound.Ended:Once(function()
			sound:Destroy();

			task.wait(Settings.EffectsLifetime);
			
			if ready_to_destroy then
				Cache:give(volume);
			else
				offload_destroy = true;
			end;
		end)
	end;
end;

function Replication:register_havoc(info, was_join)
	assert(info.id, "Crater has no ID, cannot replicate");
	assert(not self.active_havoc[info.id], "ID conflict");

	self.active_havoc[info.id] = info;

	debug.profilebegin("Rollback");

	local havoc = get_havoc();

	if not havoc then
		return warn("Havoc module does not yet exist for client");
	end;

	if info.rollback then
		for _, data in info.rollback do
			local part = data[1];
			local properties = data[2];

			if part then
				havoc.rollback_properties(part, properties);
				havoc.set_part_destructed(part, nil);
			end;
		end;
	end;

	debug.profileend();

	local havoc = havoc.create(info.havoc);
	havoc.permanent = true;

	if info.debris then
		info.debris.parent = havoc.folder.Dynamic;
	end;

	if info.crater then
		info.crater.parent = havoc.folder.Static;
	end;

	info.object = havoc;

	local parameters = {
		crater = info.crater, 
		debris = if not was_join then info.debris else nil,
		info = info,
	};

	if info.preset then
		assert(Presets[info.preset], `No preset exists named {info.preset}`);

		Presets[info.preset](havoc, parameters, was_join);
	else
		havoc:destruct(parameters);
	end;

	local volumes = havoc:get_material_volumes();

	for _, volume in volumes do
		self:create_effects_in_volume(volume);
	end
end;

function Replication:unregister_havoc(info)
	if not info then return end;

	assert(info.id, "Crater has no ID, cannot replicate");

	self.active_havoc[info.id] = nil;
end

table.freeze(Replication);

return Replication.new();