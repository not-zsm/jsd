local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

-------------------------------------------------------------------------------

local Player = Players.LocalPlayer;

-------------------------------------------------------------------------------

local Maid = require( ReplicatedStorage.Packages.Maid )

-------------------------------------------------------------------------------

local function observe_attribute(instance: Instance, attribute: string, callback)
	task.spawn(callback, instance:GetAttribute(attribute));

	return instance:GetAttributeChangedSignal(attribute):Connect(function()
		callback( instance:GetAttribute(attribute) );
	end);
end;

-------------------------------------------------------------------------------

local Message = {};
Message.__index = Message;
Message.queue = {};
Message.current_active = nil;
Message.tween_info = TweenInfo.new(0.5);
Message.blur_size = 18;

-------------------------------------------------------------------------------

function Message.show_next()
	Message.current_active = nil;
	
	local thread = Message.queue[1];
	
	if thread then
		table.remove(Message.queue, 1);
		task.spawn(thread);
	end;
end;

function Message.queue_yield(): ()
	if not Message.current_active then return end;
	
	table.insert(Message.queue, coroutine.running());
	coroutine.yield();
end;

-------------------------------------------------------------------------------

function Message.new(messager: Configuration, asset_gui: any)
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			maid = maid;
			asset_gui = asset_gui;
			messager = messager;
			gui = asset_gui:Clone();
			blur = Instance.new("BlurEffect");
		}, 
		Message);
	
	if Message.current_active then
		Message.current_active:destroy();
	end;
	
	Message.current_active = self;
	
	self:initialise();
	
	return self;
end;

-------------------------------------------------------------------------------

function Message:initialise()
	self.gui.Body.Interactable = false;
	self.gui.Ignore.Interactable = false;
	self.gui.Body.BackgroundTransparency = 1;
	self.gui.Ignore.BackgroundTransparency = 1;
	self.gui.Ignore.UIStroke.Transparency = 1;
	self.gui.Highlight.ImageTransparency = 1;
	self.gui.Ignore.TextTransparency = 1;
	
	for _, label in self.gui.Body:GetChildren() do
		if label:IsA("TextLabel") then
			label.TextTransparency = 1;
		end;
	end;
	
	self.blur.Size = Message.blur_size;
	
	self.maid:add(observe_attribute(self.messager, "Title", function(value)
		self.gui.Body.Title.Text = value or "";
	end));

	self.maid:add(observe_attribute(self.messager, "SubTitle", function(value)
		self.gui.Body.SubTitle.Text = value or "";
	end));
	
	self.blur.Parent = Lighting;
	self.gui.DisplayOrder = self.messager:GetAttribute("DisplayOrder") or 0;
	self.gui.Parent = Player:FindFirstChild("PlayerGui");
	
	self:toggle_body(true);
	
	if self.messager:GetAttribute("CanClose") then
		self.gui.Ignore.MouseButton1Click:Once(function()
			self:hide_close_button();
			self:toggle_body(false);

			Message.show_next();
		end);
		
		self.maid:add(task.delay(1, self.show_close_button, self));
	end;
end;


function Message:show_close_button(): ()
	self.gui.Ignore.Interactable = true;
	
	local tween = TweenService:Create(self.gui.Ignore.UIStroke, self.tween_info, {
		Transparency = 0.9;
	})
	tween:Play();
	
	local tween = TweenService:Create(self.gui.Ignore, self.tween_info, {
		BackgroundTransparency = 0.8;
		TextTransparency = 0;
	})
	tween:Play();
end;


function Message:hide_close_button(): ()
	self.gui.Ignore.Interactable = false;

	local tween = TweenService:Create(self.gui.Ignore.UIStroke, self.tween_info, {
		Transparency = 1;
	})
	tween:Play();
	
	local tween = TweenService:Create(self.gui.Ignore, self.tween_info, {
		BackgroundTransparency = 1;
		TextTransparency = 1;
	})
	tween:Play();
end;


function Message:toggle_body(value: boolean): ()
	local label_goal = { TextTransparency = if value then 0 else 1 };

	for _, label in self.gui.Body:GetChildren() do
		if label:IsA("TextLabel") then
			TweenService:Create(label, self.tween_info, label_goal):Play();
		end;
	end;

	local tween = TweenService:Create(self.gui.Highlight, TweenInfo.new(1.25), {
		ImageTransparency = if value then self.asset_gui.Highlight.ImageTransparency else 1;
	})
	tween:Play();
	
	local blur_tween = TweenService:Create(self.blur, self.tween_info, {Size = if value then Message.blur_size else 0})
	blur_tween:Play();

	local tween = TweenService:Create(self.gui.Body, self.tween_info, {
		BackgroundTransparency = if value then self.asset_gui.Body.BackgroundTransparency else 1;
	})
	tween:Play();
end;


function Message:destroy(): ()
	self.maid:destroy();
	
	self:hide_close_button();
	self:toggle_body(false);
	
	task.delay(self.tween_info.Time + 2, function()
		self.blur:Destroy();
		self.gui:Destroy();
	end)
	
	if Message.current_active == self then
		Message.show_next();
	end;
end;

-------------------------------------------------------------------------------

return Message;