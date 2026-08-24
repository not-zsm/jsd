local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Camera = Workspace.CurrentCamera
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Module = script
local Template = Module:WaitForChild("IndicatorTemplate")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IndicatorGui"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = -20
ScreenGui.Parent = PlayerGui

local Indicator = {}
Indicator.__index = Indicator

local ActiveIndicators = {}

--[[

<<-- CONFIG OPTIONS -->>
- !Attachment (Attachment Instance) : Attachment that the indicator is anchored to (Required)
- Color (Color3)                    : Color of the indicator
- IconColor (Color3)                : Color of the icon
- BorderColor (Color3)              : Color of the indicator's border
- Transparency (Number, 0-1)        : Transparency of the indicator
- Icon (rbxassetid)                 : Image of the indicator
- Size (Number)                     : Size of the indicator (1 is default)
- Visible (Bolean)                  : Indicator is visible when created
- TweenSpeed (Number)               : Transparency tween speed when indicator becomes visible/invisible, leave 0 to not tween at all

]]


function Indicator.new(Config)
	local self = setmetatable({}, Indicator)

	if not Config.Attachment or not Config.Attachment:IsA("Attachment") then
		warn("No valid attachment found, please make sure to include an attachment.")
		return
	end

	self.Attachment = Config.Attachment
	self.Color = Config.Color or Color3.new(0, 0, 0)
	self.IconColor = Config.IconColor or Color3.new(1, 1, 1)
	self.BorderColor = Config.BorderColor or self.IconColor
	self.Transparency = Config.Transparency or 0
	self.Image = Config.Icon or "rbxassetid://0"
	self.Size = UDim2.fromScale(0.04 * (Config.Size or 1), 0.04 * (Config.Size or 1))
	self.Visible = Config.Visible
	self.TweenSpeed = Config.TweenSpeed or 0.35

	if self.Visible == nil then
		self.Visible = true
	end

	local UI = Template:Clone()
	UI.Name = "Indicator"
	UI.Size = self.Size
	UI.Visible = false -- prevent flash before animation
	UI.Parent = ScreenGui

	local Icon = UI.ImageLabel
	if Icon then
		Icon.Image = self.Image
		Icon.ImageColor3 = self.IconColor
		Icon.BackgroundColor3 = self.Color
		Icon.UIStroke.Color = self.Color
		Icon.BorderFrame.UIStroke.Color = self.BorderColor
		Icon.ImageTransparency = self.Transparency
	end

	local Arrow = UI.Point
	if Arrow then
		Arrow.Visible = false
		Arrow.ImageLabel.ImageColor3 = self.Color
		Arrow.ImageLabel.ImageTransparency = self.Transparency
	end

	self.UI = UI
	self.Arrow = Arrow
	self.Destroyed = false

	table.insert(ActiveIndicators, self)

	if self.Visible then
		local Sound = Instance.new("Sound")
		Sound.Volume = 0.5
		Sound.SoundId = "rbxassetid://79894516715649"
		Sound.Parent = SoundService

		Sound:Play()
		task.delay(Sound.TimeLength + 1, Sound.Destroy, Sound)
		
		self:Show()
	end

	return self
end

function Indicator:Show()
	print("Shown Indicator")
	self.Visible = true
	Indicator:CheckIndicatorLoop()

	self.UI.Visible = true
	self.UI.Size = UDim2.fromScale(0, 0)

	self:UpdatePosition() -- pre-place the UI before tweening

	if self.TweenSpeed > 0 then
		local PopTween = TweenService:Create(
			self.UI,
			TweenInfo.new(self.TweenSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = self.Size}
		)
		PopTween:Play()
	else
		self.UI.Size = self.Size
	end
end

