local Model = script.Parent
local Humanoid = Model:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")

local replicatedStorage = game:GetService("ReplicatedStorage")
local AnimationsFolder = replicatedStorage:WaitForChild("animations")
local MovementFolder = AnimationsFolder:WaitForChild("Movement")
local CharaAnimations = MovementFolder:WaitForChild("chara")

local Animations = {}

for _, Animation in ipairs(CharaAnimations:GetChildren()) do
	if Animation:IsA("Animation") then
		Animations[Animation.Name] = Animator:LoadAnimation(Animation)
		Animations[Animation.Name].Priority = Enum.AnimationPriority.Core
	end
end

Humanoid.Running:Connect(function(Speed)
	if Speed > 1 then
		if Animations.Idle.IsPlaying then
			Animations.Idle:Stop()
		end

		if not Animations.Walk.IsPlaying then
			Animations.Walk:Play()
		end
	else
		if not Animations.Idle.IsPlaying then
			Animations.Idle:Play()
		end

		if Animations.Walk.IsPlaying then
			Animations.Walk:Stop()
		end
	end
end)