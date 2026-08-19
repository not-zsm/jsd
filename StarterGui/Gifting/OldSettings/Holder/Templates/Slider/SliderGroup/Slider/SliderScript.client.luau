local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local slider = script.Parent
local fill = slider.Fill
local trigger = slider.Trigger
local outputValue = slider.OutputValue

local tweenStyle = TweenInfo.new(0.25, Enum.EasingStyle.Exponential)

local maxValue = 1 or 100/100
local startingValue = 0 or 0/100

local sliderActive = false

fill.Size = UDim2.fromScale(50/100, 1) -- Starting Value

local function UpdateSlider()
	local output = math.clamp((Mouse.X - slider.AbsolutePosition.x) / slider.AbsoluteSize.X, 0, 1)
	local outputClamped = startingValue + (output * (maxValue - startingValue))

	if outputValue.Value ~= outputClamped then
		TweenService:Create(fill, tweenStyle, 
			{Size = UDim2.fromScale(output, 1)}
		):Play()
		
		outputValue.Value = math.round(outputClamped * 100)
	end
end

local function ActivateSlider()
	if sliderActive then return end
	
	sliderActive = true
	
	local Connection; Connection = RunService.PreAnimation:Connect(function()
		if not sliderActive then
			return Connection:Disconnect()
		end
		
		UpdateSlider()
	end)
end

trigger.MouseButton1Down:Connect(ActivateSlider)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch and sliderActive then
		sliderActive = false
	end
end)