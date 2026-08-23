--== Imports ==--
local contextActionService = game:GetService("ContextActionService")
local TweenService         = game:GetService("TweenService")

local Thumbstick = require("@self/Thumbstick")
local Helper     = require("./Helper")
local Bits       = require("./Bits")

--== Constants ==--
local TWEENS = {
	DMG       = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut),
	BREAK_OUT = TweenInfo.new(0.18, Enum.EasingStyle.Back,  Enum.EasingDirection.In),
	BREAK_IN  = TweenInfo.new(0.22, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
}
local DAMAGE_COOLDOWN_SEC = 0.5

local SPRITES  = script.Parent.Assets.Sprites.Slash
local FLIPBOOK = {
	FRAMES = 6,
	DELAY  = 0.12,
}

--== Module ==--
local Module = {}
Module.__index = Module

--== Private ==--
function Module:_flashDamage()
	local t1 = TweenService:Create(self.Controller, TWEENS.DMG, { ImageTransparency = 0.35 })
	local t2 = TweenService:Create(self.Controller, TWEENS.DMG, { ImageTransparency = 0 })
	t1:Play()
	t1.Completed:Once(function() t2:Play() end)
end

function Module:_damage(value: number)
	if os.clock() - (self._Tick or 0) < DAMAGE_COOLDOWN_SEC then return end
	self._Tick = os.clock()

	Bits.new(self.State, self.Contents, "Red", 1, Vector2.zero, { fromGui = self.Controller, visual = true })
	self:_flashDamage()
	self.Signals.onDamage:Fire(value)
end

