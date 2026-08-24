local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---------------------------------------------------------

local Remotes = replicatedStorage.modules.shared.projectiles.Remotes
local Maid = require( replicatedStorage.packages.Maid )

---------------------------------------------------------

local Projectile = {};
Projectile.__index = Projectile;

function Projectile.new(handler, identifier: number, saucer)
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			destroyed = false;
			
			cframe = CFrame.identity;
			saucer = saucer;
			elapsed = 0;
			last_replication = 0;
			
			hitbox = nil;
			
			maid = maid;
			handler = handler;
			identifier = identifier;
		}, 
		Projectile);
	
	self:initialise();
	
	return self;
end;

---------------------------------------------------------

function Projectile:initialise()

end

function Projectile:fire(cframe: CFrame?, ...)
	if cframe then
		self.cframe = cframe;
	end;
	
	self.saucer:fire(cframe, ...);
	self.saucer:pivot_to(cframe);
	self.saucer.model.Parent = self.handler.simulated;
	self.saucer.model:SetNetworkOwner(nil) -- For some reason the server will give a client ownership the projectile even though they cannot see it.
	
	--if self.hitbox then
	--	self.hitbox:add_to_filter(self.saucer.model);
	--	self.hitbox:start();
	--end;
	
	self.handler:add_to_active(self);
	
	Remotes.Fire:FireAllClients(self.identifier, self.cframe, ...); 
end

function Projectile:stop(result: RaycastResult?)
	self.saucer:stop(result)
	
	if self.hitbox then
		--self.hitbox:stop();
	end
	
	Remotes.Stop:FireAllClients(self.identifier, self:get_cframe());
end

function Projectile:replicate()
	self.last_replication = tick();
	
	Remotes.Update:FireAllClients(self.identifier, self:get_cframe());
end

function Projectile:update(parts, cframes, dt: number)
	self.saucer:update(self.elapsed)
	self.elapsed += dt;
end

function Projectile:get_cframe()
	return self.saucer.model.CFrame;
end

function Projectile:get_position()
	return self.saucer.model.Position;
end

function Projectile:destroy()
	if self.destroyed then return end;
	
	if self.hitbox then
		--self.hitbox:dispose();
		self.hitbox = nil;
	end;
	
	self.destroyed = true;
	self.handler:remove_from_active(self);
	
	self.saucer:destroy();
	self.maid:destroy()
	
	self.handler:unregister_identifier(self.identifier);
	
	Remotes.Delete:FireAllClients(self.identifier);
end

function Projectile:bind_to_update(frequency, callback)
	local elapsed = 0;
	local last = tick();
	local now = last;
	
	self.maid:add(RunService.PreSimulation:Connect(function(dt)
		elapsed += dt;
		now = tick();
		
		if now - last > frequency then
			last = now;
			callback(elapsed, dt);
		end;
	end))
end

---------------------------------------------------------

table.freeze(Projectile);

return Projectile;