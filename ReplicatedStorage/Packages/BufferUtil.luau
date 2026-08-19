--!native
--!optimize 2
--!strict

--[[
	A cursor based wrapper for buffers, contains reading/writing of Roblox DataTypes.
	Contains additional utilities such as Zstd compression.
]]

local HttpService = game:GetService("HttpService")

---------------------------------------------------------------------------------

export type CursorBuffer = {
	cursor: number;
	size: number;
	buffer: buffer;
	_anchor: number?;
};

export type SchemaItem = {
	type: string, 
	size: number
}

export type BufferSchema = {
	size: number,
	schema: { SchemaItem };
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
	};
end

-- Creates a CursorBuffer wrapper for a newly created buffer of size <strong>size</strong>.
function BufferUtil.create(size: number): CursorBuffer
	return {
		cursor = 0;
		size = size;
		buffer = buffer.create(size);
	};
end;

function BufferUtil.schema(schema: {SchemaItem}): BufferSchema
	local size = 0;
	
	for index, scheme in schema do
		size += scheme.size;
	end;
	
	return {
		size = size,
		schema = schema;
	};
end;

function BufferUtil.write_schema(schema: BufferSchema, values: { any }): CursorBuffer
	local cursor_buffer = BufferUtil.create(schema.size);
	
	for index, value in values do
		local write_type = schema.schema[index].type
		local write_method = BufferUtil[`write_{write_type}`];
		
		write_method(cursor_buffer, value);
	end;
	
	return cursor_buffer;
end;

function BufferUtil.read_schema(schema: BufferSchema, cursor_buffer: CursorBuffer): { any }
	local values = { };
	
	for index, scheme in schema.schema do
		local read_method = BufferUtil[`read_{scheme.type}`];
		
		values[index] = read_method(cursor_buffer);
	end;
	
	return values;
end;

---------------------------------------------------------------------------------

--[[
	Uses Zstd to compresses text into (ASCII compliant) Base64 string.
]]
function BufferUtil.compress(text: string): string
	local compressed: buffer = buffer.fromstring(text);
	local encoded: string = HttpService:JSONEncode(compressed);
	local zB64: string? = string.match(encoded, '"zbase64":"(.-)"');

	if zB64 then
		return zB64;
	end;

	assert(not string.match(encoded, '"base64":"(.-)"'), "String passed is too short to compress.");
	error("Failed to utilize Roblox's internal Zstd compression algorithm by using JSONEncode on a buffer.");
end

--[[
	Uses Zstd to decompresses a Base64 string back into its original string.
]]
function BufferUtil.decompress(compressed_text: string): string
	local encoded: buffer = buffer.fromstring(compressed_text);
	local json_reconstructed: string = [[{"m": null, "t": "buffer", "zbase64": "]] .. buffer.tostring(encoded) .. [["}]];
	local decompress_buffer: buffer = HttpService:JSONDecode(json_reconstructed);

	return buffer.tostring(decompress_buffer);
end;

---------------------------------------------------------------------------------

do
	local function schema(name: string, byte_size: number): SchemaItem
		return { type = name, size = byte_size };
	end

	BufferUtil.cframe = schema("cframe", 15);
	BufferUtil.small_cframe = schema("small_cframe", 12);
	BufferUtil.cframef32 = schema("cframef32", 12);
	BufferUtil.vector2 = schema("vector2", 8);
	BufferUtil.color3 = schema("color3", 3);
	BufferUtil.numberrange = schema("numberrange", 8);
	BufferUtil.vector3 = schema("vector3", 12);
	BufferUtil.small_vector3 = schema("small_vector3", 9);
	BufferUtil.i8 = schema("i8", 1);
	BufferUtil.u8 = schema("u8", 1);
	BufferUtil.u16 = schema("u16", 2);
	BufferUtil.f16 = schema("f16", 2);
	BufferUtil.f32 = schema("f32", 4);
	BufferUtil.alpha8 = schema("alpha8", 1);
	BufferUtil.tween_info = schema("tween_info", 1);
end;

---------------------------------------------------------------------------------


-- Allocates a number of bytes <strong>bytes</strong> after the cursor. Does not allocate if there is a sufficient number of bytes after the cursor.  
function BufferUtil.allocate(cursor_buffer: CursorBuffer, bytes: number): ()
	if not (cursor_buffer.cursor + bytes > cursor_buffer.size) then
		return
	end
	
	repeat
		cursor_buffer.size *= 2;
	until 
	cursor_buffer.size >= cursor_buffer.cursor + bytes;

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
end;


-- Returns a copy of a buffer that is truncated to down the cursor offset.
function BufferUtil.truncated(cursor_buffer: CursorBuffer): buffer
	local new_b = buffer.create(cursor_buffer.cursor);
	buffer.copy(new_b, 0, cursor_buffer.buffer, 0, cursor_buffer.cursor);
	
	return new_b;
