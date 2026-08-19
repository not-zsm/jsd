local EventService = {}
EventService.__index = EventService

local Connection = require(script.Connection)

----------------------------------------------------------------

local Main = {}

function Main.new(Deferred : boolean?)
	local self = setmetatable({}, EventService)
	
	self.Connections = {} :: {
		[Connection.Connection] : boolean
	}
	
	self.Deferred = Deferred or false
	
	return self
end

export type EventService = typeof(Main.new(...))

----------------------------------------------------------------

function EventService.Connect(self : EventService, Fn : (... any) -> ()): ()
	local Connection = Connection.new(self, Fn)
	self.Connections[Connection] = true
	
	return Connection
end

function EventService.Once(self : EventService, Fn : (... any) -> ()): ()
	local Connection
	
	Connection = self:Connect(function(...)
		Connection:Disconnect(); Fn(...)
	end)

	return Connection
end

function EventService.Wait(self : EventService): ()
	local Running = coroutine.running()
	
	self:Once(function(...)
		if coroutine.status(Running) == "suspended" then
			coroutine.resume(Running, ...)
		end
	end)

	return coroutine.yield()
end

function EventService.Fire(self : EventService, ...): ()
	for Connection in self.Connections do
		if not Connection.Connected then continue end
		
		if self.Deferred then
			task.defer(Connection.Callback, ...)
		else
			task.spawn(Connection.Callback, ...)
		end
	end
end

function EventService.DisconnectAll(self : EventService): ()
	for Connection in self.Connections do
		Connection:Disconnect()
	end
	
	table.clear(self.Connections)
end

EventService.Destroy = EventService.DisconnectAll

----------------------------------------------------------------

return Main