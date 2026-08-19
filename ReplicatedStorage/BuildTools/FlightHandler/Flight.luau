local RunService = game:GetService("RunService");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService");
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players");

-------------------------------------------------------------------------------

local Player = Players.LocalPlayer;

-------------------------------------------------------------------------------

local Maid = require( ReplicatedStorage.Packages.Maid )

local ControlModule = require(Player
	:WaitForChild("PlayerScripts")
	:WaitForChild("PlayerModule")
	:WaitForChild("ControlModule"))

-------------------------------------------------------------------------------

export type ClassFlight = {
	__index: ClassFlight;

	new: (character: Model) -> Flight;
	destroy: (self: Flight) -> ();
	on_jump: (self: Flight) -> ();
	set_noclip: (self: Flight, value: boolean) -> ();
	get_render_name: (self: Flight) -> string;
	toggle: (self: Flight, value: boolean?) -> ();
	enable: (self: Flight) -> ();
	update: (self: Flight, dt: number) -> ();
	disable: (self: Flight) -> ();
};

export type Flight = typeof(setmetatable({} :: {
	active: boolean;
	speed: number;
	speed_multiplier: NumberValue;
	noclip: boolean;
	last_jump: number;

	maid: Maid.Maid;
	active_maid: Maid.Maid;

	character: Model;
	humanoid: Humanoid;
	animator: Animator;
	camera: Camera;
	
	force: LinearVelocity?;
	lookat: AlignOrientation?;
	
	animations: {[string]: AnimationTrack};
	
}, {} :: ClassFlight));

-------------------------------------------------------------------------------

local Flight = {} :: ClassFlight;
Flight.__index = Flight;

function Flight.new(character: Model): Flight
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid;
	local animator = humanoid:WaitForChild("Animator") :: Animator;
	
	local self = setmetatable(
		{
			active = false;
			reduced_motion = false;
			noclip = true;
			
			speed = 50.0;
			speed_multiplier = Instance.new("NumberValue");
			
			last_jump = -1;
			
			maid = Maid.light();
			active_maid = Maid.light();
			
			character = character;
			humanoid = humanoid;
			animator = animator;
			camera = workspace.CurrentCamera;
			animations = {};
		},
		Flight);
	
	self:initialise();
	
	return self;
end;

local function bind_action(action_name, touch_button, keys, callback)
	ContextActionService:BindAction(action_name, callback, touch_button, unpack(keys));
	
	return function()
		ContextActionService:UnbindAction(action_name);
	end;
end;

function Flight:initialise()
	self.speed_multiplier.Value = 1;

	self.maid:add(self.character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:destroy();
		end;
	end))
	
	local wheel_delta = 0;
	
	self.maid:add(UserInputService.PointerAction:Connect(function(wheel, pan, pinch, processed)
		wheel_delta = wheel;
	end))
	
	self.maid:add(bind_action("FlyPanFaster", false, 
		{
			Enum.UserInputType.MouseWheel,
		}, 
		function(action_name: string, input_state: Enum.UserInputState, input: InputObject)
			if self.active and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				local softening = math.clamp(math.map(self.speed, 10, 30, 0.2, 1), 0.2, 1);
				
				self.speed = math.clamp(self.speed + wheel_delta * softening * 18, 0.1, 1000);
				
				return Enum.ContextActionResult.Sink;
			end

			return Enum.ContextActionResult.Pass;
		end))
	
	self.maid:add(bind_action("FlyUp", false, 
		{
			Enum.KeyCode.E,
			Enum.KeyCode.ButtonR1,
		}, 
		function(action_name, input_state, input)
			self.fly_up = (input_state == Enum.UserInputState.Begin);
			
			if self.active then
				return Enum.ContextActionResult.Sink;
			end;
			
			return Enum.ContextActionResult.Pass;
		end))
	
	self.maid:add(bind_action("FlyDown", false, 
		{
			Enum.KeyCode.Q,
			Enum.KeyCode.ButtonL1
		}, 
		function(action_name, input_state, input)
			self.fly_down = (input_state == Enum.UserInputState.Begin);
			
			if self.active then
				return Enum.ContextActionResult.Sink;
			end;
			
			return Enum.ContextActionResult.Pass;
		end))
	
	self.maid:add(bind_action("FlightBoost", false, 
		{
			Enum.KeyCode.LeftAlt,
			Enum.KeyCode.ButtonL3
		}, 
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin) then
				TweenService:Create(self.speed_multiplier, TweenInfo.new(0.25), {Value = 5}):Play();
				
			elseif (input_state == Enum.UserInputState.End) then
				TweenService:Create(self.speed_multiplier, TweenInfo.new(0.25), {Value = 1}):Play();
			end

			return Enum.ContextActionResult.Pass;
		end))
	
	self.maid:add(bind_action("Motion", false, 
		{
			Enum.KeyCode.R,
			Enum.KeyCode.DPadUp
		}, 
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin) then
				self.reduced_motion = not self.reduced_motion;
			end;
			
			return Enum.ContextActionResult.Pass;
		end))
	
	self.maid:add(bind_action("FlyTrigger", false, 
		{
			Enum.KeyCode.Space,
			Enum.KeyCode.ButtonA
		}, 
		function(action_name, input_state, input)
			if (input_state == Enum.UserInputState.Begin) then
				self:on_jump();
			end;
			
			return Enum.ContextActionResult.Pass;
		end))

	if UserInputService.TouchEnabled then
		local JumpButton: ImageButton = Player.PlayerGui:WaitForChild("Mobile"):WaitForChild("DragFrame"):WaitForChild("Jump"):WaitForChild("Button")
		
		self.maid:add(JumpButton.MouseButton1Click:Connect(function()
			self:on_jump()
		end))
	end
