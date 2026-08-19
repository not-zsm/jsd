local Utility = {};

function Utility.block_getter(data)
	return setmetatable({}, {__index = function(_, index)
		if data[index] then
			return data[index].Value;
		end;
		
		return nil
	end})
end

return Utility;