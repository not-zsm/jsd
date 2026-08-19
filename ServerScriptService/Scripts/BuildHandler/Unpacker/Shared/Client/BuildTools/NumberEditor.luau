local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

-----------------------------------------------------------------------------------------------------------

local Signal = require( ReplicatedStorage.Packages.Signal )
local Maid = require( ReplicatedStorage.Packages.Maid )
local Type = require( ReplicatedStorage.Packages.Type )
local Stylus = require( ReplicatedStorage.Packages.Stylus )
local HelpInput = require( ReplicatedStorage.Packages.HelpInput )

-----------------------------------------------------------------------------------------------------------

export type ClassNumberEditor = {
	__index: ClassNumberEditor;

	new: (build_tools: any) -> NumberEditor;
	constrain_text: (self: NumberEditor, edit_frame: any) -> ();
	initialise: (self: NumberEditor) -> ();
	get_position_to_scale: (self: NumberEditor, offset: Vector2) -> Vector2;
	get_sequence: (self: NumberEditor) -> NumberSequence;
	reset_sequence: (self: NumberEditor) -> ();
	update_scale: (self: NumberEditor) -> ();
	update_display: (self: NumberEditor) -> ();
	select_point: (self: NumberEditor, point: Frame) -> ();
	can_delete_point: (self: NumberEditor, point: Frame) -> boolean;
	delete_point: (self: NumberEditor, point: Frame) -> ();
	get_point_position: (self: NumberEditor, time: number, value: number) -> UDim2;
	create_point: (self: NumberEditor, keypoint: NumberSequenceKeypoint) -> Frame;
	get_ordered_points: (self: NumberEditor) -> {Frame};
	redraw: (self: NumberEditor) -> ();
	set_sequence: (self: NumberEditor, sequence: NumberSequence) -> ();
	bind_stringbox: (self: NumberEditor, stringbox: any, callback: () -> ()) -> ();
	destroy: (self: NumberEditor) -> ();
	toggle: (self: NumberEditor, value: boolean?) -> ();
};

export type NumberEditor = typeof(setmetatable({} :: {
	build_tools: any;
	editor_ui: any;
	editor_frame: any;
	grid: any;
	control: any;
	control_lower: any;
	maid: Maid.Maid;

	enabled: boolean;
	affector_instance: Instance;
	tweens: {[string]: Tween};
	points: {Frame};
	selected_point: Frame?;
	selected_maid: Maid.Maid;
	scale: number;
	
	on_apply: Signal.Signal<>;
	on_cancel: Signal.Signal<>;
	closed: Signal.Signal<>;
	opened: Signal.Signal<>;
	
}, {} :: ClassNumberEditor));

-----------------------------------------------------------------------------------------------------------

local NumberEditor = {} :: ClassNumberEditor;
NumberEditor.__index = NumberEditor;

function NumberEditor.new(build_tools)
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			build_tools = build_tools;
			editor_ui = build_tools.ui.NumberSequence;
			editor_frame = build_tools.ui.NumberSequence.Body.Body;
			grid = build_tools.ui.NumberSequence.Body.Body.Body.Grid;
			control = build_tools.ui.NumberSequence.Body.Body.Control.Body;
			control_lower = build_tools.ui.NumberSequence.Body.Body.Control.BodyLower;
			maid = maid;

			enabled = false;
			affector_instance = nil;
			tweens = {};
			points = {};
			selected_point = nil;
			selected_maid = maid:limb();
			scale = 1;
			
			on_apply = Signal.new();
			on_cancel = Signal.new();
			closed = Signal.new();
			opened = Signal.new();
		}, 
		NumberEditor)
	
	self:initialise();
	
	return self;
end

function NumberEditor:constrain_text(edit_frame)
	edit_frame.TextLabel.TextScaled = true;
	
	--local function update_text_size()
	--	edit_frame.TextLabel.TextSize = edit_frame.AbsoluteSize.Y * 0.7;
	--end;
	
	--task.defer(update_text_size);
	--edit_frame.TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(update_text_size);
end

