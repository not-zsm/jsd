local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Configuration = require( script.Configuration )

local Player = Players.LocalPlayer

local DialogueSystem = {}
DialogueSystem.__index = DialogueSystem

-- Constructor
function DialogueSystem.new(UI)
	local self = setmetatable({}, DialogueSystem)
	
	self.UI = UI
	self.DialogueGui = UI.PlayerGui:WaitForChild("Dialogue")
	self.Holder = self.DialogueGui.Holder
	self.ChoicesScrollingFrame = self.Holder.Choices.ScrollingFrame
	self.DisplayFrame = self.Holder.Display
	self.MessageFrame = self.DisplayFrame.Message
	
	self.Typing = false
	self.Talking = false
	self.TalkingSound = SoundService.NPC.Talk
	
	self.Player = Player

	return self
end

------------------------------------------------- [ MAIN ] --------------------------------------------------
-- Speak To NPC (Begin Dialogue)
function DialogueSystem:StartConversation(NPC, CustomDialogueStart)
	local NPCId = NPC.Name
	
	if not Configuration.Dialogues[NPCId] then
		return print("invalid NPC")
		
	elseif (self.Typing == true) or (self.Talking == true) then
		return print("cannot talk at the same time")
	end

	-- Show Holder Frame
	self.UI:Toggle(false, 0)
	self.Holder.Visible = true
	
	-- Set Configs
	self.Talking = true
	self.CurrentNPC = Configuration.Dialogues[NPCId]
	
	if not self.CurrentNPC.Configuration then
		self.CurrentNPC.Configuration = {}
	end
	
	local NPCConfiguration = self.CurrentNPC.Configuration
	self.TalkingSound.SoundId = NPCConfiguration.SpeakSFX or Configuration.DefaultConfiguration.SpeakSFX 
	
	-- Set Colors
	if NPCConfiguration.ColorGradients then
		self.DisplayFrame.UIGradient.Color = NPCConfiguration.ColorGradients.Background or self.DefaultConfiguration.ColorGradients.Background
		self.MessageFrame.Author.UIGradient.Color = NPCConfiguration.ColorGradients.Title or self.DefaultConfiguration.ColorGradients.Title
	end
	
	
	require( script.ViewportCharacter ).CopyCharacterAppearence(NPC, self.DisplayFrame.Icon.ViewportFrame)

	self:DisplayDialogue(NPCId, CustomDialogueStart or 1)
end

-- Close dialogue window
function DialogueSystem:EndConversation()
	self.Holder.Visible = false
	self.UI:Toggle(true, 0)
	
	self:StopTypewriter()
	self.Talking = false
	
	-- Stop Previous Sound
	self:StopLastTalkSound()
end

-- Handle dialogue choices
function DialogueSystem:HandleChoice(NPCId, NodeId, Choice)
	if Choice.Function then
		task.spawn(Choice.Function, self)
	end
	
	if not NPCId or Choice.EndConversation then
		self:EndConversation()
	end

	if Choice.Next then
		self:DisplayDialogue(NPCId, Choice.Next)
	end
end

------------------------------------------------- [ PROCESSES ] --------------------------------------------------
-- Icon shaking animation
function DialogueSystem:TweenIcon(Intensity : Number)
	local RandomDir = math.random(-Intensity, Intensity)
	local Tween = TweenService:Create(self.DisplayFrame.Icon, TweenInfo.new(Configuration.GlobalConfiguration.ShakeDuration, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Rotation = RandomDir})
	Tween:Play()
	Tween.Completed:Wait()
	self.DisplayFrame.Icon.Rotation = 0
end

function GraphemeLength(Text : string)
	local Length = 0

	for _ in utf8.graphemes(Text) do
		Length += 1
	end

	return Length
end

