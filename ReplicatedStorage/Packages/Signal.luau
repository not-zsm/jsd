--!native

--[[------------------------------------------------------------------------------
	 Batched Yield-Safe Signal Implementation
	 This is a Signal class which has effectively identical behavior to a
	 normal RBXScriptSignal, with the only difference being a couple extra
	 stack frames at the bottom of the stack trace when an error is thrown.
	 This implementation caches runner coroutines, so the ability to yield in
	 the signal handlers comes at minimal extra cost over a naive signal
	 implementation that either always or never spawns a thread. 

	 Licence:
	   Licenced under the MIT licence. 

	 Authors:
	   stravant - July 31st, 2021 - Created the file.
--]]------------------------------------------------------------------------------

-- The currently idle thread to run the next handler on
local freeRunnerThread: thread? = nil

-- Function which acquires the currently idle handler runner thread, runs the
-- function fn on it, and then releases the thread, returning it to being the
-- currently idle one.
-- If there was a currently idle runner thread already, that's okay, that old
-- one will just get thrown and eventually GCed.
local function acquireRunnerThreadAndCallEventHandler(fn, ...)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)
	-- The handler finished running, this runner thread is free again.
	freeRunnerThread = acquiredRunnerThread
end

-- Coroutine runner that we create coroutines of. The coroutine can be 
-- repeatedly resumed with functions to run followed by the argument to run
-- them with.
local function runEventHandlerInFreeThread()
	-- Note: We cannot use the initial set of arguments passed to
	-- runEventHandlerInFreeThread for a call to the handler, because those
	-- arguments would stay on the stack for the duration of the thread's
	-- existence, temporarily leaking references. Without access to raw bytecode
	-- there's no way for us to clear the "..." references from the stack.
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

-------------------------------------------------------------------------------------

-- this stravant guy placed the most half-baked type checking i have ever seen
-- so i fixed it

export type ClassConnection<T...> = {
	__index: ClassConnection<T...>;
	
	new: (signal: Signal<T...>, fn: () -> ()) -> Connection<T...>;
	Disconnect: (self: Connection<T...>) -> (),
	Destroy: (self: Connection<T...>) -> (),
}

export type ClassSignal<T...> = {
	__index: ClassSignal<T...>;
	
	new: () -> Signal<T...>;
	Connect: (self: Signal<T...>, Callback: (T...) -> ()) -> Connection<T...>,
	Once: (self: Signal<T...>, Callback: (T...) -> ()) -> Connection<T...>,
	Fire: (self: Signal<T...>, T...) -> (),
	Wait: (self: Signal<T...>, Timeout: number?) -> (T...),
	DisconnectAll: (self: Signal<T...>) -> ();
	Destroy: (self: Signal<T...>) -> ();
}

export type Connection<T...> = typeof(setmetatable({} :: {
	Connected: boolean,

	_signal: Signal<T...>,
	_fn: () -> (),
	_next: Connection<T...>,
	
}, {} :: ClassConnection<T...>));

export type Signal<T...> = typeof(setmetatable({} :: {
	_handlerListHead: Connection<T...>;
	
}, {} :: ClassSignal<T...>));

-------------------------------------------------------------------------------------

-- Connection class
local Connection = {} :: ClassConnection<...any>;
Connection.__index = Connection

function Connection.new(signal, fn)
	return setmetatable(
		{
			Connected = true,
			
			_signal = signal,
			_fn = fn,
			_next = false :: any,
		}, 
		Connection)
end

function Connection:Disconnect()
	self.Connected = false;

	-- Unhook the node, but DON'T clear it. That way any fire calls that are
	-- currently sitting on this node will be able to iterate forwards off of
	-- it, but any subsequent fire calls will not hit it, and it will be GCed
	-- when no more fire calls are sitting on it.
	if self._signal._handlerListHead == self then
		self._signal._handlerListHead = self._next;
	else
		local prev = self._signal._handlerListHead;
		
		while prev and prev._next ~= self do
			prev = prev._next;
		end;
		
		if prev then
			prev._next = self._next;
		end;
	end;
end;

Connection.Destroy = Connection.Disconnect;

-------------------------------------------------------------------------------------

-- Signal class
local Signal = {} :: ClassSignal<...any>
Signal.__index = Signal

function Signal.new()
	return setmetatable(
		{
			_handlerListHead = false :: any,
		}, 
		Signal)
end

function Signal:Connect(Callback)
	local connection = Connection.new(self, Callback);
	
	if self._handlerListHead then
		connection._next = self._handlerListHead;
		self._handlerListHead = connection;
	else
		self._handlerListHead = connection;
	end;
	
	return connection
end

-- Disconnect all handlers. Since we use a linked list it suffices to clear the
-- reference to the head handler.
function Signal:DisconnectAll()
	self._handlerListHead = false :: any;
end

Signal.Destroy = Signal.DisconnectAll;

-- Signal:Fire(...) implemented by running the handler functions on the
-- coRunnerThread, and any time the resulting thread yielded without returning
-- to us, that means that it yielded to the Roblox scheduler and has been taken
-- over by Roblox scheduling, meaning we have to make a new coroutine runner.
function Signal:Fire(...)
	local item = self._handlerListHead;
	
	while item do
		if item.Connected then
			if not freeRunnerThread then
				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread);
				-- Get the freeRunnerThread to the first yield
				coroutine.resume(freeRunnerThread :: any);
			end;
			
			task.spawn(freeRunnerThread :: thread, item._fn, ...)
		end;
		
		item = item._next
	end
end

-- Implement Signal:Wait() in terms of a temporary connection using
-- a Signal:Connect() which disconnects itself.
function Signal:Wait(Timeout: number?)
	local waiting_coroutine = coroutine.running();
	local timeout_thread: thread?;
	local connection;
	
	connection = self:Connect(function(...)
		connection:Disconnect();
		
		if timeout_thread and coroutine.status(timeout_thread) == "suspended" then
			task.cancel(timeout_thread);
		end;
		
		if coroutine.status(waiting_coroutine) == "suspended" then
			task.spawn(waiting_coroutine, ...);
		end;
	end);
	
	if Timeout then
		timeout_thread = task.delay(Timeout, function()
			connection:Disconnect();
			
			if coroutine.status(waiting_coroutine) == "suspended" then
				task.spawn(waiting_coroutine);
			end;
		end)
	end;
	
	return coroutine.yield();
end

-- Implement Signal:Once() in terms of a connection which disconnects
-- itself before running the handler.
function Signal:Once(Callback)
	local connection;
	
	connection = self:Connect(function(...)
		if connection.Connected then
			connection:Disconnect()
		end;
		
		Callback(...)
	end);
	
	return connection;
end

table.freeze(Signal);
table.freeze(Connection);

return Signal;