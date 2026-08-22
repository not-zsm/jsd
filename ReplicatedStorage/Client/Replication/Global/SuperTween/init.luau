local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local DataTypes = require(script.DataTypes)
local Customs = require(script.Customs)

local SuperTween = {}
SuperTween.__index = SuperTween

function SuperTween.new(instance, tweenInfo, properties)
	assert(instance, "No instance provided")
	assert(tweenInfo, "No tweenInfo provided")
	assert(properties, "No properties provided")

	local self = setmetatable({}, SuperTween)

	self.Instance = instance
	self.TweenInfo = tweenInfo
	self.Properties = properties

	self.UpdatedBindable = Instance.new("BindableEvent")
	self.Updated = self.UpdatedBindable.Event

	self.CompletedBindable = Instance.new("BindableEvent")
	self.Completed = self.CompletedBindable.Event

	return self
end

function SuperTween:Play()
	self:IndexOriginalProperties()
	self.StartTime = tick()
	self.Thread = task.defer(SuperTween.StartLoop, self)
end

function SuperTween:Cancel()
	self.Thread = nil
	self.StartTime = nil
end

function SuperTween:Reset()
	for name, value in pairs(self.Properties) do
		self.Instance[name] = self.OriginalProperties[name]
	end
end

function SuperTween:PropertyExists(name)
	local success = pcall(function()
		return self.Instance[name]
	end)

	return success
end

function SuperTween:IsWhitelisted(custom)
	if not custom.Whitelist then
		return true
	end

	for _, class in pairs(custom.Whitelist) do
		if self.Instance:IsA(class) then
			return true
		end
	end
end

function SuperTween:IndexOriginalProperties()
	self.OriginalProperties = {}

	for name, value in pairs(self.Properties) do
		local custom = Customs[name]

		assert(self:PropertyExists(name) or custom, name .. " is not a valid property of " .. self.Instance:GetFullName())

		if custom then
			assert(self:IsWhitelisted(custom), self.Instance:GetFullName() .. " class is not supported for custom type " .. name)

			self.OriginalProperties[name] = custom.Get(self.Instance)
		else
			assert(DataTypes[typeof(value)], typeof(value) .. " data type is not supported")

			self.OriginalProperties[name] = self.Instance[name]
		end
	end
end

function SuperTween:StartLoop()
	local thread = self.Thread

	local repetitions = 0
	local reverse = false

	while self.Thread == thread do
		if not self.Instance.Parent then
			break
		end

		local alpha = (tick() - self.StartTime) / self.TweenInfo.Time
		local t = math.min(alpha, 1)

		if reverse then
			alpha = 1 - t
		end

		self:Update(alpha)
		self.UpdatedBindable:Fire(alpha)

		if t == 1 then
			if self.TweenInfo.Reverses and not reverse then
				reverse = true
				self.StartTime = tick()
			elseif repetitions ~= self.TweenInfo.RepeatCount then -- allows for -1 usage
				repetitions += 1
				reverse = false
				self.StartTime = tick()
			else
				break
			end
		end

		task.wait()
	end

	self.CompletedBindable:Fire()
	self:Destroy()
end

function SuperTween:Update(t)
	local lerp = TweenService:GetValue(t, self.TweenInfo.EasingStyle, self.TweenInfo.EasingDirection)

	for name, value in pairs(self.Properties) do
		local DataType = DataTypes[typeof(value)]
		local original = self.OriginalProperties[name]
		local custom = Customs[name]

		if custom then
			custom.Set(self.Instance, original, value, lerp)
		else
			self.Instance[name] = DataType(original, value, lerp)
		end
	end
end

function SuperTween:Destroy()
	self:Cancel()
	self.CompletedBindable:Destroy()
	self.UpdatedBindable:Destroy()
end

return SuperTween