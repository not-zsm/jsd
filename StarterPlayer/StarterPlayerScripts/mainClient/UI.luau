local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local CollectionService = game:GetService("CollectionService")

----------------------------------------------------------------------------------

local Remotes = ReplicatedStorage.Remotes

local CombatRemotes = Remotes.Combat

local UIRemotes = CombatRemotes.UI
local HotbarRemotes = UIRemotes.Hotbar 

local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )
local EventService = require( ReplicatedStorage.modules.shared.Utilities.EventService )
local Job = require( ReplicatedStorage.modules.shared.Utilities.Job )
local NumberStack = require( ReplicatedStorage.modules.shared.Utilities.NumberStack )
local AnimatedGradient = require( ReplicatedStorage.modules.shared.Utilities.GradientEffect )
local ClientAnnouncementHandler = require( script.ClientAnnouncementHandler )
local HUDMovement = require( ReplicatedStorage.modules.effect.hudMovement )

local ScaleDescription = require(script:WaitForChild("InformationConfg"):WaitForChild("ScaleDescription"))

local HotbarData = require( script.HotbarData )

local FlashInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

local ULTIMATE_OUTER_GRADIENT_OFFSET = 0.575
local ULTIMATE_INNER_GRADIENT_OFFSET = 0.07
local ULTIMATE_BAR_GRADIENT_FADE = 0.005

----------------------------------------------------------------------------------

local UI = {}
UI.__index = UI

