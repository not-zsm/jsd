local TweenService = game:GetService("TweenService")
local VFX = {}

function VFX.Transition(AttackerRoot : BasePart, VictimRoot : BasePart, WallCFrame : CFrame, Offset : CFrame)
	VFX.Attacker(AttackerRoot, WallCFrame)
	VFX.Victim(VictimRoot, WallCFrame, Offset)
end

function VFX.Attacker(AttackerRoot : BasePart, WallCFrame : CFrame)
	TweenService:Create(AttackerRoot, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), 
		{CFrame = WallCFrame}
	):Play()
end

function VFX.Victim(VictimRoot : BasePart, WallCFrame : CFrame, Offset : CFrame)
	TweenService:Create(VictimRoot, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), 
		{CFrame = WallCFrame * Offset}
	):Play()
end

return VFX