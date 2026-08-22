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

local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )
local EventService = require( ReplicatedStorage.Shared.Utilities.EventService )
local Job = require( ReplicatedStorage.Shared.Utilities.Job )
local NumberStack = require( ReplicatedStorage.Shared.Utilities.NumberStack )
local AnimatedGradient = require( ReplicatedStorage.Shared.Utilities.GradientEffect )
local ClientAnnouncementHandler = require( script.ClientAnnouncementHandler )

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
	for _, GUI : Frame in ipairs(self.MainGUIHolder:GetChildren()) do
		if GUI:IsA("Frame") and GUI.Name ~= "SkillTemplate" then
			GUI.Visible = true
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
	local Data : {} = self.CurrentHotbar[Name]
	if (Data == nil) then return end

	local GUI = Data.GUI

	local Button = GUI.Button
	local Skill : Frame = Button.Skill
	Skill.DisplayName.Text = NewText

	if NewTip then
		if NewTip == "" then
			Skill.Tip.Text = ""
			Skill.Tip.Visible = false
		else
			Skill.Tip.Text = NewTip
			Skill.Tip.Visible = true
		end
	else
		if NewText == Name then
			self:UpdateAttackToUseData(Name)
		else
			Skill.Tip.Visible = false
		end
	end
	
	if (FlashColor and GUI.Parent ~= nil) then
		Skill.DisplayName.TextColor3 = FlashColor

		Button.FlashBorder.Color = FlashColor
		Button.FlashBorder.Transparency = 0
		Button.FlashBorder.Enabled = true

		local Tween = TweenService:Create(Button.FlashBorder, FlashInfo, {
			Transparency = 1
		})

		TweenService:Create(Skill.DisplayName, FlashInfo, {
			TextColor3 = Color3.new(1, 1, 1)
		}):Play()

		Tween:Play()

		Tween.Completed:Connect(function(PlaybackState)
			if (PlaybackState == Enum.PlaybackState.Completed and GUI.Parent ~= nil) then
				Button.FlashBorder.Enabled = false
			end
		end)
	end
end

function UI:AddCooldown(Name : string, Duration : number)
	local Data : {} = self.CurrentHotbar[Name]
	if (Data == nil) then return end

	local GUI = Data.GUI
	local Button = GUI.Button

	local TimingVal = Instance.new("NumberValue")
	TimingVal.Value = 1

	TimingVal.Changed:Connect(function()
		if (GUI.Parent ~= nil) then
			Button.Cooldown.Size = UDim2.fromScale(1, TimingVal.Value)
			Button.CooldownValue.Text = math.round(TimingVal.Value * Duration)
		end	
	end)

	local Tween = TweenService:Create(TimingVal, TweenInfo.new(Duration, Enum.EasingStyle.Linear), 
		{Value = 0}
	)

	Button.CooldownValue.Text = Duration
	Button.CooldownValue.Visible = true

	Button.Cooldown.Visible = true
	Button.Cooldown.Size = UDim2.fromScale(1, 1)

	Tween:Play()

	Data.RemoveCooldown:Once(function()
		TimingVal:Destroy()

		Button.Cooldown.Visible = false
		Button.CooldownValue.Visible = false
	end)
end

function UI:RemoveCooldown(Name : string)
	local Data : {} = self.CurrentHotbar[Name]
	if (Data == nil) then return end

	Data.RemoveCooldown:Fire()
end

function UI:Toggle(Toggle : boolean, Time : number)
	Time = Time or 1.3

	self.UIToggleStack:Change(not Toggle)

	if not Toggle then
		if self.UIToggleStack:IsTrue() then
			self.MainGUI:SetAttribute("Hidden", true)

			TweenService:Create(self.MainGUIHolder, TweenInfo.new(Time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(0, 0.3)
			}):Play()
		end
	else
		if self.UIToggleStack:IsFalse() then
			self.MainGUI:SetAttribute("Hidden", nil)

			TweenService:Create(self.MainGUIHolder, TweenInfo.new(Time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(0, 0)
			}):Play()
		end
	end
end

