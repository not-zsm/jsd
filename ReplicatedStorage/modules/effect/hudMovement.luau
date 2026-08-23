local RunService = game:GetService("RunService")

local Camera = workspace.CurrentCamera

local POSITION_STRENGTH = 20 -- reaction to the camera moving
local ROTATION_STRENGTH = 140 -- reaction to the camera turning
local SPEED = 10

-- Offsets are in raw pixels, so a frame under a UIScale has to divide by the
-- scale it inherits or it swings further than everything around it.
local function effectiveScale(frame: GuiObject): number
	local scale = 1
	local cursor = frame.Parent

	while cursor and (cursor:IsA("GuiObject") or cursor:IsA("LayerCollector")) do
		local uiScale = cursor:FindFirstChildOfClass("UIScale")
		if uiScale then
			scale *= uiScale.Scale
		end
		cursor = cursor.Parent
	end

	return scale
end

return function(frames: { GuiObject }, isEnabled: (() -> boolean)?): () -> ()
	local tracked = {}

	for _, frame in frames do
		if frame and frame:IsA("GuiObject") then
			table.insert(tracked, {
				frame = frame,
				origin = frame.Position,
				scale = effectiveScale(frame),
			})
		end
	end

	local lastCamera = Camera.CFrame
	local offset = Vector2.zero

	local function apply()
		for index = #tracked, 1, -1 do
			local entry = tracked[index]

			if not entry.frame.Parent then
				table.remove(tracked, index)
				continue
			end

			local origin = entry.origin
			entry.frame.Position = UDim2.new(
				origin.X.Scale, origin.X.Offset + offset.X / entry.scale,
				origin.Y.Scale, origin.Y.Offset + offset.Y / entry.scale
			)
		end
	end

	local connection = RunService.RenderStepped:Connect(function(delta)
		local currentCamera = Camera.CFrame
		local step = math.min(SPEED * delta, 1)

		-- turning the setting off has to unwind the offset, not freeze it
		if isEnabled and not isEnabled() then
			lastCamera = currentCamera

			if offset.Magnitude < 0.05 then
				if offset ~= Vector2.zero then
					offset = Vector2.zero
					apply()
				end
				return
			end

			offset = offset:Lerp(Vector2.zero, step)
			apply()
			return
		end

		local moved = lastCamera:ToObjectSpace(currentCamera)
		local pitch, yaw = moved:ToOrientation()

		offset = offset:Lerp(Vector2.new(
			moved.Position.X * POSITION_STRENGTH + yaw * ROTATION_STRENGTH,
			-moved.Position.Y * POSITION_STRENGTH + pitch * ROTATION_STRENGTH
		), step)

		apply()
		lastCamera = currentCamera
	end)

	return function()
		connection:Disconnect()

		offset = Vector2.zero
		apply()
	end
end
