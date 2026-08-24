--== Imports ==--
local SoundService = game:GetService("SoundService")

--== Module ==--
local Helper = {}

--== Time ==--
local DT_MIN = 1/240
local DT_MAX = 0.06

function Helper.toFrame(dtSeconds: number, minSec: number?, maxSec: number?): number
	local lo = minSec or DT_MIN
	local hi = maxSec or DT_MAX
	return math.clamp(dtSeconds, lo, hi) * 60
end

function Helper.toSec(dtFrames: number, minSec: number?, maxSec: number?): number
	local lo = minSec or DT_MIN
	local hi = maxSec or DT_MAX
	local dtSec = dtFrames / 60
	if dtSec < lo then return lo end
	if dtSec > hi then return hi end
	return dtSec
end

--== Easing ==--
function Helper.easeInQuad(t: number): number
	t = math.clamp(t, 0, 1); return t * t
end
function Helper.easeOutQuad(t: number): number
	t = math.clamp(t, 0, 1); return 1 - (1 - t) * (1 - t)
end
function Helper.easeInOutQuad(t: number): number
	t = math.clamp(t, 0, 1); if t < 0.5 then return 2 * t * t end; return 1 - ((-2 * t + 2)^2) / 2
end

function Helper.easeInCubic(t: number): number
	t = math.clamp(t, 0, 1); return t * t * t
end
function Helper.easeOutCubic(t: number): number
	t = math.clamp(t, 0, 1); return 1 - (1 - t)^3
end
function Helper.easeInOutCubic(t: number): number
	t = math.clamp(t, 0, 1); if t < 0.5 then return 4 * t^3 end; return 1 - ((-2 * t + 2)^3) / 2
end

function Helper.easeInQuart(t: number): number
	t = math.clamp(t, 0, 1); return t^4
end
function Helper.easeOutQuart(t: number): number
	t = math.clamp(t, 0, 1); return 1 - (1 - t)^4
end
function Helper.easeInOutQuart(t: number): number
	t = math.clamp(t, 0, 1); if t < 0.5 then return 8 * t^4 end; return 1 - ((-2 * t + 2)^4) / 2
end

function Helper.easeInQuint(t: number): number
	t = math.clamp(t, 0, 1); return t^5
end
function Helper.easeOutQuint(t: number): number
	t = math.clamp(t, 0, 1); return 1 - (1 - t)^5
end
function Helper.easeInOutQuint(t: number): number
	t = math.clamp(t, 0, 1); if t < 0.5 then return 16 * t^5 end; return 1 - ((-2 * t + 2)^5) / 2
end

function Helper.easeInSine(t: number): number
	t = math.clamp(t, 0, 1); return 1 - math.cos((t * math.pi) / 2)
end
function Helper.easeOutSine(t: number): number
	t = math.clamp(t, 0, 1); return math.sin((t * math.pi) / 2)
end
function Helper.easeInOutSine(t: number): number
	t = math.clamp(t, 0, 1); return -(math.cos(math.pi * t) - 1) / 2
end

function Helper.easeInExpo(t: number): number
	t = math.clamp(t, 0, 1); if t == 0 then return 0 end; return 2^(10 * t - 10)
end
function Helper.easeOutExpo(t: number): number
	t = math.clamp(t, 0, 1); if t == 1 then return 1 end; return 1 - 2^(-10 * t)
end
function Helper.easeInOutExpo(t: number): number
	t = math.clamp(t, 0, 1)
	if t == 0 then return 0 end
	if t == 1 then return 1 end
	if t < 0.5 then return 2^(20 * t - 10) / 2 end
	return (2 - 2^(-20 * t + 10)) / 2
end

function Helper.easeInCirc(t: number): number
	t = math.clamp(t, 0, 1); return 1 - math.sqrt(1 - t * t)
end
function Helper.easeOutCirc(t: number): number
	t = math.clamp(t, 0, 1); return math.sqrt(1 - (t - 1)^2)
end
function Helper.easeInOutCirc(t: number): number
	t = math.clamp(t, 0, 1)
	if t < 0.5 then return (1 - math.sqrt(1 - (2 * t)^2)) / 2 end
	return (math.sqrt(1 - (-2 * t + 2)^2) + 1) / 2
end

function Helper.easeInBack(t: number, s: number?): number
	s = s or 1.70158; t = math.clamp(t, 0, 1); return (s + 1) * t^3 - s * t^2
end
function Helper.easeOutBack(t: number, s: number?): number
	s = s or 1.70158; t = math.clamp(t, 0, 1) - 1; return 1 + (s + 1) * t^3 + s * t^2
