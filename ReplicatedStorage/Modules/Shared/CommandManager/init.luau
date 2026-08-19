-- Services
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GamepadService = game:GetService("GamepadService")
local Players = game:GetService("Players")

-- Modules
local Commands = require( ReplicatedStorage.Modules.Shared.Commands )
local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )
local MultipleChoiceList = require( script.MultipleChoiceList )
local Stylus = require( ReplicatedStorage.Packages.Stylus )

local Remotes = ReplicatedStorage.Remotes
local CommandRemotes = Remotes.Commands

local Macros = ReplicatedStorage.Modules.Shared.Commands.Macros;
local ReferenceTime = DateTime.now().UnixTimestamp;

local IconPlayerArchetypes = { All = "rbxassetid://128503307996830", Others = "rbxassetid://102905289808532" }
local LogColors = script.LogColors:GetAttributes();

--local function SortArray(GivenTable, SortValue)
--	local Array = {}

--	for Key, Value in pairs(GivenTable) do
--		Array[#Array+1] = {
--			Name = Key,
--			Value = Value[SortValue],
--			Parameters = Value.Parameters,
--		}
--	end

--	table.sort(Array, function(A, B)
--		return A.Value < B.Value
--	end)

--	return Array
--end

local function DisplayMatchingFrames(Array, SearchText, ValueType)
	for _, Value in ipairs(Array) do
		if Value:IsA(ValueType) then
			Value.Visible = (string.lower(Value.Name):sub(1, #SearchText) == string.lower(SearchText))
		end
	end 
end

-- CommandManager Class
local CommandManager = {}
CommandManager.__index = CommandManager

function CommandManager.new(UI)
	local self = setmetatable({}, CommandManager)
	
	self.UI = UI
	self.Combat = UI.Combat
	self.LuaPlayer = UI.LuaPlayer

	self.GUI = self.LuaPlayer.PlayerGui:WaitForChild("Commands", 10)
	self.Holder = self.GUI.Holder
	self.UserCommands = self.Holder.UserCommands
	
	self.HomePage = self.UserCommands.HomePage;
	self.MacroPage = self.UserCommands.MacroPage;
	self.LogsPage = self.UserCommands.LogsPage;
	
	self.SidePanel = self.Holder.SidePanel;
	
	self.CommandsFrame = self.HomePage.CommandsFrame
	self.SelectionFrame = self.CommandsFrame.Selection
	self.ConfigurationFrame = self.CommandsFrame.Configuration

	self.PlayersFrame = self.HomePage.PlayersFrame
	self.PlayerSelection = self.PlayersFrame.Selection
	
	self.LogListsFrame = self.LogsPage.Lists;
	
	self.LogLists = {
		Commands = self.LogsPage.Lists.Commands,
		Players = self.LogsPage.Lists.Players
	};
	
	self.Heading = self.Holder.Heading;
	self.LogActions = self.LogsPage.Actions;
	
	self.Templates = self.UserCommands.Templates
	self.SelectedCommand = nil;
	self.SelectedPlayerLog = nil;
	
	self.ParameterList = {};
	self.PlayerLogs = {};
	self.CommandLogs = {};
	
	--self.GUI:GetPropertyChangedSignal("Enabled"):Connect(function()
	--	if self.Combat.UsingController then
	--		if self.GUI.Enabled then
	--			GamepadService:EnableGamepadCursor(self.Holder)
	--		else
	--			GamepadService:DisableGamepadCursor()
	--		end
	--	end
	--end)

	return self
end

function CommandManager:SendSlashCommands()
	local Channel = TextChatService:WaitForChild("TextChannels").RBXGeneral
	Channel:DisplaySystemMessage("<b>[ Commands ]</b>")
	Channel:DisplaySystemMessage("<b> /serverlock - Locks the Private Server, kicking anyone who tries to join. </b> ")
	Channel:DisplaySystemMessage("<b> /unserverlock - Unlocks the Private Server. </b> ")
	Channel:DisplaySystemMessage("<b> /serverannounce \"[message]\" - Sends an announcement to everyone in the server. (Message must be surrounded by quotes) </b> ")
	Channel:DisplaySystemMessage("<b> /toggle_hitbox - Toggles whether hitboxes are displayed or not. </b> ")
	Channel:DisplaySystemMessage("<b> /start_event [World Event name] - Start a world event (If no parameter for World Event Name is given, it will start a random one; world event names are: DeadDrop, HotProperty, InvincibleBoss) </b> ")
	Channel:DisplaySystemMessage("<b> /stop_event - Ends the current world event. </b> ")
	Channel:DisplaySystemMessage("<b> /removenewdummies - Removes all dummies that were spawned with commands. </b> ")
	Channel:DisplaySystemMessage("<b> /unban [username] - Unban's the user from your Private Server. </b> ")
	Channel:DisplaySystemMessage("<b> /moveset [username] [list;] - Removes your current moveset, and gives you all the moves from the list. </b> ")
end

function CommandManager:GetParameters()
	local Parameters = {};
	
	for _, ParameterFrame in self.ParameterList do
		if ParameterFrame.Visible then
			local Value = nil

			if ParameterFrame:FindFirstChild("Prompt") then
				Value = ParameterFrame.Prompt.ContentText
				
			elseif ParameterFrame:FindFirstChild("Check") then
				Value = ParameterFrame.SelectedValue.Value
				
			elseif ParameterFrame:FindFirstChild("ChoiceDisplay") then
				Value = ParameterFrame.SelectedValue.Value
			end

			Parameters[ParameterFrame.Name] = Value
		end
	end

	return Parameters
end

function CommandManager:CreatePlayerFrame(Name, Username, Display, Icon)
	local NewPlayerFrame = self.Templates.PlayerTemplate:Clone()
	NewPlayerFrame.Name = Name
	NewPlayerFrame.DisplayName.Text = Display
	NewPlayerFrame.Username.Text = Username or `@{Name}`
	
	if Icon then
		NewPlayerFrame.UserIcon.Image = `{Icon}`
	end

	NewPlayerFrame.Parent = self.PlayerSelection

	return NewPlayerFrame
end

function CommandManager:CreateMultipleChoiceParameters()
	local List = MultipleChoiceList.List;
	
	table.clear(self.ParameterList);
	
	for _, ParameterFrame in self.ConfigurationFrame:GetChildren() do
		if not ParameterFrame:IsA("Frame") then
			continue;
		end;
		
		self.ParameterList[ParameterFrame.Name] = ParameterFrame;
	end;
	
	for Name, Option in pairs(List) do
		local NewConfig = self.Templates.MultipleChoiceTemplate:Clone()
		NewConfig.Name = Name
		
		local Display = NewConfig.ChoiceDisplay
		Display.Heading.Title.Text = Option.Title
		
		local SelectedOption = nil
		
		for _, Choice in ipairs(Option.Choices) do
			local NewOption = self.Templates.MultipleChoiceOptionTemplate:Clone()
			NewOption.Label.Text = Choice
			NewOption.Name = Choice
			
			NewOption.Parent = Display.Selection
			
			NewOption.MouseButton1Click:Connect(function()
				if NewOption ~= SelectedOption then
					NewOption.UnselectedColor.Enabled = false

					if SelectedOption then
						SelectedOption.UnselectedColor.Enabled = true
					end
					SelectedOption = NewOption
					NewConfig.SelectedValue.Value = NewOption.Name
				end
			end)
		end
		
		NewConfig.Parent = self.SidePanel;
		
		self.ParameterList[Name] = NewConfig;
	end;
end

function CommandManager:RefreshPlayerFrames()
	-- Delete All Current Frames
	for _, Frame in pairs(self.PlayerSelection:GetChildren()) do
		if Frame:IsA("ImageButton") then
			Frame:Destroy()
		end
	end
	
	-- Create "All Players" Button
	local AllPlayersFrame = self:CreatePlayerFrame("All Players", "Run command on everyone", "All Players", IconPlayerArchetypes.All)

	AllPlayersFrame.MouseButton1Click:Connect(function()
		self:SelectPlayerFrame("All");
	end)

	-- Create "Other Players" Button
	local OtherPlayersFrame = self:CreatePlayerFrame("Other Players", "Run command on others", "Other Players", IconPlayerArchetypes.Others)

	OtherPlayersFrame.MouseButton1Click:Connect(function()
		self:SelectPlayerFrame("Others");
	end)

	-- Create Individual Player Buttons
	for _, Player in ipairs(Players:GetPlayers()) do
		local PlayerIcon = self:IconForTarget(Player);
		local PlayerFrame = self:CreatePlayerFrame(Player.Name, nil, Player.DisplayName, PlayerIcon)

		PlayerFrame.MouseButton1Click:Connect(function()
			self:SelectPlayerFrame(Player);
		end)
	end;
end;

function CommandManager:IconForTarget(Target: Player | string | number): string
	if typeof(Target) == "Instance" then
		return `rbxthumb://type=AvatarHeadShot&id={Target.UserId}&w=420&h=420`;
		
	elseif typeof(Target) == "number" then
		return `rbxthumb://type=AvatarHeadShot&id={Target}&w=420&h=420`;
	end;
	
	return IconPlayerArchetypes[Target] or "";
end

function CommandManager:SelectPlayerFrame(Target: Player | string)
	if not self.SelectedCommand then
		return;
	end;
	
	if self:GetPrimaryPage() == "Macro" then
		CommandRemotes.CreateMacro:FireServer(self.SelectedCommand.Name, Target, self:GetParameters())
	else
		CommandRemotes.Send:FireServer(self.SelectedCommand.Name, Target, self:GetParameters())
	end;
end

function CommandManager:UpdateMacroFrames()
	local ActiveMacros = #Macros:GetChildren()
	
	if ActiveMacros > 0 then
		self.HomePage.MacroList.Macros.HelpFrame.Visible = false;
	else
		self.HomePage.MacroList.Macros.HelpFrame.Visible = true;
	end;
end;

local function HashString(Text: string): number
	local ColorHash = 0;

	for index = 1, string.len(Text) do
		ColorHash = (ColorHash * 31 + string.byte(Text, index)) % 3 ^ 32
	end;
	
	return ColorHash;
end

function CommandManager:GetColorForCommand(CommandName: string): Color3
	local ColorHash = HashString(CommandName) + string.len(CommandName) * 459;

	return Color3.fromHSV((ColorHash / 1995) % 1, 0.4, 1);
end;

function CommandManager:GetColorForPermission(Permission: string): Color3
	local ColorHash = HashString(Permission) + string.len(Permission) * 231 + 192;

	return Color3.fromHSV((ColorHash / 1995) % 1, 0.4, 1);
end

function CommandManager:CreateMacroFrame(MacroConfig: Configuration)
	local Name = MacroConfig.Name;
	local Attributes = MacroConfig:GetAttributes();
	local MacroFrame = self.Templates.MacroTemplate:Clone();
	
	MacroFrame.ListBody.Title.Text = Name;
	MacroFrame.ListBody.Targets.Title.Text = Attributes.TargetDescription or "Unknown";
	MacroFrame.ListBody.Targets.Icon.Image = self:IconForTarget(Attributes.Targets);
	
	if Attributes.Parameters then
		MacroFrame.ListBody.Parameters.Title.Text = Attributes.Parameters;
		MacroFrame.ListBody.Parameters.Visible = true;
	else
		MacroFrame.ListBody.Parameters.Visible = false;
	end;
	
	MacroFrame.Close.MouseButton1Click:Connect(function()
		CommandRemotes.DeleteMacro:FireServer(MacroConfig);
		
		MacroFrame.Close.BackgroundTransparency = 0.75;
		MacroFrame.Close.TextTransparency = 0.75;
	end);
	
	MacroConfig.AncestryChanged:Once(function()
		MacroFrame:Destroy();
		
		self:UpdateMacroFrames();
	end);
	
	MacroFrame.ListBody.Title.TextColor3 = self:GetColorForCommand(Name);
	
	MacroFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 16);
	MacroFrame.Parent = self.HomePage.MacroList.Macros.ScrollingFrame;
	
	self:UpdateMacroFrames();
end;

function CommandManager:CreateCommandFrames(PanelPermission : string)--number)
	if PanelPermission ~= "Owner" then
		self.LogLists.Commands.NoPermission.Visible = true;
	else
		self.LogLists.Commands.NoPermission.Visible = false;
	end;
	
	local Col = self:GetColorForPermission(PanelPermission);
	local R, G, B = math.floor(Col.R * 255), math.floor(Col.G * 255), math.floor(Col.B * 255);
	
	self.Heading.CurrentRank.DisplayName.Text = `Current Rank: <font color='rgb({R},{G},{B})'><i>{PanelPermission}</i></font>`;
	
	for _, Frame in ipairs(self.SelectionFrame:GetChildren()) do
		if Frame:IsA("ImageButton") then
			Frame:Destroy()
		end
	end
	
	for Name, Command in pairs(Commands) do--ipairs(SortArray(Commands, "Index")) do
		-- Set Values
		local CommandFrame = self.Templates.CommandTemplate:Clone()
		CommandFrame.Name = Name
		CommandFrame.Label.Text = Name
		CommandFrame.LayoutOrder = Command.Index or 0
		
		--if (Command.TriggerLevel == 2 and PanelPermission == 3) then
		--if (table.find(Command.PermissionsToTrigger, "PS+") and PanelPermission == "PS") then
		if (PanelPermission == "PS" and table.find(Command.PermissionsToTrigger, "PS+") and not table.find(Command.PermissionsToTrigger, "PS")) then
			CommandFrame.BackgroundColor3 = Color3.fromRGB(52, 52, 52)

			CommandFrame.MouseButton1Click:Connect(function()
				local Bindable = Instance.new("BindableFunction")

				Bindable.OnInvoke = function(Text : string)
					if Text == "Purchase PS+" then
						self.LuaPlayer:PromptGamepassPurchase("Private Server+")
					end
				end

				StarterGui:SetCore("SendNotification", {
					Title = "Missing Permissions",
					Text = "You must have the PS+ Gamepass to run this command., Debug Level: " .. tostring(PanelPermission),
					Duration = 5,
					Button1 = "Purchase PS+",
					Callback = Bindable
				})
			end)
		else
			--local Visibility = (PanelPermission <= Command.TriggerLevel)
			
			local Visibility = table.find(Command.PermissionsToTrigger, PanelPermission)
			CommandFrame.Visible = Visibility
			
			CommandFrame.MouseButton1Click:Connect(function()
				-- Unselect the previous frame, if there was one
				if self.SelectedCommand then
					self.SelectedCommand.UnselectedColor.Enabled = true
				end

				-- Update Selected Frame Values
				CommandFrame.UnselectedColor.Enabled = false

				-- Hide All Parameters
				for _, PreviousParameter in self.ParameterList do
					PreviousParameter.Visible = false
				end

				-- Show All Matching Parameters
				for _, Parameter in ipairs(Command.Parameters) do
					local FoundParameter = self.ParameterList[Parameter];

					if FoundParameter then
						FoundParameter.Visible = true
					end
				end

				self.SelectedCommand = CommandFrame
			end)
		end
		
		CommandFrame.Parent = self.SelectionFrame
	end
