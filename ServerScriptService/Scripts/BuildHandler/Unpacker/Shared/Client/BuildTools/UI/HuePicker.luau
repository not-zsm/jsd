local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

-----------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------

local Signal = require( ReplicatedStorage.Packages.Signal )
local Maid = require( ReplicatedStorage.Packages.Maid )
local Type = require( ReplicatedStorage.Packages.Type )

-----------------------------------------------------------------------------------------------------------

local HALF_VEC2 = Vector2.one / 2;
local TWO_PI = math.pi * 2;

-----------------------------------------------------------------------------------------------------------

export type ClassHuePicker = {
	__index: ClassHuePicker;

	toggle: (self: HuePicker, value: boolean?) -> ();
	get_color: (self: HuePicker) -> Color3;
	update_color: (self: HuePicker) -> ();
	set_color_position: (self: HuePicker, color: Color3) -> ();
	get_bearing: (self: HuePicker, position: Vector2) -> number;
	init_hue_scale: (self: HuePicker) -> ();
	init_gradient_scale: (self: HuePicker) -> ();
	bind_colorbox: (self: HuePicker, colorbox: unknown, callback: () -> ()) -> ();
	destroy: (self: HuePicker) -> ();
	initialise_tweens: (self: HuePicker) -> ();
	new: (build_tools: unknown) -> HuePicker;
};

export type HuePicker = typeof(setmetatable({} :: {
	build_tools: any;
	hue_picker: any;
	maid: Maid.Maid;

	affector_instance: Instance?;
	
	hue_offset: number;
	hue: number;
	saturation: number;
	value: number;

	color_commit: Signal.Signal<>;
	color_updated: Signal.Signal<>;
	closed: Signal.Signal<>;
	opened: Signal.Signal<>;
	
}, {} :: ClassHuePicker));

-----------------------------------------------------------------------------------------------------------

local HuePicker = {} :: ClassHuePicker;
HuePicker.__index = HuePicker;

function HuePicker:toggle(value: boolean?)
	self.hue_frame.Visible = true;
	
	if (value == nil) then
		value = not self.visible;
	end;
	
	if (value ~= self.visible) then
		self.visible = value;
		
		if (value) then
			self.opened:Fire();
			self.tweens.open:Play();
			
			SoundService:PlayLocalSound(self.build_tools.sounds.DockToggle);
		else
			self.affector_instance = nil;
			self.closed:Fire();
			
			if self.animated then
				self.tweens.close:Play();
			end;
		end	
	end;
end

function HuePicker:get_color(): Color3
	return Color3.fromHSV(self.hue, self.saturation, self.value);
end

function HuePicker:update_color(): ()
	local color = self:get_color();
	
	self.hue_picker.Color.BackgroundColor3 = color;
	self.hue_picker.Gradient.ImageColor3 = Color3.fromHSV(self.hue, self.saturation, 1);
	
	self.color_updated:Fire(color);
end

function HuePicker:set_color_position(color: Color3)
	self.hue, self.saturation, self.value = color:ToHSV();
	
	local hue_position = Vector2.new( math.sin(self.hue * TWO_PI), -math.cos(self.hue * TWO_PI) ) * self.saturation / 2 + HALF_VEC2
	
	self.hue_picker.Hue.Picker.Position = UDim2.fromScale(hue_position.X, hue_position.Y);
	self.hue_picker.Gradient.Slider.Position = UDim2.new(self.value, -self.hue_picker.Gradient.Slider.AbsoluteSize.X / 2, 1, 0)
	
	self:update_color();
end

function HuePicker:get_bearing(position: Vector2): number
	local angle = math.deg( Vector2.yAxis:Angle(-position, true) )

	if angle < 0 then 
		return angle + 360;
	else
		return angle;
	end
end

function HuePicker:bind_colorbox(colorbox, callback)
	
	colorbox.maid:add(self.color_updated:Connect(function()
		if self.affector_instance == colorbox.instance then
			local color = self:get_color();
			colorbox:set_color( color );
		end
	end))
	
	colorbox.maid:add(colorbox.interacted:Connect(function()
		if self.affector_instance == colorbox.instance then
			self:toggle(false);
			self.affector_instance = nil;
		else
			self:toggle(true);
			self.affector_instance = colorbox.instance;
			
			local color = Type.Color3:cast(colorbox.value_frame.TextBox.Text);
			colorbox:set_color(color);

			self:set_color_position(color)
		end;
	end))
	
	if callback then	
		colorbox.maid:add(colorbox.value_frame.TextBox.FocusLost:Connect(function()
			callback( Type.Color3:cast(colorbox.value_frame.TextBox.Text) );
		end));
		
		colorbox.maid:add(self.color_commit:Connect(function()
			if self.affector_instance == colorbox.instance then
				callback( self:get_color() );
			end;
		end))
	end;
