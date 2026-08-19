--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Emit = require("../Emit");

local Velocities = {};
local Identifiers: {[number]: LinearVelocity} = {};

function Velocities.remove(id: number)
	if Identifiers[id] then
		Identifiers[id]:Destroy();
		Identifiers[id] = nil;
	end;
end;

function Velocities.gravity(part: BasePart, alpha: number, duration: number?): VectorForce
	local mass_attachment = Instance.new("Attachment")
	mass_attachment.Parent = part;
	
	local force = Instance.new("VectorForce");
	force.ApplyAtCenterOfMass = true;
	force.Force = Vector3.yAxis * part.AssemblyMass * alpha;
	force.Attachment0 = mass_attachment;
	force.Parent = part;
	
	force.Destroying:Once(function()
		mass_attachment:Destroy();
	end);
	
	if duration then
		task.delay(duration, function()
			force:Destroy();
		end);
	end;
	
	return force;
end

function Velocities.simple(part: BasePart, velocity: Vector3, duration: number?): LinearVelocity
	local mass_attachment = Instance.new("Attachment")
	mass_attachment.Parent = part;

	local velocity_mover = Instance.new("LinearVelocity");
	velocity_mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector;
	velocity_mover.ForceLimitMode = Enum.ForceLimitMode.PerAxis;
	velocity_mover.RelativeTo = Enum.ActuatorRelativeTo.World;
	velocity_mover.MaxAxesForce = Vector3.one * 300_000;
	velocity_mover.Attachment0 = mass_attachment;
	velocity_mover.VectorVelocity = velocity;
	velocity_mover.Parent = part;
	
	mass_attachment.Parent = part;
	
	velocity_mover.Destroying:Once(function()
		mass_attachment:Destroy();
	end);
	
	if duration then
		task.delay(duration, function()
			velocity_mover:Destroy();
		end);
	end;
	
	return velocity_mover;
end

function Velocities.apply(id: number?, attachment: Attachment, velocity: Vector3, axes: Vector3, max_force: number, duration: number, tapering: NumberSequence, is_aligned: boolean)
	local root_part = attachment.Parent;
	assert(root_part and root_part:IsA("BasePart"), "No RootPart");
	
	if not tapering then
		tapering = NumberSequence.new(1);
	end;
	
	if duration > 0 then
		local mass_attachment = Instance.new("Attachment")
		mass_attachment.Name = "CenterOfMassAttachment"
		mass_attachment.CFrame = CFrame.identity;
		mass_attachment.Parent = root_part;
		
		local velocity_mover = Instance.new("LinearVelocity");
		velocity_mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector;
		velocity_mover.ForceLimitMode = Enum.ForceLimitMode.PerAxis;
		velocity_mover.RelativeTo = Enum.ActuatorRelativeTo.World;
		velocity_mover.Attachment0 = mass_attachment;
		velocity_mover.MaxAxesForce = axes * max_force;
		
		if id then
			Identifiers[id] = velocity_mover;
		end
		
		if is_aligned then
			velocity_mover.RelativeTo = Enum.ActuatorRelativeTo.Attachment0;
		else
			velocity_mover.RelativeTo = Enum.ActuatorRelativeTo.World;
		end;
		
		local elapsed = 0;
		
		local function update_velocity(dt: number)
			elapsed += dt;
			mass_attachment.WorldPosition = root_part.AssemblyCenterOfMass;
			
			local taper = Emit.EvaluateNumberSequence(tapering, elapsed / duration);
			velocity_mover.VectorVelocity = velocity * taper;
		end;
		
		update_velocity(0);
		local connection = RunService.PreSimulation:Connect(update_velocity);
		
		velocity_mover.Destroying:Once(function()
			connection:Disconnect();
			mass_attachment:Destroy();
			
			if id then
				Identifiers[id] = nil;
			end;
		end);
		
		task.delay(duration, function()
			velocity_mover:Destroy();
		end);
		
		velocity_mover.Parent = mass_attachment;
	else
		root_part.AssemblyLinearVelocity += velocity;
	end;
end;

table.freeze(Velocities);

return Velocities;