function UI:ToggleNoStack(Toggle : boolean, Time : number)
	Time = Time or 1.3
	
	if Toggle then
		self.MainGUI:SetAttribute("Hidden", true)

		TweenService:Create(self.MainGUIHolder, TweenInfo.new(Time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0, 0.3)
		}):Play()
	else
		self.MainGUI:SetAttribute("Hidden", nil)

		TweenService:Create(self.MainGUIHolder, TweenInfo.new(Time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0, 0)
		}):Play()
	end
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
		
		for Name, Table in self.CurrentHotbar do
			self:UpdateSkillTextToSupportDevice(Table.GUI)
		end

		--if self.Settings.DeviceKeybinds and self.Settings.DeviceKeybinds[Device] then
		--	for Name, Key in self.Settings.DeviceKeybinds[Device] do
		--		self.Combat:ChangeAttackKey(Name, Key)
		--	end
		--end
	end
end

local BetterSubNames = {
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
	[Enum.KeyCode.DPadLeft] = "DPad-L"
}

function UI:UpdateSkillTextToSupportDevice(GUI : Frame)
	local Skill : Frame = GUI.Button.Skill
	local Key = GUI:GetAttribute("Key")
	local Order = GUI:GetAttribute("Order")

	if self.Combat.UsingController and Utility.KeyboardToControllerInputs[Key] then
		local NewName = BetterSubNames[Utility.KeyboardToControllerInputs[Key]]

		if NewName then
			Skill.Key.Text = NewName
		end
	else
		local DisplayKey = Key.Name

		if Key == Enum.UserInputType.MouseButton1 then
			DisplayKey = "M1"

		elseif Key == Enum.UserInputType.MouseButton2 then
			DisplayKey = "M2"
		end
		
		Skill.Key.Text = (Order > 0 and Order <= 9) and Order or DisplayKey
	end
end

function UI:UpdateAttackToUseData(Name : string)
	local Data : {} = self.CurrentHotbar[Name]
	if (Data == nil) then return end

	local GUI = Data.GUI
	local Data = HotbarData[Name]

	if (Data ~= nil and Data.OnAdded) then
		Data.OnAdded(GUI)
	end
end

