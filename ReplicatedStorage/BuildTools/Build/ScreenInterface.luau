local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local BuildShared = script.Parent.Parent;
local Assets = BuildShared.Assets;

local Player = Players.LocalPlayer;
local PlayerGui = Player:WaitForChild("PlayerGui");

local Asset = require( ReplicatedStorage.Packages.Asset )
local Stylus = require( ReplicatedStorage.Packages.Stylus )

local ScreenInterface = {};
ScreenInterface.__index = ScreenInterface;

function ScreenInterface.new(identifier: string)
	local interface = Assets.CustomScreen:Clone();
	interface.Name = `CustomInterface{identifier}`;
	
	local self = setmetatable(
		{
			interface = interface;
			aspect_ratio = interface.UIAspectRatioConstraint;
			modifiers = setmetatable({}, {__mode = "v"});
		}, 
		ScreenInterface);
	
	interface.Body.Button.MouseButton1Click:Connect(function()
		for _, modifier in self.modifiers do
			local event = modifier:FindFirstChild("Click");
			
			if event then
				event:FireServer();
			end;
		end
	end)
	
	return self;
end;

function ScreenInterface:update(data: {[string]: any}): ()
	local body = self.interface.Body;
	
	body.Interactable = data.Interactable;
	body.Button.Text = data.Text;
	body.Icon.Image = Asset.get_decal_id(data.Image);
	
	local normal_tween: Tween;
	
	if data.Tween then
		local tween_info = TweenInfo.new(data.EasingTime, data.EasingStyle, data.EasingDirection);
		local goal = {Position = data.ScreenPosition, Size = data.ScreenSize, GroupTransparency = data.Transparency};
		
		normal_tween = TweenService:Create(body, tween_info, goal);
		normal_tween:Play();
	else
		body.Position = data.ScreenPosition;
		body.Size = data.ScreenSize;
	end;
	
	if data.AspectRatio == 0 then
		self.aspect_ratio.Parent = self.interface;
	else
		self.aspect_ratio.AspectRatio = data.AspectRatio;
		self.aspect_ratio.Parent = body;
	end;
	
	self.interface.DisplayOrder = 120 + data.ZIndex;
	
	if data.Remove then
		if normal_tween then
			normal_tween.Completed:Once(function(status)
				if status == Enum.PlaybackState.Completed then
					self.interface.Parent = nil;
				end
			end)
		else
			self.interface.Parent = nil;
		end
	else
		self.interface.Parent = PlayerGui;
	end;
end;

function ScreenInterface:destroy(): ()
	self.interface:Destroy();
end

table.freeze(ScreenInterface);

return ScreenInterface;