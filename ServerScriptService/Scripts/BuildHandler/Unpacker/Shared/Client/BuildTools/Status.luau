local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local BuildPersistent = ReplicatedStorage:WaitForChild("BuildTools");
local BuildShared = BuildPersistent:WaitForChild("Shared");
local Remotes = BuildPersistent:WaitForChild("Remotes");
local BuildAssets = BuildShared:WaitForChild("Assets");

local NotificationStatus = require( BuildShared.Data.NotificationStatus )

local BuildTools = script.Parent;
local Assets = BuildTools:WaitForChild("Assets");
local Sounds = BuildTools:WaitForChild("Sounds");

local SHOW_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out);
local HIDE_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out);

local SHOW_GOAL = {GroupTransparency = 0, Position = UDim2.fromScale(0, 0)}
local HIDE_GOAL = {GroupTransparency = 1, Position = UDim2.fromScale(0, 1)}

local StatusUI = {}
StatusUI.__index = StatusUI;

function StatusUI.new(build_tools)
	local self = setmetatable(
		{
			build_tools = build_tools;
			list = build_tools.elements.Status.List;
		}, 
		StatusUI);

	return self;
end

function StatusUI:create_new(text: string, text_color: Color3, image: string)
	local button = self.build_tools.assets.StatusFrame:Clone();
	button.Visible = true;
	button.Canvas.Title.TextColor3 = text_color
	button.Canvas.Title.Text = text;
	button.Canvas.Icon.Image = image;

	for property, value in HIDE_GOAL do
		button.Canvas[property] = value;
	end

	return button;
end

function StatusUI:create_warning(text: string)
	local button = self:create_new(text, Color3.fromRGB(255, 218, 34), "rbxassetid://85147473315465")
	button.Name = "Warning";
	button.Parent = self.list;

	return button;
end

function StatusUI:create_error(text: string)
	local button = self:create_new(text, Color3.fromRGB(255, 46, 46), "rbxassetid://104008649959269")
	button.Name = "Error";
	button.Parent = self.list;

	return button;
end

function StatusUI:create_info(text: string)
	local button = self:create_new(text, Color3.fromRGB(156, 215, 255), "rbxassetid://11951542684");
	button.Name = "Info";
	button.Visible = false;
	button.Parent = self.list;

	return button;
end

function StatusUI:create_success(text: string)
	local button = self:create_new(text, Color3.fromRGB(130, 255, 102), "rbxassetid://11801504719")
	button.Name = "Success";
	button.Visible = false;
	button.Parent = self.list;

	return button;
end;

function StatusUI:create_from_status(status: number, text: string)
	local frame;

	if (status == NotificationStatus.error) then
		frame = self:create_error(text);

	elseif (status == NotificationStatus.warning) then
		frame = self:create_warning(text);

	elseif (status == NotificationStatus.info) then
		frame = self:create_info(text);

	elseif (status == NotificationStatus.success) then
		frame = self:create_success(text);
	end;

	return frame;
end

function StatusUI:play_sound(button, status: number)
	if (status == NotificationStatus.error) then
		SoundService:PlayLocalSound(Sounds.Error);

	elseif (status == NotificationStatus.warning) then
		SoundService:PlayLocalSound(Sounds.Warning);

	elseif (status == NotificationStatus.success) then
		SoundService:PlayLocalSound(Sounds.Success);

	elseif (status == NotificationStatus.info) then
		SoundService:PlayLocalSound(Sounds.Info);
	end;
end

function StatusUI:play(button, status: number, duration: number): ()
	StatusUI:play_sound(button, status);
	StatusUI:animate_show(button);

	task.delay(duration, function()
		if not button.Parent then return end;

		local tween = StatusUI:animate_hide(button);
		local status = tween.Completed:Wait();

		button:Destroy();
	end)
end

function StatusUI:animate_show(button)
	button.Visible = true;

	local tween = TweenService:Create(button.Canvas, SHOW_INFO, SHOW_GOAL)
	tween:Play();

	return tween;
end;

function StatusUI:animate_hide(button)
	local tween = TweenService:Create(button.Canvas, HIDE_INFO, HIDE_GOAL)
	tween:Play();
	tween.Completed:Once(function(status)
		if (status == Enum.PlaybackState.Completed) then
			button.Visible = false;
		end;
	end);

	return tween;
end

return StatusUI;