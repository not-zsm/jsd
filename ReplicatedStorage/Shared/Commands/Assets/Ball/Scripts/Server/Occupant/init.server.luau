local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local enterBall = require(script.enterBall)
local exitBall = require(script.exitBall)

local ball = script.Parent.Parent.Parent
local driverSeat = ball.DriverSeat
local enterPrompt = ball.EnterPrompt
local exitPrompt = ball.ExitPrompt

-- If Ball speed is less than this value and occupant exists, exit prompt will appear
local EXIT_PROMPT_SPEED_THRESHOLD = 1
local MIN_TIME_BEFORE_EXIT_PROMPT_SHOWN = 2
local exitPromptConnection

-- Get any "disable exiting ball" parts
local disableExitBallBoundsParts = CollectionService:GetTagged("DisableExitingBall")

-- Listen for conditions that change whether the exit prompt is enabled
local function trackExitPromptEnabled(): RBXScriptConnection
	local connection = RunService.Heartbeat:Connect(function()
		-- check if ball is in the disable exit prompt bounds
		local isBallInDisableExitPromptBounds = false
		for _, disableExitBallBoundsPart in disableExitBallBoundsParts do
			local partsInBounds =
				Workspace:GetPartBoundsInBox(disableExitBallBoundsPart:GetPivot(), disableExitBallBoundsPart.Size)
			for _, part in partsInBounds do
				if part:IsDescendantOf(ball) then
					isBallInDisableExitPromptBounds = true
					break
				end
			end
		end

		-- check if ball speed is slow enough to exit the ball
		local isBallSpeedLow = false
		local ballVelocity = ball.PrimaryPart.AssemblyLinearVelocity
		if ballVelocity.Magnitude < EXIT_PROMPT_SPEED_THRESHOLD then
			isBallSpeedLow = true
		end

		-- enable exit prompt if ball spped is slow enough and ball is not in the disable exit prompt bounds
		if isBallSpeedLow and not isBallInDisableExitPromptBounds then
			exitPrompt.Enabled = true
		else
			exitPrompt.Enabled = false
		end
	end)
	return connection
end

local function onOccupantChanged()
	local humanoid = driverSeat.Occupant
	enterPrompt.Enabled = humanoid == nil
	-- Exit prompt will initially be false regardless of the occupancy state
	exitPrompt.Enabled = false

	if humanoid then
		-- Delay allows player to explore controlling the ball without immediately being prompted to exit
		task.delay(MIN_TIME_BEFORE_EXIT_PROMPT_SHOWN, function()
			exitPromptConnection = trackExitPromptEnabled()
		end)
	else
		if exitPromptConnection then
			exitPromptConnection:Disconnect()
			exitPromptConnection = nil
		end
	end
end

local function initialize()
	driverSeat:GetPropertyChangedSignal("Occupant"):Connect(onOccupantChanged)
	enterPrompt.Triggered:Connect(enterBall)
	exitPrompt.Triggered:Connect(exitBall)
end

initialize()
