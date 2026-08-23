local CameraShakeInstance = {}
CameraShakeInstance.__index = CameraShakeInstance

CameraShakeInstance.CameraShakeState = {
	FadingIn = 0;
	FadingOut = 1;
	Sustained = 2;
	Inactive = 3;
}

function CameraShakeInstance.new(Magnitude : number, Roughness : number, FadeInTime : number, FadeOutTime : number)
	FadeInTime = FadeInTime or 0
	FadeOutTime = FadeOutTime or 0
	
	if (FadeInTime == nil) then FadeInTime = 0 end
	if (FadeOutTime == nil) then FadeOutTime = 0 end
	
	assert(type(Magnitude) == "number", "Magnitude must be a number")
	assert(type(Roughness) == "number", "Roughness must be a number")
	assert(type(FadeInTime) == "number", "FadeInTime must be a number")
	assert(type(FadeOutTime) == "number", "FadeOutTime must be a number")
	
	local self = setmetatable({
		Magnitude = Magnitude;
		Roughness = Roughness;
		PositionInfluence = Vector3.zero;
		RotationInfluence = Vector3.zero;
		DeleteOnInactive = true;
		FadeOutDuration = FadeOutTime;
		FadeInDuration = FadeInTime;
		Sustain = (FadeInTime > 0);
		CurrentFadeTime = (FadeInTime > 0 and 0 or 1);
		Tick = Random.new():NextNumber(-100, 100);
		IsACameraShakeInstance = true;
	}, CameraShakeInstance)
	
	return self
	
end


function CameraShakeInstance:UpdateShake(Delta)
	local Tick = self.Tick
	local CurrentFadeTime = self.CurrentFadeTime

	-- Define a fixed timestep (prevents FPS-dependent behavior)
	local FixedDelta = 1 / 60  -- Always update as if at 60 FPS
	self.AccumulatedTime = (self.AccumulatedTime or 0) + Delta

	-- Process multiple fixed timesteps if Delta is large (for low FPS situations)
	while self.AccumulatedTime >= FixedDelta do
		self.AccumulatedTime = self.AccumulatedTime - FixedDelta

		-- Handle fade-in
		if self.FadeInDuration > 0 and self.Sustain then
			if CurrentFadeTime < 1 then
				CurrentFadeTime = CurrentFadeTime + (FixedDelta / self.FadeInDuration)
				
			elseif self.FadeOutDuration > 0 then
				self.Sustain = false
			end
		end

		-- Handle fade-out
		if not self.Sustain then
			CurrentFadeTime = math.max(0, CurrentFadeTime - (FixedDelta / self.FadeOutDuration))
		end

		self.Tick = Tick + (FixedDelta * self.Roughness * (self.Sustain and 1 or CurrentFadeTime))
		self.CurrentFadeTime = CurrentFadeTime
	end
	
	local OverallIntensity = 0.5

	return Vector3.new(
		math.noise(self.Tick, 0) * OverallIntensity,
		math.noise(0, self.Tick) * OverallIntensity,
		math.noise(self.Tick, self.Tick) * OverallIntensity
	) * self.Magnitude * self.CurrentFadeTime
end


function CameraShakeInstance:StartFadeOut(fadeOutTime)
	if (fadeOutTime == 0) then
		self.CurrentFadeTime = 0
	end
	
	self.FadeOutDuration = fadeOutTime
	self.FadeInDuration = 0
	self.Sustain = false
end


function CameraShakeInstance:StartFadeIn(fadeInTime)
	if (fadeInTime == 0) then
		self.CurrentFadeTime = 1
	end
	
	self.FadeInDuration = fadeInTime or self.FadeInDuration
	self.FadeOutDuration = 0
	self.Sustain = true
end


function CameraShakeInstance:GetNormalizedFadeTime()
	return self.CurrentFadeTime
end


function CameraShakeInstance:IsShaking()
	return (self.CurrentFadeTime > 0 or self.Sustain)
end


function CameraShakeInstance:IsFadingOut()
	return (not self.Sustain) and self.CurrentFadeTime > 0
end


function CameraShakeInstance:IsFadingIn()
	return (self.CurrentFadeTime < 1 and self.Sustain and self.FadeInDuration > 0)
end


function CameraShakeInstance:GetState()
	if (self:IsFadingIn()) then
		return CameraShakeInstance.CameraShakeState.FadingIn
	elseif (self:IsFadingOut()) then
		return CameraShakeInstance.CameraShakeState.FadingOut
	elseif (self:IsShaking()) then
		return CameraShakeInstance.CameraShakeState.Sustained
	else
		return CameraShakeInstance.CameraShakeState.Inactive
	end
end


return CameraShakeInstance