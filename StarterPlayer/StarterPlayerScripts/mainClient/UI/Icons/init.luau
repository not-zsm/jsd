local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Icons = {}
Icons.__index = Icons

function Icons:_Init() 
	self.ShopIcon = self.IconModule.new()
		:setLeft()
		:setImage("9405933217")
		:setLabel("Shop")
		:setCaption("Opens the shop")
		:setOrder(1)
		:oneClick()
		:bindEvent("selected", function()
			local Client = self.UI.MainClient
			if not Client then return end

			self:CloseAllExcept(nil, true)
			SoundService.GUI.BasicOpen:Play()
			Client:Shop("main shop")
		end)

	self.CharacterIcon = require(script.Characters)()

	self.InformationIcon = self.IconModule.new()
		:setLeft()
		:setImage("13858288308")
		:setOrder(4)

		:bindEvent("selected", function()
			SoundService.GUI.BasicOpen:Play()
		end)
		:bindEvent("deselected", function()
			SoundService.GUI.BasicOpen:Play()
		end)

		:setDropdown({
			self.IconModule.new()
			:setOrder(1)
			:setLabel("General Info")
			:modifyTheme({
				{"IconGlow", "Visible", true, "Deselected"},
			})

			:bindEvent("selected", function()
				self:CloseAllExcept(self.UI.InformationGUI)
				self.UI.InformationGUI.Enabled = not self.UI.InformationGUI.Enabled

				SoundService.GUI.BasicOpen:Play()
			end)

			:oneClick(),

			self.IconModule.new()
			:setOrder(2)
			:setLabel("Character Info")
			:modifyTheme({
				{"IconGlow", "Visible", true, "Deselected"},
			})

			:bindEvent("selected", function()
				self:CloseAllExcept(self.UI.CharacterInformationGUI)

				local CharacterName = self.LuaPlayer.Replication.Attributes:GetAttribute("CurrentCharacter")

				local Found = false
				for _, UI in pairs(self.UI.CharacterInformationGUI:GetChildren()) do
					if UI.Name == CharacterName then
						Found = true
						UI.Visible = true
					else
						UI.Visible = false
					end
				end

				if not Found then
					self.UI.CharacterInformationGUI.None.Visible = true
				end

				self.UI.CharacterInformationGUI.Enabled = not self.UI.CharacterInformationGUI.Enabled

				SoundService.GUI.BasicOpen:Play()
			end)

			:oneClick()

		})

	task.spawn(function()
		self.GiftingHandler = require( script.Parent.GamepassGiftingHandler ).new(self.UI.GiftingGUI)
	end)

	self.GiftingIcon = self.IconModule.new()
		:setLeft()
		:setImage("13867996075")
		:oneClick()
		:setOrder(5)
		:bindEvent("selected", function()
			self:CloseAllExcept(self.UI.GiftingGUI)
			self.UI.GiftingGUI.Enabled = not self.UI.GiftingGUI.Enabled
		end)

	task.spawn(function()
		self.CommandManager = require( replicatedStorage.modules.shared.CommandManager ).new(self.UI)

		local Resize = require( replicatedStorage.modules.shared.Utilities.GUIResize )

		local OpenedBefore = false

		local function Setup()
			local NewPermission = self.LuaPlayer.Player:GetAttribute("PanelPermission")

			if NewPermission and NewPermission ~= "None" then
				self.OpenCommands = self.IconModule.new()
					:setLeft()
					:setImage(14906357487)
					:oneClick()
					:bindToggleKey(Enum.KeyCode.N)
					:setOrder(6)
					:bindEvent("selected", function()
						self:CloseAllExcept(self.CommandManager.GUI)
						self.CommandManager.GUI.Enabled = not self.CommandManager.GUI.Enabled
						SoundService.GUI.BasicOpen:Play()

						if (not OpenedBefore and not self.Combat.UsingTouch) then
							OpenedBefore = true
							Resize.new(self.CommandManager.GUI.Holder)
						end
					end)
			end

			task.defer(function()
				self.CommandManager:SetupCommands()
			end)
		end

		if (self.LuaPlayer.Player:GetAttribute("PanelPermission") == nil) then
			self.LuaPlayer.Player:GetAttributeChangedSignal("PanelPermission"):Once(Setup)
		else
			Setup()
		end
	end)


	-----------

	self.UI.GiftingGUI:GetPropertyChangedSignal("Enabled"):Connect(function()
		self.UI:Toggle(not self.UI.GiftingGUI.Enabled, 0.5)
	end)

	self.UI.InformationGUI:GetPropertyChangedSignal("Enabled"):Connect(function()
		self.UI:Toggle(not self.UI.InformationGUI.Enabled, 0.5)
	end)

	self.UI.CharacterInformationGUI:GetPropertyChangedSignal("Enabled"):Connect(function()
		self.UI:Toggle(not self.UI.CharacterInformationGUI.Enabled, 0.5)
	end)
end

--[[
	Closes every menu but one.

	The older menus are ScreenGuis that toggle Enabled; the ported ones are built
	on demand into mainClient's container. Both kinds have to shut, or opening
	settings leaves the shop sitting on top of it.

	KeepContainer is for the container menus themselves -- they close each other
	through createContainer, and clearing it here would eat their toggle.
--]]
function Icons:CloseAllExcept(ToNotClose : Instance?, KeepContainer : boolean?)
	local UI_Module = self.UI

	local Elements = {
		UI_Module.Emotes.GUI, 
		UI_Module.Settings.GUI, 
		UI_Module.GiftingGUI, 
		UI_Module.InformationGUI,
		UI_Module.CharacterInformationGUI
	}

	for _, GUI in Elements do
		if GUI ~= ToNotClose then
			GUI.Enabled = false
		end
	end

	local Client = UI_Module.MainClient

	if Client and not KeepContainer then
		Client:CloseMenus()
	end
end

function Icons.new(UI)
	local self = setmetatable({}, Icons)

	self.UI = UI
	self.Combat = UI.Combat
	self.LuaPlayer = UI.LuaPlayer

	self.IconModule = require( replicatedStorage.packages.Icon )
	task.delay(1, self._Init, self)

	return self
end;

table.freeze(Icons);

return Icons;