function UI:InitiateUltimate()
	--local Gradient = AnimatedGradient.new(self.UltimateGradiant)

	local function UpdateMaxText(Key : (Enum.KeyCode | Enum.UserInputType))
		--print("ultimate text updated", Key)
		
		if (Key == nil) then
			--local Keybind = self.Combat:GetKeybindForMove("Ultimate") 
				
			--if Keybind then
			--	Key = Keybind
			--else
				if self.Combat.UsingController then
					Key = Utility.KeyboardToControllerInputs[Enum.KeyCode.G]
				else
					Key = Enum.KeyCode.G
				end
			--end
		end

		if typeof(Key) == "EnumItem" then
			self.Ultimate.IsMax.Text = "[" .. Key.Name .. "]"
		else
			print("ultimate key wasnt an enum? idk vro")
		end
		
	end
	
	--task.spawn(function()
	--	self.Settings.OnKeybindUpdated:Connect(function(Move : string, NewKey : (Enum.KeyCode | Enum.UserInputType))
	--		if Move == "Ultimate" then
	--			UpdateMaxText(NewKey)
	--		end
	--	end)
	--end)
	
	task.spawn(function()
		self.Combat.OnDeviceChanged:Connect(function()
			UpdateMaxText()
		end)
	end)
	
	task.spawn(UpdateMaxText)
	
	local function UpdateUltimateColor()
		self.UltimateGradiant.Color = self.Combat.AttributeValues:GetAttribute("UltimateColor")
		self.Ultimate.Title.Gradient.Color = self.Combat.AttributeValues:GetAttribute("UltimateColor")
		self.Ultimate.IsMax.Gradient.Color = self.Combat.AttributeValues:GetAttribute("UltimateColor")
	end

	local function UpdateUltimateName()
		self.Ultimate.Title.Text = self.Combat.AttributeValues:GetAttribute("UltimateName")
	end
	
	local function UpdateUltimateBar()
		self.Ultimate.Visible = self.Combat.AttributeValues:GetAttribute("UltimateBar")
	end

	local function UpdateMaxIndicator(Progress : number)
		if (Progress == 100) then
			task.spawn(UpdateMaxText)
			
			self.Ultimate.IsMax.TextTransparency = 1
			self.Ultimate.IsMax.Visible = true

			TweenService:Create(self.Ultimate.IsMax, TweenInfo.new(0.15), {
				TextTransparency = 0
			}):Play()
			
			--Gradient:Animate()
		else
			self.Ultimate.IsMax.Visible = false
			self.Ultimate.IsMax.TextTransparency = 0

			TweenService:Create(self.Ultimate.IsMax, TweenInfo.new(0.15), {
				TextTransparency = 1
			}):Play()
		end
		
		if (Progress == 0) then
			--Gradient:Stop()
		end
	end

	local function MaxIndicatorUpdate(Progress : number)
		if not self.Settings.Loaded then
			self.Settings.OnLoaded:Once(function()
				UpdateMaxIndicator(Progress)
			end)
		else
			UpdateMaxIndicator(Progress)
		end
	end

	self.UltimateTweenGradient.Changed:Connect(function(Value)
		self.UltimateGradiant.Transparency = self:CalculateUltimateGradientValue(Value)
	end)

	local StartValue = self.Combat.AttributeValues:GetAttribute("Ultimate")

	if (StartValue ~= nil) then
		self.UltimateTweenGradient.Value = (StartValue / 100)
	end

	if (StartValue == 0) then
		self.UltimateGradiant.Transparency = self:CalculateUltimateGradientValue(0)
	end

	self.Combat.AttributeValues:GetAttributeChangedSignal("Ultimate"):Connect(function()
		local Progress = self.Combat.AttributeValues:GetAttribute("Ultimate")

		TweenService:Create(self.UltimateTweenGradient, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Value = (Progress / 100)
		}):Play()

		MaxIndicatorUpdate(Progress)
	end)

	MaxIndicatorUpdate(StartValue)

	if (self.Combat.AttributeValues:GetAttribute("UltimateColor") ~= nil) then
		UpdateUltimateColor()
	end

	if (self.Combat.AttributeValues:GetAttribute("UltimateName") ~= nil) then
		UpdateUltimateName()
	end
	
	if (self.Combat.AttributeValues:GetAttribute("UltimateBar") ~= nil) then
		UpdateUltimateBar()
	end

	self.Combat.AttributeValues:GetAttributeChangedSignal("UltimateColor"):Connect(UpdateUltimateColor)
	self.Combat.AttributeValues:GetAttributeChangedSignal("UltimateName"):Connect(UpdateUltimateName)
	self.Combat.AttributeValues:GetAttributeChangedSignal("UltimateBar"):Connect(UpdateUltimateBar)
	
	do
		--local Hovering = false

		--self.Ultimate.MobileButton.MouseEnter:Connect(function()
		--	Hovering = true
		--end)

		--self.Ultimate.MobileButton.MouseLeave:Connect(function()
		--	Hovering = false
		--end)

		--UserInputService.InputBegan:Connect(function(Input, Typing)
		--	if Input.UserInputType == Enum.UserInputType.Touch and Hovering then
		--		self.LuaPlayer.Remotes.Combat.AttackInput:FireServer("Ultimate", true)
		--	end
		--end)

		--UserInputService.InputEnded:Connect(function(Input)
		--	if Input.UserInputType == Enum.UserInputType.Touch then
		--		self.LuaPlayer.Remotes.Combat.AttackInput:FireServer("Ultimate", false)
		--	end
		--end)
		
		self.Ultimate.MobileButton.MouseButton1Click:Connect(function()
			self.Combat:_AttackInputUpdate("Ultimate")
		end)
	end
end

function UI:UseOnHotbar(Name : string, CustomColor : Color3)
	local Data : {} = self.CurrentHotbar[Name]
	if (Data == nil) then return end

	local GUI = Data.GUI
	local Button = GUI.Button

	local Transparency = Button.Available.Grad:GetAttribute("StartTransparency")

	if CustomColor then
		Button.Available.Grad.Color = ColorSequence.new(CustomColor)
	end

	Button.Available.Grad.Transparency = Transparency
	Button.Available.Visible = true

	Button.BlinkValue.Value = 0

	local Tween = TweenService:Create(Button.BlinkValue, TweenInfo.new(0.25), {Value = 1})
	Tween:Play()

	local Connection = Button.BlinkValue.Changed:Connect(function()
		Button.Available.Grad.Transparency = Utility.InterpolateNumberSequenceValues(Transparency, Button.BlinkValue.Value, 1)
	end)

	Tween.Completed:Once(function(PlaybackState)
		Connection:Disconnect()

		if (PlaybackState == Enum.PlaybackState.Completed and GUI.Parent ~= nil) then
			Button.Available.Visible = false
		end
	end)
end

