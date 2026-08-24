--== Imports ==--
local HttpService = game:GetService("HttpService")

local Helper = require("./Helper")
local Bits   = require("./Bits")

--== Types ==--
export type Params = {
	fromGui: GuiObject?,
	pos: Vector2?,
	expandTime: number?,
	explodeTime: number?,
	explodeSize: Vector2?,
	damage: number?,
	attackSpace: GuiObject?,
	bitsCount: number?,
	bitsContainer: GuiObject?,
	bitsParams: Bits.Params?,
	easeAppear: "back" | "expo" | ((t:number)->number)?,
	easeExplode: "expo" | "back" | ((t:number)->number)?,
}

--== Constants ==--
local DEFAULTS = {
	expandTime  = 0.38,
	explodeTime = 1.42,
	explodeSize = Vector2.new(3, 3),
	damage      = 6,
	bitsCount   = 6,
	spawnMargin = 24,
}
local SOUND = "Explosion 2"
local EXPLOSION_DAMAGE_ALPHA_MAX = 0.5

local SPRITES = script.Parent.Assets.Sprites
local HEART   = SPRITES.Other.Heart
local RNG     = Random.new()

--== Module ==--
local Module = {}
Module.__index = Module
Module.Compute = {} :: { [string]: (dt: number) -> () }

