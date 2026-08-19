--== Imports ==--

local HttpService = game:GetService("HttpService")

local Helper = require("./Helper")

--== Types ==--
export type Orientation = "Horizontal" | "Vertical" | "Both"
export type SweepParams = {
	fromGui: GuiObject?,
	targetPos: Vector2?,
	telegraph: number?,
	expand: number?,
	shrink: number?,
	thickness: number?,
	flashRate: number?,
	damage: number?,
	slash: number?,
}
export type SpinParams = {
	fromGui: GuiObject?,
	maxLines: number?,
	rampDuration: number?,
	holdDuration: number?,
	rotateSpeedStart: number?,
	rotateSpeedEnd: number?,
	rotateSpeed: number?,
	thickness: number?,
	damage: number?,
	flashRate: number?,
	pulseTelegraph: number?,
	pulseHit: number?,
	expand: number?,
	shrink: number?,
	targetPos: Vector2?,
	minGapDeg: number?,
	gapJitterDeg: number?,
	slash: number?,
}

--== Constants ==--
local COLOR_YELLOW = Color3.fromRGB(255, 234, 0)
local COLOR_RED    = Color3.fromRGB(255, 64, 64)
local COLOR_WHITE  = Color3.new(1, 1, 1)

local SWEEP_DEFAULTS = {
	telegraph = 0.90,
	expand    = 0.22,
	shrink    = 0.30,
	thickness = 12,
	flashRate = 9,
	damage    = 6,
	slash     = 1,
}

local SPIN_DEFAULTS = {
	maxLines        = 4,
	rampDuration    = 1.40,
	holdDuration    = 2.10,
	rotateSpeedEnd  = 140,
	thickness       = 12,
	damage          = 7,
	flashRate       = 16,
	pulseTelegraph  = 0.40,
	pulseHit        = 0.30,
	expand          = 0.16,
	shrink          = 0.16,
	minGapDeg       = 28.0,
	gapJitterDeg    = 6.0,
	slash           = 3,
}

local RNG = Random.new()

--== Module ==--
local Module = {}
Module.__index = Module
Module.Compute = {} :: { [string]: (dt: number) -> () }

