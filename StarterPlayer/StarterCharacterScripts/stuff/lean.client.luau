repeat task.wait() until game:IsLoaded()
if not script.Parent:IsDescendantOf(workspace) then return end

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local info = require(ReplicatedStorage.info)

local Character = script.Parent.Parent

local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart") :: BasePart
local Torso = Character:WaitForChild("Torso") :: BasePart

local RootJoint = HumanoidRootPart:WaitForChild("RootJoint") :: Motor6D
local Neck = Torso:WaitForChild("Neck") :: Motor6D
local RightShoulder = Torso:WaitForChild("Right Shoulder") :: Motor6D
local LeftShoulder = Torso:WaitForChild("Left Shoulder") :: Motor6D
local RightHip = Torso:WaitForChild("Right Hip") :: Motor6D
local LeftHip = Torso:WaitForChild("Left Hip") :: Motor6D

local RootJointC0 = RootJoint.C0
local NeckC0 = Neck.C0
local RightShoulderC0 = RightShoulder.C0
local LeftShoulderC0 = LeftShoulder.C0
local RightHipC0 = RightHip.C0
local LeftHipC0 = LeftHip.C0

---------------------------------------------------------------------
-- config
---------------------------------------------------------------------

local CONFIG = {
	-- YAW, degrees at a full sideways strafe. These match your old
	-- numbers: torso 35, head -35 (exact counter), arms 15, hips 45/30.
	TorsoYaw = 35,
	HeadYaw = 35, -- keep == TorsoYaw for a perfectly stable head
	ArmYaw = 15,
	OuterLegYaw = 45, -- leg on the side you're moving toward
	InnerLegYaw = 30, -- trailing leg, staggered so it doesn't look pasted

	-- LEAN, degrees at the reference speed below
	LeanPitch = 7, -- forward/back, from forward velocity
	LeanRoll = 5, -- sideways, from strafe velocity
	BankRoll = 7, -- sideways, from turning

	-- velocity (studs/s) and angular velocity (rad/s) that max the lean out.
	-- nil SpeedForFullLean = use Humanoid.WalkSpeed, so the lean scales
	-- automatically with sprint / slow states.
	SpeedForFullLean = nil,
	AngularSpeedForFullBank = 6,

	-- how much of the torso lean the neck cancels out. 1 = head stays
	-- level and world-stable, 0 = head rides with the torso.
	HeadStabilise = 0.85,

	-- higher snaps to the target pose faster (framerate independent)
	Smoothing = 9,

	-- fade the whole pose out while airborne
	FadeInAir = true,
	AirFadeSpeed = 6,

	-- skip work for characters far from the camera
	MaxRenderDistance = 300,

	-- update cap. 0 = every frame.
	TickRate = 1 / 120,

	-- flip if your rig's lean comes out backwards
	Invert = false,
}

---------------------------------------------------------------------
-- state
---------------------------------------------------------------------

local Yourself = Players.LocalPlayer.Character == Character

-- smoothed scalars, in radians. Cheaper and safer than lerping CFrames,
-- and it can't produce a NaN quaternion if a velocity spikes.
local sTorsoYaw, sHeadYaw, sArmYaw = 0, 0, 0
local sRightHipYaw, sLeftHipYaw = 0, 0
local sPitch, sRoll = 0, 0
local sGrounded = 1

local accumulated = 0

local function attribute(name: string, default: number): number
	local value = script:GetAttribute(name)
	return typeof(value) == "number" and value or default
end

local function isFinite(v: Vector3): boolean
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z
end

local function approach(current: number, target: number, alpha: number): number
	return current + (target - current) * alpha
end

---------------------------------------------------------------------
-- update
---------------------------------------------------------------------

