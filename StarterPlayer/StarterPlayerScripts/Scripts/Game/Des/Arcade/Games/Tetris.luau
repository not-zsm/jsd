--== Imports ==--
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages.Des
local Signal = require(Packages.Signal)
local Trove = require(Packages.Trove)

local Utils = script.Parent.Parent.Utils
local Thumbstick = require(Utils.Thumbstick)
local Text = require(Utils.Text)

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

--== Constants ==--
local TWEEN_IN = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
local TWEEN_OUT = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TWEEN_INOUT = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local COLS, ROWS = 10, 15
local LOCK_DELAY = 0.5
local NEXT_SLOTS = 3

local DIFFICULTIES = {
	Easy = { GRAVITY = 0.90, MIN_GRAVITY = 0.20, POINTS_PER_LEVEL = 900, LEVEL_MULT = 0.94 },
	Normal = { GRAVITY = 0.60, MIN_GRAVITY = 0.12, POINTS_PER_LEVEL = 800, LEVEL_MULT = 0.92 },
	Hard = { GRAVITY = 0.38, MIN_GRAVITY = 0.08, POINTS_PER_LEVEL = 700, LEVEL_MULT = 0.90 },
}

local GRAVITY_STEP_SCORE = 800
local GRAVITY_MULT = 0.92
local GRAVITY_MIN = 0.06 

local BIT_TIME_MIN, BIT_TIME_MAX = 0.20, 0.40
local BIT_COUNT_MIN, BIT_COUNT_MAX = 7, 12
local BIT_SPEED_MIN, BIT_SPEED_MAX = 30, 64
local BIT_SIZE_MIN, BIT_SIZE_MAX = 4, 8

local RNG = Random.new()
local LETTERS = script.LetterTemplates
local FILLED = script.FilledTemplate
local EMPTY = script.EmptyTemplate
local GHOST = script.GhostTemplate
local BIT = script.BitTemplate

local COLORS = {
	I = Color3.fromRGB(0, 205, 255),
	J = Color3.fromRGB(0, 96, 255),
	L = Color3.fromRGB(255, 142, 28),
	O = Color3.fromRGB(255, 214, 10),
	S = Color3.fromRGB(48, 219, 91),
	T = Color3.fromRGB(174, 86, 255),
	Z = Color3.fromRGB(255, 82, 82),
}

local SHAPES = {
	I = {
		{ {-1, 0}, {0, 0}, {1, 0}, {2, 0} },  -- 0
		{ {0, -1}, {0, 0}, {0, 1}, {0, 2} },  -- 1
		{ {-2, 0}, {-1, 0}, {0, 0}, {1, 0} }, -- 2
		{ {0, -2}, {0, -1}, {0, 0}, {0, 1} }, -- 3
	},
	J = {
		{ {-1, -1}, {-1, 0}, {0, 0}, {1, 0} }, -- 0
		{ {0, -1}, {0, 0}, {0, 1}, {1, -1} },  -- 1
		{ {-1, 0}, {0, 0}, {1, 0}, {1, 1} },   -- 2
		{ {-1, 1}, {0, -1}, {0, 0}, {0, 1} },  -- 3
	},
	L = {
		{ {1, -1}, {-1, 0}, {0, 0}, {1, 0} },  -- 0
		{ {-1, -1}, {0, -1}, {0, 0}, {0, 1} }, -- 1
		{ {-1, 0}, {0, 0}, {1, 0}, {-1, 1} },  -- 2
		{ {0, -1}, {0, 0}, {0, 1}, {1, 1} },   -- 3
	},
	O = {
		{ {0, 0}, {0, 1}, {1, 0}, {1, 1} }, -- 0
		{ {0, 0}, {0, 1}, {1, 0}, {1, 1} }, -- 1
		{ {0, 0}, {0, 1}, {1, 0}, {1, 1} }, -- 2
		{ {0, 0}, {0, 1}, {1, 0}, {1, 1} }, -- 3
	},
	S = {
		{ {0, 0}, {1, 0}, {-1, 1}, {0, 1} }, -- 0
		{ {0, -1}, {0, 0}, {1, 0}, {1, 1} }, -- 1
		{ {0, 0}, {1, 0}, {-1, 1}, {0, 1} }, -- 2
		{ {0, -1}, {0, 0}, {1, 0}, {1, 1} }, -- 3
	},
	T = {
		{ {-1, 0}, {0, 0}, {1, 0}, {0, -1} }, -- 0
		{ {0, -1}, {0, 0}, {0, 1}, {1, 0} },  -- 1
		{ {-1, 0}, {0, 0}, {1, 0}, {0, 1} },  -- 2
		{ {0, -1}, {0, 0}, {0, 1}, {-1, 0} }, -- 3
	},
	Z = {
		{ {-1, 0}, {0, 0}, {0, 1}, {1, 1} }, -- 0
		{ {1, -1}, {0, 0}, {1, 0}, {0, 1} }, -- 1
		{ {-1, 0}, {0, 0}, {0, 1}, {1, 1} }, -- 2
		{ {1, -1}, {0, 0}, {1, 0}, {0, 1} }, -- 3
	},
}

