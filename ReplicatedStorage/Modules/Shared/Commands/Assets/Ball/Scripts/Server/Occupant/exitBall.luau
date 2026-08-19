local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ball = script.Parent.Parent.Parent.Parent
local driverSeat = ball.DriverSeat

local getPlayerFromSeat = require(script.Parent.Parent.Parent.Parent.getPlayerFromSeat)


-- Logic for player exiting the ball
local function exitBall(playerTriggered: Player)
	local playerInBall = getPlayerFromSeat(driverSeat)

	if not playerInBall or playerTriggered ~= playerInBall then
		return
	end

	-- Calculate position to place the player's character on exit
	local seatDirection = driverSeat.CFrame.LookVector.Unit * Vector3.new(1, 0, 1)
	local playerExitPosition = driverSeat.CFrame - seatDirection * ball.Exterior.CollisionBall.Size.X

	-- Before removing the weld, listen for when the humanoid is not seated
	-- to ensure the character is not moved as the humanoid is removed from the seat
	local humanoidInBall = driverSeat.Occupant
	local stateChangedConnection
	stateChangedConnection = humanoidInBall.StateChanged:Connect(
		function(old: Enum.HumanoidStateType, _: Enum.HumanoidStateType)
			if old == Enum.HumanoidStateType.Seated then
				humanoidInBall.Parent:PivotTo(playerExitPosition)

				-- Enable collisions after moving
				ball.NoCollisionConstraints:ClearAllChildren()

				stateChangedConnection:Disconnect()
			end
		end
	)

	-- Remove the seat's weld
	local seatWeld = driverSeat:FindFirstChild("SeatWeld")
	if seatWeld then
		seatWeld:Destroy()
	end
end

return exitBall
