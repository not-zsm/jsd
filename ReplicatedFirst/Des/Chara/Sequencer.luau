--== Imports ==--
local RunService  = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Helper = require("./Helper")

--== Types ==--
export type Entry = {
	id: string,
	time: number,
	run: (self: any) -> (),
}
export type Between = { min: number, max: number }

--== Constants ==--
local DEFAULTS = { BETWEEN = { min = 0.12, max = 0.28 } :: Between }
local RNG = Random.new()

--== Module ==--
local Module = {}
Module.__index = Module

--== Private ==--
local function _pickNext(pool: {Entry}, lastId: string?): Entry
	if #pool == 1 then return pool[1] end
	local candidates = table.create(#pool)
	for _, e in ipairs(pool) do
		if e.id ~= lastId then table.insert(candidates, e) end
	end
	if #candidates == 0 then
		return pool[RNG:NextInteger(1, #pool)]
	end
	return candidates[RNG:NextInteger(1, #candidates)]
end

function Module:_bumpGen()
	self._Gen += 1
end

function Module:_isAlive(gen: number?): boolean
	return (not self._Stopped) and self._Active and (not gen or gen == self._Gen)
end

function Module:_sleep(sec: number): boolean
	local gen = self._Gen
	local t = 0
	while self:_isAlive(gen) and t < sec do
		if self._Deadline and os.clock() >= self._Deadline then return false end
		t += RunService.Heartbeat:Wait()
	end
	return self:_isAlive(gen)
end

function Module:_refillBag()
	local n = #self.Pool
	self._Bag = table.create(n)
	for i = 1, n do self._Bag[i] = self.Pool[i] end
	for i = n, 2, -1 do
		local j = RNG:NextInteger(1, i)
		self._Bag[i], self._Bag[j] = self._Bag[j], self._Bag[i]
	end
	if self._LastId and n > 1 and self._Bag[1].id == self._LastId then
		local j = RNG:NextInteger(2, n)
		self._Bag[1], self._Bag[j] = self._Bag[j], self._Bag[1]
	end
	self._BagI = 1
	self._BagDirty = false
end

function Module:_nextEntry(): Entry?
	if self._BagDirty or not self._Bag or self._BagI > #self._Bag or #self._Bag == 0 then
		if #self.Pool == 0 then return nil end
		self:_refillBag()
	end
	local e = self._Bag[self._BagI]
	self._BagI += 1
	return e
end

function Module:_runLoop()
	self._Active = true
	self:_bumpGen()
	while self:_isAlive() do
		if self._Deadline and os.clock() >= self._Deadline then break end
		local entry = self:_nextEntry()
		if not entry then break end

		self._LastId = entry.id
		task.spawn(entry.run)
		if not self:_sleep(entry.time) then break end

		local gap = RNG:NextNumber(self.Between.min, self.Between.max)
		if not self:_sleep(gap) then break end
	end
	self._Active = false
end

--== Public ==--
function Module:AddEntry(entry: Entry)
	table.insert(self.Pool, entry)
	self._BagDirty = true
	return self
end

function Module:Clear()
	table.clear(self.Pool)
	self._LastId   = nil
	self._Bag      = {}
	self._BagI     = 1
	self._BagDirty = false
	return self
end

function Module:setBetween(minGap: number, maxGap: number)
	self.Between.min = math.max(0, minGap)
	self.Between.max = math.max(self.Between.min, maxGap)
	return self
end

function Module:setDeadline(secondsFromNow: number?)
	self._Deadline = secondsFromNow and (os.clock() + secondsFromNow) or nil
	return self
end

function Module:RandArenaPos(): Vector2
	local size = self.State.Arena.Size
	return Vector2.new(
		RNG:NextNumber(-(size.X * 0.5), size.X * 0.5),
		RNG:NextNumber(-(size.Y * 0.5), size.Y * 0.5)
	)
end

function Module:Defer(delaySec: number, fn: () -> ())
	local gen = self._Gen
	task.delay(delaySec, function()
		if self:_isAlive(gen) and (not self._Deadline or os.clock() < self._Deadline) then
			fn()
		end
	end)
end

function Module:Start(durationSeconds: number?)
	if self._Active then return self end
	self:setDeadline(durationSeconds)
	task.spawn(function() self:_runLoop() end)
	return self
end

function Module:Stop()
	if self._Stopped then return end
	self._Stopped = true
	self._Active  = false
	self:_bumpGen()
end

--== Lifecycle ==--
function Module.new(trove, signals, state, arena, gui)
	local self = setmetatable({
		Trove   = trove,
		Signals = signals,
		State   = state,
		Arena   = arena,
		GUI     = gui,

		Pool    = {} :: {Entry},
		Between = table.clone(DEFAULTS.BETWEEN),

		_Active   = false,
		_Stopped  = false,
		_Deadline = nil :: number?,
		_Gen      = 0,
		_LastId   = nil :: string?,

		_Bag      = {} :: {Entry},
		_BagI     = 1,
		_BagDirty = false,

		_UUID     = HttpService:GenerateGUID(false),
	}, Module)

	return self
end

function Module:Destroy()
	self:Stop()
	
	table.clear(self)
	setmetatable(self, nil)
end

--== Return ==--
return Module