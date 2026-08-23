--!strict
-- Was StarterPlayerScripts/Game/UserInterfaceAnimations.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Packages.UserInterface)

local Observer = require(ReplicatedStorage.modules.shared.Utilities.Observer)
local UserInterfaceAnimations = require(ReplicatedStorage.modules.shared.Utilities.UserInterfaceAnimations)
local Job = require(ReplicatedStorage.modules.shared.Utilities.Job)

type Button = ImageButton | TextButton

local CLICK_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In, 0, true)

--[[
	Binds a click animation to every button carrying `Tag`.

	`Play` is the animation to run and `DefaultPop` the scale used when the
	button does not set a `ButtonPop` attribute of its own.
--]]
local function BindClick(Tag: string, Play: (Button, number, TweenInfo) -> (), DefaultPop: number)
	return Observer(Tag, function(Button: Button)
		local Pop = Button:GetAttribute("ButtonPop") or DefaultPop
		local NewJob = Job.new()

		NewJob:Task(Button.MouseButton1Down:Connect(function()
			Play(Button, Pop :: number, CLICK_INFO)
		end))

		return function()
			NewJob:Destroy()
		end
	end)
end

return {
	Name = "UIAnimations",
	Priority = 60,

	Start = function()
		BindClick("UI_ButtonClick", UserInterfaceAnimations.Click, 1.1)
		BindClick("UI_ButtonClickYJump", UserInterfaceAnimations.ClickYJump, 1.25)
	end,
}
