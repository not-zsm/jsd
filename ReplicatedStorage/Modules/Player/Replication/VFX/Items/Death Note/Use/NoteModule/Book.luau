--== Imports ==--
local Workspace = game:GetService("Workspace")
local Players   = game:GetService("Players")

local Camera = Workspace.CurrentCamera

local Page = require(script.Parent.Page)

--== Constants ==--
local ANIMS = script.Animations

local CENTER_POSITION = Vector3.new(-0.425, 0, -2)
local CENTER_ROTATION = CFrame.Angles(math.rad(90), math.rad(180), 0)

local SPAWN_POSITION = Vector3.new(-2, -4, 2)
local SPAWN_ROTATION = CFrame.Angles(0, 0, 0)

local PAGE_POSITION = Vector3.new(-0.125, 0, -2)
local PAGE_ROTATION = CFrame.Angles(math.rad(90), math.rad(180), 0)

local CENTER_CFRAME = CFrame.new(CENTER_POSITION) * CENTER_ROTATION
local SPAWN_CFRAME  = CFrame.new(SPAWN_POSITION)  * SPAWN_ROTATION
local PAGE_CFRAME   = CFrame.new(PAGE_POSITION)   * PAGE_ROTATION

local CAUSES = {
	["Heart Attack"] = "Heart Attack",
	["Lightning"] = "Lightning",
	["Assassination "] = "Assassination ",
	["Explosion"] = "Explosion",
}

--== Module ==--
local Module = {}
Module.__index = Module

--== Private ==--
function Module:_Update(deltaTime: number)
	local book, target = self.Book, self.CFrame.Target

	self.CFrame.Current = self.CFrame.Current:Lerp(target, deltaTime * 0.15)
	book:PivotTo(Camera.CFrame:ToWorldSpace(self.CFrame.Current))

	if not self.Page and self.Active then
		local visible = (self.CFrame.Current.Position - target.Position).Magnitude <= 0.05
		if visible ~= self.Visible then
			self:SetVisible(visible)
		end
	end

	if self.Page then
		self.Pages[self.Page]:_Update(deltaTime)
	end
end

--== Public ==--
function Module:SetPage(value: string) 
	self.Page = value

	for index, animations in self.Animations do
		if index ~= value then
			animations.Loop:Stop(0.15)
			animations.Open:Stop(0.15)
		else
			animations.Loop:Play(0.15)
			animations.Open:Play(0.15)
		end
	end

	local active = self.Active
	if active then
		if self.Page then
			self.CFrame.Target = PAGE_CFRAME
		else
			self.CFrame.Target = CENTER_CFRAME
		end
	else
		self.CFrame.Target = SPAWN_CFRAME
	end

	if value == "Player" then
		local data = {}
		for _, player in Players:GetPlayers() do
			data[player] = player.Name
		end

		self.Pages.Player:SetList(data)
	elseif value == "Cause" then
		self.Pages.Cause:SetList(CAUSES)
	end
end

function Module:SetActive(value: boolean)
	self.Active = value

	if value then
		if self.Page then
			self.CFrame.Target = PAGE_CFRAME
		else
			self.CFrame.Target = CENTER_CFRAME
		end
	else
		self.Visible = false
		self:SetPage(nil)

		self.CFrame.Target = SPAWN_CFRAME
	end
end

function Module:SetVisible(value: boolean)
	self.Visible = value

	if value then
		self:SetPage("Player")
	else
		self:SetPage(nil)
	end
end

--== Lifecycle ==--
function Module.new(signals, trove)
	local self = setmetatable({
		Book = script.Model:Clone(),

		Signals = signals,
		Trove   = trove
	}, Module)

	self.Book.Parent = Camera
	self.Book:PivotTo(CFrame.new(0, -100, 0))

	self.Active  = false
	self.Visible = false

	self.Values = {
		Player = nil,
		Cause = nil,
	}

	self.Page  = nil
	self.Pages = {
		Player = Page.new(signals, trove, self.Book.PageLeft, "CHOOSE A VICTIM"),
		Cause  = Page.new(signals, trove, self.Book.PageRight, "CAUSE OF DEATH")
	}

	self.Animator   = self.Book.AnimationController.Animator
	self.Animations = {
		Player = {
			Loop = self.Animator:LoadAnimation(ANIMS["Page 1 Loop"]),
			Open = self.Animator:LoadAnimation(ANIMS["Page 1"])
		},
		Cause = {
			Loop = self.Animator:LoadAnimation(ANIMS["Page 2 Loop"]),
			Open = self.Animator:LoadAnimation(ANIMS["Page 2"])
		}
	}

	self.Trove:Connect(self.Signals.onActivated, function()
		if self.Page == "Player" then
			self.Values.Player = self.Pages.Player.List.Active
			
			self:SetPage("Cause")
		elseif self.Page == "Cause" then
			self.Values.Cause = self.Pages.Cause.List.Active
			
			self.Signals.onCompleted:Fire(self.Values)
			self:SetActive(false)
		end
	end)

	self.CFrame = {
		Target  = SPAWN_CFRAME,
		Current = SPAWN_CFRAME
	}

	return self
end

function Module:Destroy()
	self.Book:Destroy()

	table.clear(self)
	setmetatable(self, nil)
end

--== Return ==--
return Module