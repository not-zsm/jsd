local Players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local getVelocityVector = require(script.getVelocityVector)
local stopBallMovement = require(script.Parent.Parent.Parent.stopBallMovement)

local player = Players.LocalPlayer
local PlayerModule = require(player.PlayerScripts:WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()

local ball = script.Parent.Parent.Parent
local ballRadius = ball.Exterior.CollisionBall.Size.X / 2
local controlAngularVelocity = ball.Constraints.ControlAngularVelocity
local controlAlignOrientation = ball.Constraints:FindFirstChild("ControlAlignOrientation")

local camera = Workspace.CurrentCamera
local ballControlsConnection
local areInputControlsEnabled = false

local ballSpeed = ball:GetAttribute("Speed") -- studs / second
assert(ballSpeed, `'Speed' attribute must be set on {ball:GetFullName()}`)

local function onStepped()
	local camDir = camera.CFrame.LookVector
	local playerInputVector = Controls:GetMoveVector()
	local newVectorVelocity = getVelocityVector(camDir, playerInputVector)

	local angularVelocity = ballSpeed / ballRadius
	controlAngularVelocity.AngularVelocity = Vector3.new(newVectorVelocity.Z, 0, -newVectorVelocity.X) * angularVelocity

	-- Face interior to direction user is aiming in
	if controlAlignOrientation and newVectorVelocity ~= Vector3.zero then
		controlAlignOrientation.CFrame = CFrame.lookAt(Vector3.zero, newVectorVelocity)
	end
end

local InputControls = {}

function InputControls.enable()
	if areInputControlsEnabled then
		return
	end
	areInputControlsEnabled = true

	ballControlsConnection = RunService.Stepped:Connect(onStepped)
end

function InputControls.disable()
	if not areInputControlsEnabled then
		return
	end
	areInputControlsEnabled = false

	-- Ensure the ball stops moving when input controls are disabled
	stopBallMovement(ball)

	if ballControlsConnection then
		ballControlsConnection:Disconnect()
		ballControlsConnection = nil
	end
end

return InputControls
