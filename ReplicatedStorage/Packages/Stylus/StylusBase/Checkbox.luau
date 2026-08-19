local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Table = require( "../../Table" )
local Maid = require( "../../Maid" )
local Signal = require( "../../Signal" )
local StylusBase = require( script.Parent );

local ButtonCheckbox = script:WaitForChild("Checkbox");

-----------------------------------------------------------------------

export type Defaults = {
	text: string;
	text_scaled: boolean?;
	toggled: boolean;
	tooltip: string?;
	padding: {[string]: UDim}?;
	ui_ratio: number?;
	update_event: RBXScriptSignal?;
	parent: Instance?;
};

export type ClassCheckbox = {
	__index: ClassCheckbox;

	new: (stylus: any, defaults: Defaults) -> Checkbox;
	init: (self: Checkbox) -> ();
};

export type Checkbox = typeof(setmetatable({} :: {
	defaults: Defaults;
	toggled: boolean;
	instance: typeof(ButtonCheckbox);
	
}, {} :: ClassCheckbox));

-----------------------------------------------------------------------

local Checkbox = setmetatable({} :: ClassCheckbox, StylusBase)
Checkbox.__index = Checkbox;
Checkbox.__type = "Checkbox";
Checkbox.defaults = {
	text = "Checkbox";
	text_scaled = false;
	toggled = false;
	parent = nil;
	image_based = false;
	toggle_on_colors = {
		ball = Color3.fromRGB(255, 255, 255);
		backdrop = Color3.fromRGB(54, 188, 24);
	};
	toggle_off_colors = {
		ball = Color3.fromRGB(236, 236, 236);
		backdrop = Color3.fromRGB(148, 148, 148);
	};
}

function Checkbox.new(stylus, defaults)
	debug.profilebegin("Checkbox");
	
	local self = setmetatable(StylusBase.new(stylus, defaults), Checkbox);
	
	self.defaults = Table.mirror(Checkbox.defaults, defaults or {})
	self:create_instance(ButtonCheckbox);
	
	self.toggled = defaults.toggled;
	self.layout.TextLabel.TextScaled = self.defaults.text_scaled;
	self.layout.TextLabel.Text = defaults.text;
	self.toggle_frame = self.value_frame.Toggle;
	self.instance.Visible = true;
	
	self:init()
	self:draw();
	self:update(true);
	
	debug.profileend();
	
	return self;
end;

-- Bruh
function Checkbox:update(immediate: boolean?)
	
	if self.defaults.image_based then
		if self.toggled then
			self.toggle_frame.Image = `rbxasset://textures/RoactStudioWidgets/toggle_on_light.png`;
		else
			self.toggle_frame.Image = `rbxasset://textures/RoactStudioWidgets/toggle_off_light.png`
		end
	else
		if immediate then
			if self.toggled then
				self.toggle_frame.Ball.Icon.ImageColor3 = self.defaults.toggle_on_colors.ball;
				self.toggle_frame.Backdrop.BackgroundColor3 = self.defaults.toggle_on_colors.backdrop;
				self.toggle_frame.Ball.AnchorPoint = Vector2.new(1, 0.5);
				self.toggle_frame.Ball.Position = UDim2.fromScale(1, 0.5);
			else
				self.toggle_frame.Ball.Icon.ImageColor3 = self.defaults.toggle_off_colors.ball;
				self.toggle_frame.Backdrop.BackgroundColor3 = self.defaults.toggle_off_colors.backdrop;
				self.toggle_frame.Ball.AnchorPoint = Vector2.new(0, 0.5);
				self.toggle_frame.Ball.Position = UDim2.fromScale(0, 0.5);
			end
		else
			local info = TweenInfo.new(0.3, Enum.EasingStyle.Back);

			if not self.toggled then
				local color_tween = TweenService:Create(self.toggle_frame.Ball.Icon, info, { ImageColor3 = self.defaults.toggle_off_colors.ball })
				color_tween:Play();

				local color_tween2 = TweenService:Create(self.toggle_frame.Backdrop, info, { BackgroundColor3 =  self.defaults.toggle_off_colors.backdrop })
				color_tween2:Play();

				local open_tween = TweenService:Create(self.toggle_frame.Ball, info, {
					AnchorPoint = Vector2.new(0, 0.5);
					Position = UDim2.fromScale(0, 0.5);
				})
				open_tween:Play();
			else
				local color_tween = TweenService:Create(self.toggle_frame.Ball.Icon, info, { ImageColor3 = self.defaults.toggle_on_colors.ball })
				color_tween:Play();

				local color_tween2 = TweenService:Create(self.toggle_frame.Backdrop, info, { BackgroundColor3 =  self.defaults.toggle_on_colors.backdrop })
				color_tween2:Play();

				local close_tween = TweenService:Create(self.toggle_frame.Ball, info, {
					AnchorPoint = Vector2.new(1, 0.5);
					Position = UDim2.fromScale(1, 0.5);
				})
				close_tween:Play();
			end
		end
	end;
end

function Checkbox:toggle(value: boolean?)
	--warn("use :set_value() instead");
	
	return self:set_value(value);
end

function Checkbox:set_value(value: boolean?)
	local last_toggle = self.toggled;

	if (value == nil) then
		value = not last_toggle;
	end

	if (last_toggle ~= value) then
		self.toggled = value;
		self.value_changed:Fire(value);
		self:update();
	end
end

function Checkbox:get_value(): boolean
	return self.toggled;
end;

function Checkbox:init()
	self.maid:add(self.instance.Button.MouseButton1Click:Connect(function()
		self:toggle();
		self.interacted:Fire(self.toggled);
	end));
end

table.freeze(Checkbox);

return Checkbox;