function UI:Init()
	-- Ultimate, Hotbar, DummyHotbar and the two templates are what the hotbar
	-- used before it moved to its own ScreenGui. Nothing drives them now, so
	-- they stay hidden until you delete them.
	local Retired = {
		SkillTemplate = true, DummySkillTemplate = true,
		Ultimate = true, Hotbar = true, DummyHotbar = true,
	}

	for _, GUI : Frame in ipairs(self.MainGUIHolder:GetChildren()) do
		if GUI:IsA("Frame") then
			GUI.Visible = not Retired[GUI.Name]
		end
	end
	
	self.Combat.OnAttackChanged:Connect(function(Attack, Added)
		if (Added and Attack.DirectoryName ~= "Global" and not Attack.Properties.HotbarHidden)  then
			self:AddOnHotbar(Attack.Name, Attack.Key)
			
		elseif not Added then
			self:RemoveFromHotbar(Attack.Name)
		end
	end)

	HotbarRemotes.Use.OnClientEvent:Connect(function(Name : string)
		self:UseOnHotbar(Name)
	end)
	
	HotbarRemotes.Add.OnClientEvent:Connect(function(Name : string, Key : (Enum.KeyCode | Enum.UserInputType))
		self:AddOnHotbar(Name, Key)
	end)
	
	HotbarRemotes.Show.OnClientEvent:Connect(function(Name : string)
		self:ShowOnHotbar(Name)
	end)
	
	HotbarRemotes.Hide.OnClientEvent:Connect(function(Name : string)
		self:HideOnHotbar(Name)
	end)

	HotbarRemotes.ChangeDisplay.OnClientEvent:Connect(function(Name : string, NewText : string, NewTip : string, FlashColor : Color3)
		self:ChangeHotbarDisplay(Name, NewText, NewTip, FlashColor)
	end)

	HotbarRemotes.ImportantChangeDisplay.OnClientEvent:Connect(function(Name : string, NewText : string, NewTip : string, FlashColor : Color3)
		self:ChangeHotbarDisplay(Name, NewText, NewTip, FlashColor)
	end)

	HotbarRemotes.AddCooldown.OnClientEvent:Connect(function(Name : string, Duration : string)
		self:AddCooldown(Name, Duration)
	end)

	HotbarRemotes.RemoveCooldown.OnClientEvent:Connect(function(Name : string)
		self:RemoveCooldown(Name)
	end)

	UIRemotes.Hide.OnClientEvent:Connect(function(Toggle : boolean)
		self:Toggle(not Toggle)
	end)

	CombatRemotes.PlayerKilled.OnClientEvent:Connect(function(KilledPlayer : Player, TotalKills : number, Type : string, ...)
		local Stuff = {...}
		
		local IsAPlayer = KilledPlayer:IsA("Player")
		local Name = IsAPlayer and KilledPlayer.DisplayName .. " (" .. KilledPlayer:GetAttribute("Name") .. ")" or KilledPlayer:GetAttribute("Name")

		local Killed_Chara = (Type == "CharaKill")

		if Killed_Chara then
			local Data : {}? = Stuff[1]
			local Text = Data and Data.Text
			
			if (Text == nil) then 
				return warn("no text for chara kill")
			end
	
			local CharaKill = self.CombatGUI:WaitForChild("CharaKill")
			CharaKill.Label.TextTransparency = 1
			CharaKill.Label.UIStroke.Transparency = 1			
			CharaKill.Label.Text = Text
			CharaKill.Visible = true
			
			SoundService:PlayLocalSound(SoundService.GUI.CharaKill)
			
			TweenService:Create(CharaKill.Label, TweenInfo.new(0.1), {
				TextTransparency = 0
			}):Play()

			TweenService:Create(CharaKill.Label.UIStroke, TweenInfo.new(0.1), {
				Transparency = 0
			}):Play()

			self.AwardedKillThread = task.delay(10, function()
				TweenService:Create(CharaKill.Label, TweenInfo.new(1), {
					TextTransparency = 1
				}):Play()

				TweenService:Create(CharaKill.Label.UIStroke, TweenInfo.new(1), {
					Transparency = 1
				}):Play()
			end)
			
		else
			if Type == "Left" then
				self.AwardedKill.Label.Text = Name .. " left the game, awarded kill for dealing highest damage. Killcount: " .. TotalKills
			else
				self.AwardedKill.Label.Text = Name .. " died, awarded kill for dealing highest damage. Killcount: " .. TotalKills
			end
			
			self.AwardedKill.Label.TextTransparency = 1
			self.AwardedKill.Label.UIStroke.Transparency = 1
			self.AwardedKill.Visible = true

			TweenService:Create(self.AwardedKill.Label, TweenInfo.new(0.1), {
				TextTransparency = 0
			}):Play()

			TweenService:Create(self.AwardedKill.Label.UIStroke, TweenInfo.new(0.1), {
				Transparency = 0
			}):Play()

			self.AwardedKillThread = task.delay(3, function()
				TweenService:Create(self.AwardedKill.Label, TweenInfo.new(1), {
					TextTransparency = 1
				}):Play()

				TweenService:Create(self.AwardedKill.Label.UIStroke, TweenInfo.new(1), {
					Transparency = 1
				}):Play()
			end)
		end
	end)
	
	Remotes.Announcement.OnClientEvent:Connect(function(Message : string, Title : string, Type : String)
		Title = Title or "Server Announcement"
		ClientAnnouncementHandler:Announce(Message, Title, Type)
	end)

	Remotes.ReceiveSystemMessage.OnClientEvent:Connect(function(Name : string, Activity : string)
		TextChatService:WaitForChild("TextChannels").RBXGeneral:DisplaySystemMessage(`{Name}'s Activity: {Activity}`)
	end)
	
	task.spawn(function()
		local SetMatchStateEvent = ReplicatedStorage.Remotes.Ranked:WaitForChild("SetMatchState")
		
		SetMatchStateEvent.OnClientEvent:Connect(function(newState)
			if newState == "CharacterSelection" then
				if self.Icons.CharacterIcon then
					self.Icons.CharacterIcon:setEnabled(true)
				end

			elseif newState == "Fighting" then
				if self.Icons.CharacterIcon then
					self.Icons.CharacterIcon:deselect()
					self.Icons.CharacterIcon:setEnabled(false)
				end

			elseif newState == "Intermission" then
				if self.Icons.CharacterIcon then
					self.Icons.CharacterIcon:setEnabled(false)
				end
			end
		end)
	end)

	Remotes.Notification.OnClientEvent:Connect(function(Data : {})
		Data = Data or {
			Title = "Notification",
			Text = "U are stinky",
			Duration = 5,
			Button1 = "Yeah i am",
			Button2 = "No.",
		}

		StarterGui:SetCore("SendNotification", Data)
	end)
	
	task.spawn(function() -- dont want this erroring and bricking your whole client
		---- [Information GUI] ----
		local function RemoveIndentation(text)
			local lines = {}
			for line in text:gmatch("[^\r\n]+") do
				table.insert(lines, line:match("^%s*(.-)$")) -- Trim leading spaces
			end
			local cleanedText = table.concat(lines, "\n") -- Reconstruct with proper line breaks
			return cleanedText:gsub("<br>", "\n") -- Replace <br> with a single line break
		end
		
		-- Setup Info Templates
		local InformationConfig = require( script.InformationConfg )
		local ScaleDesctiption = require( script.InformationConfg.ScaleDescription )

		for _, Guide in ipairs(InformationConfig.Guides) do
			local NewGuideFrame : Frame = self.Information.Templates.GuideTemplate:Clone()
			NewGuideFrame.Parent = self.Information.InfoFrame
			NewGuideFrame.Name = Guide.ChoiceTitle
			NewGuideFrame.Title.Text = Guide.Title
			NewGuideFrame.CoverImage.Image = `rbxassetid://{Guide.CoverImage}`
			NewGuideFrame.Description.Text = RemoveIndentation(Guide.Description)

			-- Scale Description To Screen
			ScaleDescription.ScaleTextLabel(NewGuideFrame.Description)

			local NewGuideButton : ImageButton = self.Information.Templates.ButtonTemplate:Clone()
			NewGuideButton.Parent = self.Information.ChoicesFrame
			NewGuideButton.Name = Guide.ChoiceTitle
			NewGuideButton.Title.Text = Guide.ChoiceTitle

			-- Setup Connection
			NewGuideButton.MouseButton1Click:Connect(function()
				for _, Info : Frame in ipairs(self.Information.InfoFrame:GetChildren()) do
					if Info:IsA("Frame") then
						Info.Visible = false
					end
				end

				NewGuideFrame.Visible = true
			end)
		end
		
		
		---- [Character Information GUI] ----
		
	end)
	
	local InCombatValue = Instance.new("NumberValue")
	InCombatValue.Value = 1
	
	InCombatValue.Changed:Connect(function(Value)
		self.InCombat.Visibility.Transparency = NumberSequence.new(Value);
	end)
	
	self.Combat.AttributeValues:GetAttributeChangedSignal("InCombat"):Connect(function()
		local Visibility = (self.Combat.AttributeValues:GetAttribute("InCombat") and 0 or 1)
		TweenService:Create(InCombatValue, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Value = Visibility}):Play()
	end)

	--if UserInputService.GamepadEnabled then
	--	self:UpdateDeviceSupport(true)
	--end

	--if UserInputService.TouchEnabled then
	--	self:UpdateDeviceSupport(self.Combat.UsingController, true)
	--end
	
	local function Changed()
		local NewInput = UserInputService.PreferredInput

		if NewInput == Enum.PreferredInput.Gamepad then
			self:UpdateDeviceSupport(true, false)

		elseif NewInput == Enum.PreferredInput.Touch then
			self:UpdateDeviceSupport(false, true)
		else
			self:UpdateDeviceSupport(false, false)
		end
	end
	
	Changed()
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(Changed)

	--UserInputService.LastInputTypeChanged:Connect(function(Type)
	--	if Type == Enum.UserInputType.Gamepad1 or Type == Enum.UserInputType.Gamepad2 or Type == Enum.UserInputType.Gamepad3 or Type == Enum.UserInputType.Gamepad3 then
	--		self:UpdateDeviceSupport(true)

	--	elseif Type == Enum.UserInputType.Touch then
	--		self:UpdateDeviceSupport(self.Combat.UsingController, true)

	--	elseif Type == Enum.UserInputType.Keyboard or Type == Enum.UserInputType.MouseButton1 or Type == Enum.UserInputType.MouseButton2 then
	--		self:UpdateDeviceSupport(false)
	--	end
	--end)

	--UserInputService.GamepadConnected:Connect(function()
	--	self:UpdateDeviceSupport(true)
	--end)

	--UserInputService.GamepadDisconnected:Connect(function()
	--	self:UpdateDeviceSupport(false)
	--end)

	self:InitiateUltimate()
