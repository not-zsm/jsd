local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---------------------------------------------------------

local Remotes = ReplicatedStorage.modules.shared.projectiles.Remotes;
local Projectiles = ReplicatedStorage.modules.shared.projectiles.Projectiles;

---------------------------------------------------------

local Util = require( ReplicatedStorage.modules.shared.projectiles.Util )
local Projectile = require( script.Projectile )

---------------------------------------------------------

local ProjectileHandler = {};
ProjectileHandler.__index = ProjectileHandler;

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

---------------------------------------------------------

function ProjectileHandler:initialise()
	Remotes.Create.OnClientEvent:Connect(function(identifier: number, name: string)
		local projectile = self.identifiers[identifier];

		if projectile then
			projectile:destroy()
		end
		
		self:_create(name, identifier);
	end)
	
	Remotes.Fire.OnClientEvent:Connect(function(identifier: number, cframe: CFrame?, ...)
		local projectile = self.identifiers[identifier];
		
		if projectile then
			projectile:fire(cframe, ...);
		end
	end)
	
	Remotes.Stop.OnClientEvent:Connect(function(identifier: number, cframe: CFrame)
		local projectile = self.identifiers[identifier];
		
		if projectile then
			projectile:stop({Position = cframe.Position, Normal = cframe.LookVector});
			
			if cframe then
				projectile.saucer:pivot_to(cframe);
			end
		end
	end)
	
	Remotes.Update.OnClientEvent:Connect(function(identifier: number, cframe: CFrame)
		local projectile = self.identifiers[identifier];
		
		if projectile then
			projectile.target_cframe = cframe;
		end
	end)
	
	Remotes.Delete.OnClientEvent:Connect(function(identifier: number)
		local projectile = self.identifiers[identifier];
		
		if projectile then
			projectile:destroy()
		end
	end)
end

function ProjectileHandler:update_projectiles(dt: number)
	local parts: {BasePart} = {};
	local cframes: {CFrame} = {};

	for projectile in self.active_projectiles do
		projectile:update(parts, cframes, dt);
	end

	if parts[1] then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged);
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

function ProjectileHandler:is_active(projectile)
	return self.active_projectiles[projectile] ~= nil;
end

function ProjectileHandler:unregister_identifier(identifier: number): ()
	self.identifiers[identifier] = nil;
end

function ProjectileHandler:_create(name: string, identifier: number?)
	
	local base_projectile = Util.get_projectile_saucer(name);
	local saucer = base_projectile.new(self);
	local projectile = Projectile.new(self, identifier, saucer);
	
	if identifier then
		self.identifiers[identifier] = projectile;
	end;
	
	return projectile;
end

---------------------------------------------------------

table.freeze(ProjectileHandler);

return ProjectileHandler.new();