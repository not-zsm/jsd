--== Imports ==--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local network = require( ReplicatedStorage.modules.network )
local TweenService      = game:GetService("TweenService")
local SoundService      = game:GetService("SoundService")
local HttpService       = game:GetService("HttpService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")

local Packages  = ReplicatedStorage.Packages.Des
local Signal    = require(Packages.Signal)
local Trove     = require(Packages.Trove)

local Player    = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Controller = require("@self/Controller")
local Knifes     = require("@self/Knifes")
local Sweep      = require("@self/Sweep")
local Shake      = require("@self/Shake")
local Bits       = require("@self/Bits")
local Gray       = require("@self/Gray")
local Flower     = require("@self/Flower")
local Helper     = require("@self/Helper")
local Sequencer  = require("@self/Sequencer")


--== Types ==--
export type Attack = {
	Kind: string,
	Size: Vector2,
	Pos: Vector2,
	AbsPos: Vector2,
	AbsSize: Vector2,
	Dmg: number,
	Destroy: () -> (),
}
export type Visual = {
	Kind: string,
	Size: Vector2,
	Pos: Vector2,
	AbsPos: Vector2,
	AbsSize: Vector2,
	Destroy: () -> (),
}

--== Constants ==--
local SOUNDS = script.Assets.Sounds
local GUI    = script.Assets.GUI
local CHARA  = script.Assets.Chara
local ANIMS  = script.Assets.Animations