function Module:_checkCollisions()
	local player = self.State.Player
	if player._Locked then return end
	if os.clock() - (self._Tick or 0) < DAMAGE_COOLDOWN_SEC then return end

	local heartPos = player.Pos
	local hx, hy   = player.Size.X * 0.5, player.Size.Y * 0.5
	local rPlayer  = math.max(hx, hy)

	local isMoving = (player.Vel.Magnitude > 0.01)
	local contents = self.Contents :: GuiObject
	local w, h     = contents.AbsoluteSize.X, contents.AbsoluteSize.Y
	local diag     = math.ceil(math.sqrt(w*w + h*h))

	local PROX_MARGIN_KNIFE = 14
	local PROX_MARGIN_BITS  = 6

	for _, atk in pairs(self.State.Attacks) do
		if not atk or not atk.Pos then continue end
		local dmg = atk.Dmg or 0
		if dmg <= 0 then continue end

		if atk.Kind == "Knife" then
			if atk.Mode == "MovePunish"  and not isMoving then continue end
			if atk.Mode == "StillPunish" and     isMoving then continue end

			local sx = (atk.AbsSize and atk.AbsSize.X) or (atk.Size and atk.Size.X)
			local sy = (atk.AbsSize and atk.AbsSize.Y) or (atk.Size and atk.Size.Y)
			local proxR = atk._proxR
			if not proxR then
				if sx and sy then
					proxR = math.sqrt((0.5*sx)^2 + (0.5*sy)^2) + PROX_MARGIN_KNIFE
				else
					proxR = Helper.computeBroadRadius(atk, diag) + PROX_MARGIN_KNIFE
				end
				atk._proxR, atk._proxR2 = proxR, proxR*proxR
			end

			local dx = heartPos.X - atk.Pos.X
			local dy = heartPos.Y - atk.Pos.Y
			local rsum = rPlayer + proxR
			if dx*dx + dy*dy > rsum*rsum then continue end

			local bx, by
			if sx and sy then
				bx, by = 0.5*sx, 0.5*sy
				if atk.Rot and (atk.Rot % 360 ~= 0) then
					if atk._rHx and atk._rHy then
						bx, by = atk._rHx, atk._rHy
					else
						bx, by = Helper.rotAabbHalf(bx, by, atk.Rot)
					end
				end
				local adx, ady = math.abs(dx), math.abs(dy)
				if adx <= (hx + bx) and ady <= (hy + by) then
					self:_damage(dmg)
					return
				end
			end
			continue
		end

		if atk.Kind == "Bits" then
			local sx = (atk.AbsSize and atk.AbsSize.X) or (atk.Size and atk.Size.X)
			local sy = (atk.AbsSize and atk.AbsSize.Y) or (atk.Size and atk.Size.Y)
			local proxR = atk._proxR
			if not proxR then
				if sx and sy then
					proxR = math.sqrt((0.5*sx)^2 + (0.5*sy)^2) + PROX_MARGIN_BITS
				else
					proxR = Helper.computeBroadRadius(atk, diag) + PROX_MARGIN_BITS
				end
				atk._proxR, atk._proxR2 = proxR, proxR*proxR
			end

			local dx = heartPos.X - atk.Pos.X
			local dy = heartPos.Y - atk.Pos.Y
			local rsum = rPlayer + proxR
			if dx*dx + dy*dy > rsum*rsum then continue end

			if sx and sy then
				local adx, ady = math.abs(dx), math.abs(dy)
				if adx <= (hx + 0.5*sx) and ady <= (hy + 0.5*sy) then
					self:_damage(dmg)
					if atk.Destroy then atk.Destroy() end
					return
				end
			end
			continue
		end

		if atk.Radius then
			if Helper.intersectsAabbCircle(heartPos, hx, hy, atk.Pos, atk.Radius) then
				self:_damage(dmg); return
			end
			continue
		end

		if atk.Kind == "SpinSweep" and atk.Rot ~= nil then
			local ex, ey
			if atk.AbsSize then
				ex, ey = atk.AbsSize.X * 0.5, atk.AbsSize.Y * 0.5
			else
				local baseLen = 2 * w
				local extra   = math.max(0, diag - baseLen) + 8
				ex = 0.5 * (baseLen + extra)
				ey = 0.5 * math.max(2, atk.Minor or 2)
			end
			if Helper.intersectsAabbObb(heartPos, hx, hy, atk.Pos, ex, ey, atk.Rot) then
				self:_damage(dmg); return
			end
			continue
		end

		if atk.Pos and (atk.Size or atk.AbsSize) then
			local sx = (atk.AbsSize and atk.AbsSize.X) or atk.Size.X
			local sy = (atk.AbsSize and atk.AbsSize.Y) or atk.Size.Y
			local adx = math.abs(heartPos.X - atk.Pos.X)
			local ady = math.abs(heartPos.Y - atk.Pos.Y)
			if adx <= (hx + 0.5*sx) and ady <= (hy + 0.5*sy) then
				self:_damage(dmg); return
			end
		end
	end
end

function Module:_playSlashFlipbook()
	for i = 1, FLIPBOOK.FRAMES do
		local src = SPRITES[tostring(i)] :: ImageLabel
		local img = src:Clone()
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.Position = UDim2.fromScale(0.5, 0.5)
		img.Parent = self.Controller
		task.wait(FLIPBOOK.DELAY)
		img:Destroy()
	end
end

--== Public ==--
function Module:Break()
	local player   = self.State.Player
	player.Vel     = Vector2.zero
	player._Locked = true

	self:_playSlashFlipbook()

	local baseSize = self.Controller.Size
	local t1 = TweenService:Create(self.Controller, TWEENS.BREAK_OUT, { Size = Helper.scaleUDim2(baseSize, 0.2) })
	local t2 = TweenService:Create(self.Controller, TWEENS.BREAK_IN,  { Size = Helper.scaleUDim2(baseSize, 1.2) })
	t1:Play()
	t1.Completed:Once(function()
		t2:Play()
		t2.Completed:Once(function()
			self.Controller.Visible = false

			Bits.new(self.State, self.Contents, "Red",         10, Vector2.zero, { fromGui = self.Controller, visual = true })
			Bits.new(self.State, self.Contents, "Heart_Left",   1, Vector2.zero, { fromGui = self.Controller, visual = true })
			Bits.new(self.State, self.Contents, "Heart_Right",  1, Vector2.zero, { fromGui = self.Controller, visual = true })
		end)
	end)