function UI:OverlayOnHotbar(Name : string, Value : boolean)
	local Data : {} = self.CurrentHotbar[Name]
	if (Data == nil) then return end

	local GUI = Data.GUI
	local Button = GUI.Button
	
	if (Value ~= nil) then
		Button.Overlay.Visible = Value
	else
		Button.Overlay.Visible = not Button.Overlay.Visible
	end
end;

function UI:HideOnHotbar(Name: string)
	local HotbarItem = self.CurrentHotbar[Name];
	
	if HotbarItem and HotbarItem.DummyGUI.Visible then
		local GUI = HotbarItem.GUI;
		local Info = TweenInfo.new(0.5);
		
		HotbarItem.DummyGUI.Visible = false;
		
		local Tween = TweenService:Create(GUI.Button, Info, { Position = UDim2.fromScale(0, 2) });
		
		Tween.Completed:Once(function(Status)
			if Status == Enum.PlaybackState.Completed then
				GUI.Visible = false;
			end;
		end);

		Tween:Play();
	end;
end;

function UI:ShowOnHotbar(Name: string)
	local HotbarItem = self.CurrentHotbar[Name];

	if HotbarItem and not HotbarItem.DummyGUI.Visible then
		local GUI = HotbarItem.GUI;
		local Info = TweenInfo.new(0.5);
		
		HotbarItem.DummyGUI.Visible = true;
		
		GUI.Button.Position = UDim2.fromScale(0, 2);
		GUI.Visible = true;
		
		local Tween = TweenService:Create(GUI.Button, Info, { Position = UDim2.fromScale(0, 0) });
		Tween:Play();
	end;
end;

function UI:AddOnHotbar(Name : string, Key : (Enum.KeyCode | Enum.UserInputType))
	if typeof(Key) ~= "EnumItem" then return end
	
	if (self.CurrentHotbar[Name] ~= nil) then
		local Order = (Key.Value - 48)

		local HotbarItem = self.CurrentHotbar[Name];
		
		local DummyGUI : Frame = HotbarItem.DummyGUI;
		local GUI : Frame = HotbarItem.GUI
		local Button : ImageButton = GUI.Button
		local Skill : Frame = Button.Skill

		GUI:SetAttribute("Name", Name)
		GUI:SetAttribute("Key", Key)
		GUI:SetAttribute("Order", Order)
		
		self:UpdateSkillTextToSupportDevice(GUI)
		self:UpdateAttackToUseData(Name)

		Skill.DisplayName.Text, GUI.Name = Name, Name;
		GUI.LayoutOrder = Order;
		
		DummyGUI.Name = Name;
		DummyGUI.LayoutOrder = Order;
	else
		local Order = (Key.Value - 48)

		local DummyGUI : Frame = self.MainGUIHolder.DummySkillTemplate:Clone()
		DummyGUI.LayoutOrder = Order;
		DummyGUI.Position = UDim2.fromScale(0.5, 1.5);
		DummyGUI.Name = Name;
		
		local GUI : Frame = self.MainGUIHolder.SkillTemplate:Clone()
		local Button : ImageButton = GUI.Button
		local Skill : Frame = Button.Skill
	
		GUI:SetAttribute("Name", Name)
		GUI:SetAttribute("Key", Key)
		GUI:SetAttribute("Order", Order)

		local HotbarItem = {
			RemoveCooldown = EventService.new(),
			Job = Job.new(),
			GUI = GUI,
			DummyGUI = DummyGUI,
		};
		
		self.CurrentHotbar[Name] = HotbarItem;

		self:UpdateSkillTextToSupportDevice(GUI)
		self:UpdateAttackToUseData(Name)

		Skill.DisplayName.Text, GUI.Name = Name, Name;
		
		GUI.LayoutOrder = Order;
		GUI.Visible = true;
		GUI.Position = UDim2.fromScale(0.5, 1.5);
		GUI.Parent = self.Hotbar;
		
		DummyGUI.Parent = self.DummyHotbar;
		
		HotbarItem.Job:Task(Button.MouseButton1Click:Connect(function()
			self.Combat:_AttackInputUpdate(Name)
		end))
		
		local Info = TweenInfo.new(0.33, Enum.EasingStyle.Cubic);
		
		local function UpdateGUI(Immediate: boolean?)
			local NewPosition = (DummyGUI.AbsolutePosition - self.DummyHotbar.AbsolutePosition) + DummyGUI.AbsoluteSize * DummyGUI.AnchorPoint;
			local NewOffset = UDim2.fromOffset(NewPosition.X, NewPosition.Y);
			
			if Immediate then
				GUI.Position = NewOffset;
			else
				TweenService:Create(GUI, Info, {Position = NewOffset}):Play();
			end;
		end;
		
		task.defer(UpdateGUI, true);
		HotbarItem.Job:Task(DummyGUI:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdateGUI));
		
		TweenService:Create(Button, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), { Position = UDim2.fromScale(0, 0) }):Play()
		
		--local Hovering = false

		--self.CurrentHotbar[Name].Job:Task(Button.MouseEnter:Connect(function()
		--	Hovering = true
		--end))

		--self.CurrentHotbar[Name].Job:Task(Button.MouseLeave:Connect(function()
		--	Hovering = false
		--end))

		--self.CurrentHotbar[Name].Job:Task(UserInputService.InputBegan:Connect(function(Input, Typing)
		--	if Input.UserInputType == Enum.UserInputType.Touch and Hovering then
		--		self.LuaPlayer.Remotes.Combat.AttackInput:FireServer(Name, true)
		--	end
		--end))

		--self.CurrentHotbar[Name].Job:Task(UserInputService.InputEnded:Connect(function(Input)
		--	if Input.UserInputType == Enum.UserInputType.Touch then
		--		self.LuaPlayer.Remotes.Combat.AttackInput:FireServer(Name, false)
		--	end
		--end))
	end
