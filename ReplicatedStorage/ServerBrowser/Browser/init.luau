local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

-----------------------------------------------------------------------------------------------------

local Replicated = ReplicatedStorage:WaitForChild("ServerBrowser");
local Remotes = Replicated:WaitForChild("Remotes");
local ServerStatus = Replicated:WaitForChild("ServerStatus");

-----------------------------------------------------------------------------------------------------

local Stylus = require( ReplicatedStorage.Packages.Stylus )
local PageList = require( ReplicatedStorage.Packages.PageList )
local Maid = require( ReplicatedStorage.Packages.Maid )
local Validation = require( ReplicatedStorage.ServerBrowser.Validation )
local Utility = require( "./Utility" );

local Loading = require( script.Loading )
local Confirmations = require( script.Confirmations )

-----------------------------------------------------------------------------------------------------

local Player = Players.LocalPlayer;
local PlayerGui: typeof(StarterGui) = Player:WaitForChild("PlayerGui");

-----------------------------------------------------------------------------------------------------

local Assets = script:WaitForChild("Assets");
local Sounds = script:WaitForChild("Sounds");
local UI = PlayerGui:WaitForChild("ServerBrowser");

local ServerList = UI.Body.Servers.Pages.List;

local GUI = {
	ServerCanvas = UI.Body.Servers;
	SideCanvas = UI.Body.Side;
	Pages = UI.Body.Servers.Pages;

	ListScrollFrame = UI.Body.Servers.Pages.List.Scrolling,
	ListScrollItems = UI.Body.Servers.Pages.List.Scrolling.Items;

	MyServer = UI.Body.Servers.Pages.MyServer;
	MyServerSettings = UI.Body.Servers.Pages.MyServer.ServerBody.Settings.ScrollingFrame;
	MyServerInfo = UI.Body.Servers.Pages.MyServer.ServerBody.Info.ScrollingFrame;
	AdminServer = UI.Body.Servers.Pages.Admin.ScrollingFrame.Server;
	AdminUser = UI.Body.Servers.Pages.Admin.ScrollingFrame.User;
	Admin = UI.Body.Servers.Pages.Admin;

	SideButtons = UI.Body.Side.Buttons;
	CodeFrame = UI.Body.Side.Code;
	ServerPages = ServerList.Scrolling;
	PageControl = ServerList.Pages;
	Filtering = ServerList.Control;
	InfoFrame = ServerList.Info;
};

-----------------------------------------------------------------------------------------------------

local ServerBrowser = {};
ServerBrowser.__index = ServerBrowser;

function ServerBrowser.new()
	local self = setmetatable(
		{
			UI = UI;
			enabled = false;
			is_admin = false;

			server_list = {};
			server_frames = {};
			tweens = {};
			gui = GUI;

			number_of_servers = 0;
			last_server_refresh = tick();

			current_access_code = nil;
		}, 
		ServerBrowser);

	self.confirmations = Confirmations.new(self);

	self:initialise_tweens();
	self:initialise();

	return self;
end;

-----------------------------------------------------------------------------------------------------

local function set_user_name(frame, user_id)
	frame.Body.Left.Creator.Creator.Text = Utility.get_user_identifer(user_id);
end

