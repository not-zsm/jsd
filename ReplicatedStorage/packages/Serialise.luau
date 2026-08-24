--[[
	Serialise

	String compression, extracted from the build tools' serialiser when those
	were removed.

	Only the compression half came across. The rest of that module -- instance
	serialisation, property defaults, the inventory -- existed to save and load
	player builds and went with them. What is left is the part the destruction
	system needs to unpack its rubble presets, and it depends on nothing beyond
	Base91, LibDeflate and BufferUtil.
--]]

local HttpService = game:GetService("HttpService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local Base91 = require(script.Base91)
local BufferUtil = require(replicatedStorage.packages.BufferUtil)

-----------------------------------------------------------------------------

export type StringDecompressParameters = { machine: ("Zlib" | "Zstd")?, iterator: (() -> ())? }
export type StringCompressParameters = { machine: ("Zlib" | "Zstd")?, level: number?, iterator: (() -> ())? }

local Serialiser = {};

-----------------------------------------------------------------------------

function Serialiser.compress(text: string, parameters: StringCompressParameters): string
	if not parameters then parameters = {} end;

	if not parameters.machine then
		parameters.machine = "Zstd";

		local success, compressed = pcall(Serialiser.compress, text, parameters);

		if success then
			return compressed;
		else
			warn(compressed);
			parameters.machine = "Zlib";

			return Serialiser.compress(text, parameters);
		end;
	end;

	if parameters.machine == "Zlib" then
		local LibDeflate = require(script.LibDeflate);

		local compress_parameters = {level = parameters.level, writer_step = parameters.iterator};
		local success, compressed = pcall(LibDeflate.Zlib.Compress, text, compress_parameters)

		if not success then
			error(`[Serialiser]: Zlib compress failed: {compressed}`);
		end

		local success, encoded = pcall(Base91.encode_string, compressed);

		if not success then
			error(`[Serialiser]: Base91 encoding failed: {encoded}`);
		end;

		return encoded;

	elseif parameters.machine == "Zstd" then
		local success, compressed = pcall(BufferUtil.compress, text);

		if not success then
			error(`[Serialiser]: Zstd compress failed: {compressed}`);
		end;

		return compressed;
	end;

	error(`[Serialiser]: compress failed: invalid machine used ({parameters.machine})`);
end;

-- General decompress function with support for Zlib. If a machine is not specified then it will decide the compression type based on the given text.
function Serialiser.decompress(text: string, parameters: StringDecompressParameters?): string
	if not parameters then parameters = {} end;

	if not parameters.machine then
		if #text > 1 and string.byte(text, 1) == 56 and string.byte(text, 2) == 63 then
			parameters.machine = "Zlib";
		else
			parameters.machine = "Zstd";
		end;
	end;

	if parameters.machine == "Zlib" then
		-- Assume that Zlib compress was used for serialised.

		local LibDeflate = require(script.LibDeflate);

		local success, decoded = pcall(Base91.decode_string, text);

		if not success then
			error(`[Serialiser]: Base91 decoding failed: {decoded}`)
		end;

		local decompress_parameters = {reader_iterator = parameters.iterator};
		local success, decompressed = pcall(LibDeflate.Zlib.Decompress, decoded, decompress_parameters);

		if not success then
			error(`[Serialiser]: Zlib decompress failed: {decompressed}`);
		end;

		return decompressed;

	elseif parameters.machine == "Zstd" then
		-- Assume that Internal Zstd was used for serialised.

		local success, decompressed = pcall(BufferUtil.decompress, text);

		if not success then
			error(`[Serialiser]: Zstd decompress failed: {decompressed}`);
		end;

		return decompressed;
	end;

	error(`[Serialiser]: decompress failed: invalid machine used ({parameters.machine})`);
end;


function Serialiser.compress_json(text: string, parameters: StringCompressParameters?): string
	local success, json = pcall(HttpService.JSONEncode, HttpService, text);

	if success then
		return Serialiser.compress(json, parameters);
	end;

	return "";
end

function Serialiser.decompress_json(text: string, parameters: StringDecompressParameters?): any
	local decompress = Serialiser.decompress(text, parameters);
	local success, raw_table = pcall(HttpService.JSONDecode, HttpService, decompress);

	if success then
		return raw_table
	end;

	return {};
end

-- Copies the properties of the given instance and returns a table of format <strong>{Property = Value}</strong>.

-----------------------------------------------------------------------------

return Serialiser;