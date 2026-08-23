--[[
	A byteNet listener with a lifetime.

	packet.listen returns nothing -- it appends to an array the packet keeps and
	offers no way back out. Anything registered per character or per menu would
	therefore pile up, and Job:Task(packet.listen(...)) quietly registers nil.

	This returns a handle with Destroy, which is what Job cleans, so a listener
	can be scoped like any other connection.
--]]
local function connect<T>(Packet : any, Callback : (T, Player?) -> ()) : { Destroy : (any) -> () }
	Packet.listen(Callback)

	local Listeners = Packet.getListeners()

	return {
		Destroy = function()
			local Index = table.find(Listeners, Callback)

			if Index then
				table.remove(Listeners, Index)
			end
		end,
	}
end

return connect
