--== Imports ==--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Maid = require( ReplicatedStorage.Packages.Maid )

--== Types ==--
type State = {
	color: Color3,
	strokeSize: number,
	bold: boolean,
	italic: boolean,
	rainbow: boolean,
	shake: boolean,
	wave: boolean,
	noanim: boolean,
	waitTime: number,
}
type Options = {
	verbose: boolean?,
}

--== Constants ==--
local NAME_WORD_FRAME = "WORDFRAME"
local NAME_LETTER_FRAME = "LETTERFRAME"
local DEFAULT_STATE: State = {
	color = Color3.fromRGB(255, 255, 255),
	strokeSize = 2,
	bold = false,
	italic = false,
	rainbow = false,
	shake = false,
	wave = false,
	noanim = false,
	waitTime = -1,
}

--== Module ==--
local Module = {}

--== Private ==--
local function ensureListLayout(container: Instance, hAlign: Enum.HorizontalAlignment?, vAlign: Enum.VerticalAlignment?, verbose: boolean?): UIListLayout
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("UIListLayout") then
			local layout = child :: UIListLayout
			if hAlign then layout.HorizontalAlignment = hAlign end
			if vAlign then layout.VerticalAlignment = vAlign end
			return layout
		end
		if child:IsA("UIGridLayout") then
			return Instance.new("UIListLayout")
		end
	end

	local layoutTemplate = script:FindFirstChild("Assets") and script.Assets:FindFirstChild("FrameListLayout")
	local layout = layoutTemplate and layoutTemplate:Clone() or Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Wraps = true
	if hAlign then layout.HorizontalAlignment = hAlign end
	if vAlign then layout.VerticalAlignment = vAlign end
	layout.Parent = container
	return layout
end

local function makeLetterFrame(): Frame
	local fromAssets = script:FindFirstChild("Assets") and script.Assets:FindFirstChild("LetterFrame")
	if fromAssets then
		return fromAssets:Clone()
	end

	local f = Instance.new("Frame")
	f.Name = NAME_LETTER_FRAME
	f.AutomaticSize = Enum.AutomaticSize.XY
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.Visible = false
	local l = Instance.new("TextLabel")
	l.Name = "TextLabel"
	l.AutomaticSize = Enum.AutomaticSize.X
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.Size = UDim2.fromScale(0, 1)
	l.Text = ""
	l.TextWrapped = true
	l.Font = Enum.Font.Arial
	l.TextScaled = true
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Parent = f
	return f
end

export type AnimatedTextSettings = {
	animated: boolean;
}

local function simple_tween(instance: Instance, tween_info: TweenInfo, goals: {[string]: any}, text_settings: AnimatedTextSettings): ()
	if text_settings.animated then
		TweenService:Create(instance, tween_info, goals):Play()
	else
		for index, value in goals do
			instance[index] = value;
		end;
	end;
end

local function shakeText(target: TextLabel, text_settings: AnimatedTextSettings)
	while target.Parent do
		local x = 0
		local y = math.random(-2, 2)
		local r = math.random(-10, 10)
		simple_tween(target, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Position = UDim2.fromOffset(x, y), Rotation = r }, text_settings)
		task.wait(0.2)
	end
end

local function waveText(target: TextLabel, delay: number?, text_settings: AnimatedTextSettings)
	if delay then task.wait(delay) end
	while target.Parent do
		simple_tween(target, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Position = UDim2.fromOffset(0, 6) }, text_settings)
		task.wait(0.5)
		simple_tween(target, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Position = UDim2.fromOffset(0, -6) }, text_settings)
		task.wait(0.5)
	end
end