end


-- Truncates the buffer down to the cursor offset, returns the buffer that was truncated.
function BufferUtil.truncate(cursor_buffer: CursorBuffer): buffer
	if cursor_buffer.cursor < cursor_buffer.size then
		cursor_buffer.buffer = BufferUtil.truncated(cursor_buffer);
	end;
	
	return cursor_buffer.buffer;
end;


function BufferUtil.move(cursor_buffer: CursorBuffer, cursor: number): ()
	if not cursor_buffer._anchor then
		cursor_buffer._anchor = cursor_buffer.cursor;
	end;
	
	cursor_buffer.cursor = cursor;
end;


function BufferUtil.unmove(cursor_buffer: CursorBuffer): ()
	if cursor_buffer._anchor then
		cursor_buffer.cursor = cursor_buffer._anchor;
		cursor_buffer._anchor = nil;
	end;
end


-- Reads a TweenInfo from the <code>CursorBuffer</code>.
-- Moves the cursor by <strong>3</strong> bytes.
function BufferUtil.read_tween_info(cursor_buffer: CursorBuffer): TweenInfo
	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;
	
	local easing_time = readi16AsFloat(b, cursor + 0);
	local easing_style = buffer.readbits(b, (cursor + 2) * 8, 5);
	local easing_direction = buffer.readbits(b, (cursor + 2) * 8 + 5, 3);
	
	cursor_buffer.cursor += 3;
	
	return TweenInfo.new( easing_time, 
		Enum.EasingStyle:FromValue(easing_style) or Enum.EasingStyle.Quad, 
		Enum.EasingDirection:FromValue(easing_direction) or Enum.EasingDirection.Out)
end;



-- Writes a TweenInfo to the <code>CursorBuffer</code>.
-- Allocates <strong>3</strong> bytes if there is not enough bytes in the buffer.
function BufferUtil.write_tween_info(cursor_buffer: CursorBuffer, tween_info: TweenInfo): ()
	BufferUtil.allocate(cursor_buffer, 3);

	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;
	
	writeFloatAsi16(b, cursor + 0, tween_info.Time);
	buffer.writebits(b, (cursor + 2) * 8, 5, tween_info.EasingStyle.Value);
	buffer.writebits(b, (cursor + 2) * 8 + 5, 3, tween_info.EasingDirection.Value);
	
	cursor_buffer.cursor += 3;
end;



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


-- Writes a CFrame to the <code>CursorBuffer</code>.
-- Allocates <strong>15</strong> bytes if there is not enough bytes in the buffer.
function BufferUtil.write_cframe(cursor_buffer: CursorBuffer, cframe: CFrame): ()
	BufferUtil.allocate(cursor_buffer, 15);

	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;
	local x, y, z = cframe.X, cframe.Y, cframe.Z
	local rx, ry, rz = cframe:ToEulerAnglesXYZ()

	writei24(b, cursor + 0, x * 100);
	writei24(b, cursor + 3, y * 100);
	writei24(b, cursor + 6, z * 100);
	writeFloatAsi16(b, cursor + 9, rx);
	writeFloatAsi16(b, cursor + 11, ry);
	writeFloatAsi16(b, cursor + 13, rz);

	cursor_buffer.cursor += 15;
end



-- Reads a very compressed CFrame from the <code>CursorBuffer</code>.
-- Moves the cursor by <strong>12</strong> bytes.
function BufferUtil.read_small_cframe(cursor_buffer: CursorBuffer): CFrame
	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;

	local x = readi24(b, cursor + 0) / 100
	local y = readi24(b, cursor + 3) / 100
	local z = readi24(b, cursor + 6) / 100
	local rx = buffer.readi8(b, cursor + 9) * math.pi / 127;
	local ry = buffer.readi8(b, cursor + 10) * math.pi / 127;
	local rz = buffer.readi8(b, cursor + 11) * math.pi / 127;

	cursor_buffer.cursor += 12;
	
	return CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz);
end


-- Writes a very compressed CFrame to the <code>CursorBuffer</code>.
-- Allocates <strong>12</strong> bytes if there is not enough bytes in the buffer.
function BufferUtil.write_small_cframe(cursor_buffer: CursorBuffer, cframe: CFrame): ()
	BufferUtil.allocate(cursor_buffer, 12);

	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;
	local x, y, z = cframe.X, cframe.Y, cframe.Z
	local rx, ry, rz = cframe:ToEulerAnglesXYZ()

	writei24(b, cursor + 0, x * 100);
	writei24(b, cursor + 3, y * 100);
	writei24(b, cursor + 6, z * 100);
	buffer.writei8(b, cursor + 9, rx / math.pi * 127);
	buffer.writei8(b, cursor + 10, ry / math.pi * 127);
	buffer.writei8(b, cursor + 11, rz / math.pi * 127);

	cursor_buffer.cursor += 12;