local JLSTZ_KICKS = {
	[0] = {
		[1] = {{0, 0}, {-1, 0}, {-1, 1}, {0, -2}, {-1, -2}},
		[3] = {{0, 0}, {1, 0}, {1, 1}, {0, -2}, {1, -2}},
	},
	[1] = {
		[2] = {{0, 0}, {1, 0}, {1, -1}, {0, 2}, {1, 2}},
		[0] = {{0, 0}, {1, 0}, {1, -1}, {0, 2}, {1, 2}},
	},
	[2] = {
		[3] = {{0, 0}, {1, 0}, {1, 1}, {0, -2}, {1, -2}},
		[1] = {{0, 0}, {-1, 0}, {-1, 1}, {0, -2}, {-1, -2}},
	},
	[3] = {
		[0] = {{0, 0}, {-1, 0}, {-1, -1}, {0, 2}, {-1, 2}},
		[2] = {{0, 0}, {-1, 0}, {-1, -1}, {0, 2}, {-1, 2}},
	},
}

local I_KICKS = {
	[0] = {
		[1] = {{0, 0}, {-2, 0}, {1, 0}, {-2, -1}, {1, 2}},
		[3] = {{0, 0}, {-1, 0}, {2, 0}, {-1, 2}, {2, -1}},
	},
	[1] = {
		[2] = {{0, 0}, {-1, 0}, {2, 0}, {-1, -2}, {2, 1}},
		[0] = {{0, 0}, {2, 0}, {-1, 0}, {2, -1}, {-1, 2}},
	},
	[2] = {
		[3] = {{0, 0}, {2, 0}, {-1, 0}, {2, 1}, {-1, -2}},
		[1] = {{0, 0}, {1, 0}, {-2, 0}, {1, 2}, {-2, -1}},
	},
	[3] = {
		[0] = {{0, 0}, {1, 0}, {-2, 0}, {1, -2}, {-2, 1}},
		[2] = {{0, 0}, {-2, 0}, {1, 0}, {-2, 1}, {1, -2}},
	},
}

local PIECE_IDS = { "I", "J", "L", "O", "S", "T", "Z" }
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

local function layoutOrderFromRC(r, c)
	return (r - 1) * COLS + c
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
			if not action then
				return
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

function Module:_UpdateDifficulty()
	local current = self.Surface:GetAttribute("Difficulty")
	self.Settings = DIFFICULTIES[current]
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

--== Game ==--
local function cloneCell(kind: "Empty" | "Ghost" | "Filled", color: Color3?)
	local cell
	if kind == "Empty" then
		cell = EMPTY:Clone()
	elseif kind == "Ghost" then
		cell = GHOST:Clone()
		local st = cell:FindFirstChildOfClass("UIStroke")
		if st and color then
			st.Color = color
		end
	else
		cell = FILLED:Clone()
		if color then
			cell.BackgroundColor3 = color
			local st = cell:FindFirstChildOfClass("UIStroke")
			if st then
				st.Color     = color:Lerp(Color3.new(1, 1, 1), 0.25)
				st.Thickness = 2
			end
		end
	end
	local sc = cell:FindFirstChildOfClass("UIScale")
	if sc then
		if kind == "Ghost" then
			return cell
		end
		sc.Scale = (kind == "Filled") and 0.9 or 0.95
		TweenService:Create(sc, TWEEN_INOUT, { Scale = 1 }):Play()
	end
	return cell
end

local function makeBag()
	local bag = table.clone(PIECE_IDS)
	for i = #bag, 2, -1 do
		local j = RNG:NextInteger(1, i)
		bag[i], bag[j] = bag[j], bag[i]
	end
	return bag
end