end

function UI:ChangeHotbarDisplay(Name : string, NewText : string, NewTip : string, FlashColor : Color3)
	self.Hotbar:SetDisplay(Name, NewText, NewTip, FlashColor)
end

function UI:AddCooldown(Name : string, Duration : number)
	self.Hotbar:AddCooldown(Name, Duration)
end

function UI:RemoveCooldown(Name : string)
	self.Hotbar:RemoveCooldown(Name)
end

function UI:Toggle(Toggle : boolean, Time : number)
	Time = Time or 1.3

	self.UIToggleStack:Change(not Toggle)

	if not Toggle then
		if self.UIToggleStack:IsTrue() then
			self:SetHUDHidden(true, Time)
		end
	else
		if self.UIToggleStack:IsFalse() then
			self:SetHUDHidden(false, Time)
		end
	end
end

function UI:ToggleNoStack(Toggle : boolean, Time : number)
	Time = Time or 1.3
	
	self:SetHUDHidden(Toggle, Time)
end

-- The hotbar is its own ScreenGui now, so hiding the HUD is two moves. The
-- Hidden attribute stays on Main because TekrinnDialogue rides it.
function UI:SetHUDHidden(Hidden : boolean, Time : number?)
	Time = Time or 1.3

	self.MainGUI:SetAttribute("Hidden", Hidden or nil)

	TweenService:Create(self.MainGUIHolder, TweenInfo.new(Time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0, Hidden and 0.3 or 0)
	}):Play()

	self.Hotbar:SetHidden(Hidden)
