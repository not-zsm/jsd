local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------------------------------------------------------

local Maid = require( ReplicatedStorage.Packages.Maid )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local Signal = require( ReplicatedStorage.Packages.Signal )

---------------------------------------------------------

local Projectile = {};
Projectile.__index = Projectile;

function Projectile.new(handler, identifier: number?, saucer)
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			destroyed = false;
			
			saucer = saucer;
			elapsed = 0;
			
			origin = CFrame.identity;
			cframe = CFrame.identity;
			target_cframe = CFrame.identity;
			
			maid = maid;
			handler = handler;
			identifier = identifier;
			
			on_collide = maid:add(Signal.new());
		}, 
		Projectile);
	
	return self;
end;

---------------------------------------------------------

function Projectile:update(parts, cframes, dt)
	if self.saucer.mode == "Replicated" then
		table.insert(parts, self.saucer.model);
		table.insert(cframes, self.saucer.model.CFrame:Lerp(self.target_cframe, math.clamp(12 * dt, 0, 1)))
	else
		self.saucer.model.Anchored = false;
		self.saucer:update(self.elapsed);
	end;
	
	self.elapsed += dt;
end

function Projectile:fire(cframe: CFrame?, adornee: BasePart)
	if self.handler:is_active(self) then return end;
	
	self.handler:add_to_active(self);
	
	self.origin = cframe;
	self.target_cframe = cframe;
	
	self.saucer:fire(cframe, adornee);
	self.saucer.model.Anchored = true;
	self.saucer.model.Parent = workspace.Visuals;
end

function Projectile:stop(result: RaycastResult?)
	if not self.handler:is_active(self) then return end;
	self.handler:remove_from_active(self);
	
	self.saucer:stop(result);
	self.saucer.model.Anchored = true;
end

function Projectile:destroy()
	if self.destroyed then return end;
	
	self:stop();
	self.destroyed = true;
	
	self.saucer:destroy();
	self.maid:destroy()
	
	self.handler:unregister_identifier(self.identifier);
	
	if self.hitbox then
		self.hitbox:EndCast();
		self.hitbox:Destroy();
	end;
end

---------------------------------------------------------

table.freeze(Projectile);

return Projectile;