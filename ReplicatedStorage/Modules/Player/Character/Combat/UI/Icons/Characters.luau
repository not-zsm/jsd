local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Remotes = ReplicatedStorage.Remotes
local CombatRemotes = Remotes.Combat

local Icon = require( ReplicatedStorage.Modules.Icon )
local Observer = require( ReplicatedStorage.Packages.Observer )

local Whitelist = require( ReplicatedStorage.Modules.Shared.Game.Whitelist )

local PlayerGuis = {}

local function compress_color_sequence(original_sequence : ColorSequence, compress_to : number?)
	local multiplier = compress_to or 0.1

	local keypoints = original_sequence.Keypoints
	local new_keypoints = {}

	for _, keypoint : ColorSequenceKeypoint in keypoints do
		table.insert(new_keypoints, ColorSequenceKeypoint.new(keypoint.Time * multiplier, keypoint.Value))
	end

	table.insert(new_keypoints, ColorSequenceKeypoint.new(1, keypoints[#keypoints].Value))

	return ColorSequence.new(new_keypoints)
end

ReplicatedStorage.Remotes.Ranked.UpdateSelectionDisplay.OnClientEvent:Connect(function(TargetPlayer: Player, IconId: string)
	if not TargetPlayer then return end

	local Character = TargetPlayer.Character or TargetPlayer.CharacterAdded:Wait()
	local Head = Character and Character:FindFirstChild("Head")
	if not Head then return end

	local PlayerGui = PlayerGuis[TargetPlayer]
	if not PlayerGui then
		PlayerGui = Instance.new("BillboardGui")
		PlayerGui.Name = "CharacterSelectionIcon"
		PlayerGui.Adornee = Head
		PlayerGui.Size = UDim2.new(0, 80, 0, 80)
		PlayerGui.StudsOffset = Vector3.new(0, 2.5, 0)
		PlayerGui.AlwaysOnTop = true

		local ImageLabel = Instance.new("ImageLabel")
		ImageLabel.BackgroundTransparency = 1
		ImageLabel.Size = UDim2.fromScale(1, 1)
		ImageLabel.Parent = PlayerGui

		PlayerGui.Parent = Head
		PlayerGuis[TargetPlayer] = PlayerGui
	end

	local ImageLabel = PlayerGui:FindFirstChildOfClass("ImageLabel")

	if ImageLabel then
		ImageLabel.Image = "rbxassetid://" .. tostring(IconId)
	end
end)

ReplicatedStorage.Remotes.Ranked.ClearSelectionDisplays.OnClientEvent:Connect(function()
	for Player, Gui in pairs(PlayerGuis) do
		if Gui then
			Gui:Destroy()
		end
	end

	table.clear(PlayerGuis)
end)

--[[
	:modifyTheme({
		{"IconTextGradient", "Enabled", true},
		{"IconTextGradient", "Color", compress_color_sequence()}
	})
]]

return function(Player : Player)
	local UserId = Player.UserId

	local Jimpee = Icon.new()
		:setOrder(1)
		:setImage("17189234841")
		:setLabel("Jimpee")
		:bindEvent("selected", function()
			CombatRemotes.SwitchCharacter:FireServer("Jimpee", "17189234841")
		end)
		:oneClick()
		:hideOnCondition(function()
			return not Whitelist.is_permitted(UserId, "Jimpee")
		end)

	local Crusader = Icon.new()
		:setOrder(2)
		:setImage("136505645200132")
		:setLabel("Stardust Crusader")
		:setImageScale(0.6)
		:modifyTheme({
			"IconLabel",
			"TextColor3",
			Color3.fromRGB(162, 108, 255)
		})
		:bindEvent("selected", function()
			CombatRemotes.SwitchCharacter:FireServer("Stardust Crusader", "136505645200132")
		end)
		:oneClick()
		:hideOnCondition(function()
			return not Whitelist.is_permitted(UserId, "Crusader")
		end)

	local RedMist = Icon.new()
		:setOrder(10)
		:setImage("81824650773495")
		:setLabel("Red Mist")
		:bindEvent("selected", function()
			CombatRemotes.SwitchCharacter:FireServer("Gebura Red Mist", "81824650773495")
		end)
		:modifyTheme({
			{"IconGlow", "Visible", true, "Deselected"},
			{"IconGlow", "ImageColor3", Color3.fromRGB(170, 63, 49)},
			{"IconTextGradient", "Enabled", true},
			{"IconTextGradient", "Color", compress_color_sequence(ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(181, 53, 53)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(109, 32, 32)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(181, 53, 53)),
			}))},
		})
		:oneClick()
		:hideOnCondition(function()
			local HasWhitelist = Whitelist.is_permitted(UserId, "Gebura")
			local HasTag = Player:HasTag("DonationCharacterAccess")

			return if (HasTag or HasWhitelist) then false else true
		end)

	local function Hide_Gebura_If_Not_Permitted()
		local HasWhitelist = Whitelist.is_permitted(UserId, "Gebura")
		local HasTag = Player:HasTag("DonationCharacterAccess")

		RedMist:setEnabled(if (HasTag or HasWhitelist) then true else false)
	end

	--local Hornet = Icon.new()
	--	:setOrder(20)
	--	:setLabel("Hornet")
	--	:bindEvent("selected", function()
	--		CombatRemotes.SwitchCharacter:FireServer("Hornet", "")
	--	end)
	--	:oneClick()
	--	:hideOnCondition(function()
	--		return not Whitelist.is_permitted(UserId, "Hornet")
	--	end)

	local Meaty = Icon.new()
		:setOrder(11)
		:setImage("18303618690")
		:setLabel("Meaty Michael")
		:bindEvent("selected", function()
			CombatRemotes.SwitchCharacter:FireServer("Meaty Michael", "18303618690")
		end)
		:oneClick()
		:hideOnCondition(function()
			return not Whitelist.is_permitted(UserId, "Meaty")
		end)

	local Invincible = Icon.new()
		:setOrder(12)
		:setImage("101089066666765")
		:setLabel("The Conquered")
		:bindEvent("selected", function()
			CombatRemotes.SwitchCharacter:FireServer("Invincible", "101089066666765")
		end)
		:oneClick()
		:hideOnCondition(function()
			return not Whitelist.is_permitted(UserId, "Invisible")
		end)

	local David = Icon.new()
		:setOrder(13)
		:setImage("94362608702821")
		:setLabel("Edgerunner")
		:modifyTheme({
			"IconLabel",
			"TextColor3",
			Color3.fromRGB(251, 255, 0)
		})
		:bindEvent("selected", function()
			CombatRemotes.SwitchCharacter:FireServer("Edgerunner", "94362608702821")
		end)
		:oneClick()
		:hideOnCondition(function()
			return not Whitelist.is_permitted(UserId, "Edgerunner")
		end)

	--local Demon = Icon.new()
	--	:setOrder(14)
	--	:setImage("110542699844684")
	--	:setLabel("Destructive Demon")
	--	:modifyTheme({
	--		"IconLabel",
	--		"TextColor3",
	--		Color3.fromRGB(175, 214, 255)
	--	})
	--	:bindEvent("selected", function()
	--		CombatRemotes.SwitchCharacter:FireServer("Demon", "110542699844684")
	--	end)
	--	:oneClick()
	--	:hideOnCondition(function()
	--		return not Whitelist.is_permitted(UserId, "Demon")
	--	end)

	Observer.observe_tag("DonationCharacterAccess", function(got_instance : Instance)
		if got_instance ~= Player then
			return function() end
		end

		RedMist:setEnabled(true)

		return Hide_Gebura_If_Not_Permitted
	end)

	Whitelist.on_data_updated:Connect(function(_, did_update)
		Crusader:setEnabled(Whitelist.is_permitted(UserId, "Crusader"))
		Meaty:setEnabled(Whitelist.is_permitted(UserId, "Meaty"))
		Invincible:setEnabled(Whitelist.is_permitted(UserId, "Invisible"))
		David:setEnabled(Whitelist.is_permitted(UserId, "Edgerunner"))
		--Demon:setEnabled(Whitelist.is_permitted(UserId, "Demon"))
		Jimpee:setEnabled(Whitelist.is_permitted(UserId, "Jimpee"))
		--Hornet:setEnabled(Whitelist.is_permitted(UserId, "Hornet"))

		Hide_Gebura_If_Not_Permitted()
	end)

	local NewIcon = Icon.new()
		:align("Left")
		:setLeft()
		:setOrder(1)
		:setImage("13868730298")
		:setImageScale(0.8)
		:bindEvent("selected", function()
			SoundService.GUI.BasicOpen:Play()
		end)
		:bindEvent("deselected", function()
			SoundService.GUI.BasicOpen:Play()
		end)
		:setDropdown({

			Jimpee,
			Crusader,

			Icon.new()
			:setOrder(2)
			:setImage("83786135201265")
			:setLabel("Unsealed Sorcerer")
			:modifyTheme({
				{"IconGlow", "Visible", true, "Deselected"},
			})
			:bindEvent("selected", function()
				CombatRemotes.SwitchCharacter:FireServer("Gojo", "83786135201265")
			end)
			:oneClick(),

			Icon.new()
			:setOrder(3)
			:setImage("111176988430712")
			:setLabel("Unhinged Esper")
			:modifyTheme({
				{"IconGlow", "Visible", true, "Deselected"},
				{"IconGlow", "ImageColor3", Color3.fromRGB(169, 49, 255)}
			})
			:bindEvent("selected", function()
				CombatRemotes.SwitchCharacter:FireServer("Accelerator", "111176988430712")
			end)
			:oneClick(),

			Icon.new()
			:setOrder(4)
			:setImage("105614045113235")
			:setLabel("Greatest Psychic")
			:modifyTheme({
				{"IconGlow", "Visible", true, "Deselected"},
				{"IconGlow", "ImageColor3", Color3.fromRGB(90, 255, 115)}
			})
			:bindEvent("selected", function()
				CombatRemotes.SwitchCharacter:FireServer("Reigen", "105614045113235")
			end)
			:oneClick(),

			Icon.new()
			:setOrder(5)
			:setImage("134067514540526")
			:setLabel("Unwanted God")
			:modifyTheme({
				{"IconGlow", "Visible", true, "Deselected"},
				{"IconGlow", "ImageColor3", Color3.fromRGB(255, 124, 64)}
			})
			:bindEvent("selected", function()
				CombatRemotes.SwitchCharacter:FireServer("Kratos", "134067514540526")
			end)
			:oneClick(),

			Icon.new()
			:setOrder(6)
			:setImage("85316557846229")
			:setLabel("Cursed Child")
			:modifyTheme({
				{"IconGlow", "Visible", true, "Deselected"},
				{"IconGlow", "ImageColor3", Color3.fromRGB(181, 53, 53)}
			})
			:bindEvent("selected", function()
				CombatRemotes.SwitchCharacter:FireServer("Chara", "85316557846229")
			end)
			:oneClick()
			:updateHideOnTagChanged(Player, "CharaAccess"),

			Icon.new()
			:setOrder(7)
			:setImage("121021627605403")
			:setLabel("Godly Highschooler")
			:modifyTheme({
				{"IconGlow", "Visible", true, "Deselected"},
				{"IconGlow", "ImageColor3", Color3.fromRGB(8, 140, 255)}
			})
			:bindEvent("selected", function()
				CombatRemotes.SwitchCharacter:FireServer("Mori", "121021627605403")
			end)
			:oneClick(),

			Icon.new()
			:setOrder(8)
			:setImage("130648638148519")
			:setLabel("Living Blade")
			:modifyTheme({
				{"IconLabel", "TextColor3", Color3.fromRGB(152, 152, 152)},
				{"IconGlow", "Visible", true, "Deselected"},
				{"IconGlow", "ImageColor3", Color3.fromRGB(232, 56, 255)}
			})
			:bindEvent("selected", function()
				CombatRemotes.SwitchCharacter:FireServer("Anubis", "130648638148519")
			end)
			:oneClick(),

			Icon.new()
			:setOrder(9)
			:setImage("104251648141092")
			:setLabel("World Class Candy Maker")
			:modifyTheme({
				{"IconGlow", "Visible", true, "Deselected"},
				{"IconGlow", "ImageColor3", Color3.fromRGB(155, 223, 234)}
			})
			:bindEvent("selected", function()
				CombatRemotes.SwitchCharacter:FireServer("Walter", "104251648141092")
			end)
			:oneClick()
			:hideOnCondition(function()
				local Perms = Player:GetAttribute("PanelPermission")

				if (Perms == nil) then
					task.wait(1)
					Perms = Player:GetAttribute("PanelPermission")
				end

				return (Perms == nil or Perms == "None")
			end),

			Meaty,
			RedMist,
			Invincible,
			David,
			--Demon,
			--Hornet
		})

	NewIcon.name = "Characters"

	return NewIcon
end
