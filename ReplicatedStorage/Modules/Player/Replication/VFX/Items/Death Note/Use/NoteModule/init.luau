--== Imports ==--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = script.Packages
local Signal   = require(Packages.Signal)
local Trove    = require(Packages.Trove)

local Book = require(script.Book)

--== Module ==--
local Module = {}
Module.__index = Module

--== Public ==--
function Module:Show()
	self.Book:SetActive(true)
end

function Module:Hide()
	self.Book:SetActive(false)
end

--== Lifecycle ==--
function Module.new()
	local self = setmetatable({
		Signals = {
			onCompleted = Signal.new(),
			onActivated = Signal.new(),
		},
		Trove   = Trove.new()
	}, Module)

	self.Book = Book.new(self.Signals, self.Trove)
	self.Trove:Add(self.Book)
	
	self.Trove:Add(self.Signals.onCompleted)
	self.Trove:Add(self.Signals.onActivated)

	self.Trove:BindToRenderStep("DeathNote", Enum.RenderPriority.Camera.Value + 1, function(deltaTime: number)
		local scaledDelta = math.clamp(deltaTime * 60, 0, 0.06)
		self.Book:_Update(scaledDelta)
	end)

	self.Trove:Connect(self.Signals.onCompleted, function(values: {Player: Player?, Cause: string?})
		if not values.Player or not values.Cause then
			return
		end
		
		ReplicatedStorage.PlayerRemotes.Items["Death Note"].SelectTarget:FireServer(values.Player, values.Cause)
	end)

	return self
end

function Module:Destroy()
	self.Trove:Destroy()

	table.clear(self)
	setmetatable(self, nil)
end

--== Return ==--
return Module