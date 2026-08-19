--== Imports ==--
local HttpService = game:GetService("HttpService")

local Helper = require("./Helper")

--== Types ==--
export type Params = {
	amp: number?,
	freq: number?,
	duration: number?,
	randomness: number?,
	axis: Vector2?,
	falloff: "linear" | "cubic" | "sine" | "expo" | "circ" | "back" | ((t:number)->number)?,
}

--== Constants ==--
local DEFAULTS = {
	amp        = 10,
	freq       = 12,
	duration   = 0.40,
	randomness = 0.35,
	axis       = Vector2.new(1, 1),
	falloff    = "cubic",
}

local RNG = Random.new()

local FALLOFF = {
	linear = function(t) return 1 - t end,
	cubic  = function(t) return 1 - Helper.easeOutCubic(t)     end,
	sine   = function(t) return 1 - Helper.easeOutSine(t)      end,
	expo   = function(t) return 1 - Helper.easeOutExpo(t)      end,
	circ   = function(t) return 1 - Helper.easeOutCirc(t)      end,
	back   = function(t) return 1 - Helper.easeOutBack(t, 1.4) end,
}

--== Module ==--
local Module = {}
Module.__index = Module

--== Public ==--
function Module:Shake(params: Params?)
	params = params or {}

	local amp        = tonumber(params.amp)        or DEFAULTS.amp
	local freq       = tonumber(params.freq)       or DEFAULTS.freq
	local duration   = tonumber(params.duration)   or DEFAULTS.duration
	local randomness = tonumber(params.randomness) or DEFAULTS.randomness
	local axis       = params.axis                 or DEFAULTS.axis
	amp        = math.max(0, amp)
	freq       = math.max(0, freq)
	duration   = math.max(1e-4, duration)
	randomness = math.clamp(randomness, 0, 1)
	axis       = Vector2.new(axis.X, axis.Y)

	local fall = params.falloff
	if type(fall) == "string" then
		fall = FALLOFF[fall] or FALLOFF[DEFAULTS.falloff]
	elseif type(fall) ~= "function" then
		fall = FALLOFF[DEFAULTS.falloff]
	end

	local id    = HttpService:GenerateGUID(false)
	local seed  = RNG:NextInteger(1, 1_000_000)
	local phase = RNG:NextNumber(0, 2 * math.pi)

	self._List[#self._List + 1] = {
		id    = id,
		amp   = amp,
		freq  = freq,
		dur   = duration,
		time  = 0,
		randomness = randomness,
		axis  = axis,
		phase = phase,
		fall  = fall :: (t:number)->number,
		rng   = Random.new(seed),
	}

	return id
end

function Module:Reset()
	self._List = {}
	if self.Contents and self._BaseC then
		self.Contents.Position = self._BaseC
	end
	if self.Decorations and self._BaseD then
		self.Decorations.Position = self._BaseD
	end
end

--== Lifecycle ==--
function Module.new(trove, state, arena: Frame)
	local self = setmetatable({
		Trove  = trove,
		State  = state,

		Arena        = arena,
		Contents     = arena:FindFirstChild("Contents") :: GuiObject?,
		Decorations  = arena:FindFirstChild("Decorations") :: GuiObject?,

		_BaseC = nil :: UDim2?,
		_BaseD = nil :: UDim2?,

		_List = {} :: {
			{
				id: string,
				amp: number,
				freq: number,
				dur: number,
				time: number,
				randomness: number,
				axis: Vector2,
				phase: number,
				fall: (t:number) -> number,
				rng: Random,
			}
		},
	}, Module)

	if self.Contents then
		self._BaseC = self.Contents.Position
	end
	if self.Decorations then
		self._BaseD = self.Decorations.Position
	end

	return self
end

function Module:Step(dtFrames: number)
	if not (self.Contents or self.Decorations) then return end

	local dt = Helper.toSec(dtFrames)
	local total = Vector2.zero
	local alive = 0

	for i = #self._List, 1, -1 do
		local s = self._List[i]
		s.time += dt

		local t = math.clamp(s.time / s.dur, 0, 1)
		if t >= 1 then
			table.remove(self._List, i)
		else
			alive += 1

			s.phase += (2 * math.pi) * s.freq * dt
			local sinX = math.cos(s.phase)
			local sinY = math.sin(s.phase)

			local jx = s.rng:NextNumber(-1, 1)
			local jy = s.rng:NextNumber(-1, 1)

			local mag   = s.amp * s.fall(t)
			local blend = s.randomness

			local dx = (sinX * (1 - blend) + jx * blend) * mag * s.axis.X
			local dy = (sinY * (1 - blend) + jy * blend) * mag * s.axis.Y

			if dx ~= 0 or dy ~= 0 then
				total += Vector2.new(dx, dy)
			end
		end
	end

	local ox = Helper.roundpx(total.X)
	local oy = Helper.roundpx(total.Y)

	if self.Contents and self._BaseC then
		self.Contents.Position = UDim2.new(self._BaseC.X.Scale, self._BaseC.X.Offset + ox, self._BaseC.Y.Scale, self._BaseC.Y.Offset + oy)
	end
	if self.Decorations and self._BaseD then
		self.Decorations.Position = UDim2.new(self._BaseD.X.Scale, self._BaseD.X.Offset + ox, self._BaseD.Y.Scale, self._BaseD.Y.Offset + oy)
	end

	if alive == 0 then
		if self.Contents and self._BaseC then
			self.Contents.Position = self._BaseC
		end
		if self.Decorations and self._BaseD then
			self.Decorations.Position = self._BaseD
		end
	end
end

function Module:Destroy()
	self:Reset()
	table.clear(self)
	setmetatable(self, nil)
end

--== Return ==--
return Module