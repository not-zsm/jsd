local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Maid = require( ReplicatedStorage.Packages.Maid )
local Stylus = require( ReplicatedStorage.Packages.Stylus )

local Sounds = script.Parent.Sounds;

local ConfirmationUI = {}
ConfirmationUI.__index = ConfirmationUI;

function ConfirmationUI.new(ServerBrowser)
	local self = setmetatable(
		{
			server_browser = ServerBrowser;
			confirm = ServerBrowser.UI.Confirm;

			active_queue = {};
			active_thread = nil;
			active_maid = Maid.new();

			tweens = {};
		}, 
		ConfirmationUI);

	do
		local function update_text_size()
			self.confirm.Body.Description.TextSize = 6 + self.confirm.AbsoluteSize.X * 0.05;
		end

		update_text_size();
		self.confirm:GetPropertyChangedSignal("AbsoluteSize"):Connect(update_text_size)
	end

	self.yes_button = self.confirm.Body.Control.Yes.Button.Button;
	self.no_button = self.confirm.Body.Control.No.Button.Button;

	self:initialise_tweens();

	return self;
end

function ConfirmationUI:initialise_tweens()
	local open_tweens = {};
	local close_tweens = {};

	local info = TweenInfo.new(0.3);
	local open_tween = TweenService:Create(self.confirm, info, {GroupTransparency = 0});
	local close_tween = TweenService:Create(self.confirm, info, {GroupTransparency = 1});

	close_tween.Completed:Connect(function(status)
		if (status == Enum.PlaybackState.Completed) then
			self.confirm.Visible = false;
			self.server_browser.gui.ListScrollItems.Parent = self.server_browser.gui.ListScrollFrame;
		end
	end)

	table.insert(open_tweens, open_tween);
	table.insert(close_tweens, close_tween);

	function self.tweens.open()
		self.server_browser.gui.ListScrollItems.Parent = nil;

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

function ConfirmationUI:pop_next()
	if not next(self.active_queue) then
		return;
	end

	local thread = table.remove(self.active_queue, 1);

	if thread and coroutine.status(thread) == "suspended" then
		coroutine.resume(thread);
	end
end

function ConfirmationUI:cancel()
	self.active_thread = nil;
	self.active_maid:clean();

	self.tweens.close();
	self.server_browser.tweens.open();
	Stylus:tween_blur(0, "Confirm");
end

local function make_confirmation(self, title: string, description: string, callback: (accepted: boolean) -> (), sound: Sound): ()
	if self.active_thread or not self.server_browser.enabled then return end;

	local thread = coroutine.running();

	self:cancel();
	self.active_thread = thread;

	self.tweens.open();

	SoundService:PlayLocalSound(sound)
	Stylus:tween_blur(25, "Confirm");

	self.confirm.Body.Title.Text = title;
	self.confirm.Body.Description.Text = description;
	self.confirm.Visible = true;

	self.server_browser:ghostify();

	self.active_maid:add(self.yes_button.MouseButton1Click:Connect(function()
		self:cancel();
		self:pop_next();
		callback(true);
	end))

	self.active_maid:add(self.no_button.MouseButton1Click:Connect(function()
		self:cancel();
		self:pop_next();
		callback(false);
	end))
end

function ConfirmationUI:make_danger(title, description, callback)
	return make_confirmation(self, title, description, callback, Sounds.Danger);
end

function ConfirmationUI:make(title: string, description: string, callback: (accepted: boolean) -> ()): ()
	return make_confirmation(self, title, description, callback, Sounds.Confirm);
end

table.freeze(ConfirmationUI);

return ConfirmationUI;

--local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local TweenService = game:GetService("TweenService")
--local SoundService = game:GetService("SoundService")

--local Maid = require( ReplicatedStorage.Packages.Maid )
--local Stylus = require( ReplicatedStorage.Packages.Stylus )

--local Sounds = script.Parent.Sounds;

--local ConfirmationUI = {}
--ConfirmationUI.__index = ConfirmationUI;

--function ConfirmationUI.new(ServerBrowser)
--	local self = setmetatable(
--		{
--			server_browser = ServerBrowser;
--			confirm = ServerBrowser.UI.Confirm;
			
--			active_queue = {};
--			active_thread = nil;
--			active_maid = Maid.new();
			
--			tweens = {};
--		}, 
--		ConfirmationUI);
	
--	do
--		local function update_text_size()
--			self.confirm.Body.Description.TextSize = 6 + self.confirm.AbsoluteSize.X * 0.05;
--		end
		
--		update_text_size();
--		self.confirm:GetPropertyChangedSignal("AbsoluteSize"):Connect(update_text_size)
--	end
	
--	self.yes_button = self.confirm.Body.Control.Yes.Button.Button;
--	self.no_button = self.confirm.Body.Control.No.Button.Button;
	
--	self:initialise_tweens();
	
--	return self;
--end

--function ConfirmationUI:initialise_tweens()
--	local open_tweens = {};
--	local close_tweens = {};

--	local info = TweenInfo.new(0.3);
--	local open_tween = TweenService:Create(self.confirm, info, {GroupTransparency = 0});
--	local close_tween = TweenService:Create(self.confirm, info, {GroupTransparency = 1});
	
--	close_tween.Completed:Connect(function(status)
--		if (status == Enum.PlaybackState.Completed) then
--			self.confirm.Visible = false;
--		end
--	end)
	
--	table.insert(open_tweens, open_tween);
--	table.insert(close_tweens, close_tween);
	
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

--function ConfirmationUI:pop_next()
--	if not next(self.active_queue) then
--		return;
--	end
	
--	local thread = table.remove(self.active_queue, 1);
	
--	if thread and coroutine.status(thread) == "suspended" then
--		coroutine.resume(thread);
--	end
--end

--function ConfirmationUI:cancel()
--	self.active_thread = nil;
--	self.active_maid:clean();
	
--	self.tweens.close();
--	self.server_browser.tweens.open();
--	Stylus:tween_blur(0, "Confirm");
--end

--local function make_confirmation(self, title: string, description: string, callback: (accepted: boolean) -> (), sound: Sound): ()
--	if self.active_thread or not self.server_browser.enabled then return end;
	
--	local thread = coroutine.running();

--	self:cancel();
--	self.active_thread = thread;

--	self.tweens.open();

--	SoundService:PlayLocalSound(sound)
--	Stylus:tween_blur(25, "Confirm");
	
--	self.confirm.Body.Title.Text = title;
--	self.confirm.Body.Description.Text = description;
--	self.confirm.Visible = true;
	
--	self.server_browser:ghostify();
	
--	self.active_maid:add(self.yes_button.MouseButton1Click:Connect(function()
--		self:cancel();
--		self:pop_next();
--		callback(true);
--	end))

--	self.active_maid:add(self.no_button.MouseButton1Click:Connect(function()
--		self:cancel();
--		self:pop_next();
--		callback(false);
--	end))
--end

--function ConfirmationUI:make_danger(title, description, callback)
--	return make_confirmation(self, title, description, callback, Sounds.Danger);
--end

--function ConfirmationUI:make(title: string, description: string, callback: (accepted: boolean) -> ()): ()
--	return make_confirmation(self, title, description, callback, Sounds.Confirm);
--end

--table.freeze(ConfirmationUI);

--return ConfirmationUI;