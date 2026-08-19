local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Assets = script.Parent.Assets;
local Maid = require( ReplicatedStorage.Packages.Maid )
local Signal = require( ReplicatedStorage.Packages.Signal )

local Loading = {};
Loading.__index = Loading;

function Loading.new(parent)
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			is_loading = false;
			maid = maid;
			frame = Assets.Loading:Clone();
			changed = Signal.new();
		}, 
		Loading);
	
	if parent then
		self.frame.Parent = parent;
	end
	
	return self;
end;

function Loading:destroy()
	self.frame:Destroy();
	self.changed:Destroy();
	self.maid:destroy();
end

function Loading:set(value: boolean)
	self.maid:clean();
	self.is_loading = value;
	
	if value then
		self.frame.Visible = true;
		
		self.maid:add(RunService.PreRender:Connect(function(dt)
			self.frame.Icon.Rotation += 360 * dt;
		end))
	else
		self.frame.Visible = false;
	end
	
	self.changed:Fire(value);
end

table.freeze(Loading);

return Loading;