function NumberEditor:initialise()
	do
		self.tweens.open = TweenService:Create(self.editor_ui.Body, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {GroupTransparency = 0, AnchorPoint = Vector2.new(0.5, 0.5)});
		self.tweens.close = TweenService:Create(self.editor_ui.Body, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {GroupTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.25)});

		self.tweens.close:Play();

		self.tweens.close.Completed:Connect(function(status)
			if (status == Enum.PlaybackState.Completed) then
				self.editor_ui.Enabled = false;
			end
		end)
		
		self.tweens.open.Completed:Connect(function(status)
			if (status == Enum.PlaybackState.Completed) then
				self:redraw();
			end;
		end)
	end
	
	self.editor_frame.Body.Create:AddTag("UI-ButtonClick");

	self.control_lower.Apply.MouseButton1Click:Connect(function()
		self.on_apply:Fire();
		self:toggle(false);
	end)

	self.control_lower.Delete.MouseButton1Click:Connect(function()
		if self.selected_point then
			self:delete_point(self.selected_point);
		end
	end)

	self.editor_frame.Body.Create.MouseButton1Click:Connect(function()
		local scale = self:get_position_to_scale( UserInputService:GetMouseLocation() );

		self:select_point(self:create_point(NumberSequenceKeypoint.new(scale.X, 1 - scale.Y), 1));
		self:redraw();
	end)

	self.control.Time.TextBox.FocusLost:Connect(function()
		if not self.selected_point then return end;
		
		local value = tonumber(self.control.Time.TextBox.Text);

		if value then
			self.selected_point.Position = self:get_point_position(value, 1 - self.selected_point.Position.Y.Scale);
			self:redraw();
		end;
	end)

	self.control.Value.TextBox.FocusLost:Connect(function()
		if not self.selected_point then return end;
		
		local value = tonumber(self.control.Value.TextBox.Text);

		if value then
			self.selected_point.Position = self:get_point_position(self.selected_point.Position.X.Scale, value);
			self:redraw();
		end;
	end)
	
	self.control.Envelope.TextBox.FocusLost:Connect(function()
		if not self.selected_point then return end;

		local value = tonumber(self.control.Envelope.TextBox.Text);

		if value then
			self.selected_point:SetAttribute("Envelope", value);
			self:redraw();
		end;
	end)
	
	self.control_lower.Scale.TextBox.FocusLost:Connect(function()
		self:set_scale( tonumber(self.control_lower.Scale.TextBox.Text) or 1 );
	end)
	
	self:set_scale(1);
	self:update_display();
	
	self:constrain_text(self.control.Time);
	self:constrain_text(self.control.Value);
	self:constrain_text(self.control.Envelope);
	self:constrain_text(self.control_lower.Scale);

	self.editor_frame.Title.Close.MouseButton1Click:Connect(function()
		self:toggle(false);
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and HelpInput.IsInteract(input) then
			self:toggle(false);
		end
	end)
end

function NumberEditor:set_scale(value: number)
	local rounded_value = math.round(value * 1_000) / 1_000;

	self.scale = value;
	self.control_lower.Scale.TextBox.Text = rounded_value;
end

function NumberEditor:get_position_to_scale(offset: Vector2)
	local inset = GuiService:GetGuiInset();
	local scale = (offset - self.editor_frame.Body.Create.AbsolutePosition - inset) / self.editor_frame.Body.Create.AbsoluteSize;
	
	return scale;
end

function NumberEditor:get_sequence()
	local array = {};
	
	for _, point in self:get_ordered_points() do
		local time = point.Position.X.Scale;
		local value = point.Position.Y.Scale;
		local envelope = point:GetAttribute("Envelope");
		
		table.insert(array, NumberSequenceKeypoint.new(time, (1 - value) * self.scale, envelope));
	end	;
	
	return NumberSequence.new(array);
end

function NumberEditor:reset_sequence()
	for _, point in self.points do
		point:Destroy();
	end;
	
	table.clear(self.points);
end

function NumberEditor:update_display()
	if self.selected_point then
		local position = self.selected_point.Position;
		local envelope = self.selected_point:GetAttribute("Envelope");
		
		self.control.Time.TextBox.Text = math.round(position.X.Scale * 1_000) / 1_000;
		self.control.Value.TextBox.Text = math.round((1 - position.Y.Scale) * 1_000) / 1_000;
		self.control.Envelope.TextBox.Text = math.round(envelope * 1_000) / 1_000;
	else
		self.control.Time.TextBox.Text = "-";
		self.control.Value.TextBox.Text = "-";
		self.control.Envelope.TextBox.Text = "-";
	end
end

function NumberEditor:select_point(point)
	local last_point = self.selected_point;
	
	if last_point ~= point then
		self.selected_maid:clean();
		self.selected_point = point;
		
		if last_point then
			last_point.Display.BackgroundColor3 = self.build_tools.assets.NumberSequencePoint.Display.BackgroundColor3;
		end;
		
		if point then
			point.Display.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
			
			self.selected_maid:add(point:GetPropertyChangedSignal("Position"):Connect(function()
				self:update_display();
			end))
		end;
		
		self:update_display();
	end
