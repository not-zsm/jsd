--== Imports ==--
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage.Packages.Des
local Component = require(Packages.Component)
local Signal = require(Packages.Signal)
local Trove = require(Packages.Trove)

local Utils = script.Parent.Parent.Utils
local Thumbstick = require(Utils.Thumbstick)
local Text = require(Utils.Text)

--== Constants ==--
local TWEEN_IN = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
local TWEEN_OUT = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TWEEN_INOUT = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local COUNTDOWN = 3
local GOAL = 3

local BIT_TIME_MIN = 0.20
local BIT_TIME_MAX = 0.40
local BIT_COUNT_MIN = 6
local BIT_COUNT_MAX = 10
local BIT_SPEED_MIN = 32
local BIT_SPEED_MAX = 64
local BIT_SIZE_MIN = 2
local BIT_SIZE_MAX = 6

local DIFFICULTIES = {
	Easy = {
		BALL_SPEED = 150,
		BALL_ACCEL = 10,
		BALL_SPEED_MAX = 600,
		AI_MAX_SPEED = 100,
		PLAYER_SPEED = 150,
	},
	Normal = {
		BALL_SPEED = 175,
		BALL_ACCEL = 15,
		BALL_SPEED_MAX = 800,
		AI_MAX_SPEED = 150,
		PLAYER_SPEED = 150,
	},
	Hard = {
		BALL_SPEED = 200,
		BALL_ACCEL = 25,
		BALL_SPEED_MAX = 1000,
		AI_MAX_SPEED = 175,
		PLAYER_SPEED = 150,
	},
}

local RNG = Random.new()
local BIT = script.BitTemplate

--== Module ==--
local Module = {}

Module.Loaded = false
Module.__index = Module

--== Private ==--
local function leftEdgeX(gui: GuiObject)
	return gui.Position.X.Scale - gui.AnchorPoint.X * gui.Size.X.Scale
end

local function rightEdgeX(gui: GuiObject)
	return leftEdgeX(gui) + gui.Size.X.Scale
end

