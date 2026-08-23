--[[
	Data for the menus mainClient owns.

	Ported from jjk's UI/config. Colours come from info.movesets so a character
	is described in one place; characterSelect.data is the extra a menu needs
	that a moveset does not carry.
--]]
local Players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

local info = require(replicatedStorage.info)

local Player = Players.LocalPlayer

return {
	characterSelect = {
		-- order they appear in; a key here needs a matching info.movesets entry
		-- and an assets folder under charSelectHelper, or the slot shows empty
		characters = { "chara", "invincible" },

		ea = {},
		admin = { "invincible" },

		data = {
			chara = {
				name = "Chara",
				alias = "the fallen child",
				colour = info.movesets.chara.colour,
			},

			invincible = {
				name = "Invincible",
				alias = "think, Mark",
				colour = info.movesets.invincible.colour,
			},
		},
	},

	shop = {
		SKELETONCHANCE = 20,

		keeper = {
			shopkeeperTypes = { "fnf" },

			-- the first line is special-cased in shopHelper: it gets tenya's
			-- voice and a slower type speed. Do not reorder the first two.
			yap = {
				`tikiiii tenyaaaaa iiiida!`,
				`psst... {Player.DisplayName}? Yeah, you. I've been stuck here for centuries. And I still find this game unready for the arrival of the viltrumite em-`,
				`please spend ALL your money`,
				`activating goon mode`,
				`hows your day been?`,
				`hey there, {Player.DisplayName}!!`,
				`oh, thank GOD {Player.DisplayName} isnt here...`,
				`back again, huh?`,
				`what'll it be this time, {Player.DisplayName}?`,
				`didn't see ya there... heh!`,
				`bleeehhhh`,
				`bro back up`,
				`keep going!`,
				`STOP SCROLLING.`,
				`did someone just say potential? 🤤`,
				`oh how i WISH something motivational would come up 👀👀👀👀👀`,
				`you're gonna buy EVERYTHING, right?!? 🤑`,
				`i am iceman i- i am iceman`,
				`Alpha (α) radiation - A particle consisting of two protons and two neutrons (a helium-4 nucleus). Highly ionising, stopped by a sheet of paper or a few cm of air.`,
				`i been in the hills`,
				`hey dudeman, i'm a dudeman`,
				`how u doin?`,
				`oi oii OIIII... BAAAKEHHHHH!!!!!!!`,
				`beep bap bop skedoop bep`,
				`staaanding heeereee... i reeeaaaalissseee`,
				`life... is roadblox`,
				`release the gubbies`,
				`good robloxian~`,
				`are ya winnin', son?`,
				`man... i'm kinda hungry lowk`,
				`...`,
				`themes n such.`,
				`I feel better in metal than i do in my own skin!`,
				`I truly am a curse!... I truly am a curse!!!`,
				`IIITADORII YUUUJIIIII`,
				`hey guys its me: flying gorilla from my new app on the appstore: flying gorilla. It's a free download, so i hope you- you check it out! and, and i hope-`,
				`oi... hughie.`,

				-- {line, event, delay} -- the event fires a shopHelper:_<event>
				{ 'I like trains', 'train', 1.4 },
				{ `if you see a 'whoop' around here... EVISCERATE him.`, 'whoop', 0 },
				{ `i'm not taking my sneakers off... i am sneakers o'toole!`, 'sneaker', 0 },
			},

			-- keyed by the nir attribute applyOutfit puts on the keeper
			pokeResponses = {
				zsm = {
					`ow! dude what??`,
					`the FUCK did i do to you?`,
					`bro fuck you`,
					`what do you want??`,
					`can you NOT?`,
					`okay! okay! I'm sorry or whatever`,
					`ts GOTTA be ragebait`,
				},

				dih = {
					'h-harder! uwu',
					'hey that... h-hurts.. BAKA! >.<',
					'stawp it... i might like it~',
					"do it again.",
					'heh... that tickles...',
					'dimen stanimirov stoyanov.',
				},

				niki = {
					'h-harder! uwu',
					'hey that... h-hurts.. BAKA! >.<',
					'stawp it... i might like it~',
					"do it again.",
					'heh... that tickles...',
					'okay FINE im shit at art',
					'nichola petkov.',
				},

				pook = {
					"i'm a furry",
					'uuuwu!',
					'*click click*',
					'mmmm minecraft sheep',
					'i look like shit',
					'i am loli god',
					'yo ur my chargie wallahi',
					'This is Not. funny',
					'808 crashout incoming 🤤',
					'dargie you got me',
					'i cracked val',
					'stop being didy',
					'all roads lead to itsrainingfrags',
				},
			},
		},
	},
}