end

function UI:UpdateDeviceSupport(Controller : boolean?, Touch : boolean)
	self.Combat.LastUsingController = self.Combat.UsingController
	self.Combat.UsingController = Controller

	self.Combat.LastUsingTouch = self.Combat.UsingTouch
	self.Combat.UsingTouch = Touch

	if self.Combat.UsingController or self.Combat.UsingTouch then
		if not self.EmotesIcon then
			self.EmotesIcon = self.Icons.IconModule.new()
				:setLeft()
				:setLabel("Emotes")
				:oneClick()
				:setOrder(8)
				:bindEvent("selected", function()
					self.Emotes:Toggle()
				end)
		end
	else
		if self.EmotesIcon then
			self.EmotesIcon:Destroy()
			self.EmotesIcon = nil
		end
	end

	self:SetUpMobile(self.Combat.UsingTouch)
	
	local UsingControllerChanged = self.Combat.LastUsingController ~= self.Combat.UsingController
	local UsingTouchChanged = self.Combat.LastUsingTouch ~= self.Combat.UsingTouch
	
	if UsingControllerChanged or UsingTouchChanged then
		local Device = 
			self.Combat.UsingTouch and "Touch" or 
			self.Combat.UsingController and "Controller" or 
			"Keyboard"
		
		--print("client is currently playing on", Device) 
	
		self.Combat.CurrentDevice = Device
		self.Combat.OnDeviceChanged:Fire(Device)
		
		ReplicatedStorage.Remotes.TellServerCurrentDevice:FireServer(Device)
		
		self.Hotbar:RefreshKeys()

		--if self.Settings.DeviceKeybinds and self.Settings.DeviceKeybinds[Device] then
		--	for Name, Key in self.Settings.DeviceKeybinds[Device] do
		--		self.Combat:ChangeAttackKey(Name, Key)
		--	end
		--end
	end
end


function UI:UpdateAttackToUseData(Name : string)
	self.Hotbar:ApplyTip(Name)
end

