local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Math = require( "../../Math" )
local Table = require( "../../Table" )
local Maid = require( "../../Maid" )
local Signal = require( "../../Signal" )
local StylusBase = require( script.Parent );

local ButtonSliderbox = script:WaitForChild("Sliderbox");

-----------------------------------------------------------------------

export type Defaults = {
	text: string;
	text_scaled: boolean?;
	tooltip: string?;
	ui_ratio: number?;
	padding: {[string]: UDim}?;
	ratio: number;
	parent: Instance?;
};

export type ClassSliderbox = {
	__index: ClassSliderbox;

	new: (stylus: any, defaults: Defaults) -> Sliderbox;
	init: (self: Sliderbox) -> ();
	set_label: (self: Sliderbox, label: string) -> ();
	get_raw_alpha: (self: Sliderbox) -> number;
	set_alpha: (self: Sliderbox, alpha: number) -> ();
	update_alpha: (self: Sliderbox, input: Vector2) -> ();
	get_value_from_alpha: (self: Sliderbox) -> number;
	get_alpha_from_value: (self: Sliderbox, value: number) -> number;
};

export type Sliderbox = typeof(setmetatable({} :: {
	defaults: Defaults;
	instance: typeof(ButtonSliderbox);
	slider: typeof(ButtonSliderbox.Slider);
	ball: typeof(ButtonSliderbox.Slider.Ball);
	maid: Maid.Maid;
	alpha: number;
	value: number;

}, {} :: ClassSliderbox));

-----------------------------------------------------------------------

local Sliderbox = setmetatable({} :: ClassSliderbox, StylusBase)
Sliderbox.__index = Sliderbox;
Sliderbox.__type = "Sliderbox";
Sliderbox.defaults = {
	text = "Sliderbox";
	text_scaled = false;
	ratio = 0.5;
	range = NumberRange.new(0, 100);
	increment = 0.01;
	parent = nil;
}

function Sliderbox.new(stylus, defaults)
	debug.profilebegin("Sliderbox");
	
	local self = setmetatable(StylusBase.new(stylus, defaults), Sliderbox);
	
	self.defaults = Table.mirror(Sliderbox.defaults, defaults or {})
	self:create_instance(ButtonSliderbox);
	
	self.layout.TextLabel.Size = UDim2.fromScale(self.defaults.ratio, 1);
	self.layout.TextLabel.TextScaled = self.defaults.text_scaled;
	self.instance.Visible = true;
	self.ball = self.value_frame.Slider.Ball;
	self.slider = self.value_frame.Slider;
	self.dragger = self.slider.UIDragDetector;
	self.alpha = 0;
	self.value = 0;
	
	self:set_label(self.defaults.text)
	self:init();
	self:draw();
	
	debug.profileend();
	
	return self;
end;

function Sliderbox:set_label(label: string): ()
	self.layout.TextLabel.Text = tostring(label or "");
end

function Sliderbox:get_raw_alpha(): number
	local ball_pos = self.ball.AbsolutePosition.X;
	local start_pos = self.slider.AbsolutePosition.X;
	local end_pos = start_pos + self.slider.AbsoluteSize.X;
	
	return Math.GetAlpha(start_pos, ball_pos, end_pos);
end

function Sliderbox:get_value_from_alpha(alpha: number)
	return math.map(alpha, 0, 1, self.defaults.range.Min, self.defaults.range.Max);
end

function Sliderbox:get_alpha_from_value(value: number)
	return math.map(value, self.defaults.range.Min, self.defaults.range.Max, 0, 1);
end

function Sliderbox:set_alpha(alpha: number): ()
	local increment = self.defaults.increment
	local last_value = self.value;
	
	self.alpha = math.round(alpha / increment) * increment;
	self.value = self:get_value_from_alpha(self.alpha);
	
	self.ball.Position = UDim2.fromScale(math.clamp(self.alpha, 0.075, 0.925), 0.5)
	self.slider.Backdrop.Size = UDim2.fromScale(math.clamp(self.alpha, 0, 1), 0.5)
	self.value_frame.TextBox.Text = string.format("%.14g", self.value);
	
	if (self.value ~= last_value) then
		self.value_changed:Fire(self.value, last_value);
	end;
end

function Sliderbox:get_value(): number
	return self.value;
end

function Sliderbox:update_alpha(input: Vector2): ()
	local start, finish = self.slider.AbsolutePosition.X, self.slider.AbsolutePosition.X + self.slider.AbsoluteSize.X;
	local alpha = math.clamp( Math.GetAlpha(start, input.X, finish), 0, 1 );
	
	self:set_alpha(alpha);
end

function Sliderbox:init()
	self.value = self.defaults.value;
	self:set_alpha(self:get_alpha_from_value(self.value));
	
	self.maid:add(self.value_frame.TextBox.FocusLost:Connect(function(enter_pressed)
		if not enter_pressed then return end;
		
		self:set_alpha(self:get_alpha_from_value(tonumber(self.value_frame.TextBox.Text)));
		self.interacted:Fire(self.value);
	end))
	
	self.maid:add(self.slider.UIDragDetector.DragStart:Connect(function(input)
		self:update_alpha(input);
	end))
	
	self.maid:add(self.slider.UIDragDetector.DragContinue:Connect(function(input)
		self:update_alpha(input);
	end))
	
	self.maid:add(self.slider.UIDragDetector.DragEnd:Connect(function()
		self.interacted:Fire(self.value);
	end))
end;

function Sliderbox:set_value(value: number)
	self:set_alpha( self:get_alpha_from_value(value) );
end

table.freeze(Sliderbox);

return Sliderbox;