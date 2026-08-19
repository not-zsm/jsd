--== Imports ==--
local HttpService = game:GetService("HttpService")

local Helper = require("./Helper")

--== Types ==--
export type KnifeKind = "Normal" | "MovePunish" | "StillPunish"
export type SpawnSide = "Top" | "Bottom" | "Left" | "Right"
export type Params = {
	fromGui: GuiObject?,
	targetPos: Vector2?,
	damage: number?,
	spawnTime: number?,
	telegraphTime: number?,
	backOffset: number?,
	throwSpeed: number?,
	backRotDeg: number?,
	margin: number?,
	spawnSide: SpawnSide?,
	indicated: boolean?,
	indicatorTime: number?,
	throwTTL: number?,
	multiTTL: number?,
}

--== Constants ==--
local DEFAULTS = {
	damage         = 12,
	spawnTime      = 0.55,
	telegraphTime  = 0.18,
	backOffset     = 16,
	throwSpeed     = 1520,
	backRotDeg     = 50,
	margin         = 10,
	indicatorTime  = 0.75,
	throwTTL       = 1.6,
	multiTTL       = 1.6,
}

local SOUND = "Knife Throw"

local SPRITES    = script.Parent.Assets.Sprites
local INDICATOR  = SPRITES.Indicator
local KNIFES     = SPRITES.Knifes
local RNG        = Random.new()

--== Module ==--
local Module = {}
Module.__index = Module
Module.Compute = {} :: { [string]: (dt: number) -> () }

