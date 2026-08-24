local bufferWriter = require(script.Parent.Parent.process.bufferWriter)
local types = require(script.Parent.Parent.types)

local f32NoAlloc = bufferWriter.f32NoAlloc
local alloc = bufferWriter.alloc

-- thanks jack :p
local cframe = {
	read = function(b: buffer, cursor: number)
		local x = buffer.readf32(b, cursor)
		local y = buffer.readf32(b, cursor + 4)
		local z = buffer.readf32(b, cursor + 8)
		local rx = buffer.readf32(b, cursor + 12)
		local ry = buffer.readf32(b, cursor + 16)
		local rz = buffer.readf32(b, cursor + 20)

		-- Re-construct the CFrame from the axis-angle representation
		local axis = Vector3.new(rx, ry, rz)
		local angle = axis.Magnitude

		-- an identity rotation leaves no axis to normalise, and fromAxisAngle
		-- hands back a NaN CFrame rather than the identity it was given
		if (angle == 0) then
			return CFrame.new(x, y, z), 24
		end

		return CFrame.fromAxisAngle(axis, angle) + Vector3.new(x, y, z), 24
	end,
	write = function(value: CFrame)
		-- Convert the CFrame to an axis-angle representation
		local x, y, z = value.X, value.Y, value.Z

		-- the reader takes the angle back off the magnitude, so scale before
		-- splitting. An identity rotation has no meaningful axis, so zero it
		-- rather than trust whatever ToAxisAngle picked to stand in for one
		local axis, angle = value:ToAxisAngle()
		local rx, ry, rz = 0, 0, 0

		if (angle ~= 0) and (angle == angle) then
			axis = axis * angle
			rx, ry, rz = axis.X, axis.Y, axis.Z
		end

		-- Math done, write it now
		alloc(24)
		f32NoAlloc(x)
		f32NoAlloc(y)
		f32NoAlloc(z)
		f32NoAlloc(rx)
		f32NoAlloc(ry)
		f32NoAlloc(rz)
	end,
}

return function(): types.dataTypeInterface<CFrame>
	return cframe
end