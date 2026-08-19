-- SERVICES --
local TS = game:GetService("TweenService")

-- AUXILIARY FUNCTIONS --
local function lerp(a, b, t)
	return a + (b - a) * t
end

local function interpolateKeypoints(kp1, kp2, t)
	return NumberSequenceKeypoint.new(
		lerp(kp1.Time, kp2.Time, t),
		lerp(kp1.Value, kp2.Value, t),
		lerp(kp1.Envelope, kp2.Envelope, t)
	)
end

local function getNewValues(progress: number, originalSequence : NumberSequence, targetSequence: NumberSequence)
	local newKeypoints = {}

	local originalKeypoints = originalSequence.Keypoints
	local targetKeypoints = targetSequence.Keypoints

	local originalNumKeypoints = #originalKeypoints
	local targetNumKeypoints = #targetKeypoints

	for i = 1, math.max(originalNumKeypoints, targetNumKeypoints) do
		local originalIndex = math.floor((i - 1) * (originalNumKeypoints - 1) / (targetNumKeypoints - 1)) + 1
		local targetIndex = i

		if originalIndex < 1 then
			originalIndex = 1
		elseif originalIndex > originalNumKeypoints then
			originalIndex = originalNumKeypoints
		end

		local originalKeypoint = originalKeypoints[originalIndex]
		local targetKeypoint = targetKeypoints[targetIndex]

		local t = progress

		local newTime = lerp(originalKeypoint.Time, targetKeypoint.Time, t)
		local newValue = lerp(originalKeypoint.Value, targetKeypoint.Value, t)
		local newEnvelope = lerp(originalKeypoint.Envelope, targetKeypoint.Envelope, t)

		table.insert(newKeypoints, NumberSequenceKeypoint.new(newTime, newValue, newEnvelope))
	end

	return NumberSequence.new(newKeypoints)
end

-- TYPES --
type TweenObject = {
	PlaybackState : Enum.PlaybackState,
	Cancel : (TweenObject) -> TweenObject,
	Play : (TweenObject) -> TweenObject,
	Pause : (TweenObject) -> TweenObject,
	Destroy : (TweenObject) -> nil,
	
	Completed : RBXScriptSignal,
	Paused : RBXScriptSignal,
}

-- MAIN --
local Tween = {}
Tween.__index = Tween

function Tween.new(Object : NumberSequence | ParticleEmitter | Beam, TargetSequence : NumberSequence, Info : TweenInfo, PropertyName : string?) : TweenObject
	local ObjectType : 'NumberSequence' | 'Instance' = 'NumberSequence'
	
	if not Info or typeof(Info) ~= 'TweenInfo' then warn("TweenInfo can't be NIL!") return end
	if typeof(Object) ~= 'NumberSequence' then
		if typeof(Object) ~= 'Instance' or not Object:IsA("ParticleEmitter") and not Object:IsA("Beam") then warn("Invalid object") return end
		if not PropertyName or typeof(PropertyName) ~= 'string' then warn("Invalid property name: ", PropertyName) return end

		ObjectType = "Instance" -- If the property does not exist in the instance, this will likely error
		if typeof(Object[PropertyName]) ~= 'NumberSequence' then warn("Invalid property type: ", typeof(Object)) return end
	end

	local self = setmetatable({}, Tween)
	self.PlaybackState = Enum.PlaybackState.Begin
	
	local completedEvent = Instance.new("BindableEvent")
	local pausedEvent = Instance.new("BindableEvent")
	
	self.Completed = completedEvent.Event
	self.Paused = pausedEvent.Event
	
	local startTick = tick()
	local endTime = startTick + Info.Time
	local pauseTime = tick()
	local activeTask : thread? = nil

	local originalValues = {}

	for i, keypoint : NumberSequenceKeypoint in ipairs(ObjectType == 'NumberSequence' and Object.Keypoints or Object[PropertyName].Keypoints) do
		table.insert(originalValues, keypoint)
	end
	
	local originalSequenceCopy = NumberSequence.new(originalValues)

	function self:Cancel()
		if not self.PlaybackState or self.PlaybackState == Enum.PlaybackState.Completed or self.PlaybackState == Enum.PlaybackState.Cancelled then return self end
		self.PlaybackState = Enum.PlaybackState.Cancelled
		
		return self
	end

	function self:Destroy()
		self:Cancel()
		
		if activeTask then
			task.cancel(activeTask)
			activeTask = nil
		end
		
		pausedEvent:Destroy()
		completedEvent:Destroy()
		self.Completed = nil
		self.Paused = nil
		
		return self
	end

	function self:Play()
		if not self.PlaybackState or self.PlaybackState == Enum.PlaybackState.Completed or self.PlaybackState == Enum.PlaybackState.Cancelled then warn(1) return self end
		
		if self.PlaybackState == Enum.PlaybackState.Paused then
			local currentTime = tick()
			local timePaused = currentTime - pauseTime
			startTick = startTick + timePaused
			endTime = endTime + timePaused
		elseif self.PlaybackState == Enum.PlaybackState.Begin then
			startTick = tick()
			endTime = startTick + Info.Time
		end
		
		self.PlaybackState = Enum.PlaybackState.Playing
		
		if not activeTask then
			activeTask = task.spawn(function()
				while tick() < endTime do
					if tick() >= endTime then break end
					if self.PlaybackState == Enum.PlaybackState.Cancelled then break end

					if self.PlaybackState == Enum.PlaybackState.Paused then
						task.wait()
						continue
					end

					local timePassed = tick() - startTick
					local currentProgress = math.clamp(timePassed / Info.Time, 0, 1)
					currentProgress = TS:GetValue(currentProgress, Info.EasingStyle, Info.EasingDirection)

					local newSequence = getNewValues(currentProgress, originalSequenceCopy, TargetSequence)

					if ObjectType == 'NumberSequence' then
						Object = newSequence
					else
						Object[PropertyName] = newSequence
					end

					task.wait()
				end

				if self.PlaybackState == Enum.PlaybackState.Playing or self.PlaybackState == Enum.PlaybackState.Cancelled then
					self.PlaybackState = Enum.PlaybackState.Completed
					completedEvent:Fire()
				end
			end)
		end

		return self
	end
	
	function self:Pause()
		if self.PlaybackState == Enum.PlaybackState.Playing then
			self.PlaybackState = Enum.PlaybackState.Paused
			pauseTime = tick()
			pausedEvent:Fire()
		end
		
		return self
	end
	
	return self
end

return Tween