--== Lifecycle ==--
function Module.newSweep(signals, state, contents: GuiObject, orientation: Orientation, params: SweepParams?)
	params = params or {}
	local tele   = params.telegraph or SWEEP_DEFAULTS.telegraph
	local tExp   = params.expand    or SWEEP_DEFAULTS.expand
	local tShr   = params.shrink    or SWEEP_DEFAULTS.shrink
	local thick  = params.thickness or SWEEP_DEFAULTS.thickness
	local rate   = params.flashRate or SWEEP_DEFAULTS.flashRate
	local dmg    = params.damage    or SWEEP_DEFAULTS.damage
	local slashI = math.clamp(params.slash or SWEEP_DEFAULTS.slash, 1, 3)
	local sound  = ("Slash %d"):format(slashI)

	local attacksFolder = Helper.resolveEffectFolders(contents)
	local pos: Vector2
	if params.targetPos then
		pos = params.fromGui
			and (Helper.absToCenteredOffset(Helper.centerAbs(params.fromGui), contents) + params.targetPos)
			or  Vector2.new(Helper.roundpx(params.targetPos.X), Helper.roundpx(params.targetPos.Y))
	else
		local sz = contents.AbsoluteSize
		local hw, hh = sz.X * 0.5, sz.Y * 0.5
		pos = Vector2.new(
			Helper.roundpx(RNG:NextNumber(-hw + 8, hw - 8)),
			Helper.roundpx(RNG:NextNumber(-hh + 8, hh - 8))
		)
		
		pos = Helper.snapV2ToGrid(pos, 32, 32, Helper.centerAbs(params.fromGui))
	end
	
	local centerPos = params.fromGui
		and (Helper.absToCenteredOffset(Helper.centerAbs(params.fromGui), contents) + pos)
		or  Vector2.new(Helper.roundpx(pos.X), Helper.roundpx(pos.Y))

	local wantH = (orientation == "Horizontal") or (orientation == "Both")
	local wantV = (orientation == "Vertical")   or (orientation == "Both")

	local self = setmetatable({
		Signals   = signals,
		State     = state,
		Contents  = contents,

		Tele      = tele,
		TExp      = tExp,
		TShr      = tShr,
		Thick     = thick,
		Rate      = rate,
		Damage    = dmg,

		Center    = centerPos,
		UUID      = HttpService:GenerateGUID(false),
		Alive     = true,
		Phase     = "TELEGRAPH",
		Time      = 0,
		PTime     = 0,

		Lines     = {} :: { {isH: boolean, gui: Frame} },
		Sounded   = false,
	}, Module)

	local attacks = state.Attacks

	local function makeLine(isH: boolean)
		local f = Instance.new("Frame")
		f.Name = isH and "SweepH" or "SweepV"
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.BackgroundColor3 = COLOR_YELLOW
		f.BorderSizePixel = 0
		f.Parent = attacksFolder

		attacks[f] = {
			Kind = "Sweep",
			Size = isH and Vector2.new(contents.AbsoluteSize.X, 2) or Vector2.new(2, contents.AbsoluteSize.Y),
			Pos  = self.Center,
			Dmg  = 0,
			Destroy = function()
				if attacks[f] then attacks[f] = nil end
				if f then f:Destroy() end
			end,
		}
		table.insert(self.Lines, { isH = isH, gui = f })
	end

	if wantH then makeLine(true) end
	if wantV then makeLine(false) end

	local function apply(lr)
		local gui = lr.gui
		local atk = attacks[gui]; if not atk then return end

		local unit = Helper.unitScale(contents, state.Arena.BaselineMin)
		local minorRaw = lr.isH and atk.Size.Y or atk.Size.X
		local px = math.max(1, math.floor(minorRaw * unit + 0.5))

		local ox, oy = Helper.roundpx(atk.Pos.X), Helper.roundpx(atk.Pos.Y)

		if lr.isH then
			gui.Position = UDim2.new(0.5, ox, 0.5, oy)
			gui.Size     = UDim2.new(64, 0, 0, px)
		else
			gui.Position = UDim2.new(0.5, ox, 0.5, oy)
			gui.Size     = UDim2.new(0, px, 64, 0)
		end
	end

	for _, lr in ipairs(self.Lines) do apply(lr) end

	Module.Compute[self.UUID] = function(dtFrame: number)
		if not self.Alive then return end
		local dt = Helper.toSec(dtFrame)
		local unit = Helper.unitScale(contents, state.Arena.BaselineMin)

		if not self.Sounded then self.Signals.spawnSound:Fire(sound); self.Sounded = true end
		
		self.Time  += dt
		self.PTime += dt

		if self.Phase == "TELEGRAPH" then
			local on = (math.floor(self.Time * self.Rate) % 2 == 0)
			for _, lr in ipairs(self.Lines) do
				local gui = lr.gui
				local atk = attacks[gui]; if not atk then continue end
				if lr.isH then
					atk.Size = Vector2.new(contents.AbsoluteSize.X, 2)
				else
					atk.Size = Vector2.new(2, contents.AbsoluteSize.Y)
				end
				atk.Pos = self.Center
				atk.Dmg = 0
				gui.BackgroundColor3 = on and COLOR_YELLOW or COLOR_RED
				apply(lr)
			end
			if self.PTime >= self.Tele then
				self.Phase = "EXPAND"
				self.PTime = 0
				for _, lr in ipairs(self.Lines) do lr.gui.BackgroundColor3 = COLOR_WHITE end
			end
			return
		end

		if self.Phase == "EXPAND" then
			local t  = math.clamp(self.PTime / math.max(self.TExp, 1e-6), 0, 1)
			local th = math.lerp(2, self.Thick, Helper.easeOutCubic(t))
			for _, lr in ipairs(self.Lines) do
				local gui = lr.gui
				local atk = attacks[gui]; if not atk then continue end
				if lr.isH then
					atk.Size = Vector2.new(contents.AbsoluteSize.X, th)
				else
					atk.Size = Vector2.new(th, contents.AbsoluteSize.Y)
				end
				atk.Pos = self.Center
				atk.Dmg = self.Damage
				apply(lr)
			end
			if t >= 1 then self.Phase = "SHRINK"; self.PTime = 0 end
			return
		end

		if self.Phase == "SHRINK" then
			local t  = math.clamp(self.PTime / math.max(self.TShr, 1e-6), 0, 1)
			local th = math.max(0, math.lerp(self.Thick, 0, Helper.easeInCubic(t)))
			for _, lr in ipairs(self.Lines) do
				local gui = lr.gui
				local atk = attacks[gui]; if not atk then continue end
				if lr.isH then
					atk.Size = Vector2.new(contents.AbsoluteSize.X, th)
				else
					atk.Size = Vector2.new(th, contents.AbsoluteSize.Y)
				end
				atk.Pos = self.Center
				atk.Dmg = (th > 0) and self.Damage or 0
				apply(lr)
			end
			if t >= 1 then self.Phase = "DONE" end
			return
		end

		if self.Phase == "DONE" then
			self:Destroy()
			return
		end
	end

	return self
