local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---------------------------------------------------------

local IsClient = RunService:IsClient();
local Assets = ReplicatedStorage.Projectiles.Assets.Projectiles;

---------------------------------------------------------

local AenoirEmit = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.AenoirEmit )
local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )
local BaseSaucer = require( script.Parent );

---------------------------------------------------------

local Projectile = setmetatable({}, BaseSaucer);
Projectile.__index = Projectile;
Projectile.name = script.Name;
Projectile.mode = "Linear";

---------------------------------------------------------

function Projectile.new(projectile)
	local model = script.Parent.Boomerang.Pizza:Clone();
	local self = setmetatable(BaseSaucer.new(projectile), Projectile)

	self.model = model;
	self.linear_velocity = model.LinearVelocity;
	
	self.linear_velocity.VectorVelocity = Vector3.new(0, 0, -300);
	
	--self.hitbox = Hitbox.new();
	--self.hitbox.query = "Raycast";
	--self.hitbox.adornee = model;
	--self.hitbox.shape = "Sphere";
	--self.hitbox.group = "Part";
	--self.hitbox.radius = 0;
	--self.hitbox.ignore = {model};
	
	return self;
end

function Projectile:fire(cframe: CFrame, adornee)
	self:pivot_to(cframe)--adornee.CFrame);
	--self.hitbox:start();
	self.linear_velocity.VectorVelocity = cframe:VectorToWorldSpace(self.linear_velocity.VectorVelocity) * Vector3.new(1, 0, 1);
	AenoirEmit(script.Sound, self.model.Attachment0)
end

function Projectile:stop(result: RaycastResult?)
	--self.hitbox:stop();
	
	if result then
		local cframe = CFrame.lookAlong(result.Position, result.Normal);
		
		self:pivot_to(cframe * CFrame.Angles(0, 0, math.rad(90)));
		
		if IsClient then
			AenoirUtil.StopEffects(self.model)
			AenoirEmit(script.PizzaCollide, cframe);
		end
	end
end

function Projectile:pivot_to(cframe: CFrame)
	self.model:PivotTo(cframe * CFrame.Angles(0, 0, math.rad(-90)));
end

---------------------------------------------------------

return Projectile;