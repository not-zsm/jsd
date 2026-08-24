local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local GamepadService = game:GetService("GamepadService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

----------------------------------------------------------------------------------

local Job = require( replicatedStorage.modules.shared.Utilities.Job )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local NumberStack = require( replicatedStorage.modules.shared.Utilities.NumberStack )
local EventService = require( replicatedStorage.modules.shared.Utilities.EventService )

local Colors = require( script.Colors )
local createBGBlur = require( script.Parent.helpers.blur )

----------------------------------------------------------------------------------

local OPEN = TweenInfo.new(0.7, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)

local Emotes = {}
Emotes.__index = Emotes

function Emotes:Init()
	network.emotesUpdated.listen(function(data)
		local Emotes, Slots = data.emotes, data.slots
		for Name in Emotes do
			self:Create(Name)
		end

		self.Slots = Slots

		for Slot, Name in self.Slots do
			if (typeof(Slot) == "number") then
				Slot = tostring(Slot)
			end

			self:CreateOnSlot(Slot, (Name == "" and "None" or Name))
		end

		self:SortAll()
	end)

	network.emoteGranted.listen(function(data)
		local Name, ClaimType = data.emote, data.claimType
		if ClaimType == "Claim" then
			SoundService.GUI.ClaimEmote.PlaybackSpeed = Random.new():NextNumber(0.8, 1.2)
			SoundService.GUI.ClaimEmote:Play()

			TweenService:Create(self.TitleHolder.KillsUntilEmote, TweenInfo.new(0.05, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, 0, true),
				{Position = UDim2.fromScale(0.5, 0.6 - 0.05)}
			):Play()

		elseif ClaimType == "Purchase" or ClaimType == "Give" then
			SoundService.GUI.BuyEmote.PlaybackSpeed = Random.new():NextNumber(0.8, 1.2)
			SoundService.GUI.BuyEmote:Play()

			TweenService:Create(self.TitleHolder.BuyRandomEmote, TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, 0, true),
				{Position = UDim2.fromScale(0.5, 0.925 - 0.1)}
			):Play()
		end

		self:Create(Name, ClaimType)
	end)

	network.emoteSlotSet.listen(function(data)
		self:ApplySlot(data.slot, data.emote)
	end)

	network.emoteRemoved.listen(function(Name : string)
		if self.EmoteData[Name] then
			self.EmoteData[Name].Job:Destroy()
			self.EmoteData[Name].Frame:Destroy()
			self.EmoteData[Name] = nil
		end
	end)

	network.emotesClaimedAll.listen(function()
		self:HideClaimUI()
	end)

	network.emoteKillClaim.listen(function(data)
		local KillsCanClaim, KillsUntilEmote, HasAll = data.canClaim, data.untilNext, data.hasAll
		if HasAll then
			return self:HideClaimUI()
		end

		if KillsCanClaim > 0 then
			self.TitleHolder.KillsUntilEmote.Text = "Claim Random Emote"
			self.TitleHolder.AmountOfClaims.Text = `{KillsCanClaim}x`
		else
			self.TitleHolder.KillsUntilEmote.Text = `{KillsUntilEmote} Kills Until Random Emote`
			self.TitleHolder.AmountOfClaims.Text = ""
		end

		self.TitleHolder.KillsUntilEmote.Visible = true
		self.TitleHolder.BuyRandomEmote.Visible = true
		self.TitleHolder.AmountOfClaims.Visible = true
	end)

	self.TitleHolder.KillsUntilEmote.MouseButton1Click:Connect(function()
		network.claimEmote.send()
	end)

	self.TitleHolder.BuyRandomEmote.MouseButton1Click:Connect(function()
		network.buyRandomEmote.send()
	end)

	self.ListHolder.SearchBar.Prompt:GetPropertyChangedSignal("Text"):Connect(function()
		local Text = self.ListHolder.SearchBar.Prompt.Text

		if Text == "" then
			for Name : string, Data in self.EmoteData do
				Data.Frame.Visible = true
			end
		else

			local Matches = {}

			for Name : string, Data in self.EmoteData do
				if string.match(string.lower(Name), string.lower(Text)) then
					Matches[Name] = true
					Data.Frame.Visible = true
				end

				if not Matches[Name] then
					Data.Frame.Visible = false
				end
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(Input, Typing)
		if Typing then return end

		if Input.KeyCode == Enum.KeyCode.B then
			self:Toggle()

		elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
			self.FocusingOnSlot = nil
			self:ResetCircle()
		end
	end)
