local BezierCurveModule = {}
local TweenService = game:GetService("TweenService")

function lerp(a, b, c)
	return a + (b - a) * c
end

function bezier(t, p0, p1, p2)
	return (1 - t)^2 * p0 + 2 * (1 - t) * t * p1 + t^2 * p2
end

function BezierCurveModule.BezierCurve(Object: Part, PointA: Part, PointB: Part, PointC: Part, BezierTime: number)
	local Time = Instance.new("NumberValue")

	local Connection
	Connection = Time.Changed:Connect(function()
		Object.Position = bezier(Time.Value,
			if typeof(PointA) == "Vector3" then PointA else PointC.Position,
			if typeof(PointB) == "Vector3" then PointB else PointB.Position, 
			if typeof(PointC) == "Vector3" then PointC else PointC.Position)
	end)

	TweenService:Create(Time, TweenInfo.new(BezierTime), {Value = 1}):Play()
	task.wait(BezierTime)
	Connection:Disconnect()
end

return BezierCurveModule

