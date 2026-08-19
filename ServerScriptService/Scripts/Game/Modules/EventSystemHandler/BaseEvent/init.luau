local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Maid = require( ReplicatedStorage.Packages.Maid )
local Signal = require( ReplicatedStorage.Packages.Signal )

local BaseEvent = {};
BaseEvent.__index = BaseEvent;

function BaseEvent.new(System, Settings)
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			Maid = maid;
			System = System;
			
			Active = false,
			Ended = maid:add(Signal.new());
			Started = maid:add(Signal.new());
			
			Settings = Settings or {};
			Name = "Unknown Event";
		}, 
		BaseEvent);
	
	return self;
end;

function BaseEvent:Initialise()
	
end

function BaseEvent:Spawn()
	print("nothing ...");
end;

function BaseEvent:Start(): ()
	if self.Active then return end;
	
	self.Active = true;
	self.Started:Fire();
end

function BaseEvent:End(Result: string): ()
	if not self.Active then return end;
	
	self.Active = false;
	self.Ended:Fire(Result);
end;

function BaseEvent:Destroy(): ()
	self.Maid:destroy();
end

table.freeze(BaseEvent);

return BaseEvent;