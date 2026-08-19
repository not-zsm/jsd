--!native
--!optimize 2

--[[
	A cursor based wrapper for buffers, contains reading/writing of Roblox DataTypes.
]]

---------------------------------------------------------------------------------

export type CursorBuffer = {
	cursor: number;
	size: number;
	buffer: buffer;
};

---------------------------------------------------------------------------------

local i24 = 2^24;
local i23 = 2^23;
local i8 = 256;
local thousand = 1000;

---------------------------------------------------------------------------------

local function readi16AsFloat(b: buffer, cursor: number): number
	local i16 = buffer.readi16(b, cursor);
	return i16 / thousand;
end

local function writeFloatAsi16(b: buffer, cursor: number, value: number): ()
	local toWrite = value * thousand;
	buffer.writei16(b, cursor, toWrite);
end

local function writei24(b: buffer, cursor: number, value: number): ()
	if value < 0 then
		value = value + i24
	end

	buffer.writeu16(b, cursor, value / i8);
	buffer.writeu8(b, cursor + 2, value % i8);
end

local function readi24(b: buffer, cursor: number): number
	local value: number = i8 * buffer.readu16(b, cursor) + buffer.readu8(b, cursor + 2)

	if value >= i23 then
		return value - i24
	end;

	return value;
end

---------------------------------------------------------------------------------

local BufferUtil = {};

-- Creates a CursorBuffer wrapper for the passed buffer <strong>b</strong>.
function BufferUtil.new(b: buffer): CursorBuffer
	return {
		cursor = 0;
		size = buffer.len(b);
		buffer = b;
	}
end

-- Creates a CursorBuffer wrapper for a newly created buffer of size <strong>size</strong>.
function BufferUtil.create(size: number): CursorBuffer
	return {
		cursor = 0;
		size = size;
		buffer = buffer.create(size);
	};
end

---------------------------------------------------------------------------------


-- Allocates a number of bytes <strong>bytes</strong> after the cursor. Does not allocate if there is a sufficient number of bytes after the cursor.  
function BufferUtil.allocate(cursor_buffer: CursorBuffer, bytes: number): ()
	if not (cursor_buffer.cursor + bytes >= cursor_buffer.size) then
		return
	end

	while cursor_buffer.cursor + bytes >= cursor_buffer.size do
		cursor_buffer.size *= 2
	end
	
	local new_b = buffer.create(cursor_buffer.size)
	buffer.copy(new_b, 0, cursor_buffer.buffer)
	
	cursor_buffer.buffer = new_b;
end


-- Allocates an additional number of bytes <strong>bytes</strong> independant of the cursor.
function BufferUtil.dynallocate(cursor_buffer: CursorBuffer, bytes: number): ()
	cursor_buffer.size += bytes;
	
	local new_b = buffer.create(cursor_buffer.size)
	buffer.copy(new_b, 0, cursor_buffer.buffer)

	cursor_buffer.buffer = new_b;
end


-- Reads a CFrame from the <code>CursorBuffer</code>.
-- Moves the cursor by <strong>15</strong> bytes.
function BufferUtil.read_cframe(cursor_buffer: CursorBuffer): CFrame
	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;
	
	local x = readi24(b, cursor + 0) / 100
	local y = readi24(b, cursor + 3) / 100
	local z = readi24(b, cursor + 6) / 100
	local rx = readi16AsFloat(b, cursor + 9)
	local ry = readi16AsFloat(b, cursor + 11)
	local rz = readi16AsFloat(b, cursor + 13)
	
	cursor_buffer.cursor += 15;
	
	return CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz);
end


-- Reads a 32 Bit Floating Point CFrame from the <code>CursorBuffer</code>.
-- Moves the cursor by <strong>24</strong> bytes.
function BufferUtil.read_cframef32(cursor_buffer: CursorBuffer): CFrame
	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;
	
	local x = buffer.readf32(b, cursor)
	local y = buffer.readf32(b, cursor + 4)
	local z = buffer.readf32(b, cursor + 8)
	local rx = buffer.readf32(b, cursor + 12)
	local ry = buffer.readf32(b, cursor + 16)
	local rz = buffer.readf32(b, cursor + 20)
	
	cursor_buffer.cursor += 24;
	
	return CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz);