function ServerBrowser:update_server(item)
	local frame: typeof(Assets.ServerFrame);

	if self.server_frames[item.access_code] then
		frame = self.server_frames[item.access_code];
	else
		frame = Assets.ServerFrame:Clone();
		frame.Body.Left.Creator.Creator.Text = "---";
		frame.Body.Right.AccessCode.Title.Text = item.access_code;
		frame.UIStroke.Transparency = 0.6;
		frame.Name = item.title;

		task.spawn(set_user_name, frame, item.owner_id);

		frame.MouseEnter:Connect(function()
			TweenService:Create(frame.UIStroke, TweenInfo.new(0.25), {Transparency = 0}):Play()
			TweenService:Create(frame.Main, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(128, 128, 128)}):Play()
		end)

		frame.MouseLeave:Connect(function()
			TweenService:Create(frame.UIStroke, TweenInfo.new(0.25), {Transparency = frame.UIStroke:GetAttribute("TargetTransparency")}):Play()
			TweenService:Create(frame.Main, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
		end)

		frame.Main.MouseButton1Click:Connect(function()
			self:join_server(item.access_code);
		end)

		self.items_page:add_item(frame, item.access_code);
		self.server_frames[item.access_code] = frame;
	end;

	local stroke_hover_transparency = 0.6;

	if (item.access_code == self.current_access_code) then
		stroke_hover_transparency = 0.4;
		frame.UIStroke.Color = Color3.fromRGB(193, 255, 170);

	elseif (item.owner_id == Player.UserId) then
		stroke_hover_transparency = 0.4;
		frame.UIStroke.Color = Color3.fromRGB(148, 177, 255);
	end;

	frame.UIStroke.Transparency = stroke_hover_transparency;
	frame.UIStroke:SetAttribute("TargetTransparency", stroke_hover_transparency);

	frame.Body.Left.Title.Text = item.title;
	frame.Body.Right.PlayerCount.Title.Text = `{item.player_count}/{Players.MaxPlayers}`;

	return frame;
end

function ServerBrowser:remove_server(access_code: string)
	local frame = self.server_frames[access_code];

	if frame then
		frame:Destroy();

		self.server_frames[access_code] = nil;
		self.items_page:remove_item(frame);
	end
end

function ServerBrowser:clear_servers(ignore_access_codes)
	for access_code, frame in pairs(self.server_frames) do
		if not ignore_access_codes[access_code] then
			self:remove_server(access_code);
		end;
	end;
end;

function ServerBrowser:sort_servers(callback)
	local servers = {};

	local function sort(frame1, frame2)
		local server_1 = self.server_list[self.items_page.items[frame1]];
		local server_2 = self.server_list[self.items_page.items[frame2]];

		servers[frame1] = server_1;
		servers[frame2] = server_2;

		return callback( server_1, server_2 )
	end;

	self.items_page:sort(sort);
end

local function get_server_priority_value(self, server): number
	if (server.access_code == self.current_access_code) then
		return 3;
	elseif (server.owner_id == Player.UserId) then 
		return 2;
	else 
		return 1;
	end
end;

local function get_priority_sorted(self, server_1, server_2): (boolean, boolean)
	local aPriority = get_server_priority_value(self, server_1)
	local bPriority = get_server_priority_value(self, server_2)

	if aPriority ~= bPriority then
		return true, aPriority > bPriority;
	else
		return false, false;
	end;
end;

function ServerBrowser:sort_servers_by_player_count(direction: Enum.SortDirection)
	if (direction == Enum.SortDirection.Descending) then
		self:sort_servers(function(item1, item2)
			local use_priority, is_higher = get_priority_sorted(self, item1, item2);

			if use_priority then
				return is_higher;
			else
				return item1.player_count > item2.player_count;
			end
		end)
	else
		self:sort_servers(function(item1, item2)
			local use_priority, is_higher = get_priority_sorted(self, item1, item2);

			if use_priority then
				return is_higher;
			else
				return item1.player_count < item2.player_count;
			end
		end)
	end;
end;

function ServerBrowser:refresh_servers(list)
	assert(list, "No Server List");

	self:clear_servers(list);

	for _, item in list do
		self:update_server(item);
	end;

	GUI.InfoFrame.Display.Shown.Text = `{self.number_of_servers} Servers`;
	GUI.ListScrollItems.Parent = GUI.ListScrollFrame;

	self:start_refresh_timer();
	self:sort_servers_by_player_count(Enum.SortDirection.Descending);

	self.items_page:search(GUI.Filtering.Search.Text);

	local last_page = self.items_page:get_max_pages();

	for index, page in self.items_page.pages do
		local end_of_list = page.ScrollingFrame.Eof;

		if index >= last_page then
			end_of_list.Title.Text = "You've reached the end.";
		else
			end_of_list.Title.Text = "Go to the next page!";
		end;
	end;
end;

function ServerBrowser:load_server(server)
	self.selected_server = server;

	if server then
		local info = server or {};
		local max_players = info.max_players or Players.MaxPlayers;

		GUI.MyServerSettings.Rename.Box.Text = info.title or "";
		GUI.MyServerSettings.AccessCode.Box.Text = info.access_code or "";
		GUI.MyServerSettings.MaxPlayers.Box.Text = max_players;
		GUI.MyServerInfo.Status.Title.Text = "Status: Active";
		GUI.MyServerInfo.PlayerCount.Title.Text = `Players: {info.player_count or 0}/{max_players}`;
		GUI.MyServerInfo.ServerTitle.Text = info.title or "No Title";

		GUI.MyServer.CreateBody.Visible = false;
		GUI.MyServer.ServerBody.Visible = true;
	else
		GUI.MyServer.CreateBody.Visible = true;
		GUI.MyServer.ServerBody.Visible = false;
	end
end

function ServerBrowser:load_enforcement_server(access_code: string)
	if not access_code or access_code == "" then
		GUI.AdminServer.Controls.Visible = false;
	else
		local server = Remotes.RequestServer:InvokeServer(access_code);

		if server then
			self.enforcement_server = server;

			GUI.AdminServer.Controls.ServerName.Box.Text = server.title or "?";
			GUI.AdminServer.Controls.PlayerCount.Box.Text = `{server.player_count or 0}`;
			GUI.AdminServer.Controls.OwnerName.Box.Text = Utility.get_user_identifer(server.owner_id);
			GUI.AdminServer.Controls.OwnerId.Box.Text = `{server.owner_id}`;
			GUI.AdminServer.Controls.Visible = true;

			SoundService:PlayLocalSound(Sounds.Found);
		else
			self:create_message(`No server exists with access code '{access_code}'`);
		end
	end;
end;

function ServerBrowser:load_enforcement_user(user_id: string): ()
	if not user_id or user_id == "" then
		GUI.AdminUser.Controls.Visible = false;
	else
		local status = Remotes.RequestUserStatus:InvokeServer(user_id);

		if status then
			self.enforcement_user = status.id;

			GUI.AdminUser.Controls.Visible = true;
			GUI.AdminUser.Controls.Ban.Visible = not status.is_banned;
			GUI.AdminUser.Controls.Unban.Visible = status.is_banned;

			SoundService:PlayLocalSound(Sounds.Found);
		else
			self:create_message(`No user exists with user id '{user_id}'`);
		end
	end;
end

function ServerBrowser:get_latest_server_from_list(list)
	local latest_server;
	local latest_time = -math.huge;

	for _, server in list do
		if server.time > latest_time then
			latest_server = server;
			latest_time = server.time;
		end;
	end;

	return latest_server;
end

function ServerBrowser:load_my_servers()
	self.loading_my_servers:set(true);

	local success, list = pcall(Remotes.RequestMyServers.InvokeServer, Remotes.RequestMyServers);

	if success and list then
		local latest_server = self:get_latest_server_from_list(list);

		self:load_server(latest_server);
	end

	if not success then
		warn("Requesting servers was unsuccessful");

	elseif not list then
		warn("No list was returned");
	end;

	self.loading_my_servers:set(false);
end

function ServerBrowser:moderate_user(user_id: string, parameters: any): ()
	Remotes.ModerateUser:FireServer(user_id, parameters);
end

function ServerBrowser:moderate_server(access_code: string): ()
	Remotes.ModerateServer:FireServer(access_code);
end

function ServerBrowser:delete_server(access_code: string)
	Remotes.DeleteServer:FireServer(access_code);
end

function ServerBrowser:join_server(access_code: string): ()
	self:create_message("Teleporting to server, please wait.");
	Remotes.JoinServer:FireServer(access_code);
end;

function ServerBrowser:rename_server(access_code: string, new_title: string): ()
	self:edit_server_details(access_code, {
		title = new_title;
	});
end;

function ServerBrowser:edit_server_details(access_code: string, details: any): ()
	self:create_message("Applying changes");
	Remotes.EditServer:FireServer(access_code, details);
end

function ServerBrowser:toggle(value: boolean?)
	if (value == nil) then
		value = not self.enabled;
	end;

	if self.enabled ~= value then
		self.enabled = value;
		UI.Enabled = true;

		self.confirmations:cancel();

		if self.enabled then
			Remotes.ViewerSubscribe:FireServer();
			Stylus:tween_blur(18, "ServerBrowser");
			SoundService:PlayLocalSound(Sounds.Open);

			GUI.ListScrollItems.Parent = nil;
			self.tweens.open();

			task.delay(0.25, self.refresh_servers_async, self);
		else
			Remotes.ViewerUnsubscribe:FireServer();
			Stylus:tween_blur(0, "ServerBrowser");

			GUI.ListScrollItems.Parent = nil;
			self.tweens.close();
		end
	end
end

function ServerBrowser:ghostify()
	local info = TweenInfo.new(0.25);

	TweenService:Create(UI.Body.UIScale, info, {Scale = 0.9}):Play()

	for _, canvas in UI.Body:GetChildren() do
		if canvas:IsA("CanvasGroup") and canvas.Name ~= "Confirm" then
			TweenService:Create(canvas, info, {GroupTransparency = 0.9}):Play()
		end
	end
end

do
	local function start_refresh_thread(self)
		repeat
			GUI.InfoFrame.Display.Refresh.Text = `Refreshed {math.floor(tick() - self.last_server_refresh)}s ago`;
			task.wait(1);
		until not self;
	end;

	function ServerBrowser:start_refresh_timer()
		self.last_server_refresh = tick();

		if self.server_refresh_thread then
			if coroutine.status(self.server_refresh_thread) == "suspended" then
				task.cancel(self.server_refresh_thread);
			end;

			self.server_refresh_thread = nil;
		end;

		self.server_refresh_thread = task.spawn(start_refresh_thread, self);
	end
end;

function ServerBrowser:initialise_tweens()
	local open_tweens = {};
	local close_tweens = {};

	local info = TweenInfo.new(0.2);

	local scale_open = TweenService:Create(UI.Body.UIScale, info, {Scale = 1});
	local scale_close = TweenService:Create(UI.Body.UIScale, info, {Scale = 0.6});

	scale_close.Completed:Connect(function(status)
		if (status == Enum.PlaybackState.Completed) then
			UI.Enabled = false;
		end
	end)

	table.insert(open_tweens, scale_open);
	table.insert(close_tweens, scale_close);

	for _, canvas in UI.Body:GetChildren() do
		if canvas:IsA("CanvasGroup") then
			table.insert(open_tweens, TweenService:Create(canvas, info, {GroupTransparency = 0}));
			table.insert(close_tweens, TweenService:Create(canvas, info, {GroupTransparency = 1}));
		end
	end

	function self.tweens.open()
		for _, tween in open_tweens do
			tween:Play();
		end;
	end

	function self.tweens.close()
		for _, tween in close_tweens do
			tween:Play();
		end;
	end
end

function ServerBrowser:update_server_list(server_list)
	table.clear(self.server_list);

	self.number_of_servers = 0;

	for key, item in server_list do
		if not item.access_code then
			continue;
		end;

		self.number_of_servers += 1;
		self.server_list[item.access_code] = item;
	end;

	self:refresh_servers(self.server_list);

	GUI.SideButtons.Refresh.Button.Button.Icon.ImageColor3 = Color3.fromRGB(255, 255, 255);
end

function ServerBrowser:refresh_servers_async()
	self.loading_server_list:set(true);

	local success, list = pcall(Remotes.RequestServerList.InvokeServer, Remotes.RequestServerList);

	if success and list then
		self:update_server_list(list);
	end;

	self.loading_server_list:set(false);
end

function ServerBrowser:create_message(message: string)
	local frame = Assets.Message:Clone();
	frame.Body.Title.Text = message;
	frame.Visible = true;
	frame.Parent = UI.Body.Bottom.Messages;

	task.delay(6, function()
		frame:Destroy();
	end)

	SoundService:PlayLocalSound(Sounds.Fail);

	return frame;
end

local function create_control_box(info)
	local button = Assets.ControlBox:Clone();
	button.Title.Text = info.title;
	button.Name = info.name or info.title;
	button.Box.Text = info.text or "";
	button.Box.PlaceholderText = info.placeholder_text or "Enter Here";

	if info.read_only then
		button.Box.TextEditable = false;
	end;

	button.Parent = info.parent;

	return button;
end

local function create_side_button(info)
	local button = Assets.SideButton:Clone();
	button.Title.Text = info.title;
	button.Name = info.title;
	button.Button.Button.Icon.Image = info.image;
	button.Button.Button.MouseButton1Click:Connect(info.callback);
	button.Parent = info.parent or GUI.SideButtons;

	return button;
end

local function create_control_button(info)
	local button = Assets.ServerControl:Clone();
	button.Name = info.title;
	button.Button.Button.Title.Text = info.title;
	button.Button.Button.Icon.Image = info.image;
	button.Button.Button.MouseButton1Click:Connect(info.callback);
	button.Button.Button.BackgroundColor3 = info.color or button.Button.Button.BackgroundColor3;

	if info.icon_ratio then
		button.Button.Button.Icon.UIAspectRatioConstraint.AspectRatio = info.icon_ratio;
	end

	if info.size then
		button.Size = info.size;
	end;

	button.Parent = info.parent or GUI.MyServer.Controls;

	return button;
end

function ServerBrowser:load_as_admin()
	if self.is_admin then return end;

	self.is_admin = true;

	create_side_button({
		title = "Admin";
		image = "rbxassetid://560667850",
		callback = function()
			GUI.Pages.UIPageLayout:JumpTo(GUI.Admin);
		end,
	});

	GUI.AdminServer.Access.Box.FocusLost:Connect(function(enter_pressed)
		if enter_pressed then
			self:load_enforcement_server(GUI.AdminServer.Access.Box.Text);
		end;
	end);

	GUI.AdminUser.Access.Box.FocusLost:Connect(function(enter_pressed)
		if enter_pressed then
			self:load_enforcement_user(GUI.AdminUser.Access.Box.Text);
		end
	end)

	create_control_box({
		title = "Server Name";
		name = "ServerName";
		placeholder_text = `Server Title`;
		read_only = true;
		parent = GUI.AdminServer.Controls;
	});

	create_control_box({
		title = "Player Count";
		name = "PlayerCount";
		placeholder_text = `Player Count`;
		read_only = true;
		parent = GUI.AdminServer.Controls;
	});

	create_control_box({
		title = "Owner Name";
		name = "OwnerName";
		placeholder_text = `Player Name`;
		read_only = true;
		parent = GUI.AdminServer.Controls;
	});

	create_control_box({
		title = "Owner Id";
		name = "OwnerId";
		placeholder_text = `User Id`;
		read_only = true;
		parent = GUI.AdminServer.Controls;
	});

	create_control_box({
		title = "Duration (Days)";
		name = "Duration";
		placeholder_text = `-1 is permenant`;
		read_only = false;
		parent = GUI.AdminUser.Controls;
	});

	create_control_box({
		title = "Reason";
		name = "Reason";
		placeholder_text = `Reason`;
		read_only = false;
		parent = GUI.AdminUser.Controls;
	});

	create_control_button({
		title = "Join",
		image = "rbxasset://textures/StudioToolbox/AssetConfig/menu_friends.png";
		color = Color3.fromRGB(255, 255, 255);
		parent = GUI.AdminServer.Controls;
		callback = function()
			if not self.enforcement_server then return end;

			self.confirmations:make("Join", "Are you sure you want to join this server?", function(accepted)
				if accepted then
					self:join_server(self.enforcement_server.access_code);
				end;
			end);
		end,
	});

	create_control_button({
		title = "Delete",
		image = "rbxasset://textures/ui/Keyboard/close_button_icon.png";
		color = Color3.fromRGB(255, 57, 57);
		icon_ratio = 1;
		parent = GUI.AdminServer.Controls;
		callback = function()
			if not self.enforcement_server then return end;

			self.confirmations:make("Warning!", "Are you sure you want to shutdown this server?", function(accepted)
				if accepted then
					self:moderate_server(self.enforcement_server.access_code);
					self:create_message("Taken action against server");
					self:load_enforcement_server(nil);
				end;
			end);
		end,
	});

	create_control_button({
		title = "Ban",
		image = "rbxassetid://560667850";
		color = Color3.fromRGB(255, 85, 79);
		icon_ratio = 1;
		parent = GUI.AdminUser.Controls;
		callback = function()
			if not self.enforcement_user then return end;

			self.confirmations:make("Ban", "Are you sure you want to ban this user?", function(accepted)
				if accepted then
					local duration = tonumber(GUI.AdminUser.Controls.Duration.Box.Text);

					if not duration then
						return self:create_message("Duration is invalid :(")
					end;

					if duration ~= -1 then
						duration = duration * 24 * 60 * 60;
					end

					self:moderate_user(self.enforcement_user, {
						reason = GUI.AdminUser.Controls.Reason.Box.Text,
						duration = duration,
					});
				end;
			end);
		end,
	});

	create_control_button({
		title = "Unban",
		image = "rbxassetid://560667850";
		color = Color3.fromRGB(233, 255, 120);
		icon_ratio = 1;
		parent = GUI.AdminUser.Controls;
		callback = function()
			if not self.enforcement_user then return end;

			self.confirmations:make("Unban", "Are you sure you want to unban this user?", function(accepted)
				if accepted then
					self:moderate_user(self.enforcement_user, {
						unban = true;
					});
				end;
			end);
		end,
	});

	self:load_enforcement_server(nil);
	self:load_enforcement_user(nil);

	GUI.Admin.Visible = true;
end

function ServerBrowser:initialise()

	self.loading_server_list = Loading.new( GUI.Pages.List.Scrolling );
	self.loading_create = Loading.new( GUI.Pages.Create );
	self.loading_my_servers = Loading.new( GUI.MyServer );

	self.loading_server_list.changed:Connect(function(value)
		GUI.ListScrollItems.Visible = not value;
	end)

	local function open_browser(action_name, state, input)
		if (state == Enum.UserInputState.Begin) then
			self:toggle();
		end
	end;

	--ContextActionService:BindAction("OpenServerBrowser", open_browser, false, Enum.KeyCode.L);

	create_side_button({
		title = "Refresh";
		image = "rbxassetid://4359854600",
		callback = function()
			if self.loading_server_list.is_loading then return end;

			if GUI.Pages.UIPageLayout.CurrentPage ~= GUI.Pages.List then
				self.loading_server_list:set(true);
				GUI.Pages.UIPageLayout:JumpTo(GUI.Pages.List);
				task.wait(0.3);
				self.loading_server_list:set(false);
			end;

			self:refresh_servers_async();
		end,
	})

	create_side_button({
		title = "Create",
		image = "http://www.roblox.com/asset/?id=401613236",
		callback = function()
			GUI.Pages.UIPageLayout:JumpTo(GUI.Pages.Create);
		end,
	})

	create_side_button({
		title = "My Server";
		image = "rbxassetid://9692125126",
		callback = function()
			GUI.Pages.UIPageLayout:JumpTo(GUI.MyServer);
		end,
	});

	create_control_button({
		title = "Create Server",
		image = "http://www.roblox.com/asset/?id=401613236",
		parent = GUI.Pages.Create.Controls;
		callback = function()
			if self.loading_create.is_loading then return end;

			self.loading_create:set(true);

			local success, was_created, err = pcall(Remotes.CreateServer.InvokeServer, Remotes.CreateServer, {
				title = GUI.Pages.Create.Rename.Box.Text;
			});

			if not success then
				warn("Unable to create server:", was_created);

			elseif not was_created then
				if err then
					warn("Unable to create server:", err);
				else
					warn("Unable to create server.");
				end;
			else
				GUI.Pages.UIPageLayout:JumpTo(GUI.MyServer);
				SoundService:PlayLocalSound(Sounds.Created);
				task.spawn(self.refresh_servers_async, self);
			end;

			self.loading_create:set(false);
		end,
	})

	create_control_button({
		title = "Create One!",
		image = "http://www.roblox.com/asset/?id=401613236";
		parent = GUI.MyServer.CreateBody.Create;
		callback = function()
			GUI.Pages.UIPageLayout:JumpTo(GUI.Pages.Create);
		end,
	})

	create_control_button({
		title = "Apply",
		image = "rbxasset://textures/AnimationEditor/icon_checkmark.png";
		size = UDim2.new(0.75, 0, 0.1, 6);
		parent = GUI.MyServer.ServerBody.Controls;
		callback = function()
			if not self.selected_server then return end;

			self.confirmations:make("Warning!", "Apply these changes?", function(accepted)
				if accepted then
					self:rename_server(self.selected_server.access_code, GUI.MyServerSettings.Rename.Box.Text);
				end;
			end);
		end,
	})

	create_control_button({
		title = "Join",
		image = "rbxasset://textures/StudioToolbox/AssetConfig/menu_friends.png";
		color = Color3.fromRGB(255, 255, 255);
		size = UDim2.new(0.75, 0, 0.1, 6);
		parent = GUI.MyServer.ServerBody.Controls;
		callback = function()
			if not self.selected_server then return end;

			self.confirmations:make("Join", "Are you sure you want to join this server?", function(accepted)
				if accepted then
					self:join_server(self.selected_server.access_code);
				end;
			end);
		end,
	});

	create_control_button({
		title = "Delete",
		image = "rbxasset://textures/ui/Keyboard/close_button_icon.png";
		color = Color3.fromRGB(255, 57, 57);
		icon_ratio = 1;
		size = UDim2.new(0.75, 0, 0.1, 6);
		parent = GUI.MyServer.ServerBody.Controls;
		callback = function()
			if not self.selected_server then return end;

			self.confirmations:make("Warning!", "Are you sure you want to delete this server?", function(accepted)
				if accepted then
					self:delete_server(self.selected_server.access_code);
					self:create_message("You have deleted your server");
					task.wait(0.5);
					self:load_my_servers();
				end
			end)
		end,
	})

	local server_valid = Validation.custom_server_info;
	local name_help_string =`Between {server_valid.title.min_length}-{server_valid.title.max_length} characters long.`

	GUI.Pages.Create.Rename.Box.PlaceholderText = name_help_string;

	create_control_box({
		title = "Name";
		name = "Rename";
		placeholder_text = name_help_string;
		parent = GUI.MyServerSettings;
	})

	create_control_box({
		title = "Access Code";
		name = "AccessCode";
		placeholder_text = `Access Code`;
		read_only = true;
		parent = GUI.MyServerSettings;
	})

	create_control_box({
		title = "Max Players";
		name = "MaxPlayers";
		placeholder_text = `Max Players`;
		read_only = true;
		parent = GUI.MyServerSettings;
	})

	self.items_page = PageList.new({
		["per_page"] = 30;
		["per_row"] = 1;
		["layout"] = GUI.ServerPages.Items.UIPageLayout;
		["page_max"] = GUI.PageControl.PageMax;
		["page_current"] = GUI.PageControl.PageCurrent;
		["next_button"] = GUI.PageControl.Next;
		["previous_button"] = GUI.PageControl.Previous;
		["page_preset"] = Assets.ServerPage;
	})

	self.items_page:get_new_page();

	GUI.Filtering.Search:GetPropertyChangedSignal("Text"):Connect(function()
		self.items_page:search(GUI.Filtering.Search.Text);
	end)

	local function update_current_access_code()
		self.current_access_code = ServerStatus:GetAttribute("AccessCode");
	end

	update_current_access_code();
	ServerStatus:GetAttributeChangedSignal("AccessCode"):Connect(update_current_access_code);

	self:start_refresh_timer();

	Remotes.Message.OnClientEvent:Connect(function(message: string)
		self:create_message(message);
	end)

	Remotes.SetAdmin.OnClientEvent:Connect(function()
		self:load_as_admin();
	end)

	Remotes.NotifyServerRefresh.OnClientEvent:Connect(function()
		local time_now = tick();

		if time_now - self.last_server_refresh > 1 then
			GUI.SideButtons.Refresh.Button.Button.Icon.ImageColor3 = Color3.fromRGB(180, 210, 255);
		end;
	end)

	GUI.ServerCanvas.Back.MouseButton1Click:Connect(function()
		GUI.Pages.UIPageLayout:JumpTo(GUI.Pages.List);
	end)

	do
		GUI.ServerCanvas.Back.MouseEnter:Connect(function()
			GUI.ServerCanvas.Back.ImageColor3 = Color3.fromRGB(199, 220, 255)
		end)

		GUI.ServerCanvas.Back.MouseLeave:Connect(function()
			GUI.ServerCanvas.Back.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end)
	end

	GUI.SideCanvas.Code.Search.FocusLost:Connect(function(enter_pressed)
		if enter_pressed then
			local access_code = GUI.SideCanvas.Code.Search.Text;
			local server = Remotes.RequestServer:InvokeServer(access_code);

			if server then
				self.confirmations:make("Warning!", `You will be teleported to '{server.title}', are you sure?`, function(accepted)
					if accepted then
						self:join_server(access_code);
					end
				end)
			else
				self:create_message("Access code is invalid");
			end
		end
	end)

	GUI.Pages.UIPageLayout.PageEnter:Connect(function(page)
		if (page == GUI.Pages.List) then
			GUI.ServerCanvas.Back.Visible = false;
		else
			GUI.ServerCanvas.Back.Visible = true;

			if (page == GUI.MyServer) then
				self:load_my_servers();
			end
		end
	end)

	GUI.ServerCanvas.Back.Visible = false;
	UI.Enabled = false;
	UI.Body.UIScale.Scale = 0;
end

table.freeze(ServerBrowser);

return ServerBrowser.new();

--local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local ContextActionService = game:GetService("ContextActionService")
--local SoundService = game:GetService("SoundService")
--local TweenService = game:GetService("TweenService")
--local RunService = game:GetService("RunService")
--local StarterGui = game:GetService("StarterGui")
--local Players = game:GetService("Players")

-------------------------------------------------------------------------------------------------------

--local Replicated = ReplicatedStorage:WaitForChild("ServerBrowser");
--local Remotes = Replicated:WaitForChild("Remotes");
--local ServerStatus = Replicated:WaitForChild("ServerStatus");

-------------------------------------------------------------------------------------------------------

--local Stylus = require( ReplicatedStorage.Packages.Stylus )
--local PageList = require( ReplicatedStorage.Packages.PageList )
--local Maid = require( ReplicatedStorage.Packages.Maid )
--local Validation = require( ReplicatedStorage.ServerBrowser.Validation )
--local Utility = require( "./Utility" );

--local Loading = require( script.Loading )
--local Confirmations = require( script.Confirmations )

-------------------------------------------------------------------------------------------------------

--local Player = Players.LocalPlayer;
--local PlayerGui: typeof(StarterGui) = Player:WaitForChild("PlayerGui");

-------------------------------------------------------------------------------------------------------

--local Assets = script:WaitForChild("Assets");
--local Sounds = script:WaitForChild("Sounds");
--local UI = PlayerGui:WaitForChild("ServerBrowser");

--local ServerList = UI.Body.Servers.Pages.List;

--local GUI = {
--	ServerCanvas = UI.Body.Servers;
--	SideCanvas = UI.Body.Side;
--	Pages = UI.Body.Servers.Pages;
	
--	MyServer = UI.Body.Servers.Pages.MyServer;
--	MyServerSettings = UI.Body.Servers.Pages.MyServer.ServerBody.Settings.ScrollingFrame;
--	MyServerInfo = UI.Body.Servers.Pages.MyServer.ServerBody.Info.ScrollingFrame;
--	AdminServer = UI.Body.Servers.Pages.Admin.ScrollingFrame.Server;
--	AdminUser = UI.Body.Servers.Pages.Admin.ScrollingFrame.User;
--	Admin = UI.Body.Servers.Pages.Admin;
	
--	SideButtons = UI.Body.Side.Buttons;
--	CodeFrame = UI.Body.Side.Code;
--	ServerPages = ServerList.Scrolling;
--	PageControl = ServerList.Pages;
--	Filtering = ServerList.Control;
--	InfoFrame = ServerList.Info;
--};

-------------------------------------------------------------------------------------------------------

--local ServerBrowser = {};
--ServerBrowser.__index = ServerBrowser;

--function ServerBrowser.new()
--	local self = setmetatable(
--		{
--			UI = UI;
--			enabled = false;
--			is_admin = false;
			
--			server_list = {};
--			server_frames = {};
--			tweens = {};
			
--			number_of_servers = 0;
--			last_server_refresh = tick();
			
--			current_access_code = nil;
--		}, 
--		ServerBrowser);
	
--	self.confirmations = Confirmations.new(self);
	
--	self:initialise_tweens();
--	self:initialise();
	
--	return self;
--end;

-------------------------------------------------------------------------------------------------------

--local function set_user_name(frame, user_id)
--	frame.Body.Left.Creator.Creator.Text = Utility.get_user_identifer(user_id);
--end

--function ServerBrowser:update_server(item)
--	local frame: typeof(Assets.ServerFrame);

--	if self.server_frames[item.access_code] then
--		frame = self.server_frames[item.access_code];
--	else
--		frame = Assets.ServerFrame:Clone();
--		frame.Body.Left.Creator.Creator.Text = "---";
--		frame.Body.Right.AccessCode.Title.Text = item.access_code;
--		frame.UIStroke.Transparency = 0.6;
--		frame.Name = item.title;
		
--		task.spawn(set_user_name, frame, item.owner_id);
		
--		frame.MouseEnter:Connect(function()
--			TweenService:Create(frame.UIStroke, TweenInfo.new(0.25), {Transparency = 0}):Play()
--			TweenService:Create(frame.Main, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(128, 128, 128)}):Play()
--		end)
		
