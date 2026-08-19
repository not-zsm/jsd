--== Imports ==--
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages.Des
local Signal = require(Packages.Signal)
local Trove = require(Packages.Trove)

local Utils = script.Parent.Parent.Utils
local Text = require(Utils.Text)

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

--== Constants ==--
local TWEEN_IN = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
local TWEEN_OUT = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TWEEN_INOUT = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local TWEEN_ROW_FADE = TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TWEEN_CELL_PUNCH = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_LABEL_POP = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_GRID_FADE = TweenInfo.new(0.40, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

local DIFFICULTIES = {
	Easy = { ROWS = 6, COLS = 7, MINES = 5 },
	Normal = { ROWS = 8, COLS = 9, MINES = 9 },
	Hard = { ROWS = 10, COLS = 12, MINES = 13 },
}

local DIRECTIONS = {
	{ -1, -1 },
	{ -1, 0 },
	{ -1, 1 },
	{ 0, -1 },
	{ 0, 1 },
	{ 1, -1 },
	{ 1, 0 },
	{ 1, 1 },
}

local BITS_SAFE_COUNT_MIN = 10
local BITS_SAFE_COUNT_MAX = 16
local BITS_SAFE_SIZE_MIN = 4
local BITS_SAFE_SIZE_MAX = 8
local BITS_SAFE_TRAVEL_MIN = 14
local BITS_SAFE_TRAVEL_MAX = 36
local BITS_SAFE_TIME_MIN = 0.65
local BITS_SAFE_TIME_MAX = 1.35
local BITS_SAFE_COLORS = {
	Color3.fromRGB(245, 245, 245),
	Color3.fromRGB(210, 210, 210),
	Color3.fromRGB(255, 255, 255),
}

local BITS_EXPL_COUNT_MIN = 24
local BITS_EXPL_COUNT_MAX = 36
local BITS_EXPL_SIZE_MIN = 10
local BITS_EXPL_SIZE_MAX = 18
local BITS_EXPL_TRAVEL_MIN = 48
local BITS_EXPL_TRAVEL_MAX = 96
local BITS_EXPL_TIME_MIN = 0.95
local BITS_EXPL_TIME_MAX = 1.85
local BITS_EXPL_COLORS = {
	Color3.fromRGB(255, 238, 88),
	Color3.fromRGB(255, 167, 38),
	Color3.fromRGB(244, 67, 54),
	Color3.fromRGB(255, 255, 255),
}

local RNG = Random.new()

local BIT = script.BitTemplate
local ROW = script.RowTemplate
local CELL = script.ButtonTemplate

local MOBILE = script.Mobile

--== Module ==--
local Module = {}

Module.Loaded = false
Module.__index = Module

--== Private ==--
local function randomChild(instance: Instance)
	local children = instance:GetChildren()
	return children[RNG:NextInteger(1, #children)]
end

local function inBounds(r: number, c: number, rows: number, cols: number)
	return r >= 1 and r <= rows and c >= 1 and c <= cols
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

--== Game ==--
local function setHiddenVisible(cell, hiddenVisible)
	cell.hidden.Visible = hiddenVisible
	cell.shown.Visible = not hiddenVisible
end

local function setMineOrNumber(cell)
	if cell.isMine then
		cell.shown.Contents.Mine.Visible = true
		cell.shown.Contents.Number.Visible = false
	else
		local n = cell.count
		cell.shown.Contents.Mine.Visible = false
		cell.shown.Contents.Number.Visible = (n > 0)
		if n > 0 then
			cell.shown.Contents.Number.Text = tostring(n)
		end
	end
end

function Module:_SetupButtons()
	for _, button in ipairs(self.Surface:GetDescendants()) do
		if not button:IsA("GuiButton") then
			continue
		end

		local difficulty = button:GetAttribute("Difficulty")
		local action = button:GetAttribute("Action")
		local value = button:GetAttribute("Value")

		local scale = button:FindFirstChildOfClass("UIScale")
		if not scale then
			scale = Instance.new("UIScale")
			scale.Parent = button
		end

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

function Module:_EmitButtonBits(button: GuiObject, isExplosion: boolean)
	local bitsRoot = button.Bits
	local rootSize = bitsRoot.AbsoluteSize
	local center = rootSize * 0.5
	local radius = math.min(rootSize.X, rootSize.Y) * 0.5

	local count = RNG:NextInteger(
		isExplosion and BITS_EXPL_COUNT_MIN or BITS_SAFE_COUNT_MIN,
		isExplosion and BITS_EXPL_COUNT_MAX or BITS_SAFE_COUNT_MAX
	)

	for _ = 1, count do
		local bit = BIT:Clone()
		bit.ZIndex = (button.ZIndex or 1) + 2

		local colTbl = isExplosion and BITS_EXPL_COLORS or BITS_SAFE_COLORS
		bit.BackgroundColor3 = colTbl[RNG:NextInteger(1, #colTbl)]

		local sizePx = RNG:NextInteger(
			isExplosion and BITS_EXPL_SIZE_MIN or BITS_SAFE_SIZE_MIN,
			isExplosion and BITS_EXPL_SIZE_MAX or BITS_SAFE_SIZE_MAX
		)
		bit.Size = UDim2.fromOffset(sizePx, sizePx)

		local a = RNG:NextNumber(0, math.pi * 2)
		local dir = Vector2.new(math.cos(a), math.sin(a))

		local startR = radius * RNG:NextNumber(0.0, 0.15)
		local start = center + dir * startR

		local travel = RNG:NextNumber(
			isExplosion and BITS_EXPL_TRAVEL_MIN or BITS_SAFE_TRAVEL_MIN,
			isExplosion and BITS_EXPL_TRAVEL_MAX or BITS_SAFE_TRAVEL_MAX
		)
		local dest = center + dir * travel

		local dur = RNG:NextNumber(
			isExplosion and BITS_EXPL_TIME_MIN or BITS_SAFE_TIME_MIN,
			isExplosion and BITS_EXPL_TIME_MAX or BITS_SAFE_TIME_MAX
		)

		bit.Position = UDim2.fromOffset(start.X, start.Y)
		bit.Parent = bitsRoot

		TweenService:Create(bit, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(dest.X, dest.Y),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(math.floor(sizePx * 0.7), math.floor(sizePx * 0.7)),
		}):Play()

		task.delay(dur + 0.06, function()
			if bit.Parent then
				bit:Destroy()
			end
		end)
	end
end

function Module:_clearGridUI()
	local holder = self.Screens.Gameplay.Board.Contents
	for _, child in ipairs(holder:GetChildren()) do
		if child:IsA("UIListLayout") or child:IsA("UIPadding") or child.Name == "Decorations" then
			continue
		end
		if child:IsA("CanvasGroup") then
			child:Destroy()
		end
	end
end

function Module:_buildGrid()
	self.State.MinesPlaced = false
	self.State.Revealed = 0
	self.State.Flagged = 0

	local cfg = self.Settings
	self.State.Rows = cfg.ROWS
	self.State.Cols = cfg.COLS
	self.State.Mines = cfg.MINES

	self:_clearGridUI()
	self.State.Cells = table.create(self.State.Rows)

	local holder = self.Screens.Gameplay.Board.Contents

	for r = 1, self.State.Rows do
		local row = ROW:Clone()
		row.Name = "Row" .. r
		row.LayoutOrder = r
		row.Size = UDim2.fromScale(1, 1 / self.State.Rows)
		row.Parent = holder
		row.GroupTransparency = 1
		TweenService:Create(
			row,
			TweenInfo.new(
				TWEEN_ROW_FADE.Time,
				TWEEN_ROW_FADE.EasingStyle,
				TWEEN_ROW_FADE.EasingDirection,
				0,
				false,
				(r - 1) * 0.035
			),
			{ GroupTransparency = 0 }
		):Play()

		self.State.Cells[r] = table.create(self.State.Cols)

		for c = 1, self.State.Cols do
			local button = CELL:Clone()
			button.Name = "Button" .. c
			button.LayoutOrder = c
			button.Size = UDim2.fromScale(1 / self.State.Cols, 1)
			button.Parent = row

			local hidden = button.Hidden
			local shown = button.Shown
			local bits = button.Bits

			local hiddenScale = hidden:FindFirstChildOfClass("UIScale")
			local shownScale = shown:FindFirstChildOfClass("UIScale")

			hidden.Visible, shown.Visible = true, false
			hidden.Flag.Visible = true
			hidden.Flag.TextTransparency = 1
			shown.Contents.Mine.Visible = false
			shown.Contents.Number.Visible = false

			hiddenScale.Scale = 0.85
			shownScale.Scale = 1.15
			TweenService:Create(hiddenScale, TWEEN_CELL_PUNCH, { Scale = 1 }):Play()
			TweenService:Create(shownScale, TWEEN_CELL_PUNCH, { Scale = 1 }):Play()

			local cell = {
				r = r,
				c = c,
				isMine = false,
				count = 0,
				revealed = false,
				flagged = false,
				button = button,
				hidden = hidden,
				shown = shown,
				bits = bits,
				hiddenScale = hiddenScale,
				shownScale = shownScale,
			}
			self.State.Cells[r][c] = cell

			self.Session:Connect(hidden.Button.MouseEnter, function()
				TweenService:Create(hiddenScale, TWEEN_INOUT, { Scale = 0.975 }):Play()
				TweenService:Create(shownScale, TWEEN_INOUT, { Scale = 0.975 }):Play()
			end)
			self.Session:Connect(hidden.Button.MouseLeave, function()
				TweenService:Create(hiddenScale, TWEEN_INOUT, { Scale = 1 }):Play()
				TweenService:Create(shownScale, TWEEN_INOUT, { Scale = 1 }):Play()
			end)
			self.Session:Connect(hidden.Button.MouseButton1Down, function()
				TweenService:Create(hiddenScale, TWEEN_INOUT, { Scale = 0.925 }):Play()
				TweenService:Create(shownScale, TWEEN_INOUT, { Scale = 0.925 }):Play()
			end)
			self.Session:Connect(hidden.Button.MouseButton1Up, function()
				TweenService:Create(hiddenScale, TWEEN_INOUT, { Scale = 1 }):Play()
				TweenService:Create(shownScale, TWEEN_INOUT, { Scale = 1 }):Play()
			end)

			self.Session:Connect(hidden.Button.Activated, function(_, input)
				local isTouchOrPad =
					(self.State.Preferred == Enum.PreferredInput.Touch)
					or (self.State.Preferred == Enum.PreferredInput.Gamepad)
				if isTouchOrPad and self.State.FlagMode then
					self:_toggleFlag(cell)
				else
					self:_onReveal(cell)
				end
			end)

			self.Session:Connect(hidden.Button.MouseButton2Click, function()
				self:_toggleFlag(cell)
			end)
		end
	end

	self:_updateFlagsUI()
end

function Module:_placeMinesAvoid(firstCell)
	local rows, cols = self.State.Rows, self.State.Cols
	local pool = {}
	for r = 1, rows do
		for c = 1, cols do
			if not (r == firstCell.r and c == firstCell.c) then
				pool[#pool + 1] = { r, c }
			end
		end
	end

	for i = #pool, 2, -1 do
		local j = RNG:NextInteger(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end

	for i = 1, math.min(self.State.Mines, #pool) do
		local r, c = pool[i][1], pool[i][2]
		self.State.Cells[r][c].isMine = true
	end

	for r = 1, rows do
		for c = 1, cols do
			local cell = self.State.Cells[r][c]
			if not cell.isMine then
				local n = 0
				for _, d in ipairs(DIRECTIONS) do
					local rr, cc = r + d[1], c + d[2]
					if inBounds(rr, cc, rows, cols) and self.State.Cells[rr][cc].isMine then
						n += 1
					end
				end
				cell.count = n
			end
		end
	end

	self.State.MinesPlaced = true
end

function Module:_toggleFlag(cell)
	if cell.revealed then return end

	cell.flagged = not cell.flagged
	local flagLbl: TextLabel = cell.hidden.Flag
	if cell.flagged then
		flagLbl.TextTransparency = 1
		local startSize = math.max(10, math.floor(flagLbl.TextSize * 0.7))
		flagLbl.TextSize = startSize
		TweenService:Create(flagLbl, TWEEN_LABEL_POP, {
			TextTransparency = 0,
			TextSize = startSize + math.floor(flagLbl.TextSize * 0.3),
		}):Play()
		self.State.Flagged += 1
		self:_Sound("Flag")
	else
		TweenService:Create(flagLbl, TWEEN_OUT, { TextTransparency = 1 }):Play()
		self.State.Flagged -= 1
	end

	self:_updateFlagsUI()

	if self.State.MinesPlaced then
		self:_checkWin()
	end
end

function Module:_updateFlagsUI()
	local remain = self.State.Mines - self.State.Flagged
	self.Screens.Gameplay.Context.Flags.Indicator:SetAttribute("Text", tostring(remain))
end

function Module:_SetFlagMode(on: boolean)
	self.State.FlagMode = on and true or false
	if self.FlagIcon then
		self.FlagIcon.ImageTransparency = self.State.FlagMode and 0.25 or 0.75
	end
end

function Module:_ShowFlagUIForPreferred()
	local isTouchOrPad =
		(self.State.Preferred == Enum.PreferredInput.Touch)
		or (self.State.Preferred == Enum.PreferredInput.Gamepad)
	if not self.FlagUI then
		self.FlagUI = MOBILE:Clone()
		self.FlagUI.Parent = PlayerGui
		local btn = self.FlagUI:FindFirstChild("Flag")
		self.FlagIcon = btn and btn:FindFirstChild("Icon")
		self:_SetFlagMode(false)
		self.Session:Connect(btn.Activated, function()
			self:_SetFlagMode(not self.State.FlagMode)
		end)
	end
	self.FlagUI.Enabled = isTouchOrPad
	
	self.Session:Add(function() self.FlagUI:Destroy() end)
end

function Module:_BindFlagAction()
	local function toggle(_, state)
		if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
		self:_SetFlagMode(not self.State.FlagMode)
		return Enum.ContextActionResult.Sink
	end
	ContextActionService:BindAction(
		"MINES_FLAG_TOGGLE",
		toggle,
		false,
		Enum.KeyCode.ButtonY,
		Enum.KeyCode.ButtonR1
	)
	self.Session:Add(function() ContextActionService:UnbindAction("MINES_FLAG_TOGGLE") end)
end

function Module:_SetupInputUI()
	self.State.Preferred = UserInputService.PreferredInput
	self:_ShowFlagUIForPreferred()
	self:_BindFlagAction()
	self.Session:Connect(UserInputService:GetPropertyChangedSignal("PreferredInput"), function()
		self.State.Preferred = UserInputService.PreferredInput
		self:_ShowFlagUIForPreferred()
	end)
end

function Module:_revealCell(cell)
	if cell.revealed or cell.flagged then
		return
	end
	cell.revealed = true
	self.State.Revealed += 1

	setHiddenVisible(cell, false)
	setMineOrNumber(cell)

	local numLbl: TextLabel = cell.shown.Contents.Number
	local mineLbl: TextLabel = cell.shown.Contents.Mine

	if cell.isMine then
		mineLbl.TextTransparency = 1
		local s = math.max(10, math.floor(mineLbl.TextSize * 0.7))
		mineLbl.TextSize = s
		TweenService
			:Create(
				mineLbl,
				TWEEN_LABEL_POP,
				{ TextTransparency = 0, TextSize = s + math.floor(mineLbl.TextSize * 0.3) }
			)
			:Play()
	else
		if numLbl.Visible then
			numLbl.TextTransparency = 1
			local s = math.max(10, math.floor(numLbl.TextSize * 0.7))
			numLbl.TextSize = s
			TweenService
				:Create(
					numLbl,
					TWEEN_LABEL_POP,
					{ TextTransparency = 0, TextSize = s + math.floor(numLbl.TextSize * 0.3) }
				)
				:Play()
		end
	end

	cell.hiddenScale.Scale = 0.9
	cell.shownScale.Scale = 1.1
	TweenService:Create(cell.hiddenScale, TWEEN_CELL_PUNCH, { Scale = 1 }):Play()
	TweenService:Create(cell.shownScale, TWEEN_CELL_PUNCH, { Scale = 1 }):Play()

	self:_EmitButtonBits(cell.button, false)
end

function Module:_floodFrom(startCell)
	local q = { startCell }
	startCell._queued = true
	while #q > 0 do
		local cell = table.remove(q)
		cell._queued = nil

		self:_revealCell(cell)

		if not cell.isMine and cell.count == 0 then
			for _, d in ipairs(DIRECTIONS) do
				local rr, cc = cell.r + d[1], cell.c + d[2]
				if inBounds(rr, cc, self.State.Rows, self.State.Cols) then
					local ncell = self.State.Cells[rr][cc]
					if not ncell.revealed and not ncell.flagged and not ncell._queued then
						if ncell.count == 0 and not ncell.isMine then
							ncell._queued = true
							table.insert(q, ncell)
						end
						self:_revealCell(ncell)
					end
				end
			end
		end
	end
end

function Module:_onReveal(cell)
	if not self.State.MinesPlaced then
		self:_placeMinesAvoid(cell)
	end
	if cell.flagged or cell.revealed then
		return
	end

	if cell.isMine then
		self:_lose(cell)
		return
	end

	self:_Sound("Click")

	if cell.count == 0 then
		self:_floodFrom(cell)
	else
		self:_revealCell(cell)
	end

	self:_checkWin()
end

function Module:_explodeMineCell(cell, delay: number)
	task.delay(delay, function()
		if cell.revealed then
			return
		end
		setHiddenVisible(cell, false)
		cell.shown.Contents.Mine.Visible = true
		cell.shown.Contents.Number.Visible = false

		local mineLbl: TextLabel = cell.shown.Contents.Mine
		mineLbl.TextTransparency = 1
		local s = math.max(10, math.floor(mineLbl.TextSize * 0.7))
		mineLbl.TextSize = s
		TweenService
			:Create(
				mineLbl,
				TWEEN_LABEL_POP,
				{ TextTransparency = 0, TextSize = s + math.floor(mineLbl.TextSize * 0.35) }
			)
			:Play()

		self:_Sound("Explosion")
		self:_EmitButtonBits(cell.button, true)
	end)
end

function Module:_revealAllMinesCascade(hitCell)
	local hr, hc = hitCell.r, hitCell.c
	local step = 0.15

	for r = 1, self.State.Rows do
		for c = 1, self.State.Cols do
			local cell = self.State.Cells[r][c]
			if cell.isMine then
				local dist = math.sqrt((r - hr) ^ 2 + (c - hc) ^ 2)
				self:_explodeMineCell(cell, dist * step)
			end
		end
	end
end

function Module:_allMinesFlagged()
	local rows, cols, cells = self.State.Rows, self.State.Cols, self.State.Cells
	for r = 1, rows do
		for c = 1, cols do
			local cell = cells[r][c]
			if cell.flagged ~= cell.isMine then
				return false
			end
		end
	end
	return true
end

function Module:_checkWin()
	local total = self.State.Rows * self.State.Cols
	local safeTarget = total - self.State.Mines
	local allSafeRevealed = (self.State.Revealed >= safeTarget)

	if allSafeRevealed and self:_allMinesFlagged() then
		self:_win()
	end
end

function Module:_win()
	local victory = self.Screens.Victory
	self.Session:Clean()
	task.delay(1.2, function()
		if self.Surface:GetAttribute("Screen") == "Gameplay" then
			self:_Sound("Win")
			victory.Indicator:SetAttribute("Text", "<wave>YOU CLEARED IT!</wave>")
			self.Surface:SetAttribute("Screen", "Victory")
		end
	end)
end

function Module:_lose(hitCell)
	self:_revealAllMinesCascade(hitCell)
	local victory = self.Screens.Victory
	self.Session:Clean()
	task.delay(1.2, function()
		if self.Surface:GetAttribute("Screen") == "Gameplay" then
			self:_Sound("Loss")
			victory.Indicator:SetAttribute("Text", "<wave>TRY AGAIN!</wave>")
			self.Surface:SetAttribute("Screen", "Victory")
		end
	end)
end

function Module:_StartGame()
	self.Session:Clean()
	self:_buildGrid()
	self:_SetupInputUI()

	self.Session:Connect(self.Screens.Gameplay.Context.Return.Button.Activated, function()
		self.Surface:SetAttribute("Screen", "Menu")
		self.Session:Clean()
	end)
end

function Module:_StopGame()
	self.Session:Clean()
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

	self.Screens = {
		Idle = self.Surface.Idle,
		Difficulty = self.Surface.Game.Difficulty,
		Loading = self.Surface.Game.Loading,
		Victory = self.Surface.Game.Victory,
		Gameplay = self.Surface.Game.Gameplay,
		Menu = self.Surface.Game.Menu,
	}

	self.Settings = {}
	self.State = {}
	
	self.State.FlagMode = false
	self.State.Preferred = UserInputService.PreferredInput
	self.FlagUI = nil
	self.FlagIcon = nil
	
	self.Trove:Connect(self.Surface:GetAttributeChangedSignal("Screen"), function()
		self:_UpdateScreen()
	end)
	self.Trove:Connect(self.Surface:GetAttributeChangedSignal("Difficulty"), function()
		self:_UpdateDifficulty()
	end)

	self:_SetupIndicators()
	self:_SetupOverlay()
	self:_SetupButtons()

	self.Surface:SetAttribute("Screen", "Idle")
	self.Surface:SetAttribute("Difficulty", "Normal")

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