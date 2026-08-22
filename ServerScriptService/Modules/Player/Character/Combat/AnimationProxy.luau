-- Wrapper for AnimationTrack instances, the lazy way of adding speed multipliers without big refactors 🥀

local AnimationProxy = {};

function AnimationProxy:__index(index)
	local value = AnimationProxy[index];
	
	if value ~= nil then
		return value;
	end;
	
	value = self.Track[index];
	
	if typeof(value) ~= "function" then
		return value;
	end
	
	local fn_cached = self._fn_cache[index];
	
	if not fn_cached then
		fn_cached = function(...)
			return value(self.Track, select(2, ...));
		end;
		
		self._fn_cache[index] = fn_cached;
	end
	
	return fn_cached;
end;

function AnimationProxy:__newindex(index, value)
	self.Track[index] = value;
end;

function AnimationProxy:Play(FadeTime: number, Weight: number, Speed: number): ()
	self.Track:Play( FadeTime, Weight, (Speed or 1) * self.SpeedMultiplier );
end;

function AnimationProxy:AdjustSpeed(Speed: number): ()
	self.Track:AdjustSpeed( Speed * self.SpeedMultiplier );
end;

function AnimationProxy:SetSpeedMultiplier(Multiplier: number): ()
	if self.Track.IsPlaying then
		self.Track:AdjustSpeed( self.Track.Speed / self.SpeedMultiplier * Multiplier );
	end;
	
	self.SpeedMultiplier = Multiplier;
end;

function AnimationProxy:GetMarkerReachedSignal(Marker: string): RBXScriptSignal
	return self.Track:GetMarkerReachedSignal(Marker);
end;

function AnimationProxy.new(track: AnimationTrack)
	local self = setmetatable(
		{
			_fn_cache = {};
			
			SpeedMultiplier = 1;
			Track = track;
		}, 
		AnimationProxy);
	
	return self;
end;

table.freeze(AnimationProxy);

return AnimationProxy;