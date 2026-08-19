local DataTypes = {}

function DataTypes.number(a, b, t)
	return a + ((b - a) * t)
end

function DataTypes.boolean(a, b, t)
	return t < 0.5 and a or b
end

function DataTypes.string(a, b, t)
	local lengthA = string.len(a)
	local lengthB = string.len(b)
	
	local stringA = string.sub(a, 1, lengthA * (1 - t))
	local stringB = string.sub(b, 1, lengthB * t)
	
	return stringA .. stringB
end

function DataTypes.Vector3(a, b, t)
	return a:Lerp(b, t)
end

function DataTypes.Vector2(...)
	return DataTypes.Vector3(...)
end

function DataTypes.CFrame(...)
	return DataTypes.Vector3(...)
end

function DataTypes.Color3(...)
	return DataTypes.Vector3(...)
end

function DataTypes.NumberRange(a, b, t)
	return NumberRange.new(
		DataTypes.number(a.Min, b.Min, t),
		DataTypes.number(a.Max, b.Max, t)
	)
end

function DataTypes.NumberSequence(a, b, t)
	assert(#a.Keypoints == #b.Keypoints, "Number of NumberSequence keypoints must match")
	
	local keypoints = {}
	
	for index, keypoint in pairs(a.Keypoints) do
		local nextKeypoint = b.Keypoints[index]
		
		table.insert(keypoints, NumberSequenceKeypoint.new(
			DataTypes.number(keypoint.Time, nextKeypoint.Time, t),
			DataTypes.number(keypoint.Value, nextKeypoint.Value, t),
			DataTypes.number(keypoint.Envelope, nextKeypoint.Envelope, t)
		))
	end
	
	return NumberSequence.new(keypoints)
end

function DataTypes.ColorSequence(a, b, t)
	assert(#a.Keypoints == #b.Keypoints, "Number of ColorSequence keypoints must match")

	local keypoints = {}

	for index, keypoint in pairs(a.Keypoints) do
		local nextKeypoint = b.Keypoints[index]

		table.insert(keypoints, ColorSequenceKeypoint.new(
			DataTypes.number(keypoint.Time, nextKeypoint.Time, t),
			DataTypes.Color3(keypoint.Value, nextKeypoint.Value, math.clamp(t, 0, 1))
		))
	end

	return ColorSequence.new(keypoints)
end

return DataTypes