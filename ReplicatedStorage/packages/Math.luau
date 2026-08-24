--!strict
--!native

local TweenService = game:GetService("TweenService");

local Math = {};

---------------------------------

export type DRR_Expression = {number | {number}};

export type DRR_Values = {DRR_Expression}

export type LerpFunction<T> = (T, T, number) -> T;

export type NumberSequenceTransform = (NumberSequenceKeypoint) -> (number, number, number?)

---------------------------------

--[[Converts the given Vector3 into a CFrame of XYZ Euler angles.]]
function Math.AnglesFromVector(Vec3 : (Vector3)) : (CFrame)
	return CFrame.Angles(Vec3.X, Vec3.Y, Vec3.Z);
end

--Converts the given Vector3 direction into a CFrame facing along the direction.
function Math.VectorToRotation(Vec3 : (Vector3)) : (CFrame)
	return CFrame.lookAt(Vector3.zero, Vec3);
end

--Gets the total weight of the given array of objects. Using their 'Weight' attribute.
function Math.GetTotalWeight(WeightedObjects : {Instance}) : number
	local TotalWeight = 0;

	for _, Object in ipairs(WeightedObjects) do
		local Weight: number? = Object:GetAttribute("Weight");
		
		if Weight then
			TotalWeight += Weight;
		end;
	end
	
	return TotalWeight;
end

function Math.ExpressDRR(tbl : {number}) : (number, number)
	return tbl[1] or 0, tbl[2] or tbl[1] or 0;
end

function Math.DynamicRandomRange(Values : DRR_Values)
	local NewValues : {number} = {};
	local Rnd = Random.new();
	
	for i, tbl in Values do
		NewValues[i] = Rnd:NextNumber(Math.ExpressDRR(tbl::{number}))
		
		if tbl[3] then
			while Math.InRange(NewValues[i], NumberRange.new(Math.ExpressDRR(tbl[3]::{number}))) do
				NewValues[i] = Rnd:NextNumber(Math.ExpressDRR(tbl::{number}))
			end
		end
	end
	
	return unpack(NewValues);
end

--Chooses a random object from the given array of instances. Using their 'Weight' attribute.
function Math.GetRandomByWeight(WeightedObjects : {Instance}) : (Instance?)
	local TotalWeight = Math.GetTotalWeight(WeightedObjects);
	local Chosen = math.random(0, TotalWeight);
	
	for _, Object in ipairs(WeightedObjects) do
		local Weight: number? = Object:GetAttribute("Weight");
		
		if Weight then
			TotalWeight -= Weight;
			
			if (TotalWeight <= Chosen) then
				return Object;
			end;
		end;
	end
	
	return nil;
end

--Randomly rolls a chance percentage, and returns if result met that percent.
function Math.Chance(Percent : number) : boolean
	return Random.new():NextNumber(0, 100) < Percent;
end

--Returns true when the given value is even.
function Math.IsEven(Value : number) : boolean
	return (Value % 2 == 0);
end;

--Returns the unit vector3 of a given vector, else returning (0, 0, 0) if it's magnitude is 0.
function Math.UnitDirection(Vec3: Vector3): Vector3
	local Unit = Vec3.Unit;
	
	return if Unit ~= Unit then Vector3.zero else Unit;
end

--Rounds the given value to nearest decimal place of Degree.
function Math.Round(Value : number, Degree : number?) : number
	local Points = 10 ^ (Degree or 1);
	return math.round(Value * Points) / Points;
end;

--Rounds the given value to multiple of ToNumber.
function Math.SRound(Value : number, ToNumber : number) : number
	if ToNumber == 0 then return Value end;
	
	return math.round(Value / ToNumber) * ToNumber;
end

--Linearly interpolates a given Alpha between a given NumberRange Range.
function Math.LerpRange(Range : (NumberRange), Alpha : number) : number
	return math.lerp(Range.Min, Range.Max, Alpha);