end;

function CommandManager:CreateLogActions()
	local function CreateField(Title: string, Parent: Instance?)
		local Field = self.Templates.LogActionField:Clone();
		Field.Name = string.gsub(Title, " ", "");
		Field.TextBox.Text = "";
		Field.Title.Text = Title;
		Field.Parent = Parent;
		
		return Field;
	end;
	
	local function CreatePlayerField(Title: string, Parent: Instance?)
		local Field = self.Templates.LogActionPlayerField:Clone();
		Field.Name = string.gsub(Title, " ", "");
		Field.Icon.Image = "";
		Field.Parent = Parent;
		
		return Field;
	end;
	
	local PlayerActions = self.LogActions.PlayerActions.ScrollingFrame;
	local CommandActions = self.LogActions.CommandActions.ScrollingFrame;
	
	CreatePlayerField("Player Icon", PlayerActions);
	CreateField("Timestamp", PlayerActions);
	CreateField("Display Name", PlayerActions);
	CreateField("User Name", PlayerActions);
	CreateField("User Id", PlayerActions);
	
	CreatePlayerField("Player Icon", CommandActions);
	CreateField("Timestamp", CommandActions);
	CreateField("Display Name", CommandActions);
	CreateField("User Name", CommandActions);
	CreateField("User Id", CommandActions);
	CreateField("Permission", CommandActions);
	CreateField("Command Name", CommandActions);
	CreateField("Parameters", CommandActions);
	CreateField("Target Scope", CommandActions);
	CreateField("Target Display Name", CommandActions);
	CreateField("Target User Name", CommandActions);
	CreateField("Target User Id", CommandActions);
	CreateField("Restricted", CommandActions);
	CreateField("Macro", CommandActions);
