local CollectionService = game:GetService("CollectionService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local info = require(replicatedStorage.info)

local ENTRANCE = 0.35
local STACK_SPACING = 100
local HUD_SHIFT = 80
local HIGHER_UP_SHIFT = 60

local module = {}

local function getColor(percentage, keypoints)
	local left = keypoints[1]
	local value = left.Value

	for i = 1, #keypoints - 1 do
		if keypoints[i].Time <= percentage and keypoints[i + 1].Time >= percentage then
			left = keypoints[i]
			local right = keypoints[i + 1]
			local span = right.Time - left.Time
			return left.Value:Lerp(right.Value, span > 0 and (percentage - left.Time) / span or 0)
		end
	end

	return value
end

local function asAsset(id)
	if typeof(id) ~= "string" or id == "" then
		return nil
	end
	return string.find(id, "://") and id or ("rbxassetid://" .. id)
end

local function firstColour(colour)
	if typeof(colour) == "Color3" then
		return colour
	end
	if typeof(colour) == "ColorSequence" then
		return colour.Keypoints[1].Value
	end
	return nil
end

local function getMoveset(speaker)
	if typeof(speaker) ~= "Instance" then
		return nil
	end

	local player = Players:GetPlayerFromCharacter(speaker)
	if not player then
		return nil
	end

	local replication = player:FindFirstChild("Replication")
	local current = replication and replication:GetAttribute("CurrentCharacter")
		or player:GetAttribute("Character")

	local movesets = info.movesets

	return (movesets and typeof(current) == "string") and movesets[string.lower(current)] or nil
end

local function getName(speaker)
	if typeof(speaker) == "string" then
		return speaker
	end

	local player = Players:GetPlayerFromCharacter(speaker)
	if player then
			return player:GetAttribute("Name") or player.DisplayName
	end

	local humanoid = speaker:FindFirstChildWhichIsA("Humanoid")
	return (humanoid and humanoid.DisplayName ~= "" and humanoid.DisplayName) or speaker.Name
end

local function scaleUDim2(udim, widthMult, heightMult)
	return UDim2.new(
		udim.X.Scale * widthMult,
		udim.X.Offset * widthMult,
		udim.Y.Scale * heightMult,
		udim.Y.Offset * heightMult
	)
end

local function easeOutQuad(t)
	return 1 - math.pow(1 - t, 2)
end

local function pulseIcon(imageLabel, originalSize, idle, speaking)
	if not imageLabel or not imageLabel.Parent then return end

	local r = Random.new()
	local sx = 1.15 + r:NextNumber() * 0.05
	local sy = 0.85 + r:NextNumber() * 0.05

	local tweenIn = TweenService:Create(imageLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = scaleUDim2(originalSize, sx, sy)
	})

	local tweenOut = TweenService:Create(imageLabel, TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
		Size = originalSize
	})

	if speaking then
		imageLabel.Image = speaking
	end

	tweenIn:Play()

	local connection
	connection = tweenIn.Completed:Connect(function()
		connection:Disconnect()
		tweenOut:Play()

		task.delay(0.7, function()
			if idle and imageLabel and imageLabel.Parent then
				imageLabel.Image = idle
			end
		end)
	end)
end

