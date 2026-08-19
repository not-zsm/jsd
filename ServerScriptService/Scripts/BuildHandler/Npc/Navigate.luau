local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")

local Maid = require( ReplicatedStorage.Packages.Maid )
local Signal = require( ReplicatedStorage.Packages.Signal )

local Assets = script.Parent.Assets;

local Navigate = {};
Navigate.__index = Navigate;

function Navigate.new(npc: any)
	local maid = Maid.new();
	local active_maid = Maid.new();
	
	local self = setmetatable(
		{
			npc = npc;
			humanoid = npc.Humanoid;
			
			active_maid = active_maid;
			active_thread = nil;
			active = false;
			
			last_path_to = -math.huge;
			
			current_waypoint = 0;
			debug_points = {};
		}, 
		Navigate);
	
	return self;
end;

function Navigate:create_path(agent)
	self.path = PathfindingService:CreatePath(agent);
end

function Navigate:advance(reached: boolean, point: Vector3)
	if reached and self.current_waypoint < #self.waypoints then
		self.current_waypoint += 1;
		
		local waypoint: PathWaypoint = self.waypoints[self.current_waypoint];
		
		self:walk_to(waypoint.Position, self.no_relative);

		if waypoint.Action == Enum.PathWaypointAction.Jump then
			self.npc.humanoid:ChangeState(Enum.HumanoidStateType.Jumping);
		end
	else
		self:stop_pathing();
	end
end

function Navigate:walk_along_path_to(point: Vector3)
	self.waypoints = self.path:GetWaypoints();
	self.current_waypoint = 1;
	
	-- self:debug(self.waypoints);
	
	self.active_maid:add(self.path.Blocked:Connect(function(waypoint_index)
		if waypoint_index >= self.current_waypoint then
			self:stop_pathing()
		end
	end))

	self.active_maid:add(self.npc.humanoid.MoveToFinished:Connect(function(reached)
		self:advance(reached, point);
	end))

	self:advance(true, point);

	return self;
end

local function path_to(self, point: Vector3)
	local origin = self.npc:get_position();
	local success, result = pcall(self.path.ComputeAsync, self.path, origin, point);
	
	if success and self.path.Status == Enum.PathStatus.Success then
		self:walk_along_path_to(point);
	end
end

function Navigate:is_computing()
	return if self.active_thread then coroutine.status(self.active_thread) == "suspended" else false;
end

function Navigate:is_pathing()
	return self.active;
end

function Navigate:stop_pathing()
	if self.active_thread then
		if coroutine.status(self.active_thread) == "suspended" then
			task.cancel(self.active_thread);
		end;
		
		self.active_thread = nil;
	end;
	
	self.active = false;
	self.active_maid:clean();
	
	self:stop_walking();
end

function Navigate:get_time_since_last_path_to()
	return tick() - self.last_path_to;
end

function Navigate:path_to(point: Vector3)
	self:stop_pathing();
	
	self.last_path_to = tick();
	self.active_thread = task.spawn(path_to, self, point);
end

function Navigate:stop_walking()
	self.npc.humanoid:Move(Vector3.zero);
end;

function Navigate:walk_to(point: Vector3, relative: boolean?)
	if relative then
		self.npc.humanoid:MoveTo(point, self.npc.sensor.root);
	else
		self.npc.humanoid:MoveTo(point);
	end
end

function Navigate:undebug(): ()
	for _, debug_point in ipairs(self.debug_points) do
		debug_point:Destroy();
	end

	table.clear(self.debug_points);
end

function Navigate:debug(waypoints: {PathWaypoint}): ()
	self:undebug();

	for index, waypoint : PathWaypoint in ipairs(waypoints) do
		local Next = waypoints[index + 1];

		local debug_point = Assets.DebugWaypoint:Clone();
		debug_point.Size = Vector3.one * 0.5;
		debug_point.Position = waypoint.Position;
		debug_point.Archivable = false;
		debug_point.Name = "DebugWaypoint";
		debug_point.Parent = workspace.Terrain;

		if Next then
			local debug_line = Assets.DebugLine:Clone();
			debug_line.Size = Vector3.new(1, 1, 0) * 0.1 + Vector3.zAxis * (waypoint.Position - Next.Position).Magnitude;
			debug_line.CFrame = CFrame.lookAt(waypoint.Position:Lerp(Next.Position, 1/2), Next.Position);
			debug_line.Archivable = false;
			debug_line.Name = "DebugWaypoint";
			debug_line.Parent = workspace.Terrain;

			table.insert(self.debug_points, debug_line);
		end;

		table.insert(self.debug_points, debug_point);
	end;
end;

table.freeze(Navigate);

return Navigate;