-- Exercises the exact write/read pair byteNet uses for `unknown` and `inst`,
-- transplanted so it runs outside Roblox.
local buff = buffer.create(4096)
local cursor = 0
local references = {}

local function reference(value)
	table.insert(references, value)
	buffer.writeu16(buff, cursor, #references)
	cursor += 2
end

local function readRef(b, c)
	return references[buffer.readu16(b, c)], 2
end

-- write more than a u8 could index
local N = 600
local written = {}
for i = 1, N do
	local v = { tag = "effect" .. i }
	written[i] = v
	reference(v)
end

local ok = true
local c = 0
for i = 1, N do
	local got, width = readRef(buff, c)
	c += width
	if got ~= written[i] then
		print(`MISMATCH at {i}: expected effect{i}, got {got and got.tag or "nil"}`)
		ok = false
		break
	end
end

print(`wrote {N} references over {cursor} bytes`)
print(ok and "round-trip OK past 255" or "ROUND-TRIP BROKEN")

-- and prove the old u8 form actually breaks, so the fix is not cosmetic
local b2 = buffer.create(1024)
for i = 1, 300 do buffer.writeu8(b2, i - 1, i % 256) end
print(`u8 index for reference 256 reads back as {buffer.readu8(b2, 255)} -- wraps to 0`)
