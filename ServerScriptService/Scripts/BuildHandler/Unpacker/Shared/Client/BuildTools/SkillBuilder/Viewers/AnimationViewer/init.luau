local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

------------------------------------------------------------------------------------

local Maid = require( ReplicatedStorage.Packages.Maid )
local Math = require( ReplicatedStorage.Packages.Math )
local Instances = require( ReplicatedStorage.Packages.Instances )
local PocketTween = require( script.PocketTween )

------------------------------------------------------------------------------------

local AnimationViewer = {};
AnimationViewer.__index = AnimationViewer;

function AnimationViewer.new(panel, name, data)
	local builder = panel.builder;

	local frame = builder.assets.AnimationView:Clone();
	local dummy = builder.assets.AnimationDummy:Clone();

	local camera = Instance.new("Camera");
	camera.FieldOfView = 45
	camera.Parent = frame.Character.ViewportFrame;

	frame.Character.ViewportFrame.CurrentCamera = camera;

	dummy:PivotTo( CFrame.identity );
	dummy.Parent = frame.Character.ViewportFrame.WorldModel;

	frame.Visible = false;
	frame.Parent = builder.edit_block_frame.ScrollingFrame;

	local maid = Maid.new();

	local self = setmetatable(
		{
			name = name;
			maid = maid;
			builder = builder,
			panel = panel;
			data = data;
			dummy = dummy;
			camera = camera;
			animator = dummy.Humanoid.Animator;
			animation_track = nil;
			frame = frame;
			dragging_pointer = false;
			compact_view = false;

			timeline_frame = frame.Timeline;
			character_frame = frame.Character;
			
			yaw = math.pi;
			pitch = math.rad(15);
			zoom = 0;
			
			camera_tweener = PocketTween.new({
				yaw = math.pi,
				pitch = math.rad(15),
				zoom = 0,
			}),
			camera_info = TweenInfo.new(0.15, Enum.EasingStyle.Exponential);
		}, 
		AnimationViewer);

	self.right_pointer = self:create_pointer( UDim2.fromScale(1, 0), function(value)
		return math.clamp( value, self.left_pointer.Position.X.Scale, 1 );
	end)

	self.left_pointer = self:create_pointer( UDim2.fromScale(0, 0), function(value)
		return math.clamp( value, 0, self.right_pointer.Position.X.Scale )
	end)

	self:initialise();

	return self;
end;

------------------------------------------------------------------------------------

function AnimationViewer:initialise_character_rotation()
	local initial_input_position = Vector2.zero;
	local is_dragging = false;
	
	self.character_frame.InputChanged:Connect(function(input: InputObject, processed: boolean)
		if is_dragging and input.UserInputType == Enum.UserInputType.MouseWheel then
			self:change_zoom(input.Position.Z);
		end
	end)

	self.character_frame.TouchPinch:Connect(function(_, scale, velocity)
		self:change_zoom(scale);
	end)
	
	self.character_frame.UIDragDetector.DragEnd:Connect(function()
		is_dragging = false;
	end);
	
	self.character_frame.UIDragDetector.DragStart:Connect(function(input_position)
		is_dragging = true;
		initial_input_position = input_position;
	end)

	self.character_frame.UIDragDetector.DragContinue:Connect(function(input_position)
		local delta = input_position - initial_input_position;

		initial_input_position = input_position;

		self.yaw += math.rad(delta.X);
		self.pitch += math.rad(delta.Y);

		self:update_camera();
	end);

	function self.camera_tweener.on_step(dt: number, values)
		self.camera.CFrame = CFrame.Angles(0, -values.yaw, 0) 
			* CFrame.Angles(-math.clamp(values.pitch, -math.pi / 2.1, math.pi / 2.1), 0, 0) 
			* CFrame.new(0, 0, 10 + values.zoom)
			+ Vector3.new(0, 2.75 - math.min(2.5 + values.zoom * 0.575, 0), 0);
	end
	
	self:update_camera();
end

function AnimationViewer:initialise_full_bar_shifter()
	local bar = self.timeline_frame.Body.Bar;
	local volume = bar.Volume
	local volume_dragger = volume.UIDragDetector;

	local initial_volume_position = Vector2.zero;
	local volume_position = Vector2.zero;

	volume_dragger.DragStart:Connect(function(input_position)
		local range = self:get_animation_range();

		initial_volume_position = input_position;
		volume_position = Vector2.new(range.Min, range.Max);

		self.right_pointer.Value.Visible = true;
		self.left_pointer.Value.Visible = true;
	end)	

	volume_dragger.DragEnd:Connect(function()
		self.right_pointer.Value.Visible = false;
		self.left_pointer.Value.Visible = false;
	end)

	volume_dragger.DragContinue:Connect(function(input_position)
		local delta_position = input_position - initial_volume_position;
		local start = bar.AbsolutePosition.X;
		local finish = bar.AbsolutePosition.X + bar.AbsoluteSize.X;

		local value = delta_position.X / bar.AbsoluteSize.X;

		initial_volume_position = input_position;
		volume_position = Vector2.new(volume_position.X + value, volume_position.Y + value);

		self:set_range( volume_position.X, volume_position.Y );
		self:restart_track();
	end)