local function copyBlocks(blocks)
	local out = table.create(#blocks)
	for i = 1, #blocks do
		out[i] = { blocks[i][1], blocks[i][2] }
	end
	return out
end

local function getBlocks(id, rot)
	return copyBlocks(SHAPES[id][(rot % 4) + 1])
end

local function shapeBounds(blocks)
	local minx, maxx, miny, maxy = math.huge, -math.huge, math.huge, -math.huge
	for _, b in ipairs(blocks) do
		local x, y = b[1], b[2]
		if x < minx then
			minx = x
		end
		if x > maxx then
			maxx = x
		end
		if y < miny then
			miny = y
		end
		if y > maxy then
			maxy = y
		end
	end
	return minx, maxx, miny, maxy, (maxx - minx + 1), (maxy - miny + 1)
end

function Module:_emitBitsAtCell(cellGui: GuiObject, tint: Color3?)
	local bitsRoot = cellGui.Bits
	if not bitsRoot then
		return
	end
	local center = bitsRoot.AbsoluteSize * 0.5
	local count = RNG:NextInteger(BIT_COUNT_MIN, BIT_COUNT_MAX)
	for _ = 1, count do
		local bit = BIT:Clone()
		bit.AnchorPoint = Vector2.new(0.5, 0.5)
		if tint then
			bit.BackgroundColor3 = tint
		end
		local sz = RNG:NextInteger(BIT_SIZE_MIN, BIT_SIZE_MAX)
		bit.Size = UDim2.fromOffset(sz, sz)
		bit.Position = UDim2.fromOffset(center.X, center.Y)
		bit.BackgroundTransparency = 0
		bit.Parent = bitsRoot

		local ang = RNG:NextNumber(0, math.pi * 2)
		local dir = Vector2.new(math.cos(ang), math.sin(ang))
		local travel = RNG:NextNumber(BIT_SPEED_MIN, BIT_SPEED_MAX)
		local dur = RNG:NextNumber(BIT_TIME_MIN, BIT_TIME_MAX)
		local dest = center + dir * travel

		TweenService:Create(bit, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(dest.X, dest.Y),
			BackgroundTransparency = 1,
		}):Play()
		task.delay(dur + 0.06, function()
			if bit.Parent then
				bit:Destroy()
			end
		end)
	end
end

function Module:_clearBoardUI()
	local holder = self.Screens.Gameplay.Center.Board.Contents
	for _, ch in ipairs(holder:GetChildren()) do
		if ch:IsA("UIGridLayout") or ch:IsA("UIPadding") or ch.Name == "Decorations" then
			continue
		end
		if ch:IsA("GuiObject") then
			ch:Destroy()
		end
	end
end

function Module:_buildBoard()
	self:_clearBoardUI()
	self.State.Grid = table.create(ROWS)
	local holder = self.Screens.Gameplay.Center.Board.Contents
	for r = 1, ROWS do
		self.State.Grid[r] = table.create(COLS)
		for c = 1, COLS do
			local cell = cloneCell("Empty")
			cell.LayoutOrder = layoutOrderFromRC(r, c)
			cell.Parent = holder
			self.State.Grid[r][c] = { kind = "Empty", gui = cell }
		end
	end
end

function Module:_setCell(r, c, kind, color)
	if r < 1 or r > ROWS or c < 1 or c > COLS then
		return
	end
	local slot = self.State.Grid[r][c]
	if slot.kind == kind and ((kind ~= "Filled" and kind ~= "Ghost") or slot._color == color) then
		return
	end
	local order = slot.gui.LayoutOrder
	slot.gui:Destroy()
	local newGui = cloneCell(kind, color)
	newGui.LayoutOrder = order
	newGui.Parent = self.Screens.Gameplay.Center.Board.Contents
	self.State.Grid[r][c] =
		{ kind = kind, gui = newGui, _color = color, _locked = slot._locked and (kind == "Filled") or nil }
end

function Module:_spawnPiece(id)
	local blocks0 = getBlocks(id, 0)
	local minx, maxx, miny, maxy, w, h = shapeBounds(blocks0)

	local spawnX = math.floor((COLS - w) / 2) + 1 - minx
	local spawnY = 1 - miny

	spawnX = math.clamp(spawnX, 1 - minx, COLS - maxx)
	spawnY = math.clamp(spawnY, 1 - miny, ROWS - maxy)

	self.State.Active = { id = id, rot = 0, x = spawnX, y = spawnY, blocks = blocks0 }
	self.State.LockTimer = 0
end