end

function Module.newSpin(signals, state, contents: GuiObject, params: SpinParams?)
	params = params or {}
	local maxLines  = math.max(1, params.maxLines or SPIN_DEFAULTS.maxLines)
	local rampDur   = math.max(0, params.rampDuration or SPIN_DEFAULTS.rampDuration)
	local holdDur   = math.max(0, params.holdDuration or SPIN_DEFAULTS.holdDuration)
	local rotEnd    = params.rotateSpeedEnd or params.rotateSpeed or SPIN_DEFAULTS.rotateSpeedEnd
	local rotStart  = params.rotateSpeedStart or (rotEnd * 0.4)
	local thickness = math.max(1, params.thickness or SPIN_DEFAULTS.thickness)
	local damage    = params.damage or SPIN_DEFAULTS.damage
	local flashRate = params.flashRate or SPIN_DEFAULTS.flashRate
	local pTele     = math.max(0, params.pulseTelegraph or SPIN_DEFAULTS.pulseTelegraph)
	local pHit      = math.max(0.05, params.pulseHit or SPIN_DEFAULTS.pulseHit)
	local tExp      = math.max(0, params.expand or SPIN_DEFAULTS.expand)
	local tShr      = math.max(0, params.shrink or SPIN_DEFAULTS.shrink)
	local pos       = params.targetPos or Vector2.zero
	local minGapDeg = params.minGapDeg     or SPIN_DEFAULTS.minGapDeg
	local jitDeg    = params.gapJitterDeg  or SPIN_DEFAULTS.gapJitterDeg
	local slashI    = math.clamp(params.slash or SPIN_DEFAULTS.slash, 1, 3)
	local sound     = ("Slash %d"):format(slashI)

	local halfHit = pHit * 0.5
	if tExp > halfHit then tExp = halfHit end
	if tShr > halfHit then tShr = halfHit end

	local attacksFolder = Helper.resolveEffectFolders(contents)
	local centerPos = params.fromGui
		and (Helper.absToCenteredOffset(Helper.centerAbs(params.fromGui), contents) + pos)
		or  Vector2.new(Helper.roundpx(pos.X), Helper.roundpx(pos.Y))

	local self = setmetatable({
		Signals   = signals,
		State     = state,
		Contents  = contents,

		MaxLines  = maxLines,
		RampDur   = rampDur,
		HoldDur   = holdDur,
		RotStart  = rotStart,
		RotEnd    = rotEnd,
		Thickness = thickness,
		Damage    = damage,
		FlashRate = flashRate,
		PulseTele = pTele,
		PulseHit  = pHit,
		TExp      = tExp,
		TShr      = tShr,

		Center    = centerPos,
		MinGapDeg = minGapDeg,
		JitDeg    = jitDeg,

		UUID      = HttpService:GenerateGUID(false),
		Alive     = true,
		Time      = 0,
		PhaseT    = 0,
		BaseAng   = 0,
		Phase     = "RUN",
		FinalT    = 0,
		
		Sound = false,

		Lines     = {} :: { {gui: Frame, offsetDeg: number} },
		LastHit   = false,
	}, Module)

	local attacks = state.Attacks

	local function norm(a:number):number a = a % 360; if a < 0 then a += 360 end; return a end
	local function buildAngles(n:number, gap:number, jit:number):{number}
		if n <= 0 then return {} end
		local list = {}
		table.insert(list, RNG:NextNumber(0,360))
		for _=2,n do
			table.sort(list)
			local bestGap, bestStart = -1, 0
			for i=1,#list do
				local a = list[i]
				local b = (i < #list) and list[i+1] or (list[1] + 360)
				local g = b - a
				if g > bestGap then bestGap, bestStart = g, a end
			end
			local allowed = math.max(0, bestGap - 2*gap)
			local base = bestStart + gap
			local cand
			if allowed <= 0 then
				cand = bestStart + bestGap * 0.5
			else
				cand = base + RNG:NextNumber(0,1)*allowed
				cand = math.clamp(cand + RNG:NextNumber(-jit,jit), base, base+allowed)
			end
			table.insert(list, norm(cand))
		end
		return list
	end

	local offsets = buildAngles(self.MaxLines, self.MinGapDeg, self.JitDeg)

	local function makeLine(offsetDeg:number)
		local f = Instance.new("Frame")
		f.Name = "SpinSweepLine"
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.BorderSizePixel = 0
		f.BackgroundColor3 = COLOR_YELLOW
		f.Parent = attacksFolder

		attacks[f] = {
			Kind  = "SpinSweep",
			Pos   = self.Center,
			Dmg   = 0,
			Rot   = 0,
			Minor = 4,
			Destroy = function()
				if attacks[f] then attacks[f] = nil end
				if f then f:Destroy() end
			end,
		}

		table.insert(self.Lines, { gui = f, offsetDeg = offsetDeg })
	end

	for i=1,self.MaxLines do makeLine(offsets[i]) end

	local function apply(gui: Frame, angleDeg: number, minor: number)
		local w, h = contents.AbsoluteSize.X, contents.AbsoluteSize.Y
		local diag  = math.ceil(math.sqrt(w*w + h*h))
		local base  = 2 * w
		local extra = math.max(0, diag - base) + 8
		gui.Size     = UDim2.new(50, extra, 0, minor)
		gui.Position = UDim2.new(0.5, self.Center.X, 0.5, self.Center.Y)
		gui.Rotation = angleDeg
	end

	local function lineCount(t:number):number
		if self.RampDur <= 1e-6 then return self.MaxLines end
		local k = math.clamp(t / self.RampDur, 0, 1)
		return math.max(1, math.min(self.MaxLines, math.floor(math.lerp(1, self.MaxLines, k) + 1e-3)))
	end

	local function rotSpeed(t:number):number
		local total = self.RampDur + self.HoldDur
		local k = (total > 0) and math.clamp(t / total, 0, 1) or 1
		return math.lerp(self.RotStart, self.RotEnd, Helper.easeInCubic(k))
	end

	Module.Compute[self.UUID] = function(dtFrame: number)
		if not self.Alive then return end
		local dt = Helper.toSec(dtFrame)
		local unit = Helper.unitScale(contents, state.Arena.BaselineMin)

		self.Time  += dt
		
		if not self.Sounded then self.Signals.spawnSound:Fire(sound); self.Sounded = true end

		if self.Phase == "RUN" then
			self.PhaseT += dt
			self.BaseAng = (self.BaseAng + rotSpeed(self.PhaseT) * dt) % 360

			local count   = lineCount(self.PhaseT)
			local cycle   = self.Time % (self.PulseTele + self.PulseHit)
			local hitting = (cycle >= self.PulseTele)
			local flashOn = (math.floor(self.Time * self.FlashRate) % 2 == 0)

			local tHit = hitting and (cycle - self.PulseTele) or 0
			local minor
			if not hitting then
				minor = 2
			else
				if tHit < self.TExp then
					local k = tHit / math.max(self.TExp, 1e-6)
					minor = math.lerp(2, self.Thickness * unit, Helper.easeOutCubic(k))
				elseif tHit > (self.PulseHit - self.TShr) then
					local k = (tHit - (self.PulseHit - self.TShr)) / math.max(self.TShr, 1e-6)
					minor = math.lerp(self.Thickness * unit, 2, Helper.easeInCubic(k))
				else
					minor = self.Thickness * unit
				end
			end

			for i, rec in ipairs(self.Lines) do
				local gui = rec.gui
				local atk = attacks[gui]; if not atk then continue end
				local visible = (i <= count)
				gui.Visible = visible
				if not visible then
					atk.Dmg   = 0
					atk.Minor = 2
				else
					local ang = (self.BaseAng + rec.offsetDeg) % 360
					gui.BackgroundColor3 = (hitting and COLOR_WHITE) or (flashOn and COLOR_YELLOW or COLOR_RED)
					atk.Dmg   = hitting and self.Damage or 0
					atk.Pos   = self.Center
					atk.Rot   = ang
					atk.Minor = minor
					apply(gui, ang, minor)
				end
			end

			if self.PhaseT >= (self.RampDur + self.HoldDur) then
				self.Phase = "FINAL"
				self.FinalT = 0
			end
			return
		end

		if self.Phase == "FINAL" then
			self.FinalT += dt
			self.BaseAng = (self.BaseAng + rotSpeed(self.RampDur + self.HoldDur) * dt) % 360

			local t = self.FinalT
			local minor
			if t < self.TExp then
				local k = t / math.max(self.TExp, 1e-6)
				minor = math.lerp(2, self.Thickness * unit, Helper.easeOutCubic(k))
			elseif t < (self.TExp + self.TShr) then
				local k = (t - self.TExp) / math.max(self.TShr, 1e-6)
				minor = math.lerp(self.Thickness * unit, 0, Helper.easeInCubic(k))
			else
				self.Phase = "DONE"
				minor = 0
			end

			for _, rec in ipairs(self.Lines) do
				local gui = rec.gui
				local atk = attacks[gui]; if not atk then continue end
				local visible = (minor > 0)
				gui.Visible = visible
				if not visible then
					atk.Dmg   = 0
					atk.Minor = 0
				else
					local ang = (self.BaseAng + rec.offsetDeg) % 360
					gui.BackgroundColor3 = COLOR_WHITE
					atk.Dmg   = self.Damage
					atk.Pos   = self.Center
					atk.Rot   = ang
					atk.Minor = minor
					apply(gui, ang, minor)
				end
			end
			return
		end

		if self.Phase == "DONE" then
			self:Destroy()
			return
		end
	end

	return self
end

function Module:Destroy()
	if not self.Alive then return end
	self.Alive = false
	if self.UUID and Module.Compute[self.UUID] then Module.Compute[self.UUID] = nil end
	if self.State and self.State.Attacks then
		for _, rec in ipairs(self.Lines or {}) do
			local g = rec.gui
			if self.State.Attacks[g] then self.State.Attacks[g] = nil end
			if g then g:Destroy() end
		end
	end
	self.Lines = {}
	table.clear(self)
	setmetatable(self, nil)
end

function Module.Step(dt: number)
	for _, fn in pairs(Module.Compute) do fn(dt) end
end

--== Return ==--
return Module