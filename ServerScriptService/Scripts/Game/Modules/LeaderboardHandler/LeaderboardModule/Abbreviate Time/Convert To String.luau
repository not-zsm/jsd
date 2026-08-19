return function(data: number)
	assert(type(data :: number) == "number", "'data' variable was an incorrect type.")

	return string.format("%02i", data :: number) :: string
end
