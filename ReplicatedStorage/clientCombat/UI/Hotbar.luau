local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )
local EventService = require( ReplicatedStorage.Shared.Utilities.EventService )
local Job = require( ReplicatedStorage.Shared.Utilities.Job )
local HotbarData = require( script.Parent.HotbarData )

local LocalPlayer = Players.LocalPlayer

local FLASH = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local SLIDE = TweenInfo.new(0.5, Enum.EasingStyle.Cubic)
local USE = TweenInfo.new(0.25)

local CONTROLLER_NAMES = {
	[Enum.KeyCode.ButtonA] = "A",
	[Enum.KeyCode.ButtonY] = "Y",
	[Enum.KeyCode.ButtonB] = "B",
	[Enum.KeyCode.ButtonX] = "X",
	[Enum.KeyCode.ButtonL1] = "L1",
	[Enum.KeyCode.ButtonL2] = "L2",
	[Enum.KeyCode.ButtonR1] = "R1",
	[Enum.KeyCode.ButtonR2] = "R2",
	[Enum.KeyCode.DPadRight] = "DPad-R",
	[Enum.KeyCode.DPadUp] = "DPad-U",
	[Enum.KeyCode.DPadLeft] = "DPad-L",
}

local Hotbar = {}
Hotbar.__index = Hotbar

----------------------------------------------------------------------------------

local function keyText(key, order: number, usingController: boolean): string
	if usingController and Utility.KeyboardToControllerInputs[key] then
		local name = CONTROLLER_NAMES[Utility.KeyboardToControllerInputs[key]]
		if name then
			return name
		end
	end

	if key == Enum.UserInputType.MouseButton1 then
		return "M1"
	elseif key == Enum.UserInputType.MouseButton2 then
		return "M2"
	end

	return (order > 0 and order <= 9) and tostring(order) or key.Name
end

----------------------------------------------------------------------------------

function Hotbar.new(UI)
	local self = setmetatable({}, Hotbar)

	self.UI = UI
	self.Combat = UI.Combat
	self.Slots = {}

	local GUI: ScreenGui = script.hotbar:Clone()
	GUI.Name = "Hotbar"
	GUI.Parent = UI.PlayerGui

	self.GUI = GUI
	self.Template = GUI:WaitForChild("Base")
	self.Holder = GUI:WaitForChild("backpack"):WaitForChild("holder")
	self.UltBar = GUI:WaitForChild("ultBar")
	self.ExtraCooldowns = GUI:WaitForChild("extraCD")

	self.Template.Parent = script          -- keep the template out of the layout
	self.HolderPosition = self.Holder.Position
	self.UltPosition = self.UltBar.Position

	return self
end

----------------------------------------------------------------------------------

function Hotbar:Get(Name: string)
	return self.Slots[Name]
end

function Hotbar:Add(Name: string, Key)
	if typeof(Key) ~= "EnumItem" then return end

	local Order = Key.Value - 48
	local Slot = self.Slots[Name]

	if Slot then
		Slot.Key, Slot.Order = Key, Order
		Slot.Root.LayoutOrder = Order
		Slot.Root.Name = Name
		Slot.Name.Text = Name

		self:RefreshKey(Name)
		self:ApplyTip(Name)
		return
	end

	local Root = self.Template:Clone()
	local Inner = Root:WaitForChild("Base")

	Slot = {
		Root = Root,
		Inner = Inner,
		Name = Inner:WaitForChild("ToolName"),
		Number = Inner:WaitForChild("Number"),
		Tip = Inner:WaitForChild("Reuse"),
		Stroke = Inner:FindFirstChildWhichIsA("UIStroke"),
		Cooldown = Root:WaitForChild("Cooldown"),
		Flash = Root:WaitForChild("Flash"),

		-- jjk's template has no countdown text or overlay; both are wired only
		-- if you add them to hotbar.Base in Studio
		CooldownValue = Root:FindFirstChild("CooldownValue"),
		Overlay = Root:FindFirstChild("Overlay"),

		Key = Key,
		Order = Order,
		Shown = true,
		RemoveCooldown = EventService.new(),
		Job = Job.new(),
	}

	self.Slots[Name] = Slot

	Root.Name = Name
	Root.LayoutOrder = Order
	Root.Visible = true
	Slot.Name.Text = Name
	Slot.Tip.Visible = false
	Slot.Cooldown.Visible = false
	Slot.Flash.Visible = false

	if Slot.Overlay then
		Slot.Overlay.Visible = false
	end
	if Slot.CooldownValue then
		Slot.CooldownValue.Visible = false
	end

	self:RefreshKey(Name)
	self:ApplyTip(Name)

	Root.Parent = self.Holder

	Slot.Job:Task(Inner.MouseButton1Click:Connect(function()
		self.Combat:_AttackInputUpdate(Name)
	end))

	return Slot
