local Math = {}

function Math.WithinTime(Time : number, Value : number)
	return (Time == -1) or time() - Time < Value
end

function Math.BeyondTime(Time : number, Value : number) : boolean
	return (Time == -1) or time() - Time > Value
end

function Math.Lerp(a : number, b : number, t : number) : number
	return a + (b - a) * t
end

function Math.NumberRangeRandom(Range : NumberRange)
	return Random.new():NextNumber(Range.Min, Range.Max)
end

function Math.BetweenNumberRange(Range : NumberRange, Value : number) : boolean
	return not (Value < Range.Min or Value > Range.Max)
end

function Math.XOR(A : boolean, B : boolean) : boolean
	return (not A and B) or (A and not B)
end

return Math