end

function Emotes:HideClaimUI()
	self.TitleHolder.KillsUntilEmote.Text = "You Have All Emotes"
	self.TitleHolder.KillsUntilEmote.Visible = true
	self.TitleHolder.BuyRandomEmote.Visible = false
	self.TitleHolder.AmountOfClaims.Visible = false
end

function Emotes:PressedSlotWithEmote(Slot : string)
	local Emote : string = self.Slots[Slot] 
	if (Emote == nil) then return end

	network.useEmote.send(Emote)
	self:Toggle()
end

function Emotes:Toggle()
	if not self.CanOpenEmotes then return end

	self:ResetCircle()
	SoundService.GUI.EmotesOpen:Play()

	if self.UI.Icons then
		self.UI.Icons:CloseAllExcept(self.GUI)
	end

	-- tracked rather than read off Enabled: the close fade leaves Enabled true
	-- for its whole run, so a quick re-press would read as a second close
	self.WheelOpen = not self.WheelOpen

	if self.WheelFade then
		self.WheelFade:Cancel()
		self.WheelFade = nil
	end

	if self.WheelOpen then
		self.GUI.Enabled = true

		--[[
			What jjk opened the wheel behind: a blurred background with the
			hotbar out of the way. The job owns both, so closing drops the blur
			and puts the hotbar back however the close happened.
		--]]
		self.WheelJob = Job.new()

		createBGBlur(self.WheelJob, 0.7, 24)

		if self.UI.Hotbar then
			self.UI.Hotbar:SetHidden(true)

			self.WheelJob:Task(function()
				self.UI.Hotbar:SetHidden(false)
			end)
		end

		self.WheelFade = TweenService:Create(self.container, OPEN, { GroupTransparency = 0 })
		self.WheelFade:Play()
	else
		if self.WheelJob then
			self.WheelJob:Destroy()
			self.WheelJob = nil
		end

		self.WheelFade = TweenService:Create(self.container, OPEN, { GroupTransparency = 1 })

		self.WheelFade.Completed:Once(function(State)
			if State == Enum.PlaybackState.Completed and not self.WheelOpen then
				self.GUI.Enabled = false
			end
		end)

		self.WheelFade:Play()
	end

	self.OnToggled:Fire()
end

--- Drops everything opening the wheel put up, without animating it away.
function Emotes:CloseWheel()
	self.WheelOpen = false

	if self.WheelFade then
		self.WheelFade:Cancel()
		self.WheelFade = nil
	end

	if self.WheelJob then
		self.WheelJob:Destroy()
		self.WheelJob = nil
	end

	self.container.GroupTransparency = 1
end

function Emotes:ResetCircle()
	self.FocusingOnSlot = nil
	self.ListHolder.Visible = false

	for _, Emote in ipairs(self.Circle:GetChildren()) do
		if Emote:IsA("ViewportFrame") then
			Emote.Visible = true
		end
	end
end

function Emotes:SortAll()
	local ToSort = {}

	for _, Emote in self.EmoteData do
		if Emote.BubbleToTop then
			continue
		end

		table.insert(ToSort, Emote)
	end

	table.sort(ToSort, function(EmoteA, EmoteB)
		return EmoteA.Frame.Name < EmoteB.Frame.Name
	end)

	for Index, Emote in ToSort do
		Emote.Frame.LayoutOrder = Index
	end
end

local function SetColor(Title : TextLabel, Color : ColorSequence | Color3)
	if typeof(Color) == "ColorSequence" then
		Title.Gradient.Color = Color
		Title.Gradient.Enabled = true
	else
		Title.TextColor3 = Color
	end
end