end

function Hotbar:Remove(Name: string)
	local Slot = self.Slots[Name]
	if not Slot then return end

	self.Slots[Name] = nil
	Slot.Job:Destroy()
	Slot.Root:Destroy()
end

----------------------------------------------------------------------------------

function Hotbar:RefreshKey(Name: string)
	local Slot = self.Slots[Name]
	if not Slot then return end

	Slot.Number.Text = keyText(Slot.Key, Slot.Order, self.Combat.UsingController)
end

function Hotbar:RefreshKeys()
	for Name in self.Slots do
		self:RefreshKey(Name)
	end
end

function Hotbar:ApplyTip(Name: string)
	local Slot = self.Slots[Name]
	local Data = HotbarData[Name]
	if not (Slot and Data and Data.OnAdded) then return end

	Data.OnAdded(Slot)
end

function Hotbar:SetDisplay(Name: string, Text: string, Tip: string?, FlashColor: Color3?)
	local Slot = self.Slots[Name]
	if not Slot then return end

	Slot.Name.Text = Text

	if Tip then
		Slot.Tip.Text = Tip
		Slot.Tip.Visible = Tip ~= ""
	elseif Text == Name then
		self:ApplyTip(Name)
	else
		Slot.Tip.Visible = false
	end

	if not (FlashColor and Slot.Root.Parent) then return end

	Slot.Name.TextColor3 = FlashColor
	TweenService:Create(Slot.Name, FLASH, { TextColor3 = Color3.new(1, 1, 1) }):Play()

	if not Slot.Stroke then return end

	Slot.Stroke.Color = FlashColor
	Slot.Stroke.Transparency = 0
	Slot.Stroke.Enabled = true

	local Tween = TweenService:Create(Slot.Stroke, FLASH, { Transparency = 1 })
	Tween:Play()

	Tween.Completed:Once(function(State)
		if State == Enum.PlaybackState.Completed and Slot.Root.Parent then
			Slot.Stroke.Enabled = false
		end
	end)
end

----------------------------------------------------------------------------------

function Hotbar:AddCooldown(Name: string, Duration: number)
	local Slot = self.Slots[Name]
	if not Slot then return end

	local Timing = Instance.new("NumberValue")
	Timing.Value = 1

	Slot.Cooldown.Visible = true
	Slot.Cooldown.Size = UDim2.fromScale(1, 1)

	if Slot.CooldownValue then
		Slot.CooldownValue.Text = tostring(Duration)
		Slot.CooldownValue.Visible = true
	end

	Timing.Changed:Connect(function(Value)
		if not Slot.Root.Parent then return end

		Slot.Cooldown.Size = UDim2.fromScale(1, Value)

		if Slot.CooldownValue then
			Slot.CooldownValue.Text = tostring(math.round(Value * Duration))
		end
	end)

	TweenService:Create(Timing, TweenInfo.new(Duration, Enum.EasingStyle.Linear), { Value = 0 }):Play()

	Slot.RemoveCooldown:Once(function()
		Timing:Destroy()

		Slot.Cooldown.Visible = false

		if Slot.CooldownValue then
			Slot.CooldownValue.Visible = false
		end
	end)
