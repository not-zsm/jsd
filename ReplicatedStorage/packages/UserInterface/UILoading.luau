-----------------------------------------------------------------------------

local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-----------------------------------------------------------------------------

local Assets = script.Assets;

local Maid = require( replicatedStorage.packages.Maid )
local Signal = require( replicatedStorage.packages.Signal )

-----------------------------------------------------------------------------

export type ClassUILoading = {
	__index: ClassUILoading;

	new: (parent: Instance?) -> UILoading;
	destroy: (self: UILoading) -> ();
	set: (self: UILoading, value: boolean) -> ();
};

export type UILoading = typeof(setmetatable({} :: {
	
	stacks: number;
	is_loading: boolean;
	maid: Maid.Maid;
	frame: any;
	changed: Signal.Signal<>;
	
}, {} :: ClassUILoading));

-----------------------------------------------------------------------------

local UILoading = {} :: ClassUILoading;
UILoading.__index = UILoading;

function UILoading.new(parent)
	local maid = Maid.new();

	local self = setmetatable(
		{
			stacks = 0;
			is_loading = false;
			maid = maid;
			frame = Assets.Loading:Clone();
			changed = Signal.new();
		}, 
		UILoading);

	if parent then
		self.frame.Parent = parent;
	end;
	
	return self;
end;

function UILoading:destroy(): ()
	self.frame:Destroy();
	self.changed:Destroy();
	self.maid:destroy();
end;

-----------------------------------------------------------------------------

function UILoading:reset()
	self:set(false);
	self.stacks = 0;
end;

function UILoading:push(): ()
	self.stacks += 1;
	
	if self.stacks == 1 then
		self:set(true);
	end;
end;

function UILoading:pop(): ()
	if self.stacks <= 0 then return end;
	
	self.stacks -= 1;
	
	if self.stacks == 0 then
		self:set(false);
	end;
end;

function UILoading:set(value: boolean): ()
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
end;

-----------------------------------------------------------------------------

table.freeze(UILoading);

return UILoading;