function Indicator:Hide()
	print("Hid Indicator")
	
	if self.TweenSpeed > 0 then
		local ShrinkTween = TweenService:Create(
			self.UI,
			TweenInfo.new(self.TweenSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{Size = UDim2.fromScale(0, 0)}
		)
		ShrinkTween:Play()
		ShrinkTween.Completed:Wait()
		self.UI.Visible = false
	else
		self.UI.Visible = false
	end

	self.Visible = false
	Indicator:CheckIndicatorLoop()
end

function Indicator:Destroy(NoTween: boolean)
	if not NoTween then
		self:Hide()
		task.wait(self.TweenSpeed)
	end

	self.Destroyed = true
	self.UI:Destroy()

	for i, obj in ipairs(ActiveIndicators) do
		if obj == self then
			table.remove(ActiveIndicators, i)
			break
		end
	end

	Indicator:CheckIndicatorLoop()
end

function Indicator:UpdatePosition()
	local ScreenWidth, ScreenHeight = Camera.ViewportSize.X, Camera.ViewportSize.Y
	local Padding = self.UI.AbsoluteSize.X
	local BoundX, BoundY = ScreenWidth - Padding * 2, ScreenHeight - Padding * 2
	local MaxRadius = math.sqrt((BoundX * 0.5) ^ 2 + (BoundY * 0.5) ^ 2)

	local CamPos = Camera.CFrame.Position
	local CamMatrix = Camera.CFrame
	local Attach = self.Attachment
	local WorldPos = Attach.WorldPosition
	local ViewPos, IsVisible = Camera:WorldToViewportPoint(WorldPos)

	local PosX = math.clamp(ViewPos.X, Padding, ScreenWidth - Padding)
	local PosY = math.clamp(ViewPos.Y, Padding, ScreenHeight - Padding)

	if IsVisible and ViewPos.X == PosX and ViewPos.Y == PosY then
		if self.Arrow then self.Arrow.Visible = false end
	else
		if self.Arrow then
			self.Arrow.Visible = true
			local Direction = WorldPos - CamPos
			local LocalDir = CamMatrix:VectorToObjectSpace(Direction)
			local Dir2D = Vector2.new(LocalDir.X, LocalDir.Y).Unit

			local AngleRad = math.atan2(Dir2D.X, Dir2D.Y)
			local EdgeProjection = Dir2D * MaxRadius

			local ScreenOffset
			if math.abs(EdgeProjection.Y) > BoundY * 0.5 then
				ScreenOffset = Dir2D * math.abs((BoundY * 0.5) / Dir2D.Y)
			else
				ScreenOffset = Dir2D * math.abs((BoundX * 0.5) / Dir2D.X)
			end

			PosX = ScreenWidth * 0.5 + ScreenOffset.X
			PosY = ScreenHeight * 0.5 - ScreenOffset.Y

			self.Arrow.Rotation = math.deg(AngleRad)
		end
	end

	self.UI.Position = UDim2.fromOffset(PosX, PosY)
end

local function Loop()
	for _, Entry in ipairs(ActiveIndicators) do
		if Entry.Destroyed or not Entry.Visible then continue end
		if Entry.Attachment and Entry.Attachment:IsDescendantOf(Workspace) then
			Entry:UpdatePosition()
		else
			Entry:Destroy()
		end
	end
end

Indicator._LoopConnection = RunService.RenderStepped:Connect(Loop)

function Indicator:CheckIndicatorLoop()
	if Indicator._LoopConnection and Indicator._LoopConnection.Connected then
		if #ActiveIndicators < 1 then
			Indicator._LoopConnection:Disconnect()
			return
		end

		local ContainsVisibleEntry
		for _, Entry in ipairs(ActiveIndicators) do
			if Entry.Visible then
				ContainsVisibleEntry = true
				break
			end
		end

		if not ContainsVisibleEntry then
			Indicator._LoopConnection:Disconnect()
			return
		end
	else
		if #ActiveIndicators > 0 then
			local ContainsVisibleEntry
			for _, Entry in ipairs(ActiveIndicators) do
				if Entry.Visible then
					ContainsVisibleEntry = true
					break
				end
			end

			if ContainsVisibleEntry then
				Indicator._LoopConnection = RunService.RenderStepped:Connect(Loop)
			end
		end
	end
end

return Indicator
