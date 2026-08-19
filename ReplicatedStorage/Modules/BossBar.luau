local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Observer = require( ReplicatedStorage.Packages.Observer )
local Maid = require( ReplicatedStorage.Packages.Maid )
local Spring = require( ReplicatedStorage.Packages.Spring )

local Player = Players.LocalPlayer;
local PlayerGui = Player:WaitForChild("PlayerGui") :: typeof(StarterGui)

local UI = PlayerGui:WaitForChild("BossBars", 100);
local Assets = UI:WaitForChild("Assets");

local BossBar = {};
BossBar.__index = BossBar;

function BossBar.new(instance: Instance)
	local boss_template = Assets.Boss
	local bar_type = instance:GetAttribute("BarType");
	
	if bar_type == "Invincible" then
		boss_template = Assets.InvincibleBoss;
		
	elseif bar_type == "Meaty Michael" then
		boss_template = Assets.MeatyMichaelBoss;
	end
	
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			maid = maid;
			
			instance = instance;
			humanoid = instance.Parent :: Humanoid;
			rig = instance.Parent.Parent :: Model;

			visible_maid = maid:limb();
			bar = maid:add(boss_template:Clone());
			bar_tween_info = TweenInfo.new(0.25);
			theme_tween_info = TweenInfo.new(0.3);
			spring = Spring.new(Vector2.zero);
			bounce = 0;
			is_visible = false;
			pos_target = Vector2.zero;
		}, 
		BossBar);

	self.bar.Visible = false;
	self.bar.GroupTransparency = 1;
	self.bar.Parent = UI.List;

	self.spring.speed = 25
	self.spring.damping = 0.4;

	self.tweens = {
		[true] = {
			TweenService:Create(self.bar, TweenInfo.new(0.5), {GroupTransparency = 0})
		};
		[false] = {
			TweenService:Create(self.bar, TweenInfo.new(0.5), {GroupTransparency = 1})
		};
	};

	self.last_health = self.humanoid.Health;

	self.maid:add(self.humanoid.HealthChanged:Connect(function(health)
		self:update_progress();
	end))

	self.maid:add(task.spawn(function()
		while task.wait(0.5) do
			self:update_nearest()
		end
	end))
	
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		self:update_bounds();
	end);
	
	self:update_bounds();
	
	self:refresh();

	return self;
end;

function BossBar:update_bounds()
	local size = workspace.CurrentCamera.ViewportSize;
	local ui_scale = UI.List.UIScale;
	
	local above_720p = size.X >= 1280 and size.Y >= 720;
	
	if not above_720p then
		local new_scale = math.lerp(size.Magnitude / 1280, 1, 0.25);
		
		UI.List.Position = UDim2.fromScale(0.5, -0.02);
		ui_scale.Scale = new_scale;
	else
		UI.List.Position = UDim2.fromScale(0.5, 0.04);
		ui_scale.Scale = 1;
	end;
end

function BossBar:get_title()
	local info = self.instance:GetAttributes();
	
	return (info.Title or self.humanoid.DisplayName)
end

function BossBar:refresh()
	self.bar.Body.Title.Text = self:get_title();
	self:update_progress();
	self:update_nearest();
end

function BossBar:play_theme()
	if (self.theme == nil) then
		local theme = self.instance:FindFirstChild("Theme")
		
		if theme then
			self.theme = theme:Clone();
			self.theme:SetAttribute("original_volume", theme.Volume)
			self.theme.Name = self:get_title() .. "'s Theme";
			self.theme.Volume = 0;
			self.theme.Parent = workspace;
			self.theme:Play();

			self.maid:add(self.theme);
			
			TweenService:Create(self.theme, self.theme_tween_info, {
				Volume = self.theme:GetAttribute("original_volume")
			}):Play()
		end
	else
		self.theme.Volume = 0;
		
		TweenService:Create(self.theme, self.theme_tween_info, {
			Volume = self.theme:GetAttribute("original_volume")
		}):Play()
		
		self.theme:Resume()
	end
end

function BossBar:pause_theme()
	if self.theme then
		local tween_volume = TweenService:Create(self.theme, self.theme_tween_info, {
			Volume = 0
		})
		tween_volume:Play();

		tween_volume.Completed:Once(function()
			self.theme:Pause()
		end)
	end
end

function BossBar:show()
	self.is_visible = true;
	self.visible_maid:clean();

	self.visible_maid:add(RunService.PreRender:Connect(function(dt)
		self.bounce = math.clamp(self.bounce - dt * 10, 0, 5);

		local position = self.spring:update(self.pos_target * self.bounce);

		self.bar.Body.Position = UDim2.fromOffset(position.X, position.Y);
		self.bar.Body.Vignette.Health.Title.Position = UDim2.fromScale(0.5, 0.5 - math.clamp(self.bounce, 0, 0.4))
	end))

	self.bar.LayoutOrder = 1
	self.bar.Visible = true;
	self:play_theme()

	for _, tween in self.tweens[true] do
		tween:Play();
	end;
end

function BossBar:hide()
	self.is_visible = false;
	self.visible_maid:clean();

	for _, tween in self.tweens[false] do
		tween:Play();
		tween.Completed:Once(function(status)
			if status == Enum.PlaybackState.Completed then
				self.bar.LayoutOrder = 0
				self.bar.Visible = false;
			end
		end)
	end;

	self:pause_theme()
end

function BossBar:update_progress()
	local health: number = self.humanoid.Health;
	local health_alpha: number = math.clamp(health / self.humanoid.MaxHealth, 0, 1);

	self.bar.Body.Vignette.Health.Title.Text = `{math.round(health)}`;

	local tween_bar = TweenService:Create(self.bar.Body.Vignette.Body.Bar.Bar, self.bar_tween_info, {
		Size = UDim2.fromScale(health_alpha, 1);
	})
	tween_bar:Play();

	if (self.last_health - health) > 0 then
		self.bounce += math.clamp(0.3 + (self.last_health - health) / self.humanoid.MaxHealth * 9, 0, 2);
		self.pos_target = Vector2.new(1-math.random()*2, 1-math.random()*2).Unit * 25
	end

	self.last_health = health;
end

function BossBar:update_nearest()
	if not self.humanoid.RootPart then return end;

	local distance = Player:DistanceFromCharacter(self.humanoid.RootPart.Position);
	local visible = (distance > 0) and (distance < 150)

	if not self.is_visible and visible then
		self:show()

	elseif self.is_visible and not visible then
		self:hide()
	end
end

function BossBar:destroy()
	self.maid:destroy();
end

table.freeze(BossBar);

Observer.observe_tag("BossBar", function(instance: Configuration)
	local bar = BossBar.new(instance);

	return function()
		bar:destroy()
	end
end)

return BossBar;