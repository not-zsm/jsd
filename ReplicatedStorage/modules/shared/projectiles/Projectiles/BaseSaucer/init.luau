local replicatedStorage = game:GetService("ReplicatedStorage")

---------------------------------------------------------

local Assets = replicatedStorage.modules.shared.projectiles.Assets.Projectiles;

---------------------------------------------------------

local AenoirEmit = require( replicatedStorage.modules.client.replication.EffectUtility.AenoirEmit )
local AenoirUtil = require( replicatedStorage.modules.shared.Utilities.Utility.AenoirUtil )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local Signal = require( replicatedStorage.Packages.Signal )

---------------------------------------------------------

local Projectile = {};
Projectile.__index = Projectile;
Projectile.name = script.Name;
Projectile.replication_tick = 1 / 20;

---------------------------------------------------------

function Projectile.new(projectile)
	local self = setmetatable(
		{
			projectile = projectile;
			model = nil;
			
			on_collide = Signal.new();
		}, 
		Projectile);
	
	return self;
end

function Projectile:fire(cframe: CFrame)
	self:pivot_to(cframe);
end;

function Projectile:stop()
	if self.hitbox then
		self.hitbox:stop();
	end;
	
	self.model.Anchored = true;
end

function Projectile:update(elapsed)
	local coordinate = self:get_coordinate();
	local last_coordinate = self.last_coordinate or coordinate;
	
	local result = workspace:Raycast(last_coordinate.Position, (coordinate.Position - last_coordinate.Position), Utility.VisualParams);

	if result and result.Instance.CanCollide then
		self.on_collide:Fire(result);
	end
	
	self.last_coordinate = coordinate;
end

function Projectile:get_coordinate(): CFrame
	return self.model:GetPivot();
end

function Projectile:pivot_to(cframe: CFrame)
	self.model:PivotTo(cframe);
end

function Projectile:destroy()
	self.on_collide:Destroy()
	self.model:Destroy()
end

---------------------------------------------------------

return Projectile;