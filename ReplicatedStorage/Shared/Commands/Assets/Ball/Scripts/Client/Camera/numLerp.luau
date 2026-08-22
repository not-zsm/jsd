local function numLerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

return numLerp
