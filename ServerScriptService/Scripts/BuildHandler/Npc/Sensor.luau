local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

local Signal = require( ReplicatedStorage.Packages.Signal )
local BuildHandler = require("../../BuildHandler")

local Sensor = {};
Sensor.__index = Sensor;

function Sensor.new(npc: any)
	local self = setmetatable(
		{
			npc = npc;
			filter_descendants = { workspace.Models };
			filter_tagged_humanoids = "CombatHumanoid";
			last_search_time = -1;
			
			cache = {};
			seen_ignore_list = {};
			target_changed = Signal.new();
		}, 
		Sensor);
	
	self:initialise();
	
	return self;
end;

function Sensor:initialise(): ()
	self.seen_params = RaycastParams.new();
	self.seen_params.FilterType = Enum.RaycastFilterType.Exclude;
end

function Sensor:flush()
	table.clear(self.cache);
end

function Sensor:get_seen(flush: boolean?)
	if not self.root then
		return false;
	end;
	
	if not self.cache.seen_ray or flush then
		local origin = self.npc:get_position();
		local target = self:get_position();
		local result = workspace:Raycast(origin, target - origin, self.seen_params);
		
		if self.cache.seen_ray then
			self.cache.seen_ray.result = result;
		else
			self.cache.seen_ray = {result = result};
		end
		
		return result == nil;
	end;

	return self.cache.seen_ray.result == nil;
end

function Sensor:get_range(): number
	if not self.root then
		return math.huge;
	end;
	
	return ( self.root.Position - self.npc:get_position() ).Magnitude
end

function Sensor:get_position(offset: Vector3): Vector3
	if not self.root then
		return self.npc:get_position();
	end;
	
	local origin = self.npc:get_position();
	local direction = self.root.Position - origin;
	local unit = if direction.Magnitude < 1e-5 then Vector3.zero else direction.Unit;
	
	return self.root.Position + unit * (if offset then offset else Vector3.zero);
end

function Sensor:search(): ()
	self.last_search_time = tick();
	
	local nearest = nil;
	local distance = math.huge;
	local origin = self.npc:get_position();
	
	local function consider_humanoid(humanoid: Humanoid)
		if 
			humanoid.Health <= 0 or 
			not humanoid.RootPart or 
			humanoid == self.npc.humanoid or 
			humanoid:HasTag("EntityAI") or
			(humanoid.Parent and humanoid.Parent:GetAttribute("Jailed"))
		then
			return;
		end;

		local magnitude = (origin - humanoid.RootPart.Position).Magnitude;

		if magnitude < self.npc.range and magnitude < distance then
			nearest = humanoid;
			distance = magnitude;
		end;
	end;
	
	if self.filter_tagged_humanoids then
		for _, humanoid in CollectionService:GetTagged(self.filter_tagged_humanoids) do
			consider_humanoid(humanoid);
		end;
	end;
	
	for _, instance in self.filter_descendants do
		for _, rig in instance:GetChildren() do
			if not rig:IsA("Model") then
				continue;
			end;
			
			local humanoid = rig:FindFirstChildOfClass("Humanoid");
			
			if humanoid then
				consider_humanoid(humanoid);
			end
		end
	end;
	
	if self.humanoid ~= nearest then
		local last = self.humanoid;
		
		if nearest then
			self.humanoid = nearest;
			self.root = nearest.RootPart;
			self.rig = nearest.Parent;
			self.combat = BuildHandler:get_combat(self.rig);
			
			self.seen_params.FilterDescendantsInstances = { self.rig, self.npc.rig, unpack(self.seen_ignore_list) };
		else
			self.combat = nil;
			self.humanoid = nil;
			self.root = nil;
			self.rig = nil;
			
			self.seen_params.FilterDescendantsInstances = { self.rig, unpack(self.seen_ignore_list) };
		end
		
		self.target_changed:Fire(nearest, last);
	end
end

table.freeze(Sensor);

return Sensor;