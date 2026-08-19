local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Camera = require(script.Parent.Camera)
local InputControls = require(script.Parent.InputControls)
local setJumpingEnabled = require(script.setJumpingEnabled)
local getPlayerFromSeat = require(script.Parent.Parent.Parent.getPlayerFromSeat)

local player = Players.LocalPlayer
local ball = script.Parent.Parent.Parent
local driverSeat = ball.DriverSeat
local animation = ball:FindFirstChildOfClass("Animation")
local animationTrack = nil

local isControlling = false

-- Enable the client modules and Controller update loop
local function startControlling()
	if isControlling then
		return
	end
	isControlling = true

	-- Stop the player from jumping out of the seat
	local character = player.Character
	if character then
		setJumpingEnabled(character, false)
	end

	-- Play animation if it exists
	if animation then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				local animator = humanoid:FindFirstChild("Animator")
				animationTrack = animator:LoadAnimation(animation)
				animationTrack:Play()
			end
		end
	end

	-- Enable ball controls
	InputControls.enable()

	-- Enable camera for controlling the ball
	Camera.enable()
end

-- Disable the client modules and Controller update loop
local function stopControlling()
	if not isControlling then
		return
	end
	isControlling = false

	-- Return to default controls
	InputControls.disable()

	-- Return to default camera
	Camera.disable()

	-- Stop animation if it exists
	if animationTrack then
		animationTrack:Stop()
		animationTrack = nil
	end

	-- Reenable jumping for the player
	local character = player.Character
	if character then
		setJumpingEnabled(character, true)
	end
end

-- Call startControlling() or stopControlling() if the player enters or exits the seat
local function onOccupantChanged()
	local playerInSeat = getPlayerFromSeat(driverSeat)

	if playerInSeat == player then
		startControlling()
	else
		stopControlling()
	end
end

driverSeat:GetPropertyChangedSignal("Occupant"):Connect(onOccupantChanged)
driverSeat.AncestryChanged:Connect(function(_, Parent)
	if Parent == nil then
		stopControlling()
	end
end)

ball.Events.ToggleInputControlsRemoteEvent.OnClientEvent:Connect(function(enableControls: boolean)
	if enableControls then
		InputControls.enable()
	else
		InputControls.disable()
	end
end)
