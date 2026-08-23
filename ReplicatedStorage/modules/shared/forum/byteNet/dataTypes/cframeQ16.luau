local bufferWriter = require(script.Parent.Parent.process.bufferWriter)
local types = require(script.Parent.Parent.types)

local f32 = bufferWriter.f32
local i16 = bufferWriter.i16

local SCALE = 32767 / math.pi
local INVERSE = math.pi / 32767

local cframeQ16 = {
	read = function(b: buffer, cursor: number)
		local x = buffer.readf32(b, cursor)
		local y = buffer.readf32(b, cursor + 4)
		local z = buffer.readf32(b, cursor + 8)

		local rx = buffer.readi16(b, cursor + 12) * INVERSE
		local ry = buffer.readi16(b, cursor + 14) * INVERSE
		local rz = buffer.readi16(b, cursor + 16) * INVERSE

		return CFrame.fromOrientation(rx, ry, rz) + Vector3.new(x, y, z), 18
	end,

	write = function(value: CFrame)
		local rx, ry, rz = value:ToOrientation()

		f32(value.X)
		f32(value.Y)
		f32(value.Z)

		i16(math.clamp(math.round(rx * SCALE), -32767, 32767))
		i16(math.clamp(math.round(ry * SCALE), -32767, 32767))
		i16(math.clamp(math.round(rz * SCALE), -32767, 32767))
	end,
}

return function(): types.dataTypeInterface<CFrame>
	return cframeQ16
end