local function textAppear(target: TextLabel, mode: string?, text_settings: AnimatedTextSettings)
	if not mode or type(mode) ~= "string" then return end

	if mode:find("fade") then
		target.TextTransparency = 1
		simple_tween(target, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 })
	end

	if mode:find("up") then
		target.Position = UDim2.fromOffset(0, 16);
		simple_tween(target, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, 0) }, text_settings)
	elseif mode:find("down") then
		target.Position = UDim2.fromOffset(0, -16)
		simple_tween(target, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, 0) }, text_settings)
	elseif mode:find("diverge") then
		target.Position = UDim2.fromOffset(0, math.random(-5, 5))
		simple_tween(target, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, 0) }, text_settings)
	elseif mode:find("sizeright") then
		target.Size = UDim2.new(4, 0, 1, 0)
		target.TextXAlignment = Enum.TextXAlignment.Right
		simple_tween(target, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 1, 1, 1) }, text_settings)
	end

	if mode:find("rotate") then
		target.Rotation = 90
		simple_tween(target, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Rotation = 0 }, text_settings)
	elseif mode:find("rotright") then
		target.Rotation = -90
		simple_tween(target, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Rotation = 0 }, text_settings)
	elseif mode:find("shake") then
		target.Rotation = math.random(-30, 30)
		simple_tween(target, TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), { Rotation = 0 }, text_settings)
	elseif mode:find("rotultra") then
		target.Rotation = 360
		simple_tween(target, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Rotation = 0 }, text_settings)
	end
end

local function rainbowText(target: TextLabel, offset: number, phase: number?)
	local start = os.clock() + (phase or 0)
	while target.Parent do
		local hue = (os.clock() - start + offset / 255) % 1
		target.TextColor3 = Color3.fromHSV(hue, 1, 1)
		task.wait(0.05)
	end
end

