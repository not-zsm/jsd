local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require( ReplicatedStorage.Packages.Signal )
local Maid = require( ReplicatedStorage.Packages.Maid )

local Thread = {};
Thread.__index = Thread;

local function callback_handler(self, ...)
	local success, result = pcall(self.callback, ...);

	if not success then
		warn("thread caught an exception:", result);
	end;
	
	self:close();
end;

local function terminate_thread(thread: thread): ()
	-- what the helly 🥀
	--if coroutine.running() == thread then
	--	task.defer(task.cancel, thread);
	--	coroutine.yield();

	--elseif coroutine.status(thread) == "suspended" then
	--	task.cancel(thread);
	--end;
	
	if coroutine.status(thread) == "suspended" then
		task.cancel(thread);
	end;
end

function Thread.new(callback)
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			maid = maid;
			thread = coroutine.create(callback_handler),
			callback = callback;
			
			is_closed = false;
			closed = maid:add( Signal.new() );
		}, 
		Thread);
	
	return self;
end;

function Thread:is_running(): boolean
	if self.thread then
		return coroutine.status(self.thread) == "running";
	end;
	
	return false;
end

function Thread:restart(...)
	local thread = self.thread;
	
	self.thread = coroutine.create(callback_handler)
	self:start(...);
	
	terminate_thread(thread);
end

function Thread:start(...)
	task.spawn(self.thread, self, ...);
end

function Thread:close()
	if self.is_closed then return end;
	
	local thread = self.thread;
	
	self.is_closed = true;
	
	self.closed:Fire();
	self.maid:destroy();
	
	self.thread = nil;
	terminate_thread(thread);
end;

function Thread:destroy()
	self:close();
end

table.freeze(Thread);

return Thread;