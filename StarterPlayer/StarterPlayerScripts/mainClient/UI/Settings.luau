local Players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")

----------------------------------------------------------------------------------


local network = require( replicatedStorage.modules.network )

local Job = require( replicatedStorage.modules.shared.Utilities.Job )
local EventService = require( replicatedStorage.modules.shared.Utilities.EventService )

local Icon = require( replicatedStorage.packages.Icon )

local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local AenoirUtil = require( replicatedStorage.modules.shared.Utilities.Utility.AenoirUtil )

local SettingUpdate = require( script.SettingUpdate )
local CustomMoveOrders = require( script.CustomMoveOrders )

local UserInterfaceAnimations = require( replicatedStorage.modules.shared.Utilities.UserInterfaceAnimations )

local Whitelist = require( replicatedStorage.modules.shared.Game.Whitelist )

local Maid = require( replicatedStorage.packages.Maid )
local Stylus = require( replicatedStorage.packages.Stylus )


local LocalPlayer = Players.LocalPlayer

--local function ConvertStringToCode(Name : string)
--	return Enum.KeyCode:FromName(Name) or Enum.UserInputType:FromName(Name)
--end

----------------------------------------------------------------------------------

local Settings = {}
Settings.__index = Settings

function Settings:Init()
	for Setting in SettingUpdate do
		if (self.LuaPlayer.Player:GetAttribute(Setting) ~= nil) then
			local Value : boolean = self.LuaPlayer.Player:GetAttribute(Setting)
			SettingUpdate[Setting](self.LuaPlayer, Value)
		end

		self.LuaPlayer.Player:GetAttributeChangedSignal(Setting):Connect(function()
			local Value : boolean = self.LuaPlayer.Player:GetAttribute(Setting)
			SettingUpdate[Setting](self.LuaPlayer, Value)
		end)
	end
	
	network.loadSettings.listen(function(Settings : {[string] : boolean})
		self.SettingsData = Settings

		--- Sent twice on purpose, from InitSettings and again on clientReady,
		--- because either can be the one that lands. The rows are built once.
		if self.Loaded then return end
		
		--self.DeviceKeybinds = DeviceKeybinds

		--for _, Platform in {"Controller", "Keyboard"} do
		--	if self.DeviceKeybinds[Platform] then
		--		for Move : string, KeyName : string in self.DeviceKeybinds[Platform] do
		--			self.DeviceKeybinds[Platform][Move] = ConvertStringToCode(KeyName)
		--		end
		--	end
		--end

		--print(	self.DeviceKeybinds)

		self.Loaded = true
		self.OnLoaded:Fire()

		-- Graphics
		self:CreatePercentageInSection("Graphics", "Camera Shake", "Intensity of Camera Shake")
		self:CreateToggleInSection("Graphics", "Epileptic Mode", "Disables Vignettes and other things")
		self:CreateToggleInSection("Graphics", "Blood", "Show Blood")
		self:CreateToggleInSection("Graphics", "Cutscenes", "Display Cutscene Animations")
		self:CreateToggleInSection("Graphics", "Dialogue", "Display Dialogue")
		self:CreateToggleInSection("Graphics", "Rain", "Display Rain Effect")
		self:CreateToggleInSection("Graphics", "Tile Destruction", "Could Cause Lag On Some Devices")
		self:CreateToggleInSection("Graphics", "Tile Split Geometry", "Could Cause Lag On Some Devices")
		self:CreateToggleInSection("Graphics", "Foliage Wind", "Show Leaf Movement")
		self:CreateToggleInSection("Graphics", "Evasive Highlight", "Highlights Evasive IFrames")
		self:CreateToggleInSection("Graphics", "Hit IFrame Effect", "Shows IFrames When Hit")
		self:CreateToggleInSection("Graphics", "Accessories", "Shows Accessories When Enabled")
		self:CreateToggleInSection("Graphics", "Voxel Interpolation", "Enables the Tweening of Voxelized Debris")
		self:CreateToggleInSection("Graphics", "HUD Sway", "HUD Leans With The Camera")
		
		-- Audio
		self:CreatePercentageInSection("Audio", "Sound Effects", "Volume of SFX")
		self:CreatePercentageInSection("Audio", "Environment", "Volume of Environment (Rain, Waterfall, Wind)")
		self:CreatePercentageInSection("Audio", "Ultimate Music", "Volume of Ultimate Music")
		self:CreatePercentageInSection("Audio", "Emotes", "Volume of Player Emotes")
		self:CreatePercentageInSection("Audio", "Kill Sounds", "Volume Of Kill Sounds")
		self:CreatePercentageInSection("Audio", "UI", "Volume Of UI Elements")

		-- Gameplay
		self:CreateStringInSection("Gameplay", "Kill Sound")
		--self:CreateToggleInSection("Gameplay", "M1 Hitbox Compensate", "Scales on your velocity")
		--self:CreateToggleInSection("Gameplay", "Dash Hitbox Compensate", "Scales on your velocity")
		--self:CreatePercentageInSection("Gameplay", "Show Hitboxes", "Controller Only")
		self:CreatePercentageInSection("Gameplay", "Gamepad Sensitivity", "Controller Only")
		self:CreateToggleInSection("Gameplay", "Auto Use", "Auto Use Of Moves")
		self:CreateToggleInSection("Gameplay", "Head Tracking", "Camera Follows Head")
		self:CreateTitleEditorInSection("Gameplay")
		
		if Whitelist.is_permitted(LocalPlayer.UserId, "Gebura") then
			self:CreateToggleInSection("Gameplay", "Red Mist Avatar", "Set Character Appearance to The Mist")
		end
	end)
	
	-- First Time Joining Blood Warning
	network.bloodWarning.listen(function()
		local ScreenGui = script.Assets.BloodConfirmation:Clone()
		local Buttons = ScreenGui.Body.Body.Buttons
		ScreenGui.Parent = LocalPlayer.PlayerGui
		
		Stylus:tween_blur(15, "Confirm")
		local WarningMaid = Maid.new()
		
		local function Close()
			ScreenGui:Destroy()
			WarningMaid:clean()
			
			Stylus:tween_blur(0, "Confirm")
		end
		
		WarningMaid:add(Buttons.Confirm.MouseButton1Click:Connect(function()
			Close()
			
			if not LocalPlayer:GetAttribute("Blood") then
				network.toggleSetting.send({ setting = "Blood" })
				
				if self.Toggles.Blood then
					self.Toggles.Blood.Update(true)
				end
			end
		end))
		
		WarningMaid:add(Buttons.Deny.MouseButton1Click:Connect(function()
			Close()

			--if LocalPlayer:GetAttribute("Blood") == true then
			--	network.toggleSetting.send({ setting = "Blood" })
			--	self.Toggles["Blood"].Update(false)
			--end
		end))
	end)
	
	self.Icon = Icon.new()
		:setLeft()
		:setImage("8382597378")
		:oneClick()
		:setOrder(3)
		:bindEvent("selected", function()
			if self.UI.Icons then
				self.UI.Icons:CloseAllExcept(self.GUI)
			end

			self.GUI.Enabled = not self.GUI.Enabled
		end)
	
	self.GUI:GetPropertyChangedSignal("Enabled"):Connect(function()
		self.UI:Toggle(not self.GUI.Enabled, 0.5)
	end)

	self.Icon.name = "Settings"

	for _, ButtonFrame : Frame in ipairs(self.Categories:GetChildren()) do
		if not ButtonFrame:IsA("Frame") then continue end

		local Button : ImageButton = ButtonFrame.Button
		Button:AddTag("UI_ButtonClickYJump")

		Button.MouseButton1Click:Connect(function()
			task.spawn(function()
				for _, ButtonFrame2 : Frame in ipairs(self.Categories:GetChildren()) do
					if ButtonFrame2:IsA("Frame") then
						local Button2 : ImageButton = ButtonFrame2.Button
						Button2.Icon.UnselectedColor.Enabled = (ButtonFrame ~= ButtonFrame2)
						Button2.Title.UnselectedColor.Enabled = (ButtonFrame ~= ButtonFrame2)
					end
				end
			end)

			for _, Option : ScrollingFrame in ipairs(self.Options:GetChildren()) do
				if Option:IsA("ScrollingFrame") then
					Option.Visible = false
				end
			end

			--if ButtonFrame.Name == "Keybinds" then
			--	self:LoadCharacterMoveKeybinds()
			--end

			self.Options[ButtonFrame.Name].Visible = true
		end)
	end

	--self.Combat.OnDeviceChanged:Connect(function()
	--	local Device : string = self.Combat.CurrentDevice
	--	local DeviceKeybinds = self.DeviceKeybinds[Device]

	--	print("from device changed in settings:", Device, DeviceKeybinds)

	--	if DeviceKeybinds then
	--		for Move, Table in self.Keybinds do
	--			local SavedKey = DeviceKeybinds[Move]

	--			if SavedKey then
	--				if typeof(SavedKey) == "string" then
	--					local Code : (Enum.KeyCode | Enum.UserInputType) = ConvertStringToCode(SavedKey)

	--					if Code then
	--						Table.AssignText(Code)
	--					end

	--				elseif (typeof(SavedKey) == "EnumItem") then
	--					Table.AssignText(SavedKey)
	--				end
	--			else
	--				if Table.Data and Table.Data.Key then
	--					Table.AssignText(Table.Data.Key)
	--				end
	--			end
	--		end
	--	end
	--end)

	--self.LuaPlayer.Replication.Attributes:GetAttributeChangedSignal("CurrentCharacter"):Connect(function()
	--	task.wait()

	--	self:UnloadCharacterMoveKeybinds()
	--	self:LoadCharacterMoveKeybinds()
	--end)
