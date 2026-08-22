local function stopBallMovement(ball: Model)
	if not ball.PrimaryPart then
		return
	end

	-- Zero out velocity applied to the ball
	local controlAngularVelocity = ball.Constraints.ControlAngularVelocity
	controlAngularVelocity.AngularVelocity = Vector3.zero
	ball.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
	ball.PrimaryPart.AssemblyAngularVelocity = Vector3.zero
end

return stopBallMovement
