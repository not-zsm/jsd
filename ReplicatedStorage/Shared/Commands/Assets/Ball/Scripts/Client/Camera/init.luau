local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Config = require(script.Config)
local numLerp = require(script.numLerp)

local ball = script.Parent.Parent.Parent
local camera = Workspace.CurrentCamera :: Camera
local lastBallPosition = Vector3.zero
local lastFieldOfView = Config.MIN_FOV

local player = Players.LocalPlayer

local function updateCameraPosition(deltaTime)
	local targetPosition = camera.Focus.Position
	local targetPositionXZ = targetPosition * Vector3.new(1, 0, 1)
	local targetPositionY = targetPosition * Vector3.new(0, 1, 0)

	local lastPositionXZ = lastBallPosition * Vector3.new(1, 0, 1)
	local lastPositionY = lastBallPosition * Vector3.new(0, 1, 0)

	local newPositionXZ = lastPositionXZ:Lerp(targetPositionXZ, math.min(deltaTime * Config.HORIZONTAL_SPEED, 1))
	local newPositionY = lastPositionY:Lerp(targetPositionY, math.min(deltaTime * Config.VERTICAL_SPEED, 1))
	local newPosition = newPositionXZ + newPositionY
	lastBallPosition = newPosition

	local offset = newPosition - targetPosition
	camera.CFrame += offset
end

local function updateFieldOfView(deltaTime: number)
	local ballVelocity = ball.PrimaryPart.AssemblyLinearVelocity

	-- Adjust magnitude for FOV calculation
	local magnitude = math.min(ballVelocity.Magnitude, Config.MAX_FOV_SPEED)

	-- Interpolate the FOV based on the proportion
	local proportion = magnitude / Config.MAX_FOV_SPEED
	local newFOV = Config.MIN_FOV + proportion * (Config.MAX_FOV - Config.MIN_FOV)

	-- Update the field of view based on the camera FOV speed
	camera.FieldOfView = numLerp(lastFieldOfView, newFOV, math.min(deltaTime * Config.FOV_SPEED, 1))
	lastFieldOfView = camera.FieldOfView
end

local function onRenderStep(deltaTime: number)
	-- First update camera CFrame
	updateCameraPosition(deltaTime)

	-- Then update field of view
	updateFieldOfView(deltaTime)
end

local Camera = {}

function Camera.enable()
	player.CameraMinZoomDistance = Config.MIN_ZOOM_DISTANCE

	lastBallPosition = ball:GetPivot().Position
	camera.FieldOfView = lastFieldOfView
	camera.CameraSubject = ball.Exterior.PrimaryPart

	RunService:BindToRenderStep("CameraSmoothing", Enum.RenderPriority.Camera.Value + 1, onRenderStep)
end

function Camera.disable()
	RunService:UnbindFromRenderStep("CameraSmoothing")

	-- Reset to default field of view
	camera.FieldOfView = 70
	player.CameraMinZoomDistance = StarterPlayer.CameraMinZoomDistance
	camera.CameraSubject = player.Character
end

return Camera
