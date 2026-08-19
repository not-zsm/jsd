--== Imports ==--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = script.Parent.Packages
local Trove    = require(Packages.Trove)

--== Constants ==--
local TEMPLATE = script.Button
local FRONT    = script.Front
local BACK     = script.Back

--== Module ==--
local Module = {}
Module.__index = Module

--== Private ==--
function Module:_Update(deltaTime: number)
	local write = self.Front.Contents.Write
	
	local background = write.Background.UIGradient :: UIGradient
	local text       = write.Text.UIGradient       :: UIGradient
	
	if self.Holding and self.List.Active then
		self.Progress = math.lerp(self.Progress, 100, deltaTime * 0.25)
	else
		self.Progress = math.lerp(self.Progress, 0, deltaTime * 0.5)
	end

	background.Offset = Vector2.new((self.Progress / 100), 0)
	text.Offset       = Vector2.new((self.Progress / 100), 0)

	if self.Progress >= 95 then
		self.Progress = 0
		self.Signals.onActivated:Fire()
	end
	
	for value, frame in self.List.Frames do
		local background = frame.Background.UIGradient :: UIGradient
		local text       = frame.Text.UIGradient       :: UIGradient
		
		if self.List.Active == value then
			background.Offset = background.Offset:Lerp(Vector2.new(1, 0), deltaTime * 0.5)
			text.Offset       = text.Offset:Lerp(Vector2.new(1, 0),       deltaTime * 0.5)
		else
			background.Offset = background.Offset:Lerp(Vector2.new(0, 0), deltaTime * 0.5)
			text.Offset       = text.Offset:Lerp(Vector2.new(0, 0),       deltaTime * 0.5)
		end
	end
end

--== Public ==--
function Module:SetList(data: {[any]: any})
	local scrolling = self.Front.Contents.List.Scrolling
	
	local trove = self.List.Trove
	trove:Clean()
	
	for _, frame in self.List.Frames do
		frame:Destroy()
	end
	
	for value, text in data do
		local clone   = TEMPLATE:Clone()
		local trigger = clone.Trigger
		
		clone.Name      = text
		clone.Text.Text = text

		clone.Parent  = scrolling
		clone.Visible = true
		
		self.List.Frames[value] = clone
		trove:Connect(trigger.Activated, function()
			if self.List.Active == value then
				self.List.Active = nil
			else
				self.List.Active = value
			end
		end)
	end
	
	self.List.Active = nil
	self.List.Data   = data
end

--== Lifecycle ==--
function Module.new(signals, trove, instance, title)
	local self = setmetatable({
		Instance = instance,

		Signals = signals,
		Trove   = trove,
	}, Module)

	self.List = {
		Active = nil,
		Trove  = Trove.new(),
		
		Frames = {} :: {[any]: Frame},
		Data   = {} :: {[any]: any},
	}
	
	self.Trove:Add(self.List.Trove)

	self.Front = FRONT:Clone()
	self.Front.Parent = self.Instance

	self.Back = BACK:Clone()
	self.Back.Parent = self.Instance

	local button = self.Front.Contents.Write.Trigger
	local text   = self.Front.Contents.Title.Text
	
	text.Text = title
	
	self.Trove:Connect(button.MouseButton1Down, function() self.Holding = true  end)
	self.Trove:Connect(button.MouseButton1Up,   function() self.Holding = false end)
	self.Trove:Connect(button.MouseLeave,       function() self.Holding = false end)

	self.Progress = 0
	self.Holding  = false

	return self
end

function Module:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

--== Return ==--
return Module