function UI:InitiateUltimate()
	local Attributes = self.Combat.AttributeValues

	local function AwakenKey() : string
		local Key = self.Combat.UsingController
			and Utility.KeyboardToControllerInputs[Enum.KeyCode.G]
			or Enum.KeyCode.G

		return typeof(Key) == "EnumItem" and Key.Name or "G"
	end

	local function UpdateName()
		local Progress = Attributes:GetAttribute("Ultimate")

		if Progress == 100 then
			self.Hotbar:SetUltMax(true, AwakenKey())
		else
			self.Hotbar:SetUltName( Attributes:GetAttribute("UltimateName") )
		end
	end

	local function UpdateProgress(Instant : boolean?)
		local Progress = Attributes:GetAttribute("Ultimate") or 0

		self.Hotbar:SetUltProgress(Progress / 100, Instant)
		UpdateName()
	end

	self.Combat.OnDeviceChanged:Connect(UpdateName)

	Attributes:GetAttributeChangedSignal("Ultimate"):Connect(function()
		UpdateProgress()
	end)

	Attributes:GetAttributeChangedSignal("UltimateName"):Connect(UpdateName)

	Attributes:GetAttributeChangedSignal("UltimateColor"):Connect(function()
		self.Hotbar:SetUltColor( Attributes:GetAttribute("UltimateColor") )
	end)

	Attributes:GetAttributeChangedSignal("UltimateBar"):Connect(function()
		self.Hotbar:SetUltVisible( Attributes:GetAttribute("UltimateBar") )
	end)

	if Attributes:GetAttribute("UltimateColor") ~= nil then
		self.Hotbar:SetUltColor( Attributes:GetAttribute("UltimateColor") )
	end

	if Attributes:GetAttribute("UltimateBar") ~= nil then
		self.Hotbar:SetUltVisible( Attributes:GetAttribute("UltimateBar") )
	end

	UpdateProgress(true)

	self.Hotbar.UltBar.button.MouseButton1Click:Connect(function()
		self.Combat:_AttackInputUpdate("Ultimate")
	end)
end

function UI:UseOnHotbar(Name : string, CustomColor : Color3)
	self.Hotbar:Use(Name, CustomColor)
end

function UI:OverlayOnHotbar(Name : string, Value : boolean)
	self.Hotbar:SetOverlay(Name, Value)
end

function UI:HideOnHotbar(Name : string)
	self.Hotbar:SetSlotShown(Name, false)
end

function UI:ShowOnHotbar(Name : string)
	self.Hotbar:SetSlotShown(Name, true)
end

function UI:AddOnHotbar(Name : string, Key : (Enum.KeyCode | Enum.UserInputType))
	self.Hotbar:Add(Name, Key)
end

function UI:RemoveFromHotbar(Name : string)
	self.Hotbar:Remove(Name)
end

function UI:LoadMobileButtonPositions(savedPositions : {})
	for _, buttonFrame in ipairs(self.MobileDragFrame:GetChildren()) do
		local buttonPositionTable = savedPositions[buttonFrame.Name]

		if buttonPositionTable then
			buttonFrame.Position = UDim2.fromScale(buttonPositionTable.x, buttonPositionTable.y)
		end
	end
end

function UI:ResetMobileButtonPositions()
	for _, buttonFrame in ipairs(self.MobileDragFrame:GetChildren()) do
		buttonFrame.Position = buttonFrame:GetAttribute("OriginalPosition")
	end
end

function UI:SaveMobileButtonPositions()
	local savedPositions = {}

	for _, buttonFrame in ipairs(self.MobileDragFrame:GetChildren()) do
		savedPositions[buttonFrame.Name] = {
			x = buttonFrame.Position.X.Scale,
			y = buttonFrame.Position.Y.Scale,
		}
	end

	ReplicatedStorage.Remotes.SaveMobileUIPosition:FireServer(savedPositions)
end

