local TweenService = game:GetService("TweenService")

local SFX = {}

function SFX.TweenVolume(Sound : Sound)
	TweenService:Create(Sound, TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{Volume = 0}
	):Play()
end

return SFX
