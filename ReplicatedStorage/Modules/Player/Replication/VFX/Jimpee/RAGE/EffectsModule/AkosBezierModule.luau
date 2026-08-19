local BezierCurveModule = {}
local TweenService = game:GetService("TweenService")
function lerp(a,b,c)
	return a + (b - a) * c
end

function quadBezier(t,p0,p1,p2)
	local l1 = lerp(p0,p1,t)

	local l2 = lerp(p1,p2,t)

	local quad = lerp(l1,l2,t)

	return quad
end

function bezier(t,p0,p1,p2)
	return (1 - t)^2 * p0 + 2 * (1 - t) * t * p1 + t^2 * p2
end

function BezierCurveModule.BezierCurve(Object , PointA , PointB , PointC , BezierTime : number)

	local Time = Instance.new("NumberValue")

	local Connection
	Connection = Time.Changed:Connect(function()
		local Position = bezier(Time.Value,PointA, PointB, PointC)
		local LookAt = CFrame.lookAt(Position,PointC)
		
		Object.CFrame = CFrame.lookAt(bezier(Time.Value,PointA, PointB, PointC),PointC + Vector3.new(0,1,0)) * CFrame.Angles(math.rad(-90),0,0)
	end)

	TweenService:Create(Time, TweenInfo.new(BezierTime), {Value = 1}):Play()

	task.wait(BezierTime)

	Connection:Disconnect()
end

return BezierCurveModule