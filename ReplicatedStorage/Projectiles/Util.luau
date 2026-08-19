local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Projectiles = ReplicatedStorage.Projectiles.Projectiles;

local Util = {};

function Util.get_projectile_saucer(name: string): any
	local base_projectile_module = Projectiles.BaseSaucer:FindFirstChild(name);
	
	if base_projectile_module then
		return require( base_projectile_module );
	end;
	
	return nil;
end

return Util;