local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

------------------------------------------------------------------------------------------------

local Player = Players.LocalPlayer;
local PlayerGui = Player:WaitForChild("PlayerGui");

local Interface = script:WaitForChild("Interface");
local Sounds = script:WaitForChild("Sounds");
local Assets = script:WaitForChild("Assets");

------------------------------------------------------------------------------------------------

local InteractiveUI = Interface.InteractiveUI:Clone()
InteractiveUI.Parent = PlayerGui;

local TooltipUI = Interface.TooltipUI:Clone();
TooltipUI.Parent = PlayerGui;

------------------------------------------------------------------------------------------------

local Observer = require( ReplicatedStorage.Packages.Observer );
local Maid = require( ReplicatedStorage.Packages.Maid );
local HelpInput = require( ReplicatedStorage.Packages.HelpInput );

local UIBlur = require( script.UIBlur )
local UILoading = require( script.UILoading )

------------------------------------------------------------------------------------------------

local function find_parent(base: Instance, parents: number)
	if parents ~= nil then
		while parents > 0 do
			base = base.Parent :: any;
			parents -= 1;
		end
	end

	return base;
end;

local function mouse_position()
	return UserInputService:GetMouseLocation();
end

function multiply_udim(udim: UDim, value: number): UDim
	return UDim.new(udim.Scale * value, udim.Offset * value);
end

------------------------------------------------------------------------------------------------

local reference_viewport_size = Vector2.new(1920, 1080);

Observer.observe_tag("UI-AutoPadding", function(padding: Instance)
	local default_padding = Instance.fromExisting(padding);
	
	local update_padding: () -> ();
	
	if padding:IsA("UIPadding") then
		function update_padding()
			local viewport_size = workspace.CurrentCamera.ViewportSize;
			local scale = (viewport_size / reference_viewport_size).Magnitude;
			
			padding.PaddingLeft = multiply_udim(default_padding.PaddingLeft, scale);
			padding.PaddingRight = multiply_udim(default_padding.PaddingRight, scale);
			padding.PaddingTop = multiply_udim(default_padding.PaddingTop, scale);
			padding.PaddingBottom = multiply_udim(default_padding.PaddingBottom, scale);
		end
		
	elseif padding:IsA("UIListLayout") then
		function update_padding()
			local viewport_size = workspace.CurrentCamera.ViewportSize;
			local scale = (viewport_size / reference_viewport_size).Magnitude;

			padding.Padding = multiply_udim(default_padding.Padding, scale);
		end
	end
	
	update_padding();
	local connection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update_padding);
	
	return function()
		connection:Disconnect();
	end
end)

-- To fix strange bugs with gamepad
Observer.observe_tag("UI-PageLayoutSafe", function(layout: UIPageLayout)
	local function update_animated()
		if HelpInput.UsingGamepad then
			layout.Animated = false;
		else
			layout.Animated = true;
		end;
	end
	
	update_animated();
	local connection = HelpInput.OnPrimaryInputTypeChanged:Connect(update_animated);
	
	return function()
		connection:Disconnect();
	end
end)

Observer.observe_tag("UI-Tooltip", function(hoverable: GuiObject)
	if true then return end -- DISABLES ALL TOOLTIPS !
	
	local tooltip: typeof(Assets.DefaultTip);
	local maid = Maid.new();
	local hover_maid = maid:limb();
	local hover_tip_lock = false;
	local mouse_hovering = false;
	local mouse_hover_position = Vector2.zero;
	local info = TweenInfo.new(0.5);

	local function leave_tooltip()
		if tooltip then
			tooltip:Destroy()
		end

		hover_maid:clean();
	end

	local function enter_tooltip()
		leave_tooltip();

		if hover_tip_lock then
			return;
		end
		hover_maid:add(task.delay(0.4, function()
			tooltip = Assets.DefaultTip:Clone();
			tooltip.Body.Label.Text = hoverable:GetAttribute("Tooltip") or "";
			tooltip.Name = "Tip";
			tooltip.Visible = true;
			tooltip.GroupTransparency = 1;
			tooltip.Parent = TooltipUI.Tips;
			
			TweenService:Create(tooltip, info, {GroupTransparency = 0}):Play()
		end))
	end

	maid:add(UserInputService.InputChanged:Connect(function(input)
		if mouse_hovering and (input.UserInputType == Enum.UserInputType.MouseMovement)
			and ( mouse_position() - mouse_hover_position ).Magnitude > 8	
		then
			mouse_hover_position = mouse_position()
			enter_tooltip();
		end
	end))

	maid:add(UserInputService.TextBoxFocused:Connect(function(box)
		if box == hoverable or box:IsDescendantOf(hoverable) then
			hover_tip_lock = true;
			leave_tooltip()
		end
	end))

	maid:add(UserInputService.TextBoxFocusReleased:Connect(function()
		hover_tip_lock = false;
	end))
	
	local mouse_leave: RBXScriptConnection;
	
	maid:add(hoverable.MouseEnter:Connect(function()
		mouse_hovering = true;
		mouse_hover_position = mouse_position()
		enter_tooltip();
		
		mouse_leave = maid:add(hoverable.MouseLeave:Connect(function()
			maid:delete(mouse_leave);
			mouse_hovering = false;
			leave_tooltip();
		end))
	end))

	return function()
		maid:destroy();
		leave_tooltip()
	end
end)

