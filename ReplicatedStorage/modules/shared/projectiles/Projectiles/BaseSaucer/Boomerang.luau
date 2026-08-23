local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---------------------------------------------------------

local IsClient = RunService:IsClient()
local Assets = ReplicatedStorage.modules.shared.projectiles.Assets.Projectiles;

---------------------------------------------------------

local AenoirEmit = require( ReplicatedStorage.modules.client.replication.EffectUtility.AenoirEmit )
local AenoirUtil = require( ReplicatedStorage.modules.shared.Utilities.Utility.AenoirUtil )
local BaseSaucer = require( script.Parent );

---------------------------------------------------------

local Projectile = setmetatable({}, BaseSaucer);
Projectile.__index = Projectile;
Projectile.name = script.Name;
Projectile.mode = "Replicated";
Projectile.replication_tick = 1 / 20;

---------------------------------------------------------

function Projectile.new(projectile)
	local model = script.Pizza:Clone();
	local self = setmetatable(BaseSaucer.new(projectile), Projectile)
	
	self.model = model;
	self.linear_velocity = model.LinearVelocity;
	
	--self.hitbox = Hitbox.new();
	--self.hitbox.query = "Raycast";
	--self.hitbox.adornee = model;
	--self.hitbox.shape = "Sphere";
	--self.hitbox.group = "Part";
	--self.hitbox.radius = 0;
	--self.hitbox.ignore = {model, workspace.Visuals, workspace.chars};
	
	--self.hitbox.on_hit:Connect(function(hit, result)
	--	if not self.hitbox:get_humanoid_from_part(hit) then
	--		self.has_hit = true;
	--	end;
	--end)
	
	return self;
end

function Projectile:fire(cframe: CFrame, adornee: BasePart)
	self.adornee = adornee;
	self.direction = cframe;
	
	self:pivot_to(cframe)
	
	--self.hitbox:start();
	
	if IsClient then
		AenoirEmit(script.Sound, self.model.Attachment0)
	end;
end

function Projectile:update(elapsed)
	local hit_back = if self.has_hit then 0 else 1;
	local to_adornee_velocity = AenoirUtil.Unit(self.adornee.Position - self.model.Position) * (elapsed * 60 + if self.has_hit then 100 else 0);
	local spin = 0.1 + math.clamp(1 - elapsed / 3, 0, 1) * 0.9;
	local boomerang_velocity = Vector3.new(-75 + math.sin(elapsed * 2 + math.pi / 2) * 100 * spin , 3.5, -90 - math.cos(elapsed * 1.5) * 64) * hit_back + Vector3.new(1, 0.5, 0) * (1 - hit_back) * 25;
	
	self.linear_velocity.VectorVelocity = self.direction:VectorToWorldSpace(boomerang_velocity) + to_adornee_velocity;
	
	BaseSaucer.update(self, elapsed);
end

function Projectile:pivot_to(cframe: CFrame)
	self.model:PivotTo(cframe * CFrame.Angles(0, 0, math.rad(-90)));
end

---------------------------------------------------------

return Projectile;