local function pushState(stack: {State}, updater: (State) -> State)
	local base = stack[#stack]
	local copy: State = {
		color = base.color,
		strokeSize = base.strokeSize,
		bold = base.bold,
		italic = base.italic,
		rainbow = base.rainbow,
		shake = base.shake,
		wave = base.wave,
		noanim = base.noanim,
		waitTime = base.waitTime,
	}
	local nextState = updater(copy)
	table.insert(stack, nextState)
end

local function popState(stack: {State})
	if #stack > 1 then
		table.remove(stack)
	end
end

local container_text_settings = {};
local basic_setting = table.freeze{ animated = true };

--== Public ==--
function Module.AnimateText(text: string, container: Instance, delayTime: number?, font: Enum.Font?, mode: string?, wordMode: number?, textSize: number?, hAlign: Enum.HorizontalAlignment?, vAlign: Enum.VerticalAlignment?, extra: Instance | {Instance}? , verbose: boolean?)
	ensureListLayout(container, hAlign, vAlign, verbose)

	local stateStack: {State} = {DEFAULT_STATE}
	local i = 1
	local wrapByWord = (wordMode == 1) or (wordMode == nil)
	local word = {}
	local wordContainer: Frame? = nil

	local simpleTags = {
		["<red>"] = function(s: State) s.color = Color3.fromRGB(255, 0, 0); return s end,
		["<blue>"] = function(s: State) s.color = Color3.fromRGB(0, 0, 255); return s end,
		["<bold>"] = function(s: State) s.bold = true; return s end,
		["<italic>"] = function(s: State) s.italic = true; return s end,
		["<rainbow>"] = function(s: State) s.rainbow = true; return s end,
		["<shake>"] = function(s: State) s.shake = true; return s end,
		["<wave>"] = function(s: State) s.wave = true; return s end,
		["<noanim>"] = function(s: State) s.noanim = true; return s end,
	}
	
	local base_part = container:FindFirstAncestorWhichIsA("BasePart");
	local text_settings: AnimatedTextSettings = basic_setting;
	
	if base_part then
		
		if container_text_settings[base_part] then
			text_settings = container_text_settings[base_part];
		else
			text_settings = {
				animated = not base_part:GetAttribute("DisableTextAnimation");
				maid = Maid.new();
			};
			
			text_settings.maid:add(base_part:GetAttributeChangedSignal("DisableTextAnimation"):Connect(function()
				text_settings.animated = not base_part:GetAttribute("DisableTextAnimation")
			end));
			
			text_settings.maid:add(base_part.AncestryChanged:Once(function()
				text_settings.maid:destroy();
				text_settings.animated = false;
				
				container_text_settings[base_part] = nil;
			end));
			
			container_text_settings[base_part] = text_settings;
		end;
	end
	
	while i <= #text do
		local ch = string.sub(text, i, i)

		if wrapByWord then
			if #word == 0 then
				local wf = Instance.new("Frame")
				wf.Name = NAME_WORD_FRAME
				wf.AutomaticSize = Enum.AutomaticSize.XY
				wf.Size = UDim2.new(0, 0, 0, 1)
				wf.BackgroundTransparency = 1
				wf.Parent = container
				local ll = Instance.new("UIListLayout")
				ll.FillDirection = Enum.FillDirection.Horizontal
				ll.Parent = wf
				wordContainer = wf
			end

			if ch == " " then
				table.clear(word)
			else
				table.insert(word, ch)
			end
		end

		if ch == "<" then
			local advanced = false

			if string.sub(text, i, i + 1) == "</" then
				popState(stateStack)
				local closeIndex = string.find(text, ">", i)
				i = (closeIndex or i) + 1
				advanced = true
			elseif string.sub(text, i, i + 7) == "<color=#" then
				local hex = string.sub(text, i + 8, i + 13)
				if #hex == 6 then
					pushState(stateStack, function(s) s.color = Color3.fromHex(hex); return s end)
				end
				local closeIndex = string.find(text, ">", i)
				i = (closeIndex or i) + 1
				advanced = true
			elseif string.sub(text, i, i + 6) == "<pause=" then
				local closeIndex = string.find(text, ">", i)
				local num = tonumber(string.sub(text, i + 7, (closeIndex or i) - 1))
				if num then
					pushState(stateStack, function(s) s.waitTime = num; return s end)
				end
				i = (closeIndex or i) + 1
				advanced = true
			else
				for tag, mutator in pairs(simpleTags) do
					if string.sub(text, i, i + #tag - 1) == tag then
						pushState(stateStack, mutator)
						i += #tag
						advanced = true
						break
					end
				end
			end

			if advanced then
				continue
			end
		end

		local letterFrame = makeLetterFrame()
		local label = letterFrame:FindFirstChild("TextLabel") :: TextLabel
		label.Text = ch

		local current = stateStack[#stateStack]
		if font then
			label.Font = font
		else
			label.Font = Enum.Font.Arial
		end

		if current.shake then
			task.spawn(shakeText, label, text_settings)
		elseif current.wave then
			if delayTime == 0 then
				task.spawn(waveText, label, i / 10, text_settings)
			else
				task.spawn(waveText, label, nil, text_settings)
			end
		end

		if current.rainbow then
			task.spawn(rainbowText, label, i * 5, i)
		else
			label.TextColor3 = current.color
		end

		if current.bold then
			label.RichText = true
			label.Text = "<b>" .. ch .. "</b>"
		end

		if current.italic then
			label.RichText = true
			label.Text = "<i>" .. label.Text .. "</i>"
		end

		if textSize then
			label.TextScaled = false
			label.TextSize = textSize
			letterFrame.AutomaticSize = Enum.AutomaticSize.XY
		end

		if typeof(extra) == "table" then
			for _, inst in pairs(extra :: {Instance}) do
				inst:Clone().Parent = label
			end
		elseif extra and typeof(extra) == "Instance" then
			(extra :: Instance):Clone().Parent = label
		end

		if not current.noanim then
			textAppear(label, mode, text_settings)
		end

		letterFrame.Name = NAME_LETTER_FRAME
		letterFrame.Visible = true
		if wrapByWord then
			letterFrame.Parent = wordContainer
		else
			letterFrame.Parent = container
		end

		i += 1

		local top = stateStack[#stateStack]
		if top.waitTime > 0 then
			task.wait(top.waitTime)
		elseif top.waitTime == 0 then
		elseif delayTime ~= 0 then
			task.wait(delayTime or 0.05)
		elseif delayTime == 0 then
		else
			task.wait(0.05)
		end;
	end;
end

function Module.ClearText(container: Instance)
	if not container then
		return
	end
	for _, child in ipairs(container:GetChildren()) do
		if child.Name == NAME_WORD_FRAME or child.Name == NAME_LETTER_FRAME then
			child:Destroy()
		end
	end
end

--== Return ==--
return Module