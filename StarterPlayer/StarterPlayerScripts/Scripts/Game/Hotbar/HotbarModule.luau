local HotbarModule = {}
HotbarModule.__index = HotbarModule

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Player
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local KEYBINDS = {"J", "K", "L"}

-- Utility
local function GetHumanoid()
	local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	return Character:FindFirstChildOfClass("Humanoid")
end

local function IsOwnedByPlayer(Tool)
	local Character = LocalPlayer.Character
	local Backpack = LocalPlayer:FindFirstChild("Backpack")
	if not Tool or not Tool.Parent then return false end
	return (Character and Tool:IsDescendantOf(Character)) or (Backpack and Tool:IsDescendantOf(Backpack))
end

local function GetStroke(Button)
	return Button and Button:FindFirstChild("SelectedStroke")
end

-- Constructor
function HotbarModule.new(HotbarGui)
	local self = setmetatable({}, HotbarModule)

	self.HotbarGui = HotbarGui
	self.Template = HotbarGui.Templates.ToolButton
	self.Holder = HotbarGui.Holder

	self.Tools = {}
	self.ToolIndexByObject = {}

	self.SelectedSlot = nil

	UserInputService.InputBegan:Connect(function(Input, GameProcessed)
		if GameProcessed then return end
		if Input.UserInputType == Enum.UserInputType.Keyboard then
			local Key = Input.KeyCode.Name
			local Slot = table.find(KEYBINDS, Key)
			if Slot then
				if self.Tools[Slot] then
					self:SelectTool(Slot)
				else
					self:UnequipTool()
				end
			end
		end
	end)

	LocalPlayer.CharacterAdded:Connect(function(Character)
		self:BindCharacter(Character)
	end)
	if LocalPlayer.Character then
		self:BindCharacter(LocalPlayer.Character)
	end

	return self
end

function HotbarModule:BindCharacter(Character)
	Character.ChildAdded:Connect(function(Child)
		if Child:IsA("Tool") then
			if not self.ToolIndexByObject[Child] then
				self:AddTool(Child)
			end
		end
	end)
end

function HotbarModule:UpdateSelectionVisuals()
	for Slot, Entry in ipairs(self.Tools) do
		local Stroke = GetStroke(Entry.Button)
		if Stroke then
			if Stroke:IsA("UIStroke") then
				Stroke.Enabled = (self.SelectedSlot == Slot)
			else
				Stroke.Visible = (self.SelectedSlot == Slot)
			end
		end
	end
end

