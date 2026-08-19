local ball = script.Parent.Parent.Parent.Parent
local driverSeat = ball.DriverSeat

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Logic for player entering the ball
local function enterBall(player: Player)
	local character = player.Character
	if not character then
		return
	end

	if driverSeat.Occupant then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	assert(humanoid, "No humanoid found!")

	-- Force a character to sit in the ball

	driverSeat:Sit(humanoid)

	-- Disable collisions
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			local noCollisionConstraint = Instance.new("NoCollisionConstraint")
			noCollisionConstraint.Part0 = ball.Exterior.CollisionBall
			noCollisionConstraint.Part1 = part
			noCollisionConstraint.Parent = ball.NoCollisionConstraints
		end
	end

	-- Update network owner of the ball
	ball.PrimaryPart:SetNetworkOwner(player)
end

return enterBall