function Emotes:Create(Name : string, Type : string)
	if (self.EmoteData[Name] ~= nil) then return end

	self.EmoteData[Name] = {}
	self.EmoteData[Name].Job = Job.new()
	self.EmoteData[Name].BubbleToTop = (Type ~= nil)

	self.EmoteData[Name].Frame = self.EmoteData[Name].Job:Task(self.ListHolder.Template:Clone())
	self.EmoteData[Name].Frame.Title.Text = Name
	self.EmoteData[Name].Frame.Name = Name
	self.EmoteData[Name].Frame.Visible = true
	self.EmoteData[Name].Frame.Claimed.Visible = (Type ~= nil)

	if self.EmoteData[Name].BubbleToTop then
		self.EmoteData[Name].Frame.LayoutOrder = -Utility.TableCount(self.EmoteData)
	end

	if Colors[Name] then
		SetColor(self.EmoteData[Name].Frame.Title, Colors[Name])
	end

	self.EmoteData[Name].Frame.Parent = self.EmoteList

	self.EmoteData[Name].Job:Task(self.EmoteData[Name].Frame.Click.MouseButton1Click:Connect(function()
		self.EmoteData[Name].Frame.Claimed.Visible = false
		self:ChangeFocusedEmoteSlot(Name)
	end))
end

function Emotes:CreateOnSlot(Slot : string, Name : string)
	local Emote : ViewportFrame = self.Circle:FindFirstChild(Slot)
	if (Emote == nil) then return end

	Emote.emoteName.Text = Name

	if Colors[Name] then
		SetColor(Emote.emoteName, Colors[Name])
	end

	if Name ~= "None" then
		task.spawn(self.MakeViewportOnSlot, self, Emote, Name)
	end
end

--[[
	Dresses the rig a slot was authored with and plays the emote on it.

	Each viewport carries its own rotation and its own camera, so the rig that
	came with it is the one that sits where that camera is looking. Nothing here
	moves or replaces it -- a dummy is only cloned in if a viewport was left
	empty, and it will not be standing in the right place.
--]]
function Emotes:MakeViewportOnSlot(Emote : ViewportFrame, Name : string)
	local World = Emote:WaitForChild("WorldModel")
	local Dummy = World:FindFirstChildWhichIsA("Model")

	if Dummy == nil then
		warn(`emote slot {Emote.Name} was authored with no rig in its WorldModel`)

		Dummy = script.Dummy:Clone()
		Dummy.Parent = World
	end

	local Humanoid : Humanoid? = Dummy:FindFirstChildOfClass("Humanoid")
	if Humanoid == nil then return end

	--[[
		Once per viewport, not once per emote: re-rolling on every slot change
		would swap who the preview is every time the emote on it did.
	--]]
	if not Emote:GetAttribute("Dressed") then
		Emote:SetAttribute("Dressed", true)

		task.spawn(function()
			local Appearances = require( replicatedStorage.modules.shared.Game.Appearances )
			local Developer = Appearances.GetRandomDeveloper()

			if Developer and Humanoid.Parent then
				Humanoid:ApplyDescription(Developer)
			end
		end)
	end

	-- the rig is reused, so whatever it was playing has to come off it first
	local Playing : AnimationTrack? = self.SlotTracks[Emote]

	if Playing then
		Playing:Stop(0)
		Playing:Destroy()

		self.SlotTracks[Emote] = nil
	end

	local AnimationObject = replicatedStorage.Animations.Emotes:FindFirstChild(Name)
	if (AnimationObject == nil) then return end

	AnimationObject =
		AnimationObject:IsA("Folder") and
		AnimationObject:FindFirstChild("Start") or
		AnimationObject

	if (AnimationObject == nil) then return end

	local Animator : Animator? = Humanoid:FindFirstChildOfClass("Animator")
	if Animator == nil then return end

	local Animation = Animator:LoadAnimation(AnimationObject)
	Animation.Looped = true
	Animation:Play()

	self.SlotTracks[Emote] = Animation
end

--[[
	Asks the server to put an emote in the focused slot.

	This was a RemoteFunction the client waited on before repainting. byteNet
	does not do round trips, so the ask and the answer are two packets and the
	repaint happens in ApplySlot when the server confirms.
--]]
function Emotes:ChangeFocusedEmoteSlot(Name : string)
	if not self.FocusingOnSlot then return end

	network.setEmoteSlot.send({ slot = self.FocusingOnSlot, emote = Name })
end

