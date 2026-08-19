type DialogueInfo = {
	Speaker : string,
	Description : string,

	Options : {[number] : string},
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local Modules = ReplicatedStorage.Modules
local Remotes = ReplicatedStorage.Remotes

local UIRemotes = Remotes.Combat.UI
local DialogueRemotes = UIRemotes.Dialogue

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

----------------------------------------------------------------------------------

local Dialogue = {}
Dialogue.__index = Dialogue

function Dialogue:Init()
	DialogueRemotes.NewConveration.OnClientEvent:Connect(function(Info : DialogueInfo)
		self:NewConversation(Info)
	end)

	DialogueRemotes.EndConversation.OnClientEvent:Connect(function(SpeakerName : string)
		local Conversation = self.Conversations[SpeakerName]

		if (Conversation == nil) then
			return
		end

		Conversation:Destroy()
	end)
end

function Dialogue:NewConversation(Info : DialogueInfo)
	if (Info == nil) then
		error(`please provide a table for dialogue info`)
	end

	if typeof(Info.Speaker) ~= `string` then
		error(`hey buddy the speaker has to be a string`)
	end

	if typeof(Info.Description) ~= `string` then
		error(`erm please put a description for the converations`)
	end

	for Speaker : number, Conversation in self.Conversations do
		if Info.Speaker ~= Speaker then
			Conversation:Destroy()
		end
	end

	local NewConversation = self.Conversations[Info.Speaker]

	if (NewConversation == nil) then
		NewConversation = {}

		NewConversation.Trove = Job.new()
		NewConversation.DialogueTrove = Job.new()

		NewConversation.Destroy = function()
			self.Conversations[Info.Speaker] = nil

			self.MainFrame.Visible = false
			self.UI:Toggle(true, 0)

			NewConversation.Trove:Destroy()
			NewConversation.DialogueTrove:Destroy()
		end

		NewConversation.Options = {}

		NewConversation.ClearOptions = function()
			for _, Option in NewConversation.Options do
				if Option.Name == `Close` then continue end

				Option:Destroy()
			end
		end

		self.UI:Toggle(false, 0)

		self.MainFrame.Title.Text = `{Info.Speaker}`
		self.MainFrame.Visible = true
		
		self.Conversations[Info.Speaker] = NewConversation
	else
		NewConversation.ClearOptions()
	end
	
	if Info.Options then
		for LayoutOrder, Text in Info.Options do
			local NewOption = NewConversation.Trove:Task(self.Template:Clone())
			NewOption.Name = `{Text}`
			NewOption.LayoutOrder = LayoutOrder
			NewOption.Description.Text = `{Text}`

			local ClickedEvent = NewConversation.Trove:Task(NewOption.Interaction.MouseButton1Click:Connect(function()
				DialogueRemotes.SendChoice:FireServer(Info.Speaker, LayoutOrder, Text)
			end))

			NewConversation.Trove:Task(NewOption.Destroying:Connect(function()
				ClickedEvent:Disconnect()
			end))

			table.insert(NewConversation.Options, NewOption)

			NewOption.Visible = false
			NewOption.Parent = self.Options
		end
	end

	self.Options.Close.Visible = false
	self.Options.Close.Description.Text = Info.CustomCloseText or "GET OUT!!"
	
	NewConversation.DialogueTrove:Clean()

	local TypeWriter = NewConversation.DialogueTrove:Task(coroutine.create(function()
		for Index = 1, #Info.Description do
			local Text = string.sub(Info.Description, 1, Index)
			local Character = string.sub(Text, -1)

			self.MainFrame.Description.Text = Text
			
			local Speed = (Character == "." or Character == ",") and 0.4 or (Info.TypeWriterSpeed or 0.0475)
			
			task.wait(Speed)
		end

		for _, Option in ipairs(self.Options:GetChildren()) do
			if Option:IsA("Frame") then
				Option.Visible = true
			end
		end

		NewConversation.Trove:Task(self.Options.Close.Interaction.MouseButton1Click:Connect(function()
			DialogueRemotes.SendChoice:FireServer(Info.Speaker, -1)
			NewConversation:Destroy()
		end))
	end))

	coroutine.resume(TypeWriter)
end

function Dialogue.new(UI)
	local self = setmetatable({}, Dialogue)

	self.UI = UI
	self.Combat = UI.Combat
	self.LuaPlayer = UI.LuaPlayer

	self.PlayerGui = self.LuaPlayer.PlayerGui

	self.GUI = self.PlayerGui:WaitForChild("Dialogue")
	self.MainFrame = self.GUI:WaitForChild("Holder")
	self.Options = self.MainFrame:WaitForChild("Options")
	self.Template = self.MainFrame:WaitForChild(`Template`)

	self.Conversations = {}

	self:Init()

	return self
end

table.freeze(Dialogue)

return Dialogue