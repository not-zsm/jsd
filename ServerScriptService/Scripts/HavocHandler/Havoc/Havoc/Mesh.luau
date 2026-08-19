local Types = require("./Types");

-------------------------------------------------------------------------------------------

type SliceInfo = Types.SliceInfo;

-------------------------------------------------------------------------------------------

local Mesh = {};

@native function Mesh.try_mesh_slices(slice_A: SliceInfo, slice_B: SliceInfo, tolerance: number): SliceInfo?
	local rotation_A: CFrame = slice_A.coordinate.Rotation;
	
	-- Transform positions to object space of slice A
	local pos_A: Vector3 = rotation_A:PointToObjectSpace(slice_A.coordinate.Position);
	local pos_B: Vector3 = rotation_A:PointToObjectSpace(slice_B.coordinate.Position);
	
	local min_A: Vector3 = pos_A - slice_A.size * 0.5;
	local max_A: Vector3 = pos_A + slice_A.size * 0.5;
	local min_B: Vector3 = pos_B - slice_B.size * 0.5;
	local max_B: Vector3 = pos_B + slice_B.size * 0.5;

	-- Try merge along X axis (slices are adjacent along X and aligned on Y/Z)
	local aligned_Y: boolean = math.abs(min_A.Y - min_B.Y) < tolerance and math.abs(max_A.Y - max_B.Y) < tolerance;
	local aligned_Z: boolean = math.abs(min_A.Z - min_B.Z) < tolerance and math.abs(max_A.Z - max_B.Z) < tolerance;

	if aligned_Y and aligned_Z and (math.abs(max_A.X - min_B.X) < tolerance or math.abs(max_B.X - min_A.X) < tolerance) then
		local newMinX = math.min(min_A.X, min_B.X);
		local newMaxX = math.max(max_A.X, max_B.X);

		return {
			coordinate = rotation_A + (rotation_A * Vector3.new((newMinX + newMaxX) * 0.5, pos_A.Y, pos_A.Z)),
			size = Vector3.new(newMaxX - newMinX, slice_A.size.Y, slice_A.size.Z)
		};
	end;

	-- Try merge along Y axis (slices are adjacent along Y and aligned on X/Z)
	local aligned_X: boolean = math.abs(min_A.X - min_B.X) < tolerance and math.abs(max_A.X - max_B.X) < tolerance

	if aligned_X and aligned_Z and (math.abs(max_A.Y - min_B.Y) < tolerance or math.abs(max_B.Y - min_A.Y) < tolerance) then
		local newMinY = math.min(min_A.Y, min_B.Y);
		local newMaxY = math.max(max_A.Y, max_B.Y);

		return {
			coordinate = rotation_A + (rotation_A * Vector3.new(pos_A.X, (newMinY + newMaxY) * 0.5, pos_A.Z)),
			size = Vector3.new(slice_A.size.X, newMaxY - newMinY, slice_A.size.Z)
		};
	end;

	-- Try merge along Z axis (slices are adjacent along Z and aligned on X/Y)
	if aligned_X and aligned_Y and (math.abs(max_A.Z - min_B.Z) < tolerance or math.abs(max_B.Z - min_A.Z) < tolerance) then
		local newMinZ = math.min(min_A.Z, min_B.Z);
		local newMaxZ = math.max(max_A.Z, max_B.Z);

		return {
			coordinate = rotation_A + (rotation_A * Vector3.new(pos_A.X, pos_A.Y, (newMinZ + newMaxZ) * 0.5)),
			size = Vector3.new(slice_A.size.X, slice_A.size.Y, newMaxZ - newMinZ)
		};
	end;

	-- No merge possible
	return nil;
end;

--[[
	Greedy mesh a list of slices. The higher the 'batch' parameter is, the more merges that can be done at the cost of performance.
]]
@native function Mesh.greedy_mesh_slices(slices: {SliceInfo}, batch: number, mesh_start: number): {SliceInfo}
	-- Avoid greedy meshing when theres nothing to combine.
	if #slices <= 1 then
		return slices;
	end;
	
	local to_combine;
	
	if (#slices - mesh_start) >= batch then
		to_combine = Mesh.greedy_mesh_slices(slices, batch, mesh_start + batch + 1);
	end;
	
	debug.profilebegin("GreedyMesh");
	
	local tolerance = 0.005;
	local changed = true;
	local merged = slices;
	local mesh_end = math.min(#slices, mesh_start + batch);
	local total_size = math.max(1, mesh_end - mesh_start);
	
	while changed do
		changed = false;
		
		local new_merged = table.create(total_size);
		local used = table.create(total_size, false)
		
		for index = mesh_start, mesh_end do
			if used[index] then continue end;
			
			local current = merged[index];
			
			for new_index = total_size, index + 1, -1 do
				if used[new_index] then continue end;
				
				local new_slice = Mesh.try_mesh_slices(current, merged[new_index], tolerance);
				
				if new_slice then
					current = new_slice;
					used[new_index] = true;
					changed = true;
				end;
			end;
			
			table.insert(new_merged, current);
		end;
		
		merged = new_merged;
		total_size = #new_merged;
	end;
	
	if to_combine then
		table.move(to_combine, 1, #to_combine, #merged + 1, merged);
	end;
	
	debug.profileend();

	return merged;
end;

table.freeze(Mesh);

return Mesh
