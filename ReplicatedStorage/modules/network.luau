local ReplicatedStorage = game:GetService("ReplicatedStorage")

local byteNet = require( ReplicatedStorage.modules.shared.forum.byteNet )

--// client -> server sends, server -> client sendTo/sendToAll, both listen(data, player)
--// optional fields are for values that may be absent; unknown cannot carry nil

return byteNet.defineNamespace("game", function()
	return {
		--// client -> server
		switchCharacter = byteNet.definePacket({
			value = byteNet.struct({
				character = byteNet.string,
				icon = byteNet.optional(byteNet.string),
			}),
		}),

		purchase = byteNet.definePacket({
			value = byteNet.struct({
				item = byteNet.string,
				count = byteNet.uint16,
			}),
		}),
	}
end)
