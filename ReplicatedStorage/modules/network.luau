local replicatedStorage = game:GetService("ReplicatedStorage")

local byteNet = require( replicatedStorage.modules.shared.forum.byteNet )

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

		--// what used to be PlayerRemotes: a folder of RemoteEvents cloned into
		--// every Player. A packet carries its sender and sendTo names one
		--// client, so none of that had to exist.
		humanoidDied = byteNet.definePacket({ value = byteNet.nothing }),
		humanoidRevived = byteNet.definePacket({ value = byteNet.nothing }),
		fixCenter = byteNet.definePacket({ value = byteNet.nothing }),
		bloodWarning = byteNet.definePacket({ value = byteNet.nothing }),
		cancelDash = byteNet.definePacket({ value = byteNet.nothing }),
		tryReset = byteNet.definePacket({ value = byteNet.nothing }),

		setCharacter = byteNet.definePacket({ value = byteNet.string }),
		itemAnimations = byteNet.definePacket({ value = byteNet.string }),
		headMovement = byteNet.definePacket({ value = byteNet.bool }),
		headMovementAttach = byteNet.definePacket({ value = byteNet.inst }),
		velocitySettings = byteNet.definePacket({ value = byteNet.unknown }),

		--// nil means "use the default drop", which is not the same as zero
		standUpright = byteNet.definePacket({ value = byteNet.optional(byteNet.float32) }),

		destructibleLoop = byteNet.definePacket({
			value = byteNet.struct({
				offset = byteNet.cframe,
				size = byteNet.vec3,
			}),
		}),

		moveCooldown = byteNet.definePacket({
			value = byteNet.struct({
				move = byteNet.string,
				duration = byteNet.float32,
			}),
		}),

		--// titles
		equipTitle = byteNet.definePacket({ value = byteNet.string }),
		unequipTitle = byteNet.definePacket({ value = byteNet.nothing }),

		loadTitles = byteNet.definePacket({
			value = byteNet.struct({
				kills = byteNet.uint32,
				groupRank = byteNet.uint16,
			}),
		}),

		--// Atonement's minigame, both directions over one packet each
		minigame = byteNet.definePacket({
			value = byteNet.struct({
				action = byteNet.string,
				payload = byteNet.optional(byteNet.unknown),
			}),
		}),

		minigameInput = byteNet.definePacket({
			value = byteNet.struct({
				action = byteNet.string,
				value = byteNet.optional(byteNet.float32),
			}),
		}),

		--// emotes, client -> server
		useEmote = byteNet.definePacket({ value = byteNet.string }),
		claimEmote = byteNet.definePacket({ value = byteNet.nothing }),
		buyEmoteSlots = byteNet.definePacket({ value = byteNet.nothing }),
		buyRandomEmote = byteNet.definePacket({ value = byteNet.nothing }),
		buyLimitedEmote = byteNet.definePacket({ value = byteNet.string }),

		setEmoteSlot = byteNet.definePacket({
			value = byteNet.struct({
				slot = byteNet.string,
				emote = byteNet.string,
			}),
		}),

		--// emotes, server -> client
		emoteRemoved = byteNet.definePacket({ value = byteNet.string }),
		emotesClaimedAll = byteNet.definePacket({ value = byteNet.nothing }),
		emoteSlotsLoaded = byteNet.definePacket({ value = byteNet.bool }),

		--// UpdateSlot was a RemoteFunction returning whether the write took.
		--// byteNet does not do round trips, so the answer comes back as its
		--// own packet and the client paints on that instead of on a return.
		emoteSlotSet = byteNet.definePacket({
			value = byteNet.struct({
				slot = byteNet.string,
				emote = byteNet.string,
			}),
		}),

		emoteGranted = byteNet.definePacket({
			value = byteNet.struct({
				emote = byteNet.string,
				claimType = byteNet.string,
			}),
		}),

		emotesUpdated = byteNet.definePacket({
			value = byteNet.struct({
				emotes = byteNet.unknown,
				slots = byteNet.unknown,
			}),
		}),

		emoteKillClaim = byteNet.definePacket({
			value = byteNet.struct({
				canClaim = byteNet.int32,
				untilNext = byteNet.int32,
				hasAll = byteNet.bool,
			}),
		}),

		--// hotbar, all server -> client
		hotbarUse = byteNet.definePacket({ value = byteNet.string }),
		hotbarShow = byteNet.definePacket({ value = byteNet.string }),
		hotbarHide = byteNet.definePacket({ value = byteNet.string }),
		hotbarRemoveCooldown = byteNet.definePacket({ value = byteNet.string }),

		--// the key is an EnumItem, which byteNet has no type for; its Name
		--// crosses as a string and the client resolves it back
		hotbarAdd = byteNet.definePacket({
			value = byteNet.struct({
				move = byteNet.string,
				key = byteNet.string,
			}),
		}),

		hotbarCooldown = byteNet.definePacket({
			value = byteNet.struct({
				move = byteNet.string,
				duration = byteNet.float32,
			}),
		}),

		hotbarDisplay = byteNet.definePacket({
			value = byteNet.struct({
				move = byteNet.string,
				text = byteNet.optional(byteNet.string),
				tip = byteNet.optional(byteNet.string),
				flash = byteNet.optional(byteNet.unknown),
				important = byteNet.bool,
			}),
		}),
	}
end)