end

function NumberEditor:can_delete_point(point)
	return point.Position.X.Scale ~= 0 and point.Position.X.Scale ~= 1;
end

function NumberEditor:delete_point(point)
	if not self:can_delete_point(point) then return end;
	
	if self.selected_point == point then
		self:select_point(nil);
	end;
	
	local index = table.find(self.points, point);
	
	if index then
		table.remove(self.points, index);
	end;
	
	point:Destroy();
	self:redraw();
end

function NumberEditor:get_point_position(time: number, value: number): UDim2
	return UDim2.fromScale(math.clamp(time, 0, 1), math.clamp(1 - value, 0, 1));
end

function NumberEditor:create_point(keypoint: NumberSequenceKeypoint, scale: number)
	if #self.points >= 20 then
		return warn("Too many points");
	end;
	
	local point = self.build_tools.assets.NumberSequencePoint:Clone();
	local dragger: UIDragDetector = point.Drag;
	
	if (keypoint.Time == 0 or keypoint.Time == 1) then
		dragger.DragStyle = Enum.UIDragDetectorDragStyle.TranslateLine;
		dragger.DragAxis = Vector2.new(0, 1);
	end;
	
	point.MouseEnter:Connect(function()
		self:select_point(point);
	end)
	
	dragger:AddConstraintFunction(1, function(input_position: UDim2)
		local offset_x = point.Size.X.Offset / self.grid.AbsoluteSize.X;
		local offset_y = point.Size.Y.Offset / self.grid.AbsoluteSize.Y;
		
		return UDim2.fromScale(
			math.clamp(input_position.X.Scale, -offset_x / 2, 1 - offset_x / 2),
			math.clamp(input_position.Y.Scale, -offset_y / 2, 1 - offset_y / 2)
		)
	end)
	
	dragger.DragContinue:Connect(function(input_position)
		self:redraw();
	end);
	
	point:SetAttribute("Envelope", keypoint.Envelope);
	point.Name = "Keypoint";
	point.Position = self:get_point_position(keypoint.Time, keypoint.Value / scale);
	point.Parent = self.grid;
	
	table.insert(self.points, point);
	
	return point;
end

function NumberEditor:get_ordered_points()
	local array = table.clone(self.points);

	table.sort(array, function(point_a, point_b)
		return point_a.Position.X.Scale < point_b.Position.X.Scale;
	end)
	
	return array;
end

function NumberEditor:redraw()
	local array = self:get_ordered_points();
	local control_points = {};
	
	for index, point in array do
		table.insert(control_points, Path2DControlPoint.new(point.Position));
	end;
	
	self.grid.Path:SetControlPoints(control_points);
end

function NumberEditor:set_sequence(sequence: NumberSequence)
	if not sequence or typeof(sequence) ~= "NumberSequence" then
		return warn(`NumberSequence was not passed (got {sequence})`)
	end;
	
	self:reset_sequence();
	
	local keypoints = sequence.Keypoints;
	local max = 1;
	
	for index, keypoint in keypoints do
		if keypoint.Value > max then
			max = keypoint.Value;
		end;
	end;
	
	for index, keypoint in keypoints do
		self:create_point(keypoint, max);
	end;
	
	self:redraw();
end

function NumberEditor:bind_stringbox(stringbox, callback)
	stringbox.maid:add(stringbox.instance.Button.MouseButton1Click:Connect(function()
		if self.affector_instance == stringbox.instance then
			self:toggle(false);
			self.affector_instance = nil;
		else
			self:toggle(true);
			self.affector_instance = stringbox.instance;
		end;
	end))

	if callback then
		stringbox.maid:add(self.on_apply:Connect(function()
			if self.affector_instance == stringbox.instance then
				callback( self:get_sequence() );
			end;
		end))
	end;
end


function NumberEditor:destroy()
	self.maid:destroy();
end

function NumberEditor:toggle(value: boolean?)
	if (value == nil) then
		value = not self.enabled;
	end;

	if (value ~= self.enabled) then
		self.build_tools:close_all(self);
		self.enabled = value;
		
		self:set_scale(1);
		self:select_point(nil);
		
		if (value) then
			self.opened:Fire();
			self.tweens.open:Play();
			self.editor_ui.Enabled = true;
			
			Stylus:tween_blur(15);
			SoundService:PlayLocalSound(self.build_tools.sounds.DockToggle);
		else
			self.affector_instance = nil;
			self.closed:Fire();
			self.tweens.close:Play();
			
			Stylus:tween_blur(0);
		end	
	end;
end

table.freeze(NumberEditor);

return NumberEditor;