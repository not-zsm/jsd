local PhysicsService = game:GetService("PhysicsService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local OrbitScheduler = require(script:WaitForChild("OrbitScheduler"))

local RayCastParams = RaycastParams.new() do
	RayCastParams.FilterType = Enum.RaycastFilterType.Include
	RayCastParams.FilterDescendantsInstances = {workspace}
end

local function GetAngle(a, b)
	local projectedVector = CFrame.new(a.Position):PointToObjectSpace(b.Position) * Vector3.new(1, 0, 1)

	return -math.atan2(projectedVector.Z, projectedVector.X) + math.rad(90)
end

local function DestroyAllVelocities(GivenInstance)
	GivenInstance.AssemblyLinearVelocity = Vector3.zero
	GivenInstance.AssemblyAngularVelocity = Vector3.zero
end

local FloatRocks = {}

function FloatRocks.Create(RockDictionary : Dictionary)
	local CenterCFrame = RockDictionary.CenterCFrame

	if not CenterCFrame then 
		return false 
	end

	setmetatable(RockDictionary, {
		__index = {
			InnerRadius = 10, 
			OuterRadius = 15,
			Lifetime = 7, 
			Amount = 12, 
			Size = 0.5, 
			GroundAllowance = -20,
			Velocity = {Min = 20, Max = 40}
		}
	})

	local RockArray = {}

	for i = 1, 360, 360/RockDictionary.Amount do
		local X = math.random(RockDictionary.InnerRadius, RockDictionary.OuterRadius) * math.cos(math.rad(i))
		local Z = math.random(RockDictionary.InnerRadius, RockDictionary.OuterRadius) * math.sin(math.rad(i))

		local RayCastResult = workspace:Raycast(
			(CenterCFrame * CFrame.new(X, 10, Z)).Position, 
			Vector3.new(0, RockDictionary.GroundAllowance, 0),	
			RayCastParams
		)

		if RayCastResult then	
			local ActualSize = (typeof(RockDictionary.Size) == "table" and math.random(RockDictionary.Size.Min * 10, RockDictionary.Size.Max * 10)/10 or RockDictionary.Size)

			local Rock = Instance.new("Part") do
				Rock.CFrame = CFrame.new(RayCastResult.Position) * CFrame.Angles(math.rad(math.random(-180, 180)), math.rad(math.random(-180, 180)), math.rad(math.random(-180, 180)))
				Rock.TopSurface = Enum.SurfaceType.Smooth
				Rock.BottomSurface = Enum.SurfaceType.Smooth
				Rock.Material = RayCastResult.Material
				Rock.Size = Vector3.new(0, 0, 0)
				Rock.Color = RayCastResult.Instance.Color
				Rock.CollisionGroup = "Visuals"
				Rock.CanQuery = false
				Rock.CanTouch = false
			end

			Rock.Parent = workspace

			TweenService:Create(Rock, TweenInfo.new(0.25), {Size = Vector3.new(1, 1, 1) * ActualSize}):Play()

			table.insert(RockArray, Rock)
		end
	end

	local RockFunctionality = {}

	RockFunctionality["GetRocks"] = function()
		return RockArray
	end

	RockFunctionality["Rise"] = function(Information)
		if not Information.Delay then Information.Delay = 0; end

		for i,v in ipairs(RockArray) do
			task.delay(math.random(Information.Delay/10,Information.Delay)/100,function()
				if v:FindFirstChildOfClass("BodyVelocity") then
					v:FindFirstChildOfClass("BodyVelocity"):Destroy()
				end

				local BodyVelocity = Instance.new("BodyVelocity") do
					BodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 4e4
					BodyVelocity.Velocity = Vector3.new(0, 1, 0) * math.random(Information.Velocity.Min, Information.Velocity.Max)
					BodyVelocity.Parent = v

					Debris:AddItem(BodyVelocity, Information.FloatTime or .25)
				end
			end)
		end
	end

	RockFunctionality["Repulse"] = function(Information)
		if not Information.Delay then Information.Delay = 0; end
		for i,v in ipairs(RockArray) do
			task.delay(math.random(Information.Delay/10,Information.Delay)/100,function()
				print("a")
				if v:FindFirstChildOfClass("BodyVelocity") then
					v:FindFirstChildOfClass("BodyVelocity"):Destroy()
				end

				local BodyVelocity = Instance.new("BodyVelocity") do
					BodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 4e4
					BodyVelocity.Velocity = CFrame.lookAt(v.Position, CenterCFrame.Position).LookVector * -(Information.PushVelocity or 75)
					BodyVelocity.Parent = v

					Debris:AddItem(BodyVelocity, Information.VelocityLifetime or .25)
				end
			end)
		end
	end

	RockFunctionality["Orbit"] = function(Information)
		RockFunctionality.OrbitObjects = {}

		for i,v in ipairs(RockArray) do
			if v:FindFirstChildOfClass("BodyVelocity") then
				v:FindFirstChildOfClass("BodyVelocity"):Destroy()
			end

			v.Anchored = true

			DestroyAllVelocities(v)

			RockFunctionality.OrbitObjects[v] = OrbitScheduler(v, CenterCFrame, Information.Duration, {
				OrbitTime = Information.OrbitTime,
				AngleTheta = GetAngle(CenterCFrame, v.CFrame)
			})
		end
	end

	RockFunctionality["BreakOrbit"] = function(Information)
		for i,v in ipairs(RockArray) do
			v.Anchored = false
		end

		for i, v in pairs(RockFunctionality.OrbitObjects) do
			v:Break()
		end
	end

	RockFunctionality["Cleanup"] = function()
		for i,v in ipairs(RockArray) do
			TweenService:Create(v, TweenInfo.new(0.5), {Size = Vector3.new(0, 0, 0)}):Play()

			Debris:AddItem(v, 0.5)

			task.wait(0.1)
		end
	end

	return RockFunctionality
end

return FloatRocks