function DialogueSystem:GraphemeTypewriter(Text : string, PlayTypingSFX : bolean)
	self.MessageFrame.Dialogue.Text = Text
	
	self.TalkingSound.PitchEffect.Enabled = self.CurrentNPC.Configuration.RandomPitch or false
	self.TypeTask = task.spawn(function()
		for Index = 1, GraphemeLength(self.MessageFrame.Dialogue.ContentText) do
			if not self.Typing then return end
			
			self.MessageFrame.Dialogue.MaxVisibleGraphemes = Index
			
			if PlayTypingSFX == true then
				if self.CurrentNPC.Configuration.RandomPitch then
					self.TalkingSound.PitchEffect.Octave = (math.random(100, 115) / 100)
				end
				
				local CloneSound = self.TalkingSound:Clone()
				CloneSound.Parent = SoundService.NPC
				
				CloneSound.Volume = CloneSound.Volume * if self.CurrentNPC.Configuration.TypingSFXVolume then self.CurrentNPC.Configuration.TypingSFXVolume else 1
				
				CloneSound:Play()
				task.delay(1, CloneSound.Destroy, CloneSound)
			end
			
			self:TweenIcon(self.CurrentNPC.Configuration.IconIntensity or Configuration.DefaultConfiguration.IconIntensity)
			if table.find(Configuration.GlobalConfiguration.PunctuationCharacters, string.sub(Text, Index, Index)) then
				task.wait(self.CurrentNPC.Configuration.PunctuationSpeed or Configuration.DefaultConfiguration.PunctuationSpeed)
			end

			task.wait(self.CurrentNPC.Configuration.TypeSpeed or Configuration.DefaultConfiguration.TypeSpeed)
		end
		
		self.MessageFrame.Dialogue.MaxVisibleGraphemes = -1
		self.Typing = false
	end)
end

function DialogueSystem:StopLastTalkSound()
	if self.LastPlayedSound then
		self.LastPlayedSound:Stop()
	end
end

-- Show dialogue with typing effect
function DialogueSystem:DisplayDialogue(NPCId, NodeId)
	local NPCConfigData = self.CurrentNPC.Configuration or {}
	local NPCDialogueData = self.CurrentNPC.Dialogue[NodeId]

	self.Typing = true
	self.MessageFrame.Author.Text = NPCId
	self.MessageFrame.Dialogue.Text = ""
	
	-- Stop Previous Sound
	self:StopLastTalkSound()
	
	-- Play Sound
	if NPCConfigData.SoundFolder and NPCConfigData.SoundFolder[NodeId] then
		local Sound = NPCConfigData.SoundFolder[NodeId]
		Sound:Play()
		self.LastPlayedSound = Sound
	end

	for _, Button in pairs(self.ChoicesScrollingFrame:GetChildren()) do
		if Button:IsA("ImageButton") then
			Button:Destroy()
		end
	end
	
	local PlayTypingSFX = if NPCConfigData.SoundFolder and NPCConfigData.SoundFolder[NodeId] and not NPCConfigData.ForceTypingSFX then false else true
	self:GraphemeTypewriter(NPCDialogueData.Text, PlayTypingSFX)

	for _, Choice in pairs(NPCDialogueData.Choices) do
		self:CreateChoice(Choice, NPCId, NodeId)
	end
	
	-- Create Leave Choice
	-- self:CreateChoice({})
end

function DialogueSystem:StopTypewriter(NPCId, NodeId)
	if self.TypeTask and coroutine.status(self.TypeTask) == "suspended" then
		task.cancel(self.TypeTask)
	end
end

function DialogueSystem:CreateChoice(Choice, NPCId, NodeId)
	local ChoiceButton = self.Holder.Templates.ChoiceTemplate:Clone()
	ChoiceButton.Parent = self.ChoicesScrollingFrame
	ChoiceButton.Label.Text = Choice.Text or "Leave"
	ChoiceButton.Visible = true
	
	ChoiceButton.MouseButton1Click:Connect(function()
		self:StopTypewriter()
		
		self.Typing = false
		self:HandleChoice(NPCId, NodeId, Choice)
	end)
end

return DialogueSystem
