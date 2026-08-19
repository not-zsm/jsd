local Assets = script.Parent.Assets;

local VectorXZ = Vector3.new(1, 0, 1);

local DomainWorld = {};
DomainWorld.__index = DomainWorld;

function DomainWorld.new(model, position)
	assert(workspace.Domains, "No Domain Folder");
	
	model.Name = "Domain";
	
	if model.Parent ~= workspace.Domains then
		model.Parent = workspace.Domains;
	end;
	
	local self = setmetatable(
		{
			model = model;
			collision_sphere = model.CollisionSphere;
			collision_world_sphere = model.World.CollisionSphere;
			plane = model.World.Plane;
			position = position;
			size = 100;
			world_size = 512;
			offset_scale = 0.75;
		}, 
		DomainWorld);
	
	return self;
end;

function DomainWorld:destroy()
	
end

function DomainWorld:set_world_size(size: number): ()
	self.world_size = size;
	self.collision_world_sphere.Size = Vector3.one * self.world_size;
end

function DomainWorld:distance_from(coordinate: CFrame): number
	return (self.position - coordinate.Position).Magnitude;
end;

function DomainWorld:distance_from_world(coordinate: CFrame)
	return (self.collision_world_sphere.Position - coordinate.Position).Magnitude;
end

function DomainWorld:inside_of(coordinate: CFrame, tolerance: number?): boolean
	return (self.position - coordinate.Position).Magnitude < self.size * 0.50 + (tolerance or 0);
end;

function DomainWorld:inside_of_world(coordinate: CFrame, tolerance: number?): boolean
	return (self.collision_world_sphere.Position - coordinate.Position).Magnitude < self.world_size * 0.50 + (tolerance or 0);
end;

function DomainWorld:get_position(inside: (boolean | Model)?): Vector3
	if typeof(inside) == "Instance" then
		return inside:GetPivot().Position + Vector3.new(0, self.plane.Size.Y / 2, 0) + Vector3.new(0, 2.5, 0);
	
	elseif inside then
		return self.plane.Position + Vector3.new(0, self.plane.Size.Y / 2, 0) + Vector3.new(0, 2.5, 0);
	else
		return self.position + Vector3.new(0, 2.5, 0);
	end;
end;

function DomainWorld:get_polar_offset_xz(origin: Vector3, target: Vector3, size: number, offset_size: number?): Vector3
	local offset_size = offset_size or 0;
	local direction = (target - origin) * Vector3.one -- * VectorXZ;
	local magnitude = direction.Magnitude;
	
	return direction.Unit * math.clamp( (magnitude + offset_size) / size, 0, 1 );
end;

function DomainWorld:to_polar_offset_xz(origin: Vector3, polar: Vector3, size: number)
	return origin + polar * size;
end;

function DomainWorld:translate_polar_offset(p0: Vector3, p1: Vector3, t0: Vector3, size1: number, size2: number, offset1: number)
	return self:to_polar_offset_xz( p1, self:get_polar_offset_xz( p0, t0, size1, offset1), size2 );
end;

function DomainWorld:teleport(character: any, coordinate: CFrame): ()
	local transition_tag = "TransitionDomain";
	local value = character:GetAttribute(transition_tag) or 0;
	
	local root_part = character:FindFirstChild("HumanoidRootPart");
	
	if root_part then
		root_part.AssemblyLinearVelocity = Vector3.zero;
		root_part.AssemblyAngularVelocity = Vector3.zero;
	end;
	
	character:SetAttribute(transition_tag, value + 1);
	character:PivotTo(coordinate);
	
	task.delay(1, function()
		local value = character:GetAttribute(transition_tag) or 0;

		if value <= 1 then
			character:SetAttribute(transition_tag, nil);
		else
			character:SetAttribute(transition_tag, value - 1);
		end
	end)
end;

function DomainWorld:teleport_world(character: any, current_center: Vector3, target_center: Vector3, world_space: ("Out" | "In" | "None")): ()
	local origin = character.HumanoidRootPart.CFrame;
	local offset = Vector3.zero;
	
	if world_space == "In" then
		offset = self:translate_polar_offset(current_center, target_center, origin, self.size, self.size, -0); -- 12
		
	elseif world_space == "Out" then
		offset = self:translate_polar_offset(current_center, target_center, origin, self.size, self.size, -0); -- 12
		
	elseif world_space == "None" then
		offset = self:translate_polar_offset(current_center, target_center, origin, self.size, self.size, 0);
	end;
	
	self:teleport(character, origin.Rotation + offset);
end;

table.freeze(DomainWorld);

return DomainWorld;