local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local MoonUtil = {}

function MoonUtil.AnimateValueWithMoonFile(TargetInstance, PropertyName, Folder, DontResetValue, AdditionalValue, FrameRate, ResetValue)
	assert(typeof(TargetInstance) == "Instance", "TargetInstance must be an Instance")
	assert(type(PropertyName) == "string", "PropertyName must be a string")
	assert(typeof(Folder) == "Instance" and Folder:IsA("Folder"), "Folder must be a Folder")

	FrameRate = FrameRate or 60
	AdditionalValue = AdditionalValue or 0

	local Paused = false
	local Cleaned = false
	local Connection = nil
	local StartTime = os.clock()
	local ChildrenCount = #Folder:GetChildren()

	local function SafeSetProperty(InstanceObj, PropName, Value)
		-- pcall so we don't error if property is read-only / wrong type
		pcall(function()
			InstanceObj[PropName] = Value
		end)
	end

	local function Clean()
		if Cleaned then return end
		Cleaned = true
		if Connection then
			Connection:Disconnect()
			Connection = nil
		end
		if not DontResetValue and ResetValue ~= nil then
			SafeSetProperty(TargetInstance, PropertyName, ResetValue)
		end
	end

	-- PreRender loop: apply frame value + AdditionalValue each tick
	Connection = RunService.PreRender:Connect(function()
		if Paused then return end

		local Elapsed = os.clock() - StartTime
		local FrameIndex = math.ceil(Elapsed / (1 / FrameRate))

		-- if there are fewer frames than current index -> end animation
		if FrameIndex >= ChildrenCount then
			Clean()
			return
		end

		-- prefer named children "0","1",...; fallback to array index
		local Child = Folder:FindFirstChild(tostring(FrameIndex))
		if not Child then
			local ArrayChildren = Folder:GetChildren()
			-- array indexing: if folder contains "0" as first element the user likely expects FrameIndex+1
			Child = ArrayChildren[FrameIndex + 1]
		end
		
		local Value = Child:FindFirstChild("Values") and Child.Values["0"].Value
		
		if Child and typeof(Value) == "number" then
			local NewValue = Value + AdditionalValue
			SafeSetProperty(TargetInstance, PropertyName, NewValue)
		end
	end)

	-- set initial value from "0" if present
	local InitialChild = Folder:FindFirstChild("0")
	if InitialChild and typeof(InitialChild.Values["0"].Value) == "number" then
		SafeSetProperty(TargetInstance, PropertyName, InitialChild.Values["0"].Value + AdditionalValue)
	end

	-- Return Clean function and Pause setter (same call pattern as original)
	return Clean, function(Value) Paused = Value end
end


return MoonUtil
