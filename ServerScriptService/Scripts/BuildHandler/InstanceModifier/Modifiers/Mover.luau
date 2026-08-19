local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Serialise = require( "../../Serialise" )
local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );
local Instances = require( Unpacker.Packages.Instances );

local BufferUtil = require( ReplicatedStorage.Packages.BufferUtil )
local MotorTween = Unpacker.Remotes.Effects.MotorTween;

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Moves the reference part from start to end.";
TagModifier.icon = 11769203234;
TagModifier.color = Color3.fromRGB(0, 218, 229)
TagModifier.section = 2;
TagModifier.use_prompt = false;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	EasingStyle = {
		Default = Enum.EasingStyle.Linear;
	};
	EasingDirection = {
		Default = Enum.EasingDirection.Out;
	};
	Time = {
		Default = 1;
	};
	Part = {
		Default = nil;
		Type = Type.Instance()
	};
	Start = {
		Default = nil;
		Type = Type.Instance()
	};
	End = {
		Default = nil;
		Type = Type.Instance()
	};
	TwoWay = {
		Default = true;
	};
	C0 = {
		Default = Vector3.zero;
	};
};

local function get_motor(self, part: BasePart): Motor6D
	local existing_motor = if part then part:FindFirstChild("MoverMotor") else nil;

	if existing_motor then
		return existing_motor;
	else
		return self.tween_motor;
	end;
end;

local function get_refs(self, data)
	if not data then
		data = self.attributes:all();
	end;
	
	local origin = data.Start or self.part;
	local part = data.Part;
	local target = data.End or origin;
	
	return part, origin, target;
end;

local function transition_motor(self, active: boolean, tweened: boolean)
	local data = self.attributes:all();
	local part, expected_origin, expected_target = get_refs(self, data);

	-- Redeploy the motor
	do
		local existing_motor = get_motor(self, part);

		if self.tween_motor ~= existing_motor then
			self.tween_motor.Part0 = nil;
			self.tween_motor.Part1 = nil;
			self.tween_motor.Parent = nil;
		else
			existing_motor.Part1 = expected_origin;
		end

		existing_motor.Part0 = part;
		existing_motor.Parent = part;
	end

	if part and (data.TwoWay or active) then
		local motor = get_motor(self, part);

		local origin = motor.Part1;
		local target = expected_target;

		local move_to_part = if active then expected_target else expected_origin;
		local move_to_cframe: CFrame = Instances.cframe(move_to_part);
		local origin_cframe: CFrame = Instances.cframe(origin);

		if move_to_cframe then

			-- New CFrame thats relative to Part0 of the Motor6D
			local motor_aligned_cframe: CFrame = move_to_cframe:ToObjectSpace(origin.CFrame);

			motor.C0 = CFrame.new(data.C0)

			--origin.Anchored = true;
			part.Anchored = false;

			if tweened then
				local tween_info = TweenInfo.new(data.Time, data.EasingStyle, data.EasingDirection);
				local goal = {Transform = motor_aligned_cframe};

				TweenService:Create(motor, tween_info, goal):Play();

				local packet = BufferUtil.create(BufferUtil.cframe.size + BufferUtil.tween_info.size);
				BufferUtil.write_cframe(packet, motor_aligned_cframe);
				BufferUtil.write_tween_info(packet, tween_info);
				BufferUtil.truncate(packet);

				MotorTween:FireAllClients(motor, packet.buffer);
			else
				motor.Transform = motor_aligned_cframe;
				MotorTween:FireAllClients(motor, motor_aligned_cframe);
			end;

			motor:SetAttribute("TargetTransform", motor_aligned_cframe);
		end;
	end;
end

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	self.pulse_on_powered = false;
	
	self.tween_motor = Instance.new("Motor6D");
	self.tween_motor.Name = "MoverMotor";
	self.tween_motor.Archivable = false;
	self.tween_motor:AddTag("TweenMotor");
	
	task.defer(transition_motor, self, false, false);
	
	return self;
end

function TagModifier.attribute_updates:C0(value)
	self.tween_motor.C0 = CFrame.new(value);
end;

function TagModifier:pulse(signal, chain)
	if not self.attributes:get("TwoWay")  then
		transition_motor(self, true, true);
	else
		return InstanceModifier.pulse(self, signal, chain);
	end;
end;

function TagModifier:on_active_changed()
	transition_motor(self, self.active, true);
end;

function TagModifier:destroy()
	local tween_motor = self.tween_motor;
	
	InstanceModifier.destroy(self);
	tween_motor:Destroy();
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;