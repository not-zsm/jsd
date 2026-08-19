local CollectionService = game:GetService("CollectionService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local module = {}

getColor = function(timeLength, points)
	local data1 = points[1]
	local allPoints = points[#points]

	local newPoint = 0.5
	local value = data1.Value

	for i = 1, #points - 1 do
		if points[i].Time <= timeLength and timeLength <= points[i + 1].Time then
			data1 = points[i]
			allPoints = points[i + 1]
			newPoint = (timeLength - data1.Time) / (allPoints.Time - data1.Time)
			return (data1.Value:lerp(allPoints.Value, newPoint))
		end
	end
	return value
end

local function EndDialogue(gui)
	for _, v in gui:GetChildren() do
		if v.Name == "letter" then
			v:SetAttribute("Ending", true)
			
			TweenService:Create(v, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = v.Position + UDim2.new(0, 0, 0, 50), 
				TextTransparency = 1, 
				TextStrokeTransparency = 1
			}):Play()
			
			TweenService:Create(v.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Transparency = 1
			}):Play()
			
			Debris:AddItem(v, 0.5)
		end
	end
end

local function CreateDialogue(model, data, appearance, life)
	if not LocalPlayer:GetAttribute("Dialogue") then 
		return function() end
	end
	
	model = model or LocalPlayer
	
	local name
	
	if model.Parent == workspace.Models then
		local player = Players:GetPlayerFromCharacter(model)
		
		if player then
			name = player:GetAttribute("Name")
		else
			name = model.Name
		end
	else
		name = model.Name
	end

	local DialogueUI = LocalPlayer.PlayerGui:FindFirstChild(name .. "CUSTOM_DIALOGUE") or script.CUSTOM_DIALOGUE:Clone()

	local Holder = DialogueUI:WaitForChild("Holder")
	local Template = Holder:WaitForChild("Template")
	local ImageLabel : ImageLabel = Template:WaitForChild("ImageLabel")
	local Name : TextLabel = Template:WaitForChild("Name")

	local posY = 0
	local posX = 0
	local Time = 0
	
	local ENDNOW = false

	if not DialogueUI:GetAttribute("Created") then
		Holder.Position = Holder.Position - UDim2.fromOffset(0, 100 * #CollectionService:GetTagged("CUSTOM_DIALOGUE"))
		ImageLabel.Position = ImageLabel.Position - UDim2.fromOffset(0, 100)
		Name.Position = Name.Position - UDim2.fromOffset(0, 100)

		if data.Image then
			ImageLabel.Image = "rbxassetid://" .. data.Image
		end

		if data.ExtraImageSize then
			ImageLabel.Size += data.ExtraImageSize
		end

		Name.TextTransparency = 1
		
		if appearance then
			Name.Gradient.Color = appearance.Color or ColorSequence.new(Color3.new(1, 1, 1))
			Name.Stroke.Color = appearance.StrokeColor or Color3.new(0, 0, 0)
		end

		TweenService:Create(ImageLabel, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = ImageLabel.Position + UDim2.fromOffset(0, 100), 
			ImageTransparency = 0
		}):Play()

		TweenService:Create(Name, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = Name.Position + UDim2.fromOffset(0, 100),
			TextTransparency = 0, 
		}):Play()
		
		TweenService:Create(Name.Stroke, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Transparency = 0
		}):Play()

		task.spawn(function()
			DialogueUI:SetAttribute("Created", os.clock())

			repeat
				task.wait()
			until (os.clock() - DialogueUI:GetAttribute("Created") > (life or 5)) or (not DialogueUI.Parent) or ENDNOW

			DialogueUI.Name = "deleting"
			EndDialogue(Template)
			
			local Info = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

			TweenService:Create(ImageLabel, Info, {
				Position = ImageLabel.Position - UDim2.fromOffset(0, 100), 
				ImageTransparency = 1
			}):Play()

			TweenService:Create(Name, Info, {
				Position = Name.Position - UDim2.fromOffset(0, 100), 
				TextTransparency = 1, 
			}):Play()
			
			TweenService:Create(Name.Stroke, Info, {
				Transparency = 1
			}):Play()

			task.delay(1, DialogueUI.Destroy, DialogueUI)
		end)
	else
		DialogueUI:SetAttribute("Created", os.clock())
	end

	DialogueUI.Name = name .. "CUSTOM_DIALOGUE"
	DialogueUI:AddTag("CUSTOM_DIALOGUE")

	Name.Text = name

	DialogueUI.Enabled = true
	DialogueUI.Parent = LocalPlayer.PlayerGui

	do
		local y_value = data.HigherUp and (1 / 1.125) or 1
		local goal = UDim2.fromScale(0.5, y_value)
		
		if Holder.Position ~= goal then
			TweenService:Create(Holder, TweenInfo.new(data.HigherUp and 0.6 or 1), {
				Position = goal
			}):Play()
		end
	end

	EndDialogue(Template)

	local split = string.split(data.Text, "")
	local font = data.Bold and Enum.Font.SourceSansBold or data.Italic and Enum.Font.SourceSansItalic or Enum.Font.SourceSans

	for _, b in split do
		posY = posY + TextService:GetTextSize(b, 25, font, Vector2.new(100, 100)).X
	end
	
	for _, b in split do
		local TextSize = TextService:GetTextSize(b, 25, font, Vector2.new(100, 100))
		
		local TextLabel = Instance.new("TextLabel")
		--local Gradient = Instance.new("UIGradient",  TextLabel)
		local Stroke = Instance.new("UIStroke",  TextLabel)
		
		local newPosY = posY
		local newPosX = posX

		TextLabel.Name = "letter"

		TextLabel.AnchorPoint = Vector2.new(0, 0.5)
		TextLabel.Position = UDim2.new(0.5, newPosX - newPosY / 2 // 1, 0.5, 10)

		TextLabel.Size = UDim2.fromOffset(TextSize.X, TextSize.Y)
		TextLabel.Font = font
		TextLabel.Text = b

		TextLabel.TextSize = 25
		TextLabel.BackgroundTransparency = 1
	
		Stroke.Color = data.TextStrokeColor

		if data.Shake then
			Stroke.Transparency = 1
			TextLabel.TextTransparency = 1

			task.delay(Time, function() 
				local osClock = os.clock()

				repeat

					local keyPointTime = math.min((os.clock() - osClock) / 0.35, 1)
					local shakeLifeTime = math.min((os.clock() - osClock) / data.Shake.Lifetime, 1)

					local currentShake = not data.Shake.Enabled and UDim2.fromOffset(0, 0) or UDim2.fromOffset(
						math.random(-data.Shake.Intensity, data.Shake.Intensity) * (1 - shakeLifeTime), 
						math.random(-data.Shake.Intensity, data.Shake.Intensity) * (1 - shakeLifeTime)
					)

					local textSettings = 1 - (1 + 2.70158 * math.pow(keyPointTime - 1, 3) + 1.70158 * math.pow(keyPointTime - 1, 2))

					Stroke.Transparency = (1 - keyPointTime) ^ 10
					TextLabel.TextTransparency = textSettings

					TextLabel.TextSize = 25 + 25 * textSettings
					TextLabel.TextColor3 = getColor(keyPointTime, data.Color.Keypoints)

					TextLabel.Position = UDim2.new(0.5, newPosX - newPosY / 2 // 1, 0.5, 0) + currentShake

					task.wait()

				until os.clock() - osClock > math.max(0.35, data.Shake.Lifetime) or not TextLabel or not TextLabel:IsDescendantOf(DialogueUI) or TextLabel:GetAttribute("Ending")

				if TextLabel then
					TextLabel.Position = UDim2.new(0.5, newPosX - newPosY / 2 // 1, 0.5, 0)
					
					TextLabel.TextSize = 25
					TextLabel.TextColor3 = data.Color.Keypoints[#data.Color.Keypoints].Value

					Stroke.Transparency = 0
					TextLabel.TextTransparency = 0
				end
			end)
		else
			TextLabel.TextColor3 = data.Color.Keypoints[#data.Color.Keypoints].Value
			
			Stroke.Transparency = 0
			TextLabel.TextTransparency = 0
		end
		
		TextLabel.Parent = Template

		Time += data.TypeSpeed
		posX += TextSize.X
	end
	
	return function()
		ENDNOW = true
	end
end

module.Speak = CreateDialogue

return module