--== Lifecycle ==--
function Module.new(signals, state, contents: GuiObject, params: Params?)
	params = params or {}

	local expandTime  = params.expandTime  or DEFAULTS.expandTime
	local explodeTime = params.explodeTime or DEFAULTS.explodeTime
	local explodeSize = params.explodeSize or DEFAULTS.explodeSize
	local damage      = params.damage      or DEFAULTS.damage
	local bitsCount   = params.bitsCount   or DEFAULTS.bitsCount
	local attackSpace = params.attackSpace or contents

	local easeA = params.easeAppear
	if type(easeA) == "string" then
		easeA = (easeA == "back" and Helper.easeOutBack) or Helper.easeOutExpo
	elseif type(easeA) ~= "function" then
		easeA = Helper.easeOutBack
	end

	local easeE = params.easeExplode
	if type(easeE) == "string" then
		easeE = (easeE == "back" and Helper.easeOutBack) or Helper.easeOutExpo
	elseif type(easeE) ~= "function" then
		easeE = Helper.easeOutExpo
	end

	local pos: Vector2
	if params.pos then
		pos = params.fromGui
			and (Helper.absToCenteredOffset(Helper.centerAbs(params.fromGui), contents) + params.pos)
			or  Vector2.new(Helper.roundpx(params.pos.X), Helper.roundpx(params.pos.Y))
	else
		local sz = contents.AbsoluteSize
		local hw, hh = sz.X * 0.5, sz.Y * 0.5
		local m = DEFAULTS.spawnMargin
		pos = Vector2.new(
			Helper.roundpx(RNG:NextNumber(-hw + m, hw - m)),
			Helper.roundpx(RNG:NextNumber(-hh + m, hh - m))
		)
	end

	local self = setmetatable({
		Signals = signals,

		State       = state,
		Contents    = contents,
		AttackSpace = attackSpace,

		ExpandTime  = expandTime,
		ExplodeTime = explodeTime,
		ExplodeSize = explodeSize,
		Damage      = damage,

		BitsCount = bitsCount,
		BitsParams= params.bitsParams,

		EaseAppear  = easeA :: (t:number)->number,
		EaseExplode = easeE :: (t:number)->number,

		UUID   = HttpService:GenerateGUID(false),
		Alive  = true,
		Phase  = "APPEAR",
		Time   = 0,

		Gui        = nil :: ImageLabel?,
		Scale      = nil :: UIScale?,
		Explosion  = nil :: GuiObject?,
		Atk        = nil :: any,
	}, Module)

	local heart = HEART:Clone() :: ImageLabel
	heart.AnchorPoint = Vector2.new(0.5, 0.5)
	heart.Position    = UDim2.new(0.5, pos.X, 0.5, pos.Y)
	heart.Parent      = contents

	local explosion = heart:FindFirstChild("Explosion") :: GuiObject
	explosion.AnchorPoint = Vector2.new(0.5, 0.5)
	explosion.Position    = UDim2.fromScale(0.5, 0.5)
	explosion.Size        = UDim2.fromOffset(0, 0)
	explosion.Visible     = false
	if explosion:IsA("ImageLabel") then
		explosion.ImageTransparency = 0
	else
		(explosion :: GuiObject).BackgroundTransparency = 0
	end

	self.Gui       = heart
	self.Scale     = heart:FindFirstChildOfClass("UIScale") :: UIScale
	self.Explosion = explosion
	
	self.Scale.Scale = 0

	Module.Compute[self.UUID] = function(dtFrame: number)
		if not self.Alive then return end
		local dt = Helper.toSec(dtFrame)
		self.Time += dt

		if self.Phase == "APPEAR" then
			if not self.Sounded then self.Signals.spawnSound:Fire(SOUND); self.Sounded = true end

			local t = math.clamp(self.Time / math.max(self.ExpandTime, 1e-6), 0, 1)
			self.Scale.Scale = self.EaseAppear(t)

			if t >= 1 then
				self.Phase = "EXPLODE"
				self.Time  = 0
				self.Gui.ImageTransparency = 1
				self.Explosion.Visible = true

				Bits.new(self.State, self.AttackSpace, "Gray", self.BitsCount, Vector2.zero, {
					fromGui = self.Gui,
					ttl     = self.BitsParams and self.BitsParams.ttl or nil,
					gravity = self.BitsParams and self.BitsParams.gravity or nil,
					vxMin   = self.BitsParams and self.BitsParams.vxMin or nil,
					vxMax   = self.BitsParams and self.BitsParams.vxMax or nil,
					vyMin   = self.BitsParams and self.BitsParams.vyMin or nil,
					vyMax   = self.BitsParams and self.BitsParams.vyMax or nil,
					spinMin = self.BitsParams and self.BitsParams.spinMin or nil,
					spinMax = self.BitsParams and self.BitsParams.spinMax or nil,
					damage  = damage,
				})

				local centerAbs = Helper.centerAbs(self.Gui)
				local atkPos = Helper.absToCenteredOffset(centerAbs, self.AttackSpace)
				self.State.Attacks[self.Explosion] = {
					Kind    = "GrayExplosion",
					Pos     = atkPos,
					Radius  = 0,
					Dmg     = 0,
					Destroy = function()
						if self.State and self.State.Attacks then
							self.State.Attacks[self.Explosion] = nil
						end
					end,
				}
				self.Atk = self.State.Attacks[self.Explosion]
			end
			return
		end

		if self.Phase == "EXPLODE" then
			if not self.Shaked then self.Signals.onShake:Fire({ amp = 12, freq = 10, duration = 0.2, falloff = "cubic" }); self.Shaked = true end

			local unit = (self.State and self.State.Arena and Helper.unitScale(self.AttackSpace, self.State.Arena.BaselineMin)) or 1
			local eff  = Vector2.new(self.ExplodeSize.X, self.ExplodeSize.Y)

			local t = math.clamp(self.Time / math.max(self.ExplodeTime, 1e-6), 0, 1)
			local k = self.EaseExplode(t)
			local w = math.lerp(0, eff.X, k)
			local h = math.lerp(0, eff.Y, k)

			self.Explosion.Size = UDim2.fromScale(w, h)

			local fade = k
			if self.Explosion:IsA("ImageLabel") then
				(self.Explosion :: ImageLabel).ImageTransparency = fade
			else
				(self.Explosion :: GuiObject).BackgroundTransparency = fade
			end

			if self.Atk then
				local centerAbs = Helper.centerAbs(self.Gui)
				self.Atk.Pos    = Helper.absToCenteredOffset(centerAbs, self.AttackSpace)
				self.Atk.Radius = 0.5 * math.min(w, h)
				self.Atk.Dmg    = (fade <= EXPLOSION_DAMAGE_ALPHA_MAX) and self.Damage or 0
			end

			if t >= 1 then
				self.Phase = "DONE"
				self.Time  = 0
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

	if self.State and self.State.Attacks and self.Atk then
		self.State.Attacks[self.Explosion] = nil
	end

	if self.Gui then self.Gui:Destroy() end

	self.Gui, self.Scale, self.Explosion, self.Atk = nil, nil, nil, nil
	table.clear(self)
	setmetatable(self, nil)
end

function Module.Step(dt: number)
	for _, fn in pairs(Module.Compute) do fn(dt) end
end

--== Return ==--
return Module