--[[
	Luau based spatial volume functions to check intersection between two volumes.
]]

-------------------------------------------------------------------------------------------

local TWO_PI = 2 * math.pi;
local CYLINDER_HEIGHT_SAMPLES = 6;

local Types = require("./Types")

local corners1 = table.create(8);
local corners2 = table.create(8);

-------------------------------------------------------------------------------------------

local Spatial = {};

Spatial.vertices_x = {
	Vector3.new(0, -1, 1),
	Vector3.new(0, 1, 1),
	Vector3.new(0, -1, -1),
	Vector3.new(0, 1, -1),
};

Spatial.vertices_y = {
	Vector3.new(-1, 0, 1),
	Vector3.new(1, 0, -1),
	Vector3.new(1, 0, 1),
	Vector3.new(-1, 0, -1),
};

Spatial.vertices_z = {
	Vector3.new(1, -1, 0),
	Vector3.new(1, 1, 0),
	Vector3.new(-1, -1, 0),
	Vector3.new(-1, 1, 0),
};

Spatial.vertices = {
	Vector3.new(1, 1, -1),  --v1 - top front right
	Vector3.new(1, -1, -1), --v2 - bottom front right
	Vector3.new(-1, -1, -1),--v3 - bottom front left
	Vector3.new(-1, 1, -1), --v4 - top front left
	Vector3.new(1, 1, 1),  --v5 - top back right
	Vector3.new(1, -1, 1), --v6 - bottom back right
	Vector3.new(-1, -1, 1),--v7 - bottom back left
	Vector3.new(-1, 1, 1)  --v8 - top back left
};

Spatial.half_vertices = table.create(8, Vector3.zero);

for index, vertice in Spatial.vertices do
	Spatial.half_vertices[index] = vertice / 2.0;
end

-------------------------------------------------------------------------------------------

-- Projection of SAT
@native local function project_onto_axis(axis: Vector3, corners: {Vector3}): (number, number)
	local min, max = math.huge, -math.huge;
	
	for index, corner in corners do
		local p = corner:Dot(axis);
		if p < min then min = p end;
		if p > max then max = p end;
	end
	
	return min, max;
end

-- Detecting if two volumes (between box and box) are touching using the Separating Axis Theorem (SAT).
@native function Spatial.is_touching(cframe1: CFrame, size1: Vector3, cframe2: CFrame, size2: Vector3): boolean
	for index, vertice in Spatial.half_vertices do
		corners1[index] = cframe1 * (vertice * size1)
		corners2[index] = cframe2 * (vertice * size2)
	end
	
	local min1: number, max1: number;
	local min2: number, max2: number;

	for _, axis in {
		cframe1.RightVector,
		cframe1.UpVector,
		cframe1.LookVector,
		cframe2.RightVector,
		cframe2.UpVector,
		cframe2.LookVector,
	} do
		min1, max1 = project_onto_axis(axis, corners1)
		min2, max2 = project_onto_axis(axis, corners2)

		if max1 < min2 or max2 < min1 then
			return false
		end
	end
	
	return true
end

-- Detecting if two volumes (between a box and sphere) are touching.
@native function Spatial.in_radius(box_coordinate: CFrame, box_size: Vector3, sphere_origin: Vector3, sphere_radius: number): boolean
	local sphere_relative = box_coordinate:PointToObjectSpace(sphere_origin)
	local half_size = box_size * 0.5;
	local min_box, max_box = -half_size, half_size;

	local closest_sphere_point = Vector3.new(
		math.clamp(sphere_relative.X, min_box.X, max_box.X),
		math.clamp(sphere_relative.Y, min_box.Y, max_box.Y),
		math.clamp(sphere_relative.Z, min_box.Z, max_box.Z));

	return (sphere_origin - box_coordinate * closest_sphere_point).Magnitude < sphere_radius;
end


