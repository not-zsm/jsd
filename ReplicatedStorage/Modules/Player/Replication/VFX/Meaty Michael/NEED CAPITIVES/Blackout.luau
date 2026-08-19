local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Player = Players.LocalPlayer;
local PlayerGui = Player:WaitForChild("PlayerGui") :: typeof(StarterGui);

local UI = PlayerGui:WaitForChild("Blackout");

local Blackout = {};
Blackout.__index = Blackout;

function Blackout.new()
	local self = setmetatable(
		{}, 
		Blackout);
	
	return self;
end;

function Blackout:display(uptime: number?)
	local blackout_frame = UI.Default:Clone();
	blackout_frame.Name = "Blackout";
	blackout_frame.Visible = true;
	blackout_frame.Black.Transparency = 1;
	blackout_frame.Vignette.ImageTransparency = 1;
	blackout_frame.Parent = UI;
	
	SoundService:PlayLocalSound(script.Breathe);
	
	local tween = TweenService:Create(blackout_frame.Vignette, TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		ImageTransparency = 0;
	})
	tween:Play();
	
	local tween = TweenService:Create(blackout_frame.Black, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		Transparency = 0;
	})
	tween:Play();
	
	task.delay(uptime or 1.25, function()
		local tween = TweenService:Create(blackout_frame.Vignette, TweenInfo.new(1.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
			ImageTransparency = 1;
		})
		tween:Play();

		local tween = TweenService:Create(blackout_frame.Black, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
			Transparency = 1;
		})
		tween:Play();

		task.wait(3)
		blackout_frame:Destroy();
	end)
end

table.freeze(Blackout);

return Blackout.new();