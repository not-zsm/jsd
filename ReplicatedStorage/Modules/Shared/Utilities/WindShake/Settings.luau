--!strict
local Settings = {}
Settings.__index = Settings

local function Normalize(vec: Vector3)
	return vec.Magnitude > 0 and vec.Unit or Vector3.zero
end

function Settings.new(object: BasePart | Bone | ModuleScript)
	local self = setmetatable({}, Settings)

	-- Initial settings
	local WindPower = object:GetAttribute("WindPower")
	local WindSpeed = object:GetAttribute("WindSpeed")
	local WindDirection = object:GetAttribute("WindDirection")

	self.WindPower = if type(WindPower) == "number"
		then WindPower
		else nil

	self.WindSpeed = if type(WindSpeed) == "number"
		then WindSpeed
		else nil

	self.WindDirection = if typeof(WindDirection) == "Vector3"
		then Normalize(WindDirection)
		else nil

	self.PivotOffset = if object:IsA("BasePart")
		then object.PivotOffset
		else nil

	self.PivotOffsetInverse = if self.PivotOffset
		then self.PivotOffset:Inverse()
		else nil

	-- Update settings on event
	self.Conns = {} :: {
		[string]: RBXScriptConnection
	}

	self.Conns.PowerConnection = object:GetAttributeChangedSignal("WindPower"):Connect(function()
		WindPower = object:GetAttribute("WindPower")
		self.WindPower = if type(WindPower) == "number" then WindPower else nil
	end)

	self.Conns.SpeedConnection = object:GetAttributeChangedSignal("WindSpeed"):Connect(function()
		WindSpeed = object:GetAttribute("WindSpeed")
		self.WindSpeed = if type(WindSpeed) == "number" then WindSpeed else nil
	end)

	self.Conns.DirectionConnection = object:GetAttributeChangedSignal("WindDirection"):Connect(function()
		WindDirection = object:GetAttribute("WindDirection")
		self.WindDirection = if typeof(WindDirection) == "Vector3" then Normalize(WindDirection) else nil
	end)

	if object:IsA("BasePart") then
		self.Conns.PivotConnection = object:GetPropertyChangedSignal("PivotOffset"):Connect(function()
			local pivotOffset = object.PivotOffset
			self.PivotOffset = pivotOffset
			self.PivotOffsetInverse = pivotOffset:Inverse()
		end)
	end

	return self
end

function Settings:Destroy()
	for _, Connection in pairs(self.Conns) do
		Connection:Disconnect()
	end
end

return Settings