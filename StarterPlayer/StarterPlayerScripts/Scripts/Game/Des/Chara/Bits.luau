--== Imports ==--
local HttpService = game:GetService("HttpService")

local Helper = require("./Helper")

--== Types ==--
export type Params = {
	fromGui: GuiObject?,
	ttl: number?,
	gravity: number?,
	vxMin: number?,
	vxMax: number?,
	vyMin: number?,
	vyMax: number?,
	spinMin: number?,
	spinMax: number?,
	damage: number?,
}

--== Constants ==--
local DEFAULTS = {
	ttl     = 2.2,
	gravity = 520,
	vxMin   = -120,
	vxMax   =  120,
	vyMin   =  120,
	vyMax   =  180,
	spinMin = -240,
	spinMax =  240,
}

local SPRITES = script.Parent.Assets.Sprites
local RNG     = Random.new()

--== Module ==--
local Module = {}
Module.__index = Module
Module.Compute = {} :: { [string]: (dt: number) -> () }

--== Lifecycle ==--
function Module.new(state, contents: GuiObject, kind: string, count: number, offset: Vector2, params: Params?)
	params = params or {}

	local ttl     = params.ttl     or DEFAULTS.ttl
	local gravity = params.gravity or DEFAULTS.gravity
	local vxMin   = params.vxMin   or DEFAULTS.vxMin
	local vxMax   = params.vxMax   or DEFAULTS.vxMax
	local vyMin   = params.vyMin   or DEFAULTS.vyMin
	local vyMax   = params.vyMax   or DEFAULTS.vyMax
	local spinMin = params.spinMin or DEFAULTS.spinMin
	local spinMax = params.spinMax or DEFAULTS.spinMax
	local damage  = params.damage

	local attacksFolder, visualsFolder = Helper.resolveEffectFolders(contents)

	local basePos: Vector2
	if params.fromGui then
		basePos = Helper.absToCenteredOffset(Helper.centerAbs(params.fromGui), contents) + offset
	else
		basePos = offset
	end

	local root = (SPRITES:FindFirstChild("Bits") and SPRITES.Bits:FindFirstChild(kind)) or SPRITES:FindFirstChild(kind)
	if not root then return nil end

	local self = setmetatable({
		State     = state,
		Contents  = contents,
		Folder    = visualsFolder,
		Kind      = kind,

		UUID  = HttpService:GenerateGUID(false),
		Alive = true,

		TTL   = ttl,
		Time  = 0,

		Guis = {} :: {ImageLabel},
		Pos  = {} :: {Vector2},
		Vel  = {} :: {Vector2},
		Rot  = {} :: {number},
		Spin = {} :: {number},
		Kill = {} :: { [GuiObject]: () -> () },
	}, Module)

	for i = 1, math.max(1, count or 1) do
		local pick = Helper.randomChild(root)
		if not pick or not pick:IsA("ImageLabel") then continue end

		local g = pick:Clone()
		g.AnchorPoint = Vector2.new(0.5, 0.5)
		g.Parent = visualsFolder

		local scale = Helper.unitScale(self.Contents, self.State.Arena.BaselineMin)
		local vx    = RNG:NextNumber(vxMin, math.max(vxMin, vxMax)) * scale
		local vy    = -RNG:NextNumber(vyMin, math.max(vyMin, vyMax)) * scale

		local rot  = RNG:NextNumber(0, 360)
		local spin = RNG:NextNumber(spinMin, spinMax)

		self.Guis[i] = g
		self.Pos[i]  = basePos
		self.Vel[i]  = Vector2.new(vx, vy)
		self.Rot[i]  = rot
		self.Spin[i] = spin

		g.Position = UDim2.new(0.5, Helper.roundpx(basePos.X), 0.5, Helper.roundpx(basePos.Y))
		g.Rotation = rot
		if damage and damage > 0 then
			g.Parent = attacksFolder
			self.State.Attacks[g] = {
				Kind    = "Bits",
				Pos     = basePos,
				Size    = g.AbsoluteSize,
				Dmg     = damage,
				Destroy = function()
					self.State.Attacks[g] = nil
					if g then g:Destroy() end
				end,
			}
		else
			self.State.Visuals[g] = {
				Kind = kind,
				Size = Vector2.new(g.AbsoluteSize.X, g.AbsoluteSize.Y),
				Pos  = basePos,
				AbsPos  = Helper.centerAbs(g),
				AbsSize = g.AbsoluteSize,
				Destroy = function()
					self.State.Visuals[g] = nil
					if g then g:Destroy() end
				end,
			}
		end
	end

	Module.Compute[self.UUID] = function(dt: number)
		if not self.Alive then return end
		local dtSec = Helper.toSec(dt)
		local scale = Helper.unitScale(self.Contents, self.State.Arena.BaselineMin)

		self.Time += dtSec

		local centerOffset, halfW, halfH = Helper.getDeadzoneRect(self.Contents)
		local contentsAbs = Helper.centerAbs(self.Contents)
		local gy = gravity * scale * dtSec
		local rpx = Helper.roundpx

		local Guis, Pos, Vel, Rot, Spin = self.Guis, self.Pos, self.Vel, self.Rot, self.Spin
		local Visuals = self.State and self.State.Visuals or nil
		local Attacks = self.State and self.State.Attacks or nil
		self._gSize = self._gSize or {}

		for idx = #Guis, 1, -1 do
			local g = Guis[idx]
			if not g then
				table.remove(Guis, idx)
				table.remove(Pos,  idx)
				table.remove(Vel,  idx)
				table.remove(Rot,  idx)
				table.remove(Spin, idx)
			else
				local p0 = Pos[idx]
				local v0 = Vel[idx]
				local vY = v0.Y + gy
				v0 = Vector2.new(v0.X, vY)
				local p1 = Vector2.new(p0.X + v0.X * dtSec, p0.Y + vY * dtSec)

				local lp1 = p1 - centerOffset
				if math.abs(lp1.X) > halfW or math.abs(lp1.Y) > halfH then
					local k = self.Kill[g]
					if k then
						k()
					else
						if Visuals and Visuals[g] then Visuals[g] = nil end
						if Attacks and Attacks[g] then Attacks[g] = nil end
						g:Destroy()
						table.remove(Guis, idx)
						table.remove(Pos,  idx)
						table.remove(Vel,  idx)
						table.remove(Rot,  idx)
						table.remove(Spin, idx)
					end
				else
					Pos[idx] = p1
					Vel[idx] = v0

					local s = Spin[idx]
					if s ~= 0 then
						local r = Rot[idx] + s * dtSec
						Rot[idx] = r
						g.Rotation = r
					end

					g.Position = UDim2.new(0.5, rpx(p1.X), 0.5, rpx(p1.Y))

					if Visuals then
						local v = Visuals[g]
						if v then
							v.Pos = p1
							v.AbsPos = Vector2.new(contentsAbs.X + p1.X, contentsAbs.Y + p1.Y)
							local sz = self._gSize[g]
							if not sz then sz = g.AbsoluteSize; self._gSize[g] = sz end
							v.AbsSize = sz
						end
					end

					if Attacks then
						local a = Attacks[g]
						if a then
							a.Pos = p1
							local sz = self._gSize[g]
							if not sz then sz = g.AbsoluteSize; self._gSize[g] = sz end
							a.Size = sz
						end
					end
				end
			end
		end

		if self.Time >= self.TTL or #Guis == 0 then
			self:Destroy()
		end
	end

	return self
end

function Module:Destroy()
	if not self.Alive then return end
	self.Alive = false
	if self.UUID and Module.Compute[self.UUID] then Module.Compute[self.UUID] = nil end

	for i = 1, #self.Guis do
		local g = self.Guis[i]
		if g then
			if self.State and self.State.Visuals and self.State.Visuals[g] then
				self.State.Visuals[g] = nil
			end
			if self.State and self.State.Attacks and self.State.Attacks[g] then
				self.State.Attacks[g] = nil
			end
			g:Destroy()
		end
	end

	table.clear(self)
	setmetatable(self, nil)
end

function Module.Step(dt: number)
	for _, fn in pairs(Module.Compute) do fn(dt) end
end

--== Return ==--
return Module