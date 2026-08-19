local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local highlightUtil = {}

highlightUtil.tweenHighlight = function(
	model: Model,
	fillColor: Color3?,
	outlineColor: Color3?,
	duration: number?,
	depthMode: Enum.HighlightDepthMode?,
	fadeDirection: "In" | "Out"?,
	initialFillTransparency: number?)

	local highlightDuration = duration or 1
	local highlight = Instance.new("Highlight")
	highlight.Adornee = model
	highlight.DepthMode = depthMode or Enum.HighlightDepthMode.Occluded
	highlight.FillColor = fillColor or Color3.new(1, 1, 1)
	highlight.OutlineColor = outlineColor or Color3.new(1, 1, 1)
	highlight.OutlineTransparency = 0

	local startFillTransparency: number
	local endFillTransparency: number

	if fadeDirection == "Out" then
		startFillTransparency = 1
		endFillTransparency = 0
	else
		startFillTransparency = initialFillTransparency or 0
		endFillTransparency = 1
	end

	highlight.FillTransparency = startFillTransparency
	highlight.OutlineTransparency = startFillTransparency

	highlight.Parent = model

	local tweenInfo = TweenInfo.new(highlightDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local goal = {
		FillTransparency = endFillTransparency,
		OutlineTransparency = endFillTransparency
	}
	local tween = TweenService:Create(highlight, tweenInfo, goal)
	tween:Play()

	Debris:AddItem(highlight, highlightDuration)

	return highlight
end

highlightUtil.pulseHighlight = function(
	model: Model,
	fillColor: Color3?,
	outlineColor: Color3?,
	pulseDuration: number?,
	depthMode: Enum.HighlightDepthMode?,
	repeatCount: number?,
	startTransparency: number?,
	endTransparency: number?
)
	
	local highlight = Instance.new("Highlight")
	highlight.Adornee = model
	highlight.DepthMode = depthMode or Enum.HighlightDepthMode.Occluded
	highlight.FillColor = fillColor or Color3.new(1, 1, 1)
	highlight.OutlineColor = outlineColor or Color3.new(1, 1, 1)

	local currentPulseDuration = pulseDuration or 0.5
	local currentStartTransparency = startTransparency or 0
	local currentEndTransparency = endTransparency or 1

	highlight.FillTransparency = currentStartTransparency
	highlight.OutlineTransparency = currentStartTransparency
	highlight.Parent = model

	local tweenInfoIn = TweenInfo.new(currentPulseDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local tweenInfoOut = TweenInfo.new(currentPulseDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

	local pulseGoalIn = { FillTransparency = currentEndTransparency, OutlineTransparency = currentEndTransparency }
	local pulseGoalOut = { FillTransparency = currentStartTransparency, OutlineTransparency = currentStartTransparency }

	local tweenIn = TweenService:Create(highlight, tweenInfoIn, pulseGoalIn)
	local tweenOut = TweenService:Create(highlight, tweenInfoOut, pulseGoalOut)

	local currentRepeat = 0
	local maxRepeats = repeatCount or 0

	local function doPulse()
		if not highlight or not highlight.Parent then return end

		tweenIn:Play()
		tweenIn.Completed:Wait()

		if not highlight or not highlight.Parent then return end

		tweenOut:Play()
		tweenOut.Completed:Wait()

		currentRepeat += 1
		if maxRepeats == 0 or currentRepeat < maxRepeats then
			task.spawn(doPulse)
		else
			Debris:AddItem(highlight, 0.1)
		end
	end

	task.spawn(doPulse)

	return highlight
end

highlightUtil.flashHighlight = function(
	model: Model,
	fillColor: Color3?,
	outlineColor: Color3?,
	flashDuration: number?,
	flashSpeed: number?,
	depthMode: Enum.HighlightDepthMode?,
	startTransparency: number?
)
	
	local highlight = Instance.new("Highlight")
	highlight.Adornee = model
	highlight.DepthMode = depthMode or Enum.HighlightDepthMode.Occluded
	highlight.FillColor = fillColor or Color3.new(1, 1, 1)
	highlight.OutlineColor = outlineColor or Color3.new(1, 1, 1)
	highlight.FillTransparency = startTransparency
	highlight.OutlineTransparency = startTransparency
	highlight.Parent = model

	local currentFlashSpeed = flashSpeed or 0.1
	local totalFlashDuration = flashDuration or 1

	local tweenInfoIn = TweenInfo.new(currentFlashSpeed / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweenInfoOut = TweenInfo.new(currentFlashSpeed / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	local goalVisible = { FillTransparency = startTransparency, OutlineTransparency = startTransparency }
	local goalHidden = { FillTransparency = 1, OutlineTransparency = 1 }

	local tweenShow = TweenService:Create(highlight, tweenInfoIn, goalVisible)
	local tweenHide = TweenService:Create(highlight, tweenInfoOut, goalHidden)

	local startTime = os.clock()

	local function doFlash()
		if not highlight or not highlight.Parent then return end
		if os.clock() - startTime >= totalFlashDuration then
			Debris:AddItem(highlight, 0.1)
			return
		end

		tweenShow:Play()
		tweenShow.Completed:Wait()

		if not highlight or not highlight.Parent then return end

		tweenHide:Play()
		tweenHide.Completed:Wait()

		task.spawn(doFlash)
	end

	task.spawn(doFlash)

	Debris:AddItem(highlight, totalFlashDuration + 0.5)

	return highlight
end

return highlightUtil