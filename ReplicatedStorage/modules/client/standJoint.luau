local replicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

--------------------------------------------------------------------------------------------

local Maid = require( replicatedStorage.packages.Maid )
local CFSpring = require( replicatedStorage.packages.Spring.CFSpring )

--------------------------------------------------------------------------------------------

local StandJointTag = "StandJoint";

--------------------------------------------------------------------------------------------

export type ClassStandJoint = {
	__index: ClassStandJoint;

	new: (motor: Motor6D) -> StandJoint;
	destroy: (self: StandJoint) -> ();
	initialise: (self: StandJoint) -> ();
	step: (self: StandJoint, dt: number) -> ();
};

export type StandJoint = typeof(setmetatable({} :: {
	motor: Motor6D;
	maid: Maid.Maid;
	attributes: {[string]: any};

}, {} :: ClassStandJoint));

--------------------------------------------------------------------------------------------

local StandJoint = {};
StandJoint.__index = StandJoint;
StandJoint.pool = {};

function StandJoint.new(motor: Motor6D)
	assert(not StandJoint.pool[motor], "Motor already has an associated StandJoint object");

	local maid = Maid.new();

	local self = setmetatable(
		{
			motor = motor;
			maid = maid;
			attributes = motor:GetAttributes();
			moving_cframe = CFrame.identity;
		}, 
		StandJoint);

	self:initialise();

	return self;
end;

function StandJoint:destroy()
	StandJoint.pool[self.motor] = nil;
	self.maid:destroy();
end

function StandJoint:initialise()
	StandJoint.pool[self.motor] = self;

	self.maid:add(self.motor.AttributeChanged:Connect(function(attribute)
		self.attributes[attribute] = self.motor:GetAttribute(attribute);
	end))
end

function StandJoint:step(dt: number)
	if self.attributes.Disabled then
		self.moving_cframe = self.moving_cframe:Lerp(CFrame.identity, 0.1 * (dt * 60));
	else
		local part0 = self.motor.Part0;
		local part1 = self.motor.Part1;

		if part0 and part1 then
			local alpha = 1 - math.exp(-self.attributes.Speed * dt);
			local velocity = part0.CFrame:VectorToObjectSpace(part0.AssemblyLinearVelocity * self.attributes.Aggression);
			local direction = CFrame.lookAlong(velocity, part1.CFrame.LookVector);

			if direction ~= direction then
				direction = part1.CFrame.Rotation;
			end;

			self.moving_cframe = self.moving_cframe:Lerp(direction, alpha);

			local moving = self.moving_cframe * part1.CFrame.Rotation:Inverse();

			self.motor.Transform = (moving.Rotation:Inverse() + moving.Position) * self.attributes.Offset;
		end
	end
end

--------------------------------------------------------------------------------------------

table.freeze(StandJoint);

--------------------------------------------------------------------------------------------

CollectionService:GetInstanceAddedSignal(StandJointTag):Connect(function(motor)
	StandJoint.new(motor);
end)

CollectionService:GetInstanceRemovedSignal(StandJointTag):Connect(function(motor)
	if StandJoint.pool[motor] then
		StandJoint.pool[motor]:destroy();
	end;
end)

for _, motor in CollectionService:GetTagged(StandJointTag) do
	task.spawn(StandJoint.new, motor);
end;

RunService.PreSimulation:Connect(function(dt)
	for motor, stand_joint in StandJoint.pool do
		stand_joint:step(dt);
	end
end)

--------------------------------------------------------------------------------------------

return StandJoint;