end


-- Writes a CFrame to the <code>CursorBuffer</code>.
-- Allocates <strong>15</strong> bytes if there is not enough bytes in the buffer.
function BufferUtil.write_cframe(cursor_buffer: CursorBuffer, cframe: CFrame): ()
	BufferUtil.allocate(cursor_buffer, 15);
	
	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;
	local x, y, z = cframe.X, cframe.Y, cframe.Z
	local rx, ry, rz = cframe:ToEulerAnglesXYZ()

	writei24(b, cursor + 0, x * 100)
	writei24(b, cursor + 3, y * 100)
	writei24(b, cursor + 6, z * 100)
	writeFloatAsi16(b, cursor + 9, rx)
	writeFloatAsi16(b, cursor + 11, ry)
	writeFloatAsi16(b, cursor + 13, rz)
	
	cursor_buffer.cursor += 15;
end


-- Writes a 32 Bit Floating Point CFrame to the <code>CursorBuffer</code>.
-- Allocates <strong>24</strong> bytes if there is not enough bytes in the buffer.
function BufferUtil.write_cframef32(cursor_buffer: CursorBuffer, cframe: CFrame): ()
	BufferUtil.allocate(cursor_buffer, 24);

	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;
	local x, y, z = cframe.X, cframe.Y, cframe.Z
	local rx, ry, rz = cframe:ToEulerAnglesXYZ()

	buffer.writef32(b, cursor + 0, x);
	buffer.writef32(b, cursor + 4, y);
	buffer.writef32(b, cursor + 8, z);
	buffer.writef32(b, cursor + 12, rx);
	buffer.writef32(b, cursor + 16, ry);
	buffer.writef32(b, cursor + 20, rz);
	
	cursor_buffer.cursor += 24;
end


-- Reads a Vector3 from the <code>CursorBuffer</code>.
-- Moves the cursor by <strong>12</strong> bytes.
function BufferUtil.read_vector3(cursor_buffer: CursorBuffer): Vector3
	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;
	
	local x = buffer.readf32(b, cursor);
	local y = buffer.readf32(b, cursor + 4);
	local z = buffer.readf32(b, cursor + 8);
	
	cursor_buffer.cursor += 12;
	
	return Vector3.new(x, y, z);
end


-- Writes a Vector3 to the <code>CursorBuffer</code>.
-- Allocates <strong>12</strong> bytes if there is not enough bytes in the buffer.
function BufferUtil.write_vector3(cursor_buffer: CursorBuffer, vector: Vector3): ()
	BufferUtil.allocate(cursor_buffer, 12);
	
	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;

	buffer.writef32(b, cursor + 0, vector.X)
	buffer.writef32(b, cursor + 4, vector.Y)
	buffer.writef32(b, cursor + 8, vector.Z)
	
	cursor_buffer.cursor += 12;
end


-- Writes an 8 Bit Integer (0-255) to the <code>CursorBuffer</code>.
-- Allocates <strong>1</strong> byte if there is not enough bytes in the buffer.
function BufferUtil.write_i8(cursor_buffer: CursorBuffer, number: number): ()
	BufferUtil.allocate(cursor_buffer, 1);
	
	buffer.writei8(cursor_buffer.buffer, cursor_buffer.cursor, number);
	
	cursor_buffer.cursor += 1;
end


-- Reads an 8 Bit Intenger (0-255) from the <code>CursorBuffer</code>.
-- Moves the cursor by <strong>1</strong> byte.
function BufferUtil.read_i8(cursor_buffer: CursorBuffer): ()
	local value = buffer.readi8(cursor_buffer.buffer, cursor_buffer.cursor);
	
	cursor_buffer.cursor += 1;
	
	return value;
end

---------------------------------------------------------------------------------

table.freeze(BufferUtil);

return BufferUtil;