end

function CommandManager:GetLogColor(Log): ColorSequence
	local IsMultiTarget = Log.TargetType == "Others" or Log.TargetType == "All";
	
	if Log.WasRestricted then
		return LogColors.Restricted;

	elseif Log.IsMacro then
		if IsMultiTarget then
			return LogColors.MacroGeneral;
		else
			return LogColors.Macro;
		end;
		
	elseif IsMultiTarget then
		return LogColors.General;
	end;
	
	return LogColors.Default;
end;

function CommandManager:RenderCommandLog(Log)
	if Log.Frame then
		Log.Frame:Destroy();
		Log.Frame = nil;
	end;
	
	local Time = DateTime.fromUnixTimestamp(Log.UnixTimestamp)
	local CommandLog = self.Templates.CommandLogTemplate:Clone();

	CommandLog.Button.UIGradient.Color = self:GetLogColor(Log);
	CommandLog.Body.Status.TextColor3 = self:GetColorForPermission(Log.Permission);
	CommandLog.Frame.BackgroundColor3 = self:GetColorForCommand(Log.CommandName);
	CommandLog.Body.Status.Text = Log.Permission;
	CommandLog.Body.TitleBody.Title.Text = Log.UserName;
	CommandLog.Body.TitleBody.Command.Text = Log.CommandName;
	CommandLog.Body.TitleBody.PlayerIcon.Image = self:IconForTarget(Log.UserId);
	CommandLog.Body.TitleBody.Time.Text = `{Time:FormatLocalTime("L", "en-us")} at {Time:FormatLocalTime("LTS", "en-us")}`;
	CommandLog.LayoutOrder = -Log.UniqueId;
	CommandLog.Parent = self.LogLists.Commands.ScrollingFrame;

	CommandLog.Button.MouseButton1Click:Connect(function()
		self:SelectCommandLog(Log);
	end);

	Log.QueryText = string.lower(`{Log.UserName}-{Log.DisplayName}-{Log.CommandName}-{Log.Permission}`);
	Log.Frame = CommandLog;
	
	return CommandLog;
