local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---------------------------------------------------------

local Remotes = ReplicatedStorage.modules.shared.projectiles.Remotes;

---------------------------------------------------------

local Util = require( ReplicatedStorage.modules.shared.projectiles.Util )
local Projectile = require( script.Projectile )

---------------------------------------------------------

local ProjectileHandler = {};
ProjectileHandler.__index = ProjectileHandler;

---------------------------------------------------------

function ProjectileHandler.new()
	local self = setmetatable(
		{
			identifiers = {};
			active_projectiles = {};
		}, 
		ProjectileHandler);
	
	ProjectileHandler.initialise(self);
	
	return self;
end;

function ProjectileHandler:initialise()
	self.simulated = Instance.new("Camera");
	self.simulated.Name = "ProjectilesServer";
	self.simulated.Parent = workspace;
end

function ProjectileHandler:get_new_identifier(): number
	for identifier = 0, 65535 do
		if not self.identifiers[identifier] then
			return identifier;
		end;
	end;
	
	error("Reached the max limit of 65536 projectiles at once")
end

function ProjectileHandler:update_projectiles(dt: number)
	local parts: {BasePart} = {};
	local cframes: {CFrame} = {};
	local now = tick();
	
	for projectile in self.active_projectiles do
		projectile:update(parts, cframes, dt);
	end

	if parts[1] then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged);
	end;
	
	for projectile in self.active_projectiles do
		if projectile.saucer.mode == "Replicated" and now - projectile.last_replication > projectile.saucer.replication_tick then
			projectile:replicate();
		end;
	end;
end

function ProjectileHandler:add_to_active(projectile)
	if not self.active_projectiles[projectile] then
		if not next(self.active_projectiles) then
			self.update_projectile_connection = RunService.PreSimulation:Connect(function(dt)
				self:update_projectiles(dt);
			end)
		end

		self.active_projectiles[projectile] = true;
	end
end

function ProjectileHandler:remove_from_active(projectile)
	if self.active_projectiles[projectile] then
		self.active_projectiles[projectile] = nil;

		if not next(self.active_projectiles) then
			self.update_projectile_connection:Disconnect()
		end
	end
end

function ProjectileHandler:unregister_identifier(identifier: number): ()
	self.identifiers[identifier] = nil;
end

function ProjectileHandler:create(name)
	local identifier = self:get_new_identifier();
	
	local base_projectile = Util.get_projectile_saucer(name);
	local saucer = base_projectile.new(self);
	local projectile = Projectile.new(self, identifier, saucer);
	
	self.identifiers[identifier] = projectile;
	
	Remotes.Create:FireAllClients(identifier, name);
	
	return projectile;
end

---------------------------------------------------------

table.freeze(ProjectileHandler);

return ProjectileHandler.new();