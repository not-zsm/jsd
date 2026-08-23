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

		--// grab, server -> every client
		grabSet = byteNet.definePacket({
			value = byteNet.struct({
				part = byteNet.inst,
				boundTo = byteNet.inst,
				offset = byteNet.cframe,
				preset = byteNet.optional(byteNet.string),
			}),
		}),

		grabSetBound = byteNet.definePacket({
			value = byteNet.struct({
				part = byteNet.inst,
				boundTo = byteNet.inst,
			}),
		}),

		grabSetOffset = byteNet.definePacket({
			value = byteNet.struct({
				part = byteNet.inst,
				offset = byteNet.cframe,
			}),
		}),

		grabDetach = byteNet.definePacket({ value = byteNet.inst }),

		--// projectiles
		projectileCreate = byteNet.definePacket({
			value = byteNet.struct({
				config = byteNet.inst,
				origin = byteNet.vec3,
				direction = byteNet.vec3,
			}),
		}),

		--// a position stream: a dropped frame costs nothing, the next one
		--// carries the truth
		projectileUpdate = byteNet.definePacket({
			reliabilityType = "unreliable",
			value = byteNet.struct({
				config = byteNet.inst,
				position = byteNet.vec3,
				direction = byteNet.vec3,
			}),
		}),

		--// destruction
		destruction = byteNet.definePacket({
			value = byteNet.struct({
				part = byteNet.inst,
				effect = byteNet.optional(byteNet.string),
			}),
		}),

		clientDestruction = byteNet.definePacket({ value = byteNet.inst }),

		--[[
			Every visual effect in the game.

			directory addresses a module under the VFX folder ("Chara/Onslaught"),
			fn names the method on it, and args is that call's varargs packed with
			table.pack so a trailing nil still counts. unknown carries them by
			reference, which is what a RemoteEvent was doing anyway.

			This replaced two folders of RemoteEvents built at runtime and picked
			from at random to spread load. byteNet already batches a frame's
			packets into one buffer, so the pool bought nothing.
		--]]
		vfx = byteNet.definePacket({
			reliabilityType = "unreliable",
			value = byteNet.struct({
				directory = byteNet.string,
				fn = byteNet.string,
				args = byteNet.optional(byteNet.unknown),
			}),
		}),

		vfxReliable = byteNet.definePacket({
			value = byteNet.struct({
				directory = byteNet.string,
				fn = byteNet.string,
				args = byteNet.optional(byteNet.unknown),
			}),
		}),

		--// announcements
		announce = byteNet.definePacket({
			value = byteNet.struct({
				message = byteNet.string,
				title = byteNet.optional(byteNet.string),
				kind = byteNet.optional(byteNet.string),
			}),
		}),

		systemMessage = byteNet.definePacket({
			value = byteNet.struct({
				name = byteNet.string,
				activity = byteNet.string,
			}),
		}),

		--// collab emotes: the prompt is the shared object both ends key on
		collabProxy = byteNet.definePacket({
			value = byteNet.struct({
				player = byteNet.inst,
				prompt = byteNet.inst,
			}),
		}),

		collabJoined = byteNet.definePacket({ value = byteNet.inst }),

		--// emote input, client -> server
		finishWriting = byteNet.definePacket({ value = byteNet.string }),
		chooseDirection = byteNet.definePacket({ value = byteNet.string }),

		--// combat state, server -> client
		resetJumpFatigue = byteNet.definePacket({ value = byteNet.nothing }),
		frontDashOutput = byteNet.definePacket({ value = byteNet.nothing }),
		wallComboOutput = byteNet.definePacket({ value = byteNet.nothing }),
		wallComboFail = byteNet.definePacket({ value = byteNet.nothing }),

		ragdoll = byteNet.definePacket({ value = byteNet.bool }),
		updateJump = byteNet.definePacket({ value = byteNet.bool }),
		removeAttack = byteNet.definePacket({ value = byteNet.string }),
		updatePivot = byteNet.definePacket({ value = byteNet.inst }),
		characterInfo = byteNet.definePacket({ value = byteNet.unknown }),

		--// keys cross as their Name; byteNet has no EnumItem type
		changeAttackKey = byteNet.definePacket({
			value = byteNet.struct({
				move = byteNet.string,
				key = byteNet.string,
			}),
		}),

		createAttack = byteNet.definePacket({
			value = byteNet.struct({
				move = byteNet.string,
				key = byteNet.string,
				directory = byteNet.string,
				properties = byteNet.optional(byteNet.unknown),
			}),
		}),

		--// one packet for both directions of the walkspeed scale
		scaleSpeed = byteNet.definePacket({
			value = byteNet.struct({
				humanoid = byteNet.inst,
				amount = byteNet.float32,
				divide = byteNet.bool,
			}),
		}),

		setSpeed = byteNet.definePacket({
			value = byteNet.struct({
				humanoid = byteNet.inst,
				value = byteNet.float32,
			}),
		}),

		evasiveOutput = byteNet.definePacket({
			value = byteNet.struct({
				direction = byteNet.string,
				was = byteNet.optional(byteNet.string),
			}),
		}),

		playerKilled = byteNet.definePacket({
			value = byteNet.struct({
				killed = byteNet.inst,
				totalKills = byteNet.uint32,
				kind = byteNet.string,
				extra = byteNet.optional(byteNet.unknown),
			}),
		}),
	}
end)
