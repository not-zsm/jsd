local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Job = require( replicatedStorage.modules.shared.Utilities.Job )

local Functions = require( script.Functions )

local Projectiles = {}
local Active = {}

---------------------------------------------------------------------------------------

local Projectile = {};
Projectile.__index = Projectile;

function Projectile.new(Config : Configuration, Origin : Vector3, Direction : Vector3)
	local Visualizer = Functions[Config.Name]
	if (Visualizer == nil) then return end
	
	local self = setmetatable({}, Projectile);
	self.Job = Job.new();

	local Visual, TargetCFrame = Visualizer(Origin, Direction)

	self.Visual = Visual
	self.TargetCFrame = TargetCFrame
	self.Config = Config;
	
	Active[Config] = self
	
	self.Job:Task(RunService.PreSimulation:Connect(function(Delta)
		self:Update(Delta)
	end))
	
	Config.Destroying:Once(function()
		self:Destroy()
	end)
	
	return self;
end;

function Projectile:Destroy()
	Active[self.Config] = nil;

	self.Job:Destroy()
	self.Visual:Destroy()
end

function Projectile:Update(Delta : number)
	self.Visual.CFrame = self.Visual.CFrame:Lerp(self.TargetCFrame, 0.4 * (Delta * 60))
end

function Projectile:SetTarget(Position : Vector3, Direction : Vector3)
	self.TargetCFrame = CFrame.lookAlong(Position, Direction)
end

table.freeze(Projectile)

---------------------------------------------------------------------------------------

function Projectiles.Create(Config : Configuration, Origin : Vector3, Direction : Vector3)
	if (Config ~= nil and Config.Parent ~= nil) then
		Projectile.new(Config, Origin, Direction)
	end
end

function Projectiles.Update(Config : Configuration, Position : Vector3, Direction : Vector3)
	local self = Active[Config]

	if self then
		self:SetTarget(Position, Direction)
	end
end

---------------------------------------------------------------------------------------

return Projectiles