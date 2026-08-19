local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer;
local BuildPersistent = ReplicatedStorage:WaitForChild("BuildTools");
local BuildShared = BuildPersistent:WaitForChild("Shared");
local Remotes = BuildPersistent:WaitForChild("Remotes");
local BuildAssets = BuildShared:WaitForChild("Assets");
local InstancesBuild = BuildAssets:WaitForChild("Build");

local NotificationStatus = require( BuildShared.Data.NotificationStatus )

local Maid = require( ReplicatedStorage.Packages.Maid )
local Table = require( ReplicatedStorage.Packages.Table )
local Stylus = require( ReplicatedStorage.Packages.Stylus )
local Signal = require( ReplicatedStorage.Packages.Signal )

local HelperWidget = {};
HelperWidget.__index = HelperWidget;

function HelperWidget.new(build_tools)
	local maid = build_tools.maid:limb();
	local widget = build_tools.assets.HelperWidget:Clone();

	local self = setmetatable(
		{
			frame = widget;
			title = widget.Widget.Body.Title;
			body = widget.Widget.Body.Body;
			main = widget.Widget.Body.Body.Body;
			done_button = widget.Widget.Body.Body.Accept.Button;
			exit_button = widget.Widget.Body.Title.Close;
			
			maid = maid;
			build_tools = build_tools;
			
			enabled = false;

			opened = maid:add(Signal.new()),
			closed = maid:add(Signal.new()),
			toggled = maid:add(Signal.new()),
			finished = maid:add(Signal.new()),
			active_maid = maid:limb();
			
			tweens = {};
		}, 
		HelperWidget);
	
	self:initialise_tweens();
	self:initialise();

	return self;
end;

function HelperWidget:destroy()
	table.clear(self.tweens);
	
	Table.dispose(self);
end;

function HelperWidget:set_done_visible(value: boolean)
	self.body.Accept.Visible = value;
end;

function HelperWidget:set_description(text: string)
	self.main.TitleFrame.Title.Text = text;
	self.main.TitleFrame.Visible = true;
end

function HelperWidget:initialise()
	self.done_button.MouseButton1Click:Connect(function()
		self:finish(true);
	end);
	
	self.exit_button.MouseButton1Click:Connect(function()
		self:finish(false);
	end);
end;

function HelperWidget:finish(value: boolean)
	if self.awaiting_finish then
		self.awaiting_finish = false;
		self.finished:Fire(value);
		
		self:toggle(false);
	end;
end;

function HelperWidget:initialise_tweens()
	self.tweens.open = TweenService:Create(self.frame.Widget, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {GroupTransparency = 0, AnchorPoint = Vector2.new(0.5, 0.5)});
	self.tweens.close = TweenService:Create(self.frame.Widget, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {GroupTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.4)});
	
	self.tweens.close:Play();
	
	self.tweens.close.Completed:Connect(function(status)
		if (status == Enum.PlaybackState.Completed) then
			self.frame.Visible = false;
			self.frame.Interactable = false;
		end;
	end)
end;

function HelperWidget:hide()
	self:toggle(false);
end

function HelperWidget:show()
	self:toggle(true);
end

function HelperWidget:toggle(value: boolean?)
	if value == nil then
		value = not self.enabled
	end;

	if self.enabled ~= value then
		self.enabled = value;
		self.active_maid:clean();
		
		if value then
			SoundService:PlayLocalSound(self.build_tools.sounds.Flash);
			
			self.frame.Visible = true;
			self.frame.Interactable = true;
			self.awaiting_finish = true;
			
			self.tweens.open:Play();
			self.opened:Fire();
		else
			self.tweens.close:Play();
			self.closed:Fire();
		end;
		
		self.toggled:Fire(value);
	end;
end;

table.freeze(HelperWidget);

return HelperWidget;