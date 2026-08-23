--- Titles, was a LocalScript under StarterPlayerScripts. Body unchanged.
return {
	Name = "Titles",
	Priority = 100,
	Async = true,

	Start = function()
		-- Services

		local replicatedStorage = game:GetService("ReplicatedStorage")
		local TextChatService = game:GetService("TextChatService")
		local Players = game:GetService("Players")
		local RunService = game:GetService("RunService")

		local TitleData = require(replicatedStorage.modules.shared.Game.TitleData)
		local network = require(replicatedStorage.modules.network)

		local LocalPlayer = Players.LocalPlayer

		-- GUI Variables

		local playerGui = LocalPlayer.PlayerGui
		local settingsGui = playerGui:WaitForChild("Settings", 100)

		local holder = settingsGui:WaitForChild("Holder")
		local titleEditor = holder:WaitForChild("TitleEditor")

		local unlockedTemplate = titleEditor:WaitForChild("UnlockedTemplate")
		local lockedTemplate = titleEditor:WaitForChild("LockedTemplate")

		local titlesList = titleEditor:WaitForChild("TitlesList")

		-- Remotes
		local remotes = replicatedStorage.Remotes
		local groupRank = 0

		local titlesArray = {}
		for Name, Data in pairs(TitleData.KillTitles) do
			table.insert(titlesArray, {name = Name, requirement = Data.requirement, color = Data.color})
		end

		-- Sort the array by the Requirement field
		table.sort(titlesArray, function(a, b) return a.requirement < b.requirement end)

		-- dumb functions
		function createTitleButton(titleButton : ImageButton, name : string, titleTable : {})
			local Title = titleButton:WaitForChild("Title")
			local Stroke = titleButton:WaitForChild("Stroke")

			titleButton.Name = name
			Title.Text = name
			Stroke.Text = name

			local DefaultFont = TitleData.DefaultSettings.font
			local FontData = titleTable.font or {}

			if (typeof(titleTable.color) == "ColorSequence") then
				titleButton.Title.UIGradient.Color = titleTable.color

			elseif (typeof(titleTable.color) == "Color3") then
				titleButton.Title.UIGradient.Color = ColorSequence.new(titleTable.color)
			end

			if FontData.FontFace and tonumber(FontData.FontFace) then
				Title.FontFace = Font.fromId(FontData.FontFace)
				Stroke.FontFace = Font.fromId(FontData.FontFace)
			else
				Title.Font = FontData.FontFace or DefaultFont.FontFace
				Stroke.Font = FontData.FontFace or DefaultFont.FontFace
			end

			Title.FontFace.Weight = FontData.FontWeight or DefaultFont.FontWeight
			Stroke.FontFace.Weight = FontData.FontWeight or DefaultFont.FontWeight

			Stroke.UIStroke.Color = FontData.StrokeColor or DefaultFont.StrokeColor
			Stroke.UIStroke.Thickness = FontData.StrokeSize or DefaultFont.StrokeSize

			titleButton.Visible = true

			if titleButton:GetAttribute("Locked") == false then
				-- On Player Click
				titleButton.MouseButton1Click:Connect(function()
					if name == "NO TITLE" then -- Player selects NO TITLE button
						network.unequipTitle.send()
					else
						network.equipTitle.send(name)
					end
				end)
			end

			titleButton.Parent = titlesList
		end

		function updateTitles(totalKills, groupRank)
			totalKills = tonumber(totalKills)
			-- Insert "None" Title

			task.spawn(createTitleButton, unlockedTemplate:Clone(), "NO TITLE", {color = Color3.fromRGB(255, 255, 255)})

			-- Custom Titles
			for name, title in TitleData.CustomTitles do
				local accessIds = title.accessIds
				local access = title.access

				if (accessIds and table.find(accessIds, LocalPlayer.UserId)) or (access and table.find(access, LocalPlayer.Name)) then
					task.spawn(createTitleButton, unlockedTemplate:Clone(), name, title)
				end
			end

			-- Group Titles
			for name, title in TitleData.GroupTitles do
				local requirement = title.requirement

				if typeof(requirement) == "table" then
					if table.find(requirement, groupRank) then
						task.spawn(createTitleButton, unlockedTemplate:Clone(), name, title)
					end
				else
					if requirement == groupRank then
						task.spawn(createTitleButton, unlockedTemplate:Clone(), name, title)
					end
				end
			end

			-- Kill Titles
			for index, title in titlesArray do
				local name = title.name
				local killsTitleButton

				if totalKills >= title.requirement then
					killsTitleButton = unlockedTemplate:Clone()
				else
					task.spawn(function()
						killsTitleButton = lockedTemplate:Clone()

						local Requirement = killsTitleButton:WaitForChild("Requirement")
						Requirement.Label.Text = `🔒{title.requirement} Kills`

						-- Attach Hover Script
						killsTitleButton.MouseEnter:Connect(function()
							if Requirement then
								Requirement.Visible = true
							end
						end)

						killsTitleButton.MouseLeave:Connect(function()
							if Requirement then
								Requirement.Visible = false
							end
						end)
					end)
				end

				task.spawn(createTitleButton, killsTitleButton, name, title)
			end
		end

		network.playerKilled.listen(function(data)
			local totalKills = data.totalKills
			for _, titleButton in ipairs(titlesList:GetChildren()) do
				if titleButton:IsA("ImageButton") then
					titleButton:Destroy()
				end
			end

			updateTitles(totalKills, groupRank)
		end)

		network.loadTitles.listen(function(data)
			local totalKills, servergroupRank = data.kills, data.groupRank
			groupRank = servergroupRank
			updateTitles(totalKills, groupRank)
		end)

		local NameColors = require( script.NameColors )
		--local Observer = require( replicatedStorage.Packages.Observer )

		--task.defer(function()
		--	Observer.observe_tag("Disguise", function(Player : Player)
		--		if not Player:IsA("Player") then return end

		--		local Connection: RBXScriptConnection;

		--		local function Reparent(Parent)
		--			Player.Parent = Parent
		--		end

		--		if LocalPlayer ~= Player then 
		--			Connection = RunService.PreRender:Connect(function(dt)
		--				pcall(Reparent, nil);
		--			end);
		--		end;
		
		--		return function()
		--			if LocalPlayer ~= Player then 
		--				pcall(Reparent, Players);
		--			end;

		--			if Connection and Connection.Connected then
		--				Connection:Disconnect();
		--			end;
		--		end;
		--	end);
		--end);

		-- Prefix Listen Event
		TextChatService.OnIncomingMessage = function(TextChatMessage : TextChatMessage)
			if TextChatMessage.TextSource then
				local player = Players:GetPlayerByUserId(TextChatMessage.TextSource.UserId)
				local character = player.Character

				if (character ~= nil) then
					local humanoid = character:FindFirstChild("Humanoid")
					local head = character:WaitForChild("Head")

					if (humanoid == nil) or (head == nil) then return end
			
					local Name : string? = player:GetAttribute("Name")
			
					if (Name ~= nil and player:GetAttribute("UseNameAttributeForTextColor")) then
						local new_name_color = NameColors(Name)
						local updated_prefix_text = `<font color='#{new_name_color:ToHex()}'>{humanoid.DisplayName}:</font>`

						local TitleGui = head:FindFirstChild("Title")

						if (TitleGui ~= nil and TitleGui:GetAttribute("ChatPrefix")) then
							local Color : Color3 = TitleGui:GetAttribute("Color") or Color3.fromRGB(255, 255, 255)
							local Title : TextLabel = TitleGui:FindFirstChild("Title")

							if Title then
								local props = Instance.new("TextChatMessageProperties")
								props.PrefixText = `<font color='#{Color:ToHex()}'>[{Title.Text}]</font> {updated_prefix_text}`
								return props
							end
						end

						local props = Instance.new("TextChatMessageProperties")
						props.PrefixText = updated_prefix_text
						return props
					else
						local TitleGui = head:FindFirstChild("Title")

						if (TitleGui ~= nil and TitleGui:GetAttribute("ChatPrefix")) then
							local Color : Color3 = TitleGui:GetAttribute("Color") or Color3.fromRGB(255, 255, 255)
							local Title : TextLabel = TitleGui:FindFirstChild("Title")

							if Title then
								local props = Instance.new("TextChatMessageProperties")
								props.PrefixText = `<font color='#{Color:ToHex()}'>[{Title.Text}]</font> {TextChatMessage.PrefixText}`
								return props
							end
						end
					end
				else
					return Instance.new("TextChatMessageProperties")
				end
			end 
		end
	end,
}
