local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer;

local Planter = {};
Planter.__index = Planter;

function Planter.new()
	local self = setmetatable(
		{
			tag = "FootPlantable";
			plantables = {};
			raycast_params = RaycastParams.new();
		}, 
		Planter);
	
	self:initialise();
	
	return self;
end;

function Planter:update_planter_filter()
	self.raycast_params.FilterDescendantsInstances = CollectionService:GetTagged(self.tag);
end

function Planter:initialise()
	self.raycast_params.FilterType = Enum.RaycastFilterType.Include;
	
	for _, part in CollectionService:GetTagged(self.tag) do
		self:register(part);
	end;
	
	self:update_planter_filter();
	
	CollectionService:GetInstanceAddedSignal(self.tag):Connect(function(part: BasePart)
		self:register(part);
		self:update_planter_filter();
	end)
	
	CollectionService:GetInstanceRemovedSignal(self.tag):Connect(function(part: BasePart)
		self:unregister(part);
		self:update_planter_filter();
	end)
	
	local function character_added(character: Model)
		self.root = character:WaitForChild("HumanoidRootPart", 5);
	end
	
	local function character_removing(character: Model)
		self.root = nil;
	end
	
	if Player.Character then
		task.spawn(character_added, Player.Character);
	end;
	
	Player.CharacterAdded:Connect(character_added)
	Player.CharacterRemoving:Connect(character_removing)
end

function Planter:step_planter(dt: number)
	self.part_planted, self.part_planted_origin = nil, nil;
	
	if not self.root then 
		return;
	end;
	
	local ray = workspace:Raycast(self.root.Position, -Vector3.yAxis * 12.5, self.raycast_params);
	
	if ray then
		self.part_planted = ray.Instance;
		self.part_planted_origin = ray.Instance.CFrame;
	end
end

function Planter:register(part: BasePart)
	self.plantables[part] = true;
	
	if not self.active_connection then
		self.active_connection = RunService.PreRender:Connect(function(dt)
			self:step_planter(dt);
			RunService.PostSimulation:Wait();
			
			if self.part_planted_origin then
				local difference = self.part_planted.Position - self.part_planted_origin.Position;
				
				self.root.CFrame += difference;
			end
		end)
	end
end

function Planter:unregister(part: BasePart)
	if self.plantables[part] then
		self.plantables[part] = nil;
		
		if not next(self.plantables) and self.active_connection then
			self.active_connection:Disconnect();
			self.active_connection = nil;
		end;
	end;
end;

table.freeze(Planter);

return Planter.new();