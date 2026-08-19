local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

export type Bubble = typeof(script.Bubble);

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AenoirEmit = EffectUtility.AenoirEmit

local Rnd = Random.new();

local BubbleHandler = {};
BubbleHandler.__index = BubbleHandler;

function BubbleHandler.new()
	local self = setmetatable(
		{
			active = {};
			bubble_lifetime_goal = {
				Transparency = 1;
			};
			update_connection = nil;
		}, 
		BubbleHandler);
	
	return self;
end;

function BubbleHandler:update(dt: number): ()
	local coordinates = {};
	local parts = {};
	
	for bubble: BasePart, data in self.active do
		data.alive += dt;
		
		bubble.Size = Vector3.one * data.size + Vector3.new( 
			math.sin(data.alive * 6 * data.seed) * data.size / 4, 
			math.cos(data.alive * 5 * data.seed) * data.size / 4, 0
		);
		
		table.insert(coordinates, bubble.CFrame + Vector3.yAxis * dt * data.seed)
		table.insert(parts, bubble);
	end
	
	workspace:BulkMoveTo(parts, coordinates, Enum.BulkMoveMode.FireCFrameChanged);
end

function BubbleHandler:pop(bubble: Bubble): ()
	AenoirEmit(script.Pop, bubble.Attachment, function()
		self:remove(bubble);
	end)
end

-- Use this method to create bubbles
function BubbleHandler:create(coordinate: CFrame, size: number?, lifetime: number): Bubble
	local bubble = script.Bubble:Clone();
	bubble.CFrame = coordinate;
	bubble.Parent = workspace;
	
	if not next(self.active) then
		if self.update_connection then
			self.update_connection:Disconnect();
			self.update_connection = nil;
		end;
		
		self.update_connection = RunService.PreSimulation:Connect(function(dt)
			self:update(dt);
		end);
	end;
	
	self.active[bubble] = {
		alive = 0, 
		size = size or 4, 
		seed = Rnd:NextNumber(0.5, 1)
	};
	
	local tween = TweenService:Create(bubble, TweenInfo.new(lifetime, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), self.bubble_lifetime_goal)
	tween:Play();
	
	tween.Completed:Once(function()
		self:pop(bubble);
	end)
	
	return bubble;
end

-- Use this method to destroy bubbles
function BubbleHandler:remove(bubble: Bubble): ()
	if self.active[bubble] then
		self.active[bubble] = nil;
		
		bubble:Destroy();
		
		if not next(self.active) and self.update_connection then
			self.update_connection:Disconnect();
			self.update_connection = nil;
		end;
	end
end

table.freeze(BubbleHandler);

return BubbleHandler.new();