function UI:SetUpMobile(Value : boolean)
	self.MobileGUI.Enabled = Value

	if Value and not self.HasSetUpMobile then
		self.HasSetUpMobile = true
		self.MobileUIJob = Job.new()

		self.MobileRearrangeIcon = self.Icons.IconModule.new()
			:align("Left")
			:setLeft()
			:setLabel("Icon Edit")
			:setOrder(8)
			:setDropdown({
				self.Icons.IconModule.new()
				:setLabel("Rearrange")
				:bindEvent("selected", function()
					if not self.MobileRearranging then
						self.MobileRearranging = true

						for _, buttonFrame in ipairs(self.MobileDragFrame:GetChildren()) do
							buttonFrame.UIDragDetector.Enabled = true
							buttonFrame.Button.Interactable = false
						end
					end
				end)
				:bindEvent("deselected", function()
					if self.MobileRearranging then
						for _, buttonFrame in ipairs(self.MobileDragFrame:GetChildren()) do
							buttonFrame.UIDragDetector.Enabled = false
							buttonFrame.Button.Interactable = true
						end

						self:SaveMobileButtonPositions()
						self.MobileRearranging = false
					end
				end),
				
				self.Icons.IconModule.new()
				:setLabel("Reset")
				:oneClick()
				:bindEvent("selected", function()
					self:ResetMobileButtonPositions()
				end)
			})

		--self.MobileRearrangeIcon:bindEvent("selected", function()
		--	if not self.MobileRearranging then
		--		self.MobileRearranging = true

		--		for _, buttonFrame in ipairs(self.MobileDragFrame:GetChildren()) do
		--			buttonFrame.UIDragDetector.Enabled = true
		--			buttonFrame.Button.Interactable = false
		--		end
		--	end
		--end)

		--self.MobileRearrangeIcon:bindEvent("deselected", function()
		--	if self.MobileRearranging then
		--		for _, buttonFrame in ipairs(self.MobileDragFrame:GetChildren()) do
		--			buttonFrame.UIDragDetector.Enabled = false
		--			buttonFrame.Button.Interactable = true
		--		end

		--		self:SaveMobileButtonPositions()
		--		self.MobileRearranging = false
		--	end
		--end)

		self.MobileUIJob:Task(ReplicatedStorage.Remotes.SaveMobileUIPosition.OnClientEvent:Connect(function(Positions)
			if (Positions ~= nil) then
				self:LoadMobileButtonPositions(Positions)
			else
				self:ResetMobileButtonPositions()
			end
		end))

		for _, Frame : Frame in ipairs(self.MobileDragFrame:GetChildren()) do
			local Button : ImageButton = Frame.Button

			if Frame.Name == "Jump" then
				local JumpThread = nil
				
				local function OnJumpLetGo()
					self.Combat:StartNotHoldingJump()

					if JumpThread then
						coroutine.close(JumpThread)
						JumpThread = nil
					end

					Button.ImageRectOffset = Vector2.new(1, 146)
				end
				
				Button.MouseButton1Down:Connect(function()
					self.Combat:StartHoldingJump()

					if (JumpThread == nil) then
						JumpThread = coroutine.create(function()
							while self.LuaCharacter.HumanoidAlive do
								
								if self.LuaCharacter.Humanoid.FloorMaterial ~= Enum.Material.Air and self.LuaCharacter.Humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
									self.LuaCharacter.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
								end
							
								RunService.PostSimulation:Wait()
							end
						end)
						
						coroutine.resume(JumpThread)
					end
					
					Button.ImageRectOffset = Vector2.new(146, 146)
				end)
				
				Button.MouseButton1Up:Connect(OnJumpLetGo)
				Button.MouseLeave:Connect(OnJumpLetGo)
			else
				local function OnLetGo()
					if Frame.Name == "M1" or Frame.Name == "Block" then
						self.Combat:_AttackInputUpdate(Frame.Name, false)
					end
				end
			
				Button.MouseButton1Down:Connect(function()
					if Frame.Name == "ShiftLock" then
						self.LuaCharacter:ToggleShiftlock()

					elseif Frame.Name == "Dash" then
						self.Combat.ClientHandlers.Dash:OnInput()
					end

					if Frame.Name == "M1" or Frame.Name == "Block" then
						self.Combat:_AttackInputUpdate(Frame.Name, true)
					end
				end)
				
				Button.MouseButton1Up:Connect(OnLetGo)
				Button.MouseLeave:Connect(OnLetGo)
			end
		end

	elseif not Value and self.HasSetUpMobile then
		self.HasSetUpMobile = false

		if self.MobileRearrangeIcon then
			self.MobileRearrangeIcon:Destroy()
			self.MobileRearrangeIcon = nil
		end

		for _, buttonFrame in ipairs(self.MobileDragFrame:GetChildren()) do
			buttonFrame.UIDragDetector.Enabled = false
			buttonFrame.Button.Interactable = true
		end

		if self.MobileUIJob then
			self.MobileUIJob:Destroy()
			self.MobileUIJob = nil
		end

		self.MobileRearranging = false
	end