end

function HuePicker:init_hue_scale()
	local hue_drag = self.hue_picker.Hue.UIDragDetector :: UIDragDetector;
	local initial_position = Vector2.zero;

	local function update_hue_scale()
		local drag_scale = hue_drag.DragUDim2;
		local position = Vector2.new(drag_scale.Width.Scale, drag_scale.Height.Scale) * self.hue_offset + initial_position - HALF_VEC2

		if position ~= Vector2.zero then
			local clamp_position = position.Unit * math.min(position.Magnitude, 1/2);
			local anchor_position = clamp_position + HALF_VEC2;

			local angle = self:get_bearing(position);
			-- what the hell is an fmod ...... thanks documentation
			local color = Color3.fromHSV( math.fmod(angle, 360 ) / 360, math.clamp(clamp_position.Magnitude * 2, 0, 1), self.value )
			
			self:set_color_position(color);
			self.hue_picker.Hue.Picker.Position = UDim2.fromScale(anchor_position.X, anchor_position.Y);
		end
	end;
	
	hue_drag.DragStart:Connect(function(input_position)
		local inset_top = GuiService:GetGuiInset()
		local to_scale = (input_position - self.hue_picker.Hue.AbsolutePosition - inset_top) / self.hue_picker.Hue.AbsoluteSize
		
		initial_position = to_scale;
		update_hue_scale();
	end)

	hue_drag.DragEnd:Connect(function()
		self.color_commit:Fire()
	end)
	
	hue_drag.DragContinue:Connect(update_hue_scale)
end

function HuePicker:init_gradient_scale()
	local gradient_drag = self.hue_picker.Gradient.UIDragDetector;

	local initial_position = Vector2.zero;

	local function update_gradient_scale()
		local drag_scale = gradient_drag.DragUDim2;
		local position = Vector2.new(drag_scale.Width.Scale, 1) + initial_position;
		local color = Color3.fromHSV( self.hue, self.saturation, math.clamp(position.X, 0.001, 1) )
		
		self:set_color_position(color)
	end

	gradient_drag.DragStart:Connect(function(input_position)
		local inset_top = GuiService:GetGuiInset()
		local to_scale = (input_position - self.hue_picker.Gradient.AbsolutePosition - inset_top) / self.hue_picker.Gradient.AbsoluteSize

		initial_position = to_scale;
		update_gradient_scale();
	end)

	gradient_drag.DragEnd:Connect(function()
		self.color_commit:Fire()
	end)
	
	gradient_drag.DragContinue:Connect(update_gradient_scale)
end

function HuePicker:destroy()
	self.maid:destroy();
	self.hue_picker:Destroy();
end

function HuePicker:initialise_tweens()
	self.tweens = {
		open = TweenService:Create(self.hue_picker, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {Position = UDim2.fromScale(0, 0)});
		close = TweenService:Create(self.hue_picker, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {Position = UDim2.fromScale(if self.animated then 1 else 0, 0)});
	};

	self.tweens.close:Play();

	self.tweens.close.Completed:Connect(function(status)
		if (status == Enum.PlaybackState.Completed) then
			self.hue_frame.Visible = false;
		end
	end)
end

function HuePicker.new(build_tools, hue_picker_frame, animated)
	local maid = Maid.new();
	
	if not hue_picker_frame then
		hue_picker_frame = build_tools.elements.HuePickerFrame;
	end;
	
	local self = setmetatable(
		{
			build_tools = build_tools;
			hue_frame = hue_picker_frame,
			hue_picker = hue_picker_frame.Body;
			maid = maid;

			animated = not not animated;
			visible = false;
			affector_instance = nil;
			hue_offset = 1;

			hue = 1;
			saturation = 1;
			value = 1;

			color_commit = maid:add(Signal.new());
			color_updated = maid:add(Signal.new());
			closed = maid:add(Signal.new());
			opened = maid:add(Signal.new());
		}, 
		HuePicker)
	
	self:initialise_tweens();
	self:init_hue_scale();
	self:init_gradient_scale();
	
	return self;
end

table.freeze(HuePicker);

return HuePicker;