end

function Flight:destroy(): ()
	self:disable();
	self.maid:destroy();
	self.active_maid:destroy();
end

-------------------------------------------------------------------------------

function Flight:on_jump(): ()
	local now = tick();
	
	if now - self.last_jump < 0.3 then
		self:toggle();
	end
	
	self.last_jump = now;
end

function Flight:set_noclip(value: boolean): ()
	self.noclip = value;
end

function Flight:get_render_name(): string
	return "Flight" .. tostring(self);
end

function Flight:toggle(value: boolean?): ()
	if (value == nil) then
		value = not self.active;
	end;
	
	if self.active ~= value then
		if value then
			self:enable();
		else
			self:disable();
		end
	end
end

function Flight:enable(): ()
	if self.active then return end;

	self.active = true;
	
	-- Make the flying not bug out
	self.humanoid.AutoRotate = false;
	self.humanoid.PlatformStand = true;
	self.humanoid.Jump = false;
	
	-- Create moving velocity
	self.force = script.LinearVelocity:Clone()
	self.force.Attachment0 = self.humanoid.RootPart.RootAttachment;
	self.force.Parent = self.force.Attachment0.Parent;
	
	-- Create look gyro
	self.lookat = script.AlignOrientation:Clone();
	self.lookat.Attachment0 = self.force.Attachment0;
	self.lookat.Parent = self.force.Parent;
	
	-- Idle animation
	self.animations.idle = self.animator:LoadAnimation(script.Idle);
	self.animations.idle:Play();
	
	-- Flying animation
	self.animations.forward = self.animator:LoadAnimation(script.Forward);
	self.animations.forward:Play();
	
	self.character:AddTag("Flying");
	
	self.fly_connection = RunService.PreSimulation:Connect(function(dt)
		self:update(dt);
	end)
end

function Flight:update(dt: number): ()
	local move_vector: Vector3 = ControlModule:GetMoveVector();
	local camera_vector: Vector3 = self.camera.CFrame:VectorToWorldSpace(move_vector);
	local shift = self.speed_multiplier.Value;
	
	if self.fly_up then
		camera_vector += self.camera.CFrame.UpVector;
	end;
	
	if self.fly_down then
		camera_vector -= self.camera.CFrame.UpVector;
	end;

	if self.noclip then
		for _, child in self.character:GetChildren() do
			if child:IsA("BasePart") then
				child.CanCollide = false;
			end
		end
	end;

	self.force.VectorVelocity = camera_vector * self.speed * shift;
	
	if not self.reduced_motion and move_vector ~= Vector3.zero then
		self.lookat.CFrame = self.lookat.CFrame:Lerp(CFrame.lookAlong(Vector3.zero, self.camera.CFrame.LookVector + camera_vector * 4), 12 * dt);
		self.animations.forward:AdjustWeight(1);
	else
		self.lookat.CFrame = self.lookat.CFrame:Lerp(self.camera.CFrame.Rotation, 12 * dt);
		self.animations.forward:AdjustWeight(0.001);
	end;
end

function Flight:disable(): ()
	if not self.active then return end;
	
	self.active = false;
	self.active_maid:clean();
	
	self.humanoid.AutoRotate = true;
	self.humanoid.PlatformStand = false;
	self.humanoid.Jump = false;
	self.character:RemoveTag("Flying");
	
	if self.force then
		self.force:Destroy();
		self.force = nil;
	end;
	
	if self.lookat then
		self.lookat:Destroy();
		self.lookat = nil;
	end;
	
	for name, animation in self.animations do
		animation:Stop();
		animation:Destroy();
	end;
	
	table.clear(self.animations);
	
	self.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp);
	
	if self.fly_connection then
		self.fly_connection:Disconnect();
		self.fly_connection = nil;
	end
end

-------------------------------------------------------------------------------

table.freeze(Flight)

return Flight;