end

function AnimationViewer:initialise()
	self:initialise_character_rotation();
	self:initialise_full_bar_shifter();
	
	self.character_frame.ViewMode.MouseButton1Click:Connect(function()
		self:set_compact(not self.compact_view);
	end);
	
	task.defer(function()
		self.maid:add(self.panel:get_property_changed("Speed"):Connect(function(value)
			if self.animation_track and tonumber(value) then
				self.animation_track:AdjustSpeed( value );
			end;
		end));
	end);
end;

function AnimationViewer:set_compact(value: boolean)
	self.compact_view = value;
	
	local value_view = self.panel.fields[self.data.ViewingHelper.Name];

	if value_view then
		if value then
			value_view.frame.BackgroundTransparency = 1;
			value_view.frame.Size = UDim2.fromScale(1, 1);
			value_view.frame.SizeConstraint = Enum.SizeConstraint.RelativeXY;
			value_view.frame.Parent = self.character_frame.SideView;
			
			TweenService:Create(self.character_frame, TweenInfo.new(0.33), { Size = UDim2.fromScale(1, 0.75) }):Play();
			TweenService:Create(self.character_frame.ViewportFrame, TweenInfo.new(0.33), { Size = UDim2.fromScale(0.55, 1) }):Play();
			TweenService:Create(self.character_frame.ViewMode, TweenInfo.new(0.33), { ImageColor3 = Color3.fromRGB(151, 187, 255) }):Play();
		else
			value_view:reset_frame();
			value_view.frame.Parent = self.builder.edit_block_frame.ScrollingFrame;
			
			TweenService:Create(self.character_frame, TweenInfo.new(0.33), { Size = UDim2.fromScale(1, 0.65) }):Play();
			TweenService:Create(self.character_frame.ViewportFrame, TweenInfo.new(0.33), { Size = UDim2.fromScale(1, 1) }):Play();
			TweenService:Create(self.character_frame.ViewMode, TweenInfo.new(0.33), { ImageColor3 = Color3.fromRGB(255, 255, 255) }):Play();
		end;
	end
end

function AnimationViewer:update_camera()
	self.camera_tweener:tween_values(self.camera_info, { yaw = self.yaw, pitch = self.pitch, zoom = self.zoom })
end;

function AnimationViewer:change_zoom(value: number)
	self.zoom = math.clamp(self.zoom - value, -7.50, 20);
	self:update_camera();
end;

function AnimationViewer:get_speed(): number
	local block = self.panel.update_target;

	if block then
		return block:get_value("Speed");
	end;
	
	return 1;
end;

function AnimationViewer:set_animation(animation: Animation)
	if self.animation_track then
		self.animation_track:Stop();
		self.animation_track = nil;
	end;
	
	if animation and animation.AnimationId ~= "" then
		local animation_track: AnimationTrack = self.animator:LoadAnimation(animation);
		animation_track.Looped = true;
		
		animation_track:Play(0);
		animation_track:AdjustSpeed( self:get_speed() );
		
		local connection = RunService.PreAnimation:Connect(function(dt)
			self:update_track_timeline();
		end)

		animation_track.Destroying:Once(function()
			connection:Disconnect();
		end);

		self.animation_track = animation_track
	end;
end;

function AnimationViewer:restart_track()
	if self.animation_track then
		self:update_track_timeline(true);
	end;
end;

function AnimationViewer:update_track_timeline(reset: boolean)
	
	if self.animation_track then
		local length = self.animation_track.Length;
		local position = self.animation_track.TimePosition;
		
		local speed = self:get_speed();
		local range = self:get_animation_range();
		
		local min, max = range.Min * length, range.Max * length;
		
		if self.dragging_pointer then
			if self.animation_track.Speed ~= 0 then
				self.animation_track:AdjustSpeed(0);
			end;

			self.animation_track.TimePosition = self.dragging_pointer.Position.X.Scale * length;
			self.timeline_frame.Body.Bar.Volume.Time.Position = UDim2.fromScale(0, 0);
		else
			if self.animation_track.Speed == 0 then
				self.animation_track:AdjustSpeed( speed );
			end;
			
			if reset or (position > max or position < min) then
				position = if speed < 0 then max else min;
				
				self.animation_track.TimePosition = position
			end;
			
			local value = Math.GetAlpha(min, position, max);
			
			self.timeline_frame.Body.Bar.Volume.Time.Position = UDim2.fromScale(value, 0);
		end;
		
		self.timeline_frame.Body.Bar.Volume.Length.Text = `{string.format("%.2f", (max - min) / speed)}`;
	else
		self.timeline_frame.Body.Bar.Volume.Time.Position = UDim2.fromScale(0, 0);
		self.timeline_frame.Body.Bar.Volume.Length.Text = "-";
	end;