end

function UI:RemoveFromHotbar(Name : string)
	local HotbarItem = self.CurrentHotbar[Name];
	if not HotbarItem then return end
	
	HotbarItem.Job:Destroy()
	HotbarItem.DummyGUI:Destroy();
	
	self.CurrentHotbar[Name] = nil;
	
	local GUI = HotbarItem.GUI;
	local Info = TweenInfo.new(0.5);
	local Tween = TweenService:Create(GUI.Button, Info, { Position = UDim2.fromScale(0, 2) });
	
	Tween.Completed:Once(function()
		GUI:Destroy();
	end);
	
	Tween:Play();
end

function UI:CalculateUltimateGradientValue(Alpha: number)
	Alpha = math.clamp(Alpha * ULTIMATE_OUTER_GRADIENT_OFFSET, 0, ULTIMATE_OUTER_GRADIENT_OFFSET)

	local Delta = ULTIMATE_INNER_GRADIENT_OFFSET + Alpha / 2

	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(Utility.AlphaClamp(0.5 - Delta - ULTIMATE_BAR_GRADIENT_FADE), 1),
		NumberSequenceKeypoint.new(Utility.AlphaClamp(0.5 - Delta), 0),
		NumberSequenceKeypoint.new(Utility.AlphaClamp(0.5 + Delta), 0),
		NumberSequenceKeypoint.new(Utility.AlphaClamp(0.5 + Delta + ULTIMATE_BAR_GRADIENT_FADE), 1),
		NumberSequenceKeypoint.new(1, 1)
	})
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

	self.Ultimate = self.MainGUIHolder:WaitForChild("Ultimate")
	self.Hotbar = self.MainGUIHolder:WaitForChild("Hotbar")
	self.DummyHotbar = self.MainGUIHolder:WaitForChild("DummyHotbar");
	
	self.Announcement = self.AnnouncementGUI:WaitForChild("Holder")
	self.Information = self.InformationGUI:WaitForChild("Holder")
	
	self.Statistics = self.StatisticsGUI:WaitForChild("Holder")
	self.InCombat = self.Statistics:WaitForChild("InCombat")
	
	--self.InCombat = self.CombatGUI:WaitForChild("InCombat")
	self.AwardedKill = self.CombatGUI:WaitForChild("AwardedKill")
	self.AwardedKillThread = nil

	self.MobileDragFrame = self.MobileGUI:WaitForChild("DragFrame")

	self.UltimateGradiant = self.Ultimate.Fill.UIGradient
	self.UltimateTweenGradient = Instance.new("NumberValue")

	self.UIToggleStack = NumberStack.new()

	self.CurrentHotbar = {}
	
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

	self.Emotes = require(script.Emotes).new(self)
	self.Settings = require(script.Settings).new(self)
	self.Icons = require(script.Icons).new(self)

	return self
end

table.freeze(UI)

return UI