-- Break the current line apart instead of fading it, so a new line landing on
-- top of an old one reads as an interruption.
local function retireTexts(parent)
	local layout = parent:FindFirstChildWhichIsA("UIGridStyleLayout")
	if layout then layout:Destroy() end

	local rng = Random.new()

	for _, entry in parent:GetChildren() do
		if (entry.Name == "letter" or entry:GetAttribute("RetireMe")) and not entry:GetAttribute("Ending") then
			entry:SetAttribute("Ending", true)

			local distance = rng:NextNumber(40, 120)
			local angle = rng:NextNumber(0, math.pi * 2)
			local duration = rng:NextNumber(0.4, 0.75)
			local stagger = rng:NextNumber(0, 0.15)

			local endPos = entry.Position + UDim2.new(
				0, math.cos(angle) * distance,
				0, math.sin(angle) * distance + rng:NextNumber(40, 100)
			)
			local endRot = entry.Rotation + rng:NextNumber(-360, 360)

			task.delay(stagger, function()
				if not entry or not entry.Parent then return end

				local props = { Position = endPos, Rotation = endRot }

				if entry:IsA("TextLabel") then
					props.TextTransparency = 1
					props.TextStrokeTransparency = 1
					props.TextSize = entry.TextSize * rng:NextNumber(0.4, 1.8)
				elseif entry:IsA("ImageLabel") then
					props.ImageTransparency = 1
					props.Size = scaleUDim2(entry.Size, rng:NextNumber(0.5, 1.5), rng:NextNumber(0.5, 1.5))
				end

				local tween = TweenService:Create(entry, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
				tween:Play()
				tween.Completed:Connect(function()
					entry:Destroy()
				end)
			end)
		end
	end
end

-- Holder drifts to its stack slot rather than snapping, and rides the combat
-- HUD so a subtitle never sits on top of it.
local function startFloating(ui, holder)
	if ui:GetAttribute("IsFloating") then return end
	ui:SetAttribute("IsFloating", true)

	local baseY = ui:GetAttribute("BaseAnchorY")
	ui:SetAttribute("CurrentY", baseY - STACK_SPACING * (ui:GetAttribute("StackCount") or 0))

	task.spawn(function()
		local elapsed = 0

		while not ui.Parent do task.wait() end

		while ui.Parent and ui.Name ~= "deleting" do
			local dt = task.wait(0.03)
			elapsed += dt

			if not holder.Parent then return end

			local hud = LocalPlayer.PlayerGui:FindFirstChild("CombatHotbar")
			local shift = (hud and not hud.Enabled) and HUD_SHIFT or 0

			local targetY = baseY
				- STACK_SPACING * (ui:GetAttribute("StackCount") or 0)
				- (ui:GetAttribute("HigherUp") and HIGHER_UP_SHIFT or 0)
				+ shift

			local currentY = ui:GetAttribute("CurrentY") or targetY
			currentY += (targetY - currentY) * math.min(dt * 12, 1)
			ui:SetAttribute("CurrentY", currentY)

			holder.Position = UDim2.new(
				holder.Position.X.Scale,
				holder.Position.X.Offset,
				holder.Position.Y.Scale,
				currentY + math.sin(elapsed * 3) * 3
			)
		end
	end)
end

local function doText(speaker, words, appearance, lifetime, customIcon, customColour)
	if not LocalPlayer:GetAttribute("Dialogue") then
		return function() end
	end

	local template = script:FindFirstChild("subtitleDialogue")
	if not template then
		warn("TekrinnDialogue: subtitleDialogue template is missing")
		return function() end
	end

	local moveset = getMoveset(speaker)
	local speakerName = getName(speaker)
	local head = words[1] or {}

	lifetime = lifetime or 3

	local idleIcon = asAsset(customIcon) or asAsset(head.Image) or asAsset(moveset and moveset.icon)
	local speakIcon = asAsset(moveset and moveset.iconSpeak) or idleIcon

	local colour = customColour or head.Color or (moveset and moveset.colour) or ColorSequence.new(Color3.new(1, 1, 1))
	local nameColour = firstColour(appearance and appearance.Color) or firstColour(colour) or Color3.new(1, 1, 1)

	local uiName = speakerName .. "SubtitleDialogue"
	local ui = LocalPlayer.PlayerGui:FindFirstChild(uiName) or template:Clone()

	local holder = ui:WaitForChild("Holder")
	local main = holder:WaitForChild("Template")
	local imageLabel = main:WaitForChild("ImageLabel")
	local nameText = main:WaitForChild("NameText")

	local stale = LocalPlayer.PlayerGui:FindFirstChild("deleting")
	if stale then stale:Destroy() end

	nameText.Text = speakerName
	nameText.TextColor3 = nameColour
	if appearance and appearance.StrokeColor then
		nameText.TextStrokeColor3 = appearance.StrokeColor
	end

	ui:SetAttribute("HigherUp", head.HigherUp == true)

	if not ui:GetAttribute("BaseAnchorY") then
		ui:SetAttribute("BaseAnchorY", holder.Position.Y.Offset)
	end

	if not ui:GetAttribute("OriginalIconSize") then
		if head.ExtraImageSize then
			imageLabel.Size += head.ExtraImageSize
		end
		ui:SetAttribute("OriginalIconSize", imageLabel.Size)
	end
	local originalIcon = ui:GetAttribute("OriginalIconSize")

	local created = ui:GetAttribute("Created")

	if not created then
		ui:SetAttribute("StackCount", #CollectionService:GetTagged("DialogueUI"))
	end

	startFloating(ui, holder)

	local cancelled = false

	if not created then
		-- snap to the stack slot before the entrance tweens, or it flies in
		-- from wherever the template happened to sit
		holder.Position = UDim2.new(
			holder.Position.X.Scale, holder.Position.X.Offset,
			holder.Position.Y.Scale, ui:GetAttribute("CurrentY")
		)

		if idleIcon then imageLabel.Image = idleIcon end

		imageLabel.Position -= UDim2.fromOffset(0, 100)
		imageLabel.ImageTransparency = 1

		nameText.Position -= UDim2.fromOffset(0, 100)
		nameText.TextTransparency = 1
		nameText.TextStrokeTransparency = 1

		local entrance = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

		TweenService:Create(imageLabel, entrance, {
			Position = imageLabel.Position + UDim2.fromOffset(0, 100),
			ImageTransparency = 0
		}):Play()

		TweenService:Create(nameText, entrance, {
			Position = nameText.Position + UDim2.fromOffset(0, 100),
			TextTransparency = 0,
			TextStrokeTransparency = 0
		}):Play()

		ui:SetAttribute("Created", os.clock())
		ui:SetAttribute("Lifetime", lifetime)

		task.spawn(function()
			repeat
				task.wait()
			until cancelled
				or not ui.Parent
				or os.clock() - ui:GetAttribute("Created") > ui:GetAttribute("Lifetime")

			ui.Name = "deleting"

			imageLabel:SetAttribute("RetireMe", true)
			nameText:SetAttribute("RetireMe", true)
			retireTexts(main)

			task.delay(1, function()
				if ui then ui:Destroy() end
			end)
		end)
	else
		-- a live bar being handed a new line: reset its clock rather than
		-- stacking a second copy on top of it
		ui:SetAttribute("Created", os.clock())
		ui:SetAttribute("Lifetime", lifetime)
	end

	ui.Name = uiName
	ui.Parent = LocalPlayer.PlayerGui
	ui.Enabled = true
	CollectionService:AddTag(ui, "DialogueUI")

	retireTexts(main)

	local totalWidth = 0
	for _, segment in words do
		local font = segment.Bold and Enum.Font.SourceSansBold
			or segment.Italic and Enum.Font.SourceSansItalic
			or Enum.Font.SourceSans

		for _, letter in string.split(segment.Text, "") do
			totalWidth += TextService:GetTextSize(letter, 25, font, Vector2.new(100, 100)).X
		end
	end

	local vowels = { a = true, e = true, i = true, o = true, u = true }
	local lastWasVowel = false
	local cursor = 0
	local delayed = 0

	for _, segment in words do
		local weight = segment.Bold and Enum.FontWeight.Bold or Enum.FontWeight.Regular
		local style = segment.Italic and Enum.FontStyle.Italic or Enum.FontStyle.Normal
		local visualFont = Font.new("rbxasset://fonts/families/SourceSansPro.json", weight, style)

		-- GetTextSize still wants the old enum, so the two fonts have to be
		-- kept side by side: one to measure with, one to draw with
		local mathFont = segment.Bold and Enum.Font.SourceSansBold
			or segment.Italic and Enum.Font.SourceSansItalic
			or Enum.Font.SourceSans

		local shake = segment.Shake or {}
		local shakeEnabled = shake.Enabled or false
		local shakeLooped = shake.Looped or false
		local shakeIntensity = shake.Intensity or 2
		local shakeLifetime = shake.Lifetime or 1

		local wavyTable = type(segment.Wavy) == "table" and segment.Wavy or nil
		local wavyEnabled = wavyTable and (wavyTable.Enabled or false) or segment.Wavy == true
		local wavyLooped = wavyTable and (wavyTable.Looped or false) or segment.Wavy == true
		local wavyIntensity = wavyTable and (wavyTable.Intensity or 6) or 6
		local wavyLifetime = wavyTable and (wavyTable.Lifetime or 1) or 1

		local keypoints = (segment.Color or colour).Keypoints
		local strokeColour = segment.TextStrokeColor or Color3.new(0, 0, 0)

		for _, letter in string.split(segment.Text, "") do
			local size = TextService:GetTextSize(letter, 25, mathFont, Vector2.new(100, 100))
			local offsetX = cursor - totalWidth / 2 + size.X / 2
			local restPos = UDim2.new(0.5, offsetX, 0.5, 0)
			local columnPhase = cursor * 0.05

			local label = Instance.new("TextLabel")
			label.Name = "letter"
			label.AnchorPoint = Vector2.new(0.5, 0.5)
			label.Position = restPos + UDim2.fromOffset(0, 15)
			label.Rotation = math.random(-25, 25)
			label.Size = UDim2.fromOffset(size.X, size.Y)
			label.Text = letter
			label.FontFace = visualFont
			label.TextSize = 25
			label.BackgroundTransparency = 1
			label.TextStrokeColor3 = strokeColour
			label.TextStrokeTransparency = 1
			label.TextTransparency = 1
			label.ZIndex = 10
			label.Parent = main

			-- pulse the icon on the first vowel of each syllable, which is
			-- close enough to a mouth opening to read as speech
			local isVowel = vowels[string.lower(letter)] ~= nil
			local shouldPulse = isVowel and not lastWasVowel
			lastWasVowel = letter ~= " " and isVowel

			task.delay(delayed, function()
				if shouldPulse then
					pulseIcon(imageLabel, originalIcon, idleIcon, speakIcon)
				end

				local started = os.clock()

				repeat
					local now = os.clock()
					local progress = math.min((now - started) / ENTRANCE, 1)

					local intensity = 0
					if shakeEnabled then
						intensity = shakeLooped and shakeIntensity
							or shakeIntensity * (1 - math.min((now - started) / shakeLifetime, 1))
					end

					local shakeAdd = UDim2.fromOffset(
						intensity > 0 and math.random(-intensity, intensity) or 0,
						intensity > 0 and math.random(-intensity, intensity) or 0
					)

					local wave = 0
					if wavyEnabled then
						local amount = wavyLooped and wavyIntensity
							or wavyIntensity * (1 - math.min((now - started) / wavyLifetime, 1))
						wave = math.sin(now * 6 + columnPhase) * amount
					end

					if segment.Rainbow then
						label.TextColor3 = Color3.fromHSV((now * 0.5 + cursor * 0.002) % 1, 0.85, 1)
					else
						label.TextColor3 = getColor(progress, keypoints)
					end

					local eased = 1 - easeOutQuad(progress)

					label.TextStrokeTransparency = (1 - progress) ^ 10
					label.TextTransparency = eased
					label.TextSize = 25 + 25 * eased

					if not label:GetAttribute("Ending") then
						label.Rotation = math.random(-25, 25) * eased
						label.Position = restPos + UDim2.fromOffset(0, 15 * eased + wave) + shakeAdd
					end

					task.wait()
				until os.clock() - started > math.max(ENTRANCE, shakeLifetime, wavyLifetime)
					or not label:IsDescendantOf(ui)
					or label:GetAttribute("Ending")

				if label:GetAttribute("Ending") or not label:IsDescendantOf(ui) then
					return
				end

				label.TextStrokeTransparency = 0
				label.TextTransparency = 0
				label.TextSize = 25
				label.Rotation = 0
				label.Position = restPos

				local restColour = keypoints[#keypoints].Value
				if not segment.Rainbow and not (shakeEnabled and shakeLooped) and not (wavyEnabled and wavyLooped) then
					label.TextColor3 = restColour
					return
				end

				-- only the looping effects need a thread past the entrance
				task.spawn(function()
					while label.Parent and not label:GetAttribute("Ending") do
						local now = os.clock()
						local x, y = 0, 0

						if wavyEnabled and wavyLooped then
							y += math.sin(now * 6 + columnPhase) * wavyIntensity
						end

						if shakeEnabled and shakeLooped then
							x += math.random(-shakeIntensity, shakeIntensity)
							y += math.random(-shakeIntensity, shakeIntensity)
						end

						label.Position = restPos + UDim2.fromOffset(x, y)
						label.TextColor3 = segment.Rainbow
							and Color3.fromHSV((now * 0.5 + cursor * 0.002) % 1, 0.85, 1)
							or restColour

						task.wait()
					end
				end)
			end)

			cursor += size.X
			delayed += segment.TypeSpeed or 0.05
		end
	end

	return function()
		cancelled = true
	end
end

-- Speak(speaker, words, lifetime, icon, colour)  -- one line, styled segments
-- Speak(speaker, data, appearance, lifetime)     -- one segment, older shape
function module.Speak(speaker, words, a, b, c)
	if typeof(words) ~= "table" then
		return function() end
	end

	if typeof(words.Text) == "string" then
		words = { words }
	end

	if #words == 0 then
		return function() end
	end

	if typeof(a) == "table" then
		return doText(speaker, words, a, b)
	end

	return doText(speaker, words, nil, a, b, c)
end

return module
