local Gui = script.Parent
local Label = Gui:WaitForChild("Title")

local replicatedStorage = game:GetService("ReplicatedStorage")
local GradientEffect = require( replicatedStorage.modules.shared.Utilities.GradientEffect )

local NewGradient = GradientEffect.new(Label.UIGradient, Gui:GetAttribute("GradientOffsetTime"))
NewGradient:Animate()