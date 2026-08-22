--== Imports ==--
local HttpService = game:GetService("HttpService")

local Helper = require("./Helper")
local Bits   = require("./Bits")

--== Types ==--
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
	spinSpeed: number?,
	bitsCount: number?,
	bitsParams: Bits.Params?,
	impactOffset: number?,
}

--== Constants ==--
local DEFAULTS = {
	damage        = 10,
	spawnTime     = 0.55,
	telegraphTime = 0.18,
	backOffset    = 64,
	throwSpeed    = 760,
	backRotDeg    = 50,
	margin        = 6,
	spinSpeed     = 360,
	bitsCount     = 6,
	impactOffset  = 2,
}
local SOUND = "Explosion 1"

local SPRITES = script.Parent.Assets.Sprites
local FLOWER  = SPRITES.Other.Flower
local RNG     = Random.new()

--== Module ==--
local Module = {}
Module.__index = Module
Module.Compute = {} :: { [string]: (dt: number) -> () }

--== Lifecycle ==--
function Module.new(signals, state, contents: GuiObject, params: Params?)
	params = params or {}

	local damage        = params.damage        or DEFAULTS.damage
	local spawnTime     = params.spawnTime     or DEFAULTS.spawnTime
	local telegraphTime = params.telegraphTime or DEFAULTS.telegraphTime
	local backOffset    = params.backOffset    or DEFAULTS.backOffset
	local throwSpeed    = params.throwSpeed    or DEFAULTS.throwSpeed
	local backRotDeg    = params.backRotDeg    or DEFAULTS.backRotDeg
	local margin        = params.margin        or DEFAULTS.margin
	local spawnSide     = params.spawnSide
	local spinSpeed     = params.spinSpeed     or DEFAULTS.spinSpeed
	local bitsCount     = params.bitsCount     or DEFAULTS.bitsCount
	local impactOffset  = params.impactOffset  or DEFAULTS.impactOffset

	local attacksFolder = Helper.resolveEffectFolders(contents)

	local target: Vector2
	if params.fromGui and params.targetPos then
		target = Helper.absToCenteredOffset(Helper.centerAbs(params.fromGui), contents) + params.targetPos
	elseif params.targetPos then
		target = Vector2.new(Helper.roundpx(params.targetPos.X), Helper.roundpx(params.targetPos.Y))
	else
		target = state.Player and state.Player.Pos or Vector2.zero
	end

	local dirIn: Vector2
	if     spawnSide == "Left"   then dirIn = Vector2.new( 1, 0)
	elseif spawnSide == "Right"  then dirIn = Vector2.new(-1, 0)
	elseif spawnSide == "Top"    then dirIn = Vector2.new( 0, 1)
	elseif spawnSide == "Bottom" then dirIn = Vector2.new( 0,-1)
	else
		local v = target.Magnitude > 1e-6 and -target.Unit or Vector2.new(1,0)
		dirIn = v
	end

	local faceRot       = Helper.dirToRotation(dirIn)
	local startRot      = faceRot - backRotDeg
	local parkPos, startPos = Helper.parkAndStartForRay(contents, target, dirIn, margin)
	local impactPos     = parkPos - dirIn * impactOffset

	local gui = FLOWER:Clone() :: GuiObject
	gui.AnchorPoint = Vector2.new(0.5, 0.5)
	gui.Parent = attacksFolder
	gui.Position = UDim2.new(0.5, startPos.X, 0.5, startPos.Y)
	gui.Rotation = startRot

	state.Attacks[gui] = {
		Kind    = "Flower",
		Pos     = startPos,
		Dmg     = 0,
		Rot     = startRot,
		AbsSize = gui.AbsoluteSize,
		Destroy = function()
			if state.Attacks[gui] then state.Attacks[gui] = nil end
			if gui then gui:Destroy() end
		end,
	}

	local self = setmetatable({
		Signals  = signals,
		State    = state,
		Contents = contents,

		Damage  = damage,
		SpawnTime  = spawnTime,
		TeleTime   = telegraphTime,
		BackOffset = backOffset,
		ThrowSpeed = throwSpeed,
		BackRot    = backRotDeg,
		Margin     = margin,
		SpinSpeed  = spinSpeed,
		BitsCount  = bitsCount,
		BitsParams = params.bitsParams,

		Target     = target,
		DirIn      = dirIn,
		ParkPos    = parkPos,
		ImpactPos  = impactPos,
		StartPos   = startPos,
		FaceRot    = faceRot,
		StartRot   = startRot,

		GUI        = gui,
		Atk        = state.Attacks[gui],

		TimeSec  = 0,
		PhaseSec = 0,
		SpinAcc  = 0,
		Phase    = "SPAWN",

		UUID     = HttpService:GenerateGUID(false),
	}, Module)

	Module.Compute[self.UUID] = function(dtFrame: number)
		local dt = Helper.toSec(dtFrame)

		self.TimeSec  += dt
		self.PhaseSec += dt

		if self.Phase == "SPAWN" then
			local t  = math.clamp(self.PhaseSec / self.SpawnTime, 0, 1)
			local tt = Helper.easeOutCubic(t)
			local x  = math.lerp(self.StartPos.X, self.ImpactPos.X, tt)
			local y  = math.lerp(self.StartPos.Y, self.ImpactPos.Y, tt)
			local r  = math.lerp(self.StartRot,   self.FaceRot,    tt)

			self.GUI.Position = UDim2.new(0.5, Helper.roundpx(x), 0.5, Helper.roundpx(y))
			self.GUI.Rotation = r
			self.Atk.Pos, self.Atk.Rot, self.Atk.Dmg = Vector2.new(x, y), r, 0

			if t >= 1 then
				self.Phase = "TELEGRAPH"
				self.PhaseSec = 0
			end
			return
		end

		if self.Phase == "TELEGRAPH" then
			local t  = math.clamp(self.PhaseSec / self.TeleTime, 0, 1)
			local d  = math.lerp(0, self.BackOffset, Helper.easeOutCubic(t))
			local p  = self.ImpactPos - self.DirIn * d

			self.GUI.Position = UDim2.new(0.5, Helper.roundpx(p.X), 0.5, Helper.roundpx(p.Y))
			self.GUI.Rotation = self.FaceRot
			self.Atk.Pos, self.Atk.Rot, self.Atk.Dmg = p, self.FaceRot, 0

			if t >= 1 then
				self.Phase = "THROW"
				self.PhaseSec = 0
				self.FromPos = p
				self.SpinAcc = 0
			end
			return
		end

		if self.Phase == "THROW" then
			if not self.Sounded then self.Signals.spawnSound:Fire(SOUND); self.Sounded = true end

			self.SpinAcc = (self.SpinAcc + self.SpinSpeed * dt) % 360
			local t  = math.clamp(self.PhaseSec / self.TeleTime, 0, 1)
			local tt = Helper.easeOutCubic(t)
			local x  = math.lerp(self.FromPos.X, self.ImpactPos.X, tt)
			local y  = math.lerp(self.FromPos.Y, self.ImpactPos.Y, tt)
			local r  = self.FaceRot + self.SpinAcc

			self.GUI.Position = UDim2.new(0.5, Helper.roundpx(x), 0.5, Helper.roundpx(y))
			self.GUI.Rotation = r
			self.Atk.Pos, self.Atk.Rot, self.Atk.Dmg = Vector2.new(x, y), r, 0

			if t >= 1 then
				if not self.Shaked then self.Signals.onShake:Fire({ amp = 12, freq = 10, duration = 0.2, falloff = "cubic" }); self.Shaked = true end

				Bits.new(self.State, self.Contents, "Yellow", self.BitsCount, Vector2.zero, {
					fromGui = self.GUI,
					damage  = self.Damage,
					ttl     = self.BitsParams and self.BitsParams.ttl or nil,
					gravity = self.BitsParams and self.BitsParams.gravity or nil,
					vxMin   = self.BitsParams and self.BitsParams.vxMin or nil,
					vxMax   = self.BitsParams and self.BitsParams.vxMax or nil,
					vyMin   = self.BitsParams and self.BitsParams.vyMin or nil,
					vyMax   = self.BitsParams and self.BitsParams.vyMax or nil,
					spinMin = self.BitsParams and self.BitsParams.spinMin or nil,
					spinMax = self.BitsParams and self.BitsParams.spinMax or nil,
				})

				self.Phase = "DONE"
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
	if self.UUID and Module.Compute[self.UUID] then Module.Compute[self.UUID] = nil end
	if self.State and self.State.Attacks and self.Atk then
		self.State.Attacks[self.GUI] = nil
	end
	if self.GUI then self.GUI:Destroy() end
	table.clear(self)
	setmetatable(self, nil)
end

function Module.Step(dt: number)
	for _, fn in pairs(Module.Compute) do fn(dt) end
end

--== Return ==--
return Module