--- The server confirmed a slot write. Same repaint the invoke used to gate.
function Emotes:ApplySlot(Slot : string, Name : string)
	self.Slots[Slot] = Name

	local Emote : ViewportFrame = self.Circle:FindFirstChild(Slot)
	if not Emote then return end

	self:MakeViewportOnSlot(Emote, Name)

	Emote.emoteName.Text = Name

	if Colors[Name] then
		SetColor(Emote.emoteName, Colors[Name])
	else
		Emote.emoteName.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	if self.FocusingOnSlot == Slot then
		self:ResetCircle()
	end
end

--[[
	Binds the viewports the wheel was authored with.

	They are found by name rather than cloned and placed, because each one is
	rotated to its own spot on the dial -- nothing here writes Position,
	Rotation, AnchorPoint or Parent.
--]]
function Emotes:BindSlots()
	for _, Slot in self.Circle:GetChildren() do
		if not Slot:IsA("ViewportFrame") then continue end

		local SlotId = Slot.Name

		if tonumber(SlotId) == nil then
			warn(`emote wheel has a viewport named {SlotId}, which is not a slot number`)
			continue
		end

		local Button : TextButton? = Slot:FindFirstChild("pick")

		if Button == nil then
			warn(`emote slot {SlotId} has no pick button`)
			continue
		end

		local Job = Job.new()

		local function Connect(NewDevice : string)
			Job:Clean()

			local TimedClick : boolean = (
				(NewDevice == "Touch" or NewDevice == "Controller")
			)

			if TimedClick then
				Job:Task(Button.MouseButton1Down:Connect(function()
					self.SelectSlotThread = task.delay(0.3, function()
						self.SelectSlotThread = nil
						self:SelectSlot(SlotId)
					end)
				end))

				Job:Task(Button.MouseButton1Click:Connect(function()
					if not self.FocusingOnSlot then
						self:PressedSlotWithEmote(SlotId)
					end
				end))

				Job:Task(Button.MouseButton1Up:Connect(function()
					if self.SelectSlotThread then
						task.cancel(self.SelectSlotThread)
						self.SelectSlotThread = nil
					end
				end))
			else
				Job:Task(Button.MouseButton1Down:Connect(function()
					self:PressedSlotWithEmote(SlotId)
				end))

				Job:Task(Button.MouseButton2Down:Connect(function()
					self:SelectSlot(SlotId)
				end))
			end
		end

		self.Combat.OnDeviceChanged:Connect(Connect)
		Connect(self.Combat.CurrentDevice)
	end
end

function Emotes:SelectSlot(Slot : string)
	self.FocusingOnSlot = Slot

	for _, Emote in ipairs(self.Circle:GetChildren()) do
		if Emote:IsA("ViewportFrame") and Emote.Name ~= Slot then
			Emote.Visible = false
		end
	end

	self.ListHolder.Visible = true
end

function Emotes.new(UI)
	local self = setmetatable({}, Emotes)

	self.UI = UI
	self.Combat = UI.Combat
	self.LuaPlayer = UI.LuaPlayer

	self.EmoteData = {}
	self.SlotTracks = {}

	self.GUI = self.LuaPlayer.PlayerGui:WaitForChild("Emotes")

	self.container = self.GUI:WaitForChild("container")
	self.Holder = self.container:WaitForChild("otherOne")

	self.Wheel = self.Holder:WaitForChild("wheel")
	self.Circle = self.Holder:WaitForChild("display")

	self.ListHolder = self.Holder:WaitForChild("listHolder")
	self.TitleHolder = self.Holder:WaitForChild("titleHolder")

	self.EmoteList = self.ListHolder:WaitForChild("EmoteList")

	self.container.GroupTransparency = 1

	self.WheelOpen = false
	self.CanOpenEmotes = true

	self.OnToggled = EventService.new()

	self.GUI:GetPropertyChangedSignal("Enabled"):Connect(function()
		if self.Combat.UsingController then
			if self.GUI.Enabled then
				GamepadService:EnableGamepadCursor(self.Holder)
			else
				GamepadService:DisableGamepadCursor()
			end
		end

		--[[
			Icons:CloseAllExcept disables the screen behind Toggle's back, so
			the wheel has to notice: otherwise the blur stays up, the hotbar
			stays hidden, and the next press reads as a close.
		--]]
		if not self.GUI.Enabled and self.WheelOpen then
			self:CloseWheel()
		end
	end)

	self.Slots = {}

	self:BindSlots()

	self:Init()

	return self
end

table.freeze(Emotes)

return Emotes
