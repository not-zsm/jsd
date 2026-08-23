local RunService = game:GetService("RunService")

-- Ahead of the camera module, so the offset it reads is this frame's, not last
-- frame's.
local ACTION = "FollowHead"
local PRIORITY = Enum.RenderPriority.Camera.Value - 1

local SPEED = 20
local BASE_OFFSET = Vector3.yAxis * 1.5

local FollowHead = {}
FollowHead.__index = FollowHead

function FollowHead.new(Character: Model, IsEnabled: (() -> boolean)?)
	local self = setmetatable({}, FollowHead)

	self.Camera = workspace.CurrentCamera
	self.Character = Character
	self.IsEnabled = IsEnabled

	self.Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
	self.RootPart = Character:WaitForChild("HumanoidRootPart") :: BasePart
	self.Head = Character:WaitForChild("Head") :: BasePart

	self.Target = nil     -- nil follows the head
	self.Bound = false

	return self
end

-- A part to look at instead of the head, for a cutscene or a finisher.
function FollowHead:SetTarget(Part: BasePart?)
	self.Target = Part
end

function FollowHead:ClearTarget()
	self.Target = nil
end

function FollowHead:Offset(): Vector3
	if self.IsEnabled and not self.IsEnabled() then
		return Vector3.zero
	end

	if self.Target then
		if not self.Target:IsDescendantOf(workspace) then
			self.Target = nil
		else
			return self.RootPart.CFrame:PointToObjectSpace(self.Target.Position)
		end
	end

	-- while something else owns the camera the offset would fight it
	if self.Camera.CameraSubject ~= self.Humanoid then
		return Vector3.zero
	end

	if not self.Head:IsDescendantOf(workspace) then
		return Vector3.zero
	end

	return self.RootPart.CFrame:PointToObjectSpace(self.Head.Position) - BASE_OFFSET
end

function FollowHead:Step(Delta: number)
	if not (self.Humanoid:IsDescendantOf(workspace) and self.RootPart:IsDescendantOf(workspace)) then
		return
	end

	-- exponential rather than Delta * SPEED, which overshoots past ~50ms
	-- frames and makes the follow speed depend on framerate
	self.Humanoid.CameraOffset = self.Humanoid.CameraOffset:Lerp(
		self:Offset(),
		1 - math.exp(-SPEED * Delta)
	)
end

function FollowHead:Bind()
	if self.Bound then return end
	self.Bound = true

	RunService:BindToRenderStep(ACTION, PRIORITY, function(Delta)
		self:Step(Delta)
	end)
end

function FollowHead:Unbind()
	if not self.Bound then return end
	self.Bound = false

	RunService:UnbindFromRenderStep(ACTION)
end

function FollowHead:Destroy()
	self:Unbind()

	if self.Humanoid and self.Humanoid:IsDescendantOf(workspace) then
		self.Humanoid.CameraOffset = Vector3.zero
	end
end

return FollowHead