-- Detecting if two volumes (between a box and cylinder) are touching.
-- This spatial method uses an approximation, so it will not be calculated with full accuracy.
function Spatial.is_touching_cylinder(box_cframe: CFrame, box_size: Vector3, cylinder_cframe: CFrame, cylinder_height: number, cylinder_radius: number): boolean
	local half_box = box_size * 0.5;
	local cylinder_axis = cylinder_cframe.UpVector;
	local cylinder_half_height = cylinder_height * 0.5;
	
	for index, vertice in Spatial.vertices do
		corners1[index] = box_cframe * (vertice * half_box)
	end

	-- Check if any box corner is inside the cylinder
	for _, point in corners1 do
		local direction_to = point - cylinder_cframe.Position;
		local height_projection = direction_to:Dot(cylinder_axis);
		
		if math.abs(height_projection) < cylinder_half_height and (direction_to - cylinder_axis * height_projection).Magnitude < cylinder_radius then
			return true;
		end;
	end;
	
	for index = -1, 1, 1 / CYLINDER_HEIGHT_SAMPLES do
		local alpha = index * cylinder_half_height;
		local point_on_axis = cylinder_cframe.Position + cylinder_axis * alpha;

		local local_point = box_cframe:PointToObjectSpace(point_on_axis);
		
		local closest_world = box_cframe:PointToWorldSpace(Vector3.new(
			math.clamp(local_point.X, -half_box.X, half_box.X),
			math.clamp(local_point.Y, -half_box.Y, half_box.Y),
			math.clamp(local_point.Z, -half_box.Z, half_box.Z)
		))
		
		if (closest_world - point_on_axis).Magnitude < cylinder_radius then
			return true;
		end;
	end;
	
	return false;
end;


-- Gets the bounding box of a collection of parts.
-- Returns the origin and the size of the bounding box.
function Spatial.get_parts_bounding_box(parts: {BasePart}, orientation: CFrame): (CFrame, Vector3)
	local minx, miny, minz, maxx, maxy, maxz = math.huge, math.huge, math.huge, -math.huge, -math.huge, -math.huge;

	for _, part in parts do
		local cf, size = part.CFrame, part.Size;
		local sx, sy, sz = size.X, size.Y, size.Z;
		local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents();

		local wsx = 0.5 * (math.abs(R00) * sx + math.abs(R01) * sy + math.abs(R02) * sz);
		local wsy = 0.5 * (math.abs(R10) * sx + math.abs(R11) * sy + math.abs(R12) * sz);
		local wsz = 0.5 * (math.abs(R20) * sx + math.abs(R21) * sy + math.abs(R22) * sz);

		minx = if minx > x - wsx then x - wsx else minx;
		miny = if miny > y - wsy then y - wsy else miny;
		minz = if minz > z - wsz then z - wsz else minz;
		maxx = if maxx < x + wsx then x + wsx else maxx;
		maxy = if maxy < y + wsy then y + wsy else maxy;
		maxz = if maxz < z + wsz then z + wsz else maxz;
	end;

	local omin, omax = Vector3.new(minx, miny, minz), Vector3.new(maxx, maxy, maxz);

	return orientation.Rotation + orientation:PointToWorldSpace((omax + omin) * 0.5), (omax - omin);
end;


-- Gets the bounding box of the given slices.
-- Returns the origin and the size of the bounding box.
function Spatial.get_bounding_box(array_slices: {{Types.SliceInfo}}, orientation: CFrame): (CFrame, Vector3)
	local minx, miny, minz, maxx, maxy, maxz = math.huge, math.huge, math.huge, -math.huge, -math.huge, -math.huge;

	for _, slice_parts in array_slices do
		for _, slice in slice_parts do
			local cf, size = slice.coordinate, slice.size;
			local sx, sy, sz = size.X, size.Y, size.Z;
			local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents();

			local wsx = 0.5 * (math.abs(R00) * sx + math.abs(R01) * sy + math.abs(R02) * sz);
			local wsy = 0.5 * (math.abs(R10) * sx + math.abs(R11) * sy + math.abs(R12) * sz);
			local wsz = 0.5 * (math.abs(R20) * sx + math.abs(R21) * sy + math.abs(R22) * sz);

			minx = if minx > x - wsx then x - wsx else minx;
			miny = if miny > y - wsy then y - wsy else miny;
			minz = if minz > z - wsz then z - wsz else minz;
			maxx = if maxx < x + wsx then x + wsx else maxx;
			maxy = if maxy < y + wsy then y + wsy else maxy;
			maxz = if maxz < z + wsz then z + wsz else maxz;
		end;
	end;

	local omin, omax = Vector3.new(minx, miny, minz), Vector3.new(maxx, maxy, maxz);
	
	return orientation.Rotation + orientation:PointToWorldSpace((omax + omin) * 0.5), (omax - omin);
end

-------------------------------------------------------------------------------------------

table.freeze(Spatial)

return Spatial;