end

--function Settings:UnloadCharacterMoveKeybinds()
--	if not self.CharacterKeybindsUILoaded then return end

--	for Name, Table in self.Keybinds do
--		if Table.CharacterMove then
--			self.Keybinds[Name] = nil
--			Table.GUI:Destroy()
--		end
--	end

--	self.CharacterKeybindsUILoaded = false
--end

--function Settings:LoadCharacterMoveKeybinds()
--	if self.CharacterKeybindsUILoaded then return end

--	for Move : string, Data : {} in self.Combat.Attacks do
--		if Move == "WallJump" or Move == "Vault" then continue end

--		self:CreateKeybind(Move, Data, true)
--	end

--	self.CharacterKeybindsUILoaded = true
--end

--function Settings:CreateKeybind(Move : string, Data : {Key : (Enum.KeyCode | Enum.UserInputType)}, CharacterMove : boolean)
--	local NewFrame : Frame = self.Templates.Keybind:Clone()
--	local KeyLetterName = Utility.GetNumberFromNumberKey(Data.Key)

--	if KeyLetterName then
--		NewFrame.LayoutOrder = KeyLetterName
--	else
--		NewFrame.LayoutOrder = table.find(CustomMoveOrders, Data.Key.Name) or 0
--	end

--	NewFrame.Title.Text = Move

