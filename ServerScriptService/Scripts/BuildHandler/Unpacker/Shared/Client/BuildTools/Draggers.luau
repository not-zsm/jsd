local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-----------------------------------------------------------------------------------------------------------

local Player = Players.LocalPlayer;
local BuildShared = ReplicatedStorage:WaitForChild("BuildTools");

-----------------------------------------------------------------------------------------------------------

local Table = require( ReplicatedStorage.Packages.Table )
local Signal = require( ReplicatedStorage.Packages.Signal )
local Maid = require( ReplicatedStorage.Packages.Maid )
local Math = require( ReplicatedStorage.Packages.Math )
local HelpInput = require( ReplicatedStorage.Packages.HelpInput )

-----------------------------------------------------------------------------------------------------------

local Draggers = {};
Draggers.__index = Draggers;

function Draggers.new(build_tools, extents_part: any)
	local self = setmetatable({}, Draggers);

	self.build_tools = build_tools;
	self.selection = build_tools.selection;

	self.extents_part = extents_part;
	self.maid = Maid.new();
	
	self.world_aligned = false;
	self.local_space = false;
	self.alignment_mode = "FacePivot";

	self.touching_handles = 0;
	self.handles = {
		scale = {
			x = extents_part.ScaleX :: Handles;
			y = extents_part.ScaleY :: Handles;
			z = extents_part.ScaleZ :: Handles;
		};
		move = {
			x = extents_part.MoveX :: Handles;
			y = extents_part.MoveY :: Handles;
			z = extents_part.MoveZ :: Handles;
		};
		rotate = {
			all = extents_part.Rotate :: ArcHandles;
		};
	};
	
	self.current_scale_space = "World";
	self.current_handle_space = "World";
	
	self.move_handle_drag = self.maid:add(Signal.new());
	self.scale_handle_drag = self.maid:add(Signal.new());
	self.rotation_handle_drag = self.maid:add(Signal.new());
	self.locality_changed = self.maid:add(Signal.new());
	self.alignment_changed = self.maid:add(Signal.new());

	return self;
end;

export type Draggers = typeof(Draggers.new(...))

function Draggers.destroy(self: Draggers): ()
	self.maid:destroy();

	for _, handle in self.handles do
		table.clear(handle);
		--handle:Destroy();
	end;
	table.clear(self.handles);
	
	Table.dispose(self);
end

function Draggers.set_handle_visible(self: Draggers, mode: Enum.RibbonTool): ()
	for name, handles in self.handles do
		if self.build_tools.selection:is_empty() or self.build_tools.placement:is_active() then
			for axes, handle in handles do
				handle.Visible = false;
			end;
		else
			local visible = name == string.lower(mode.Name);
			
			for axes, handle in handles do
				handle.Visible = visible;
				handle.Parent = self.build_tools.ui;
			end;
		end
	end
end

function Draggers.is_touching_handle(self: Draggers): boolean
	return self.touching_handles > 0;
end

function Draggers.set_alignment_mode(self: Draggers, mode: "Pivot" | "FacePivot" | "Move")
	if self.alignment_mode ~= mode then
		self.alignment_mode = mode;
		self.alignment_changed:Fire(mode);
	end
end

function Draggers.set_world_aligned(self: Draggers, world_aligned: boolean?)
	if world_aligned == nil then
		world_aligned = not self.world_aligned;
	end;
	
	if (self.world_aligned ~= world_aligned) then
		self.world_aligned = world_aligned;
	end
end

function Draggers.set_local_space(self: Draggers, local_space: boolean?)
	local last_value = self.local_space;

	if (local_space ~= nil) then
		self.local_space = local_space;
	else
		self.local_space = not self.local_space;
	end;

	if (self.local_space ~= last_value) then
		self.locality_changed:Fire(self.local_space);
		self.selection:update_extents();
		self:update_handles();
	end;
end

-- Returns whether local space should be used, and whether the first selected is an attachment.
function Draggers.get_local_space(self: Draggers, raw: boolean?): (boolean, boolean)
	if raw or self.local_space then
		local first, second = self.build_tools.selection:sample(2)
		
		if first and not second and (first:IsA("BasePart") or first:IsA("Attachment")) then
			return true, first:IsA("Attachment");
		end;
	end;
	
	return false, false;
end

function Draggers:toggle_move_increment(value: boolean?)
	if (value == nil) then
		value = not self:get_move_increment_enabled();
	end;
	
	self.build_tools.preferences:set("move_increment_enabled", value);
end

function Draggers:toggle_rotate_increment(value: boolean?)
	if (value == nil) then
		value = not self:get_rotate_increment_enabled();
	end;
	
	self.build_tools.preferences:set("rotate_increment_enabled", value)
