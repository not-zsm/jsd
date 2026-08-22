local TweenService = game:GetService("TweenService")
local ShockwaveInfo = TweenInfo.new(0.2)

return function(VictimRootPart : (BasePart | CFrame), AttackerRootPart : BasePart, Offset : CFrame, Size : Vector3)
	Offset = Offset or CFrame.identity
	
	local ShockwaveAngleFix = CFrame.Angles(0, math.pi / 2, 0)
	local Shockwave = script.Shockwave:Clone()
	
	if (AttackerRootPart ~= nil) then
		Shockwave.CFrame = CFrame.lookAt(VictimRootPart.Position, AttackerRootPart.Position) * ShockwaveAngleFix * Offset
	else
		if typeof(VictimRootPart) == "CFrame" then
			Shockwave.CFrame = VictimRootPart * ShockwaveAngleFix * Offset
		else
			Shockwave.CFrame = VictimRootPart.CFrame * ShockwaveAngleFix * Offset
		end
	end

	Shockwave.Size = Vector3.zero
	Shockwave.Parent = workspace.Visuals

	TweenService:Create(Shockwave, ShockwaveInfo, {
		CFrame = Shockwave.CFrame * CFrame.Angles(0, math.pi * 4, 0),
		Size = Size or Vector3.new(0.2, 12.5, 12.5),
		Transparency = 1
	}):Play()

	task.delay(ShockwaveInfo.Time, Shockwave.Destroy, Shockwave)
end