repeat task.wait() until game:IsLoaded()
if not script.Parent:IsDescendantOf(workspace) then return end

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

local info = require(replicatedStorage.info)

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

	-- a standing humanoid never reads exactly zero: the state solver keeps
	-- nudging it, and in shiftlock every mouse movement spins the root. Below
	-- DeadZone the pose is off entirely, and it ramps in over the next
	-- DeadZoneRamp studs/s so there is no step at the boundary.
	DeadZone = 1.5,
	DeadZoneRamp = 2,
	AngularDeadZone = 0.15,

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

	-- update cap for everyone else's characters. Your own runs every frame:
	-- capping it makes the pose land on some frames and not others, which
	-- reads as jitter on anything above 120Hz.
	RemoteTickRate = 1 / 30,

	-- radians. Under this the pose is indistinguishable from neutral, so we
	-- write the base C0 once and stop touching the joints until there is
	-- something to say again.
	SettleEpsilon = 1e-4,

	-- flip if your rig's lean comes out backwards
	Invert = false,
}

---------------------------------------------------------------------
-- state
---------------------------------------------------------------------

-- smoothed scalars, in radians. Cheaper and safer than lerping CFrames,
-- and it can't produce a NaN quaternion if a velocity spikes.
local sTorsoYaw, sHeadYaw, sArmYaw = 0, 0, 0
local sRightHipYaw, sLeftHipYaw = 0, 0
local sPitch, sRoll = 0, 0
local sGrounded = 1

local accumulated = 0
local posed = false

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

local function deadZone(value: number, zone: number): number
	return math.abs(value) < zone and 0 or value
end

-- anything that means the joints belong to somebody else: a cutscene
-- anchoring or CFraming the character, a seat, a ragdoll swapping the motors
-- out. Suspended does not mean "stop updating" — the pose still eases back to
-- neutral, then hands the joints over.
local function suspended(): boolean
	if not RootJoint.Parent or not Neck.Parent then
		return true
	end
	if not RootJoint.Enabled or not Neck.Enabled then
		return true
	end
	if Humanoid.Health <= 0 or Humanoid.Sit or Humanoid.PlatformStand then
		return true
	end
	if HumanoidRootPart.Anchored then
		return true
	end

	local camera = workspace.CurrentCamera
	if camera and (camera.CFrame.Position - HumanoidRootPart.Position).Magnitude > CONFIG.MaxRenderDistance then
		return true
	end

	return false
end

local function settled(): boolean
	return math.max(
		math.abs(sTorsoYaw), math.abs(sHeadYaw), math.abs(sArmYaw),
		math.abs(sRightHipYaw), math.abs(sLeftHipYaw),
		math.abs(sPitch), math.abs(sRoll)
	) < CONFIG.SettleEpsilon
end

---------------------------------------------------------------------
-- update
---------------------------------------------------------------------

local function UpdateDirectionalMovement(DeltaTime: number)
	local Yourself = Players.LocalPlayer.Character == Character
	local step = DeltaTime

	if not Yourself then
		accumulated += DeltaTime
		if accumulated < CONFIG.RemoteTickRate then
			return
		end
		step = accumulated
		accumulated = 0
	end

	step = math.min(step, 0.25)

	local alpha = 1 - math.exp(-CONFIG.Smoothing * step)

	local TorsoMulti = attribute("TorsoMultiplier", 1)
	local HeadMulti = attribute("HeadMultiplier", 1)
	local ArmMulti = attribute("ArmMultiplier", 1)
	local LegMulti = attribute("LegMultiplier", 1)

	local rootCFrame = HumanoidRootPart.CFrame
	local off = suspended()

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

	if off or not isFinite(moveDirection) or moveDirection.Magnitude < 0.01 or Humanoid.WalkSpeed < info.walkSpeed then
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
	if off or not isFinite(velocity) then
		velocity = Vector3.zero
	end

	-- never divide by a slowed WalkSpeed: a stun that drops it to 1 would
	-- turn any leftover drift into a full-tilt lean
	local reference = CONFIG.SpeedForFullLean or math.max(Humanoid.WalkSpeed, info.walkSpeed)

	local planarSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local intensity = math.clamp((planarSpeed - CONFIG.DeadZone) / CONFIG.DeadZoneRamp, 0, 1)

	local forward = math.clamp(-velocity.Z / reference, -1, 1) * intensity -- + running forward
	local strafe = math.clamp(velocity.X / reference, -1, 1) * intensity -- + moving right

	local angular = HumanoidRootPart.AssemblyAngularVelocity.Y
	if off or angular ~= angular then
		angular = 0
	end
	angular = deadZone(angular, CONFIG.AngularDeadZone)

	-- banking is a running move. Standing still and looking around in
	-- shiftlock spins the root every frame the mouse moves, and without
	-- this the torso rocks along with it.
	local spin = math.clamp(angular / CONFIG.AngularSpeedForFullBank, -1, 1) * intensity -- + turning left

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

	-- the exponential never actually reaches zero, so without this the
	-- script would hold the joints at a fraction of a degree forever and
	-- keep overwriting them every frame
	if settled() then
		if not posed then
			return
		end

		sTorsoYaw, sHeadYaw, sArmYaw = 0, 0, 0
		sRightHipYaw, sLeftHipYaw = 0, 0
		sPitch, sRoll = 0, 0
		posed = false

		RootJoint.C0 = RootJointC0
		Neck.C0 = NeckC0
		RightShoulder.C0 = RightShoulderC0
		LeftShoulder.C0 = LeftShoulderC0
		RightHip.C0 = RightHipC0
		LeftHip.C0 = LeftHipC0

		return
	end

	posed = true

	-- the neck shares the RootJoint's rotated basis, so negating the same
	-- three components is an exact inverse: the head stays level and
	-- pointed forward while the torso does whatever it likes
	local stabilise = CONFIG.HeadStabilise * HeadMulti

	RootJoint.C0 = RootJointC0 * CFrame.Angles(sPitch, sRoll, sTorsoYaw)
	Neck.C0 = NeckC0 * CFrame.Angles(-sPitch * stabilise, -sRoll * stabilise, sHeadYaw)
	RightShoulder.C0 = RightShoulderC0 * CFrame.Angles(0, sArmYaw, 0)
	LeftShoulder.C0 = LeftShoulderC0 * CFrame.Angles(0, sArmYaw, 0)
	RightHip.C0 = RightHipC0 * CFrame.Angles(0, sRightHipYaw, 0)
	LeftHip.C0 = LeftHipC0 * CFrame.Angles(0, sLeftHipYaw, 0)
end

RunService.PreRender:Connect(UpdateDirectionalMovement)
