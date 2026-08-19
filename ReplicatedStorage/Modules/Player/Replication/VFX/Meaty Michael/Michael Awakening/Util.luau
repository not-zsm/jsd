local Util = {};

function Util.GetLaserCoordinateAtTime(Origin: CFrame, Elapsed: number)
	local Sine = Elapsed * 10;
	return Origin * CFrame.new(math.cos(Sine / 1.28) * 50, 0, math.sin(Sine * 1.03) * 50);
end

return Util;