--	if Data.Description then
--		NewFrame.Description.Text = Data.Description
--	end

--	local KeyName = tostring(KeyLetterName) or Data.Key.Name
--	local SelectedKeybind : ImageButton = NewFrame.Button.SelectedKeybind
--	SelectedKeybind:AddTag("UI_ButtonClick")

--	local function AssignText(Key : (Enum.KeyCode | Enum.UserInputType))
--		local Name

--		local Number = Utility.GetNumberFromNumberKey(Key)

--		if (Number ~= nil and Number >= 0 and Number <= 9) then
--			Name = Number

--		elseif Key == Enum.UserInputType.MouseButton1 then
--			Name = "M1"

--		elseif Key == Enum.UserInputType.MouseButton2 then
--			Name = "M2"
--		else
--			Name = string.upper(Key.Name)
--		end

--		if self.Combat.UsingController then
--			if Utility.KeyboardToControllerInputs[Key] then
--				SelectedKeybind.Key.Button.Text = Utility.KeyboardToControllerInputs[Key].Name
--			else
--				SelectedKeybind.Key.Button.Text = Name
--			end
--		else
--			SelectedKeybind.Key.Button.Text = Name
--		end
--	end

--	local function SwitchKeyIfController(Key  : (Enum.KeyCode | Enum.UserInputType))
--		if (string.find(Key.Name, "Button") or string.find(Key.Name, "Dpad")) and Utility.ControllerToKeyboardInputs[Key] then
--			return Utility.ControllerToKeyboardInputs[Key]
--		end

--		return Key
--	end

--	local function UpdateAndSave(Key : (Enum.KeyCode | Enum.UserInputType))
--		AssignText(Key)
--		UserInterfaceAnimations.Click(SelectedKeybind, 1.1)

--		--print("old key:", Key)
--		Key = SwitchKeyIfController(Key)
--		--print("new key:", Key)

--		local Device : string = self.Combat.CurrentDevice

--		if self.DeviceKeybinds[Device] then
--			self.DeviceKeybinds[Device][Move] = Key.Name
--			self.OnKeybindUpdated:Fire(Move, Key)