end

function AnimationViewer:set_range(min: number, max: number)
	self.left_pointer.Position = UDim2.fromScale(math.clamp(min, 0, 1), 0);
	self.right_pointer.Position = UDim2.fromScale(math.clamp(max, 0, 1), 0);

	self:update_timeline();
end

function AnimationViewer:get_animation_range(): NumberRange
	return NumberRange.new(self.left_pointer.Position.X.Scale, self.right_pointer.Position.X.Scale);
end;

function AnimationViewer:update_timeline()
	local left_x = self.left_pointer.Position.X.Scale;
	local right_x = self.right_pointer.Position.X.Scale;
	local length = if self.animation_track then self.animation_track.Length else 1;

	self.timeline_frame.Body.Bar.Volume.Position = UDim2.fromScale( left_x, 0.5 );
	self.timeline_frame.Body.Bar.Volume.Size = UDim2.fromScale( right_x - left_x, 1 );

	if (right_x - left_x) < 0.3 then
		self.timeline_frame.Body.Bar.Volume.Length.Position = UDim2.fromScale(0.5, 0.66)
	else
		self.timeline_frame.Body.Bar.Volume.Length.Position = UDim2.fromScale(0.5, -1.5)
	end;
	
	self.left_pointer.Value.Text = string.format("%.2f", left_x * length);
	self.right_pointer.Value.Text = string.format("%.2f", right_x * length);
	
	if left_x > 0.5 then
		self.left_pointer.ZIndex = 2;
		self.right_pointer.ZIndex = 1;
	else
		self.left_pointer.ZIndex = 1;
		self.right_pointer.ZIndex = 2;
	end

	local block = self.panel.update_target;

	if block then
		block:set_property_value(self.data.ViewingHelper.Range, self:get_animation_range())
		--block:set_property_value(self.data.ViewingHelper.Name, self:get_animation_range())
	end;
end;

function AnimationViewer:update_with_panel()
	local block = self.panel.update_target;

	if block then
		local range = block:get_value(self.data.ViewingHelper.Range);
		local name = block:get_value(self.data.ViewingHelper.Name);

		self:set_range( range.Min, range.Max );
		self:set_animation( self.builder:unparse_animation(name) );
	end;
end

function AnimationViewer:create_pointer(position: UDim2, value_callback)
	local pointer = self.builder.assets.AnimationPointer:Clone();
	pointer.Value.Visible = false;
	pointer.Position = position;

	local dragger: UIDragDetector = pointer.UIDragDetector;
	dragger.DragStyle = Enum.UIDragDetectorDragStyle.Scriptable;
	dragger.ResponseStyle = Enum.UIDragDetectorResponseStyle.CustomScale;

	local bar = self.timeline_frame.Body.Bar;

	pointer.Ball.MouseEnter:Connect(function()
		pointer.Ball.BackgroundColor3 = Color3.fromRGB(202, 202, 202)
	end)

	pointer.Ball.MouseLeave:Connect(function()
		pointer.Ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	end)

	dragger.DragStart:Connect(function(input_position)
		self.dragging_pointer = pointer;
		pointer.Value.Visible = true;
	end)

	dragger.DragEnd:Connect(function(input_position)
		self.dragging_pointer = nil;
		pointer.Value.Visible = false;
	end)

	dragger.DragContinue:Connect(function(input_position)
		local start = bar.AbsolutePosition.X;
		local finish = bar.AbsolutePosition.X + bar.AbsoluteSize.X;

		local value = value_callback( Math.GetAlpha(start, input_position.X, finish) );

		if value then
			pointer.Position = UDim2.fromScale( value, 0 );

			self:update_timeline();
		end;
	end)

	pointer.Parent = self.timeline_frame.Body;

	return pointer, dragger;
end

function AnimationViewer:destroy()
	self:set_animation(nil);

	self.maid:destroy();
	self.frame:Destroy();
end

------------------------------------------------------------------------------------

table.freeze(AnimationViewer);

return AnimationViewer;