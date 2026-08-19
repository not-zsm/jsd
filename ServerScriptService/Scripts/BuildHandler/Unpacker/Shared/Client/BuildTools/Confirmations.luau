local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Maid = require( ReplicatedStorage.Packages.Maid )
local Stylus = require( ReplicatedStorage.Packages.Stylus )
local Signal = require( ReplicatedStorage.Packages.Signal )

local ConfirmationUI = {}
ConfirmationUI.__index = ConfirmationUI;

function ConfirmationUI.new(build_tools)
	local self = setmetatable(
		{
			build_tools = build_tools;
			
			confirm_ui = build_tools.ui.Confirm;
			confirm = build_tools.ui.Confirm.Body;
			
			active_queue = {};
			active_thread = nil;
			active_maid = Maid.new();
			
			tweens = {};
		}, 
		ConfirmationUI);
	
	do
		local info = TweenInfo.new(0.15);
		local open_info = {GroupTransparency = 0, AnchorPoint = Vector2.new(0.5, 0.5)};
		local close_info = {GroupTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.25)};
		
		self.tweens.open = TweenService:Create(self.confirm, info, open_info);
		self.tweens.close = TweenService:Create(self.confirm, info, close_info);

		self.tweens.close:Play();

		self.tweens.close.Completed:Connect(function(status)
			if (status == Enum.PlaybackState.Completed) then
				self.confirm_ui.Enabled = false;
				self.confirm.Position = UDim2.fromScale(0.5, 0.5);
			end;
		end)
	end
	
	Stylus.bind_to_resize(self.confirm_ui, function(size)
		self.confirm.Body.Title.TextSize = 12 + size.x * 0.0035;
		self.confirm.Body.Description.TextSize = 10 + size.x * 0.0035;
	end)
	
	return self;
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
	if self.active_thread then
		self.active_thread = nil;
	end;
	
	self.active_maid:clean();
	
	self.tweens.close:Play();
	Stylus:tween_blur(0, "Confirm");
end

function ConfirmationUI:destroy()
	self:cancel();
	table.clear(self.tweens)
	table.clear(self);
end

local function make_confirmation(self, title: string, description: string, callback: (accepted: boolean) -> (), sound: Sound): ()
	if self.active_thread then return end;
	
	local thread = coroutine.running();

	self:cancel();
	self.active_thread = thread;

	self.tweens.open:Play();

	SoundService:PlayLocalSound(sound)
	Stylus:tween_blur(15, "Confirm");
	
	self.confirm.Body.Title.Text = title;
	self.confirm.Body.Description.Text = description;
	self.confirm_ui.Enabled = true;
	
	self.active_maid:add(self.confirm.Body.Buttons.Confirm.MouseButton1Click:Connect(function()
		self:cancel();
		self:pop_next();
		callback(true);
	end))

	self.active_maid:add(self.confirm.Body.Buttons.Deny.MouseButton1Click:Connect(function()
		self:cancel();
		self:pop_next();
		callback(false);
	end))
end

function ConfirmationUI:make_danger(title, description, callback)
	return make_confirmation(self, title, description, callback, self.build_tools.sounds.Danger);
end

function ConfirmationUI:make(title: string, description: string, callback: (accepted: boolean) -> ()): ()
	return make_confirmation(self, title, description, callback, self.build_tools.sounds.Confirm);
end

table.freeze(ConfirmationUI);

return ConfirmationUI;