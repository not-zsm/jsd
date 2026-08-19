local function getVelocityVector(cameraLookVector: Vector3, playerInputVector: Vector3): Vector3
	-- Only unitize the input vector if it's larger than 1
	if playerInputVector.Magnitude > 1 then
		playerInputVector = playerInputVector.Unit
	end

	-- Remove the Y component to project onto the horizontal plane
	local forward = (cameraLookVector * Vector3.new(1, 0, 1)).Unit
	local right = forward:Cross(Vector3.yAxis)

	-- Now calculate the movement direction based on the player's input
	-- Note that in Roblox, the Z-axis goes the opposite way, so we invert it
	local moveDirection = (right * playerInputVector.X) - (forward * playerInputVector.Z)

	return moveDirection
end

return getVelocityVector
