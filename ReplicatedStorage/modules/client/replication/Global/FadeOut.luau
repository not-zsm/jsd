-- if u want it to yield abit just put that in the tweeninfo

export type FadeData = {
	Color : Color3?,
	Tween : TweenInfo?,
}

local DEFAULT_DATA : FadeData = {
	Color = Color3.new(),
	Tween = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
}

local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui : PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Reconcile = require(replicatedStorage.packages.Table).reconcile

return function(Data : FadeData) : (() -> ())
	local fade_data : FadeData = Reconcile(Data or {}, DEFAULT_DATA)

	local screen = script.FadeScreen:Clone()
	screen.Fade.BackgroundColor3 = fade_data.Color
	screen.Parent = PlayerGui
	
	local fade_tween = TweenService:Create(screen.Fade, fade_data.Tween, {
		BackgroundTransparency = 1
	})
	
	fade_tween.Completed:Once(function()
		if (screen and screen.Parent ~= nil) then
			screen:Destroy()
		end
	end)
	
	fade_tween:Play()
	
	return function()
		fade_tween:Cancel()
		fade_tween:Destroy()
		fade_tween = nil
	end
end
