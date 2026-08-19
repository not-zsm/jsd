local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Player = Players.LocalPlayer;
local PlayerGui = Player:WaitForChild("PlayerGui") :: typeof(StarterGui);

local UI = PlayerGui:WaitForChild("Region");

local RegionUI = {};
RegionUI.__index = RegionUI;

function RegionUI.new()
	local self = setmetatable(
		{
			region_thread = nil;
		}, 
		RegionUI);
	
	return self;
end;

function RegionUI:tween_gradient(gradient: UIGradient, info: TweenInfo, goal)
	local title_value = Instance.new("NumberValue");
	
	if goal then
		title_value.Value = goal[1];
	end;
	
	title_value.Changed:Connect(function(value)
		gradient.Transparency = NumberSequence.new(1 - title_value.Value)
	end)

	local tween = TweenService:Create(title_value, info, {Value = if goal then goal[2] else 1});
	tween:Play();
	tween.Completed:Once(function()
		title_value:Destroy();
	end)
end

function RegionUI:dethread()
	if self.region_thread and coroutine.status(self.region_thread) == "suspended" then
		task.cancel(self.region_thread);
		self.region_thread = nil;
	end
end

function RegionUI:set(title: string, subtitle: string, duration: number?)
	self:dethread();
	
	UI.Body.Visible = true;
	UI.Body.Title.Text = title;
	UI.Body.SubTitle.Text = subtitle;
	
	UI.Body.Underline.Size = UDim2.new(0, 0, 0, 1);
	UI.Body.Underline.Left.ImageTransparency = 0;
	UI.Body.Underline.Right.ImageTransparency = 0;
	
	local text_info = TweenInfo.new(2.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut);
	local underline_info = TweenInfo.new(2, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut);
	
	self:tween_gradient(UI.Body.Title.UIGradient, text_info);
	self:tween_gradient(UI.Body.SubTitle.UIGradient, text_info)
	
	local tween = TweenService:Create(UI.Body.Underline.Left, underline_info, {
		ImageTransparency = 0;
	});
	tween:Play();
	local tween = TweenService:Create(UI.Body.Underline.Right, underline_info, {
		ImageTransparency = 0;
	});
	tween:Play();
	
	local tween = TweenService:Create(UI.Body.Underline, underline_info, {
		Size = UDim2.new(1, 0, 0, 1);
	});
	tween:Play();
	
	if duration then
		self.region_thread = task.delay(duration, function()
			if UI.Body.Title.Text == title then
				self:hide()
			end
		end)
	end
end

function RegionUI:hide()
	local text_info = TweenInfo.new(2.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut);
	local underline_info = TweenInfo.new(2, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut);
	
	self:tween_gradient(UI.Body.Title.UIGradient, text_info, {1, 0})
	self:tween_gradient(UI.Body.SubTitle.UIGradient, text_info, {1, 0})
	
	local tween = TweenService:Create(UI.Body.Underline.Left, underline_info, {
		ImageTransparency = 1;
	});
	tween:Play();
	local tween = TweenService:Create(UI.Body.Underline.Right, underline_info, {
		ImageTransparency = 1;
	});
	tween:Play();
	
	local tween = TweenService:Create(UI.Body.Underline, underline_info, {
		Size = UDim2.new(0, 0, 0, 1);
	});
	tween:Play();
end

table.freeze(RegionUI);

return RegionUI.new();