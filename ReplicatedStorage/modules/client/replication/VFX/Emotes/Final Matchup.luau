type R6 = typeof(script.Rigs.Friend)

local CollectionService = game:GetService("CollectionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Yuki_FOV = require( replicatedStorage.modules.client.replication.Global.Yuki_FOV )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local RunCameraRig = require( replicatedStorage.modules.client.replication.Global.RunCameraRig )
local AttributeListener = require( replicatedStorage.modules.client.replication.Global.AttributeListener )

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )

local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Afterimage = require( replicatedStorage.modules.client.replication.Global.Afterimage )

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local CharacterTransparency = require( replicatedStorage.modules.client.replication.Global.CharacterTransparency )

local Yuki_Emit = require(script.Yuki_Emit)

local Dialogue = require(replicatedStorage.modules.effect.tekrinnDialogue)

local JobApplication = require( replicatedStorage.modules.shared.Utilities.Job )

local Animations = replicatedStorage.animations.Emotes["Final Matchup"]

local AttackerVFX = script.Effects.Attacker
local VictimVFX = script.Effects.Victim

local function cutesey_arc_vfx_emitter(instance : Instance, parent : Instance)
	local clone = instance:Clone()
	clone.Parent = parent
	EffectUtility.Arc.EmitAttachment(clone)
end

local function MxitzEmit(instance : Instance, parent : Instance)
	local clone = instance:Clone()
	clone.Parent = parent
	Yuki_Emit.Emit(clone)
	return clone
end

local DefaultSlowdownInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local DefaultResumeInfo = TweenInfo.new(0, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local DoesSlowDown = {
	E1 = {
		Delay = 11/60,
		Resume = 79/60,
		DelayInfo = DefaultSlowdownInfo,
		ResumeInfo = DefaultResumeInfo
	},
	
	idk = {
		Delay = 11/60,
		Resume = 214/60,
		DelayInfo = DefaultSlowdownInfo,
		ResumeInfo = DefaultResumeInfo
	},
	
	idk2 = {
		Delay = 11/60,
		Resume = 92/60,
		DelayInfo = DefaultSlowdownInfo,
		ResumeInfo = DefaultResumeInfo
	},
}

local CCFrames = {
	[0] = {
		Brightness = -0.08,
		Contrast = 0.05,
		Saturation = 0.5,
		TintColor = Color3.new(1, 0.972549, 0.929412)
	},
	[3934] = {
		Brightness = -0.08,
		Contrast = 0.05,
		Saturation = 0.5,
		TintColor = Color3.new(1, 0.972549, 0.929412)
	},
	[3935] = {
		Brightness = 111111,
		Contrast = 250,
		Saturation = -0.25,
		TintColor = Color3.new(1, 0.972549, 0.929412)
	},
	[3936] = {
		Brightness = -1,
		Contrast = 500,
		Saturation = -1,
		TintColor = Color3.new(1, 0.972549, 0.929412)
	},
	[3938] = {
		Brightness = -15555,
		Contrast = -11,
		Saturation = 11111,
		TintColor = Color3.new(0.941177, 0.145098, 1)
	},
	[3939] = {
		Brightness = -1111111,
		Contrast = 0,
		Saturation = 5555,
		TintColor = Color3.new(0.941177, 0.145098, 1)
	},
	[3940] = {
		Brightness = 2555,
		Contrast = -15555,
		Saturation = -1,
		TintColor = Color3.new(0.941177, 0.145098, 1)
	},
	[3942] = {
		Brightness = -0.08,
		Contrast = 0.05,
		Saturation = 0.5,
		TintColor = Color3.new(1, 0.972549, 0.929412)
	},
	[3944] = {
		Brightness = 111,
		Contrast = 1,
		Saturation = 0.5,
		TintColor = Color3.new(1, 0.972549, 0.929412)
	},
	[3945] = {
		Brightness = -0.08,
		Contrast = 0.05,
		
		Saturation = 0.5,
		TintColor = Color3.new(1, 0.972549, 0.929412)
	},
	[3946] = {
		Brightness = -111,
		Contrast = 1,
		Saturation = 0.5,
		TintColor = Color3.new(1, 0.972549, 0.929412)
	},
	[3947] = {
		Brightness = -0.08,
		Contrast = 0.05,
		Saturation = 0.5,
		TintColor = Color3.new(1, 0.972549, 0.929412)
	}
}

local FriendData = {
	Nagi = {
		Offset = CFrame.new(0, 0, -2, 1, 0, 0, 0, 1, 0, 0, 0, 1),
		SpawnDelay = 770/60,
	},

	Barou = {
		Offset = CFrame.new(0, 0, -4, 1, 0, 0, 0, 1, 0, 0, 0, 1),
		SpawnDelay = 367/60,
	},

	Isagi = {
		Offset = CFrame.new(0, 0, -6, 1, 0, 0, 0, 1, 0, 0, 0, 1),
		SpawnDelay = 0,
	}
}

local ExtraImageSize = UDim2.fromOffset(15, 15)

local IconImages = {
	Sae = "120299790098008",
	Rin = "112438431567646",
	Nagi = "86451690558257",
	Staidum = "120461454545039",
	Fan = "122793755620724",
	Commentator = "17189234841",
	Isagi = "89531478481726", -- GOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
	Barou = "93783521803820",
}

local function GetNextFrame(currentFrame, framesTable)
	local nextFrame = nil
	local smallestDiff = math.huge
	
	for frame in framesTable do
		if frame > currentFrame and (frame - currentFrame) < smallestDiff then
			nextFrame = frame
			smallestDiff = frame - currentFrame
		end
	end
	
	return nextFrame
end

local Loading = false

local function Load()
	if Loading then return end
	
	Loading = true
	
	StarterGui:SetCore("SendNotification", {
		Title = "Notification",
		Text = "Loading the Final Matchup emote, this may take a little.",
		Duration = 1.5
	})
end

return {
	Start = function(Attacker : R6, Victim : R6, FriendIds : {[string] : {[string] : any}})
		local UUID = `A{Attacker.Name}V{Victim.Name}T{os.clock()}`
		
		local Retrieved = AnimationRetriever.new(Attacker, Animations.Keyframeless)
		if (Retrieved == nil) then return end

		local KeyframlessTrack = Retrieved.Animation
		local Job = Retrieved.Job
		
		local Map = Job:Task(script.Map:Clone())
		Map:PivotTo(CFrame.new(0, 750, 2000) * CFrame.Angles(0, 0, math.pi/2))
		Map.Parent = workspace.Visuals
		
		local AttackerClone = Job:Task(script.Rigs.Friend:Clone())
		AttackerClone.Name = Attacker.Name
		AttackerClone.HumanoidRootPart.CFrame = Map.Centre.CFrame * CFrame.new(2.9384973, 6.96754569e-06, -80.5494308, 0, 1, 0, -1, 0, 0, 0, 0, 1)
		AttackerClone.Parent = Map
		AttackerClone.Humanoid:ApplyDescription(Attacker.Humanoid:GetAppliedDescription())
		
		local RootPart = AttackerClone.HumanoidRootPart
		
		local VictimClone = Job:Task(script.Rigs.Friend:Clone())
		VictimClone.Name = Victim.Name
		VictimClone.HumanoidRootPart.CFrame = RootPart.CFrame * CFrame.new(0, 0, -22, -1, 0, 0, 0, 1, 0, 0, 0, -1)
		VictimClone.Parent = Map
		VictimClone.Humanoid:ApplyDescription(Victim.Humanoid:GetAppliedDescription())
		
		for _, Item in AttackerClone:GetChildren() do
			if not (Item:IsA("Shirt") or Item:IsA("Pants")) then
				continue
			end
			
			Item:Destroy()
		end

		for _, Item in script.Clothing:FindFirstChild("Rin"):GetChildren() do
			Item:Clone().Parent = AttackerClone
		end

		for _, Item in VictimClone:GetChildren() do
			if not (Item:IsA("Shirt") or Item:IsA("Pants")) then
				continue
			end
			
			Item:Destroy()
		end

		for _, Item in script.Clothing:FindFirstChild("Sae"):GetChildren() do
			Item:Clone().Parent = VictimClone
		end
		
		local Animation = AttackerClone.Humanoid.Animator:LoadAnimation(Animations.User)
		local VictimAnimation = VictimClone.Humanoid.Animator:LoadAnimation(Animations.Victim)
		
		if Animation.Length <= 0 then
			Load()
			repeat task.wait() until Animation.Length > 0
		end

		Animation.Priority = Enum.AnimationPriority.Action4

		if VictimAnimation.Length <= 0 then
			Load()
			repeat task.wait() until VictimAnimation.Length > 0
		end
		
		VictimAnimation.Priority = Enum.AnimationPriority.Action4
		
		Animation:Play(0)
		VictimAnimation:Play(0)
		
		local TabledFriends : {[string] : typeof(script.Rigs.Friend)} = {
			Nagi = true,
			Isagi = true,
			Barou = true,
		}
		
		task.spawn(function()
			for FriendName in TabledFriends do
				TabledFriends[FriendName] = Job:Task(script.Rigs.Friend:Clone())
				TabledFriends[FriendName].Name = `{FriendName}`
				TabledFriends[FriendName].HumanoidRootPart.CFrame = CFrame.new(0, -100, 0)
				TabledFriends[FriendName].Parent = workspace.Visuals

				local FriendId = tonumber(FriendIds[FriendName].Id) or 24941

				pcall(function()
					TabledFriends[FriendName].Name = FriendIds[FriendName].Username or `{FriendName}`

					local Humanoid = TabledFriends[FriendName]:WaitForChild("Humanoid")
					local Description = Players:GetHumanoidDescriptionFromUserId(FriendId)

					if Description then
						Humanoid:ApplyDescription(Description)
					end
				end)

				for _, Item : Shirt | Pants in TabledFriends[FriendName]:GetChildren() do
					if not (Item:IsA("Shirt") or Item:IsA("Pants")) then
						continue
					end

					Item:Destroy()
				end

				for _, Item in script.Clothing:FindFirstChild(FriendName):GetChildren() do
					Item:Clone().Parent = TabledFriends[FriendName]
				end

				local ToDelay = FriendData[FriendName].SpawnDelay - Animation.TimePosition

				if ToDelay <= 0 then
					TabledFriends[FriendName].HumanoidRootPart.CFrame = RootPart.CFrame * FriendData[FriendName].Offset
				else
					Job:Task(task.delay(ToDelay, function()
						TabledFriends[FriendName].HumanoidRootPart.CFrame = RootPart.CFrame * FriendData[FriendName].Offset
					end))
				end

				local Track = TabledFriends[FriendName].Humanoid.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Final Matchup"]:FindFirstChild(FriendName))
				Track:Play()
				Track.TimePosition = Animation.TimePosition
				Job:Task(Track.Stopped:Once(function()
					TabledFriends[FriendName]:Destroy()
				end))
			end
		end)
		
		local function AttackerExists()
			return (Attacker ~= nil and Attacker.Parent ~= nil)
		end
		
		local function VictimExists()
			return (Victim ~= nil and Victim.Parent ~= nil)
		end
		
		local Sound = script.SFX:Clone()
		Sound.Parent = workspace
		Sound:Play()

		Job:Task(Sound)
		
		local Offset = CFrame.new(-0, -2, -17, -1, 0, 0, 0, 1, 0, 0, 0, -1) 

		local Camera = script.Rigs.Camera:Clone()
		Camera:PivotTo(RootPart.CFrame * Offset)
		Camera.Parent = workspace.Visuals

		Job:Task(Animation:GetMarkerReachedSignal("CameraSpeedLines"):Connect(function(State)
			if State == "On" then
				local SpeedLines = Job:Task(script.Effects.camerafx:Clone())
				SpeedLines:AddTag(`{UUID}-CameraSpeedLines`)
				Yuki_Emit.Enable(SpeedLines, true)
				SpeedLines.camera.Part1 = Camera.camera
				SpeedLines.Parent = workspace.Visuals
			elseif State == "Off" then
				for _, Item in CollectionService:GetTagged(`{UUID}-CameraSpeedLines`) do
					Yuki_Emit.Enable(Item, false)
					task.delay(Yuki_Emit.GetMaxLifetime(Item), Item.Destroy, Item)
				end
			end
		end))

		local CameraAnimation = Camera.Humanoid.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Final Matchup"].Camera)
		CameraAnimation:Play(0)

		Job:Task(RunService.PreSimulation:Connect(function()
			CameraAnimation.TimePosition = Animation.TimePosition
		end))

		Job:Task(RunCameraRig(RootPart, Camera, Offset, {
			DontDoTransition = true,
			DontSupportCutsceneSetting = true
		}))

		Job:Task(Yuki_FOV.AnimateWithMoonFile(replicatedStorage.fovFiles["Final Matchup"]))
		Job:Task(Camera)

		local ColorCorrection = Job:Task(Instance.new("ColorCorrectionEffect"))
		ColorCorrection.Parent = game:GetService("Lighting")

		for Frame, Data in CCFrames do
			Job:Task(task.delay(Frame/60, function()
				local NextFrame = GetNextFrame(Frame, CCFrames)
				local TweenDuration = if NextFrame then (NextFrame - Frame)/60 else 0.05

				TweenService:Create(
					ColorCorrection,
					TweenInfo.new(TweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					Data
				):Play()
			end))
		end

		local Vignette : typeof(script.Guis.Vignette) = Job:Task(script.Guis.Vignette:Clone())
		local DepthOfField : typeof(Instance.new("DepthOfFieldEffect")) = Job:Task(Instance.new("DepthOfFieldEffect"))

		Job:Task(Animation:GetMarkerReachedSignal("SaeAura"):Connect(function(State)
			if State == "On" then
				Vignette.Image.Size = UDim2.fromScale(1.25, 1.25)
				Vignette.Image.ImageColor3 = Color3.fromRGB(255, 104, 182)
				Vignette.Image.ImageTransparency = 0.5
				Vignette.Parent = LocalPlayer.PlayerGui
				DepthOfField.FarIntensity = 0.75
				DepthOfField.FocusDistance = 0.05
				DepthOfField.InFocusRadius = 5
				DepthOfField.NearIntensity = 0
				DepthOfField.Parent = game:GetService("Lighting")
			elseif State == "Off" then
				TweenService:Create(Vignette.Image, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
					Size = UDim2.fromScale(1.75, 1.75),
					ImageTransparency = 1,
				}):Play()

				task.delay(0.25, Vignette.Destroy, Vignette)

				TweenService:Create(DepthOfField, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
					FarIntensity = 0,
					FocusDistance = 0,
					InFocusRadius = 0,
					NearIntensity = 0,
				}):Play()

				task.delay(0.25, DepthOfField.Destroy, DepthOfField)
			end
		end))

		local LabelGui : typeof(script.Guis.FinalMatchup) = Job:Task(script.Guis.FinalMatchup:Clone())

		Job:Task(task.delay(2345/60, function()
			LabelGui.Parent = LocalPlayer.PlayerGui

			TweenService:Create(LabelGui.Image, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 3.5), {
				ImageTransparency = 1
			}):Play()
		end))

		local DialogueFrames = {
			[0] = function()
				Job:Task(Dialogue.Speak(script.Speakers.Commentator, {
					Text = "Will this be the last play?",
					TextStrokeColor = Color3.fromRGB(0, 0, 0),
					Color = ColorSequence.new(Color3.new(1, 1, 1)),
					Shake = {
						Lifetime = 0.5,
						Enabled = true,
						Intensity = 1,
					},
					TypeSpeed = 0.02,
					Image = IconImages.Commentator,
					ExtraImageSize = ExtraImageSize,
				}, {
					Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
				}, 1))
			end,

			[110] = function()
				Job:Task(Dialogue.Speak(TabledFriends.Isagi, {
					Text = "If I can steal the ball...",
					TextStrokeColor = Color3.fromRGB(0, 0, 0),
					Color = ColorSequence.new(Color3.new(1, 1, 1)),
					Shake = {
						Lifetime = 0.5,
						Enabled = true,
						Intensity = 1,
					},
					TypeSpeed = 0.02,
					Image = IconImages.Isagi,
					ExtraImageSize = ExtraImageSize,
				}, {
					Color = ColorSequence.new(Color3.fromRGB(0, 85, 255))
				}, 1.25))
			end,

			[230] = function()
				Job:Task(Dialogue.Speak(TabledFriends.Isagi, {
					Text = "It's gonna be a big chance!",
					TextStrokeColor = Color3.fromRGB(0, 0, 0),
					Color = ColorSequence.new(Color3.new(1, 1, 1)),
					Shake = {
						Lifetime = 0.5,
						Enabled = true,
						Intensity = 1,
					},
					TypeSpeed = 0.02,
					Image = IconImages.Isagi,
					ExtraImageSize = ExtraImageSize,
				}, {
					Color = ColorSequence.new(Color3.fromRGB(0, 85, 255))
				}, 1.25))
			end,

			[300] = function()
				Job:Task(Dialogue.Speak(TabledFriends.Isagi, {
					Text = "*tch*",
					Italic = true,
					TextStrokeColor = Color3.fromRGB(0, 0, 0),
					Color = ColorSequence.new(Color3.new(1, 1, 1)),
					Shake = {
						Lifetime = 0.5,
						Enabled = true,
						Intensity = 1,
					},
					TypeSpeed = 0.02,
					Image = IconImages.Isagi,
					ExtraImageSize = ExtraImageSize,
				}, {
					Color = ColorSequence.new(Color3.fromRGB(0, 85, 255))
				}, 0.5))
			end,

			[387] = function()
				Job:Task(Dialogue.Speak(TabledFriends.Barou, {
					Text = "I'm not done yet!",
					TextStrokeColor = Color3.fromRGB(0, 0, 0),
					Color = ColorSequence.new(Color3.new(1, 1, 1)),
					Shake = {
						Lifetime = 0.5,
						Enabled = true,
						Intensity = 1,
					},
					TypeSpeed = 0.02,
					Image = IconImages.Barou,
					ExtraImageSize = ExtraImageSize,
				}, {
					Color = ColorSequence.new(Color3.fromRGB(170, 0, 0))
				}, 1.35))
			end,

			[720] = function()
				Job:Task(Dialogue.Speak(TabledFriends.Barou, {
					Text = "*grunt*",
					Italic = true,
					TextStrokeColor = Color3.fromRGB(0, 0, 0),
					Color = ColorSequence.new(Color3.new(1, 1, 1)),
					Shake = {
						Lifetime = 0.5,
						Enabled = true,
						Intensity = 1,
					},
					TypeSpeed = 0.02,
					Image = IconImages.Barou,
					ExtraImageSize = ExtraImageSize,
				}, {
					Color = ColorSequence.new(Color3.fromRGB(170, 0, 0))
				}, 0.75))
			end,

			[770] = function()
				Job:Task(Dialogue.Speak(TabledFriends.Nagi, {
					Text = "No... Im here!",
					TextStrokeColor = Color3.fromRGB(0, 0, 0),
					Color = ColorSequence.new(Color3.new(1, 1, 1)),
					Shake = {
						Lifetime = 0.5,
						Enabled = true,
						Intensity = 1,
					},
					TypeSpeed = 0.02,
					Image = IconImages.Nagi,
					ExtraImageSize = ExtraImageSize,
				}, {
					Color = ColorSequence.new(Color3.fromRGB(193, 185, 255))
				}, 2))
			end,

			[1090] = function()
				Job:Task(Dialogue.Speak(TabledFriends.Nagi, {
					Text = "Darn it!",
					TextStrokeColor = Color3.fromRGB(0, 0, 0),
					Color = ColorSequence.new(Color3.new(1, 1, 1)),
					Shake = {
						Lifetime = 0.5,
						Enabled = true,
						Intensity = 1,
					},
					TypeSpeed = 0.02,
					Image = IconImages.Nagi,
					ExtraImageSize = ExtraImageSize,
				}, {
					Color = ColorSequence.new(Color3.fromRGB(193, 185, 255))
				}, 1))
			end,

			[1320] = function()
				Job:Task(Dialogue.Speak(AttackerClone, {
					Text = "I'll kill you... I'll crush you... I'LL DESTROY YOU.",
					TextStrokeColor = Color3.fromRGB(0, 0, 0),
					Color = ColorSequence.new(Color3.new(1, 1, 1)),
					Shake = {
						Lifetime = 0.5,
						Enabled = true,
						Intensity = 1,
					},
					TypeSpeed = 0.02,
					Image = IconImages.Rin,
					ExtraImageSize = ExtraImageSize,
				}, {
					Color = ColorSequence.new(Color3.fromRGB(41, 80, 255))
				}, 4))
			end,

			[1550] = function()
				Job:Task(Dialogue.Speak(VictimClone, {
					Text = "Look at you.",
					TextStrokeColor = Color3.fromRGB(0, 0, 0),
					Color = ColorSequence.new(Color3.new(1, 1, 1)),
					Shake = {
						Lifetime = 0.5,
						Enabled = true,
						Intensity = 1,
					},
					TypeSpeed = 0.02,
					Image = IconImages.Sae,
					ExtraImageSize = ExtraImageSize,
				}, {
					Color = ColorSequence.new(Color3.fromRGB(244, 160, 255))
				}, 1.5))
			end,

			[1710] = function()
				Job:Task(Dialogue.Speak(VictimClone, {
					Text = " I guess you can still make that face.",
					TextStrokeColor = Color3.fromRGB(0, 0, 0),
					Color = ColorSequence.new(Color3.new(1, 1, 1)),
					Shake = {
						Lifetime = 0.5,
						Enabled = true,
						Intensity = 1,
					},
					TypeSpeed = 0.02,
					Image = IconImages.Sae,
					ExtraImageSize = ExtraImageSize,
				}, {
					Color = ColorSequence.new(Color3.fromRGB(244, 160, 255))
				}, 2))
			end,

			[1850] = function()
				Job:Task(Dialogue.Speak(AttackerClone, {
					Text = "*freakazoid tweaking out*",
					TextStrokeColor = Color3.fromRGB(0, 0, 0),
					Color = ColorSequence.new(Color3.new(1, 1, 1)),
					Italic = true,
					Shake = {
						Lifetime = 0.5,
						Enabled = true,
						Intensity = 1,
					},
					TypeSpeed = 0.02,
					Image = IconImages.Rin,
					ExtraImageSize = ExtraImageSize,
				}, {
					Color = ColorSequence.new(Color3.fromRGB(41, 80, 255))
				}, 7))
			end,

			[2280] = function()
				Job:Task(Dialogue.Speak(script.Speakers.Fan, {
					Text = "GOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",
					TextStrokeColor = Color3.fromRGB(0, 0, 0),
					Color = ColorSequence.new(Color3.new(1, 1, 1)),
					Bold = true,
					Shake = {
						Lifetime = 0.5,
						Enabled = true,
						Intensity = 1,
					},
					TypeSpeed = 0.03,
					Image = IconImages.Fan,
					ExtraImageSize = ExtraImageSize,
				}, {
					Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
				}, 3.5))
			end,

			[2400] = function()
				Job:Task(Dialogue.Speak(script.Speakers.Stadium, {
					Text = "*cheering*",
					TextStrokeColor = Color3.fromRGB(0, 0, 0),
					Color = ColorSequence.new(Color3.new(1, 1, 1)),
					Italic = true,
					Shake = {
						Lifetime = 0.5,
						Enabled = true,
						Intensity = 1,
					},
					TypeSpeed = 0.03,
					Image = IconImages.Staidum,
					ExtraImageSize = ExtraImageSize,
				}, {
					Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
				}, 40))
			end,
		}

		for Frame, Callback in DialogueFrames do
			Job:Task(task.delay(Frame/60, Callback))
		end

		-----------------------------------------------------------------------------------------------
		-- ATTACKER
		
		Job:Task(Animation:GetMarkerReachedSignal("AttackerEmit"):Connect(function(Data : string)
			local PartName, AttachmentName = unpack(Data:split("-"))
			
			local Part = AttackerClone:FindFirstChild(PartName)
			local Particle = AttackerVFX:FindFirstChild(AttachmentName)
			
			if not (Part and Particle) then
				return
			end
			
			cutesey_arc_vfx_emitter(Particle, Part)
		end))
		
		local IsTransparent = true
		
		CharacterTransparency(AttackerClone, 1)
		
		Job:Task(task.delay(1170/60, function()
			if not IsTransparent then
				return 
			end
			IsTransparent = false
			CharacterTransparency(AttackerClone, 0)
		end))
		
		Job:Task(function()
			if not IsTransparent then
				return 
			end
			IsTransparent = false
			CharacterTransparency(AttackerClone, 0)
		end)
		
		-----------------------------------------------------------------------------------------------
		-- ENEMY
		
		local Ball : typeof(script.Ball) = Job:Task(script.Ball:Clone())
		Ball.Motor.Part0 = VictimClone.HumanoidRootPart
		Ball.Parent = VictimClone
		
		Job:Task(Animation:GetMarkerReachedSignal("VictimEmit"):Connect(function(Data : string)
			local PartName, AttachmentName = unpack(Data:split("-"))

			local Part = VictimClone:FindFirstChild(PartName)
			local Particle = VictimVFX:FindFirstChild(AttachmentName)

			if not (Part and Particle) then
				return
			end
			
			local Effect
			
			local SlowDownData = DoesSlowDown[AttachmentName]
			
			if not SlowDownData then
				cutesey_arc_vfx_emitter(Particle, Part)
				return
			else
				Effect = Job:Task(MxitzEmit(Particle, Part))
			end
			
			Job:Task(task.delay(SlowDownData.Delay, function()
				for _, Child in Effect:GetDescendants() do
					if not Child:IsA("ParticleEmitter") then
						continue
					end
					
					TweenService:Create(Child, SlowDownData.DelayInfo, {TimeScale = 0.09}):Play()
				end
			end))
			
			Job:Task(task.delay(SlowDownData.Resume, function()
				for _, Child in Effect:GetDescendants() do
					if not Child:IsA("ParticleEmitter") then
						continue
					end
					
					TweenService:Create(Child, SlowDownData.ResumeInfo, {TimeScale = 1}):Play()
				end
			end))
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("SaeAura"):Connect(function(State)
			if State == "On" then
				local SaiAura = Job:Task(VictimVFX.SaeAura:Clone())
				SaiAura:AddTag(`{UUID}-Aura`)
				Yuki_Emit.Enable(SaiAura, true)
				SaiAura.Parent = VictimClone.HumanoidRootPart
			elseif State == "Off" then
				for _, Item in CollectionService:GetTagged(`{UUID}-Aura`) do
					Yuki_Emit.Enable(Item, false)
					task.delay(Yuki_Emit.GetMaxLifetime(Item), Item.Destroy, Item)
				end
			end
		end))
		
		-----------------------------------------------------------------------------------------------
		-- MISC
		
		Job:Task(task.spawn(function()
			local Barou : typeof(script.Rigs.Friend) = TabledFriends.Barou
			
			while typeof(Barou) == "boolean" do
				Barou = TabledFriends.Barou
				task.wait()
			end

			for _, PartName in {"Left Arm", "Right Arm", "Torso", "Left Leg", "Right Leg"} do
				local Part = Barou:FindFirstChild(PartName)

				if not Part then
					continue
				end

				for _, Emiiter in script.Effects.BarouAura:GetChildren() do
					Emiiter:Clone().Parent = Part
				end
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("SpeedLines"):Connect(function(State)
			if State == "On" then
				local SpeedLines = Job:Task(script.Effects.Speedline:Clone())
				SpeedLines:AddTag(`{UUID}-SpeedLines`)
				Yuki_Emit.Enable(SpeedLines, true)
				SpeedLines.CFrame = RootPart.CFrame * CFrame.new(-21.1660004, -1.03199995, 70.6169968, -1, 0, 0, 0, 1, 0, 0, 0, -1)
				SpeedLines.Parent = workspace.Visuals
			elseif State == "Off" then
				for _, Item in CollectionService:GetTagged(`{UUID}-SpeedLines`) do
					Yuki_Emit.Enable(Item, false)
					task.delay(Yuki_Emit.GetMaxLifetime(Item), Item.Destroy, Item)
				end
			end
		end))
	end
}