end

function Draggers:get_rotate_increment_enabled()
	return self.build_tools.preferences:get("rotate_increment_enabled");
end

function Draggers:get_move_increment_enabled()
	return self.build_tools.preferences:get("move_increment_enabled");
end

function Draggers:get_move_increment()
	return self.build_tools.preferences:get("move_increment");
end

function Draggers:get_rotate_increment()
	return self.build_tools.preferences:get("rotate_increment");
end

function Draggers:set_move_increment(value: number)
	self.build_tools.preferences:set("move_increment", (tonumber(value) or 0))
end

function Draggers:set_rotate_increment(value: number)
	self.build_tools.preferences:set("rotate_increment", math.rad(tonumber(value) or 0))
end

function Draggers:round_to_move_increment<T>(value: T): T
	
	if not self:get_move_increment_enabled() then
		return value;
	end;
	
	local move_increment = self:get_move_increment();

	if typeof(value) == "number" then
		return Math.SRound(value, move_increment) :: any;

	elseif typeof(value) == "Vector3" then
		return Math.RoundVector3(value, move_increment) :: any;
	end;

	error("Unsupported value");
end

function Draggers:round_to_rotate_increment(value: number): number
	if not self:get_rotate_increment_enabled() then
		return value;
	end;
	
	return Math.SRound(value, self:get_rotate_increment());
end

function Draggers.update_handles(self: Draggers): ()
	local is_local, attachment_based = self:get_local_space(true);
	local scale_space = "Local";
	local handle_space = "Local";
	
	if not (is_local and self.local_space) or attachment_based then
		handle_space = "World";
		scale_space = "World";
	end;
	
	local ctrl_down, alt_down = self.build_tools:is_control_down(), self.build_tools:is_alt_down();
	
	-- ion even know whats going on anymore with this 🥀
	if is_local and ( not ctrl_down or (ctrl_down and alt_down) ) then
		scale_space = "Local";
	end;
	
	-- i never want to touch any of this ever againe
	if is_local and ctrl_down and not alt_down and self.local_space then
		scale_space = "World";
	end
	
	local adornee_local = self.build_tools.selection:next();
	local adornee_world = self.extents_part;
	
	if attachment_based then
		adornee_local = adornee_world;
	end;
	
	local scale_adornee = if scale_space == "World" then adornee_world else adornee_local;
	local handle_adornee = if handle_space == "World" then adornee_world else adornee_local;
	
	for mode, handles in self.handles do
		local use_adornee = if mode == "scale" then scale_adornee else handle_adornee;
		
		for _, handle in handles do
			handle.Adornee = use_adornee;
		end;
	end;
	
	self.current_scale_space = scale_space;
	self.current_handle_space = handle_space;
end

function Draggers.init(self: Draggers)
	local touch_handles_bind = {
		[Enum.UserInputState.Begin] = function()
			self.touching_handles += 1;
		end,

		[Enum.UserInputState.End] = function()
			self.touching_handles -= 1;
		end};
	
	for _, handles in self.handles do
		for _, handle: Handles in handles do
			HelpInput.BindToHandle(handle, touch_handles_bind);
		end;
	end
	
	self:init_move_handles();
	self:init_scale_handles();
	self:init_rotation_handles();
end

function Draggers.init_move_handles(self: Draggers): ()
	local last_distance = 0;
	local selection = self.build_tools.selection;
	local active_handles = {};
	
	local handle_bind = {
		[Enum.UserInputState.Begin] = function(handle)
			active_handles[handle] = true;
			last_distance = 0;
		end,
		
		[Enum.UserInputState.End] = function(handle)
			active_handles[handle] = false;
		end};

	local function mouse_drag(face: Enum.NormalId, distance: number)
		distance = self:round_to_move_increment(distance);

		local look: CFrame;
		local is_local, attachment_based = self:get_local_space();

		if is_local and not attachment_based then
			look = selection:next():GetPivot().Rotation;
		else
			look = selection:get_pivot().Rotation;
		end

		selection:translate_by(look * Vector3.FromNormalId(face) * (distance - last_distance));
		last_distance = distance;
	end
	
	for _, handle in self.handles.move do
		handle.MouseDrag:Connect(function(...)
			if active_handles[handle] then
				mouse_drag(...);
			end
		end)
		HelpInput.BindToHandle(handle, handle_bind)
	end;
end

