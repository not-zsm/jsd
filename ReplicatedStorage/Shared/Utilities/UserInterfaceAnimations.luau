local UserInterfaceAnimations = {}
type Button = ImageButton | TextButton

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Job = require( ReplicatedStorage.Shared.Utilities.Job )

function UserInterfaceAnimations.Click(Button : Button, Pop : number, Info : TweenInfo)
	Info = Info or TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In, 0, true)
	
	Button.Size = UDim2.new(0.273, 0, 0.605, 0)
	
	local ButtonSize = Button.Size

	SoundService.GUI.Click:Play()

	local Tween = TweenService:Create(Button, Info, {
		Size = UDim2.new(
			ButtonSize.X.Scale * Pop,
			ButtonSize.X.Offset * Pop,
			ButtonSize.Y.Scale * Pop,
			ButtonSize.Y.Offset * Pop
		)
	})
	
	Tween:Play()
end

function UserInterfaceAnimations.ClickYJump(Button : Button, Pop : number, Info : TweenInfo)
	Info = Info or TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In, 0, true)
	
	local ButtonPosition = Button.Position
	local ButtonPop = 1 - (Pop -1)
	
	SoundService.GUI.Click:Play()

	local Tween = TweenService:Create(Button, Info, {
		Position = UDim2.new(
			Button.Position.X.Scale,
			Button.Position.X.Offset,
			ButtonPosition.Y.Scale * ButtonPop,
			ButtonPosition.Y.Offset * ButtonPop
		)
	})
	
	Tween:Play()
end

return UserInterfaceAnimations