end

function Module:Clear()
	local player = self.State.Player
	player.Req   = Vector2.zero
	table.clear(player._Held)
end

--== Lifecycle ==--
function Module:Initialize()
	local player = self.State.Player

	self.Arena    = self.GUI.Canvas.Contents.Arena
	self.Contents = self.Arena.Contents
	self.Attacks  = self.Contents.Attacks
	self.Visuals  = self.Contents.Visuals

	local DEADZONE = 0.3

	local pressed = {
		up   = { kb=false, dpad=false, touch=false },
		down = { kb=false, dpad=false, touch=false },
		left = { kb=false, dpad=false, touch=false },
		right= { kb=false, dpad=false, touch=false },
	}
	local stickVec = Vector2.zero
	local stickActive = false

	local function updateReq()
		if player._Locked then
			player.Req = Vector2.zero
			return
		end
		local up    = pressed.up.kb    or pressed.up.dpad    or pressed.up.touch
		local down  = pressed.down.kb  or pressed.down.dpad  or pressed.down.touch
		local left  = pressed.left.kb  or pressed.left.dpad  or pressed.left.touch
		local right = pressed.right.kb or pressed.right.dpad or pressed.right.touch

		local dx = (right and 1 or 0) + (left and -1 or 0)
		local dy = (down and 1 or 0)  + (up and -1 or 0)

		local v = Vector2.new(dx, dy)
		if stickActive then
			v = stickVec
		end
		if self.State.Arena.Kind == "1D" then
			v = Vector2.new(v.X, 0)
		end
		if v.Magnitude > 1 then v = v.Unit end
		player.Req = v
	end

	local function handler(actionName, inputState, inputObject)
		if player._Locked then
			player.Req = Vector2.zero
			return Enum.ContextActionResult.Sink
		end
		if actionName ~= "CONTROLLER_MOVE_KEYS" then
			return Enum.ContextActionResult.Pass
		end

		local isDown = (inputState == Enum.UserInputState.Begin or inputState == Enum.UserInputState.Change)
		local kc = inputObject.KeyCode

		if kc == Enum.KeyCode.W or kc == Enum.KeyCode.Up then
			player._Held[kc] = isDown
			pressed.up.kb = isDown
		elseif kc == Enum.KeyCode.S or kc == Enum.KeyCode.Down then
			player._Held[kc] = isDown
			pressed.down.kb = isDown
		elseif kc == Enum.KeyCode.A or kc == Enum.KeyCode.Left then
			player._Held[kc] = isDown
			pressed.left.kb = isDown
		elseif kc == Enum.KeyCode.D or kc == Enum.KeyCode.Right then
			player._Held[kc] = isDown
			pressed.right.kb = isDown
		elseif kc == Enum.KeyCode.DPadUp then
			pressed.up.dpad = isDown
		elseif kc == Enum.KeyCode.DPadDown then
			pressed.down.dpad = isDown
		elseif kc == Enum.KeyCode.DPadLeft then
			pressed.left.dpad = isDown
		elseif kc == Enum.KeyCode.DPadRight then
			pressed.right.dpad = isDown
		end

		local x  = ((player._Held[Enum.KeyCode.D] or player._Held[Enum.KeyCode.Right]) and 1 or 0)
		local x2 = ((player._Held[Enum.KeyCode.A] or player._Held[Enum.KeyCode.Left])  and -1 or 0)
		local y  = ((player._Held[Enum.KeyCode.S] or player._Held[Enum.KeyCode.Down])  and 1 or 0)
		local y2 = ((player._Held[Enum.KeyCode.W] or player._Held[Enum.KeyCode.Up])    and -1 or 0)
		if self.State.Arena.Kind == "1D" then y, y2 = 0, 0 end
		local vel = Vector2.new(x + x2, y + y2)
		if vel.Magnitude > 1 then vel = vel.Unit end
		player.Req = stickActive and stickVec or vel

		updateReq()
		return Enum.ContextActionResult.Sink
	end

	contextActionService:BindAction("CONTROLLER_MOVE_KEYS", handler, false,
		Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
		Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right,
		Enum.KeyCode.DPadUp, Enum.KeyCode.DPadDown, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight,
		Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift
	)

	local function stickHandler(_, state, input)
		if input.KeyCode ~= Enum.KeyCode.Thumbstick1 then return end
		local x = input.Position.X
		local y = -input.Position.Y
		local v = Vector2.new(x, y)
		if state == Enum.UserInputState.End or v.Magnitude < DEADZONE then
			stickActive = false
			stickVec = Vector2.zero
			updateReq()
			return
		end
		if v.Magnitude > 1 then v = v.Unit end
		if self.State.Arena.Kind == "1D" then v = Vector2.new(v.X, 0) end
		stickActive = true
		stickVec = v
		updateReq()
	end

	contextActionService:BindAction("CONTROLLER_MOVE_STICK", stickHandler, false, Enum.KeyCode.Thumbstick1)

	local ts = 	Thumbstick.new({
		Position = UDim2.new(0.8, 0, 0.6, 0),
		Theme = "Modern",
		UiType = 1,
		Deadzone = 2
	})

	self.Trove:Connect(ts.Changed, function(direction: Vector2)
		local v = direction
		if v.Magnitude < DEADZONE then
			stickActive = false
			stickVec = Vector2.zero
		else
			if v.Magnitude > 1 then v = v.Unit end
			if self.State.Arena.Kind == "1D" then v = Vector2.new(v.X, 0) end
			stickActive = true
			stickVec = Vector2.new(v.X, -v.Y)
		end
		updateReq()
	end)

	self.Trove:Connect(ts.Ended, function()
		stickActive = false
		stickVec = Vector2.zero
		updateReq()
	end)

	self.Trove:Add(function()
		contextActionService:UnbindAction("CONTROLLER_MOVE_KEYS")
		contextActionService:UnbindAction("CONTROLLER_MOVE_STICK")

		Thumbstick:ClearUis()
	end)
