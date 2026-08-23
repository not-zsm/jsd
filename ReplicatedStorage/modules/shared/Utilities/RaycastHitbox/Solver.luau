-- @author Swordphin123

local Solver = {}

function Solver.Solve(Point) : (Vector3, Vector3)
	if not Point.LastPosition then
		Point.LastPosition = Point.Attachments[1].WorldPosition
	end

	local Origin : Vector3 = Point.LastPosition
	local Direction : Vector3 = Point.Attachments[1].WorldPosition - Point.LastPosition

	return Origin, Direction
end

function Solver.UpdateToNextPosition(Point) : Vector3
	return Point.Attachments[1].WorldPosition
end

function Solver.Visualize(Point) : CFrame
	return CFrame.lookAt(Point.Attachments[1].WorldPosition, Point.LastPosition)
end

return Solver