--		frame.MouseLeave:Connect(function()
--			TweenService:Create(frame.UIStroke, TweenInfo.new(0.25), {Transparency = frame.UIStroke:GetAttribute("TargetTransparency")}):Play()
--			TweenService:Create(frame.Main, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
--		end)
		
--		frame.Main.MouseButton1Click:Connect(function()
--			self:join_server(item.access_code);
--		end)
		
--		self.items_page:add_item(frame, item.access_code);
--		self.server_frames[item.access_code] = frame;
--	end;
	
--	local stroke_hover_transparency = 0.6;
		
--	if (item.access_code == self.current_access_code) then
--		stroke_hover_transparency = 0.4;
--		frame.UIStroke.Color = Color3.fromRGB(193, 255, 170);
		
--	elseif (item.owner_id == Player.UserId) then
--		stroke_hover_transparency = 0.4;
--		frame.UIStroke.Color = Color3.fromRGB(148, 177, 255);
--	end;
	
--	frame.UIStroke.Transparency = stroke_hover_transparency;
--	frame.UIStroke:SetAttribute("TargetTransparency", stroke_hover_transparency);
	
--	frame.Body.Left.Title.Text = item.title;
--	frame.Body.Right.PlayerCount.Title.Text = `{item.player_count}/{Players.MaxPlayers}`;
	
--	return frame;
--end

--function ServerBrowser:remove_server(access_code: string)
--	local frame = self.server_frames[access_code];
	
--	if frame then
--		frame:Destroy();
		
--		self.server_frames[access_code] = nil;
--		self.items_page:remove_item(frame);
--	end
--end

--function ServerBrowser:clear_servers(ignore_access_codes)
--	for access_code, frame in pairs(self.server_frames) do
--		if not ignore_access_codes[access_code] then
--			self:remove_server(access_code);
--		end;
--	end;
--end;

--function ServerBrowser:sort_servers(callback)
--	local servers = {};
	
--	local function sort(frame1, frame2)
--		local server_1 = self.server_list[self.items_page.items[frame1]];
--		local server_2 = self.server_list[self.items_page.items[frame2]];

--		servers[frame1] = server_1;
--		servers[frame2] = server_2;

--		return callback( server_1, server_2 )
--	end;
	
--	self.items_page:sort(sort);
--end

--local function get_server_priority_value(self, server): number
--	if (server.access_code == self.current_access_code) then
--		return 3;
--	elseif (server.owner_id == Player.UserId) then 
--		return 2;
--	else 
--		return 1;
--	end
--end;

--local function get_priority_sorted(self, server_1, server_2): (boolean, boolean)
--	local aPriority = get_server_priority_value(self, server_1)
--	local bPriority = get_server_priority_value(self, server_2)

--	if aPriority ~= bPriority then
--		return true, aPriority > bPriority;
--	else
--		return false, false;
--	end;
--end;

--function ServerBrowser:sort_servers_by_player_count(direction: Enum.SortDirection)
--	if (direction == Enum.SortDirection.Descending) then
--		self:sort_servers(function(item1, item2)
--			local use_priority, is_higher = get_priority_sorted(self, item1, item2);
			
--			if use_priority then
--				return is_higher;
--			else
--				return item1.player_count > item2.player_count;
--			end
--		end)
--	else
--		self:sort_servers(function(item1, item2)
--			local use_priority, is_higher = get_priority_sorted(self, item1, item2);

--			if use_priority then
--				return is_higher;
--			else
--				return item1.player_count < item2.player_count;
--			end
--		end)
--	end;
--end;

--function ServerBrowser:refresh_servers(list)
--	assert(list, "No Server List");
	
--	self:clear_servers(list);
	
--	for _, item in list do
--		self:update_server(item);
--	end;
	
--	GUI.InfoFrame.Display.Shown.Text = `{self.number_of_servers} Servers`;
	
--	self:start_refresh_timer();
--	self:sort_servers_by_player_count(Enum.SortDirection.Descending);
	
--	self.items_page:search(GUI.Filtering.Search.Text);
	
--	local last_page = self.items_page:get_max_pages();

--	for index, page in self.items_page.pages do
--		local end_of_list = page.ScrollingFrame.Eof;

--		if index >= last_page then
--			end_of_list.Title.Text = "You've reached the end.";
--		else
--			end_of_list.Title.Text = "Go to the next page!";
--		end;
--	end;
--end;

--function ServerBrowser:load_server(server)
--	self.selected_server = server;
	
--	if server then
--		local info = server or {};
--		local max_players = info.max_players or Players.MaxPlayers;
		
--		GUI.MyServerSettings.Rename.Box.Text = info.title or "";
--		GUI.MyServerSettings.AccessCode.Box.Text = info.access_code or "";
--		GUI.MyServerSettings.MaxPlayers.Box.Text = max_players;
--		GUI.MyServerInfo.Status.Title.Text = "Status: Active";
--		GUI.MyServerInfo.PlayerCount.Title.Text = `Players: {info.player_count or 0}/{max_players}`;
--		GUI.MyServerInfo.ServerTitle.Text = info.title or "No Title";
		
--		GUI.MyServer.CreateBody.Visible = false;
--		GUI.MyServer.ServerBody.Visible = true;
--	else
--		GUI.MyServer.CreateBody.Visible = true;
--		GUI.MyServer.ServerBody.Visible = false;
--	end
--end

--function ServerBrowser:load_enforcement_server(access_code: string)
--	if not access_code or access_code == "" then
--		GUI.AdminServer.Controls.Visible = false;
--	else
--		local server = Remotes.RequestServer:InvokeServer(access_code);
		
--		if server then
--			self.enforcement_server = server;
			
--			GUI.AdminServer.Controls.ServerName.Box.Text = server.title or "?";
--			GUI.AdminServer.Controls.PlayerCount.Box.Text = `{server.player_count or 0}`;
--			GUI.AdminServer.Controls.OwnerName.Box.Text = Utility.get_user_identifer(server.owner_id);
--			GUI.AdminServer.Controls.OwnerId.Box.Text = `{server.owner_id}`;
--			GUI.AdminServer.Controls.Visible = true;
			
--			SoundService:PlayLocalSound(Sounds.Found);
--		else
--			self:create_message(`No server exists with access code '{access_code}'`);
--		end
--	end;
--end;

--function ServerBrowser:load_enforcement_user(user_id: string): ()
--	if not user_id or user_id == "" then
--		GUI.AdminUser.Controls.Visible = false;
--	else
--		local status = Remotes.RequestUserStatus:InvokeServer(user_id);
		
--		if status then
--			self.enforcement_user = status.id;

--			GUI.AdminUser.Controls.Visible = true;
--			GUI.AdminUser.Controls.Ban.Visible = not status.is_banned;
--			GUI.AdminUser.Controls.Unban.Visible = status.is_banned;
			
--			SoundService:PlayLocalSound(Sounds.Found);
--		else
--			self:create_message(`No user exists with user id '{user_id}'`);
--		end
--	end;
--end

--function ServerBrowser:get_latest_server_from_list(list)
--	local latest_server;
--	local latest_time = -math.huge;
	
--	for _, server in list do
--		if server.time > latest_time then
--			latest_server = server;
--			latest_time = server.time;
--		end;
--	end;
	
--	return latest_server;
--end

--function ServerBrowser:load_my_servers()
--	self.loading_my_servers:set(true);
	
--	local success, list = pcall(Remotes.RequestMyServers.InvokeServer, Remotes.RequestMyServers);
	
--	if success and list then
--		local latest_server = self:get_latest_server_from_list(list);
		
--		self:load_server(latest_server);
--	end
	
--	if not success then
--		warn("Requesting servers was unsuccessful");
		
--	elseif not list then
--		warn("No list was returned");
--	end;
	
--	self.loading_my_servers:set(false);
--end

--function ServerBrowser:moderate_user(user_id: string, parameters: any): ()
--	Remotes.ModerateUser:FireServer(user_id, parameters);
--end

--function ServerBrowser:moderate_server(access_code: string): ()
--	Remotes.ModerateServer:FireServer(access_code);
--end

--function ServerBrowser:delete_server(access_code: string)
--	Remotes.DeleteServer:FireServer(access_code);
--end

--function ServerBrowser:join_server(access_code: string): ()
--	self:create_message("Teleporting to server, please wait.");
--	Remotes.JoinServer:FireServer(access_code);
--end;

--function ServerBrowser:rename_server(access_code: string, new_title: string): ()
--	self:edit_server_details(access_code, {
--		title = new_title;
--	});
--end;

--function ServerBrowser:edit_server_details(access_code: string, details: any): ()
--	self:create_message("Applying changes");
--	Remotes.EditServer:FireServer(access_code, details);
--end

--function ServerBrowser:toggle(value: boolean?)
--	if (value == nil) then
--		value = not self.enabled;
--	end;
	
--	if self.enabled ~= value then
--		self.enabled = value;
--		UI.Enabled = true;
		
--		self.confirmations:cancel();
		
--		if self.enabled then
--			Remotes.ViewerSubscribe:FireServer();
--			Stylus:tween_blur(18, "ServerBrowser");
--			SoundService:PlayLocalSound(Sounds.Open);
			
--			self.tweens.open();
			
--			task.delay(0.25, self.refresh_servers_async, self);
--		else
--			Remotes.ViewerUnsubscribe:FireServer();
--			Stylus:tween_blur(0, "ServerBrowser");
			
--			self.tweens.close();
--		end
--	end
--end

--function ServerBrowser:ghostify()
--	local info = TweenInfo.new(0.25);
	
--	TweenService:Create(UI.Body.UIScale, info, {Scale = 0.9}):Play()
	
--	for _, canvas in UI.Body:GetChildren() do
--		if canvas:IsA("CanvasGroup") and canvas.Name ~= "Confirm" then
--			TweenService:Create(canvas, info, {GroupTransparency = 0.9}):Play()
--		end
--	end
--end

--do
--	local function start_refresh_thread(self)
--		repeat
--			GUI.InfoFrame.Display.Refresh.Text = `Refreshed {math.floor(tick() - self.last_server_refresh)}s ago`;
--			task.wait(1);
--		until not self;
--	end;
	
--	function ServerBrowser:start_refresh_timer()
--		self.last_server_refresh = tick();

--		if self.server_refresh_thread then
--			if coroutine.status(self.server_refresh_thread) == "suspended" then
--				task.cancel(self.server_refresh_thread);
--			end;

--			self.server_refresh_thread = nil;
--		end;

--		self.server_refresh_thread = task.spawn(start_refresh_thread, self);
--	end
--end;

--function ServerBrowser:initialise_tweens()
--	local open_tweens = {};
--	local close_tweens = {};
	
--	local info = TweenInfo.new(0.2);
	
--	local scale_open = TweenService:Create(UI.Body.UIScale, info, {Scale = 1});
--	local scale_close = TweenService:Create(UI.Body.UIScale, info, {Scale = 0.6});
	
--	scale_close.Completed:Connect(function(status)
--		if (status == Enum.PlaybackState.Completed) then
--			UI.Enabled = false;
--		end
--	end)
	
--	table.insert(open_tweens, scale_open);
--	table.insert(close_tweens, scale_close);
	
--	for _, canvas in UI.Body:GetChildren() do
--		if canvas:IsA("CanvasGroup") then
--			table.insert(open_tweens, TweenService:Create(canvas, info, {GroupTransparency = 0}));
--			table.insert(close_tweens, TweenService:Create(canvas, info, {GroupTransparency = 1}));
--		end
--	end
	
--	function self.tweens.open()
--		for _, tween in open_tweens do
--			tween:Play();
--		end;
--	end
	
--	function self.tweens.close()
--		for _, tween in close_tweens do
--			tween:Play();
--		end;
--	end
--end

--function ServerBrowser:update_server_list(server_list)
--	table.clear(self.server_list);

--	self.number_of_servers = 0;

--	for key, item in server_list do
--		if not item.access_code then
--			continue;
--		end;
		
--		self.number_of_servers += 1;
--		self.server_list[item.access_code] = item;
--	end;

--	self:refresh_servers(self.server_list);
	
--	GUI.SideButtons.Refresh.Button.Button.Icon.ImageColor3 = Color3.fromRGB(255, 255, 255);
--end

--function ServerBrowser:refresh_servers_async()
--	self.loading_server_list:set(true);
	
--	local success, list = pcall(Remotes.RequestServerList.InvokeServer, Remotes.RequestServerList);

--	if success and list then
--		self:update_server_list(list);
--	end;
	
--	self.loading_server_list:set(false);
--end

--function ServerBrowser:create_message(message: string)
--	local frame = Assets.Message:Clone();
--	frame.Body.Title.Text = message;
--	frame.Visible = true;
--	frame.Parent = UI.Body.Bottom.Messages;

--	task.delay(6, function()
--		frame:Destroy();
--	end)

--	SoundService:PlayLocalSound(Sounds.Fail);
	
--	return frame;
--end

--local function create_control_box(info)
--	local button = Assets.ControlBox:Clone();
--	button.Title.Text = info.title;
--	button.Name = info.name or info.title;
--	button.Box.Text = info.text or "";
--	button.Box.PlaceholderText = info.placeholder_text or "Enter Here";
	
--	if info.read_only then
--		button.Box.TextEditable = false;
--	end;
	
--	button.Parent = info.parent;
	
--	return button;
--end

--local function create_side_button(info)
--	local button = Assets.SideButton:Clone();
--	button.Title.Text = info.title;
--	button.Name = info.title;
--	button.Button.Button.Icon.Image = info.image;
--	button.Button.Button.MouseButton1Click:Connect(info.callback);
--	button.Parent = info.parent or GUI.SideButtons;
	
--	return button;
--end

--local function create_control_button(info)
--	local button = Assets.ServerControl:Clone();
--	button.Name = info.title;
--	button.Button.Button.Title.Text = info.title;
--	button.Button.Button.Icon.Image = info.image;
--	button.Button.Button.MouseButton1Click:Connect(info.callback);
--	button.Button.Button.BackgroundColor3 = info.color or button.Button.Button.BackgroundColor3;
	
--	if info.icon_ratio then
--		button.Button.Button.Icon.UIAspectRatioConstraint.AspectRatio = info.icon_ratio;
--	end
	
--	if info.size then
--		button.Size = info.size;
--	end;
	
--	button.Parent = info.parent or GUI.MyServer.Controls;
	
--	return button;
--end

--function ServerBrowser:load_as_admin()
--	if self.is_admin then return end;

--	self.is_admin = true;

--	create_side_button({
--		title = "Admin";
--		image = "rbxassetid://560667850",
--		callback = function()
--			GUI.Pages.UIPageLayout:JumpTo(GUI.Admin);
--		end,
--	});

--	GUI.AdminServer.Access.Box.FocusLost:Connect(function(enter_pressed)
--		if enter_pressed then
--			self:load_enforcement_server(GUI.AdminServer.Access.Box.Text);
--		end;
--	end);
	
--	GUI.AdminUser.Access.Box.FocusLost:Connect(function(enter_pressed)
--		if enter_pressed then
--			self:load_enforcement_user(GUI.AdminUser.Access.Box.Text);
--		end
--	end)
	
--	create_control_box({
--		title = "Server Name";
--		name = "ServerName";
--		placeholder_text = `Server Title`;
--		read_only = true;
--		parent = GUI.AdminServer.Controls;
--	});
	
--	create_control_box({
--		title = "Player Count";
--		name = "PlayerCount";
--		placeholder_text = `Player Count`;
--		read_only = true;
--		parent = GUI.AdminServer.Controls;
--	});

--	create_control_box({
--		title = "Owner Name";
--		name = "OwnerName";
--		placeholder_text = `Player Name`;
--		read_only = true;
--		parent = GUI.AdminServer.Controls;
--	});

--	create_control_box({
--		title = "Owner Id";
--		name = "OwnerId";
--		placeholder_text = `User Id`;
--		read_only = true;
--		parent = GUI.AdminServer.Controls;
--	});
	
--	create_control_box({
--		title = "Duration (Days)";
--		name = "Duration";
--		placeholder_text = `-1 is permenant`;
--		read_only = false;
--		parent = GUI.AdminUser.Controls;
--	});
	
--	create_control_box({
--		title = "Reason";
--		name = "Reason";
--		placeholder_text = `Reason`;
--		read_only = false;
--		parent = GUI.AdminUser.Controls;
--	});
	
--	create_control_button({
--		title = "Join",
--		image = "rbxasset://textures/StudioToolbox/AssetConfig/menu_friends.png";
--		color = Color3.fromRGB(255, 255, 255);
--		parent = GUI.AdminServer.Controls;
--		callback = function()
--			if not self.enforcement_server then return end;

--			self.confirmations:make("Join", "Are you sure you want to join this server?", function(accepted)
--				if accepted then
--					self:join_server(self.enforcement_server.access_code);
--				end;
--			end);
--		end,
--	});
	
--	create_control_button({
--		title = "Delete",
--		image = "rbxasset://textures/ui/Keyboard/close_button_icon.png";
--		color = Color3.fromRGB(255, 57, 57);
--		icon_ratio = 1;
--		parent = GUI.AdminServer.Controls;
--		callback = function()
--			if not self.enforcement_server then return end;

--			self.confirmations:make("Warning!", "Are you sure you want to shutdown this server?", function(accepted)
--				if accepted then
--					self:moderate_server(self.enforcement_server.access_code);
--					self:create_message("Taken action against server");
--					self:load_enforcement_server(nil);
--				end;
--			end);
--		end,
--	});
	
--	create_control_button({
--		title = "Ban",
--		image = "rbxassetid://560667850";
--		color = Color3.fromRGB(255, 85, 79);
--		icon_ratio = 1;
--		parent = GUI.AdminUser.Controls;
--		callback = function()
--			if not self.enforcement_user then return end;

--			self.confirmations:make("Ban", "Are you sure you want to ban this user?", function(accepted)
--				if accepted then
--					local duration = tonumber(GUI.AdminUser.Controls.Duration.Box.Text);
					
--					if not duration then
--						return self:create_message("Duration is invalid :(")
--					end;
					
--					if duration ~= -1 then
--						duration = duration * 24 * 60 * 60;
--					end
					
--					self:moderate_user(self.enforcement_user, {
--						reason = GUI.AdminUser.Controls.Reason.Box.Text,
--						duration = duration,
--					});
--				end;
--			end);
--		end,
--	});
	
--	create_control_button({
--		title = "Unban",
--		image = "rbxassetid://560667850";
--		color = Color3.fromRGB(233, 255, 120);
--		icon_ratio = 1;
--		parent = GUI.AdminUser.Controls;
--		callback = function()
--			if not self.enforcement_user then return end;

--			self.confirmations:make("Unban", "Are you sure you want to unban this user?", function(accepted)
--				if accepted then
--					self:moderate_user(self.enforcement_user, {
--						unban = true;
--					});
--				end;
--			end);
--		end,
--	});
	
--	self:load_enforcement_server(nil);
--	self:load_enforcement_user(nil);
	
--	GUI.Admin.Visible = true;
--end

--function ServerBrowser:initialise()
	
--	self.loading_server_list = Loading.new( GUI.Pages.List.Scrolling );
--	self.loading_create = Loading.new( GUI.Pages.Create );
--	self.loading_my_servers = Loading.new( GUI.MyServer );
	
--	self.loading_server_list.changed:Connect(function(value)
--		GUI.ServerPages.Items.Visible = not value;
--	end)
	
--	local function open_browser(action_name, state, input)
--		if (state == Enum.UserInputState.Begin) then
--			self:toggle();
--		end
--	end;
	
--	ContextActionService:BindAction("OpenServerBrowser", open_browser, false, Enum.KeyCode.L);
	
--	create_side_button({
--		title = "Refresh";
--		image = "rbxassetid://4359854600",
--		callback = function()
--			if self.loading_server_list.is_loading then return end;
			
--			if GUI.Pages.UIPageLayout.CurrentPage ~= GUI.Pages.List then
--				self.loading_server_list:set(true);
--				GUI.Pages.UIPageLayout:JumpTo(GUI.Pages.List);
--				task.wait(0.3);
--				self.loading_server_list:set(false);
--			end;
			
--			self:refresh_servers_async();
--		end,
--	})

--	create_side_button({
--		title = "Create",
--		image = "http://www.roblox.com/asset/?id=401613236",
--		callback = function()
--			GUI.Pages.UIPageLayout:JumpTo(GUI.Pages.Create);
--		end,
--	})
	
--	create_side_button({
--		title = "My Server";
--		image = "rbxassetid://9692125126",
--		callback = function()
--			GUI.Pages.UIPageLayout:JumpTo(GUI.MyServer);
--		end,
--	});
	
--	create_control_button({
--		title = "Create Server",
--		image = "http://www.roblox.com/asset/?id=401613236",
--		parent = GUI.Pages.Create.Controls;
--		callback = function()
--			if self.loading_create.is_loading then return end;

--			self.loading_create:set(true);

--			local success, was_created, err = pcall(Remotes.CreateServer.InvokeServer, Remotes.CreateServer, {
--				title = GUI.Pages.Create.Rename.Box.Text;
--			});
			
--			if not success then
--				warn("Unable to create server:", was_created);
				
--			elseif not was_created then
--				if err then
--					warn("Unable to create server:", err);
--				else
--					warn("Unable to create server.");
--				end;
--			else
--				GUI.Pages.UIPageLayout:JumpTo(GUI.MyServer);
--				SoundService:PlayLocalSound(Sounds.Created);
--				task.spawn(self.refresh_servers_async, self);
--			end;

--			self.loading_create:set(false);
--		end,
--	})
	
--	create_control_button({
--		title = "Create One!",
--		image = "http://www.roblox.com/asset/?id=401613236";
--		parent = GUI.MyServer.CreateBody.Create;
--		callback = function()
--			GUI.Pages.UIPageLayout:JumpTo(GUI.Pages.Create);
--		end,
--	})
	
--	create_control_button({
--		title = "Apply",
--		image = "rbxasset://textures/AnimationEditor/icon_checkmark.png";
--		size = UDim2.fromScale(0.75, 0.11);
--		parent = GUI.MyServer.ServerBody.Controls;
--		callback = function()
--			if not self.selected_server then return end;

--			self.confirmations:make("Warning!", "Apply these changes?", function(accepted)
--				if accepted then
--					self:rename_server(self.selected_server.access_code, GUI.MyServerSettings.Rename.Box.Text);
--				end;
--			end);
--		end,
--	})
	
--	create_control_button({
--		title = "Join",
--		image = "rbxasset://textures/StudioToolbox/AssetConfig/menu_friends.png";
--		color = Color3.fromRGB(255, 255, 255);
--		size = UDim2.fromScale(0.75, 0.11);
--		parent = GUI.MyServer.ServerBody.Controls;
--		callback = function()
--			if not self.selected_server then return end;
			
--			self.confirmations:make("Join", "Are you sure you want to join this server?", function(accepted)
--				if accepted then
--					self:join_server(self.selected_server.access_code);
--				end;
--			end);
--		end,
--	});
	
--	create_control_button({
--		title = "Delete",
--		image = "rbxasset://textures/ui/Keyboard/close_button_icon.png";
--		color = Color3.fromRGB(255, 57, 57);
--		icon_ratio = 1;
--		size = UDim2.fromScale(0.75, 0.11);
--		parent = GUI.MyServer.ServerBody.Controls;
--		callback = function()
--			if not self.selected_server then return end;
			
--			self.confirmations:make("Warning!", "Are you sure you want to delete this server?", function(accepted)
--				if accepted then
--					self:delete_server(self.selected_server.access_code);
--					self:create_message("You have deleted your server");
--					task.wait(0.5);
--					self:load_my_servers();
--				end
--			end)
--		end,
--	})
	
--	local server_valid = Validation.custom_server_info;
--	local name_help_string =`Between {server_valid.title.min_length}-{server_valid.title.max_length} characters long.`
	
--	GUI.Pages.Create.Rename.Box.PlaceholderText = name_help_string;
	
--	create_control_box({
--		title = "Name";
--		name = "Rename";
--		placeholder_text = name_help_string;
--		parent = GUI.MyServerSettings;
--	})
	
--	create_control_box({
--		title = "Access Code";
--		name = "AccessCode";
--		placeholder_text = `Access Code`;
--		read_only = true;
--		parent = GUI.MyServerSettings;
--	})
	
--	create_control_box({
--		title = "Max Players";
--		name = "MaxPlayers";
--		placeholder_text = `Max Players`;
--		read_only = true;
--		parent = GUI.MyServerSettings;
--	})
	
--	self.items_page = PageList.new({
--		["per_page"] = 30;
--		["per_row"] = 1;
--		["layout"] = GUI.ServerPages.Items.UIPageLayout;
--		["page_max"] = GUI.PageControl.PageMax;
--		["page_current"] = GUI.PageControl.PageCurrent;
--		["next_button"] = GUI.PageControl.Next;
--		["previous_button"] = GUI.PageControl.Previous;
--		["page_preset"] = Assets.ServerPage;
--	})
	
--	self.items_page:get_new_page();
	
--	GUI.Filtering.Search:GetPropertyChangedSignal("Text"):Connect(function()
--		self.items_page:search(GUI.Filtering.Search.Text);
--	end)
	
--	local function update_current_access_code()
--		self.current_access_code = ServerStatus:GetAttribute("AccessCode");
--	end
	
--	update_current_access_code();
--	ServerStatus:GetAttributeChangedSignal("AccessCode"):Connect(update_current_access_code);
	
--	self:start_refresh_timer();
	
--	Remotes.Message.OnClientEvent:Connect(function(message: string)
--		self:create_message(message);
--	end)
	
--	Remotes.SetAdmin.OnClientEvent:Connect(function()
--		self:load_as_admin();
--	end)
	
--	Remotes.NotifyServerRefresh.OnClientEvent:Connect(function()
--		local time_now = tick();
		
--		if time_now - self.last_server_refresh > 1 then
--			GUI.SideButtons.Refresh.Button.Button.Icon.ImageColor3 = Color3.fromRGB(180, 210, 255);
--		end;
--	end)
	
--	GUI.ServerCanvas.Back.MouseButton1Click:Connect(function()
--		GUI.Pages.UIPageLayout:JumpTo(GUI.Pages.List);
--	end)
	
--	do
--		GUI.ServerCanvas.Back.MouseEnter:Connect(function()
--			GUI.ServerCanvas.Back.ImageColor3 = Color3.fromRGB(199, 220, 255)
--		end)
		
--		GUI.ServerCanvas.Back.MouseLeave:Connect(function()
--			GUI.ServerCanvas.Back.ImageColor3 = Color3.fromRGB(255, 255, 255)
--		end)
--	end
	
--	GUI.SideCanvas.Code.Search.FocusLost:Connect(function(enter_pressed)
--		if enter_pressed then
--			local access_code = GUI.SideCanvas.Code.Search.Text;
--			local server = Remotes.RequestServer:InvokeServer(access_code);
			
--			if server then
--				self.confirmations:make("Warning!", `You will be teleported to '{server.title}', are you sure?`, function(accepted)
--					if accepted then
--						self:join_server(access_code);
--					end
--				end)
--			else
--				self:create_message("Access code is invalid");
--			end
--		end
--	end)
	
--	GUI.Pages.UIPageLayout.PageEnter:Connect(function(page)
--		if (page == GUI.Pages.List) then
--			GUI.ServerCanvas.Back.Visible = false;
--		else
--			GUI.ServerCanvas.Back.Visible = true;
			
--			if (page == GUI.MyServer) then
--				self:load_my_servers();
--			end
--		end
--	end)
	
--	GUI.ServerCanvas.Back.Visible = false;
--	UI.Enabled = false;
--	UI.Body.UIScale.Scale = 0;
--end

--table.freeze(ServerBrowser);

--return ServerBrowser.new();