end
function Helper.easeInOutBack(t: number, s: number?): number
	s = (s or 1.70158) * 1.525; t = math.clamp(t, 0, 1)
	if t < 0.5 then return (t * 2)^2 * ((s + 1) * (t * 2) - s) / 2 end
	local u = (t * 2) - 2; return (u^2 * ((s + 1) * u + s) + 2) / 2
end

function Helper.expSmoothing(dt: number, k: number?): number
	k = k or 1
	return 1 - math.exp(-k * dt)
end

--== Grid ==--
function Helper.gridCenters(container: GuiObject, rows: number, cols: number, marginPx: number?, snapPx: number?): {Vector2}
	rows     = math.max(1, math.floor(rows))
	cols     = math.max(1, math.floor(cols))
	marginPx = math.max(0, marginPx or 0)

	local sz   = container.AbsoluteSize
	local innerW = math.max(0, sz.X - 2*marginPx)
	local innerH = math.max(0, sz.Y - 2*marginPx)

	local stepX = innerW / cols
	local stepY = innerH / rows

	local out = {}
	for r = 1, rows do
		local cy = -innerH * 0.5 + (r - 0.5) * stepY
		for c = 1, cols do
			local cx = -innerW * 0.5 + (c - 0.5) * stepX
			if snapPx and snapPx > 0 then
				cx = Helper.snapMultiple(cx, snapPx)
				cy = Helper.snapMultiple(cy, snapPx)
			else
				cx = Helper.roundpx(cx)
				cy = Helper.roundpx(cy)
			end
			table.insert(out, Vector2.new(cx, cy))
		end
	end
	return out
end

function Helper.snapMultiple(v: number, unit: number): number
	if unit <= 0 then return v end
	local k = v / unit
	local r = (k >= 0) and math.floor(k + 0.5) or math.ceil(k - 0.5)
	return r * unit
end

--== Geometry ==--
function Helper.unitScale(gui: GuiObject): number
	local bx = 500
	local by = 200

	local s = gui.AbsoluteSize
	return math.max(s.X / bx, s.Y / by)
end

function Helper.dirToRotation(v: Vector2): number
	return math.deg(math.atan2(v.Y, v.X)) + 90
end

function Helper.dirFromAngle(deg: number): Vector2
	local r = math.rad(deg)
	return Vector2.new(math.cos(r), math.sin(r))
end

function Helper.edgeDistanceToRectAlong(p: Vector2, v: Vector2, halfW: number, halfH: number): number
	local bestT = math.huge
	if math.abs(v.X) > 1e-6 then
		local xEdge = (v.X > 0) and halfW or -halfW
		local t = (xEdge - p.X) / v.X
		if t >= 0 then
			local y = p.Y + v.Y * t
			if math.abs(y) <= halfH + 1e-4 and t < bestT then bestT = t end
		end
	end
	if math.abs(v.Y) > 1e-6 then
		local yEdge = (v.Y > 0) and halfH or -halfH
		local t = (yEdge - p.Y) / v.Y
		if t >= 0 then
			local x = p.X + v.X * t
			if math.abs(x) <= halfW + 1e-4 and t < bestT then bestT = t end
		end
	end
	if bestT == math.huge then bestT = math.max(halfW, halfH) end
	return bestT
end

function Helper.parkAndStartForRay(contents: GuiObject, target: Vector2, dirIn: Vector2, margin: number, extraStartPx: number?): (Vector2, Vector2)
	local halfW, halfH = contents.AbsoluteSize.X * 0.5, contents.AbsoluteSize.Y * 0.5
	local edgeDist = Helper.edgeDistanceToRectAlong(target, -dirIn, halfW, halfH)
	local park = target - dirIn * (edgeDist + margin)
	local off  = extraStartPx or (math.max(contents.AbsoluteSize.X, contents.AbsoluteSize.Y) * 0.75 + 200)
	return park, (park - dirIn * off)
end

function Helper.sharedIndicatorRadii(contents: GuiObject, target: Vector2, margin: number, backOffset: number)
	local halfW, halfH = contents.AbsoluteSize.X * 0.5, contents.AbsoluteSize.Y * 0.5
	local dirs = {
		Vector2.new(-1,-1).Unit,
		Vector2.new( 1,-1).Unit,
		Vector2.new(-1, 1).Unit,
		Vector2.new( 1, 1).Unit,
	}
	local maxEdge = 0
	for i = 1, 4 do
		local d = dirs[i]
		local t = Helper.edgeDistanceToRectAlong(target, -d, halfW, halfH)
		if t > maxEdge then maxEdge = t end
	end
	local parkRadius       = maxEdge + margin
	local throwStartRadius = parkRadius + backOffset
	return dirs, parkRadius, throwStartRadius