function HotbarModule:AddTool(Tool)
	local Slot
	for I = 1, math.max(#self.Tools + 1, #KEYBINDS) do
		if self.Tools[I] == nil then
			Slot = I
			break
		end
	end
	if not Slot then Slot = #self.Tools + 1 end

	local Button = self.Template:Clone()
	Button.Name = Tool.Name
	Button.LayoutOrder = Slot
	Button.Parent = self.Holder
	Button.Visible = true

	local ImageLabel = Button:FindFirstChild("Image")
	if ImageLabel and Tool.TextureId and Tool.TextureId ~= "" then
		ImageLabel.Image = Tool.TextureId
	end

	local KeyLabel = Button:FindFirstChild("Key")
	if KeyLabel then
		KeyLabel.Text = KEYBINDS[Slot] or ""
	end

	local ToolObject = Button:FindFirstChild("ToolObject")
	if ToolObject then ToolObject.Value = Tool end

	local Entry = {
		Object = Tool,
		Button = Button,
		Key = KEYBINDS[Slot],
		Connections = {},
		AncestryConn = nil,
	}

	self.Tools[Slot] = Entry
	self.ToolIndexByObject[Tool] = Slot

	table.insert(Entry.Connections, Button.MouseButton1Click:Connect(function()
		self:SelectTool(Slot)
	end))

	table.insert(Entry.Connections, Tool.Equipped:Connect(function()
		local S = self.ToolIndexByObject[Tool]
		if S then
			self.SelectedSlot = S
			self:UpdateSelectionVisuals()
		end
	end))
	table.insert(Entry.Connections, Tool.Unequipped:Connect(function()
		if self.SelectedSlot and self.Tools[self.SelectedSlot] and self.Tools[self.SelectedSlot].Object == Tool then
			self.SelectedSlot = nil
			self:UpdateSelectionVisuals()
		end
	end))

	Entry.AncestryConn = Tool.AncestryChanged:Connect(function()
		if not IsOwnedByPlayer(Tool) then
			self:RemoveTool(Tool)
		end
	end)

	-- If already equipped when added, reflect selection
	if Tool:IsDescendantOf(LocalPlayer.Character) then
		self.SelectedSlot = Slot
		self:UpdateSelectionVisuals()
	else
		self:UpdateSelectionVisuals()
	end

	return Slot
end

-- Remove a tool
function HotbarModule:RemoveTool(Tool)
	local Slot = self.ToolIndexByObject[Tool]
	local Entry = Slot and self.Tools[Slot]
	if not Entry then return end

	if Entry.AncestryConn then Entry.AncestryConn:Disconnect() end
	for _, Conn in ipairs(Entry.Connections) do
		if Conn and Conn.Disconnect then Conn:Disconnect() end
	end
	if Entry.Button then Entry.Button:Destroy() end

	self.Tools[Slot] = nil
	self.ToolIndexByObject[Tool] = nil

	if self.SelectedSlot == Slot then
		self.SelectedSlot = nil
	end

	self:CompactSlots()
	self:UpdateSelectionVisuals()
end

function HotbarModule:CompactSlots()
	local New = {}
	for I = 1, #self.Tools + 3 do
		local E = self.Tools[I]
		if E then table.insert(New, E) end
	end
	self.Tools = New
	-- Re-map indices and labels
	for I, E in ipairs(self.Tools) do
		self.ToolIndexByObject[E.Object] = I
		E.Key = KEYBINDS[I]
		E.Button.LayoutOrder = I
		local KeyLabel = E.Button:FindFirstChild("Key")
		if KeyLabel then KeyLabel.Text = KEYBINDS[I] or "" end
	end
end

-- Select by slot (toggle behavior)
function HotbarModule:SelectTool(Slot)
	local Character = LocalPlayer.Character
	if Character and Character:GetAttribute("FreezeHotbar") == true then
		return
	end

	local Entry = self.Tools[Slot]
	if not Entry then return end

	if self.SelectedSlot == Slot then
		self:UnequipTool()
		return
	end

	self.SelectedSlot = Slot

	local Humanoid = GetHumanoid()
	if Humanoid then
		Humanoid:EquipTool(Entry.Object)
	end

	self:UpdateSelectionVisuals()
end


-- Unequip currently selected tool (if any)
function HotbarModule:UnequipTool()
	local Character = LocalPlayer.Character
	if Character and Character:GetAttribute("FreezeHotbar") == true then
		return
	end

	local Humanoid = GetHumanoid()
	if Humanoid then
		Humanoid:UnequipTools()
	end
	self.SelectedSlot = nil
	self:UpdateSelectionVisuals()
end

-- Load initial tools
function HotbarModule:LoadTools()
	-- Clear old
	for _, Entry in ipairs(self.Tools) do
		if Entry.AncestryConn then Entry.AncestryConn:Disconnect() end
		for _, Conn in ipairs(Entry.Connections) do
			if Conn and Conn.Disconnect then Conn:Disconnect() end
		end
		if Entry.Button then Entry.Button:Destroy() end
	end
	self.Tools = {}
	self.ToolIndexByObject = {}
	self.SelectedSlot = nil

	local Backpack = LocalPlayer:WaitForChild("Backpack")

	local Slot = 1
	for _, Tool in ipairs(Backpack:GetChildren()) do
		if Tool:IsA("Tool") then
			self:AddTool(Tool)
			Slot += 1
		end
	end
	local Character = LocalPlayer.Character
	if Character then
		for _, Tool in ipairs(Character:GetChildren()) do
			if Tool:IsA("Tool") and not self.ToolIndexByObject[Tool] then
				self:AddTool(Tool)
				Slot += 1
			end
		end
	end

	-- Backpack additions
	Backpack.ChildAdded:Connect(function(Tool)
		if Tool:IsA("Tool") and not self.ToolIndexByObject[Tool] then
			self:AddTool(Tool)
		end
	end)
end

return HotbarModule
