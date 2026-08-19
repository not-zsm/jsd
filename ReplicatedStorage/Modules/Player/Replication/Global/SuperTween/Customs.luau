local DataTypes = require(script.Parent.DataTypes)

local Customs = {}

Customs.Pivot = {
	Whitelist = {"PVInstance"},
	Set = function(instance, a, b, t)
		local cframe = DataTypes.CFrame(a, b, t)

		instance:PivotTo(cframe)
	end,
	Get = function(instance)
		return instance:GetPivot()
	end
}

Customs.Scale = {
	Whitelist = {"Model"},
	Set = function(instance, a, b, t)
		local scale = DataTypes.number(a, b, t)

		instance:ScaleTo(scale)
	end,
	Get = function(instance)
		return instance:GetScale()
	end
}

return Customs