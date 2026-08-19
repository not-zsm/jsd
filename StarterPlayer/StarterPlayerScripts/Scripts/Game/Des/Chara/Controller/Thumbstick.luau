
--[[

=========================================================
=========================================================

					Module by @jlhklmn
		Credits are apprechiated but not required

		Please do not steal and re-publish my code
		Tutorial can be found on the devforum post

=========================================================
=========================================================

Forum Post Link: https://devforum.roblox.com/t/thumbstick-module-easy-mobile-touchscreen-joystick/3474175

]]

--// 
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local keyboardEnabled = false

--// 
type ThumbstickObject = {
	--// Events
	["Began"]: RBXScriptSignal,
	["Changed"]: RBXScriptSignal,
	["Ended"]: RBXScriptSignal,

	--// Methods
	["Enable"]: (self, any) -> RBXScriptConnection,
	["Disable"]: (self, any) -> RBXScriptConnection,

	--// Properties
	["InputObject"]: Enum.UserInputType,
	["Type"]: string,
	["IsDisabled"]: boolean,
	["StartPosition"]: UDim2
}

local module = {}

--// 
function getScreenGui()
	local ScreenGui = PlayerGui:FindFirstChild("ThumbstickGui")

	if not ScreenGui then
		ScreenGui = Instance.new("ScreenGui", PlayerGui)
		ScreenGui.Name = "ThumbstickGui"

		ScreenGui.ResetOnSpawn = false
		ScreenGui.DisplayOrder = 10000
		ScreenGui.ClipToDeviceSafeArea = false
	end

	return ScreenGui
end