end

function CommandManager:CreateCommandLog(Log)
	local PreviousLog = self.CommandLogs[Log.Id];

	-- Delete old entries (they get overwritten when reaching the max log limit)
	if PreviousLog and PreviousLog.Frame then
		PreviousLog.Frame:Destroy();
		PreviousLog.Frame = nil;
	end;
	
	if self.RenderLogs then
		self:RenderCommandLog(Log);
	end;
	
	self.CommandLogs[Log.Id] = Log;
end;

function CommandManager:RenderPlayerLog(Log)
	if Log.Frame then
		Log.Frame:Destroy();
		Log.Frame = nil;
	end;
	
	local Time = DateTime.fromUnixTimestamp(Log.UnixTimestamp)
	local PlayerLog = self.Templates.PlayerJoinTemplate:Clone();
	
	if Log.Join then
		PlayerLog.Body.Status.TextColor3 = Color3.fromRGB(130, 255, 128);
		PlayerLog.Frame.BackgroundColor3 = Color3.fromRGB(130, 255, 128);
		PlayerLog.Body.Status.Text = "Joined";
	else
		PlayerLog.Body.Status.TextColor3 = Color3.fromRGB(255, 129, 129);
		PlayerLog.Frame.BackgroundColor3 = Color3.fromRGB(255, 129, 129);
		PlayerLog.Body.Status.Text = "Left";
	end;
	
	PlayerLog.LayoutOrder = -Log.UniqueId;
	PlayerLog.Body.TitleBody.Title.Text = Log.UserName;
	PlayerLog.Body.TitleBody.Time.Text = `{Time:FormatLocalTime("L", "en-us")} at {Time:FormatLocalTime("LTS", "en-us")}`;
	PlayerLog.Body.TitleBody.PlayerIcon.Image = self:IconForTarget(Log.UserId);
	PlayerLog.Parent = self.LogLists.Players.ScrollingFrame;

	PlayerLog.Button.MouseButton1Click:Connect(function()
		self:SelectPlayerLog(Log);
	end);

	Log.QueryText = string.lower(`{Log.UserName}-{Log.DisplayName}-{Log.UserId}`);
	Log.Frame = PlayerLog;
