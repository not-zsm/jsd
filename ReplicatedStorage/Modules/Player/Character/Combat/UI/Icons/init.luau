local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VoiceChatService = game:GetService("VoiceChatService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Icons = {}
Icons.__index = Icons

local IsRankedPlace = workspace:GetAttribute("IsRankedPlace")

if IsRankedPlace == nil then
	workspace:GetAttributeChangedSignal("IsRankedPlace"):Wait()
	IsRankedPlace = workspace:GetAttribute("IsRankedPlace")
end 

function Icons:_Init() 
	-- in order

	if not workspace:GetAttribute("IsRankedLobby") then
		self.CharacterIcon = require(script.Characters)(self.LuaPlayer.Player)
	end

	if not IsRankedPlace and not workspace:GetAttribute("IsRankedLobby") then

		self.InformationIcon = self.IconModule.new()
			:setLeft()
			:setImage("13858288308")
			:setOrder(3)

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

		task.spawn(function()
			local Browser = require( ReplicatedStorage.ServerBrowser.Browser )

			self.BrowserIcon = self.IconModule.new()
				:setLeft()
				:setImage("14906353972")
				:setOrder(5)
				:bindEvent("selected", function()
					self:CloseAllExcept(Browser.UI)
					Browser:toggle(true)
				end)
				:bindEvent("deselected", function()
					Browser:toggle(false)
				end)
		end)

		self.GiftingIcon = self.IconModule.new()
			:setLeft()
			:setImage("13867996075")
			:oneClick()
			:setOrder(6)
			:bindEvent("selected", function()
				self:CloseAllExcept(self.UI.GiftingGUI)
				self.UI.GiftingGUI.Enabled = not self.UI.GiftingGUI.Enabled
			end)

		self.VCIcon = self.IconModule.new()
			:setLeft()
			:oneClick()
			:setOrder(7)
			:setImage("13868452862")
			:hideOnCondition(function()
				if workspace:GetAttribute("IsVCPlace") then
					return true
				end

				return not VoiceChatService:IsVoiceEnabledForUserIdAsync(self.LuaPlayer.Player.UserId)
			end)

			:bindEvent("selected", function()
				SoundService.GUI.BasicOpen:Play()
				require( script.JoinVCServer ):Join()
			end)

		if workspace:GetAttribute("IsTestPlace") then
			self.RankedIcon = self.IconModule.new()
				:setLeft()
				:oneClick()
				:setOrder(8)
				:setImage("84982423657682")

				:bindEvent("selected", function()
					SoundService.GUI.BasicOpen:Play()
					require( script.JoinRankedLobby ):Join()
				end)
		end

		task.spawn(function()
			if workspace:GetAttribute("IsRankedPlace") or workspace:GetAttribute("IsRankedLobby") then
				return
			end

			self.CommandManager = require( ReplicatedStorage.Modules.Shared.CommandManager ).new(self.UI)

			local Resize = require( ReplicatedStorage.Modules.Shared.Utilities.GUIResize )

			local OpenedBefore = false

			local function Setup()
				local NewPermission = self.LuaPlayer.Player:GetAttribute("PanelPermission")

				if NewPermission and NewPermission ~= "None" then
					self.OpenCommands = self.IconModule.new()
						:setLeft()
						:setImage(14906357487)
						:oneClick()
						:bindToggleKey(Enum.KeyCode.N)
						:setOrder(9)
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

		task.spawn(function()
			local BuildPersistent = require( ReplicatedStorage.BuildTools.Build )

			BuildPersistent.OnDelete:Connect(function()
				if self.BuildIcon then
					self.BuildIcon:destroy()
					self.BuildIcon = nil
				end
			end)

			BuildPersistent.OnToggled:Connect(function(Value : boolean)
				if (self.BuildIcon == nil) then
					self.BuildIcon = self.IconModule.new()
						:setLeft()
						:autoDeselect(false)
						:setImage("129306263749313")
						:setOrder(7)

					self.BuildIcon:bindEvent("selected", function(_, Source)
						if Source == "User" then
							SoundService.GUI.BasicOpen:Play()
							BuildPersistent:toggle(true)
						end
					end)

					self.BuildIcon:bindEvent("deselected", function(_, Source)
						if Source == "User" then
							SoundService.GUI.BasicOpen:Play()
							BuildPersistent:toggle(false)
						end
					end)
				end

				if Value then
					self.BuildIcon:select()
				else
					self.BuildIcon:deselect()
				end
			end)
		end)
	end

	if workspace:GetAttribute("IsRankedLobby") then
		self.MainPlaceIcon = self.IconModule.new()
			:setLeft()
			:oneClick()
			:setOrder(8)
			:setImage("75309286909772")

			:bindEvent("selected", function()
				SoundService.GUI.BasicOpen:Play()
				require( script.JoinMainPlace ):Join()
			end)
	end

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

function Icons:CloseAllExcept(ToNotClose : Instance)
	local UI_Module = self.UI

	local Elements = {
		UI_Module.Emotes.GUI, 
		UI_Module.Settings.GUI, 
		UI_Module.GiftingGUI, 
		UI_Module.InformationGUI
	}

	for _, GUI in Elements do
		if GUI ~= ToNotClose then
			GUI.Enabled = false
		end
	end
end

function Icons.new(UI)
	local self = setmetatable({}, Icons)

	self.UI = UI
	self.Combat = UI.Combat
	self.LuaPlayer = UI.LuaPlayer

	self.IconModule = require( ReplicatedStorage.Modules.Icon )
	task.delay(1, self._Init, self)

	return self
end;

table.freeze(Icons);

return Icons;