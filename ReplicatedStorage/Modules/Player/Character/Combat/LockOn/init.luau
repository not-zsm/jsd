local LockOn = {};
LockOn.__index = LockOn;

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local MaxYAngle = math.rad(75)
local YThetaClamp = math.rad(5) --math.rad(5)
local MinYAngle = math.rad(0)

local AimAssist = require( ReplicatedStorage.Modules.Shared.Game.AimAssist )
local LockOnEffect = require( script.Effect )

function LockOn.new(combat)
	local self = setmetatable({}, LockOn);
	self.combat = combat;
	
	self.lock_on = false;
	self.lock_on_target = nil;
	
	self.lock_on_speed = 0.2 --0.15
	
	self.combat.OnDeviceChanged:Connect(function(Device : string)
		if Device ~= "Controller" and self.lock_on then
			self:reset_lock_on()
		end
	end)
	
	UserInputService.InputBegan:Connect(function(Input, Typing)
		if Input.KeyCode == Enum.KeyCode.DPadDown and not Typing then
			if self.lock_on then
				self:reset_lock_on()
			else
				local humanoid : Humanoid? = AimAssist.get(30, 200, CollectionService:GetTagged("ManHumanoid"))

				if humanoid then
					self:set_lock_on(humanoid)
				end
			end
		end
	end)
	
	return self;
	
end;

function LockOn:update_camera(delta : number)
	if not self.lock_on_target then return end;

	local camera = workspace.CurrentCamera;
	local current_look_vector : Vector3 = (self.lock_on_target.Position - camera.CFrame.Position).Unit
	local current_pitch_angle = math.asin(current_look_vector.Y)
	local y_theta = math.clamp(YThetaClamp, -MinYAngle + current_pitch_angle, MaxYAngle + current_pitch_angle)
	local constrained_rotate_input = Vector2.new(0, y_theta)
	local start_cframe = CFrame.lookAt(Vector3.zero, current_look_vector)

	local new_look_cframe = CFrame.Angles(0, -constrained_rotate_input.X, 0) * start_cframe * CFrame.Angles(-constrained_rotate_input.Y, 0, 0);
	camera.CFrame = camera.CFrame.Rotation:Lerp(new_look_cframe, math.clamp(self.lock_on_speed * (delta * 60), 0, 1)) + camera.CFrame.Position;
end

function LockOn:reset_lock_on()
	if self.lock_on_target then
		task.spawn(LockOnEffect, self.lock_on_target, false);
	end
	
	if self.on_target_gone and self.on_target_gone.Connected then
		self.on_target_gone:Disconnect();
		self.on_target_gone = nil;
	end;
	
	self.lock_on = false;
	self.on_target_gone = nil;
	self.lock_on_target = nil;
	
	RunService:UnbindFromRenderStep("GamepadLockOn");
end

function LockOn:set_lock_on(humanoid : Humanoid)
	if (humanoid ~= nil and humanoid.Parent ~= nil and humanoid.RootPart) then
		self.lock_on = true;
		self.lock_on_target = humanoid.RootPart;

		task.spawn(function()
			self.on_target_gone = self.lock_on_target.AncestryChanged:Connect(function(_, Parent)
				if (Parent == nil) then
					self:reset_lock_on();
				end;
			end);
		end)
		
		RunService:BindToRenderStep("GamepadLockOn", Enum.RenderPriority.Camera.Value - 1, function(delta)
			self:update_camera(delta);
		end);

		task.spawn(LockOnEffect, self.lock_on_target, true);
	end
end

table.freeze(LockOn);

return LockOn;