--			SettingsRemotes.Keybind:FireServer(Move, Key, Device)
--		else
--			StarterGui:SetCore("SendNotification", {
--				Title = "Notification",
--				Text = "Error while trying to set a keybind: Your current device doesn't have a keybind table.",
--				Duration = 3,
--			})
--		end
--	end

--	local function Fail()
--		if self.Combat.UsingController then
--			local Key = ConvertStringToCode(KeyName)
			
--			if Key and Utility.KeyboardToControllerInputs[Key] then -- check dms rq
--				SelectedKeybind.Key.Button.Text = Utility.KeyboardToControllerInputs[Key].Name
--			else
--				SelectedKeybind.Key.Button.Text = KeyName
--			end
--		else
--			SelectedKeybind.Key.Button.Text = KeyName
--		end
--	end

--	local Device : string = self.Combat.CurrentDevice
--	local DeviceKeybinds = self.DeviceKeybinds[Device]

--	if (Device ~= "" and DeviceKeybinds) then
--		local Keybind = DeviceKeybinds[Move]

--		if Keybind then
--			if typeof(Keybind) == "string" then
--				local Code : (Enum.KeyCode | Enum.UserInputType) = ConvertStringToCode(Keybind)

--				if Code then
--					AssignText(Code)
--				else
--					Fail()
--				end

--			elseif typeof(Keybind) == "EnumItem" then
--				AssignText(Keybind)
--			end
--		else
--			Fail()
--		end
--	else
--		Fail()
--	end

--	SelectedKeybind.MouseButton1Click:Connect(function()
--		local ListenConnection : RBXScriptConnection

--		ListenConnection = UserInputService.InputBegan:Connect(function(Input)
--			ListenConnection:Disconnect()

--			if Input.KeyCode ~= Enum.KeyCode.Escape then
--				UpdateAndSave(if Input.KeyCode == Enum.KeyCode.Unknown then Input.UserInputType else Input.KeyCode)
--			else
--				SelectedKeybind.Key.Button.Text = KeyName
--			end
--		end)

--		SelectedKeybind.Key.Button.Text = "Press Any Key"
--	end)

--	NewFrame.Parent = self.Options.Keybinds

--	self.Keybinds[Move] = {
--		Data = Data,
--		GUI = NewFrame,
--		CharacterMove = CharacterMove,
--		Update = UpdateAndSave,
--		AssignText = AssignText
--	}
--end

function Settings:CreateToggleInSection(SectionName : string, Text : string, Description : string)
	local NewToggle : Frame = self.Templates.Toggle:Clone()
	NewToggle.Title.Text = Text

	if Description then
		NewToggle.Description.Text = Description
	end

	local Toggle : ImageButton = NewToggle.Button.Toggle
	Toggle:AddTag("UI_ButtonClick")

	local function Update(Value : boolean)
		NewToggle:SetAttribute("Toggled", Value)
		Toggle.Disabled.Visible = not Value
		Toggle.Enabled.Visible = Value
	end

	local ConvertedText = Text:gsub(" ", "_")

	if (self.SettingsData[ConvertedText] ~= nil) then
		Update(self.SettingsData[ConvertedText])
	end

	Toggle.MouseButton1Click:Connect(function()
		Update(not NewToggle:GetAttribute("Toggled"))
		network.toggleSetting.send({ setting = Text })
	end)

	NewToggle.Parent = self.Options[SectionName]

	self.Toggles[Text] = {
		GUI = NewToggle,
		Update = function(Value : boolean)
			Update(Value)
		end,
	}
end

