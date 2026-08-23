local Gui = script.Parent
local Label = Gui:WaitForChild("Title")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GradientEffect = require( ReplicatedStorage.modules.shared.Utilities.GradientEffect )

local NewGradient = GradientEffect.new(Label.UIGradient, Gui:GetAttribute("GradientOffsetTime"))
NewGradient:Animate()