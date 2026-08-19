return function(number: number)
	assert(type(number) == "number", "'number' variable was an incorrect type.")
	
	local index, j, minus, integer, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
	
	integer = integer:reverse():gsub("(%d%d%d)", "%1,")
	
	return minus .. integer:reverse():gsub("^,", "") .. fraction
end