function Settings:CreatePercentageInSection(SectionName : string, Text : string, Description : string)
	local NewFrame : Frame = self.Templates.Percentage:Clone()
	NewFrame.Title.Text = Text

	if Description then
		NewFrame.Description.Text = Description
	end

	local Percent : Frame = NewFrame.Button.Percent
	local Back : ImageButton = Percent.Back
	local Next : ImageButton = Percent.Next

	local Max = 200

	local function SetPercentage(Percentage : number)
		Percentage = tonumber(Percentage)
		Percentage = Percentage or 0

		if (Percentage < 0) then
			Percentage = Max

		elseif (Percentage > Max) then
			Percentage = 0
		end

		Percentage = math.clamp(Percentage, 0, Max)
		NewFrame:SetAttribute("Percentage", Percentage)

		return Percentage
	end

	local function Update(Percentage : number)
		local NewPercentage = SetPercentage(Percentage)

		Percent.Display.TextBox.Text = tostring(NewPercentage)
		network.sliderSetting.send({ setting = Text, value = NewPercentage })
	end

	local ConvertedText = Text:gsub(" ", "_")

	if (self.SettingsData[ConvertedText] ~= nil) then
		local NewPercentage = SetPercentage(self.SettingsData[ConvertedText])
		Percent.Display.TextBox.Text = tostring(NewPercentage)
	end

	Next.MouseButton1Click:Connect(function()
		Update( (NewFrame:GetAttribute("Percentage") or 0) + 10 )
	end)

	Back.MouseButton1Click:Connect(function()
		Update( (NewFrame:GetAttribute("Percentage") or 0) - 10 )
	end)

	Percent.Display.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		local TextValue = tonumber(Percent.Display.TextBox.Text)

		if Percent.Display.TextBox.Text ~= "" and TextValue ~= NewFrame:GetAttribute("Percentage") then
			Update(TextValue)
		end
	end)

	NewFrame.Parent = self.Options[SectionName]

	self.Percentages[Text] = {
		GUI = NewFrame,
		Update = function(Value : boolean)
			Update(Value)
		end,
	}
end

function Settings:CreateStringInSection(SectionName : string, Text : string)
	local NewFrame : Frame = self.Templates.String:Clone()
	NewFrame.Title.Text = Text
	
	local TextBox : TextBox = NewFrame.Button.Display.TextBox
	
	local function Update(String : string)
		if Text == "Kill Sound" then
			local Asset = AenoirUtil.get_asset_id(String)
			
			if Asset then
				Asset = tostring(Asset)
				
				network.stringSetting.send({ setting = Text, value = Asset })
				TextBox.Text = Asset
			else
				StarterGui:SetCore("SendNotification", {
					Title = "Notification",
					Text = "Not a valid ID, needs to be numbers .",
					Duration = 3,
					Button1 = "nah imma do my own thing .",
				})

				TextBox.Text = ""
			end
		else
			if String ~= "" then
				network.stringSetting.send({ setting = Text, value = String })
				TextBox.Text = String
			end
		end
	end

	TextBox.FocusLost:Connect(function()
		Update(TextBox.Text)
	end)
	
	local ConvertedText = Text:gsub(" ", "_")
	
	if (self.SettingsData[ConvertedText] ~= nil) then
		local Asset = AenoirUtil.get_asset_id(self.SettingsData[ConvertedText])
		
		if Asset then
			TextBox.Text = tostring(Asset)
		end
	end

	NewFrame.Parent = self.Options[SectionName]

	self.Strings[Text] = {
		GUI = NewFrame,
		Update = function(String : string)
			Update(String)
		end,
	}
end

function Settings:CreateTitleEditorInSection(SectionName : string)
	local NewEditor : Frame = self.Templates.EquippedTitle:Clone()

	local Toggle : ImageButton = NewEditor.Button.Selection.Edit
	Toggle:AddTag("UI_ButtonClick")

	local function Update(Value : boolean)
		NewEditor:SetAttribute("Toggled", Value)
		NewEditor.Button.Selection.Edit.SelectedVisual.Visible = Value
	end

	Toggle.MouseButton1Click:Connect(function()
		local NewValue = not NewEditor:GetAttribute("Toggled")
		Update(NewValue)
		self.Holder.TitleEditor.Visible = NewValue
	end)

	NewEditor.Parent = self.Options[SectionName]
end

-----------------------------------------------

function Settings.new(UI)
	local self = setmetatable({}, Settings)

	self.UI = UI
	self.Combat = UI.Combat
	self.LuaPlayer = UI.LuaPlayer

	self.GUI = self.LuaPlayer.PlayerGui:WaitForChild("Settings")
	self.Holder = self.GUI:WaitForChild("Holder")
	self.Templates = self.Holder:WaitForChild("Templates")
	self.Categories = self.Holder:WaitForChild("Categories")
	self.Options = self.Holder:WaitForChild("Options")

	self.SettingsData = {}
	--self.DeviceKeybinds = {}

	--self.OnKeybindUpdated = EventService.new()

	self.OnLoaded = EventService.new()
	self.Loaded = false

	--self.CharacterKeybindsUILoaded = false

	self.Sections = {}
	self.Toggles = {}
	self.Percentages = {}
	--self.Keybinds = {}
	self.Strings = {}

	self:Init()

	return self
end

table.freeze(Settings)

return Settings