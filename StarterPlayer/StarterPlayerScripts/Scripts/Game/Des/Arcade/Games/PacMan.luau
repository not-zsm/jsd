--== Imports ==--
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local ContentProvider      = game:GetService("ContentProvider")
local TweenService         = game:GetService("TweenService")
local SoundService         = game:GetService("SoundService")
local RunService           = game:GetService("RunService")

local Packages  = ReplicatedStorage.Packages.Des
local Component = require(Packages.Component)
local Signal    = require(Packages.Signal)
local Trove     = require(Packages.Trove)

local Utils = script.Parent.Parent.Utils
local Thumbstick = require(Utils.Thumbstick)
local Text = require(Utils.Text)

--== Constants ==--
local TWEEN_IN    = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
local TWEEN_OUT   = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TWEEN_INOUT = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local COUNTDOWN = 3

local BIT_TIME_MIN  = 0.20
local BIT_TIME_MAX  = 0.40
local BIT_COUNT_MIN = 3
local BIT_COUNT_MAX = 6
local BIT_SPEED_MIN = 12
local BIT_SPEED_MAX = 24
local BIT_SIZE_MIN  = 1
local BIT_SIZE_MAX  = 3

local TILE_COLS, TILE_ROWS = 23, 19
local DIRS = {
	Up    = Vector2.new(0, -1),
	Left  = Vector2.new(-1, 0),
	Down  = Vector2.new(0,  1),
	Right = Vector2.new(1,  0),
}
local DIR_ORDER = { "Up", "Left", "Down", "Right" }
local OPPOSITE  = { Up="Down", Down="Up", Left="Right", Right="Left" }

local DIFFICULTIES = {
	Easy   = { PLAYER_SPEED_TPS = 6.0, GHOST_SPEED_TPS = 5.4, FRIGHT_TIME = 6.0 },
	Normal = { PLAYER_SPEED_TPS = 6.8, GHOST_SPEED_TPS = 6.5, FRIGHT_TIME = 5.0 },
	Hard   = { PLAYER_SPEED_TPS = 7.4, GHOST_SPEED_TPS = 7.8, FRIGHT_TIME = 4.0 },
}

local PLAYER_ANIM_DT  = 0.12
local GHOST_ANIM_DT   = 0.12
local COLLIDE_RADIUS  = 0.38
local PELLET_SCORE    = 10
local ENERGIZER_SCORE = 50
local GHOST_SCORE     = 200

local CHOMP_TAIL = 0.25

local CHASE_DIST_ENTER = 6.0
local CHASE_DIST_EXIT  = 8.0
local STATE_MIN_TIME   = { Patrol=0.75, Chase=0.75, Fright=0.25, Eyes=0.0 }
local FRIGHT_SPEED_FACTOR = 0.6
local EYES_SPEED_FACTOR   = 1.25
local PATROL_TURN_CHANCE  = 0.12

local FRUIT_DURATION = 9.0
local FRUIT_ORDER = {
	"fruit_cherry","fruit_strawberry","fruit_orange","fruit_apple",
	"fruit_melon","fruit_galaxian"
}
local FRUIT_SCORE = {
	fruit_cherry=100, fruit_strawberry=300, fruit_orange=500,
	fruit_apple=700, fruit_melon=1000, fruit_galaxian=2000
}

local RNG = Random.new()
local BIT = script.BitTemplate
local SPRITES = script.Sprites
local PLAYER_TEMPLATE = script.Player
local GHOST_TEMPLATE  = script.Ghost

--== Module ==--
local Module = {}
Module.Loaded = false
Module.__index = Module