end

--== Coordinates ==--
function Helper.centerAbs(gui: GuiObject): Vector2
	local p, s = gui.AbsolutePosition, gui.AbsoluteSize
	return Vector2.new(p.X + s.X * 0.5, p.Y + s.Y * 0.5)
end

function Helper.absToCenteredOffset(absPos: Vector2, container: GuiObject): Vector2
	local localPos = absPos - container.AbsolutePosition
	local centered = localPos - container.AbsoluteSize * 0.5
	local x = (centered.X >= 0) and math.floor(centered.X + 0.5) or math.ceil(centered.X - 0.5)
	local y = (centered.Y >= 0) and math.floor(centered.Y + 0.5) or math.ceil(centered.Y - 0.5)
	return Vector2.new(x, y)
end

function Helper.roundpx(v: number): number
	return (v >= 0) and math.floor(v + 0.5) or math.ceil(v - 0.5)
end

function Helper.snapToGrid(v: number, step: number, origin: number?): number
	step = (step and step ~= 0) and step or 1
	origin = origin or 0
	local q = (v - origin) / step
	local n = (q >= 0) and math.floor(q + 0.5) or math.ceil(q - 0.5)
	return origin + n * step
end

function Helper.snapV2ToGrid(p: Vector2, stepX: number, stepY: number, origin: Vector2?): Vector2
	origin = origin or Vector2.zero
	return Vector2.new(
		Helper.snapToGrid(p.X, stepX, origin.X),
		Helper.snapToGrid(p.Y, stepY, origin.Y)
	)
end

function Helper.snapUDim2Offset(u: UDim2, stepX: number, stepY: number, origin: Vector2?): UDim2
	origin = origin or Vector2.zero
	return UDim2.new(
		u.X.Scale, Helper.snapToGrid(u.X.Offset, stepX, origin.X),
		u.Y.Scale, Helper.snapToGrid(u.Y.Offset, stepY, origin.Y)
	)
end

--== Containers ==--
function Helper.resolveEffectFolders(contents: Instance)
	return contents:FindFirstChild("Attacks") :: Folder, contents:FindFirstChild("Visuals") :: Folder
end

function Helper.getDeadzoneRect(contents: GuiObject)
	local dz = contents:FindFirstChild("_Deadzone")
	if dz and dz:IsA("GuiObject") then
		local c = Helper.centerAbs(contents)
		local d = Helper.centerAbs(dz)
		local centerOffset = d - c
		local sz = dz.AbsoluteSize
		return centerOffset, sz.X * 0.5, sz.Y * 0.5
	else
		local sz = contents.AbsoluteSize
		return Vector2.zero, sz.X * 0.5, sz.Y * 0.5
	end
end

--== Ray ==--
function Helper.rayHitRectEdge(p: Vector2, v: Vector2, halfW: number, halfH: number, margin: number): Vector2
	local bestT = math.huge
	local best: Vector2? = nil
	if math.abs(v.X) > 1e-6 then
		local xEdge = (v.X > 0) and halfW or -halfW
		local t = (xEdge - p.X) / v.X
		if t >= 0 then
			local y = p.Y + v.Y * t
			if math.abs(y) <= halfH + 1e-4 and t < bestT then bestT = t; best = Vector2.new(xEdge, y) end
		end
	end
	if math.abs(v.Y) > 1e-6 then
		local yEdge = (v.Y > 0) and halfH or -halfH
		local t = (yEdge - p.Y) / v.Y
		if t >= 0 then
			local x = p.X + v.X * t
			if math.abs(x) <= halfW + 1e-4 and t < bestT then bestT = t; best = Vector2.new(x, yEdge) end
		end
	end
	if not best then best = p + v.Unit * math.max(halfW, halfH) end
	return best + v.Unit * (margin or 0)
end

function Helper.rayHitDeadzoneEdge(p: Vector2, v: Vector2, contents: GuiObject, margin: number): Vector2
	local centerOffset, hw, hh = Helper.getDeadzoneRect(contents)
	local localP = p - centerOffset
	local hitLocal = Helper.rayHitRectEdge(localP, v, hw, hh, margin)
	return hitLocal + centerOffset
end

