local History = {}
History.__index = History

local ResetIndex = {}

function ResetIndex:__index(index)
	if not rawget(self, index) then
		rawset(self, index, -1)
	end
	
	return rawget(self, index)
end

local Main = {}

function Main.new()
	local self = {}
	setmetatable(self, History)
		
	self.History = setmetatable({}, ResetIndex)
	self.Next = setmetatable({}, ResetIndex)
	
	return self
end

return Main