end;

function CommandManager:CreatePlayerLog(Log)
	local PreviousLog = self.PlayerLogs[Log.Id];
	
	-- Delete old entries (they get overwritten when reaching the max log limit)
	if PreviousLog and PreviousLog.Frame then
		PreviousLog.Frame:Destroy();
		PreviousLog.Frame = nil;
	end;
	
	if self.RenderLogs then
		self:RenderPlayerLog(Log);
	end;
	
	self.PlayerLogs[Log.Id] = Log;
end;

function CommandManager:SelectPlayerLog(Log)
	local LastLog = self.SelectedPlayerLog;

	if LastLog ~= Log then
		self:SelectCommandLog(nil);
		self.SelectedPlayerLog = Log;
		
		if LastLog then
			LastLog.Frame.Button.UIGradient.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
		end;

		if Log then
			Log.Frame.Button.UIGradient.Color = ColorSequence.new(Color3.fromRGB(96, 96, 96));
			
			local Actions = self.LogActions.PlayerActions.ScrollingFrame;
			
			Actions.PlayerIcon.Icon.Image = self:IconForTarget(Log.UserId);
			Actions.UserId.TextBox.Text = `{Log.UserId or "?"}`;
			Actions.UserName.TextBox.Text = Log.UserName or "?";
			Actions.DisplayName.TextBox.Text = Log.DisplayName or "?";
			Actions.Timestamp.TextBox.Text = Log.UnixTimestamp;
			
			self.LogsPage.Actions.Help.Visible = false;
			self.LogActions.PlayerActions.Visible = true;
		else
			self.LogsPage.Actions.Help.Visible = true;
			self.LogActions.PlayerActions.Visible = false;
		end;

	elseif LastLog then
		self:SelectPlayerLog(nil);
	end;
