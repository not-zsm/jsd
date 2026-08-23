local DialogueConfiguration = {}

local SoundService = game:GetService("SoundService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )

local LocalPlayer = game:GetService("Players").LocalPlayer

local NewspaperViewer = require( script.NewspaperViewer )
local Newspaper = NewspaperViewer.new()

DialogueConfiguration.GlobalConfiguration = {
	ShakeDuration = 0.01,
	StartConversationSFX = "rbxassetid://6214955871",
	CloseConversationSFX = "rbxassetid://17779566040",
	PunctuationCharacters = {"!", ".", ",", "?"}
}

DialogueConfiguration.DefaultConfiguration = {
	TypeSpeed = 0.03,
	PunctuationSpeed = 0.2,
	IconIntensity = 3,
	RandomPitch = false,
	SpeakSFX = "rbxassetid://15675032796",

	ColorGradients = {
		Title = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
			ColorSequenceKeypoint.new(1, Color3.new(0.756863, 0.756863, 0.756863)),
		}), 

		Background = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(0.0784314, 0.0784314, 0.0784314)),
			ColorSequenceKeypoint.new(1, Color3.new(0.756863, 0.756863, 0.756863)),
		})
	}
}

DialogueConfiguration.Dialogues = {
	["Carti"] = {
		Dialogue = {
			[1] = {
				Text = "Seeyuh ... finally dropped my album . Trim or na ?",
				Choices = {
					{Text = "That album was absolutely beautiful, inspiring and generational. You cooked", Next = 2},
					{Text = "Album was alright not gonna lie", EndConversation = true},
					{Text = "That was ur worst work, drop wlr deluxe already bro", EndConversation = true}
				},
			},

			[2] = {
				Text = "Fwehh ! BBY BOI next !",
				Choices = {
					{Text = "I can't wait 😭😭😭😭", EndConversation = true}
				}
			},
		},

		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.Carti,

			ColorGradients = {
				Title = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
				}), 

				Background = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
					ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
				})
			}
		}
	},
	
	["Anna"] = {
		Dialogue = {
			[1] = {
				Text = "Hey there! I Haven't see you around here, are you perhaps new to the area?",
				Choices = {
					{Text = "Yes, I am actually.", Next = 2},
					{Text = "omg, felinor from deepwoken?!?!!", Next = 3},
					{Text = "Talk in a bit.", EndConversation = true}
				},
			},
			
			[2] = {
				Text = "Heres a word of advice. Keep away from the residents on this island... If you know whats good for you.",
				Choices = {
					{Text = "Alright, thanks.", EndConversation = true}
				}
			},

			[3] = {
				Text = "No, I think you're in the wrong game sweetie~",
				Choices = {
					{Text = "😅", EndConversation = true}
				}
			}
		},

		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.Anna,
			
			ColorGradients = {
				Title = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(0.992157, 0.870588, 1)),
					ColorSequenceKeypoint.new(1, Color3.new(0.627451, 0.603922, 0.756863)),
				}), 

				Background = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(0.231373, 0.105882, 0.227451)),
					ColorSequenceKeypoint.new(1, Color3.new(1, 0.737255, 0.976471)),
				})
			}
		}
	},
	
	["Remelia"] = {
		Dialogue = {
			[1] = {
				Text = "赤いユリの花はとても美しいですよね？ (Red lily flowers are so beautiful, aren't they?)",
				Choices = {
					{Text = "What about it?", Next = 2},
					{Text = "What is up with this place?", Next = 4},
					{Text = "What's cookin, good looking 😉", Next = 3},
					{Text = "yeah uhh, how about later?", EndConversation = true}
				},
			},
			
			[2] = {
				Text = "Legends says that it was this time of year when... Nevermind. あなたに言っても無駄です (It'd be useless to tell you)",
				Choices = {
					{Text = "uhhuh. see you later?", EndConversation = true}
				},
			},
			
			[3] = {
				Text = "あなたは迷惑だ (You're annoying)",
				Choices = {
					{Text = "aww man", EndConversation = true}
				},
			},
			
			[4] = {
				Text = "知りたくないの (Wouldn't you like to know?)",
				Choices = {
					{Text = "whatever", EndConversation = true}
				},
			},
		},
		
		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.Remelia,
		}
	},
	
	["FadeUnchanged"] = {
		Dialogue = {
			[1] = {
				Text = "bro, i don even why im in this gaaameee.. this game is buns broOO........ LET ME OUTT........... LET MEEE OUTTTTTTTTTT!!!! AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHHHHHHHH!!",
				Choices = {
					{Text = "you crazy lil bro", EndConversation = true}
				},
			},
		},
		
		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.FadeUnchanged
		}
	},
	
	["Anectdote"] = {
		Dialogue = {
			[1] = {
				Text = "Jump Showdown is so peak and I'm the best Jump Showdown player in the world, also, you should totally subscribe to me, anectdote",
				Choices = {
					{Text = "Yes!", EndConversation = true},
					{Text = "No.", EndConversation = true},
				},
			},
		},

		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.Anectdote,
			TypeSpeed = 0.04
		}
	},
	
	["Jimpee"] = {
		Dialogue = {
			[1] = {
				Text = "Wsg bruzz.. You want me to call up cursed child? it'll cost you tho.",
				Choices = {
					{Text = "yes sir", Function = function()
						network.spawnCharaBoss.send()
					end,
					EndConversation = true},
					{Text = "nah srry", EndConversation = true},
				},
			},
		},

		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.Jimpee,
			TypeSpeed = 0.0325
		}
	},
	
	["Wellworks"] = {
		Dialogue = {
			[1] = {
				Text = "The Strongest Battlegrounds is, a lot less chaotic than this. I don't even know why im here in the first place. Just, don't let Jimpee know that we're down here.",
				Choices = {
					{Text = "aight bro i gotchu", EndConversation = true}
				},
			},
		},

		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.Wellworks
		}
	},
	
	["Mark"] = {
		Dialogue = {
			[1] = {
				Text = "hello there everybody my name is markiplier and today we will be playing some jump showdown",
				Choices = {
					{Text = "oh my god is that the real markiplier??", Next = 2},
					{Text = "bah bye!", EndConversation = true}
				},
			},
			
			[2] = {
				Text = "i know i know its me markiplier markiplier playing jump showdown markiplier.. and i have a quest for you that you can do for me that i- i need doing you need to do it yeess",
				Choices = {
					{Text = "maybe next time", EndConversation = true}
				},
			},
		},

		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.Mark
		}
	},
	
	["Todd"] = {
		Dialogue = {
			[1] = {
				Text = "*SIGHHHHH* HUH? What is it? Something on my face?",
				Choices = {
					{Text = "There are a lot of people here huh?", Next = 2},
					{Text = "no i don't think so", EndConversation = true}
				},
			},
			
			[2] = {
				Text = "We're the only ones here aside from you all. Where did you people COME from anyway?",
				Choices = {
					{Text = "no idea bro", EndConversation = true},
				},
			},
		},

		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.Todd
		}
	},
	
	
	["TheCookieGuy"] = {
		Dialogue = {
			[1] = {
				Text = "You know, I wouldn't mind some milk and cookies right about now. 😍",
				Choices = {
					{Text = "sorry i ate them", EndConversation = true}
				},
			},
		},

		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.TheCookieGuy
		}
	},
	
	["Bald Gojo"] = {
		Dialogue = {
			[1] = {
				Text = "Last thing I remember was me doing a hollow purple, now I'm suddenly here. Something's off about this place, I feel no cursed energy at all except for you people.",
				Choices = {
					{Text = "why are you bald LOL", EndConversation = true}
				},
			},
		},
		
		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines["The Strongest"]
		}
	},
	
	["Sketch"] = {
		Dialogue = {
			[1] = {
				Text = "jump showdown is my favorite game. jimpee did not pay me to say this. is that good? no dude, i don't want to do it again. no i'm not doing it again ",
				Choices = {
					{Text = "light up light up sketchers", EndConversation = true}
				},
			}
		},
		
		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.Sketch
		}
	},
	
	["HW5567"] = {
		Dialogue = {
			[1] = {
				Text = "YO! I don't really know these people here that much, but they've been chill, so we're getting along. After we're done here though, I'm gonna go grind some tower defense games.",
				Choices = {
					{Text = "is that.. a wig?", EndConversation = true}
				},
			}
		},
		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.HW5567
		}
	},
	
	["Mymy32100"] = {
		Dialogue = {
			[1] = {
				Text = "Hey! Do you need somethin'?",
				Choices = {
					{Text = "Nope", EndConversation = true}
				},
			}
		},
		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.Mymy32100
		}
	},
	
	["News Boy"] = {
		Dialogue = {
			[1] = {
				Text = "here for the letta' brotha?",
				Choices = Newspaper:GetChoices()
			}
		},
		Configuration = {
			
		}
	},
	
	["BruhSalino"] = {
		Dialogue = {
			[1] = {
				Text = "wanna tune into some of JSD's OST?",
				Choices = {
					{Text = "tune me in!", EndConversation = true, Function = function()
						require( script.Parent.Modules.SongPlayer )()
					end},
					
					{Text = "no thanks", EndConversation = true}
				}
			}
		},
		Configuration = {

		}
	},
	
	["Deku"] = {
		Dialogue = {
			[1] = {
				Text = "H-Hey!... it's me DEKU!....... i've been working here part time at Mr. Mymy's store. Did you know i actually saved the world once?",
				Choices = {
					{Text = "Your a great hero man, I really look up to you!", Next = 2},
					{Text = "just ring these up for me lil bro.", Next = 3},
					{Text = "c pro... I DONT CARE", EndConversation = true}
				},
			},
			
			[2] = {
				Text = "huh.....Oh..WOW!.....Only kachan has ever said that to me before!!",
				Choices = {
					{Text = "heh...", EndConversation = true}
				},
			},

			[3] = {
				Text = "*shameless crying*",
				Choices = {
					{Text = "ez", EndConversation = true}
				},
			}
		},
		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.Deku
		}
	},

	["Tough"] = {
		Dialogue = {
			[1] = {
				Text = "out of any game you could have played, you played this one????? this game is TRAAAAAAAAAAAAAAAAAAASSHHHHHH UHH",
				Choices = {
					{Text = "UR buns kid", EndConversation = true}
				},
			}
		},
		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.Tough
		}
	},
	
	["Black Market Dealer"] = {
		Dialogue = {
			[1] = {
				Text = "You got five seconds before I lose interest. I don't deal in small talk, only serious business, and I don't see no Weapons Crate on your back.",
				Choices = {
					{Text = "Weapons Crate?", Next = 2},
					{Text = "yeah whatever man", EndConversation = true}
				},
			},
			
			[2] = {
				Text = "Sometimes when the military runs their high-altitude supply runs, a few cargo planes go off-course due to the weather. One little accident and boom, crate falls outta the sky like a gift from the gods above. Usually packed with suppressed tech, prototypes, or stuff that's... not meant to be public.",
				Choices = {
					{Text = "What if I happen to find one?", Next = 3},
					{Text = "you're crazy man", EndConversation = true}
				},
			},
			
			[3] = {
				Text = "You bring it to me. No questions. You’ll be compensated... generously. But if someone else gets it first? Grab it right off them and run for it as fast as you can.",
				Choices = {
					{Text = "I'll be on the lookout.", EndConversation = true}
				},
			},
			
			[4] = {
				Text = "Well, look who found me some treasure. This could go for a pretty penny if you know where to look. Well, a deal's a deal. You want more work like this? Keep your ears open and your mouth shut. There’s more falling from the sky than just rain.",
				Choices = {
					{Text = "Sounds good.", EndConversation = true}
				},
			}
		},
		Configuration = {
			TypeSpeed = 0.04,
			RandomPitch = true,
			SpeakSFX = "rbxassetid://5008607047"
		}
	},
	
	["Benzen"] = {
		Dialogue = {
			[1] = {
				Text = "Do you need something, customer?",
				Choices = {
					{Text = "uh, what's in the room behind you?", Next = 2},
					{Text = "what's up with those other two?", Next = 3},
					{Text = "i'll keep looking around", EndConversation = true}
				}
			},
			
			[2] = {
				Text = "Nothing to worry about, you should probably go back to playing those arcade games.",
				Choices = {
					{Text = "okay then...", EndConversation = true}
				}
			},
			
			[3] = {
				Text = "Jade and Molly? Comrades in ar- I mean, just co-workers I suppose... We aren't related in the slightest.",
				Choices = {
					{Text = "cool beans", EndConversation = true}
				}
			}
		},
		
		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.Benzen,
			TypeSpeed = 0.05,
			PunctuationSpeed = 0.4,
			
			ForceTypingSFX = true,
			TypingSFXVolume = 0.3,
		}
	},
	
	["Jade"] = {
		Dialogue = {
			[1] = {
				Text = "Do you need something?",
				Choices = {
					{Text = "who even are you guys?", Next = 2},
					{Text = "how can I use the arcade machines?", Next = 3},
					{Text = "no thanks", EndConversation = true}
				}
			},

			[2] = {
				Text = "Don't worry about us, just a local business trying to set up shop. We won't be here long.",
				Choices = {
					{Text = "alright", EndConversation = true}
				}
			},

			[3] = {
				Text = "The machines you can use for free, just don't make a mess.",
				Choices = {
					{Text = "no promises", EndConversation = true}
				}
			}
		},

		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.Jade,
			TypeSpeed = 0.035,
			PunctuationSpeed = 0.4,

			ForceTypingSFX = true,
			TypingSFXVolume = 0.3,
		}
	},
	
	["Molly"] = {
		Dialogue = {
			[1] = {
				Text = "Let's hope this, pitstop, doesn't last long.",
				Choices = {
					{Text = "pitstop?", Next = 2},
					{Text = "goodbye", EndConversation = true}
				}
			},

			[2] = {
				Text = "Ohhh haha!! I was just thinking out loud.. don't mind me!",
				Choices = {
					{Text = "erm okay", EndConversation = true}
				}
			},
		},

		Configuration = {
			SoundFolder = SoundService.DialogueVoicelines.Molly,
			TypeSpeed = 0.03,
			PunctuationSpeed = 0.4,

			ForceTypingSFX = true,
			TypingSFXVolume = 0.3,
		}
	}
}



return DialogueConfiguration
