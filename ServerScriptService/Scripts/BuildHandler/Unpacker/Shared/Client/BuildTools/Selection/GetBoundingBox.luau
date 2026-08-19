
local ToObjSpace = CFrame.identity.ToObjectSpace;
local GetComponents = CFrame.identity.GetComponents;
local PointToWorldSpace = CFrame.identity.PointToWorldSpace;

local inf = math.huge;
local negInf = -inf;

return function(instances: {[Instance]: any}, orientation: CFrame): (CFrame, Vector3)
	local minx, miny, minz, maxx, maxy, maxz = inf, inf, inf, negInf, negInf, negInf;

	local function calculate(cf: CFrame, size: Vector3): ()
		local sx, sy, sz = size.X, size.Y, size.Z;
		local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = GetComponents(cf);

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

	local function recursive_find(instance: Instance): ()
		if instance:IsA("Model") then
			calculate(instance:GetBoundingBox());

		elseif instance:IsA("BasePart") then
			calculate(ToObjSpace(orientation, instance.CFrame), instance.Size);

			for _, part2 in instance:GetChildren() do
				recursive_find(part2);
			end;
		end;
	end;

	for part in instances do
		recursive_find(part);
	end;

	local omin, omax = Vector3.new(minx, miny, minz), Vector3.new(maxx, maxy, maxz);
	return orientation - orientation.Position + PointToWorldSpace(orientation, (omax + omin) * 0.5), (omax - omin);
end;