--== Lifecycle ==--
function Module.new(signals, state, contents: GuiObject, kind: KnifeKind, params: Params?)
	params = params or {}

	local fromGui       = params.fromGui
	local damage        = params.damage        or DEFAULTS.damage
	local spawnTime     = params.spawnTime     or DEFAULTS.spawnTime
	local telegraphTime = params.telegraphTime or DEFAULTS.telegraphTime
	local backOffset    = params.backOffset    or DEFAULTS.backOffset
	local throwSpeed    = params.throwSpeed    or DEFAULTS.throwSpeed
	local backRotDeg    = params.backRotDeg    or DEFAULTS.backRotDeg
	local margin        = params.margin        or DEFAULTS.margin
	local spawnSide     = params.spawnSide
	local indicated     = params.indicated or false
	local indicatorTime = params.indicatorTime or DEFAULTS.indicatorTime
	local throwTTL      = params.throwTTL      or DEFAULTS.throwTTL
	local multiTTL      = params.multiTTL      or DEFAULTS.multiTTL

	local halfW = contents.AbsoluteSize.X * 0.5
	local halfH = contents.AbsoluteSize.Y * 0.5

	local attacksFolder = Helper.resolveEffectFolders(contents)

	local targetPos: Vector2
	if fromGui and params.targetPos then
		targetPos = Helper.absToCenteredOffset(Helper.centerAbs(fromGui) + params.targetPos, contents)
	elseif params.targetPos then
		targetPos = Vector2.new(Helper.roundpx(params.targetPos.X), Helper.roundpx(params.targetPos.Y))
	else
		if spawnSide == "Left"  or spawnSide == "Right"  then
			local range = math.max(0, (halfH * 0.5) - margin)
			targetPos = Vector2.new(0, Helper.roundpx(RNG:NextNumber(-range, range)))
			targetPos = Helper.snapV2ToGrid(targetPos, 16, 16, Helper.centerAbs(fromGui))
		elseif spawnSide == "Top"   or spawnSide == "Bottom" then
			local range = math.max(0, (halfW * 0.5) - margin)
			targetPos = Vector2.new(Helper.roundpx(RNG:NextNumber(-range, range)), 0)
			targetPos = Helper.snapV2ToGrid(targetPos, 16, 16, Helper.centerAbs(fromGui))
		else
			local rx = math.max(0, (halfW * 0.5) - margin)
			local ry = math.max(0, (halfH * 0.5) - margin)
			targetPos = Vector2.new(Helper.roundpx(RNG:NextNumber(-rx, rx)), Helper.roundpx(RNG:NextNumber(-ry, ry)))
			targetPos = Helper.snapV2ToGrid(targetPos, 16, 16, Helper.centerAbs(fromGui))
		end
	end

	local self = setmetatable({
		Signals = signals,

		State     = state,
		Contents  = contents,
		Kind      = kind,

		Damage        = damage,
		SpawnTime     = spawnTime,
		TeleTime      = telegraphTime,
		BackOffset    = backOffset,
		ThrowSpeed    = throwSpeed,
		BackRot       = backRotDeg,
		Margin        = margin,
		IndicatorTime = indicatorTime,
		ThrowTTL      = throwTTL,
		MultiTTL      = multiTTL,

		Target   = targetPos,
		UUID     = HttpService:GenerateGUID(false),
		_Alive   = true,
		Phase    = indicated and "INDICATE" or "SPAWN",

		KnifeGui = nil :: GuiObject?,
		Atk      = nil :: any,

		Indicator= nil :: ImageLabel?,
		Exclaim  = nil :: ImageLabel?,

		TimeSec  = 0,
		PhaseSec = 0,
		ThrowSec = 0,

		parkPos  = Vector2.zero,
		startPos = Vector2.zero,
		shootDir = Vector2.xAxis,
		faceRot  = 0,
		startRot = 0,

		Multi = {
			Phase   = "NONE",
			PSec    = 0,
			Guis    = {} :: {GuiObject},
			Dirs    = {} :: {Vector2},
			Start   = {} :: {Vector2},
			Park    = {} :: {Vector2},
			FromTH  = {} :: {Vector2},
			Pos     = {} :: {Vector2},
			RotS    = {} :: {number},
			RotF    = {} :: {number},
			Atk     = {} :: {any},
			N       = 0,
		},
	}, Module)

	if params.targetPos then
		local dir = (self.Target - Vector2.zero)
		if dir.Magnitude < 1e-6 then dir = Vector2.new(1, 0) end
		self.shootDir = dir.Unit
	else
		if     spawnSide == "Left"   then self.shootDir = Vector2.new( 1, 0)
		elseif spawnSide == "Right"  then self.shootDir = Vector2.new(-1, 0)
		elseif spawnSide == "Top"    then self.shootDir = Vector2.new( 0, 1)
		elseif spawnSide == "Bottom" then self.shootDir = Vector2.new( 0,-1)
		else
			local pick = RNG:NextInteger(1, 4)
			self.shootDir = (pick == 1 and Vector2.new(1,0))
				or          (pick == 2 and Vector2.new(-1,0))
				or          (pick == 3 and Vector2.new(0,1))
				or                         Vector2.new(0,-1)
		end
	end

	self.faceRot  = Helper.dirToRotation(self.shootDir)
	self.startRot = self.faceRot - self.BackOffset
	self.parkPos, self.startPos = Helper.parkAndStartForRay(self.Contents, self.Target, self.shootDir, self.Margin)

	local ksrc = KNIFES:FindFirstChild(kind)
	if not ksrc then
		self._Alive = false
		return self
	end
	local knife = ksrc:Clone() :: GuiObject
	knife.AnchorPoint = Vector2.new(0.5, 0.5)
	knife.Parent = attacksFolder
	knife.Position = UDim2.new(0.5, self.startPos.X, 0.5, self.startPos.Y)
	knife.Rotation = self.startRot
	self.KnifeGui = knife

	local attacks = state.Attacks
	attacks[knife] = {
		Kind    = "Knife",
		Mode    = kind,
		Pos     = self.startPos,
		Dmg     = 0,
		Rot     = self.startRot,
		AbsSize = knife.AbsoluteSize,
		Destroy = function()
			if attacks[knife] then attacks[knife] = nil end
			if knife then knife:Destroy() end
		end,
	}
	self.Atk = attacks[knife]

	if self.Phase == "INDICATE" then
		local ind = INDICATOR:Clone()
		ind.AnchorPoint = Vector2.new(0.5, 0.5)
		ind.Parent      = self.Contents
		ind.Position    = UDim2.new(0.5, Helper.roundpx(self.Target.X), 0.5, Helper.roundpx(self.Target.Y))
		
		self.Indicator = ind
		local exc = ind:FindFirstChild("Exclamation")
		if exc and exc:IsA("ImageLabel") then
			self.Exclaim = exc
			self.Exclaim.ImageTransparency = 0.25
		end
	end

	local function buildIndicatedGeometry()
		local dirs, parkR, throwR = Helper.sharedIndicatorRadii(self.Contents, self.Target, self.Margin, self.BackOffset)
		self.Multi.N     = 0
		self.Multi.Phase = "SPAWN"
		self.Multi.PSec  = 0

		for i = 1, 4 do
			local dIn = dirs[i]
			local park, startPos = Helper.parkAndStartForRay(self.Contents, self.Target, dIn, self.Margin)
			local fromTH = self.Target - dIn * throwR
			local rF  = Helper.dirToRotation(dIn)
			local rS  = rF - self.BackOffset

			local gsrc = KNIFES:FindFirstChild(self.Kind)
			if gsrc then
				local g = gsrc:Clone() :: GuiObject
				g.AnchorPoint = Vector2.new(0.5, 0.5)
				g.Parent = attacksFolder
				g.Position = UDim2.new(0.5, Helper.roundpx(startPos.X), 0.5, Helper.roundpx(startPos.Y))
				g.Rotation = rS

				self.Multi.N += 1
				local idx = self.Multi.N
				self.Multi.Guis[idx]   = g
				self.Multi.Dirs[idx]   = dIn
				self.Multi.Start[idx]  = startPos
				self.Multi.Park[idx]   = self.Target - dIn * parkR
				self.Multi.FromTH[idx] = fromTH
				self.Multi.Pos[idx]    = startPos
				self.Multi.RotS[idx]   = rS
				self.Multi.RotF[idx]   = rF

				local a = {
					Kind    = "Knife",
					Mode    = self.Kind,
					Pos     = startPos,
					Dmg     = 0,
					Rot     = rS,
					AbsSize = g.AbsoluteSize,
					Destroy = function()
						if state.Attacks[g] then state.Attacks[g] = nil end
						if g then g:Destroy() end
					end,
				}
				state.Attacks[g] = a
				self.Multi.Atk[idx] = a
			end
		end
	end

	Module.Compute[self.UUID] = function(dt: number)
		if not self._Alive then return end

		if not self._once then
			self._c0   = Color3.fromRGB(255,234,0)
			self._c1   = Color3.fromRGB(255, 64,64)
			self._once = true
		end

		local dtSec = Helper.toSec(dt)
		local scale = Helper.unitScale(self.Contents, self.State.Arena.BaselineMin)

		self.TimeSec  += dtSec
		self.PhaseSec += dtSec

		if self.Multi and self.Multi.Phase ~= "NONE" then
			local M = self.Multi
			M.PSec += dtSec

			local Guis, Atk, Pos, Start, Park, RotS, RotF, Dirs, FromTH =
				M.Guis, M.Atk, M.Pos, M.Start, M.Park, M.RotS, M.RotF, M.Dirs, M.FromTH

			if M.Phase == "SPAWN" then
				if not self.Sounded then self.Signals.spawnSound:Fire(SOUND); self.Sounded = true end

				local t  = math.clamp(M.PSec / self.SpawnTime, 0, 1)
				local tt = Helper.easeOutCubic(t)

				for i = 1, M.N do
					local s, p = Start[i], Park[i]
					local r = RotS[i] + (RotF[i] - RotS[i]) * tt
					local x = s.X + (p.X - s.X) * tt
					local y = s.Y + (p.Y - s.Y) * tt
					local v2 = Vector2.new(x, y)
					Pos[i] = v2

					local g = Guis[i]
					if g then
						g.Position = UDim2.new(0.5, Helper.roundpx(x), 0.5, Helper.roundpx(y))
						g.Rotation = r
					end
					local a = Atk[i]
					if a then
						if Helper.setRotAndCacheAabb then Helper.setRotAndCacheAabb(a, r) else a.Rot = r end
						a.Pos = v2
						a.Dmg = 0
					end
				end

				if t >= 1 then
					M.Phase = "TELEGRAPH"
					M.PSec  = 0
					for i = 1, M.N do
						local g = Guis[i]; if g then g.Rotation = RotF[i] end
						local a = Atk[i];  if a then
							if Helper.setRotAndCacheAabb then Helper.setRotAndCacheAabb(a, RotF[i]) else a.Rot = RotF[i] end
						end
					end
				end
				return
			end

			if M.Phase == "TELEGRAPH" then
				local t  = math.clamp(M.PSec / self.TeleTime, 0, 1)
				local d  = self.BackOffset * Helper.easeOutCubic(t)

				for i = 1, M.N do
					local pos = Park[i] - Dirs[i] * d
					Pos[i] = pos

					local g = Guis[i]
					if g then
						g.Position = UDim2.new(0.5, Helper.roundpx(pos.X), 0.5, Helper.roundpx(pos.Y))
					end
					local a = Atk[i]
					if a then
						a.Pos = pos
						a.Dmg = 0
					end
				end

				if t >= 1 then
					M.Phase = "THROW"
					M.PSec  = 0
					for i = 1, M.N do
						Pos[i] = FromTH[i]
					end
				end
				return
			end

			if M.Phase == "THROW" then
				local step = self.ThrowSpeed * scale * dtSec
				for i = 1, M.N do
					local pos = Pos[i] + Dirs[i] * step
					Pos[i] = pos

					local g = Guis[i]
					if g then
						g.Position = UDim2.new(0.5, Helper.roundpx(pos.X), 0.5, Helper.roundpx(pos.Y))
					end
					local a = Atk[i]
					if a then
						a.Pos = pos
						a.Dmg = self.Damage
					end
				end

				if M.PSec >= self.MultiTTL then
					self:Destroy()
				end
				return
			end
		end

		if self.Phase == "INDICATE" then
			if self.Indicator then
				local t = math.clamp(self.PhaseSec / self.IndicatorTime, 0, 1)
				self.Indicator.ImageColor3 = self._c0:Lerp(self._c1, t)
				if self.Exclaim then
					self.Exclaim.ImageColor3 = self.Indicator.ImageColor3
					local s = 0.5 - 0.5 * math.cos(2 * math.pi * (self.TimeSec * 3.0))
					self.Exclaim.ImageTransparency = 0.25 + 0.75 * s
				end
			end

			if self.PhaseSec >= self.IndicatorTime then
				if self.Indicator then
					self.Indicator:Destroy()
					self.Indicator = nil
					self.Exclaim = nil
				end
				self.PhaseSec = 0
				buildIndicatedGeometry()
				self.Phase = "MULTI"
				if self.KnifeGui then self.KnifeGui.Visible = false end
			end
			return
		end

		if self.Phase == "SPAWN" then
			if not self.Sound then
				self.Signals.spawnSound:Fire(SOUND)
				self.Sound = true
			end

			local t  = math.clamp(self.PhaseSec / self.SpawnTime, 0, 1)
			local tt = Helper.easeOutCubic(t)

			local x = self.startPos.X + (self.parkPos.X - self.startPos.X) * tt
			local y = self.startPos.Y + (self.parkPos.Y - self.startPos.Y) * tt
			local r = self.startRot   + (self.faceRot   - self.startRot)   * tt

			self.KnifeGui.Position = UDim2.new(0.5, Helper.roundpx(x), 0.5, Helper.roundpx(y))
			self.KnifeGui.Rotation = r

			if Helper.setRotAndCacheAabb then Helper.setRotAndCacheAabb(self.Atk, r) else self.Atk.Rot = r end
			self.Atk.Pos = Vector2.new(x, y)
			self.Atk.Dmg = 0

			if t >= 1 then
				self.Phase   = "TELEGRAPH"
				self.PhaseSec= 0
				if self.KnifeGui then self.KnifeGui.Rotation = self.faceRot end
				if Helper.setRotAndCacheAabb then Helper.setRotAndCacheAabb(self.Atk, self.faceRot) else self.Atk.Rot = self.faceRot end
			end
			return
		end

		if self.Phase == "TELEGRAPH" then
			local t   = math.clamp(self.PhaseSec / self.TeleTime, 0, 1)
			local d   = self.BackOffset * Helper.easeOutCubic(t)
			local pos = self.parkPos - self.shootDir * d

			self.KnifeGui.Position = UDim2.new(0.5, Helper.roundpx(pos.X), 0.5, Helper.roundpx(pos.Y))
			self.Atk.Pos = pos
			self.Atk.Dmg = 0

			if t >= 1 then
				self.Phase    = "THROW"
				self.PhaseSec = 0
				self.ThrowSec = 0
				if self.KnifeGui then self.KnifeGui.Rotation = self.faceRot end
			end
			return
		end

		if self.Phase == "THROW" then
			self.ThrowSec += dtSec
			local step = self.ThrowSpeed * scale * dtSec

			local pos = self.Atk.Pos + self.shootDir * step
			self.KnifeGui.Position = UDim2.new(0.5, Helper.roundpx(pos.X), 0.5, Helper.roundpx(pos.Y))
			self.Atk.Pos = pos
			self.Atk.Dmg = self.Damage

			if self.ThrowSec >= self.ThrowTTL then
				self:Destroy()
			end
			return
		end
	end

	return self
end

function Module:Destroy()
	if not self._Alive then return end
	self._Alive = false
	if self.UUID and Module.Compute[self.UUID] then Module.Compute[self.UUID] = nil end

	local attacks = self.State and self.State.Attacks
	if self.Atk and attacks then attacks[self.KnifeGui] = nil end
	if self.KnifeGui then self.KnifeGui:Destroy() end
	if self.Indicator then self.Indicator:Destroy() end

	for i = 1, self.Multi.N do
		local g = self.Multi.Guis[i]
		if attacks and g and attacks[g] then attacks[g] = nil end
		if g then g:Destroy() end
	end

	table.clear(self)
	setmetatable(self, nil)
end

function Module.Step(dt: number)
	for _, fn in pairs(Module.Compute) do fn(dt) end
end

--== Return ==--
return Module