local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Handler = {}

function Handler:_Load(rig, animation, fadeTime, priority, looped, fadeOutTime)
	if animation == nil then warn('no anim provided') return end
	if rig == nil then return end

	fadeTime = fadeTime or 0
	fadeOutTime = fadeOutTime or 0.5

	if typeof(animation) == 'string' then
		local actualAnim = Instance.new('Animation')
		actualAnim.AnimationId = animation
		animation = actualAnim
		animation:AddTag('toDelete')
	end

	local humanoid = rig:FindFirstChildOfClass("Humanoid")

	if (humanoid == nil) then
		local animCtrl = rig:FindFirstChildOfClass("AnimationController")
		if (animCtrl) then
			humanoid = animCtrl
		else return end
	end

	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end

		local Anim = animator:LoadAnimation(animation)

		if animation:HasTag('toDelete') then
			Debris:AddItem(animation, 1)
		end

		local pri = Enum.AnimationPriority.Action

		if (priority == nil) then
			pri = Anim.Priority or pri
		else
			pri = priority
		end

		if (looped == nil) then
			looped = Anim.Looped
		end

		Anim.Looped = looped
		Anim.Priority = pri
		--Anim:AdjustSpeed(speed)

		local cleaned = false

		Anim.Destroying:Once(function()
			if cleaned then return end
			cleaned = true
			pcall(function() Anim:Stop(fadeOutTime) end)
		end)

		Anim.Stopped:Once(function()
			if cleaned then return end
			cleaned = true
			Anim:Destroy()
		end)

		return Anim
	end
end

function Handler:loadAnimation(rig, animation, fadeTime, priority, looped, fadeOutTime) : AnimationTrack
	local animationTrack = Handler:_Load(rig, animation, fadeTime, priority, looped, fadeOutTime)

	if (not animationTrack) then return end
	return animationTrack
end

return Handler