--== Collision ==--
function Helper.setRotAndCacheAabb(atk, rot: number)
	atk.Rot = rot
	local sx = (atk.AbsSize and atk.AbsSize.X) or (atk.Size and atk.Size.X)
	local sy = (atk.AbsSize and atk.AbsSize.Y) or (atk.Size and atk.Size.Y)
	if sx and sy then
		local bx, by = Helper.rotAabbHalf(0.5*sx, 0.5*sy, rot)
		atk._rHx, atk._rHy = bx, by
		atk._broadR = math.sqrt(bx*bx + by*by)
	end
end

function Helper.rotAabbHalf(hx: number, hy: number, rotDeg: number): (number, number)
	local r = math.rad(rotDeg)
	local c, s = math.cos(r), math.sin(r)
	local ex = math.abs(c)*hx + math.abs(s)*hy
	local ey = math.abs(s)*hx + math.abs(c)*hy
	return ex, ey
end

function Helper.axesFromDeg(deg: number): (number, number, number, number)
	local r = math.rad(deg)
	local ux, uy = math.cos(r), math.sin(r)
	local vx, vy = -uy, ux
	return ux, uy, vx, vy
end

function Helper.computeBroadRadius(atk, diag: number): number
	if atk._broadR then return atk._broadR end
	local r
	if atk.Radius then
		r = atk.Radius
	elseif atk.Size then
		local hx, hy = atk.Size.X * 0.5, atk.Size.Y * 0.5
		r = math.sqrt(hx*hx + hy*hy)
	elseif atk.AbsSize then
		local hx, hy = atk.AbsSize.X * 0.5, atk.AbsSize.Y * 0.5
		r = math.sqrt(hx*hx + hy*hy)
	else
		local baseLen = 2 * diag
		local ey = 0.5 * math.max(2, atk.Minor or 2)
		r = math.sqrt((0.5*baseLen)^2 + ey*ey)
	end
	atk._broadR = r
	return r
end

function Helper.setAttackRotation(atk, rot: number)
	atk.Rot = rot
	atk._ux, atk._uy, atk._vx, atk._vy = Helper.axesFromDeg(rot)
end

function Helper.touchAttackSize(atk)
	atk._broadR = nil
end

function Helper.intersectsAabbObb(aC: Vector2, ax: number, ay: number, bC: Vector2, bx: number, by: number, angDeg: number): boolean
	local r = math.rad(angDeg)
	local ux, uy = math.cos(r), math.sin(r)
	local vx, vy = -uy, ux
	local dx, dy = aC.X - bC.X, aC.Y - bC.Y
	local function overlapOn(axx, axy)
		local projC = math.abs(dx * axx + dy * axy)
		local rA = ax * math.abs(axx) + ay * math.abs(axy)
		local rB = bx * math.abs(axx * ux + axy * uy) + by * math.abs(axx * vx + axy * vy)
		return projC <= (rA + rB)
	end
	return overlapOn(1,0) and overlapOn(0,1) and overlapOn(ux,uy) and overlapOn(vx,vy)
end

function Helper.intersectsAabbCircle(aC: Vector2, ax: number, ay: number, cC: Vector2, r: number): boolean
	local dx = math.abs(cC.X - aC.X)
	local dy = math.abs(cC.Y - aC.Y)
	if dx > (ax + r) or dy > (ay + r) then return false end
	if dx <= ax or dy <= ay then return true end
	local cx = dx - ax
	local cy = dy - ay
	return (cx*cx + cy*cy) <= (r*r)
end

--== Utilities ==--
function Helper.scaleUDim2(u: UDim2, f: number): UDim2
	return UDim2.new(u.X.Scale * f, u.X.Offset * f, u.Y.Scale * f, u.Y.Offset * f)
end

function Helper.randomChild(container: Instance)
	if not container:IsA("Folder") then
		return container
	end
	local children = container:GetChildren()
	local n = #children
	if n == 0 then return nil end
	return children[math.random(1, n)]
end

--== Sound ==--
local _sounds = {}
function Helper.playLocalSound(sounds: Instance, name: string)
	local src = sounds:FindFirstChild(name)
	if not src or not src:IsA("Sound") then return end

	local sound  = src:Clone() :: Sound
	sound.Parent = SoundService
	sound:Play()
	table.insert(_sounds, sound)

	local i = #_sounds
	task.delay(sound.PlaybackRegion.Max - sound.PlaybackRegion.Min, function()
		table.remove(_sounds, i)
		if sound then
			sound:Destroy()
		end
	end)
end

function Helper.stopLocalSounds()
	for _, sound in ipairs(_sounds) do
		sound:Destroy()
	end
end

--== Return ==--
return Helper