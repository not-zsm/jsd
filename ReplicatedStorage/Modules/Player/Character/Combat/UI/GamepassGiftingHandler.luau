local GamepassGiftingHandler = {}
GamepassGiftingHandler.__index = GamepassGiftingHandler

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserService = game:GetService("UserService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local LocalPlayer = Players.LocalPlayer

-- Configuration Module
local Gamepasses = require( ReplicatedStorage.Modules.Shared.Game.Gamepasses )

function GamepassGiftingHandler.new(Gui)
	local self = setmetatable({}, GamepassGiftingHandler)
	self.Gui = Gui
	self.SelectionFrame = Gui.Holder.Choices.Selection.Gameplay
	self.Template = self.SelectionFrame.Template
	self.CurrentSelection = Gui.Holder.CurrentSelection
	self.PlayersList = Gui.Holder.PlayersList
	self.SearchBar = self.PlayersList.Players.SearchBar
	self.Confirmation = self.Gui.Holder.Confirmation
	
	self.Connections = {}
	self.ConfirmationConnections = {}
	
	self.Friends = nil
	self.PageSelected = nil
	
	self.PromptListener = nil

	self:CreateGamepassButtons()
	return self
end

------------------------- [ GENERAL ] -------------------------
function GamepassGiftingHandler:Close()
	self.Friends = nil
	
	-- Delete Selection Frames
	for _, PlayerButton in pairs(self.PlayersList.Players[`ServerSelection`]:GetChildren()) do
		if PlayerButton:IsA("ImageButton") then
			PlayerButton:Destroy()
		end
	end
	
	for _, PlayerButton in pairs(self.PlayersList.Players[`GlobalSelection`]:GetChildren()) do
		if PlayerButton:IsA("ImageButton") then
			PlayerButton:Destroy()
		end
	end
end

------------------------- [ BACKGROUND ] -------------------------
function GamepassGiftingHandler:CreateGamepassButtons()
	for Name : string, Data : {} in pairs(Gamepasses) do
		local Button = self.Template:Clone()
		Button.Title.Text = Name
		Button.Description.Text = Data.Description
		Button.Cost.Text = `\u{E002}{Data.Price}`
		
		if Data.GamepassIcon then
			Button.GamepassIcon.Image = `rbxassetid://{Data.GamepassIcon}`
		end
	
		Button.LayoutOrder = Data.Order
		Button.Parent = self.SelectionFrame
		Button.Visible = true

		Button.MouseButton1Click:Connect(function()
			self:SelectGamepass(Name, Data)
		end)
	end
	
	-- Setup Selection Button Listeners
	self.CurrentSelection.PurchaseForSelf.MouseButton1Click:Connect(function()
		if self.SelectedGamepass then
			Remotes.PromptGamepassPurchase:FireServer(self.SelectedGamepass.Name)
		end
	end)

	self.CurrentSelection.GiftButton.MouseButton1Click:Connect(function()
		if self.SelectedGamepass then
			self:OpenPlayerSelection(self.SelectedGamepass.Data)
		end
	end)
end

function GamepassGiftingHandler:SelectGamepass(Name : string, Data : {})
	if Data.GamepassIcon then
		self.CurrentSelection.GamepassIcon.Image = `rbxassetid://{Data.GamepassIcon}`
	end

	self.CurrentSelection.Title.Text = Name
	self.CurrentSelection.Description.Text = Data.Description
	
	self.SelectedGamepass = {
		Name = Name,
		Data = Data
	}
end

function GamepassGiftingHandler:OpenPlayerSelection(Gamepass)
	if self.Connections then
		for _, Connection in self.Connections do
			Connection:Disconnect()
		end
		
		self.Connections = {}
	end
	
	self.PlayersList.Visible = true
	local ServerButton = self.PlayersList.SearchType.Server
	local GlobalButton = self.PlayersList.SearchType.Global

	self.Connections[ServerButton] = ServerButton.MouseButton1Click:Connect(function()
		self:PopulatePlayers("Server")
	end)

	self.Connections[GlobalButton] = GlobalButton.MouseButton1Click:Connect(function()
		self.PageSelected = "Global"
		self:PopulatePlayers("Global")
	end)
end

function GamepassGiftingHandler:PopulatePlayers(SelectionType)
	-- Edit Prompt & Listener
	if self.PromptListener then
		self.PromptListener:Disconnect()
		self.PromptListener = nil
	end
	
	if self.PromptListener then
		self.PromptListener:Disconnect()
		self.PromptListener = nil
	end
	
	self.SearchBar.Prompt.Text = ""
	
	if SelectionType == "Server" then
		local PlayersList = Players:GetPlayers()
		
		local SelectionFrame = self.PlayersList.Players[`ServerSelection`]
		SelectionFrame.Visible = true
		self.PlayersList.Players["GlobalSelection"].Visible = false
		
		for _, PlayerButton in pairs(SelectionFrame:GetChildren()) do
			if PlayerButton:IsA("ImageButton") then 
				PlayerButton:Destroy()
			end
		end
		
		self:CreatePlayerFrames(SelectionFrame, SelectionType, PlayersList)
		
		-- Connect Prompt
		self.SearchBar.Prompt:GetPropertyChangedSignal("Text"):Connect(function()
			self:FilterPlayers(SelectionFrame,"Server")
		end)
		self:FilterPlayers(SelectionFrame,"Server")
	elseif SelectionType == "Global" then
		local SelectionFrame = self.PlayersList.Players[`GlobalSelection`]
		SelectionFrame.Visible = true
		self.PlayersList.Players["ServerSelection"].Visible = false
		
		-- Connect Prompt
		self.PromptListener = self.SearchBar.Prompt:GetPropertyChangedSignal("Text"):Connect(function()
			self:FilterPlayers(SelectionFrame, "Global")
		end)
		self:FilterPlayers(SelectionFrame, "Global")
		
		if not self.Friends then
			self.Friends = self:FetchFriends(LocalPlayer.UserId)
			self:CreatePlayerFrames(SelectionFrame, SelectionType, self.Friends)
		end
	end
end

function GamepassGiftingHandler:CreatePlayerFrames(SelectionFrame, SelectionType, PlayersList)
	for _, Player in pairs(PlayersList) do
		local UserId
		local Username

		if SelectionType == "Global" then
			UserId = Player.Id
			Username = Player.Username
		else
			UserId = Player.UserId
			Username = Player.Name
		end
		
		if (Player.UserId == LocalPlayer.UserId) then
			continue
		end

		local PlayerButton = self.Gui.Holder.Templates.PlayerTemplate:Clone()
		PlayerButton.Name = Username
		PlayerButton.Username.Text = Username
		PlayerButton.DisplayName.Text = Player.DisplayName
		PlayerButton.UserIcon.Image = Players:GetUserThumbnailAsync(UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180) or nil
		PlayerButton.Parent = SelectionFrame
		PlayerButton.Visible = true

		PlayerButton.MouseButton1Click:Connect(function()
			self:ConfirmSelection(UserId, Username, Player.DisplayName, PlayerButton.UserIcon.Image)
		end)
	end
end

function GamepassGiftingHandler:FilterPlayers(SelectionFrame, SelectionType)
	local PartialString = string.lower(self.SearchBar.Prompt.Text)

	for _, PlayerButton in pairs(SelectionFrame:GetChildren()) do
		if PlayerButton:IsA("ImageButton") then
			if PlayerButton.Name == "!GlobalUser" then
				PlayerButton:Destroy()
				continue
			end
			
			local Username = string.lower(PlayerButton.Username.Text)
			PlayerButton.Visible = PartialString == "" or Username:find(PartialString)
		end
	end
	
	if SelectionType == "Global" then
		local LastSearchTime = tick()
		local CurrentSearch = PartialString
		
		task.delay(1, function()
			if string.lower(CurrentSearch) == string.lower(self.SearchBar.Prompt.Text) then
				-- Make sure player isn't the user's friend
				if self.Friends then
					for _, Player in pairs(self.Friends) do
						if (Player.Username == CurrentSearch) then
							print("Already a friend")
							return
						end
					end
				end
				
				local Success, UserId = pcall(function()
					return Players:GetUserIdFromNameAsync(PartialString)
				end)

				if Success and UserId then
					local DisplaySuccess, UserInfo = pcall(function()
						return UserService:GetUserInfosByUserIdsAsync({UserId})
					end)

					local Username = PartialString
					local DisplayName = Username
					if DisplaySuccess and UserInfo then
						if UserInfo[1] then
							DisplayName = UserInfo[1].DisplayName
						end
					end

					local PlayerButton = self.Gui.Holder.Templates.PlayerTemplate:Clone()
					PlayerButton.Name = "!GlobalUser"
					PlayerButton.Username.Text = Username
					PlayerButton.DisplayName.Text = DisplayName
					PlayerButton.UserIcon.Image = Players:GetUserThumbnailAsync(UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180) or nil
					PlayerButton.Parent = SelectionFrame
					PlayerButton.Visible = true

					PlayerButton.MouseButton1Click:Connect(function()
						self:ConfirmSelection(UserId, Username, DisplayName, PlayerButton.UserIcon.Image)
					end)
				end
			end
		end)
	end
end

function GamepassGiftingHandler:FetchFriends(UserId : Number)
	local PlayersFriends = {}
	
	local success, pages = pcall(function()
		return Players:GetFriendsAsync(UserId)
	end)
	
	if success and pages then
		while true do
			local pagenum = 1
			
			for _, item in ipairs(pages:GetCurrentPage()) do
				table.insert(PlayersFriends, item)
			end
			if pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
			pagenum = pagenum + 1
		end
		
		return PlayersFriends
	else
		return nil
	end
end

function GamepassGiftingHandler:ConfirmSelection(UserId, Username, Displayname, UserIcon)
	if not self.SelectedGamepass then return end
	if self.ConfirmationPrompted then return end
	
	local SelectedGamepassName = self.SelectedGamepass.Name
	
	self.Confirmation.Label.Text = `Are you sure you would like to gift <b>{SelectedGamepassName}</b> to:`
	self.Confirmation.PlayerButton.Username.Text = Username
	self.Confirmation.PlayerButton.DisplayName.Text = Displayname
	self.Confirmation.PlayerButton.UserIcon.Image = UserIcon
	self.Confirmation.Visible = true
	
	self.ConfirmationPrompted = true
	
	self.ConfirmationConnections[self.Confirmation.Selections.Yes] = self.Confirmation.Selections.Yes.MouseButton1Click:Connect(function()
		Remotes.GiftGamepass:FireServer(UserId, SelectedGamepassName)
		self.Confirmation.Visible = false
		self.ConfirmationPrompted = false
		
		for _, Connection in pairs(self.ConfirmationConnections) do
			Connection:Disconnect()
		end
		self.ConfirmationConnections = {}
	end)
	
	self.ConfirmationConnections[self.Confirmation.Selections.No] = self.Confirmation.Selections.No.MouseButton1Click:Connect(function()
		self.Confirmation.Visible = false
		self.ConfirmationPrompted = false
		
		for _, Connection in pairs(self.ConfirmationConnections) do
			Connection:Disconnect()
		end
		self.ConfirmationConnections = {}
	end)
end

return GamepassGiftingHandler