-- || Services || --
local RunService = game:GetService("RunService")

-- || Variables || --
local CurrentTime

local OrbitingFunctions = {}
local ScheduleInfo = {}

-- || Imports || --
local DefaultSettings = require(script:WaitForChild("DefaultSettings"))

local function ConvertVector3(CenterPosition)
	if typeof(CenterPosition) == "CFrame" then
		return CenterPosition.Position
	elseif typeof(CenterPosition) == "Vector3" then
		return CenterPosition
	elseif typeof(CenterPosition) == "Instance" and CenterPosition:IsA("BasePart") then
		return CenterPosition.Position
	end
	
	return Vector3.zero
end

-- || Main || --
local function Run(DeltaTime)
	if #ScheduleInfo == 0 then RunService:UnbindFromRenderStep("Orbit") end
	
	CurrentTime = workspace:GetServerTimeNow()
	
	for Index, OrbitData in next, ScheduleInfo do
		local Object, Duration, OrbitSettings, CenterPosition = OrbitData.Object, OrbitData.Duration, OrbitData.OrbitSettings, OrbitData.CenterPosition
		
		if Object then
			local OrbitSpeed = math.pi * 2 / OrbitSettings.OrbitTime
			
			local Theta = (OrbitSettings.AngleTheta + ((DeltaTime * OrbitSpeed) * OrbitSettings.OrbitDirection)) % (2 * math.pi)
			
			OrbitSettings.AngleTheta = Theta
			
			Object.Position = (OrbitSettings.OrbitRotation * CFrame.new(math.sin(Theta) * OrbitData.Radius, 0, math.cos(Theta) * OrbitData.Radius) + CenterPosition).Position
			
			if CurrentTime >= Duration or not Object.Parent then
				table.remove(ScheduleInfo, Index)
			end
		else
			table.remove(ScheduleInfo, Index)
		end
	end
end

function OrbitingFunctions:Break()
	local Index = table.find(ScheduleInfo, self)
	
	if Index then
		table.remove(ScheduleInfo, Index)
	end
	
	self = nil
end

return function(Object : BasePart, CenterPosition : BasePart | CFrame | Vector3, OrbitDuration : number, OrbitSettings : {
		OrbitTime : number | nil, 
		OrbitDirection : number | nil, 
		OrbitRotation : CFrame | nil, 
		AngleTheta : number | nil
	})
	
	CenterPosition = ConvertVector3(CenterPosition)
	
	if not CenterPosition then
		return
	end
	
	local OrbitData = setmetatable({
		Object = Object,
		
		Radius = (Object.Position * Vector3.new(1, 0, 1) - CenterPosition * Vector3.new(1, 0, 1)).Magnitude,
		CenterPosition = CenterPosition + (Vector3.new(0, Object.Position.Y, 0) - Vector3.new(0, CenterPosition.Y, 0)),
		
		Duration = workspace:GetServerTimeNow() + OrbitDuration,
		
		OrbitSettings = setmetatable(OrbitSettings, {__index = DefaultSettings})
	}, {__index = OrbitingFunctions})
	
	OrbitData.OrbitSettings.OrbitDirection = math.clamp(OrbitData.OrbitSettings.OrbitDirection, -1, 1)
	if OrbitData.OrbitSettings.OrbitDirection == 0 then
		OrbitData.OrbitSettings.OrbitDirection = 1
	end
	
	ScheduleInfo[#ScheduleInfo + 1] = OrbitData
	
	if #ScheduleInfo == 1 then
		RunService:BindToRenderStep("Orbit", Enum.RenderPriority.Last.Value, Run)
	end
	
	return OrbitData
end