end

--Clamps a given value between a given range.
function Math.ClampRange(Value : number, Range : (NumberRange)) : number
	return  math.clamp(Value, Range.Min, Range.Max)
end

--Multiplies a given range by a multiplier.
function Math.RangeMult(Range : (NumberRange), Mult : number)
	return NumberRange.new(Range.Min * Mult, Range.Max * Mult);
end

--Returns 1 if the given value is truthy. Else returns 0.
function Math.TruthySign(Value : any?) : number
	return if (Value) then 1 else 0;
end

--Returns 1 if the given value resolves to 'true', else returns -1 if the value resolves to 'false', else returns 0.
function Math.BooleanSign(Value : boolean?) : number
	return if (Value == true) then 1 elseif (Value == false) then -1 else 0;
end;

--Randomly chooses a value between the given range.
function Math.RangeRandom(Range : NumberRange) : number
	return Random.new():NextNumber(Range.Min, Range.Max);
end;

--Returns whether a given point lies within the bounds of the given rectangle.
function Math.InBounds(Point : (Vector2), TX: number, TY: number, BX: number, BY: number) : boolean
	return Point.X >= TX
		and Point.X <= BX
		and Point.Y >= TY
		and Point.Y <= BY
end

--Returns whether a given point lies within the bounds of the given rectangle.
function Math.InRect(Point : (Vector2), Rectangle : Rect) : boolean
	return Point.X >= Rectangle.Min.X
		and Point.X <= Rectangle.Max.X
		and Point.Y >= Rectangle.Min.Y
		and Point.Y <= Rectangle.Max.Y
end

--Returns whether a given point is any one of the four corners of the given rectangle.
function Math.InRectCorner(Point: Vector2, Rectangle: Rect): boolean
	return Point.X == Rectangle.Min.X and Point.Y == Rectangle.Min.Y
		or Point.X == Rectangle.Min.X and Point.Y == Rectangle.Max.Y
		or Point.X == Rectangle.Max.X and Point.Y == Rectangle.Min.Y
		or Point.X == Rectangle.Max.X and Point.Y == Rectangle.Max.Y
end

--Rounds all the dimensions of the given vector3 to decimal places of Degree.
function Math.RoundVector3(Vec3: Vector3, Degree: number?)
	if Degree == 0 then return Vec3 end;
	
	local Points = (Degree or 1);

	return Vector3.new(
		math.round(Vec3.X / Points) * Points,
		math.round(Vec3.Y / Points) * Points,
		math.round(Vec3.Z / Points) * Points
	);
end

--Returns whether a given value lies within the given range.
function Math.InRange(Value : number, Range : NumberRange) : boolean
	return Value < Range.Max and Value > Range.Min;
end

--Returns whether a given value lies within the given range.
function Math.InRangeInclusive(Value : number, Range : NumberRange) : boolean
	return Value <= Range.Max and Value >= Range.Min;
end

--Performs a logical XOr (exclusive OR) operation on A and B.
function Math.XOr(A : boolean, B : boolean) : boolean
	return (A or B) and not (A and B);
end;

--Returns the alpha of the value being between the lower bound and upper bound.
function Math.GetAlpha(LowerBound : number, Value : number, UpperBound : number) : number
	return (Value - LowerBound) / (UpperBound - LowerBound)
end

--Clamps a given alpha between 0 to 1 with the padding of 'Offset'.
function Math.SideClamp(Alpha : number, Offset : number) : number
	return math.clamp(Alpha, 0 + Offset, 1 - Offset);
end;

--Reverses the result of using Math.SideClamp.
function Math.InverseSideClamp(Alpha : number, Offset : number) : number
	return math.clamp((Alpha - Offset) / (1 - Offset * 2), 0, 1);
end;

--Returns the alpha of the value being between Min and Max of the given range.
function Math.GetAlphaRange(Range : (NumberRange), Value : number) : number
	return Math.GetAlpha(Range.Min, Value, Range.Max);
