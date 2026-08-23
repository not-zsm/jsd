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

		--// settings: one packet per value shape, so each stays typed
		toggleSetting = byteNet.definePacket({
			value = byteNet.struct({
				setting = byteNet.string,
			}),
		}),

		sliderSetting = byteNet.definePacket({
			value = byteNet.struct({
				setting = byteNet.string,
				value = byteNet.float32,
			}),
		}),

		stringSetting = byteNet.definePacket({
			value = byteNet.struct({
				setting = byteNet.string,
				value = byteNet.string,
			}),
		}),

		--// what the client reports about its own movement and input
		clientLanded = byteNet.definePacket({ value = byteNet.nothing }),
		clientJumped = byteNet.definePacket({ value = byteNet.nothing }),
		dashProximity = byteNet.definePacket({ value = byteNet.nothing }),

		spaceHeld = byteNet.definePacket({ value = byteNet.bool }),
		airState = byteNet.definePacket({ value = byteNet.string }),
		currentDevice = byteNet.definePacket({ value = byteNet.string }),

		--// the main combat input. state is absent for a one-shot move, and
		--// unknown writes a reference index so it cannot carry nil itself
		useMove = byteNet.definePacket({
			value = byteNet.struct({
				move = byteNet.string,
				state = byteNet.optional(byteNet.bool),
				extra = byteNet.optional(byteNet.unknown),
			}),
		}),

		--// server -> client
		--// keys stay capitalised: the client hands this straight to
		--// StarterGui:SetCore("SendNotification", ...), which names them
		notify = byteNet.definePacket({
			value = byteNet.struct({
				Title = byteNet.string,
				Text = byteNet.string,
				Duration = byteNet.optional(byteNet.float32),
				Icon = byteNet.optional(byteNet.string),
			}),
		}),
	}
end)