end

function Module:Step(dtFrame: number)
	local player = self.State.Player
	local arena  = self.State.Arena

	local req = player.Req
	if req.Magnitude > 1 then
		req = req.Unit
	end
	player.Vel = player.Vel:Lerp(req, player.Accel * dtFrame)

	local size    = arena.Size
	local scale   = Helper.unitScale(self.Contents, self.State.Arena.BaselineMin)
	local speedPx = player.Speed * scale
	local pos     = player.Pos + player.Vel * speedPx * dtFrame

	local halfW = (size.X - player.Size.X * 1.5) * 0.5
	local halfH = (size.Y - player.Size.Y * 1.5) * 0.5
	if halfW == 0 or halfH == 0 then return end
	if -halfH > halfH then return end
	if -halfW > halfW then return end

	pos = Vector2.new(
		math.clamp(pos.X, -halfW, halfW),
		math.clamp(pos.Y, -halfH, halfH)
	)

	local ox = Helper.roundpx(pos.X)
	local oy = Helper.roundpx(pos.Y)

	player.Pos = pos
	self.Controller.Position = UDim2.new(0.5, ox, 0.5, oy)

	self:_checkCollisions()
end

function Module.new(trove, signals, state, controller, gui)
	local self = setmetatable({
		Trove   = trove,
		Signals = signals,
		State   = state,

		Controller = controller,
		GUI        = gui,

		_Tick = 0,
	}, Module)

	self:Initialize()

	self.State.Player.Size = controller.AbsoluteSize
	self.Trove:Connect(controller:GetPropertyChangedSignal("AbsoluteSize"), function()
		self.State.Player.Size = controller.AbsoluteSize
	end)

	return self
end

function Module:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

return Module