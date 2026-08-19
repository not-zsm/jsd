local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Animations = ReplicatedStorage.Animations
local Emotes = Animations.Emotes

local Dancer = script.Parent
local Humanoid = Dancer:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local CurrentEmote

local function Dance()
	local ChosenEmote = Utility.PickRandom(Emotes:GetChildren(), function(Item)
		return typeof(Item) == "Instance" and Item:IsA("Animation")
	end)

	if ChosenEmote then
		if CurrentEmote then
			CurrentEmote:Stop()
		end
		
		CurrentEmote = Animator:LoadAnimation(ChosenEmote)
		CurrentEmote.Looped = true
		CurrentEmote:Play()
	end
	
	task.delay(30, Dance)
end

Dance()