function Draggers.init_scale_handles(self: Draggers): ()
	local last_scale = 0;
	local instances_scaled = {};
	local active_handles = {};
	
	local alt_down = false;
	local ctrl_down = false;
	local in_local = false;
	
	local selection = self.build_tools.selection;
	
	local handle_bind = {
		[Enum.UserInputState.Begin] = function(handle)
			active_handles[handle] = true;
			last_scale = 0;
		end,

		[Enum.UserInputState.End] = function(handle)
			active_handles[handle] = false;
			
			self.build_tools.actions:bulk_modify(Table.keys(instances_scaled), {"CFrame", "Size"});
			table.clear(instances_scaled);
		end}
	
	local normals = {};
	
	for _, normal in Enum.NormalId:GetEnumItems() do
		table.insert(normals, Vector3.FromNormalId(normal));
	end;
	
	local function scale_part(part: BasePart, normal: Vector3, dt: number)
		if not self.world_aligned and self.current_scale_space == "World" then
			local world_normal = part.CFrame.Rotation:VectorToObjectSpace(normal);
			local max_dot = -math.huge;
			
			for _, axes_normal in normals do
				local dot = world_normal:Dot(axes_normal);
				
				if dot > max_dot then
					normal = axes_normal;
					max_dot = dot;
				end;
			end;
		end;
		
		local direction = math.sign(normal:Dot(Vector3.one));
		local look = CFrame.lookAlong(Vector3.zero, normal);
		
		local size_dt = ( look * CFrame.new(0, 0, -dt * direction) ).Position;
		local pos_dt = ( look * CFrame.new(0, 0, -dt / 2) ).Position;

		local target_size = (part.Size + size_dt);
		
		if target_size.X > 0 and target_size.Y > 0 and target_size.Z > 0 then
			-- Dual sided scaling
			if ctrl_down and alt_down then
				target_size += size_dt;
				pos_dt = Vector3.zero;
			end;
			
			part.CFrame *= CFrame.new(pos_dt);
			part.Size = target_size;

			instances_scaled[part] = true;
		end;
	end
	
	local function mouse_drag(face: Enum.NormalId, distance: number)
		distance = self:round_to_move_increment(distance);

		local dt = (distance - last_scale);
		local look = selection:get_pivot().Rotation:Inverse() :: CFrame
		local normal = Vector3.FromNormalId(face);

		alt_down = self.build_tools:is_alt_down();
		ctrl_down = self.build_tools:is_control_down();
		in_local = self:get_local_space(true);
		
		if (not in_local and not alt_down) or (ctrl_down and not alt_down) then
			local cf, size = selection:get_bounding_box();

			if self.build_tools.settings.scale_pivot_by_axis then
				selection:set_pivot(cf + cf.Rotation * CFrame.lookAlong(Vector3.zero, normal) * CFrame.Angles(0, -math.pi / 2, 0) * size / 2);
			else
				selection:set_pivot(cf);
			end;

			selection:scale_by(dt / 12);

			for instance in selection.items do
				instances_scaled[instance] = true;
			end;
		else
			for instance: PVInstance in selection.pivot_items do
				if instance:IsA("BasePart") then
					scale_part(instance, normal, dt);
				end;
			end;
			
			self.build_tools.actions:update_commit_cframe();
			self.build_tools.actions:update_commit_size();
			
			selection:update_extents();
		end

		last_scale = distance;
	end;
	
	for _, handle in self.handles.scale do
		handle.MouseDrag:Connect(function(...)
			if active_handles[handle] then
				mouse_drag(...);
			end
		end)
		HelpInput.BindToHandle(handle, handle_bind)
	end
end

function Draggers.init_rotation_handles(self: Draggers): ()
	local last_relative_angle = 0;
	local selection = self.build_tools.selection;
	local active_handles = {};
	
	local handle_bind = {
		[Enum.UserInputState.Begin] = function(handle)
			active_handles[handle] = true;
			last_relative_angle = 0;
		end,

		[Enum.UserInputState.End] = function(handle)
			active_handles[handle] = false;
			last_relative_angle = 0;
		end}
	
	local function mouse_drag(axis: Enum.Axis, relative_angle: number, delta_radius: number)
		local relative_angle = self:round_to_rotate_increment(relative_angle)
		local axis_angle = Vector3.FromAxis(axis) * (relative_angle - last_relative_angle);
		local angle =  CFrame.Angles(axis_angle.X, axis_angle.Y, axis_angle.Z);

		selection:rotate_by( angle, self:get_local_space() );
		last_relative_angle = relative_angle;
	end

	for _, handle in self.handles.rotate do
		handle.MouseDrag:Connect(function(...)
			if active_handles[handle] then
				mouse_drag(...);
			end
		end)
		HelpInput.BindToHandle(handle, handle_bind);
	end
end

table.freeze(Draggers);

return Draggers;