function Module:_pullQueue()
	while #self.State.Queue < NEXT_SLOTS + 1 do
		local bag = makeBag()
		for _, p in ipairs(bag) do
			table.insert(self.State.Queue, p)
		end
	end
	local id = table.remove(self.State.Queue, 1)
	self:_refreshNextUI()
	return id
end

function Module:_refreshNextUI()
	local root = self.Screens.Gameplay.Center.Context.Next.Contents
	for i = 1, NEXT_SLOTS do
		local slot = root:FindFirstChild(tostring(i))
		if slot then
			for _, ch in ipairs(slot:GetChildren()) do
				if ch:IsA("GuiObject") then
					ch:Destroy()
				end
			end
			local id = self.State.Queue[i]
			if id then
				local tpl = LETTERS:FindFirstChild(id)
				if tpl then
					tpl:Clone().Parent = slot
				end
			end
		end
	end
end

function Module:_refreshHeldUI()
	local slot = self.Screens.Gameplay.Center.Context.Held.Contents
	for _, ch in ipairs(slot:GetChildren()) do
		if ch:IsA("GuiObject") then
			ch:Destroy()
		end
	end
	if self.State.Held then
		local tpl = LETTERS:FindFirstChild(self.State.Held)
		if tpl then
			tpl:Clone().Parent = slot
		end
	end
end

function Module:_tryHold()
	if self.State.HoldUsed then
		return
	end
	self.State.HoldUsed = true
	local cur = self.State.Active and self.State.Active.id
	if not cur then
		return
	end
	if self.State.Held then
		local swap = self.State.Held
		self.State.Held = cur
		self:_refreshHeldUI()
		self:_spawnPiece(swap)
	else
		self.State.Held = cur
		self:_refreshHeldUI()
		self:_spawnPiece(self:_pullQueue())
	end
end

function Module:_fits(atX, atY, id, rot)
	local blocks = getBlocks(id, rot)
	for _, b in ipairs(blocks) do
		local c = atX + b[1]
		local r = atY + b[2]
		if c < 1 or c > COLS or r < 1 or r > ROWS then
			return false
		end
		local slot = self.State.Grid[r][c]
		if slot.kind == "Filled" and slot._locked then
			return false
		end
	end
	return true
end

function Module:_clearActiveVisuals()
	for r = 1, ROWS do
		for c = 1, COLS do
			local slot = self.State.Grid[r][c]
			if slot.kind == "Ghost" or slot._active then
				self:_setCell(r, c, "Empty")
			end
		end
	end
end