local function randomChild(instance: Instance)
	local children = instance:GetChildren()
	return children[RNG:NextInteger(1, #children)]
end

function Module:_Sound(name: string)
	local sounds = self.Sounds:FindFirstChild(name)
	if not sounds then
		return
	end

	local sound = (randomChild(sounds) :: Sound):Clone()
	sound.Parent = SoundService

	sound:Play()
	task.delay(math.max(0.06, sound.TimeLength / (sound.PlaybackSpeed > 0 and sound.PlaybackSpeed or 1)), function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

function Module:_ButtonsIn(screen: GuiObject)
	for _, button in ipairs(screen:GetDescendants()) do
		if not button:IsA("GuiButton") then
			continue
		end
		button.Position = UDim2.fromScale(-0.5, 0.5)
		TweenService:Create(
			button,
			TweenInfo.new(
				TWEEN_INOUT.Time,
				TWEEN_INOUT.EasingStyle,
				TWEEN_INOUT.EasingDirection,
				0,
				false,
				(button.Parent.LayoutOrder or 1) * 0.15
			),
			{ Position = UDim2.fromScale(0.5, 0.5) }
		):Play()
	end
end

function Module:_ButtonsOut(screen: GuiObject)
	for _, button in ipairs(screen:GetDescendants()) do
		if not button:IsA("GuiButton") then
			continue
		end
		button.Position = UDim2.fromScale(0.5, 0.5)
		TweenService:Create(
			button,
			TweenInfo.new(
				TWEEN_INOUT.Time,
				TWEEN_INOUT.EasingStyle,
				TWEEN_INOUT.EasingDirection,
				0,
				false,
				(button.Parent.LayoutOrder or 1) * 0.15
			),
			{ Position = UDim2.fromScale(-0.5, 0.5) }
		):Play()
	end
end

function Module:_UpdateScreen()
	local current = self.Surface:GetAttribute("Screen")

	for name, screen in self.Screens do
		if name == current then
			TweenService:Create(screen, TWEEN_IN, { GroupTransparency = 0 }):Play()
			screen.Interactable = true

			if screen:GetAttribute("Animate") then
				self:_ButtonsIn(screen)
			end

			local animatedTitle = screen:FindFirstChild("animatedTitle")
			if animatedTitle then
				local text = animatedTitle:GetAttribute("Text")
				local size = animatedTitle:GetAttribute("Size")
				if text then
					task.defer(function()
						Text.AnimateText(text, animatedTitle, 0.06, Enum.Font.Arcade, "rotate up", nil, size)
					end)
				end
			end
		else
			TweenService:Create(screen, TWEEN_OUT, { GroupTransparency = 1 }):Play()
			screen.Interactable = false

			if screen:GetAttribute("Animate") then
				self:_ButtonsOut(screen)
			end

			local animatedTitle = screen:FindFirstChild("animatedTitle")
			if animatedTitle then
				Text.ClearText(animatedTitle)
			end
		end
	end

	if current == "Gameplay" then
		self:_StartGame()
	else
		self:_StopGame()
	end
end

function Module:_UpdateDifficulty()
	self.Settings = DIFFICULTIES[self.Surface:GetAttribute("Difficulty")]
end

function Module:_SetupButtons()
	for _, button in ipairs(self.Surface:GetDescendants()) do
		if not button:IsA("GuiButton") then
			continue
		end

		local difficulty = button:GetAttribute("Difficulty")
		local action = button:GetAttribute("Action")
		local value = button:GetAttribute("Value")

		local scale = Instance.new("UIScale")
		scale.Parent = button

		self.Trove:Connect(button.MouseEnter, function()
			TweenService:Create(scale, TWEEN_INOUT, { Scale = 0.975 }):Play()
		end)
		self.Trove:Connect(button.MouseLeave, function()
			TweenService:Create(scale, TWEEN_INOUT, { Scale = 1 }):Play()
		end)
		self.Trove:Connect(button.MouseButton1Down, function()
			TweenService:Create(scale, TWEEN_INOUT, { Scale = 0.925 }):Play()
		end)
		self.Trove:Connect(button.MouseButton1Up, function()
			TweenService:Create(scale, TWEEN_INOUT, { Scale = 1 }):Play()
		end)

		self.Trove:Connect(button.Activated, function()
			if difficulty then
				self.Surface:SetAttribute("Difficulty", difficulty)
			end
			if action == "Exit" then
				self.Signal:Fire()
			elseif action == "Pause" then
				self:_TogglePause()
			elseif action == "Transition" then
				self.Surface:SetAttribute("Screen", value)
			end
		end)
	end
end

function Module:_SetupIndicators()
	for _, indicator in ipairs(self.Surface:GetDescendants()) do
		if not indicator:HasTag("Indicator") then
			continue
		end

		local text = indicator:GetAttribute("Text")
		local size = indicator:GetAttribute("Size")
		if text then
			Text.AnimateText(text, indicator, 0.06, Enum.Font.Arcade, "rotate up", nil, size)
		end

		self.Trove:Connect(indicator:GetAttributeChangedSignal("Text"), function()
			local t = indicator:GetAttribute("Text")
			local s = indicator:GetAttribute("Size")
			if not t then
				return
			end
			Text.ClearText(indicator)
			Text.AnimateText(t, indicator, 0.06, Enum.Font.Arcade, "rotate up", nil, s)
		end)
	end
end

function Module:_SetupOverlay()
	local overlay = self.Surface.Overlay
	local tween = TweenService:Create(
		overlay,
		TweenInfo.new(10, Enum.EasingStyle.Linear),
		{ Position = UDim2.new(1, 128, 1, 128) }
	)
	tween:Play()
	self.Trove:Connect(tween.Completed, function()
		overlay.Position = UDim2.new(1, 0, 1, 0)
		tween:Play()
	end)
end

--== Game ==--
function Module:_BindInput()
	self.State.Pressed = { up = false, down = false }
	self.State.MoveAxis = 0

	local DEADZONE = 0.35
	local pressed = {
		up   = { kb=false, dpad=false, touch=false, stick=false },
		down = { kb=false, dpad=false, touch=false, stick=false },
	}

	local function updateAxis()
		self.State.Pressed.up   = pressed.up.kb   or pressed.up.dpad   or pressed.up.touch   or pressed.up.stick
		self.State.Pressed.down = pressed.down.kb or pressed.down.dpad or pressed.down.touch or pressed.down.stick
		local up   = self.State.Pressed.up
		local down = self.State.Pressed.down
		self.State.MoveAxis = (down and 1 or 0) + (up and -1 or 0)
	end

	local function keyHandler(_, state, input)
		local isDown = (state == Enum.UserInputState.Begin or state == Enum.UserInputState.Change)
		if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then
			pressed.up.kb = isDown
		elseif input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then
			pressed.down.kb = isDown
		elseif input.KeyCode == Enum.KeyCode.DPadUp then
			pressed.up.dpad = isDown
		elseif input.KeyCode == Enum.KeyCode.DPadDown then
			pressed.down.dpad = isDown
		end
		updateAxis()
	end

	ContextActionService:BindAction(
		"PONG_MOVE_KEYS",
		keyHandler,
		false,
		Enum.KeyCode.W, Enum.KeyCode.S, Enum.KeyCode.Up, Enum.KeyCode.Down,
		Enum.KeyCode.DPadUp, Enum.KeyCode.DPadDown
	)

	local function stickHandler(_, state, input)
		if input.KeyCode ~= Enum.KeyCode.Thumbstick1 then return end
		local x = input.Position.X
		local y = input.Position.Y
		local ax, ay = math.abs(x), math.abs(y)
		if state == Enum.UserInputState.End or ay < DEADZONE then
			pressed.up.stick, pressed.down.stick = false, false
			updateAxis()
			return
		end
		if y <= -DEADZONE then
			pressed.up.stick, pressed.down.stick = false, true
		elseif y >= DEADZONE then
			pressed.up.stick, pressed.down.stick = true, false
		end
		updateAxis()
	end

	ContextActionService:BindAction("PONG_MOVE_STICK", stickHandler, false, Enum.KeyCode.Thumbstick1)

	local ts = Thumbstick.new({
		Position = UDim2.new(0.8, 0, 0.6, 0),
		Theme = "Modern",
		UiType = 1,
		Deadzone = 2
	})

	local lastTouch = 0
	local function setTouchAxis(mode)
		if mode == lastTouch then return end
		pressed.up.touch   = (mode == -1)
		pressed.down.touch = (mode == 1)
		lastTouch = mode
		updateAxis()
	end

	local function fromVec2(v: Vector2)
		local y = v.Y
		local ay = math.abs(y)
		if ay < DEADZONE then
			setTouchAxis(0)
		elseif y <= -DEADZONE then
			setTouchAxis(1)
		else
			setTouchAxis(-1)
		end
	end

	self.Session:Connect(ts.Changed, function(v) fromVec2(v) end)
	self.Session:Connect(ts.Ended, function() setTouchAxis(0) end)

	self.Session:Add(function()
		ContextActionService:UnbindAction("PONG_MOVE_KEYS")
		ContextActionService:UnbindAction("PONG_MOVE_STICK")
		
		setTouchAxis(0)
		Thumbstick:ClearUis()
	end)
end

function Module:_ResetPositions()
	local gameplay = self.Screens.Gameplay
	local board = gameplay.Board.Contents
	local left = board.Left
	local right = board.Right
	local ball = board.Ball

	self.State.LeftY = 0.5
	self.State.RightY = 0.5
	self.State.BallPos = Vector2.new(0.5, 0.5)
	self.State.BallVel = Vector2.zero

	left.Position = UDim2.fromScale(left.Position.X.Scale, self.State.LeftY)
	right.Position = UDim2.fromScale(right.Position.X.Scale, self.State.RightY)
	ball.Position = UDim2.fromScale(self.State.BallPos.X, self.State.BallPos.Y)
end

function Module:_ResetScore()
	local score = self.Screens.Gameplay.Score
	local leftI = score.Left.Indicator
	local rightI = score.Right.Indicator

	self.State.LeftScore, self.State.RightScore = 0, 0
	leftI:SetAttribute("Text", "0")
	rightI:SetAttribute("Text", "0")

	self.State.InPoint = false
end

function Module:_PointScored(byLeft: boolean)
	if self.State.InPoint then
		return
	end
	self.State.InPoint = true

	if byLeft then
		self.State.LeftScore += 1
	else
		self.State.RightScore += 1
	end

	local score = self.Screens.Gameplay.Score
	score.Left.Indicator:SetAttribute("Text", tostring(self.State.LeftScore))
	score.Right.Indicator:SetAttribute("Text", tostring(self.State.RightScore))

	if self.State.LeftScore >= GOAL or self.State.RightScore >= GOAL then
		local victory = self.Screens.Victory
		local text = (self.State.LeftScore > self.State.RightScore) and "<wave>PLAYER 1 WON</wave>"
			or "<wave>PLAYER 2 WON</wave>"
		victory.Indicator:SetAttribute("Text", text)
		self:_Sound(self.State.LeftScore > self.State.RightScore and "Win" or "Loss")
		self.Surface:SetAttribute("Screen", "Victory")
		self:_ResetScore()
		return
	end

	self:_Sound(byLeft and "Score Left" or "Score Right")
	self:_ResetPositions()
	self:_Countdown()
	self:_Serve(not byLeft)
	self.State.InPoint = false
end

function Module:_EmitBitsAbs(hitAbs: Vector2, normal: Vector2)
	local gameplay = self.Screens.Gameplay
	local board = gameplay.Board
	local bitsRoot = board.Decorations.Bits

	local count = RNG:NextInteger(BIT_COUNT_MIN, BIT_COUNT_MAX)

	for _ = 1, count do
		local bit = BIT:Clone()
		bit.AnchorPoint = Vector2.new(0.5, 0.5)

		local sizePx = RNG:NextInteger(BIT_SIZE_MIN, BIT_SIZE_MAX)
		bit.Size = UDim2.fromOffset(sizePx, sizePx)

		local localHit = hitAbs - bitsRoot.AbsolutePosition
		bit.Position = UDim2.fromOffset(localHit.X, localHit.Y)
		bit.Parent = bitsRoot

		local jitter = Vector2.new(RNG:NextNumber(-0.6, 0.6), RNG:NextNumber(-0.6, 0.6))
		local dir = (normal + jitter)
		if dir.Magnitude < 1e-3 then
			dir = Vector2.new(RNG:NextNumber(-1, 1), RNG:NextNumber(-1, 1))
		end
		dir = dir.Unit

		local travelPx = RNG:NextNumber(BIT_SPEED_MIN, BIT_SPEED_MAX)
		local dur = RNG:NextNumber(BIT_TIME_MIN, BIT_TIME_MAX)
		local dest = localHit + dir * travelPx

		TweenService:Create(bit, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(dest.X, dest.Y),
			BackgroundTransparency = 1,
		}):Play()

		task.delay(dur + 0.06, function()
			if bit and bit.Parent then
				bit:Destroy()
			end
		end)
	end
end

function Module:_EmitBitsAt(gui: GuiObject, normal: Vector2)
	local center = gui.AbsolutePosition + gui.AbsoluteSize * 0.5
	local radius = gui.AbsoluteSize * 0.5
	local hitAbs = center - Vector2.new(normal.X * radius.X, normal.Y * radius.Y)
	self:_EmitBitsAbs(hitAbs, normal)
end

function Module:_Serve(toRight: boolean)
	local x = toRight and 1 or -1
	local y = RNG:NextNumber(-0.55, 0.55)
	self.State.BallVel = Vector2.new(x, y).Unit * self.Settings.BALL_SPEED
end

function Module:_UpdatePaddles(dt: number, boardH: number)
	if self.State.Paused or self.State.Locked then
		return
	end

	local gameplay = self.Screens.Gameplay
	local board = gameplay.Board.Contents
	local left = board.Left
	local right = board.Right
	local axis = self.State.MoveAxis or 0

	if axis ~= 0 then
		local delta = (self.Settings.PLAYER_SPEED * dt) / boardH
		self.State.LeftY = math.clamp(self.State.LeftY + axis * delta, 0.125, 0.875)
		left.Position = UDim2.fromScale(left.Position.X.Scale, self.State.LeftY)
	end

	local target = self.State.BallPos.Y
	local dy = target - self.State.RightY
	local maxMove = (self.Settings.AI_MAX_SPEED * dt) / boardH

	if math.abs(dy) <= maxMove then
		self.State.RightY = target
	else
		self.State.RightY += (dy > 0 and 1 or -1) * maxMove
	end

	self.State.RightY = math.clamp(self.State.RightY, 0.125, 0.875)
	right.Position = UDim2.fromScale(right.Position.X.Scale, self.State.RightY)
end

function Module:_UpdateBall(dt: number, boardSize: Vector2)
	if self.State.Paused or self.State.Locked then
		return
	end

	local gameplay = self.Screens.Gameplay
	local board = gameplay.Board.Contents
	local left = board.Left
	local right = board.Right
	local ball = board.Ball

	local dx = (self.State.BallVel.X * dt) / boardSize.X
	local dy = (self.State.BallVel.Y * dt) / boardSize.Y
	self.State.BallPos = Vector2.new(self.State.BallPos.X + dx, self.State.BallPos.Y + dy)

	local halfW = (ball.AbsoluteSize.X / boardSize.X) * 0.5
	local halfH = (ball.AbsoluteSize.Y / boardSize.Y) * 0.5

	if self.State.BallPos.Y - halfH <= 0 then
		self.State.BallPos = Vector2.new(self.State.BallPos.X, halfH)
		self.State.BallVel = Vector2.new(self.State.BallVel.X, -self.State.BallVel.Y)
		self:_EmitBitsAt(ball, Vector2.new(0, 1))
		self:_Sound("Wall")
	elseif self.State.BallPos.Y + halfH >= 1 then
		self.State.BallPos = Vector2.new(self.State.BallPos.X, 1 - halfH)
		self.State.BallVel = Vector2.new(self.State.BallVel.X, -self.State.BallVel.Y)
		self:_EmitBitsAt(ball, Vector2.new(0, -1))
		self:_Sound("Wall")
	end

	local leftY = self.State.LeftY
	local leftHalf = left.Size.Y.Scale * 0.5
	local rightY = self.State.RightY
	local rightHalf = right.Size.Y.Scale * 0.5

	local leftLeft = leftEdgeX(left)
	local leftRight = rightEdgeX(left)
	local rightLeft = leftEdgeX(right)
	local rightRight = rightEdgeX(right)

	local ballLeft = self.State.BallPos.X - halfW
	local ballRight = self.State.BallPos.X + halfW
	local ballY = self.State.BallPos.Y

	if self.State.BallVel.X < 0 and ballLeft <= leftRight and ballRight >= leftLeft then
		if math.abs(ballY - leftY) <= (leftHalf + halfH) then
			local speed =
				math.min(self.State.BallVel.Magnitude + self.Settings.BALL_ACCEL, self.Settings.BALL_SPEED_MAX)
			local offset = math.clamp((ballY - leftY) / (leftHalf + halfH), -1, 1)
			local dir = Vector2.new(1, offset).Unit
			self.State.BallVel = dir * speed
			self.State.BallPos = Vector2.new(leftRight + halfW, self.State.BallPos.Y)
			self:_EmitBitsAt(ball, Vector2.new(1, 0))
			self:_Sound("Paddle")
		end
	end

	if self.State.BallVel.X > 0 and ballRight >= rightLeft and ballLeft <= rightRight then
		if math.abs(ballY - rightY) <= (rightHalf + halfH) then
			local speed =
				math.min(self.State.BallVel.Magnitude + self.Settings.BALL_ACCEL, self.Settings.BALL_SPEED_MAX)
			local offset = math.clamp((ballY - rightY) / (rightHalf + halfH), -1, 1)
			local dir = Vector2.new(-1, offset).Unit
			self.State.BallVel = dir * speed
			self.State.BallPos = Vector2.new(rightLeft - halfW, self.State.BallPos.Y)
			self:_EmitBitsAt(ball, Vector2.new(-1, 0))
			self:_Sound("Paddle")
		end
	end

	if self.State.BallPos.X + halfW < 0 then
		self:_PointScored(false)
		return
	elseif self.State.BallPos.X - halfW > 1 then
		self:_PointScored(true)
		return
	end

	ball.Position = UDim2.fromScale(self.State.BallPos.X, self.State.BallPos.Y)
end

function Module:_Countdown()
	task.spawn(function()
		script.Parent.Parent.Start:Play()
	end)
	
	self.State.Locked = true

	local gameplay = self.Screens.Gameplay
	local timerCG = gameplay.Board.Timer
	local indicator = timerCG.Indicator

	TweenService:Create(timerCG, TWEEN_IN, { GroupTransparency = 0 }):Play()

	for n = COUNTDOWN, 1, -1 do
		if self.Surface:GetAttribute("Screen") ~= "Gameplay" then
			indicator:SetAttribute("Text", nil)
			return
		end
		indicator:SetAttribute("Text", tostring(n))
		task.wait(1)
	end

	if self.Surface:GetAttribute("Screen") ~= "Gameplay" then
		return
	end

	TweenService:Create(timerCG, TWEEN_OUT, { GroupTransparency = 1 }):Play()
	indicator:SetAttribute("Text", nil)
	self.State.Locked = false
end

function Module:_TogglePause()
	if self.State.Locked then
		return
	end

	local gameplay = self.Screens.Gameplay
	local pausedCG = gameplay.Board.Paused
	local pauseBTN = gameplay.Buttons.Pause.Button
	local indicator = pausedCG.Indicator

	self.State.Paused = not self.State.Paused
	pauseBTN.Text = self.State.Paused and "UNPAUSE" or "PAUSE"

	if self.State.Paused then
		indicator:SetAttribute("Text", "<wave>PAUSED</wave>")
		TweenService:Create(pausedCG, TWEEN_IN, { GroupTransparency = 0 }):Play()
	else
		TweenService:Create(pausedCG, TWEEN_OUT, { GroupTransparency = 1 }):Play()
		indicator:SetAttribute("Text", nil)
	end
end

function Module:_StartGame()
	self.Session:Clean()

	self.State.Paused = false
	self.State.Locked = false

	self:_BindInput()
	self:_ResetPositions()
	self:_ResetScore()
	self:_Countdown()
	self:_Serve(true)

	self.Session:Connect(RunService.PostSimulation, function(dt)
		local size = self.Screens.Gameplay.Board.AbsoluteSize
		self:_UpdatePaddles(dt, size.Y)
		self:_UpdateBall(dt, size)
	end)
end

function Module:_StopGame()
	self.Session:Clean()

	local gameplay = self.Screens.Gameplay
	local pausedCG = gameplay.Board.Paused
	local pauseInd = pausedCG and pausedCG.Indicator
	local timerCG = gameplay.Board.Timer
	local timerInd = timerCG and timerCG.Indicator

	if pauseInd then
		pauseInd:SetAttribute("Text", nil)
	end
	if timerInd then
		timerInd:SetAttribute("Text", nil)
	end

	if pausedCG then
		TweenService:Create(pausedCG, TWEEN_OUT, { GroupTransparency = 1 }):Play()
	end
	if timerCG then
		TweenService:Create(timerCG, TWEEN_OUT, { GroupTransparency = 1 }):Play()
	end
end

--== Public ==--
function Module:Focus()
	if Module.Loaded then
		self.Surface:SetAttribute("Screen", "Menu")
		return
	end
	self.Surface:SetAttribute("Screen", "Loading")
	task.spawn(self._Load, self)
end

function Module:Unfocus()
	self.Surface:SetAttribute("Screen", "Idle")
	self.Session:Clean()
end

--== Loading ==--
function Module:_Load()
	Text.ClearText(self.Screens.Loading.animatedTitle)
	Text.AnimateText("LOADING", self.Screens.Loading.animatedTitle, 0.06, Enum.Font.Arcade, "rotate up")

	local progress, visual = 0, 0
	local indicator = self.Screens.Loading.Indicator

	local segments = {}
	for _, child in ipairs(indicator:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(segments, { th = tonumber(child.Name), node = child })
		end
	end
	table.sort(segments, function(a, b)
		return a.th < b.th
	end)

	self.Session:Connect(RunService.PostSimulation, function(dt)
		local k = math.clamp(dt * 5, 0, 1)
		visual = math.lerp(visual, progress, k)

		for i, seg in ipairs(segments) do
			local lower = (i > 1) and segments[i - 1].th or 0
			local upper = seg.th
			local t
			if visual >= upper then
				t = 0
			else
				local frac = math.clamp((visual - lower) / (upper - lower), 0, 1)
				t = 1 - frac
			end
			seg.node.Transparency = (Module.Loaded and 0 or t)
		end
	end)

	local targets = {}
	for _, d in ipairs(script:GetDescendants()) do
		if d:IsA("Sound") then
			table.insert(targets, d)
		end
		if d:IsA("ImageLabel") or d:IsA("ImageButton") then
			table.insert(targets, d)
		end
	end

	local done = false
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(targets)
		end)
		done = true
	end)

	local startQueue, t0 = 0, os.clock()
	repeat
		startQueue = ContentProvider.RequestQueueSize
		task.wait()
	until startQueue > 0 or os.clock() - t0 > 1.0

	if startQueue > 0 then
		while not done do
			local remain = ContentProvider.RequestQueueSize
			local ok = math.max(startQueue - remain, 0)
			progress = math.clamp((ok / startQueue) * 100, 0, 99)
			task.wait()
		end
	else
		local i, total = 1, #targets
		local chunk = 64
		while i <= total do
			local batch, bi = table.create(math.min(chunk, total - i + 1)), 0
			while bi < chunk and i <= total do
				bi += 1
				batch[bi] = targets[i]
				i += 1
			end
			pcall(function()
				ContentProvider:PreloadAsync(batch)
			end)
			progress = math.floor(((i - 1) / total) * 100)
			task.wait()
		end
		done = true
	end

	Module.Loaded = true

	Text.ClearText(self.Screens.Loading.animatedTitle)
	Text.AnimateText("<wave>LOADED!</wave>", self.Screens.Loading.animatedTitle, 0.06, Enum.Font.Arcade, "rotate up")

	task.wait(1.5)
	if self.Surface:GetAttribute("Screen") ~= "Loading" then
		return
	end

	self.Surface:SetAttribute("Screen", "Menu")
end

--== Lifecycle ==--
function Module.new(instance: Instance)
	local self = setmetatable({ Instance = instance }, Module)

	self.Signal = Signal.new()
	self.Session = Trove.new()
	self.Trove = Trove.new()

	self.Surface = script.Surface:Clone()
	self.Surface.Parent = instance

	self.Sounds = self.Surface.Sounds

	self.Settings = {}
	self.State = {}

	self.Screens = {
		Idle = self.Surface.Idle,
		Difficulty = self.Surface.Game.Difficulty,
		Gameplay = self.Surface.Game.Gameplay,
		Loading = self.Surface.Game.Loading,
		Victory = self.Surface.Game.Victory,
		Menu = self.Surface.Game.Menu,
	}

	self.Trove:Connect(self.Surface:GetAttributeChangedSignal("Screen"), function()
		self:_UpdateScreen()
	end)
	self.Trove:Connect(self.Surface:GetAttributeChangedSignal("Difficulty"), function()
		self:_UpdateDifficulty()
	end)

	self:_SetupIndicators()
	self:_SetupOverlay()
	self:_SetupButtons()

	self.Surface:SetAttribute("Difficulty", "Normal")
	self.Surface:SetAttribute("Screen", "Idle")

	return self
end

function Module:Destroy()
	self.Session:Destroy()
	self.Trove:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

--== Return ==--
return Module