Observer.observe_tag("UI-RotatingGradient", function(object: UIGradient)
	local rotations_per_second = 90;
	
	local connection = RunService.PostSimulation:Connect(function(dt)
		object.Rotation += rotations_per_second * dt;
	end)
	
	return function()
		connection:Disconnect();
	end
end)

Observer.observe_tag("UI-RainbowText", function(object: TextLabel)
	local loop_time = 5; 
	
	local connection = RunService.PostSimulation:Connect(function(dt)
		local hue = tick() % loop_time / loop_time;
		local color = Color3.fromHSV(hue, 0.5, 1);
		
		object.TextColor3 = color;
	end)
	
	return function()
		connection:Disconnect();
	end
end)

Observer.observe_tag("UI-ButtonHover", function(object: GuiObject)
	local maid = Maid.light();
	local bounds = object.Size;

	local info = object:GetAttributes();

	local open_info = TweenInfo.new(info.EasingTime or 0.1, info.EasingStyle or Enum.EasingStyle.Sine, info.EasingDirection or Enum.EasingDirection.Out);
	local close_info = TweenInfo.new(info.EasingTime or 0.1, info.EasingStyle or Enum.EasingStyle.Sine, info.EasingDirection or Enum.EasingDirection.Out);

	local hoverable = find_parent(object, info.HoverParent) :: GuiObject
	local hover_scale = info.ButtonHoverScale or 1.1;
	
	local open_tween = TweenService:Create(hoverable, open_info, {Size = UDim2.new(bounds.X.Scale * hover_scale, bounds.X.Offset * hover_scale, bounds.Y.Scale * hover_scale, bounds.Y.Offset * hover_scale)});
	local close_tween = TweenService:Create(hoverable, close_info, {Size = bounds;});
	
	maid:add(hoverable.MouseEnter:Connect(function()
		open_tween:Play();
	end))

	maid:add(hoverable.MouseLeave:Connect(function()
		close_tween:Play();
	end))

	return function()
		close_tween:Play();
		maid:destroy();
	end
end)

local click_animate_info = TweenInfo.new(0.2);
local click_animate_goal = {
	Size = UDim2.fromOffset(48, 48);
	BackgroundTransparency = 1;
};

local function animated_click()
	local position = mouse_position();

	local click = InteractiveUI.Click:Clone();
	click.Name = "Animate";
	click.Archivable = false;
	click.Visible = true;
	click.Position = UDim2.fromOffset(position.X, position.Y);
	click.Size = UDim2.fromOffset(0, 0);
	click.Parent = InteractiveUI;

	local tween = TweenService:Create(click, click_animate_info, click_animate_goal);
	tween.Completed:Once(function()
		click:Destroy();
	end);
	tween:Play();
end

local function animated_sound(object: Instance)
	local sound = object:FindFirstChild("UIButtonClick") :: Sound;

	if sound then
		SoundService:PlayLocalSound(sound);
	else
		SoundService:PlayLocalSound(Sounds.ButtonPop);
	end
end

Observer.observe_tag("UI-ButtonClick", function(object: GuiButton)
	local connection = object.MouseButton1Click:Connect(function()
		animated_sound(object);
		animated_click();
	end)

	return function()
		connection:Disconnect()
	end
end)

Observer.observe_tag("UI-ButtonPop", function(object: GuiObject)
	local maid = Maid.new();
	local bounds = object.Size;

	local info = object:GetAttributes();
	local affected = find_parent(object, info.PopParent);
	local ui_scale: UIScale = affected:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", affected);

	local open_info = TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.Out);

	local close_tween = TweenService:Create(ui_scale, open_info, {Scale = 1});
	local open_tween = TweenService:Create(ui_scale, open_info, {Scale = info.ButtonPopScale or 1.1});

	object:AddTag("UI-ButtonClick");

	local connection = object.InputEnded:Connect(function(input)
		if HelpInput.IsInteract(input) then
			open_tween:Play();
		end;
	end)

	open_tween.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed then
			close_tween:Play();
		end;
	end);

	return function()
		open_tween:Destroy();
		close_tween:Destroy();
		connection:Disconnect();
	end
end)

return {};