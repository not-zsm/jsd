-- Encodes a number into a Base91 string.

local BASE92_CHARS = [[0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$%&()*+,-./:;<=>?@[]^_`{|}~']]

local Base91 = {};
local EncodeChars = {};
local DecodeChars = {};

for i = 1, 91 do
	local char = string.sub(BASE92_CHARS, i, i);
	EncodeChars[i - 1] = char;
	DecodeChars[char] = i - 1;
end

@native function Base91.encode_value(value: number): string
	value = math.floor(value);
	
	local t = {};
	
	repeat
		local d = (value % 91) + 1;
		value = math.floor(value / 91);
		table.insert(t, 1, string.sub(BASE92_CHARS, d, d));
		
	until value == 0;
	
	return table.concat(t, "");
end;

@native function Base91.encode_string(str: string): string
	local output: {string} = {};
	local count = 1;
	local counter = 0;
	local bit_count = 0;

	for index = 1, #str do
		counter = bit32.bor(counter, bit32.lshift(string.byte(str, index), bit_count));
		bit_count += 8;
		
		if bit_count > 13 then
			local entry = bit32.band(counter, 8191); -- 2^13-1 = 8191
			
			if entry > 88 then -- Voodoo magic (https://www.reddit.com/r/learnprogramming/comments/8sbb3v/understanding_base91_encoding/e0y85ot/)
				counter = bit32.rshift(counter, 13);
				bit_count -= 13;
			else
				entry = bit32.band(counter, 16383); -- 2^14-1 = 16383
				counter = bit32.rshift(counter, 14);
				bit_count -= 14;
			end;
			
			output[count] = EncodeChars[entry % 91] .. EncodeChars[entry // 91];
			count += 1;
		end
	end

	if bit_count > 0 then
		output[count] = EncodeChars[counter % 91];
		
		if bit_count > 7 or counter > 90 then
			output[count + 1] = EncodeChars[counter // 91];
		end;
	end;

	return table.concat(output);
end

@native function Base91.decode_string(str: string): string
	local output: {string} = {};
	local count = 1;
	local counter = 0;
	local bit_count = 0;
	local entry = -1;

	for index = 1, #str do
		local char = string.sub(str, index, index);
		
		if DecodeChars[char] then
			if entry == -1 then
				entry = DecodeChars[char]
			else
				entry += DecodeChars[char] * 91;
				counter = bit32.bor(counter, bit32.lshift(entry, bit_count));
				
				if bit32.band(entry, 8191) > 88 then
					bit_count += 13;
				else
					bit_count += 14;
				end;
				
				while bit_count > 7 do
					output[count] = string.char(counter % 256);
					count += 1;
					counter = bit32.rshift(counter, 8);
					bit_count -= 8;
				end;
				
				entry = -1;
			end;
		end;
	end;

	if entry ~= -1 then
		output[count] = string.char(bit32.bor(counter, bit32.lshift(entry, bit_count)) % 256);
	end;

	return table.concat(output);
end

return Base91;