--== Private ==--
local function randomChild(instance: Instance)
	local children = instance:GetChildren()
	return children[RNG:NextInteger(1, #children)]
end

local function two(n) return string.format("%02d", n) end
local function lowerDir(d) return string.lower(d) end

local function ensureSpriteImage(container: Instance): ImageLabel
	if not container then
		return
	end
	local img: ImageLabel? = nil
	local explicit = container:FindFirstChild("Sprite", true)
	if explicit and explicit:IsA("ImageLabel") then
		img = explicit
	else
		for _, d in ipairs(container:GetDescendants()) do
			if d:IsA("ImageLabel") then img = d; break end
		end
	end
	if not img then
		local parentGui = container:IsA("GuiObject") and container or container:FindFirstChildWhichIsA("GuiObject") or container
		img = Instance.new("ImageLabel")
		img.Name = "Sprite"
		img.BackgroundTransparency = 1
		img.ScaleType = Enum.ScaleType.Fit
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.Size = UDim2.fromScale(0.95, 0.95)
		img.Position = UDim2.fromScale(0.5, 0.5)
		img.Parent = parentGui :: Instance
	end
	return img
end

local function applySprite(target: Instance, name: string)
	local dst = ensureSpriteImage(target)
	local src = SPRITES and SPRITES:FindFirstChild(name)
	if not (src and src:IsA("ImageLabel")) then
		return
	end
	dst.Image = src.Image
	dst.ImageRectOffset = src.ImageRectOffset
	dst.ImageRectSize   = src.ImageRectSize
end

function Module:_Sound(name: string)
	local sounds = self.Sounds:FindFirstChild(name)
	if not sounds then return end
	local sound = (randomChild(sounds) :: Sound):Clone()
	sound.Parent = SoundService
	sound:Play()
	task.delay(math.max(0.06, sound.TimeLength / (sound.PlaybackSpeed > 0 and sound.PlaybackSpeed or 1)), function()
		if sound.Parent then sound:Destroy() end
	end)
end

function Module:_AudioShutdown()
	if not self.Loops then return end
	for _, s in pairs(self.Loops) do
		if s then
			if s.IsPlaying then s:Stop() end
		end
	end
end

function Module:_updateAudio()
	local wantWalk = self.State.IsChomping
		and not self.State.Paused
		and not self.State.Locked
		and not self.State.PlayerDying

	local walk = self.Loops and self.Loops.Walk
	if walk then
		if wantWalk and not walk.IsPlaying then walk:Play()
		elseif not wantWalk and walk.IsPlaying then walk:Stop() end
	end

	local frightenedActive = false
	if self.Ghosts then
		for _, g in ipairs(self.Ghosts) do
			if g.State == "Fright" then frightenedActive = true break end
		end
	end
	local wantFright = frightenedActive and not self.State.Paused and not self.State.Locked
	local fr = self.Loops and self.Loops.Frightened
	if fr then
		if wantFright and not fr.IsPlaying then fr:Play()
		elseif not wantFright and fr.IsPlaying then fr:Stop() end
	end
end

function Module:_EmitBitsAbs(hitAbs: Vector2, normal: Vector2)
	local bitsRoot = self.Screens.Gameplay.Board.Decorations.Bits
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
			if bit and bit.Parent then bit:Destroy() end
		end)
	end
end
function Module:_EmitBitsAt(gui: GuiObject, normal: Vector2)
	local center = gui.AbsolutePosition + gui.AbsoluteSize * 0.5
	local radius = gui.AbsoluteSize * 0.5
	local hitAbs = center - Vector2.new(normal.X * radius.X, normal.Y * radius.Y)
	self:_EmitBitsAbs(hitAbs, normal)
end

function Module:_ButtonsIn(screen: GuiObject)
	for _, button in ipairs(screen:GetDescendants()) do
		if not button:IsA("GuiButton") then continue end
		button.Position = UDim2.fromScale(-0.5, 0.5)
		TweenService:Create(
			button,
			TweenInfo.new(
				TWEEN_INOUT.Time, TWEEN_INOUT.EasingStyle, TWEEN_INOUT.EasingDirection, 0, false,
				(button.Parent.LayoutOrder or 1) * 0.15
			),
			{ Position = UDim2.fromScale(0.5, 0.5) }
		):Play()
	end
end
function Module:_ButtonsOut(screen: GuiObject)
	for _, button in ipairs(screen:GetDescendants()) do
		if not button:IsA("GuiButton") then continue end
		button.Position = UDim2.fromScale(0.5, 0.5)
		TweenService:Create(
			button,
			TweenInfo.new(
				TWEEN_INOUT.Time, TWEEN_INOUT.EasingStyle, TWEEN_INOUT.EasingDirection, 0, false,
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
			if screen:GetAttribute("Animate") then self:_ButtonsIn(screen) end
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
			if screen:GetAttribute("Animate") then self:_ButtonsOut(screen) end
			local animatedTitle = screen:FindFirstChild("animatedTitle")
			if animatedTitle then Text.ClearText(animatedTitle) end
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

function Module:_SetupIndicators()
	for _, indicator in ipairs(self.Surface:GetDescendants()) do
		if not indicator:HasTag("Indicator") then continue end
		local text = indicator:GetAttribute("Text")
		local size = indicator:GetAttribute("Size")
		if text then Text.AnimateText(text, indicator, 0.06, Enum.Font.Arcade, "rotate up", nil, size) end
		self.Trove:Connect(indicator:GetAttributeChangedSignal("Text"), function()
			local t = indicator:GetAttribute("Text")
			local s = indicator:GetAttribute("Size")
			if not t then return end
			Text.ClearText(indicator)
			Text.AnimateText(t, indicator, 0.06, Enum.Font.Arcade, "rotate up", nil, s)
		end)
	end
end

function Module:_SetupButtons()
	for _, button in ipairs(self.Surface:GetDescendants()) do
		if not button:IsA("GuiButton") then continue end
		local difficulty = button:GetAttribute("Difficulty")
		local action     = button:GetAttribute("Action")
		local value      = button:GetAttribute("Value")

		local scale = Instance.new("UIScale")
		scale.Parent = button

		self.Trove:Connect(button.MouseEnter,      function() TweenService:Create(scale, TWEEN_INOUT, { Scale = 0.975 }):Play() end)
		self.Trove:Connect(button.MouseLeave,      function() TweenService:Create(scale, TWEEN_INOUT, { Scale = 1     }):Play() end)
		self.Trove:Connect(button.MouseButton1Down,function() TweenService:Create(scale, TWEEN_INOUT, { Scale = 0.925 }):Play() end)
		self.Trove:Connect(button.MouseButton1Up,  function() TweenService:Create(scale, TWEEN_INOUT, { Scale = 1     }):Play() end)

		self.Trove:Connect(button.Activated, function()
			if difficulty then self.Surface:SetAttribute("Difficulty", difficulty) end
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
		overlay, TweenInfo.new(10, Enum.EasingStyle.Linear),
		{ Position = UDim2.new(1, 128, 1, 128) }
	)
	tween:Play()
	self.Trove:Connect(tween.Completed, function()
		overlay.Position = UDim2.new(1, 0, 1, 0)
		tween:Play()
	end)
end

--== Game ==--
function Module:_toScaleFromTile(tp: Vector2)
	return UDim2.fromScale((tp.X + 0.5) / TILE_COLS, (tp.Y + 0.5) / TILE_ROWS)
end
function Module:_tileCenter(tp: Vector2) return Vector2.new(math.floor(tp.X) + 0.5, math.floor(tp.Y) + 0.5) end
function Module:_tileOf(pos: Vector2)    return Vector2.new(math.floor(pos.X), math.floor(pos.Y)) end

local function _inBounds(x,y) return x>=0 and y>=0 and x<TILE_COLS and y<TILE_ROWS end
function Module:_isHardWall(tx: number, ty: number): boolean
	if not _inBounds(tx,ty) then return true end
	return self.Map[ty + 1][tx + 1] == "Wall"
end
function Module:_isGhostWall(tx: number, ty: number): boolean
	if not _inBounds(tx,ty) then return true end
	return self.Map[ty + 1][tx + 1] == "GhostWall"
end
function Module:_isWall(tx: number, ty: number): boolean
	if not _inBounds(tx,ty) then return true end
	local t = self.Map[ty + 1][tx + 1]
	return t == "Wall" or t == "GhostWall"
end
function Module:_canEnter(tile: Vector2): boolean return not self:_isWall(tile.X, tile.Y) end
function Module:_canEnterGhost(tile: Vector2): boolean
	if not _inBounds(tile.X, tile.Y) then return false end
	return not self:_isHardWall(tile.X, tile.Y)
end

local function _centerDistance(a: Vector2, b: Vector2, dir: Vector2)
	if dir.X ~= 0 then return math.abs(b.X - a.X) else return math.abs(b.Y - a.Y) end
end

function Module:_openDirsOrdered(tile: Vector2, forbidDirName: string?): {string}
	local dirs = {}
	for _, name in ipairs(DIR_ORDER) do
		if not (forbidDirName and OPPOSITE[name] == forbidDirName) then
			local nt = tile + DIRS[name]
			if self:_canEnter(nt) then table.insert(dirs, name) end
		end
	end
	if #dirs == 0 and forbidDirName and self:_canEnter(tile + DIRS[OPPOSITE[forbidDirName]]) then
		return { OPPOSITE[forbidDirName] }
	end
	return dirs
end
function Module:_openDirsOrderedGhost(tile: Vector2, forbidDirName: string?): {string}
	local dirs = {}
	for _, name in ipairs(DIR_ORDER) do
		if not (forbidDirName and OPPOSITE[name] == forbidDirName) then
			local nt = tile + DIRS[name]
			if self:_canEnterGhost(nt) then table.insert(dirs, name) end
		end
	end
	if #dirs == 0 and forbidDirName and self:_canEnterGhost(tile + DIRS[OPPOSITE[forbidDirName]]) then
		return { OPPOSITE[forbidDirName] }
	end
	return dirs
end
function Module:_isIntersection(tile: Vector2, currentDirName: string?): boolean
	local count = 0
	for _, name in ipairs(DIR_ORDER) do
		if not (currentDirName and OPPOSITE[name] == currentDirName) then
			if self:_canEnter(tile + DIRS[name]) then count += 1 end
		end
	end
	return count >= 2
end
function Module:_isIntersectionGhost(tile: Vector2, currentDirName: string?): boolean
	local count = 0
	for _, name in ipairs(DIR_ORDER) do
		if not (currentDirName and OPPOSITE[name] == currentDirName) then
			if self:_canEnterGhost(tile + DIRS[name]) then count += 1 end
		end
	end
	return count >= 2
end

local function _manhattanToCenter(ahead: Vector2, targetCenter: Vector2)
	return math.abs(ahead.X + 0.5 - targetCenter.X) + math.abs(ahead.Y + 0.5 - targetCenter.Y)
end
local function _chooseToward(self, tile: Vector2, forbid: string?, targetCenter: Vector2)
	local best, bestScore
	for _, name in ipairs(self:_openDirsOrdered(tile, forbid)) do
		local ahead = tile + DIRS[name]
		local s = _manhattanToCenter(ahead, targetCenter)
		if not best or s < bestScore then best, bestScore = name, s end
	end
	return best
end
local function _chooseTowardGhost(self, tile: Vector2, forbid: string?, targetCenter: Vector2)
	local best, bestScore
	for _, name in ipairs(self:_openDirsOrderedGhost(tile, forbid)) do
		local ahead = tile + DIRS[name]
		local s = _manhattanToCenter(ahead, targetCenter)
		if not best or s < bestScore then best, bestScore = name, s end
	end
	return best
end
local function _randomDir(self, tile: Vector2, forbid: string?)
	local options = self:_openDirsOrdered(tile, forbid)
	if #options == 0 then return forbid and OPPOSITE[forbid] or "Left" end
	return options[RNG:NextInteger(1, #options)]
end
local function _randomDirGhost(self, tile: Vector2, forbid: string?)
	local options = self:_openDirsOrderedGhost(tile, forbid)
	if #options == 0 then return forbid and OPPOSITE[forbid] or "Left" end
	return options[RNG:NextInteger(1, #options)]
end
local function _forwardOpen(self, tile: Vector2, dirName: string)      return self:_canEnter(tile + DIRS[dirName]) end
local function _forwardOpenGhost(self, tile: Vector2, dirName: string) return self:_canEnterGhost(tile + DIRS[dirName]) end
local function _mustChoose(self, tile: Vector2, dirName: string)       return (not _forwardOpen(self, tile, dirName)) or self:_isIntersection(tile, dirName) end
local function _mustChooseGhost(self, tile: Vector2, dirName: string)  return (not _forwardOpenGhost(self, tile, dirName)) or self:_isIntersectionGhost(tile, dirName) end

local CONTENT_SET = {
	empty=true, wall=true, ghost_wall=true, pellet=true, energizer=true, fruit=true,
	ghost_spawn=true, player_spawn=true, teleport_left=true, teleport_right=true
}
local function parseRC(name: string) local rr, cc = name:match("^R(%d+)C(%d+)$"); return tonumber(rr), tonumber(cc) end
local function findContentChild(cell: Instance): GuiObject?
	for _, c in ipairs(cell:GetChildren()) do
		if c:IsA("GuiObject") and CONTENT_SET[string.lower(c.Name)] then return c end
	end
	return nil
end

function Module:_buildMap()
	self.Map = table.create(TILE_ROWS)
	self.Spawns = { Player = {}, Ghosts = {} }
	self.RemainingPellets = 0
	self.TotalPellets = 0

	self.Teleports = { LeftByRow = {}, RightByRow = {} }
	self.TeleportLookup = table.create(TILE_ROWS)
	self.CellContent = table.create(TILE_ROWS)
	self.CellOrb = table.create(TILE_ROWS)
	self.FruitSlots = {}

	local grid = self.Screens.Gameplay.Board.Contents:FindFirstChild("Grid")
	for r = 1, TILE_ROWS do
		self.Map[r] = table.create(TILE_COLS, "Empty")
		self.TeleportLookup[r] = table.create(TILE_COLS, nil)
		self.CellContent[r] = table.create(TILE_COLS, nil)
		self.CellOrb[r] = table.create(TILE_COLS, nil)
	end

	for _, cell in ipairs(grid:GetChildren()) do
		if not cell:IsA("Frame") then continue end
		local r, c = cell:GetAttribute("Row"), cell:GetAttribute("Col")
		if not r or not c then r, c = parseRC(cell.Name) end
		if not r or not c then continue end
		r, c = math.clamp(r, 1, TILE_ROWS), math.clamp(c, 1, TILE_COLS)

		local content = findContentChild(cell)
		if not content then continue end
		self.CellContent[r][c] = content

		local tag = string.lower(content.Name)
		if tag == "wall" then
			self.Map[r][c] = "Wall"
		elseif tag == "ghost_wall" then
			self.Map[r][c] = "GhostWall"
		elseif tag == "pellet" or tag == "energizer" then
			local orb = content:FindFirstChild("orb")
			if orb and orb:IsA("GuiObject") then
				orb.Visible = true
				self.CellOrb[r][c] = orb
			end
			self.Map[r][c] = (tag == "pellet") and "Pellet" or "Energizer"
			self.RemainingPellets += 1
			self.TotalPellets += 1
		elseif tag == "fruit" then
			table.insert(self.FruitSlots, Vector2.new(c - 1, r - 1))
		elseif tag == "player_spawn" then
			table.insert(self.Spawns.Player, Vector2.new(c - 1, r - 1))
		elseif tag == "ghost_spawn" then
			table.insert(self.Spawns.Ghosts, Vector2.new(c - 1, r - 1))
		elseif tag == "teleport_left" then
			self.TeleportLookup[r][c] = "L"
			self.Teleports.LeftByRow[r] = self.Teleports.LeftByRow[r] or {}
			table.insert(self.Teleports.LeftByRow[r], Vector2.new(c - 1, r - 1))
		elseif tag == "teleport_right" then
			self.TeleportLookup[r][c] = "R"
			self.Teleports.RightByRow[r] = self.Teleports.RightByRow[r] or {}
			table.insert(self.Teleports.RightByRow[r], Vector2.new(c - 1, r - 1))
		end
	end

	self.GhostBaseTile   = self.Spawns.Ghosts[1] or Vector2.new(11, 8)
	self.GhostBaseCenter = self:_tileCenter(self.GhostBaseTile)

	self.FruitTriggers = {
		math.max(1, math.floor(self.TotalPellets * 0.25)),
		math.max(2, math.floor(self.TotalPellets * 0.75)),
	}
end

local function _pickPartner(self, rowIdx: number, side: "L" | "R"): Vector2?
	if side == "L" then
		local lst = self.Teleports.RightByRow[rowIdx]
		if lst and #lst > 0 then return lst[1] end
		for rr = 1, TILE_ROWS do
			lst = self.Teleports.RightByRow[rr]
			if lst and #lst > 0 then return lst[1] end
		end
	else
		local lst = self.Teleports.LeftByRow[rowIdx]
		if lst and #lst > 0 then return lst[1] end
		for rr = 1, TILE_ROWS do
			lst = self.Teleports.LeftByRow[rr]
			if lst and #lst > 0 then return lst[1] end
		end
	end
	return nil
end

local function _forcedDirFromExit(self, exitTile: Vector2): string
	local r, c = exitTile.Y + 1, exitTile.X + 1
	local exitSide = self.TeleportLookup[r] and self.TeleportLookup[r][c]
	return (exitSide == "R") and "Left" or "Right"
end

function Module:_BindInput()
	self.State.DirQueued = nil
	self.State.DirActive = nil

	local DEADZONE = 0.3
	local lastStickDir = nil

	local function fourWayHandler(_, state, input)
		if state ~= Enum.UserInputState.Begin and state ~= Enum.UserInputState.Change then return end
		local k = input.KeyCode
		if k == Enum.KeyCode.W or k == Enum.KeyCode.Up or k == Enum.KeyCode.DPadUp then
			self.State.DirQueued = "Up"
		elseif k == Enum.KeyCode.S or k == Enum.KeyCode.Down or k == Enum.KeyCode.DPadDown then
			self.State.DirQueued = "Down"
		elseif k == Enum.KeyCode.A or k == Enum.KeyCode.Left or k == Enum.KeyCode.DPadLeft then
			self.State.DirQueued = "Left"
		elseif k == Enum.KeyCode.D or k == Enum.KeyCode.Right or k == Enum.KeyCode.DPadRight then
			self.State.DirQueued = "Right"
		end
	end

	ContextActionService:BindAction(
		"PACMAN_MOVE_4WAY",
		fourWayHandler,
		false,
		Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
		Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right,
		Enum.KeyCode.DPadUp, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadDown, Enum.KeyCode.DPadRight
	)

	local function stickHandler(_, state, input)
		if input.KeyCode ~= Enum.KeyCode.Thumbstick1 then return end
		if state == Enum.UserInputState.End then
			lastStickDir = nil
			return
		end
		if state ~= Enum.UserInputState.Begin and state ~= Enum.UserInputState.Change then return end

		local x = input.Position.X
		local y = -input.Position.Y
		local ax = math.abs(x)
		local ay = math.abs(y)

		local dir
		if ax < DEADZONE and ay < DEADZONE then
			dir = nil
		elseif ax > ay then
			dir = (x > 0) and "Right" or "Left"
		else
			dir = (y > 0) and "Down" or "Up"
		end

		if dir and dir ~= lastStickDir then
			lastStickDir = dir
			self.State.DirQueued = dir
		elseif not dir then
			lastStickDir = nil
		end
	end

	ContextActionService:BindAction(
		"PACMAN_MOVE_STICK",
		stickHandler,
		false,
		Enum.KeyCode.Thumbstick1
	)

	local last
	Thumbstick.new({
		Position = UDim2.new(0.8, 0, 0.6, 0),
		Theme = "Modern",
		UiType = 1,
		Deadzone = 2
	}).Changed:Connect(function(direction)
		local x, y = direction.X, direction.Y
		local ax, ay = math.abs(x), math.abs(y)
		if ax < DEADZONE and ay < DEADZONE then
			last = nil
			return
		end

		local dir
		if ax > ay then
			dir = (x > 0) and "Right" or "Left"
		else
			dir = (y > 0) and "Up" or "Down"
		end

		if dir ~= last then
			self.State.DirQueued = dir
			last = dir
		end
	end)

	self.Session:Add(function()
		ContextActionService:UnbindAction("PACMAN_MOVE_4WAY")
		ContextActionService:UnbindAction("PACMAN_MOVE_STICK")
		
		Thumbstick:ClearUis()
	end)
end

function Module:_updateHUD()
	local score = self.Screens.Gameplay.Score
	if not score then return end
	local leftI  = score.Left  and score.Left.Indicator
	local rightI = score.Right and score.Right.Indicator
	if leftI  then leftI:SetAttribute("Text", tostring(self.State.Score or 0)) end
	if rightI then rightI:SetAttribute("Text", `x{tostring(self.State.Lives or 0)}`) end
end

function Module:_ResetScore()
	self.State.Score = 0
	self.State.Lives = 3
	self.State.GhostChain = 0
	self.State.ChompTime = 0
	self.State.IsChomping = false
	self:_updateHUD()
end

function Module:_clearActors()
	if self.PlayerGui then self.PlayerGui:Destroy() self.PlayerGui = nil end
	if self.Ghosts then for _, g in ipairs(self.Ghosts) do if g.Gui then g.Gui:Destroy() end end end
	self.Ghosts = {}
	if self.Fruit and self.Fruit.Gui then self.Fruit.Gui:Destroy() end
	self.Fruit = nil
end

local GhostKinds = { "blinky", "pinky", "inky", "clyde" }

function Module:_spawnActors()
	self:_clearActors()

	local board = self.Screens.Gameplay.Board.Contents

	local pSpawn = (#self.Spawns.Player > 0) and self.Spawns.Player[RNG:NextInteger(1, #self.Spawns.Player)] or Vector2.new(11, 14)
	self.State.PlayerTile  = pSpawn
	self.State.PlayerPos   = self:_tileCenter(pSpawn)
	self.State.DirActive   = nil
	self.State.DirQueued   = nil
	self.State.TeleLock    = nil
	self.State.PlayerAnim  = 0
	self.State.LastDir     = "Right"
	self.State.PlayerDying = false

	local p = PLAYER_TEMPLATE:Clone()
	p.Name = "Player"
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.Size = UDim2.fromScale(1 / TILE_COLS, 1 / TILE_ROWS)
	p.Position = self:_toScaleFromTile(pSpawn)
	p.Parent = board
	self.PlayerGui = p
	applySprite(self.PlayerGui, "pacman_move_right_02")

	self.Ghosts = {}
	local corners = {
		Vector2.new(1,1), Vector2.new(TILE_COLS-2,1),
		Vector2.new(1,TILE_ROWS-2), Vector2.new(TILE_COLS-2,TILE_ROWS-2),
	}
	for i = 1, math.max(4, #self.Spawns.Ghosts) do
		local kind   = GhostKinds[((i - 1) % #GhostKinds) + 1]
		local gSpawn = (#self.Spawns.Ghosts > 0) and self.Spawns.Ghosts[((i - 1) % #self.Spawns.Ghosts) + 1] or Vector2.new(11, 8)
		local scatter= corners[((i - 1) % #corners) + 1]
		local g = {
			Kind  = kind, Tile  = gSpawn, Pos = self:_tileCenter(gSpawn),
			Dir   = "Left", State = "Patrol", StateTime = 0, FrightTime=0,
			Scatter = scatter, PatrolBias = RNG:NextNumber() < 0.5 and "Left" or "Right",
			TeleLock = nil, Anim = 0,
		}
		local gui = GHOST_TEMPLATE:Clone()
		gui.Name = `Ghost_{kind}`
		gui.AnchorPoint = Vector2.new(0.5, 0.5)
		gui.Size = UDim2.fromScale(1 / TILE_COLS, 1 / TILE_ROWS)
		gui.Position = self:_toScaleFromTile(gSpawn)
		gui.Parent = board
		g.Gui = gui
		applySprite(gui, `ghost_{kind}_left_01`)
		table.insert(self.Ghosts, g)
	end

	self.State.Level = (self.State.Level or 0) + 1
	self.State.PelletsEaten = 0
	self.Fruit = nil
	self.FruitSpawned1, self.FruitSpawned2 = false, false
end

function Module:_findFruitTile(): Vector2
	if #self.FruitSlots > 0 then return self.FruitSlots[1] end
	local t = self.GhostBaseTile + Vector2.new(0, 1)
	if self:_canEnter(t) then return t end
	t = Vector2.new(math.floor(TILE_COLS/2), math.floor(TILE_ROWS/2))
	if self:_canEnter(t) then return t end
	return self.Spawns.Player[1] or Vector2.new(11, 14)
end

function Module:_spawnFruitIfNeeded()
	if self.Fruit then return end
	for i, trig in ipairs(self.FruitTriggers) do
		if not self[`FruitSpawned{i}`] and self.State.PelletsEaten >= trig then
			self[`FruitSpawned{i}`] = true
			local pool = {}
			for _, n in ipairs(FRUIT_ORDER) do if SPRITES:FindFirstChild(n) then table.insert(pool, n) end end
			if #pool == 0 then return end
			local idx = ((self.State.Level - 1) % #pool) + 1
			local name = pool[idx]
			local tile = self:_findFruitTile()
			local gui = Instance.new("ImageLabel")
			gui.Name = "Fruit"
			gui.BackgroundTransparency = 1
			gui.AnchorPoint = Vector2.new(0.5, 0.5)
			gui.Size = UDim2.fromScale(1 / TILE_COLS, 1 / TILE_ROWS)
			gui.Position = self:_toScaleFromTile(tile)
			gui.Parent = self.Screens.Gameplay.Board.Contents
			applySprite(gui, name)
			self.Fruit = { Name = name, Tile = tile, Gui = gui, Time = FRUIT_DURATION }
			break
		end
	end
end

function Module:_updateFruit(dt: number)
	local f = self.Fruit
	if not f then return end
	f.Time -= dt
	if f.Time <= 0 then if f.Gui then f.Gui:Destroy() end self.Fruit = nil return end
	if self.State.PlayerTile.X == f.Tile.X and self.State.PlayerTile.Y == f.Tile.Y then
		local pts = FRUIT_SCORE[f.Name] or 100
		self.State.Score += pts
		self:_updateHUD()
		self:_Sound("Fruit")
		self:_EmitBitsAt(self.PlayerGui, Vector2.new(0, -1))
		if f.Gui then f.Gui:Destroy() end
		self.Fruit = nil
	end
end

function Module:_applyQueuedTurnAtCenter()
	if not self.State.DirQueued then return end
	local try = self.State.DirQueued
	local nextTile = self.State.PlayerTile + DIRS[try]
	if self:_canEnter(nextTile) then
		self.State.DirActive = try
		self.State.DirQueued = nil
	end
end

function Module:_teleportPlayerIfNeeded(): boolean
	local tile = self.State.PlayerTile
	local r, c = tile.Y + 1, tile.X + 1
	local side = self.TeleportLookup[r] and self.TeleportLookup[r][c]
	if not side then
		self.State.TeleLock = nil
		return false
	end
	if self.State.TeleLock and self.State.TeleLock.X == tile.X and self.State.TeleLock.Y == tile.Y then
		return false
	end

	local partner = _pickPartner(self, r, side)
	if not partner then return false end

	local forcedDir = _forcedDirFromExit(self, partner)
	local ahead     = partner + DIRS[forcedDir]

	if self:_canEnter(ahead) then
		self.State.PlayerTile = ahead
		self.State.PlayerPos  = self:_tileCenter(ahead)
	else
		self.State.PlayerTile = partner
		self.State.PlayerPos  = partner + Vector2.new(0.5, 0.5)
	end

	self.State.DirActive  = forcedDir
	self.State.TeleLock   = partner
	return true
end

function Module:_eatAt(tile: Vector2)
	local r, c = tile.Y + 1, tile.X + 1
	local t = self.Map[r][c]
	if t == "Pellet" or t == "Energizer" then
		local orb = self.CellOrb[r][c]
		if orb then orb.Visible = false end
		self.Map[r][c] = "Empty"
		self.RemainingPellets -= 1
		self.State.PelletsEaten += 1
		if t == "Pellet" then
			self.State.Score += PELLET_SCORE
			self:_EmitBitsAt(self.PlayerGui, -DIRS[self.State.DirActive])
		else
			self.State.Score += ENERGIZER_SCORE
			self.State.GhostChain = 0
			for _, g in ipairs(self.Ghosts) do
				if g.State ~= "Eyes" then
					g.State = "Fright"
					g.StateTime = 0
					g.FrightTime = self.Settings.FRIGHT_TIME
					g.Dir = OPPOSITE[g.Dir]
				end
			end
			self:_EmitBitsAt(self.PlayerGui, -DIRS[self.State.DirActive])
		end
		self:_updateHUD()
		self:_spawnFruitIfNeeded()
		
		self.State.ChompTime = CHOMP_TAIL
	end
end

function Module:_updatePlayer(dt: number)
	if self.State.DirActive == nil then self:_applyQueuedTurnAtCenter() end

	local moving   = false
	local stepLeft = self.Settings.PLAYER_SPEED_TPS * dt
	local EPS_CONT = 1e-3

	while stepLeft > 1e-6 do
		if not self.State.DirActive then break end
		local dirVec   = DIRS[self.State.DirActive]
		local nextTile = self.State.PlayerTile + dirVec
		if not self:_canEnter(nextTile) then self.State.DirActive = nil break end

		moving = true
		local targetCenter = self:_tileCenter(nextTile)
		local dist = _centerDistance(self.State.PlayerPos, targetCenter, dirVec)
		local move = math.min(stepLeft, dist)
		self.State.PlayerPos = self.State.PlayerPos + dirVec * move
		stepLeft -= move

		if dist - move <= 1e-6 then
			self.State.PlayerTile = nextTile
			self.State.PlayerPos  = targetCenter
			self:_eatAt(nextTile)

			if self:_teleportPlayerIfNeeded() then
				stepLeft = math.max(stepLeft, EPS_CONT)
			else
				local r, c = self.State.PlayerTile.Y + 1, self.State.PlayerTile.X + 1
				if not (self.TeleportLookup[r] and self.TeleportLookup[r][c]) then self.State.TeleLock = nil end
			end

			self:_applyQueuedTurnAtCenter()
		end
	end

	self.State.IsMoving = moving

	self.State.PlayerAnim += dt
	if moving then self.State.LastDir = self.State.DirActive or self.State.LastDir end
	local frameIdx = moving and ((math.floor(self.State.PlayerAnim / PLAYER_ANIM_DT) % 2) + 1) or 1
	applySprite(self.PlayerGui, `pacman_move_{lowerDir(self.State.DirActive or self.State.LastDir or "Right")}_{two(frameIdx)}`)
	self.PlayerGui.Position = self:_toScaleFromTile(self.State.PlayerPos - Vector2.new(0.5, 0.5))
	
	self.State.ChompTime = math.max(0, (self.State.ChompTime or 0) - dt)
	self.State.IsChomping = (self.State.ChompTime or 0) > 0
end

function Module:_playDeathAnimThenRespawn()
	self.State.PlayerDying = true
	self.State.Locked = true
	self:_updateAudio()
	task.spawn(function()
		for i = 1, 12 do
			applySprite(self.PlayerGui, `pacman_die_{two(i)}`)
			task.wait(0.08)
		end
		if self.State.Lives <= 0 then
			local victory = self.Screens.Victory
			victory.Indicator:SetAttribute("Text", "<wave>GAME OVER</wave>")
			self.Surface:SetAttribute("Screen", "Victory")
			self:_ResetScore()
			return
		end
		self:_spawnActors()
		self:_Countdown()
		self.State.PlayerDying = false
	end)
end

local function ghostDirFrame(kind: string, dir: string, idx: number) return `ghost_{kind}_{lowerDir(dir)}_{two(idx)}` end
local function ghostEyes(dir: string) return `ghost_eyes_{lowerDir(dir)}` end
local function frightFrame(g)
	if g.FrightTime <= 1.5 then return `ghost_fright_0{((math.floor(g.Anim / 0.10) % 2) + 3)}`
	else return `ghost_fright_0{((math.floor(g.Anim / 0.12) % 2) + 1)}` end
end
local function _updateGhostSprite(g)
	if g.State == "Eyes" then applySprite(g.Gui, ghostEyes(g.Dir))
	elseif g.State == "Fright" then applySprite(g.Gui, frightFrame(g))
	else local idx = (math.floor(g.Anim / GHOST_ANIM_DT) % 2) + 1; applySprite(g.Gui, ghostDirFrame(g.Kind, g.Dir, idx)) end
end

function Module:_tryTeleportGhost(g)
	local tile = g.Tile
	local r, c = tile.Y + 1, tile.X + 1
	local side = self.TeleportLookup[r] and self.TeleportLookup[r][c]
	if not side then g.TeleLock = nil; return false end
	if g.TeleLock and g.TeleLock.X == tile.X and g.TeleLock.Y == tile.Y then return false end

	local partner = _pickPartner(self, r, side)
	if not partner then return false end

	local forcedDir = _forcedDirFromExit(self, partner)
	local ahead     = partner + DIRS[forcedDir]

	if self:_canEnterGhost(ahead) then
		g.Tile = ahead
		g.Pos  = self:_tileCenter(ahead)
	else
		g.Tile = partner
		g.Pos  = partner + Vector2.new(0.5, 0.5)
	end
	g.Dir     = forcedDir
	g.TeleLock= partner
	return true
end

function Module:_updateGhosts(dt: number)
	local speedBase = self.Settings.GHOST_SPEED_TPS

	for _, g in ipairs(self.Ghosts) do
		g.StateTime += dt
		g.Anim += dt

		if g.State == "Fright" then
			g.FrightTime = math.max(0, g.FrightTime - dt)
			if g.FrightTime <= 0 and g.StateTime >= STATE_MIN_TIME.Fright then g.State = "Patrol"; g.StateTime = 0 end
		end

		if g.State ~= "Fright" and g.State ~= "Eyes" then
			local distp = _manhattanToCenter(self:_tileOf(g.Pos), self.State.PlayerPos)
			if g.State == "Chase" then
				if distp >= CHASE_DIST_EXIT and g.StateTime >= STATE_MIN_TIME.Chase then g.State = "Patrol"; g.StateTime = 0 end
			else
				if distp <= CHASE_DIST_ENTER and g.StateTime >= STATE_MIN_TIME.Patrol then g.State = "Chase"; g.StateTime = 0 end
			end
		end

		local speed = speedBase
		if g.State == "Fright" then speed *= FRIGHT_SPEED_FACTOR end
		if g.State == "Eyes"   then speed *= EYES_SPEED_FACTOR   end

		local stepLeft = speed * dt
		local guard = 0
		while stepLeft > 1e-6 do
			guard += 1; if guard > 128 then break end

			local atCenter = (g.Pos - self:_tileCenter(g.Tile)).Magnitude <= 1e-6
			if atCenter and _mustChooseGhost(self, g.Tile, g.Dir) then
				local forbid = g.Dir
				if g.State == "Eyes" then
					g.Dir = _chooseTowardGhost(self, g.Tile, forbid, self.GhostBaseCenter) or g.Dir
				elseif g.State == "Fright" then
					g.Dir = _randomDirGhost(self, g.Tile, forbid)
				elseif g.State == "Chase" then
					g.Dir = _chooseTowardGhost(self, g.Tile, forbid, self.State.PlayerPos) or g.Dir
				else
					if _forwardOpenGhost(self, g.Tile, g.Dir) and RNG:NextNumber() > PATROL_TURN_CHANCE then
					else
						g.Dir = _chooseTowardGhost(self, g.Tile, forbid, self:_tileCenter(g.Scatter)) or g.Dir
					end
				end
			end

			local dirVec = DIRS[g.Dir] or DIRS.Left
			local nextTile = g.Tile + dirVec
			if not self:_canEnterGhost(nextTile) then
				local forbid = g.Dir
				if g.State == "Eyes" then
					g.Dir = _chooseTowardGhost(self, g.Tile, forbid, self.GhostBaseCenter) or OPPOSITE[g.Dir]
				elseif g.State == "Fright" then
					g.Dir = _randomDirGhost(self, g.Tile, forbid)
				elseif g.State == "Chase" then
					g.Dir = _chooseTowardGhost(self, g.Tile, forbid, self.State.PlayerPos) or OPPOSITE[g.Dir]
				else
					g.Dir = _chooseTowardGhost(self, g.Tile, forbid, self:_tileCenter(g.Scatter)) or OPPOSITE[g.Dir]
				end
				dirVec = DIRS[g.Dir] or DIRS.Left
				nextTile = g.Tile + dirVec
				if not self:_canEnterGhost(nextTile) then break end
			end

			local targetCenter = self:_tileCenter(nextTile)
			local dist = _centerDistance(g.Pos, targetCenter, dirVec)

			if dist <= 1e-6 then
				g.Tile = nextTile
				g.Pos  = targetCenter
				if self:_tryTeleportGhost(g) then end
				if g.State == "Eyes" and (g.Pos - self.GhostBaseCenter).Magnitude <= 1e-6 then g.State = "Patrol"; g.StateTime = 0 end
			else
				local move = math.min(stepLeft, dist)
				g.Pos = g.Pos + dirVec * move
				stepLeft -= move
			end
		end

		_updateGhostSprite(g)
		g.Gui.Position = self:_toScaleFromTile(g.Pos - Vector2.new(0.5, 0.5))
	end
end

function Module:_checkCollisions()
	for _, g in ipairs(self.Ghosts) do
		if g.State ~= "Eyes" and (g.Pos - self.State.PlayerPos).Magnitude <= COLLIDE_RADIUS then
			if g.State == "Fright" then
				self.State.GhostChain += 1
				self.State.Score += GHOST_SCORE * self.State.GhostChain
				self:_updateHUD()
				self:_Sound("Ghost Eaten")
				self:_EmitBitsAt(g.Gui, Vector2.new(0, -1))
				g.State = "Eyes"; g.StateTime = 0; g.FrightTime = 0
			else
				if self.State.PlayerDying then return true end
				self.State.Lives -= 1
				self:_updateHUD()
				self:_Sound("Death")
				self:_playDeathAnimThenRespawn()
				return true
			end
		end
	end
	return false
end

function Module:_maybeWin()
	if self.RemainingPellets <= 0 then
		local victory = self.Screens.Victory
		victory.Indicator:SetAttribute("Text", "<wave>LEVEL CLEAR</wave>")
		self:_Sound("Win")
		self.Surface:SetAttribute("Screen", "Victory")
		self:_ResetScore()
		return true
	end
	return false
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
		if self.Surface:GetAttribute("Screen") ~= "Gameplay" then indicator:SetAttribute("Text", nil) return end
		indicator:SetAttribute("Text", tostring(n))
		task.wait(1)
	end
	if self.Surface:GetAttribute("Screen") ~= "Gameplay" then return end
	TweenService:Create(timerCG, TWEEN_OUT, { GroupTransparency = 1 }):Play()
	indicator:SetAttribute("Text", nil)
	self.State.Locked = false
end

function Module:_TogglePause()
	if self.State.Locked then return end
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
	self:_updateAudio()
end

function Module:_StartGame()
	self.Session:Clean()
	self.State.Paused = false
	self.State.Locked = false

	self:_BindInput()
	self:_buildMap()
	self:_spawnActors()
	self:_ResetScore()
	self:_Countdown()

	self.Loops = {
		Walk = self.Sounds["Walk"],
		Frightened = self.Sounds["Frightened"],
	}

	self.Session:Connect(RunService.PostSimulation, function(dt)
		if self.State.Paused or self.State.Locked then
			self:_updateAudio()
			return
		end
		self:_updatePlayer(dt)
		self:_updateGhosts(dt)
		self:_updateFruit(dt)
		self:_updateAudio()
		if self:_checkCollisions() then return end
		if self:_maybeWin() then return end
	end)
end

function Module:_StopGame()
	self.Session:Clean()
	self:_AudioShutdown()
	self:_clearActors()

	local gameplay = self.Screens.Gameplay
	local pausedCG = gameplay.Board.Paused
	local pauseInd = pausedCG and pausedCG.Indicator
	local timerCG = gameplay.Board.Timer
	local timerInd = timerCG and timerCG.Indicator

	if pauseInd then pauseInd:SetAttribute("Text", nil) end
	if timerInd then timerInd:SetAttribute("Text", nil) end

	if pausedCG then TweenService:Create(pausedCG, TWEEN_OUT, { GroupTransparency = 1 }):Play() end
	if timerCG then TweenService:Create(timerCG, TWEEN_OUT, { GroupTransparency = 1 }):Play() end
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
	self:_AudioShutdown()
	self:_clearActors()
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

	self.Signal  = Signal.new()
	self.Session = Trove.new()
	self.Trove   = Trove.new()

	self.Surface = script.Surface:Clone()
	self.Surface.Parent = instance

	self.Sounds   = self.Surface.Sounds
	self.Settings = {}
	self.State    = {}

	self.Screens = {
		Idle       = self.Surface.Idle,
		Difficulty = self.Surface.Game.Difficulty,
		Gameplay   = self.Surface.Game.Gameplay,
		Loading    = self.Surface.Game.Loading,
		Victory    = self.Surface.Game.Victory,
		Menu       = self.Surface.Game.Menu,
	}

	self.Trove:Connect(self.Surface:GetAttributeChangedSignal("Screen"),     function() self:_UpdateScreen() end)
	self.Trove:Connect(self.Surface:GetAttributeChangedSignal("Difficulty"), function() self:_UpdateDifficulty() end)

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
	self:_AudioShutdown()
	self:_clearActors()
	table.clear(self)
	setmetatable(self, nil)
end

--== Return ==--
return Module