end;

function CommandManager:SelectCommandLog(Log)
	local LastLog = self.SelectedCommandLog;
	
	if LastLog ~= Log then
		self:SelectPlayerLog(nil);
		self.SelectedCommandLog = Log;
		
		if LastLog then
			LastLog.Frame.UIStroke.Color = Color3.fromRGB(42, 42, 42);
		end;
		
		if Log then
			Log.Frame.UIStroke.Color = Color3.fromRGB(212, 212, 212);
			
			local Actions = self.LogActions.CommandActions.ScrollingFrame;
			
			Actions.PlayerIcon.Icon.Image = self:IconForTarget(Log.UserId);
			Actions.UserId.TextBox.Text = `{Log.UserId or "?"}`;
			Actions.UserName.TextBox.Text = Log.UserName or "?";
			Actions.DisplayName.TextBox.Text = Log.DisplayName or "?";
			Actions.Timestamp.TextBox.Text = Log.UnixTimestamp;
			
			Actions.Permission.TextBox.Text = Log.Permission or "?";
			Actions.CommandName.TextBox.Text = Log.CommandName or "?";
			
			local Parameters = {} do
				local Sorting = {};
				
				for Name, Value in ( Log.Parameters or {} ) do
					table.insert(Sorting, Name);
				end;
				
				table.sort(Sorting, function(a, b)
					return a > b;
				end);
				
				local ParameterList = Log.Parameters or {};
				
				for _, Name in Sorting do
					local Value = ParameterList[Name];
					
					if typeof(Value) == "boolean" then
						table.insert(Parameters, if Value then "🟩 True" else "🟥 False");
					else
						table.insert(Parameters, tostring(Value));
					end
				end;
			end;
			
			Actions.Parameters.TextBox.Text = table.concat(Parameters, ", ");
			
			Actions.TargetScope.TextBox.Text = `{Log.TargetType or "-"}`;
			Actions.TargetUserId.TextBox.Text = `{Log.TargetUserId or "-"}`;
			Actions.TargetUserName.TextBox.Text = Log.TargetUserName or "-";
			Actions.TargetDisplayName.TextBox.Text = Log.TargetDisplayName or "-";
			
			Actions.Restricted.TextBox.Text = if Log.WasRestricted then "🟩 Yes" else "🟥 No";
			Actions.Macro.TextBox.Text = if Log.IsMacro then "🟩 Yes" else "🟥 No";
			
			self.LogsPage.Actions.Help.Visible = false;
			self.LogActions.CommandActions.Visible = true;
		else
			self.LogsPage.Actions.Help.Visible = true;
			self.LogActions.CommandActions.Visible = false;
		end;
		
	elseif LastLog then
		self:SelectCommandLog(nil);
	end;
