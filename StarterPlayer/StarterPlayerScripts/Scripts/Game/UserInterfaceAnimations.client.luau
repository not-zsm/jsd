local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

require( ReplicatedStorage.Packages.UserInterface )

local Observer = require( ReplicatedStorage.Modules.Shared.Utilities.Observer )
local UserInterfaceAnimations = require( ReplicatedStorage.Modules.Shared.Utilities.UserInterfaceAnimations )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

type Button = ImageButton | TextButton

Observer("UI_ButtonClick", function(Button : Button)
	local ButtonSize = Button.Size
	
	local Settings = Button:GetAttributes()
	local ButtonPop = (Settings.ButtonPop or 1.1)
	
	local Info = TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In, 0, true)
	local NewJob = Job.new()
	
	NewJob:Task(Button.MouseButton1Down:Connect(function()
		UserInterfaceAnimations.Click(Button, ButtonPop, Info)
	end))
	
	return function()
		NewJob:Destroy()
	end
end)

Observer("UI_ButtonClickYJump", function(Button : Button)
	local ButtonPosition = Button.Position

	local Settings = Button:GetAttributes()
	local ButtonPop = (Settings.ButtonPop or 1.25)

	local Info = TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In, 0, true)

	local NewJob = Job.new()

	NewJob:Task(Button.MouseButton1Down:Connect(function()
		UserInterfaceAnimations.ClickYJump(Button, ButtonPop, Info)
	end))

	return function()
		NewJob:Destroy()
	end
end)