local TWEENS = {
	IN       = TweenInfo.new(0.25, Enum.EasingStyle.Sine,   Enum.EasingDirection.In),
	FADE     = TweenInfo.new(0.45, Enum.EasingStyle.Cubic,  Enum.EasingDirection.InOut),
	FLICKER  = TweenInfo.new(0.08, Enum.EasingStyle.Sine,   Enum.EasingDirection.InOut),
	HEART    = TweenInfo.new(0.08, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
}

local BREAK_DELAY = 3.0
local RNG = Random.new()

local SPRITES = script.Assets.Sprites

--== Module ==--
local Module = {}
Module.__index = Module

local Current = nil

--== Private ==--
local function rt(a,b) return RNG:NextNumber(a,b) end
local function ri(a,b) return RNG:NextInteger(a,b) end

local function _playSound(name: string)
	Helper.playLocalSound(SOUNDS, name)
end

local function _safeRatio(r: number): number
	return math.clamp(r, 1e-3, 1e3)
end

function Module:_stepAspect(dtFrame: number)
	local dt = Helper.toSec(dtFrame)
	local ar = self.AspectRatio
	local want = self.State.Arena.Ratio
	local parent = self.Arena.Parent :: GuiObject
	local parentAbs = parent.AbsoluteSize

	local function absFromUDim2(u: UDim2): Vector2
		local w = parentAbs.X * u.X.Scale + u.X.Offset
		local h = parentAbs.Y * u.Y.Scale + u.Y.Offset
		return Vector2.new(w, h)
	end

	local function currentVisualRatio(): number
		local sz = absFromUDim2(self.Arena.Size)
		local h = math.max(1, sz.Y)
		return sz.X / h
	end

	local function startEnable(targetRatio: number)
		local from = currentVisualRatio()
		self.Aspect.active = true
		self.Aspect.disabling = false
		self.Aspect.t = 0
		self.Aspect.from = from
		self.Aspect.to = targetRatio
		ar.Parent = self.Arena
		ar.AspectRatio = from
	end

	local function startDisable()
		local targetSize = (self.State.Arena.Kind == "2D")
			and self.State.Arena.ActualSize
			or UDim2.new(self.State.Arena.ActualSize.X.Scale, 0, 0, self.State.Player.Size.Y * 1.5)

		local absTarget = absFromUDim2(targetSize)
		local freeRatio = absTarget.X / math.max(1, absTarget.Y)

		local from = (ar.Parent == self.Arena) and ar.AspectRatio or currentVisualRatio()
		self.Aspect.active = true
		self.Aspect.disabling = true
		self.Aspect.t = 0
		self.Aspect.from = from
		self.Aspect.to = freeRatio

		if ar.Parent ~= self.Arena then ar.Parent = self.Arena end
		ar.AspectRatio = from
	end

	if want ~= nil then
		if not self.Aspect.active and ar.Parent ~= self.Arena then
			startEnable(want)
		elseif self.Aspect.active and not self.Aspect.disabling and self.Aspect.to ~= want then
			self.Aspect.to = want
		end
	else
		if (ar.Parent == self.Arena) and (not self.Aspect.disabling) then
			startDisable()
		end
	end

	if self.Aspect.active then
		self.Aspect.t = math.min(1, self.Aspect.t + dt / self.Aspect.dur)
		local k = Helper.easeInOutCubic(self.Aspect.t)
		local r = math.lerp(self.Aspect.from, self.Aspect.to, k)
		ar.AspectRatio = r

		if self.Aspect.t >= 1 then
			if self.Aspect.disabling then
				ar.Parent = script
			end
			self.Aspect.active = false
			self.Aspect.disabling = false
		end
	end
end

function Module:_setupIntro()
	if self._Stopped then return end

	local introHeart = self.GUI.Canvas.Heart
	local arenaHeart = self.Arena.Contents.Controller
	local absSize    = arenaHeart.AbsoluteSize

	introHeart.ImageTransparency = 1
	introHeart.AnchorPoint = Vector2.new(0.5, 0.5)
	introHeart.Position    = UDim2.fromScale(0.5, 0.5)
	introHeart.Size        = UDim2.fromOffset(absSize.X, absSize.Y)

	self.GUI.Canvas.Decorations.GroupTransparency = 1
	self.GUI.Canvas.Contents.GroupTransparency    = 1
	TweenService:Create(self.GUI.Canvas.Decorations, TWEENS.FADE, { GroupTransparency = 0 }):Play()

	for _ = 1, 4 do
		if self._Stopped then return end
		TweenService:Create(introHeart, TWEENS.FLICKER, { ImageTransparency = 0    }):Play()
		task.wait(0.08)
		TweenService:Create(introHeart, TWEENS.FLICKER, { ImageTransparency = 0.85 }):Play()
		task.wait(0.08)
	end
	TweenService:Create(introHeart, TWEENS.HEART, { ImageTransparency = 0 }):Play()

	local targetAbs = Helper.centerAbs(arenaHeart)
	local parentAbs = Helper.centerAbs(introHeart.Parent)

	local ox = Helper.roundpx(targetAbs.X - parentAbs.X)
	local oy = Helper.roundpx(targetAbs.Y - parentAbs.Y)

	local move = TweenService:Create(introHeart, TWEENS.IN, { Position = UDim2.new(0.5, ox, 0.5, oy) })
	move:Play()
	move.Completed:Wait()
	if self._Stopped then return end

	TweenService:Create(self.GUI.Canvas.Contents, TWEENS.FADE, { GroupTransparency = 0 }):Play()

	introHeart:Destroy()
end

function Module:_setupViewport()
	local viewport = self.Character.Viewport :: ViewportFrame

	local camera  = Instance.new("Camera")
	camera.CFrame = CFrame.new(0, 0.5, -6) * CFrame.Angles(0, math.rad(180), 0)
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local chara  = CHARA:Clone()
	chara.Parent = viewport.WorldModel
	chara:PivotTo(CFrame.new())

	local animator = chara.Humanoid.Animator
	animator:LoadAnimation(ANIMS.Idle):Play()
end

function Module:_breakNow()
	if self._Broken then return end
	self._Broken = true
	self.Controller:Break()
	if self.Sequencer then
		self.Sequencer:Stop()
	end
end

--== Public ==--
function Module:setRatio(value: number?)
	self.State.Arena.Ratio = value
end

function Module:setSize(size: UDim2?)
	if not size then
		self.State.Arena.ActualSize = UDim2.fromScale(0.53, 0.4)
		return
	end

	self.State.Arena.ActualSize = size
end

function Module:setKind(kind: "2D" | "1D")
	self.State.Arena.Kind = kind
end

--== Lifecycle ==--
function Module:Initialize()
	self.GUI = GUI:Clone()
	self.GUI.Parent = PlayerGui

	self.Character = self.GUI.Canvas.Contents.Character
	self.Actions   = self.GUI.Canvas.Contents.Actions
	self.Status    = self.GUI.Canvas.Contents.Status
	self.Arena     = self.GUI.Canvas.Contents.Arena

	self.AspectRatio = Instance.new("UIAspectRatioConstraint")
	self.AspectRatio.Parent = script

	self.Status.User.Text = Player.Name

	self.State.Arena.BaselineMin = self.Arena.Contents.AbsoluteSize.X
	self.State.Arena.Size        = self.Arena.Contents.AbsoluteSize
	
	self.Trove:Connect(self.Arena.Contents:GetPropertyChangedSignal("AbsoluteSize"), function()
		self.State.Arena.BaselineMin = self.Arena.Contents.AbsoluteSize.X
		self.State.Arena.Size        = self.Arena.Contents.AbsoluteSize
	end)
	
	local scale = Helper.unitScale(self.Arena.Contents, self.State.Arena.BaselineMin)
	self.GUI.Canvas.Heart.Size          = Helper.scaleUDim2(UDim2.fromOffset(16, 16), scale)
	self.Arena.Contents.Controller.Size = Helper.scaleUDim2(UDim2.fromOffset(16, 16), scale)
	
	for _, sprite in ipairs(SPRITES:GetDescendants()) do
		if not sprite:IsA("ImageLabel") or sprite:GetAttribute("keepSize") then
			continue
		end		
		if not sprite:GetAttribute("Size") then
			sprite:SetAttribute("Size", sprite.Size)
		end

		sprite.Size = Helper.scaleUDim2(sprite:GetAttribute("Size"), scale)
	end

	_playSound("Start")
	self:_setupViewport()
	self:_setupIntro()
end

function Module:Stop(reason: string?)
	if self._Stopped then return end
	self._Stopped = true
	
	Helper.stopLocalSounds()

	if self.Sequencer then
		self.Sequencer:Stop()
	end

	TweenService:Create(self.GUI.Canvas.Contents,    TWEENS.FADE, { GroupTransparency = 1 }):Play()
	TweenService:Create(self.GUI.Canvas.Decorations, TWEENS.FADE, { GroupTransparency = 1 }):Play()

	task.delay(TWEENS.FADE.Time, function()
		if Current == self then Current = nil end
		self:Destroy()
	end)
end

function Module.new()
	local self = setmetatable({
		Trove   = Trove.new(),
		Signals = {
			spawnSound = Signal.new(),
			onDamage   = Signal.new(),
			onShake    = Signal.new(),
		},
		UUID = HttpService:GenerateGUID(false),
	}, Module)

	local character = Player.Character
	local humanoid  = character and character:FindFirstChildOfClass("Humanoid") :: Humanoid?
	if not humanoid then
		self:Destroy()
		return
	end

	self.Humanoid = humanoid
	self.State = {
		Player = {
			Size = Vector2.new(),
			Pos  = Vector2.new(),
			Vel  = Vector2.new(),
			Req  = Vector2.new(),
			Accel = 0.12,
			Speed = 3,
			_Locked = false,
			_Tick   = 0,
			_Held   = {},
		},
		Arena = {
			ActualSize  = UDim2.fromScale(0.53, 0.4),
			BaselineMin = Vector2.new(),
			Size        = Vector2.new(),
			
			Kind  = "2D" :: "1D" | "2D",
			Ratio = nil,
		},
		Attacks = {} :: {[Instance]: Attack},
		Visuals = {} :: {[Instance]: Visual},
	}
	
	self.Aspect = {
		active    = false,
		disabling = false,
		t    = 0,
		dur  = 0.28,
		from = nil,
		to   = nil,
	}

	self:Initialize()

	local controller = self.Arena.Contents.Controller :: Frame
	self.Controller  = Controller.new(self.Trove, self.Signals, self.State, controller, self.GUI)
	self.Shake       = Shake.new(self.Trove, self.State, self.Arena)
	self.Sequencer   = Sequencer.new(self.Trove, self.Signals, self.State, self.Arena.Contents, self.GUI)

	self.Trove:Connect(RunService.PostSimulation, function(dt: number)
		if self._Stopped then
			return
		end
		local dtFrame = Helper.toFrame(dt)

		self:Step(dtFrame)
		self.Controller:Step(dtFrame)
		self.Shake:Step(dtFrame)

		Knifes.Step(dtFrame)
		Flower.Step(dtFrame)
		Sweep.Step(dtFrame)
		Bits.Step(dtFrame)
		Gray.Step(dtFrame)
	end)
	
	self.Trove:Connect(self.Signals.onDamage, function(value: number)
		self.Humanoid.Health = math.clamp(self.Humanoid.Health - value, 1, self.Humanoid.MaxHealth)
		self.Shake:Shake({ amp = 12, freq = 10, duration = 0.2, falloff = "cubic" })
		network.minigameInput.send({ action = "Damage", value = value })
		if self.Humanoid.Health <= 1 then
			self:_breakNow()
			task.delay(BREAK_DELAY, function()
				if self.Stop and not self._Stopped then
					self:Stop("fail")
				end
			end)
		end
	end)

	self.Trove:Connect(self.Signals.onShake, function(params)
		self.Shake:Shake(params)
	end)
	self.Trove:Connect(self.Signals.spawnSound, _playSound)
	self.Trove:Add(self.Signals.spawnSound)
	self.Trove:Add(self.Signals.onDamage)
	self.Trove:Add(self.Signals.onShake)
	self.Trove:Add(self.GUI)

	self.Sequencer
		:setBetween(0.45, 0.55)
		:AddEntry({
			id   = "Pattern.A",
			time = 2.40,
			run  = function()
				self:setRatio(1)
				self:setKind("2D")
				self:setSize(UDim2.fromScale(0.4, 0.3))
				
				local sides = { "Right", "Left" }
				self.Sequencer:Defer(0.2, function()
					for _ = 1, 5 do
						if not self.Sequencer:_sleep(0.30) then break end
						Sweep.newSweep(self.Signals, self.State, self.Arena.Contents, "Horizontal", {
							fromGui   = self.Arena.Contents,
							targetPos = self.State.Player.Pos
						})
					end
				end)
				
				for _ = 1, 12 do
					if not self.Sequencer:_sleep(0.20) then break end
					Knifes.new(self.Signals, self.State, self.Arena.Contents, "Normal", {
						fromGui   = self.Arena.Contents,
						spawnSide = sides[ri(1, 2)]
					})
				end
			end
		})
		:AddEntry({
			id   = "Pattern.A",
			time = 2.40,
			run  = function()
				self:setRatio()
				self:setKind("2D")
				self:setSize()
				
				self.Sequencer:Defer(0.20, function()
					for _ = 1, 3 do
						if not self.Sequencer:_sleep(0.60) then break end
						Knifes.new(self.Signals, self.State, self.Arena.Contents, "Normal", {
							fromGui   = self.Arena.Contents,
							indicated = true
						})
					end
				end)
				
				for _ = 1, 12 do
					if not self.Sequencer:_sleep(0.20) then break end
					Knifes.new(self.Signals, self.State, self.Arena.Contents, "Normal", {
						fromGui   = self.Arena.Contents,
						targetPos = self.State.Player.Pos
					})
				end
			end
		})
		:AddEntry({
			id   = "Pattern.B",
			time = 2.00,
			run  = function()
				self:setRatio()
				self:setKind("2D")
				self:setSize()
				
				local orientation = { "Horizontal", "Vertical", "Both" }
				local centers = Helper.gridCenters(self.Arena.Contents, 3, 3, 12)
				for _, p in ipairs(centers) do
					if not self.Sequencer:_sleep(0.15) then break end
					Sweep.newSweep(self.Signals, self.State, self.Arena.Contents, orientation[ri(1, 3)], {
						fromGui   = self.Arena.Contents,
						targetPos = p,
					})
				end
			end
		})
		:AddEntry({
			id   = "Pattern.B",
			time = 2.70,
			run  = function()
				self:setRatio()
				self:setKind("2D")
				self:setSize()

				local centers = Helper.gridCenters(self.Arena.Contents, 4, 5, 12)
				for _, p in ipairs(centers) do
					Sweep.newSweep(self.Signals, self.State, self.Arena.Contents, "Both", {
						fromGui   = self.Arena.Contents,
						targetPos = p,
						telegraph = 1.90,
						expand    = 0.22,
						shrink    = 0.30,
						thickness = 12,
						flashRate = 9,
						damage    = 6,
						slash     = 2,
					})
				end
				
				self.Sequencer:Defer(0.95, function()
					for _ = 1, 6 do
						if not self.Sequencer:_sleep(0.15) then break end
						Knifes.new(self.Signals, self.State, self.Arena.Contents, "StillPunish", {
							fromGui   = self.Arena.Contents,
							targetPos = self.State.Player.Pos
						})
					end
				end)
			end
		})
		:AddEntry({
			id   = "Pattern.B",
			time = 2.90,
			run  = function()
				self:setRatio(1)
				self:setKind("2D")
				self:setSize()
				
				Sweep.newSpin(self.Signals, self.State, self.Arena.Contents, {
					fromGui = self.Arena.Contents
				})
				self.Sequencer:Defer(0.5, function()
					for _ = 1, 12 do
						if not self.Sequencer:_sleep(0.15) then break end
						Knifes.new(self.Signals, self.State, self.Arena.Contents, "MovePunish", {
							fromGui = self.Arena.Contents
						})
					end
				end)
			end
		})
		:AddEntry({
			id   = "Pattern.B",
			time = 3.0,
			run  = function()
				self:setRatio()
				self:setKind("1D")
				self:setSize(UDim2.fromScale(0.4, 0.3))

				for _ = 1, 12 do
					if not self.Sequencer:_sleep(0.20) then break end
					Sweep.newSweep(self.Signals, self.State, self.Arena.Contents, "Vertical", {
						targetPos = self.State.Player.Pos,
						thickness = 24,
					})
				end
			end
		})
		:AddEntry({
			id   = "Flowers.A",
			time = 1.1,
			run  = function()
				self:setRatio()
				self:setKind("2D")
				self:setSize()
				
				for _ = 1, 3 do
					if not self.Sequencer:_sleep(0.30) then break end
					Flower.new(self.Signals, self.State, self.Arena.Contents, {
						fromGui   = self.Arena.Contents,
						targetPos = self.State.Player.Pos,
						spawnSide = "Top"
					})
				end
			end
		})
		:AddEntry({
			id   = "Flowers.B",
			time = 0.15,
			run  = function()
				Flower.new(self.Signals, self.State, self.Arena.Contents, {
					fromGui   = self.Arena.Contents,
					targetPos = self.State.Player.Pos,
					spawnSide = "Top"
				})
			end
		})
		:AddEntry({
			id   = "Hearts.A",
			time = 1,
			run  = function()
				self:setRatio()
				self:setKind("2D")
				self:setSize()
				
				for _ = 1, 3 do
					if not self.Sequencer:_sleep(0.30) then break end
					Gray.new(self.Signals, self.State, self.Arena.Contents, {
						fromGui = self.Arena.Contents
					})
				end
			end
		})
		:AddEntry({
			id   = "Hearts.B",
			time = 0.15,
			run  = function()
				Gray.new(self.Signals, self.State, self.Arena.Contents, {
					fromGui = self.Arena.Contents
				})
			end
		})

	self.Sequencer:Start()

	return self
end

function Module:Step(dtFrame: number)
	local step = Helper.easeOutCubic(1 - math.exp(-1 * dtFrame))
	self:_stepAspect(dtFrame)

	local player = self.State.Player
	local arena  = self.State.Arena

	local current: UDim2 = self.Arena.Size
	local target:  UDim2
	if arena.Kind == "2D" then
		target = arena.ActualSize
	else
		target = UDim2.new(arena.ActualSize.X.Scale, 0, 0, player.Size.Y * 1.75)
	end
	self.Arena.Size = current:Lerp(target, step)

	local health     = self.Humanoid.Health
	local maxHealth  = self.Humanoid.MaxHealth
	local fill       = self.Status.Health.Contents.Fill
	local targetFill = math.clamp(health / maxHealth, 0, 1)
	fill.Size        = fill.Size:Lerp(UDim2.fromScale(targetFill, 1), step)
end

function Module:Destroy()
	self.Trove:Destroy()
	if self.GUI then self.GUI:Destroy() end
	table.clear(self)
	setmetatable(self, nil)
end

--== Hooks ==--
network.minigame.listen(function(data)
	local action, payload = data.action, data.payload
	if action == "Start" then
		if Current and not Current._Stopped then
			return
		end
		Current = Module.new()
	elseif action == "Stop" then
		if not Current then return end
		if payload and payload.reason == "fail" then
			Current:_breakNow()
			task.delay(BREAK_DELAY, function()
				if Current then Current:Stop("fail") end
			end)
		else
			Current:Stop(payload and payload.reason or "server")
		end
	end
end)

--== Return ==--
return Module