function Module:_renderActiveAndGhost()
	local a = self.State.Active
	if not a then return end

	local color = COLORS[a.id] or Color3.new(1, 1, 1)

	local gy = a.y
	while self:_fits(a.x, gy + 1, a.id, a.rot) do
		gy += 1
	end

	local ghostCells = table.create(#a.blocks)
	for _, b in ipairs(a.blocks) do
		local r = gy + b[2]
		local c = a.x + b[1]
		self:_setCell(r, c, "Ghost", color)
		ghostCells[#ghostCells + 1] = { r = r, c = c }
	end

	for _, rc in ipairs(ghostCells) do
		local r, c = rc.r, rc.c
		local slot  = self.State.Grid[r][c]
		local gui   = slot and slot.gui
		if gui then
			local grad = gui.Gradient
			local aboveIsGhost = (r > 1) and (self.State.Grid[r - 1][c].kind == "Ghost")
			grad.Visible = not aboveIsGhost
			grad.BackgroundColor3 = color
		end
	end

	for _, b in ipairs(a.blocks) do
		local r = a.y + b[2]
		local c = a.x + b[1]
		self:_setCell(r, c, "Filled", color)
		self.State.Grid[r][c]._active = true
	end
end

function Module:_lockActive()
	local a = self.State.Active
	if not a then
		return
	end
	local color = COLORS[a.id] or Color3.new(1, 1, 1)
	for _, b in ipairs(a.blocks) do
		local c = a.x + b[1]
		local r = a.y + b[2]
		self:_setCell(r, c, "Filled", color)
		local slot = self.State.Grid[r][c]
		slot._active = nil
		slot._locked = true
		self:_emitBitsAtCell(slot.gui, color)
		
		local st = slot.gui:FindFirstChildOfClass("UIStroke")
		if st then
			st.Thickness = 6
			TweenService:Create(st, TWEEN_INOUT, { Thickness = 0 }):Play()
		end
	end
	self:_Sound("Place")
	self.State.HoldUsed = false
	self.State.Active = nil
end

function Module:_clearLines()
	local toClear, isCleared = {}, {}
	for r = 1, ROWS do
		local full = true
		for c = 1, COLS do
			if self.State.Grid[r][c].kind ~= "Filled" then
				full = false
				break
			end
		end
		if full then
			table.insert(toClear, r)
			isCleared[r] = true
		end
	end
	if #toClear == 0 then return end
	table.sort(toClear)

	local holder = self.Screens.Gameplay.Center.Board.Contents
	local clearedColors = {}
	for _, r in ipairs(toClear) do
		local rowColors = table.create(COLS)
		for c = 1, COLS do
			local slot = self.State.Grid[r][c]
			local gui  = slot.gui
			local st   = gui and gui:FindFirstChildOfClass("UIStroke")
			rowColors[c] = (st and st.Color) or (gui and gui.BackgroundColor3) or Color3.new(1,1,1)
			if gui then gui:Destroy() end
			self.State.Grid[r][c] = { kind = "Empty", gui = nil }
		end
		clearedColors[r] = rowColors
	end

	local write = ROWS
	for read = ROWS, 1, -1 do
		if not isCleared[read] then
			for c = 1, COLS do
				local slot = self.State.Grid[read][c]
				self.State.Grid[write][c] = slot
				if slot.gui then
					slot.gui.LayoutOrder = layoutOrderFromRC(write, c)
					if slot.gui.Parent ~= holder then
						slot.gui.Parent = holder
					end
				end
			end
			write -= 1
		end
	end

	for r = 1, write do
		for c = 1, COLS do
			local cell = cloneCell("Empty")
			cell.LayoutOrder = layoutOrderFromRC(r, c)
			cell.Parent = holder
			self.State.Grid[r][c] = { kind = "Empty", gui = cell }
		end
	end

	for _, r in ipairs(toClear) do
		local colors = clearedColors[r]
		for c = 1, COLS do
			local slot = self.State.Grid[r][c]
			if slot.gui then
				self:_emitBitsAtCell(slot.gui, colors[c])
			end
		end
	end

	local cleared = #toClear
	self.State.Score = (self.State.Score or 0) + 100 * (cleared * cleared)

	local scoreInd = self.Screens.Gameplay.Score.Indicator
	scoreInd:SetAttribute("Text", tostring(self.State.Score))
	
	self:_Sound("Clear")
end

function Module:_hardDrop()
	local a = self.State.Active
	if not a then
		return
	end
	while self:_fits(a.x, a.y + 1, a.id, a.rot) do
		a.y += 1
	end
	self:_lockActive()
	self:_clearLines()
	self:_spawnNextOrGameOver()
end

function Module:_stepActive(dcx, dcy, drot)
	local a = self.State.Active
	if not a then
		return
	end
	local nx, ny, nr = a.x + (dcx or 0), a.y + (dcy or 0), (a.rot + (drot or 0)) % 4

	if drot == 0 then
		if self:_fits(nx, ny, a.id, a.rot) then
			a.x, a.y = nx, ny
			self.State.LockTimer = 0
			return true
		end
		return false
	else
		local from = a.rot
		local to = nr
		local kick_table
		if a.id == "I" then
			kick_table = I_KICKS
		elseif a.id == "O" then
			kick_table = { [from] = { [to] = {{0, 0}} } }
		else
			kick_table = JLSTZ_KICKS
		end
		local kicks = (kick_table[from] or {})[to] or {}
		for _, kick in ipairs(kicks) do
			local test_x = nx + kick[1]
			local test_y = ny + kick[2]
			if self:_fits(test_x, test_y, a.id, to) then
				a.x, a.y, a.rot = test_x, test_y, to
				a.blocks = getBlocks(a.id, a.rot)
				--self.State.LockTimer = 0
				return true
			end
		end
		return false
	end
end

function Module:_spawnNextOrGameOver()
	local id = self:_pullQueue()
	self:_spawnPiece(id)
	if not self:_fits(self.State.Active.x, self.State.Active.y, id, 0) then
		self:_gameOver()
	end
end

function Module:_BindInput()
	local UserInputService = game:GetService("UserInputService")

	local DEADZONE = 0.35
	local DAS      = 0.45
	local ARR      = 0.15

	local held = { left=false, right=false, down=false }
	local tHeld = { left=0, right=0, down=0 }
	local delay = { left=DAS, right=DAS, down=ARR }
	local lastStickDir = nil

	local function move(dx, dy)
		if self.State.Paused or self.State.Locked then return end
		if self:_stepActive(dx, dy, 0) then self:_Sound("Move") end
	end
	local function rotate(dir)
		if self.State.Paused or self.State.Locked then return end
		if self:_stepActive(0, 0, dir) then self:_Sound("Rotate") end
	end
	local function hardDrop()
		if self.State.Paused or self.State.Locked then return end
		self:_hardDrop()
	end
	local function hold()
		if self.State.Paused or self.State.Locked then return end
		self:_tryHold()
		self:_Sound("Hold")
	end

	local function tapHandler(_, state, input)
		if self.State.Paused or self.State.Locked then return end
		if state ~= Enum.UserInputState.Begin then return end
		local k = input.KeyCode
		if k == Enum.KeyCode.Up or k == Enum.KeyCode.W or k == Enum.KeyCode.E or k == Enum.KeyCode.ButtonA then
			rotate(1)
		elseif k == Enum.KeyCode.Q or k == Enum.KeyCode.ButtonX then
			rotate(-1)
		elseif k == Enum.KeyCode.Space or k == Enum.KeyCode.ButtonB or k == Enum.KeyCode.ButtonR2 then
			hardDrop()
		elseif k == Enum.KeyCode.LeftShift or k == Enum.KeyCode.ButtonY or k == Enum.KeyCode.ButtonR1 then
			hold()
		end
	end

	ContextActionService:BindAction(
		"TETRIS_INPUT_TAP",
		tapHandler,
		false,
		Enum.KeyCode.Up, Enum.KeyCode.W, Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.Space, Enum.KeyCode.LeftShift,
		Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonR2
	)

	local function heldHandler(_, state, input)
		if self.State.Paused or self.State.Locked then return end
		local begin = state == Enum.UserInputState.Begin
		local ended = state == Enum.UserInputState.End
		local k = input.KeyCode
		local function set(which, v)
			if held[which] ~= v then
				held[which] = v
				tHeld[which] = 0
				delay[which] = ARR
				if v then
					if which == "left" then move(1, 0) end
					if which == "right" then move(-1, 0) end
					if which == "down" then move(0, 1) end
				end
			end
		end
		if k == Enum.KeyCode.Left or k == Enum.KeyCode.A or k == Enum.KeyCode.DPadLeft then
			set("left", begin and true or ended and false or held.left)
		elseif k == Enum.KeyCode.Right or k == Enum.KeyCode.D or k == Enum.KeyCode.DPadRight then
			set("right", begin and true or ended and false or held.right)
		elseif k == Enum.KeyCode.Down or k == Enum.KeyCode.S or k == Enum.KeyCode.DPadDown then
			set("down", begin and true or ended and false or held.down)
		end
	end

	ContextActionService:BindAction(
		"TETRIS_INPUT_HELD",
		heldHandler,
		false,
		Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.Down,
		Enum.KeyCode.A, Enum.KeyCode.D, Enum.KeyCode.S,
		Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight, Enum.KeyCode.DPadDown
	)

	local function stickHandler(_, state, input)
		if input.KeyCode ~= Enum.KeyCode.Thumbstick1 then return end
		local x = input.Position.X
		local y = -input.Position.Y
		local ax, ay = math.abs(x), math.abs(y)
		if state == Enum.UserInputState.End or (ax < DEADZONE and ay < DEADZONE) then
			lastStickDir = nil
			held.left, held.right, held.down = false, false, false
			tHeld.left, tHeld.right, tHeld.down = 0, 0, 0
			delay.left, delay.right, delay.down = DAS, DAS, ARR
			return
		end
		if state ~= Enum.UserInputState.Begin and state ~= Enum.UserInputState.Change then return end
		local dir = (ax > ay) and ((x > 0) and "right" or "left") or ((y > 0) and "up" or "down")
		if dir ~= lastStickDir then
			held.left, held.right, held.down = false, false, false
			tHeld.left, tHeld.right, tHeld.down = 0, 0, 0
			delay.left, delay.right, delay.down = ARR, ARR, ARR
			lastStickDir = dir
			if dir == "left" then
				move(1, 0)
				held.left = true
			elseif dir == "right" then
				move(-1, 0)
				held.right = true
			elseif dir == "down" then
				move(0, 1)
				held.down = true
			end
		end
	end

	ContextActionService:BindAction("TETRIS_INPUT_STICK", stickHandler, false, Enum.KeyCode.Thumbstick1)

	local preferred = UserInputService.PreferredInput
	local mobileGui

	local function mountMobileUI()
		if preferred == Enum.PreferredInput.Touch then
			if not mobileGui then
				mobileGui = MOBILE:Clone()
				mobileGui.Parent = PlayerGui
				local function hook(name, fn)
					local btn = mobileGui:FindFirstChild(name, true)
					if btn and btn.Activated then self.Session:Connect(btn.Activated, fn) end
				end
				hook("Hold", hold)
				hook("Drop", hardDrop)
				hook("RotateRight", function() rotate(1) end)
				hook("RotateLeft",  function() rotate(-1) end)
			end
			mobileGui.Enabled = true
		else
			if mobileGui then mobileGui.Enabled = false end
		end
	end

	local ts
	local function clearHolds()
		held.left, held.right, held.down = false, false, false
		tHeld.left, tHeld.right, tHeld.down = 0, 0, 0
		delay.left, delay.right, delay.down = DAS, DAS, ARR
		lastStickDir = nil
	end
	local function fromVec2Touch(v: Vector2)
		local x, y = v.X, v.Y
		local ax, ay = math.abs(x), math.abs(y)
		if ax < DEADZONE and ay < DEADZONE then
			return
		end
		local dir = (ax > ay) and ((x > 0) and "right" or "left") or ((y > 0) and "up" or "down")
		if dir ~= lastStickDir then
			held.left, held.right, held.down = false, false, false
			tHeld.left, tHeld.right, tHeld.down = 0, 0, 0
			delay.left, delay.right, delay.down = ARR, ARR, ARR
			lastStickDir = dir
			if dir == "left" then
				move(1, 0);  held.left  = true
			elseif dir == "right" then
				move(-1, 0); held.right = true
			elseif dir == "down" then
				move(0, 1);  held.down  = true
			end
		end
	end
	local function ensureThumbstick()
		if preferred == Enum.PreferredInput.Touch then
			if ts then return end
			ts = Thumbstick.new({
				Position = UDim2.new(0.8, 0, 0.6, 0),
				Theme = "Modern",
				UiType = 1,
				Deadzone = 2
			})
			self.Session:Connect(ts.Changed, function(v) fromVec2Touch(v) end)
			self.Session:Connect(ts.Ended, function() clearHolds() end)
		else
			if ts then ts = nil end
			clearHolds()
			if Thumbstick and Thumbstick.ClearUis then Thumbstick:ClearUis() end
		end
	end

	mountMobileUI()
	ensureThumbstick()
	self.Session:Connect(UserInputService:GetPropertyChangedSignal("PreferredInput"), function()
		preferred = UserInputService.PreferredInput
		mountMobileUI()
		ensureThumbstick()
	end)

	local function anyDown(list)
		for i = 1, #list do
			if UserInputService:IsKeyDown(list[i]) then return true end
		end
		return false
	end

	self.Session:Connect(RunService.RenderStepped, function(dt)
		if self.State.Paused or self.State.Locked then
			clearHolds()
			return
		end
		if held.left and not anyDown{Enum.KeyCode.Left, Enum.KeyCode.A, Enum.KeyCode.DPadLeft} and lastStickDir ~= "left" then
			held.left = false; tHeld.left = 0; delay.left = DAS
		end
		if held.right and not anyDown{Enum.KeyCode.Right, Enum.KeyCode.D, Enum.KeyCode.DPadRight} and lastStickDir ~= "right" then
			held.right = false; tHeld.right = 0; delay.right = DAS
		end
		if held.down and not anyDown{Enum.KeyCode.Down, Enum.KeyCode.S, Enum.KeyCode.DPadDown} and lastStickDir ~= "down" then
			held.down = false; tHeld.down = 0; delay.down = ARR
		end
		if held.left then
			tHeld.left += dt
			if tHeld.left >= delay.left then
				tHeld.left -= delay.left
				move(1, 0)
				delay.left = ARR
			end
		end
		if held.right then
			tHeld.right += dt
			if tHeld.right >= delay.right then
				tHeld.right -= delay.right
				move(-1, 0)
				delay.right = ARR
			end
		end
		if held.down then
			tHeld.down += dt
			if tHeld.down >= delay.down then
				tHeld.down = 0
				move(0, 1)
				delay.down = ARR
			end
		end
	end)

	self.Session:Add(function()
		ContextActionService:UnbindAction("TETRIS_INPUT_TAP")
		ContextActionService:UnbindAction("TETRIS_INPUT_HELD")
		ContextActionService:UnbindAction("TETRIS_INPUT_STICK")
		if mobileGui then mobileGui:Destroy() end
		if Thumbstick and Thumbstick.ClearUis then Thumbstick:ClearUis() end
	end)
end

function Module:_currentGravity()
	local cfg = self.Settings or {}
	local base = cfg.GRAVITY or 0.60
	local minG = cfg.MIN_GRAVITY or 0.10
	local ppl  = cfg.POINTS_PER_LEVEL or 800
	local mult = cfg.LEVEL_MULT or 0.92

	local score = self.State.Score or 0
	local level = math.floor(score / ppl)

	local g = base * (mult ^ level)
	if g < minG then g = minG end
	return g
end

function Module:_update(dt)
	if self.State.Paused or self.State.Locked then return end
	self.State.FallAcc = (self.State.FallAcc or 0) + dt

	self:_clearActiveVisuals()

	local interval = self:_currentGravity()

	if self.State.FallAcc >= interval then
		self.State.FallAcc -= interval
		if not self:_stepActive(0, 1, 0) then
			self.State.LockTimer = (self.State.LockTimer or 0) + interval
			if self.State.LockTimer >= LOCK_DELAY then
				self:_lockActive()
				self:_clearLines()
				self:_spawnNextOrGameOver()
			end
		end
	end

	if self.State.Active then
		self:_renderActiveAndGhost()
	end
end

function Module:_Countdown()
	task.spawn(function()
		script.Parent.Parent.Start:Play()
	end)
	
	local gameplay = self.Screens.Gameplay.Center
	local timerCG = gameplay.Board.Timer
	local indicator = timerCG.Indicator
	self.State.Locked = true

	TweenService:Create(timerCG, TWEEN_IN, { GroupTransparency = 0 }):Play()
	for n = 3, 1, -1 do
		if self.Surface:GetAttribute("Screen") ~= "Gameplay" then
			indicator:SetAttribute("Text", nil)
			return
		end
		indicator:SetAttribute("Text", tostring(n))
		task.wait(1)
	end

	TweenService:Create(timerCG, TWEEN_OUT, { GroupTransparency = 1 }):Play()
	indicator:SetAttribute("Text", nil)
	self.State.Locked = false
end

function Module:_gameOver()
	self.Session:Clean()
	self.State.Active = nil
	local victory = self.Screens.Victory
	victory.Indicator:SetAttribute("Text", "<wave>GAME OVER</wave>")
	self:_Sound("Loss")
	if self.Surface:GetAttribute("Screen") == "Gameplay" then
		self.Surface:SetAttribute("Screen", "Victory")
	end
end

function Module:_TogglePause()
	if self.State.Locked then
		return
	end

	local gameplay = self.Screens.Gameplay
	local pausedCG = gameplay.Center.Board.Paused
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

	self.State = {
		Paused = false,
		Locked = false,
		Queue = {},
		Held = nil,
		HoldUsed = false,
		Score = 0,
	}

	local sc = self.Screens.Gameplay.Score.Indicator
	sc:SetAttribute("Text", "0")

	self:_buildBoard()
	self:_refreshNextUI()
	self:_refreshHeldUI()
	self:_spawnPiece(self:_pullQueue())
	self:_BindInput()
	self:_Countdown()

	self.Session:Connect(RunService.Heartbeat, function(dt)
		self:_update(dt)
	end)
end

function Module:_StopGame()
	self.Session:Clean()

	local gameplay = self.Screens.Gameplay.Center
	local pausedCG = gameplay.Board.Paused
	local timerCG = gameplay.Board.Timer

	pausedCG.Indicator:SetAttribute("Text", nil)
	TweenService:Create(pausedCG, TWEEN_OUT, { GroupTransparency = 1 }):Play()
	
	timerCG.Indicator:SetAttribute("Text", nil)
	TweenService:Create(timerCG, TWEEN_OUT, { GroupTransparency = 1 }):Play()
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
		Keybinds = self.Surface.Game.Keybinds,
		Loading = self.Surface.Game.Loading,
		Victory = self.Surface.Game.Victory,
		Gameplay = self.Surface.Game.Gameplay,
		Menu = self.Surface.Game.Menu,
	}

	self.Settings = {}
	self.State = {}
	
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