end;

function CommandManager:SearchForLog(Text: string)
	local SearchText = string.lower(Text);
	
	for Id, Log in self.PlayerLogs do
		if not Log.Frame then continue end;
		
		if string.match(Log.QueryText, SearchText) then
			Log.Frame.Visible = true;
		else
			Log.Frame.Visible = false;
		end;
	end;
	
	for Id, Log in self.CommandLogs do
		if not Log.Frame then continue end;
		
		if string.match(Log.QueryText, SearchText) then
			Log.Frame.Visible = true;
		else
			Log.Frame.Visible = false;
		end;
	end;
end;

function CommandManager:GetPrimaryPage(): string
	return self.PrimaryPage or string.sub(self.UserCommands.UIPageLayout.CurrentPage.Name, 1, -5)
end;

function CommandManager:SetRenderingLogs(Value: boolean)
	
	self.RenderLogs = Value;
	
	if Value then
		for Id, Log in self.PlayerLogs do
			if not Log.Frame then
				self:RenderPlayerLog(Log);
			end
		end;

		for Id, Log in self.CommandLogs do
			if not Log.Frame then
				self:RenderCommandLog(Log);
			end;
		end;
		
		self.LogListsFrame.Parent = self.LogsPage;
	else
		self.LogListsFrame.Parent = nil;
	end
end

function CommandManager:SetLogsPage(Name: string)
	local Page = if Name then self.LogLists[Name] else nil;
	local LastLogsPage = self.CurrentLogsPage;
	
	if LastLogsPage ~= Page then
		self.CurrentLogsPage = Page;
		
		if LastLogsPage then
			LastLogsPage.Visible = false;
			LastLogsPage.Parent = nil;
		end;
		
		if Page then
			Page.Visible = true;
			Page.Parent = self.LogListsFrame;
		end;
	end;
end

function CommandManager:SetPrimaryPage(Name: string)
	if (Name == "Macro") then
		self:SetPrimaryPage("Home");
		self.PrimaryPage = Name;
		self.UserCommands.HomePage.MacroList.Visible = true;
		self.SelectionFrame.UIGridLayout.CellSize = UDim2.new(1/2, -4, 0.13, -4);
	else
		local Page = self.UserCommands:FindFirstChild(`{Name}Page`);

		if not Page then
			return warn(`Unable to set page {Name}, as it does not exist`);
		end;

		self.UserCommands.UIPageLayout:JumpTo(Page);
		self.UserCommands.HomePage.MacroList.Visible = false;
		self.SelectionFrame.UIGridLayout.CellSize = UDim2.new(1/3, -4, 0.13, -4);
		
		local LastPage = self.PrimaryPage;
		
		if LastPage ~= Name then
			self.PrimaryPage = Name;
			
			if Name == "Logs" then
				self:SetRenderingLogs(true);
				
			elseif LastPage == "Logs" then
				self:SetRenderingLogs(false);
			end;
		end;
	end;
end