local function UpdateDirectionalMovement(DeltaTime: number)
	accumulated += DeltaTime
	if accumulated < CONFIG.TickRate then
		return
	end

	-- use the ACCUMULATED time, not the frame delta, or the smoothing
	-- runs slow whenever the tick cap actually skips a frame
	local step = math.min(accumulated, 0.25)
	accumulated = 0

	local camera = workspace.CurrentCamera
	if camera and (camera.CFrame.Position - HumanoidRootPart.Position).Magnitude > CONFIG.MaxRenderDistance then
		return
	end

	local alpha = 1 - math.exp(-CONFIG.Smoothing * step)

	local TorsoMulti = attribute("TorsoMultiplier", 1)
	local HeadMulti = attribute("HeadMultiplier", 1)
	local ArmMulti = attribute("ArmMultiplier", 1)
	local LegMulti = attribute("LegMultiplier", 1)

	local rootCFrame = HumanoidRootPart.CFrame

	----------------------------------------------------------------
	-- signal 1: intent (drives yaw)
	----------------------------------------------------------------

	local moveDirection = Vector3.zero

	if Yourself then
		moveDirection = rootCFrame:VectorToObjectSpace(Humanoid.MoveDirection)
	else
		local replicated = Character:GetAttribute("MoveDirection")
		if typeof(replicated) == "Vector3" and replicated.Magnitude > 0.01 then
			moveDirection = replicated
		else
			-- no attribute? derive intent from replicated velocity instead,
			-- so other players still pose correctly with zero networking
			local planar = rootCFrame:VectorToObjectSpace(HumanoidRootPart.AssemblyLinearVelocity)
			planar = Vector3.new(planar.X, 0, planar.Z)
			local speed = planar.Magnitude
			if speed > 0.1 then
				moveDirection = planar.Unit * math.min(speed / math.max(Humanoid.WalkSpeed, 1), 1)
			end
		end
	end

	if not isFinite(moveDirection) or moveDirection.Magnitude < 0.01 or Humanoid.WalkSpeed < info.walkSpeed then
		moveDirection = Vector3.zero
	end

	-- continuous, no dot-product buckets, no dead zones between them.
	-- for a unit direction, .X IS sin(angle from forward), which is
	-- exactly what the old branches were approximating.
	local x = math.clamp(moveDirection.X, -1, 1) -- + right
	local movingRight = x >= 0

	----------------------------------------------------------------
	-- signal 2: momentum (drives pitch and roll)
	----------------------------------------------------------------

	local velocity = rootCFrame:VectorToObjectSpace(HumanoidRootPart.AssemblyLinearVelocity)
	if not isFinite(velocity) then
		velocity = Vector3.zero
	end

	local reference = CONFIG.SpeedForFullLean or math.max(Humanoid.WalkSpeed, 1)
	local forward = math.clamp(-velocity.Z / reference, -1, 1) -- + running forward
	local strafe = math.clamp(velocity.X / reference, -1, 1) -- + moving right

	local angular = HumanoidRootPart.AssemblyAngularVelocity.Y
	if angular ~= angular then
		angular = 0
	end
	local spin = math.clamp(angular / CONFIG.AngularSpeedForFullBank, -1, 1) -- + turning left

	----------------------------------------------------------------
	-- targets
	----------------------------------------------------------------

	local grounded = (CONFIG.FadeInAir and Humanoid.FloorMaterial == Enum.Material.Air) and 0 or 1
	sGrounded = approach(sGrounded, grounded, 1 - math.exp(-CONFIG.AirFadeSpeed * step))

	local sign = CONFIG.Invert and -1 or 1
	local gate = sGrounded

	-- yaw: torso turns toward movement, head cancels it, legs go further
	local tTorsoYaw = -x * math.rad(CONFIG.TorsoYaw) * TorsoMulti * gate
	local tHeadYaw = x * math.rad(CONFIG.HeadYaw) * HeadMulti * gate
	local tArmYaw = x * math.rad(CONFIG.ArmYaw) * ArmMulti * gate
	local tRightHipYaw = -x * math.rad(movingRight and CONFIG.OuterLegYaw or CONFIG.InnerLegYaw) * LegMulti * gate
	local tLeftHipYaw = -x * math.rad(movingRight and CONFIG.InnerLegYaw or CONFIG.OuterLegYaw) * LegMulti * gate

	-- lean: +pitch = forward, +roll = left, so strafing right rolls negative
	-- and turning left (+spin) banks positive, into the turn
	local tPitch = sign * forward * math.rad(CONFIG.LeanPitch) * TorsoMulti * gate
	local tRoll = sign * (-strafe * math.rad(CONFIG.LeanRoll) + spin * math.rad(CONFIG.BankRoll)) * TorsoMulti * gate

	sTorsoYaw = approach(sTorsoYaw, tTorsoYaw, alpha)
	sHeadYaw = approach(sHeadYaw, tHeadYaw, alpha)
	sArmYaw = approach(sArmYaw, tArmYaw, alpha)
	sRightHipYaw = approach(sRightHipYaw, tRightHipYaw, alpha)
	sLeftHipYaw = approach(sLeftHipYaw, tLeftHipYaw, alpha)
	sPitch = approach(sPitch, tPitch, alpha)
	sRoll = approach(sRoll, tRoll, alpha)

	----------------------------------------------------------------
	-- apply
	----------------------------------------------------------------

	-- the neck shares the RootJoint's rotated basis, so negating the same
	-- three components is an exact inverse: the head stays level and
	-- pointed forward while the torso does whatever it likes
	local stabilise = CONFIG.HeadStabilise * HeadMulti

	task.synchronize()

	RootJoint.C0 = RootJointC0 * CFrame.Angles(sPitch, sRoll, sTorsoYaw)
	Neck.C0 = NeckC0 * CFrame.Angles(-sPitch * stabilise, -sRoll * stabilise, sHeadYaw)
	RightShoulder.C0 = RightShoulderC0 * CFrame.Angles(0, sArmYaw, 0)
	LeftShoulder.C0 = LeftShoulderC0 * CFrame.Angles(0, sArmYaw, 0)
	RightHip.C0 = RightHipC0 * CFrame.Angles(0, sRightHipYaw, 0)
	LeftHip.C0 = LeftHipC0 * CFrame.Angles(0, sLeftHipYaw, 0)
end

RunService.PreRender:ConnectParallel(UpdateDirectionalMovement)