end

--Linearly interpolates all NumberSequenceKeypoints of a given NumberSequence a given alpha towards the goal value.
function Math.InterpolateNumberSequenceValues(Sequence: NumberSequence, Alpha: number, Goal: number)
	local NewSequence = table.create(#Sequence.Keypoints)
	
	for Index, Keypoint in ipairs(Sequence.Keypoints) do
		NewSequence[Index] = NumberSequenceKeypoint.new(
			Keypoint.Time,
			Keypoint.Value + (Goal - Keypoint.Value) * Alpha,
			Keypoint.Envelope
		)
	end;

	return NumberSequence.new(NewSequence);
end

--Evaluates a given NumberSequence at the given time.
function Math.EvaluateNumberSequence(Sequence: NumberSequence, Time: number): number
	local Keypoints = Sequence.Keypoints;
	
	if Time <= 0 then
		return Keypoints[1].Value;
		
	elseif Time >= 1 then
		return Keypoints[#Keypoints].Value;
	end
	
	for Index = 1, #Keypoints - 1 do
		local Keypoint, NextKeypoint = Keypoints[Index], Keypoints[Index + 1]

		if Keypoint.Time <= Time and NextKeypoint.Time >= Time then
			return math.lerp(
				Keypoint.Value, NextKeypoint.Value, 
				Math.GetAlpha(Keypoint.Time, Time, NextKeypoint.Time)
			);
		end
	end;
	
	error("NumberSequence could not return a value");
end;

--Evaluates a given ColorSequence at the given time.
function Math.EvaluateColorSequence(Sequence: ColorSequence, Time: number): Color3
	local Keypoints = Sequence.Keypoints;
	
	if Time <= 0 then
		return Keypoints[1].Value;

	elseif Time >= 1 then
		return Keypoints[#Keypoints].Value;
	end
	
	for Index = 1, #Keypoints - 1 do
		local Keypoint, NextKeypoint = Keypoints[Index], Keypoints[Index + 1]

		if Keypoint.Time < Time and NextKeypoint.Time > Time then
			return Keypoint.Value:Lerp(
				NextKeypoint.Value, 
				Math.GetAlpha(Keypoint.Time, Time, NextKeypoint.Time)
			);
		end
	end;
	
	error("ColorSequence could not return a value");
end;

--Brightens a given color (whitens) by the given value.
function Math.Brighten(Color: Color3, Value: number): Color3
	local R = math.clamp(Color.R + Value, 0, 1);
	local G = math.clamp(Color.G + Value, 0, 1);
	local B = math.clamp(Color.B + Value, 0, 1);

	return Color3.new(R, G, B);
end;

--[[
Returns the CFrame of a given RaycastResult, 
has an optional Inverse parameter that makes the result face the opposite direction
]]
function Math.RayCFrame(Result: RaycastResult, Inverse: boolean?): CFrame
	return CFrame.lookAlong(Result.Position, if Inverse then -Result.Normal else Result.Normal);
end

local spread_rnd = Random.new();

function Math.GetSpreadAngle(LookVector: Vector3, SpreadAngle: Vector2, Face: Enum.NormalId): Vector3
	local spread_angle: CFrame = CFrame.fromEulerAngles(
		math.rad(spread_rnd:NextNumber(-1, 1) * SpreadAngle.X), 
		math.rad(spread_rnd:NextNumber(-1, 1) * SpreadAngle.Y), 0
	)

	local facing_angle: CFrame = CFrame.lookAlong(Vector3.zero, Vector3.FromNormalId(Face))
	local adornee_angle: CFrame = CFrame.lookAlong(Vector3.zero, LookVector);
	
	return (adornee_angle * facing_angle * spread_angle ).LookVector;
end

---------------------------------

table.freeze(Math);

---------------------------------

return Math;