function module.new(config: {})
	local showZone = false
	if not config then config = {} end

	--// Default Properties
	if not config.Position or typeof(config.Position) ~= "UDim2" then config.Position = UDim2.new(0.5, 0, 0.5, 0) end
	if not config.Size or typeof(config.Size) ~= "UDim2" then config.Size = UDim2.new(0, 55, 0, 55) end
	if not config.UiType or config.UiType ~= 1 then config.UiType = 0 end -- 0 = Hidden, 1 = Visible
	if not config.Theme or not tostring(config.Theme) or not script:FindFirstChild(config.Theme) then config.Theme = "Modern" end
	if not config.ImageId or not tonumber(config.ImageId) then config.ImageId = 109486912260101 end
	if not config.Deadzone or not tonumber(config.Deadzone) then config.Deadzone = 3.6 end

	config.ImageId = "rbxassetid://"..tostring(config.ImageId)

	if config.UiType == 0 and not config.TouchZone then
		config.TouchZone = {}
		config.TouchZone.Size = UDim2.new(0.35, 100, 0.4, 100)
		config.TouchZone.Position = UDim2.new(0.65, 0, 0, -100)
	end

	local self: ThumbstickObject = {}

	--// Cloning Ui Components
	local UiGroup = script:FindFirstChild(config.Theme):Clone()
	UiGroup.Parent = getScreenGui()

	UiGroup.TouchStart.ImageLabel.Image = config.ImageId
	UiGroup.TouchEnd.ImageLabel.Image = config.ImageId

	local pointDisplay = Instance.new("Folder", UiGroup)
	pointDisplay.Name = "PointDisplay"

	--// [[	Dragging Functionality	]]
	local zone = Instance.new("Frame", UiGroup)
	zone.Name = "DynamicThumbstickFrame"
	zone.Transparency = 1
	zone.Active = true
	zone.Interactable = true

	--// Set Size
	UiGroup.TouchStart.Size = config.Size + UDim2.new(0, 10, 0, 10)
	UiGroup.TouchEnd.Size = config.Size

	local point = UiGroup.Point
	point.Size = UDim2.new(0, UiGroup.TouchEnd.AbsoluteSize.X/6, 0, UiGroup.TouchEnd.AbsoluteSize.Y/6)
	point.Position = UDim2.new(2, 0, 2, 0)

	--// Component Transparencies
	local ts, te = UiGroup.TouchStart.BackgroundTransparency, UiGroup.TouchEnd.BackgroundTransparency
	local tss1, tes1 = UiGroup.TouchStart.Outline.UIStroke1.Transparency, UiGroup.TouchEnd.Outline.UIStroke1.Transparency
	local tss2, tes2 = UiGroup.TouchStart.Outline.UIStroke2.Transparency, UiGroup.TouchEnd.Outline.UIStroke2.Transparency
	local tsil, teil = UiGroup.TouchStart.ImageLabel.ImageTransparency, UiGroup.TouchEnd.ImageLabel.ImageTransparency

	UiGroup.TouchStart.BackgroundTransparency = 1
	UiGroup.TouchEnd.BackgroundTransparency = 1
	UiGroup.TouchStart.Outline.UIStroke1.Transparency = 1
	UiGroup.TouchStart.Outline.UIStroke2.Transparency = 1
	UiGroup.TouchEnd.Outline.UIStroke1.Transparency = 1
	UiGroup.TouchEnd.Outline.UIStroke2.Transparency = 1

	UiGroup.TouchStart.ImageLabel.ImageTransparency = 1
	UiGroup.TouchEnd.ImageLabel.ImageTransparency = 1

	--// Determine Ui Type
	if config.UiType == 0 then
		zone.Size = config.TouchZone.Size
		zone.Position = config.TouchZone.Position

		zone.BackgroundColor3 = Color3.new(0, 0, 0)
		zone.BackgroundTransparency = 0.8
	else
		showZone = true

		zone.Size = UiGroup.TouchStart.Size
		zone.Position = config.Position
		zone.AnchorPoint = Vector2.new(0.5, 0.5)

		UiGroup.TouchStart.Position = config.Position

		UiGroup.TouchStart.BackgroundTransparency = math.clamp(ts - 0.5, 0, 1)
		UiGroup.TouchStart.Outline.UIStroke1.Transparency = math.clamp(tss1 - 0.5, 0, 1)
		UiGroup.TouchStart.Outline.UIStroke2.Transparency = math.clamp(tss2 - 0.5, 0, 1)
		UiGroup.TouchStart.ImageLabel.ImageTransparency = tsil

		UiGroup.TouchStart.ImageLabel.Visible = true
	end

	UiGroup.TouchStart.Visible = true
	UiGroup.TouchEnd.Visible = true

	--// Properties
	local BeganEvent = Instance.new("BindableEvent")
	self.Began = BeganEvent.Event
	local ChangedEvent = Instance.new("BindableEvent")
	self.Changed = ChangedEvent.Event
	local EndedEvent = Instance.new("BindableEvent")
	self.Ended = EndedEvent.Event

	self.StartPosition = config.UiType == 1 and config.Position or nil
	self.IsDisabled = false
	self.InputObject = nil
	self.Type = config.UiType == 0 and "Hidden" or "Visible"

	--// Dragging Events
	local c1 = UserInputService.InputBegan:Connect(function(input, gpe)
		if UserInputService.KeyboardEnabled or self.IsDisabled then return end
		if self.InputObject or input.UserInputType ~= Enum.UserInputType.Touch then return end

		local x, y = input.Position.X, input.Position.Y
		local uis = PlayerGui:GetGuiObjectsAtPosition(x, y)
		local top = uis[1]
		if not top then return end
		if not (top == zone or top:IsDescendantOf(UiGroup)) then
			return
		end
		
		--// 
		self.StartPosition = config.UiType == 1 and config.Position or UDim2.new(0, x, 0, y)
		UiGroup.TouchStart.Position = self.StartPosition

		local distance = (Vector2.new(UiGroup.TouchStart.AbsolutePosition.X + UiGroup.TouchStart.AbsoluteSize.X * 0.5, UiGroup.TouchStart.AbsolutePosition.Y + UiGroup.TouchStart.AbsoluteSize.Y * 0.5) - Vector2.new(x, y)).Magnitude
		if distance <= 15 then x, y = UiGroup.TouchStart.AbsolutePosition.X + UiGroup.TouchStart.AbsoluteSize.X * 0.5, UiGroup.TouchStart.AbsolutePosition.Y + UiGroup.TouchStart.AbsoluteSize.Y * 0.5 end

		UiGroup.TouchEnd.Position = UDim2.new(0, x, 0, y)

		--// Tweening Components Fade In
		TweenService:Create(UiGroup.TouchStart, TweenInfo.new(0.1), {BackgroundTransparency = ts}):Play()
		TweenService:Create(UiGroup.TouchEnd, TweenInfo.new(0.1), {BackgroundTransparency = te}):Play()
		TweenService:Create(UiGroup.TouchStart.Outline.UIStroke1, TweenInfo.new(0.1), {Transparency = tss1}):Play()
		TweenService:Create(UiGroup.TouchStart.Outline.UIStroke2, TweenInfo.new(0.1), {Transparency = tss2}):Play()
		TweenService:Create(UiGroup.TouchEnd.Outline.UIStroke1,   TweenInfo.new(0.1), {Transparency = tes1}):Play()
		TweenService:Create(UiGroup.TouchEnd.Outline.UIStroke2,   TweenInfo.new(0.1), {Transparency = tes2}):Play()
		TweenService:Create(UiGroup.TouchStart.ImageLabel, TweenInfo.new(0.1), {ImageTransparency = 1}):Play()
		TweenService:Create(UiGroup.TouchEnd.ImageLabel, TweenInfo.new(0.1), {ImageTransparency = teil}):Play()

		self.InputObject = input
		BeganEvent:Fire()

		if not showZone then
			showZone = true

			zone.BackgroundTransparency = 1
			task.wait()
			TweenService:Create(zone, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.7}):Play()
			task.wait(0.4)
			TweenService:Create(zone, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
		end
	end)

	local c2 = UserInputService.InputChanged:Connect(function(input, gpe)
		if UserInputService.KeyboardEnabled or self.IsDisabled then return end
		if not self.InputObject or self.InputObject ~= input then return end

		local x, y = input.Position.X, input.Position.Y
		if math.abs(UiGroup.TouchStart.AbsolutePosition.X + UiGroup.TouchStart.AbsoluteSize.X * 0.5 - x) < 1 or math.abs(UiGroup.TouchStart.AbsolutePosition.Y + UiGroup.TouchStart.AbsoluteSize.Y * 0.5 - y) < 1 then return end

		--// Auto Snapping
		local difference = UDim2.new(0, UiGroup.TouchStart.AbsolutePosition.X + UiGroup.TouchStart.AbsoluteSize.X * 0.5, 0, UiGroup.TouchStart.AbsolutePosition.Y + UiGroup.TouchStart.AbsoluteSize.Y * 0.5) - UDim2.new(0, x, 0, y)
		difference = UDim2.new(0, -difference.X.Offset, 0, difference.Y.Offset)

		local distance = (Vector2.new(UiGroup.TouchStart.AbsolutePosition.X + UiGroup.TouchStart.AbsoluteSize.X * 0.5, UiGroup.TouchStart.AbsolutePosition.Y + UiGroup.TouchStart.AbsoluteSize.Y * 0.5) - Vector2.new(x, y)).Magnitude
		if distance <= 15 then x, y = UiGroup.TouchStart.AbsolutePosition.X + UiGroup.TouchStart.AbsoluteSize.X * 0.5, UiGroup.TouchStart.AbsolutePosition.Y + UiGroup.TouchStart.AbsoluteSize.Y * 0.5 end

		--// Deadzone Calculations
		local a = math.atan(math.abs(difference.X.Offset)/math.abs(difference.Y.Offset))
		local r = math.max(UiGroup.TouchStart.AbsoluteSize.X, UiGroup.TouchStart.AbsoluteSize.Y) * config.Deadzone * 0.5

		local corner = difference.X.Offset < 0 and difference.Y.Offset > 0 and 1 --// Top left
			or difference.X.Offset > 0 and difference.Y.Offset > 0 and 2 --// Top Right
			or difference.X.Offset < 0 and difference.Y.Offset < 0 and 3 --// Bottom Left
			or 4 --// Bottom Right

		if corner == 2 then a += math.rad(270) elseif corner == 1 then a += math.rad(180) a = math.rad(90)-a elseif corner == 3 then a += math.rad(90) else a = math.rad(90)-a end
		local maxX, maxY = (UiGroup.TouchStart.AbsolutePosition.X + UiGroup.TouchStart.AbsoluteSize.X * 0.5) + r * math.cos(a), (UiGroup.TouchStart.AbsolutePosition.Y + UiGroup.TouchStart.AbsoluteSize.Y * 0.5) + r * math.sin(a)

		if corner == 1 then
			if x < maxX then x = maxX end
			if y < maxY then y = maxY end
		elseif corner == 2 then
			if x > maxX then x = maxX end
			if y < maxY then y = maxY end
		elseif corner == 3 then
			if x < maxX then x = maxX end
			if y > maxY then y = maxY end
		else
			if x > maxX then x = maxX end
			if y > maxY then y = maxY end
		end

		maxX -= UiGroup.TouchEnd.AbsoluteSize.X * 0.5
		maxY -= UiGroup.TouchEnd.AbsoluteSize.Y * 0.5

		UiGroup.TouchEnd.Position = UDim2.new(0, x, 0, y)

		--// Point Displaying
		local difference = UDim2.new(0, UiGroup.TouchStart.AbsolutePosition.X + UiGroup.TouchStart.AbsoluteSize.X * 0.5, 0, UiGroup.TouchStart.AbsolutePosition.Y + UiGroup.TouchStart.AbsoluteSize.Y * 0.5) -
			UDim2.new(0, UiGroup.TouchEnd.AbsolutePosition.X + UiGroup.TouchEnd.AbsoluteSize.X * 0.5, 0, UiGroup.TouchEnd.AbsolutePosition.Y + UiGroup.TouchEnd.AbsoluteSize.Y * 0.5)
		difference = Vector2.new(-difference.X.Offset, difference.Y.Offset)

		local h = math.sqrt(math.abs(difference.X)^2 + math.abs(difference.Y)^2)
		local s = math.max(point.AbsoluteSize.X, point.AbsoluteSize.Y)
		local num = s * 1.8
		local i = math.floor(h/num)

		for _, v in pairs(pointDisplay:GetChildren()) do
			if tonumber(v.Name) > i then v:Destroy() end
		end

		for i = 1, i do
			if not pointDisplay:FindFirstChild(tostring(i)) then
				local point = point:Clone()
				point.Name = tostring(i)
				point.Parent = pointDisplay
			else
				local point = pointDisplay:FindFirstChild(tostring(i))
				local r = num * i
				local x, y = (UiGroup.TouchStart.AbsolutePosition.X + UiGroup.TouchStart.AbsoluteSize.X * 0.5) + r * math.cos(a), (UiGroup.TouchStart.AbsolutePosition.Y + UiGroup.TouchStart.AbsoluteSize.Y * 0.5) + r * math.sin(a)

				point.Position = UDim2.new(0, x, 0, y)
				point.Transparency = math.clamp(1 - (r/h), 0, 1)

				local a = (Vector2.new(UiGroup.TouchStart.AbsolutePosition.X + UiGroup.TouchStart.AbsoluteSize.X * 0.5, UiGroup.TouchStart.AbsolutePosition.Y + UiGroup.TouchStart.AbsoluteSize.Y * 0.5) -
					Vector2.new(x, y)).Magnitude

				local s = math.clamp((a/num) * s, s * 0.05, s * 4) * 0.25
				point.Size = UDim2.new(0, s, 0, s)
			end
		end

		--// 
		ChangedEvent:Fire(difference) --// Send signal for changed event with position differences
	end)

	local c3 = UserInputService.InputEnded:Connect(function(input, gpe)
		if UserInputService.KeyboardEnabled or self.IsDisabled then return end
		if not self.InputObject or self.InputObject ~= input then return end

		UiGroup.TouchEnd.Position = self.StartPosition
		pointDisplay:ClearAllChildren()

		--// Tweening Components Fade Out
		TweenService:Create(UiGroup.TouchStart, TweenInfo.new(0.1), {BackgroundTransparency = config.UiType == 0 and 1 or math.clamp(ts - 0.5, 0, 1)}):Play()
		TweenService:Create(UiGroup.TouchEnd, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
		TweenService:Create(UiGroup.TouchStart.Outline.UIStroke1, TweenInfo.new(0.1), {Transparency = config.UiType == 0 and 1 or math.clamp(tss1 - 0.5, 0, 1)}):Play()
		TweenService:Create(UiGroup.TouchStart.Outline.UIStroke2, TweenInfo.new(0.1), {Transparency = config.UiType == 0 and 1 or math.clamp(tss2 - 0.5, 0, 1)}):Play()
		TweenService:Create(UiGroup.TouchEnd.Outline.UIStroke1,   TweenInfo.new(0.1), {Transparency = 1}):Play()
		TweenService:Create(UiGroup.TouchEnd.Outline.UIStroke2,   TweenInfo.new(0.1), {Transparency = 1}):Play()
		TweenService:Create(UiGroup.TouchStart.ImageLabel, TweenInfo.new(0.1), {ImageTransparency = config.UiType == 0 and 1 or tsil}):Play()
		TweenService:Create(UiGroup.TouchEnd.ImageLabel, TweenInfo.new(0.1), {ImageTransparency = 1}):Play()

		--// 
		self.InputObject = nil
		EndedEvent:Fire()
	end)

	--// Object Methods
	function self:Enable()
		self.IsDisabled = false
		task.wait()

		TweenService:Create(UiGroup.TouchStart, TweenInfo.new(0.1), {BackgroundTransparency = config.UiType == 0 and 1 or math.clamp(ts - 0.5, 0, 1)}):Play()
		TweenService:Create(UiGroup.TouchEnd, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
		TweenService:Create(UiGroup.TouchStart.Outline.UIStroke1, TweenInfo.new(0.1), {Transparency = config.UiType == 0 and 1 or math.clamp(tss1 - 0.5, 0, 1)}):Play()
		TweenService:Create(UiGroup.TouchStart.Outline.UIStroke2, TweenInfo.new(0.1), {Transparency = config.UiType == 0 and 1 or math.clamp(tss2 - 0.5, 0, 1)}):Play()
		TweenService:Create(UiGroup.TouchEnd.Outline.UIStroke1,   TweenInfo.new(0.1), {Transparency = 1}):Play()
		TweenService:Create(UiGroup.TouchEnd.Outline.UIStroke2,   TweenInfo.new(0.1), {Transparency = 1}):Play()
		TweenService:Create(UiGroup.TouchStart.ImageLabel, TweenInfo.new(0.1), {ImageTransparency = config.UiType == 0 and 1 or tsil}):Play()
		TweenService:Create(UiGroup.TouchEnd.ImageLabel, TweenInfo.new(0.1), {ImageTransparency = 1}):Play()
	end

	function self:Disable()
		self.IsDisabled = true
		task.wait()

		TweenService:Create(UiGroup.TouchStart, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
		TweenService:Create(UiGroup.TouchEnd, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
		TweenService:Create(UiGroup.TouchStart.Outline.UIStroke1, TweenInfo.new(0.1), {Transparency = 1}):Play()
		TweenService:Create(UiGroup.TouchStart.Outline.UIStroke2, TweenInfo.new(0.1), {Transparency = 1}):Play()
		TweenService:Create(UiGroup.TouchEnd.Outline.UIStroke1,   TweenInfo.new(0.1), {Transparency = 1}):Play()
		TweenService:Create(UiGroup.TouchEnd.Outline.UIStroke2,   TweenInfo.new(0.1), {Transparency = 1}):Play()
		TweenService:Create(UiGroup.TouchStart.ImageLabel, TweenInfo.new(0.1), {ImageTransparency = 1}):Play()
		TweenService:Create(UiGroup.TouchEnd.ImageLabel, TweenInfo.new(0.1), {ImageTransparency = 1}):Play()

		if self.InputObject then
			EndedEvent:Fire()
		end

		self.InputObject = nil
	end

	local renderstepped
	renderstepped = RunService.RenderStepped:Connect(function()
		local s, _ = pcall(function()
			--// Dynamic Device Detection
			if UserInputService.KeyboardEnabled and not keyboardEnabled then
				self:Disable()
			elseif not UserInputService.KeyboardEnabled and keyboardEnabled then
				self:Enable()
			end

			keyboardEnabled = UserInputService.KeyboardEnabled
 
			for _, v in pairs(pointDisplay:GetChildren()) do
				if self.InputObject then v.Visible = true
				else v.Visible = false end
			end
		end)

		if not s then renderstepped:Disconnect() end
	end)

	local destroying
	destroying = UiGroup.Destroying:Connect(function()
		c1:Disconnect()
		c2:Disconnect()
		c3:Disconnect()

		renderstepped:Disconnect()
		destroying:Disconnect()
	end)

	return self
end

function module:ClearUis()
	getScreenGui():ClearAllChildren()
	return
end

return module