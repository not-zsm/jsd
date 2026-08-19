local TweenService = game:GetService("TweenService")

local GradientEffect = {}
GradientEffect.__index = GradientEffect

-- Constructor for GradientEffect
function GradientEffect.new(uiElement : UIGradient, offsetTime : number, direction : Vector2)
	assert(uiElement, "A UI element is required.")
	assert(uiElement:IsA("UIGradient"), "uiElement must be a UIGradient instance.")

	local self = setmetatable({}, GradientEffect)

	self.uiElement = uiElement
	self.offsetTime = offsetTime or 3 -- Default speed
	self.direction = direction or Vector2.new(1, 0) -- Default direction
	self.tweenInfo = TweenInfo.new(self.offsetTime, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
	self.startingPos = Vector2.new(-1, 0)
	self.uiElement.Offset = self.startingPos
	self.isAnimating = false -- Animation State

	return self
end

function GradientEffect:GradientAvailable()
	return (self.uiElement ~= nil and self.uiElement.Parent ~= nil)
end

-- Start the animation
function GradientEffect:Animate()
	if self.isAnimating then 
		warn("Gradient is already animated")
		return
	end

	self.isAnimating = true
	local targetOffset = {Offset = self.direction}
	local tween = TweenService:Create(self.uiElement, self.tweenInfo, targetOffset)

	local function loopAnimation()
		while self.isAnimating and self:GradientAvailable()  do
			tween:Play()
			tween.Completed:Wait()
			self.uiElement.Offset = self.startingPos
		end
	end

	task.spawn(loopAnimation)
end

-- Stop the animation
function GradientEffect:Stop()
	self.isAnimating = false
end

return GradientEffect