function CommandManager:SetupCommands()
	self.LuaPlayer.Player:GetAttributeChangedSignal("PanelPermission"):Connect(function()
		self:CreateCommandFrames(self.LuaPlayer.Player:GetAttribute("PanelPermission") or "None")
	end)

	self:CreateCommandFrames(self.LuaPlayer.Player:GetAttribute("PanelPermission") or "None")
	self:CreateMultipleChoiceParameters()
	self:CreateLogActions();
	
	-- Player Search Bar
	self.PlayersFrame.SearchBar.Prompt:GetPropertyChangedSignal("ContentText"):Connect(function()
		local PromptText = self.PlayersFrame.SearchBar.Prompt.ContentText

		DisplayMatchingFrames(self.PlayerSelection:GetChildren(), PromptText, "ImageButton")
	end)

	-- Check Boxes
	for _, CheckBox in ipairs(self.ConfigurationFrame:GetChildren()) do
		if CheckBox:FindFirstChild("Check") then
			local SelectedVal = CheckBox.SelectedValue
			local CheckedIcon = CheckBox.Check.Checked
			local UncheckedIcon = CheckBox.Check.Unchecked

			CheckBox.Button.MouseButton1Click:Connect(function()
				if (SelectedVal.Value == false) then
					SelectedVal.Value = true
					CheckedIcon.Visible = true
					UncheckedIcon.Visible = false
				else
					SelectedVal.Value = false
					CheckedIcon.Visible = false
					UncheckedIcon.Visible = true
				end
			end)
		end;
	end; 
	
	self.Holder.Heading.Body.Home.MouseButton1Click:Connect(function()
		self:SetPrimaryPage("Home");
	end);
	
	self.Holder.Heading.Body.Macro.MouseButton1Click:Connect(function()
		self:SetPrimaryPage("Macro");
	end);
	
	self.Holder.Heading.Body.Logs.MouseButton1Click:Connect(function()
		self:SetPrimaryPage("Logs");
	end);
	
	self.LogsPage.LogTabs.ScrollingFrame.Commands.MouseButton1Click:Connect(function()
		self:SetLogsPage("Commands");
	end);
	
	self.LogsPage.LogTabs.ScrollingFrame.PlayerJoins.MouseButton1Click:Connect(function()
		self:SetLogsPage("Players");
	end);
	
	Stylus.bind_to_resize(self.Heading.CurrentRank.DisplayName, function(size)
		self.Heading.CurrentRank.DisplayName.TextSize = size.Y;
	end)
	
	-- Send Slash Commands if button is clicked
	self.Holder.Heading.SlashCommands.MouseButton1Click:Connect(function()
		CommandManager:SendSlashCommands()
	end);
	
	CommandRemotes.SendPlayerLogs.OnClientEvent:Connect(function(Logs)
		for _, Log in Logs do
			Log.Type = "Player";
			self:CreatePlayerLog(Log);
		end;
	end)
	
	CommandRemotes.SendCommandLogs.OnClientEvent:Connect(function(Logs)
		for _, Log in Logs do
			Log.Type = "Command";
			self:CreateCommandLog(Log);
		end;
	end);
	
	self.LogListsFrame.Search.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		self:SearchForLog(self.LogListsFrame.Search.TextBox.Text);
	end)
	
	self.LogsPage.Actions.Help.Visible = true;
	self.LogActions.PlayerActions.Visible = false;
	self.LogActions.CommandActions.Visible = false;
	self.Heading.CurrentRank.DisplayName.TextScaled = false;
	self.Heading.CurrentRank.DisplayName.RichText = true;
	
	for _, Page in self.LogLists do
		Page.Visible = false;
	end;
	
	self:SetPrimaryPage("Home");
	self:SetLogsPage("Players");
	
	self:RefreshPlayerFrames();
	
	Players.PlayerAdded:Connect(function()
		self:RefreshPlayerFrames()
	end);

	Players.PlayerRemoving:Connect(function()
		self:RefreshPlayerFrames()
	end);
	
	Macros.ChildAdded:Connect(function(Macro)
		self:CreateMacroFrame(Macro);
	end);
	
	for _, Macro in Macros:GetChildren() do
		task.spawn(self.CreateMacroFrame, self, Macro);
	end;
end

return CommandManager