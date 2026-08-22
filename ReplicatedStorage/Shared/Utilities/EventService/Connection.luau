local Connection = {}
Connection.__index = Connection

----------------------------------------------------------------

local Main = {}

function Main.new(EventHandler : {}, Callback : () -> ())
	local self = setmetatable({}, Connection)
	self.EventHandler = EventHandler
	self.Callback = Callback
	
	self.Connected = true
	
	return self
end

export type Connection = typeof(Main.new(...))

----------------------------------------------------------------

function Connection.Disconnect(self : Connection)
	if not self.Connected then
		return
	end

	self.Connected = false
	self.EventHandler.Connections[self] = nil
end

Connection.Destroy = Connection.Disconnect

return Main