end

function Hotbar:RemoveCooldown(Name: string)
	local Slot = self.Slots[Name]
	if not Slot then return end

	Slot.RemoveCooldown:Fire()
end

function Hotbar:Use(Name: string, CustomColor: Color3?)
	local Slot = self.Slots[Name]
	if not Slot then return end

	local Flash = Slot.Flash
	local Resting = Flash:GetAttribute("StartTransparency") or 0.2

	if CustomColor then
		Flash.BackgroundColor3 = CustomColor
	end

	Flash.BackgroundTransparency = Resting
	Flash.Visible = true

	local Tween = TweenService:Create(Flash, USE, { BackgroundTransparency = 1 })
	Tween:Play()

	Tween.Completed:Once(function(State)
		if State == Enum.PlaybackState.Completed and Slot.Root.Parent then
			Flash.Visible = false
		end
	end)
end

function Hotbar:SetOverlay(Name: string, Value: boolean?)
	local Slot = self.Slots[Name]
	if not (Slot and Slot.Overlay) then return end

	if Value ~= nil then
		Slot.Overlay.Visible = Value
	else
		Slot.Overlay.Visible = not Slot.Overlay.Visible
	end
end

-- The holder's UIListLayout reflows on its own, so hiding is just Visible.
function Hotbar:SetSlotShown(Name: string, Shown: boolean)
	local Slot = self.Slots[Name]
	if not Slot or Slot.Shown == Shown then return end

	Slot.Shown = Shown

	if Shown then
		Slot.Root.Visible = true
		Slot.Inner.Position = UDim2.fromScale(0.5, 2)
		TweenService:Create(Slot.Inner, SLIDE, { Position = UDim2.fromScale(0.5, 0.5) }):Play()
		return
	end

	local Tween = TweenService:Create(Slot.Inner, SLIDE, { Position = UDim2.fromScale(0.5, 2) })

	Tween.Completed:Once(function(State)
		if State == Enum.PlaybackState.Completed and not Slot.Shown then
			Slot.Root.Visible = false
		end
	end)

	Tween:Play()
end

----------------------------------------------------------------------------------

function Hotbar:SetHidden(Hidden: boolean, Time: number?)
	local Info = TweenInfo.new(Time or 1.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local Drop = Hidden and 0.3 or 0

	for _, Frame in { { self.Holder, self.HolderPosition }, { self.UltBar, self.UltPosition } } do
		local Target, Origin = Frame[1], Frame[2]

		TweenService:Create(Target, Info, {
			Position = UDim2.new(Origin.X.Scale, Origin.X.Offset, Origin.Y.Scale + Drop, Origin.Y.Offset)
		}):Play()
	end
end

function Hotbar:SetUltVisible(Visible: boolean)
	self.UltBar.Visible = Visible
end

function Hotbar:SetUltName(Text: string)
	self.UltBar.TextLabel.Text = Text or "???"
end

function Hotbar:SetUltColor(Color)
	local Mask = self.UltBar.prog.progressContainer.mask

	if typeof(Color) == "ColorSequence" then
		Mask.ImageColor3 = Color.Keypoints[1].Value
		self.UltBar.prog.UIGradient.Color = Color
	elseif typeof(Color) == "Color3" then
		Mask.ImageColor3 = Color
	end
end

function Hotbar:SetUltProgress(Fraction: number, Instant: boolean?)
	local Size = UDim2.new(math.clamp(Fraction, 0, 1), 0, 1, 0)
	local Container = self.UltBar.prog.progressContainer

	if Instant then
		Container.Size = Size
		return
	end

	TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Size = Size
	}):Play()
end

function Hotbar:SetUltMax(IsMax: boolean, Key: string?)
	local Label = self.UltBar.TextLabel

	if not IsMax then
		return
	end

	if Key then
		Label.Text = `[{Key}] to Awaken`
	end
end

return Hotbar