end


-- Reads a high-precision, 32 bit floating point CFrame from the <code>CursorBuffer</code>.
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


-- Reads a Vector2 from the <code>CursorBuffer</code>.
-- Moves the cursor by <strong>8</strong> bytes.
function BufferUtil.read_vector2(cursor_buffer: CursorBuffer): Vector2
	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;

	local x = buffer.readf32(b, cursor);
	local y = buffer.readf32(b, cursor + 4);

	cursor_buffer.cursor += 8;

	return Vector2.new(x, y);
end


-- Writes a Vector2 to the <code>CursorBuffer</code>.
-- Allocates <strong>8</strong> bytes if there is not enough bytes in the buffer.
function BufferUtil.write_vector2(cursor_buffer: CursorBuffer, vector: Vector3): ()
	BufferUtil.allocate(cursor_buffer, 8);

	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;

	buffer.writef32(b, cursor + 0, vector.X)
	buffer.writef32(b, cursor + 4, vector.Y)

	cursor_buffer.cursor += 8;
end


-- Reads a Color3 from the <code>CursorBuffer</code>.
-- Moves the cursor by <strong>3</strong> bytes.
function BufferUtil.read_color3(cursor_buffer: CursorBuffer): Color3
	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;

	local r = buffer.readu8(b, cursor);
	local g = buffer.readu8(b, cursor + 1);
	local b = buffer.readu8(b, cursor + 2);

	cursor_buffer.cursor += 3;

	return Color3.fromRGB(r, g, b);
end


-- Writes a Color3 to the <code>CursorBuffer</code>.
-- Allocates <strong>3</strong> bytes if there is not enough bytes in the buffer.
function BufferUtil.write_color3(cursor_buffer: CursorBuffer, color: Color3): ()
	BufferUtil.allocate(cursor_buffer, 3);

	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;

	buffer.writeu8(b, cursor + 0, math.clamp(color.R * 255, 0, 255))
	buffer.writeu8(b, cursor + 1, math.clamp(color.G * 255, 0, 255))
	buffer.writeu8(b, cursor + 2, math.clamp(color.B * 255, 0, 255))

	cursor_buffer.cursor += 3;
end


-- Reads a NumberRange from the <code>CursorBuffer</code>.
-- Moves the cursor by <strong>8</strong> bytes.
function BufferUtil.read_numberrange(cursor_buffer: CursorBuffer): NumberRange
	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;

	local min = buffer.readf32(b, cursor + 0);
	local max = buffer.readf32(b, cursor + 4);

	cursor_buffer.cursor += 8;

	return NumberRange.new(min, max);
end


-- Writes a NumberRange to the <code>CursorBuffer</code>.
-- Allocates <strong>8</strong> bytes if there is not enough bytes in the buffer.
function BufferUtil.write_numberrange(cursor_buffer: CursorBuffer, range: NumberRange): ()
	BufferUtil.allocate(cursor_buffer, 8);

	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;

	buffer.writef32(b, cursor + 0, range.Min)
	buffer.writef32(b, cursor + 4, range.Max)

	cursor_buffer.cursor += 8;
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



-- Reads a very compressed Vector3 from the <code>CursorBuffer</code>.
-- Moves the cursor by <strong>9</strong> bytes.
function BufferUtil.read_small_vector3(cursor_buffer: CursorBuffer): Vector3
	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;

	local x = readi24(b, cursor + 0) / 100
	local y = readi24(b, cursor + 3) / 100
	local z = readi24(b, cursor + 6) / 100

	cursor_buffer.cursor += 9;

	return Vector3.new(x, y, z);
end


-- Writes a very compressed Vector3 to the <code>CursorBuffer</code>.
-- Allocates <strong>9</strong> bytes if there is not enough bytes in the buffer.
function BufferUtil.write_small_vector3(cursor_buffer: CursorBuffer, vector: Vector3): ()
	BufferUtil.allocate(cursor_buffer, 9);

	local b, cursor = cursor_buffer.buffer, cursor_buffer.cursor;

	writei24(b, cursor + 0, vector.X * 100);
	writei24(b, cursor + 3, vector.Y * 100);
	writei24(b, cursor + 6, vector.Z * 100);

	cursor_buffer.cursor += 9;
end


-- Writes an 8 Bit Integer (-127 -> 127) to the <code>CursorBuffer</code>.
-- Allocates <strong>1</strong> byte if there is not enough bytes in the buffer.
function BufferUtil.write_i8(cursor_buffer: CursorBuffer, number: number): ()
	BufferUtil.allocate(cursor_buffer, 1);

	buffer.writei8(cursor_buffer.buffer, cursor_buffer.cursor, number);

	cursor_buffer.cursor += 1;
