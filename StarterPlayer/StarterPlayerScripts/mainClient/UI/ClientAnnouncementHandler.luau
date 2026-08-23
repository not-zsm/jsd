local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local AnnouncementModule = {}
AnnouncementModule.__index = AnnouncementModule

function AnnouncementModule._new()
	local self = setmetatable({}, AnnouncementModule)
	local Player = Players.LocalPlayer
	local Gui = Player:WaitForChild("PlayerGui", 100):WaitForChild("Announcement", 100):WaitForChild("Holder", 100)

	self.GuiElement = Gui
	self.DisplayFrame = Gui:WaitForChild("Display")
	self.SidebarFrame = Gui:WaitForChild("Sidebar")

	self.TitleLabel = self.DisplayFrame:WaitForChild("TitleLabel")
	self.MessageLabel = self.DisplayFrame:WaitForChild("Message")

	self.TypingSpeed = 0.009

	self.EraseSpeed = 0.02
	self.IsAnimating = false

	self.TweenSettings = {
		Display = {
			Goal = {Size = UDim2.new(0.928, 0, 0.903, 0)},
			HideGoal = {Size = UDim2.new(0, 0, 0.903, 0)},
			TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		},

		Sidebar = {
			Goal = {Position = UDim2.new(0.015, 0, 0.049, 0)},
			HideGoal = {Position = UDim2.new(-0.1, 0, 0.049, 0)},
			TweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		},

		TextLabels = {
			TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		}
	}

	self.Queue = {} -- Queue for announcements
	self.IsProcessing = false

	return self
end

function GraphemeLength(Text : string)
	local Length = 0

	for _ in utf8.graphemes(Text) do
		Length += 1
	end

	return Length
end

local function TypingEffect(Object, TargetText, TypingSpeed)
	for Index = 1, GraphemeLength(TargetText) do
		Object.MaxVisibleGraphemes = Index
		task.wait(TypingSpeed)
	end

	Object.MaxVisibleGraphemes = -1
end

function AnnouncementModule:_ProcessQueue()
	if self.IsProcessing or #self.Queue == 0 then return end

	self.IsProcessing = true

	while #self.Queue > 0 do
		local Announcement = table.remove(self.Queue, 1)
		self:_ShowAnnouncement(Announcement.Message, Announcement.Title, Announcement.Type, Announcement.TypingSpeed, Announcement.EraseSpeed)
		task.wait(0.5)
	end

	self.IsProcessing = false
end

function AnnouncementModule:_ShowAnnouncement(Message, Title, Type, TypingSpeed)
	self.IsAnimating = true

	if TypingSpeed then self.TypingSpeed = TypingSpeed end
	if Title then self.TitleLabel.Text = Title end
	if Message then self.MessageLabel.Text = Message end

	self.GuiElement.Visible = true
	
	local AnnounceSound = Instance.new("Sound")
	AnnounceSound.Volume = 0.5

	if Type == "Reward" then
		AnnounceSound.SoundId = "rbxassetid://83995242757223"
	else
		AnnounceSound.SoundId = "rbxassetid://95520165876139"
	end
	
	AnnounceSound.Parent = SoundService
	
	AnnounceSound:Play()
	task.delay(AnnounceSound.TimeLength + 1, AnnounceSound.Destroy, AnnounceSound)

	local SidebarTween = TweenService:Create(self.SidebarFrame, self.TweenSettings.Sidebar.TweenInfo, self.TweenSettings.Sidebar.Goal)
	SidebarTween:Play()
	SidebarTween.Completed:Wait()

	task.spawn(function()
		TypingEffect(self.TitleLabel, Title, TypingSpeed)
	end)

	local DisplayTween = TweenService:Create(self.DisplayFrame, self.TweenSettings.Display.TweenInfo, self.TweenSettings.Display.Goal)
	DisplayTween:Play()
	DisplayTween.Completed:Wait()

	TypingEffect(self.MessageLabel, Message, self.TypingSpeed)

	task.wait((string.len(Message) / 12) + 2)

	local HideMessageTween = TweenService:Create(self.MessageLabel, self.TweenSettings.TextLabels.TweenInfo, {TextTransparency = 1})
	local HideTitleTween = TweenService:Create(self.TitleLabel, self.TweenSettings.TextLabels.TweenInfo, {TextTransparency = 1})
	HideMessageTween:Play()
	HideTitleTween:Play()

	HideMessageTween.Completed:Wait()

	local HideDisplayTween = TweenService:Create(self.DisplayFrame, self.TweenSettings.Display.TweenInfo, self.TweenSettings.Display.HideGoal)
	HideDisplayTween:Play()
	HideDisplayTween.Completed:Wait()

	local HideSidebarTween = TweenService:Create(self.SidebarFrame, self.TweenSettings.Sidebar.TweenInfo, self.TweenSettings.Sidebar.HideGoal)
	HideSidebarTween:Play()
	HideSidebarTween.Completed:Wait()

	self.TitleLabel.TextTransparency = 0
	self.TitleLabel.MaxVisibleGraphemes = 0
	self.MessageLabel.TextTransparency = 0
	self.MessageLabel.MaxVisibleGraphemes = 0

	self.GuiElement.Visible = false
	self.IsAnimating = false
end

function AnnouncementModule:Announce(Message, Title, Type, TypingSpeed, EraseSpeed)
	task.spawn(function()
		table.insert(self.Queue, {Message = Message, Title = Title, Type = Type, TypingSpeed = TypingSpeed, EraseSpeed = EraseSpeed})
		self:_ProcessQueue()
	end)
end

return AnnouncementModule._new()