end

function UI.new(Combat)
	local self = setmetatable({}, UI)

	self.Combat = Combat
	self.LuaCharacter = Combat.LuaCharacter
	self.LuaPlayer = Combat.LuaCharacter.LuaPlayer

	self.PlayerGui = self.LuaPlayer.PlayerGui

	self.MainGUI = self.PlayerGui:WaitForChild("Main", 100)

	self.ImpactFrames = self.PlayerGui:WaitForChild("ImpactFrames")
	self.AnnouncementGUI = self.PlayerGui:WaitForChild("Announcement")
	self.GiftingGUI = self.PlayerGui:WaitForChild("Gifting")
	self.InformationGUI = self.PlayerGui:WaitForChild("Information")
	self.CharacterInformationGUI = self.PlayerGui:WaitForChild("CharacterInfo")
	self.CombatGUI = self.PlayerGui:WaitForChild("Combat")
	self.MobileGUI = self.PlayerGui:WaitForChild("Mobile")
	self.StatisticsGUI = self.PlayerGui:WaitForChild("Statistics")

	self.MainGUIHolder = self.MainGUI:WaitForChild("Holder")

	self.Hotbar = require(script.Hotbar).new(self)
	
	self.Announcement = self.AnnouncementGUI:WaitForChild("Holder")
	self.Information = self.InformationGUI:WaitForChild("Holder")
	
	self.Statistics = self.StatisticsGUI:WaitForChild("Holder")
	self.InCombat = self.Statistics:WaitForChild("InCombat")
	
	--self.InCombat = self.CombatGUI:WaitForChild("InCombat")
	self.AwardedKill = self.CombatGUI:WaitForChild("AwardedKill")
	self.AwardedKillThread = nil

	self.MobileDragFrame = self.MobileGUI:WaitForChild("DragFrame")

	self.UIToggleStack = NumberStack.new()
	
	task.spawn(function()
		if UserInputService.TouchEnabled then
			self.PlayerGui:WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):WaitForChild("JumpButton"):Destroy()
		end
	end)
	
	task.spawn(function()
		local DialogueManager = require(script:WaitForChild("DialogueManager"))
		local Dialogue = DialogueManager.Init(self)
		
		local function Add(Model : Model)
			local RootPart : BasePart = Model:WaitForChild("HumanoidRootPart")
			local Prompt = RootPart:FindFirstChildOfClass("ProximityPrompt")
			
			if Prompt then
				Prompt.Triggered:Connect(function()
					if not self.LuaPlayer.Player:GetAttribute("HoldingCrate") then
						Dialogue:StartConversation(Model)
					end
				end)
			end
		end
		
		for _, Model in CollectionService:GetTagged("Dialogue") do
			if Model:IsA("Model") then
				Add(Model)
			end
		end
		
		CollectionService:GetInstanceAddedSignal("Dialogue"):Connect(function(Model : Model?)
			if Model:IsA("Model") then
				Add(Model)
			end
		end)
	end)

	-- SetHUDHidden owns Position on these two, so the sway has to be the only
	-- other writer: it reads their rest position once and offsets from it
	HUDMovement({ self.Hotbar.Holder, self.Hotbar.UltBar }, function()
		return self.LuaPlayer.Player:GetAttribute("HUD_Sway") ~= false
	end)

	self.Emotes = require(script.Emotes).new(self)
	self.Settings = require(script.Settings).new(self)
	self.Icons = require(script.Icons).new(self)

	return self
end

table.freeze(UI)

return UI