end


-- Reads an 8 Bit Intenger (-127 -> 127) from the <code>CursorBuffer</code>.
-- Moves the cursor by <strong>1</strong> byte.
function BufferUtil.read_i8(cursor_buffer: CursorBuffer): number
	local value = buffer.readi8(cursor_buffer.buffer, cursor_buffer.cursor);

	cursor_buffer.cursor += 1;

	return value;
end


-- Writes a 16 Bit Integer (0-65536) to the <code>CursorBuffer</code>.
-- Allocates <strong>2</strong> byte if there is not enough bytes in the buffer.
function BufferUtil.write_u16(cursor_buffer: CursorBuffer, number: number): ()
	BufferUtil.allocate(cursor_buffer, 2);

	buffer.writeu16(cursor_buffer.buffer, cursor_buffer.cursor, number);
	
	cursor_buffer.cursor += 2;
end


-- Reads a 16 Bit Intenger (0-65536) from the <code>CursorBuffer</code>.
-- Moves the cursor by <strong>2</strong> byte.
function BufferUtil.read_u16(cursor_buffer: CursorBuffer): number
	local value = buffer.readu16(cursor_buffer.buffer, cursor_buffer.cursor);

	cursor_buffer.cursor += 2;

	return value;
end;


-- Writes a 16 Bit Integer (0-65536) to the <code>CursorBuffer</code>.
-- Allocates <strong>1</strong> byte if there is not enough bytes in the buffer.
function BufferUtil.write_u8(cursor_buffer: CursorBuffer, number: number): ()
	BufferUtil.allocate(cursor_buffer, 1);

	buffer.writeu8(cursor_buffer.buffer, cursor_buffer.cursor, number);

	cursor_buffer.cursor += 1;
end


-- Reads a 8 Bit Intenger (0-255) from the <code>CursorBuffer</code>.
-- Moves the cursor by <strong>1</strong> byte.
function BufferUtil.read_u8(cursor_buffer: CursorBuffer): number
	local value = buffer.readu8(cursor_buffer.buffer, cursor_buffer.cursor);

	cursor_buffer.cursor += 1;

	return value;
end


-- Writes a 32-bit floating-point value to the <code>CursorBuffer</code>.
-- Allocates <strong>2</strong> byte if there is not enough bytes in the buffer.
function BufferUtil.write_f32(cursor_buffer: CursorBuffer, number: number): ()
	BufferUtil.allocate(cursor_buffer, 4);

	buffer.writef32(cursor_buffer.buffer, cursor_buffer.cursor, number);

	cursor_buffer.cursor += 4;
end


-- Reads a 32-bit floating-point value from the <code>CursorBuffer</code>.
-- Moves the cursor by <strong>4</strong> byte.
function BufferUtil.read_f32(cursor_buffer: CursorBuffer): number
	local value = buffer.readf32(cursor_buffer.buffer, cursor_buffer.cursor);

	cursor_buffer.cursor += 4;
	
	return value;
end



-- Writes a string to the <code>CursorBuffer</code>.
function BufferUtil.write_string(cursor_buffer: CursorBuffer, string: string): ()
	BufferUtil.allocate(cursor_buffer, #string);

	buffer.writestring(cursor_buffer.buffer, cursor_buffer.cursor, string, #string);
	
	cursor_buffer.cursor += #string;
end


-- Reads a 16 Floating Point Number from the <code>CursorBuffer</code>.
-- Moves the cursor by <strong>1</strong> byte.
function BufferUtil.read_string(cursor_buffer: CursorBuffer, length: number): string
	local value = buffer.readstring(cursor_buffer.buffer, cursor_buffer.cursor, length);

	cursor_buffer.cursor += length;

	return value;
end



-- Writes an alpha value (0-1) with 1 byte of precision to the <code>CursorBuffer</code>.
-- Allocates <strong>1</strong> byte if there is not enough bytes in the buffer.
function BufferUtil.write_alpha8(cursor_buffer: CursorBuffer, alpha: number): ()
	BufferUtil.allocate(cursor_buffer, 1);
	
	buffer.writeu8(cursor_buffer.buffer, cursor_buffer.cursor, alpha * 255);
	
	cursor_buffer.cursor += 1;
end


-- Reads an alpha value (0-1) from the <code>CursorBuffer</code>.
-- Moves the cursor by <strong>1</strong> byte.
function BufferUtil.read_alpha8(cursor_buffer: CursorBuffer): number
	local value = buffer.readu8(cursor_buffer.buffer, cursor_buffer.cursor) / 255;
	
	cursor_buffer.cursor += 1;
	
	return value;
end


---------------------------------------------------------------------------------

table.freeze(BufferUtil);

return BufferUtil;