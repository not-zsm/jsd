-- modules
local convertToString: any = require(script:WaitForChild("Convert To String", 100) :: ModuleScript) :: any

-- functions
local function ms(seconds: number)
	local minutes: number = (seconds :: number - seconds :: number % 60 :: number) / 60 :: number
	seconds -= minutes :: number * 60 :: number

	return convertToString(minutes :: number) .. ":" .. convertToString(seconds :: number)
end

local function hms(seconds: number)
	local minutes: number = (seconds :: number - seconds :: number % 60 :: number) / 60 :: number
	seconds -= minutes :: number * 60 :: number

	local hours: number = (minutes :: number - minutes :: number % 60 :: number) / 60 :: number
	minutes -= hours :: number * 60 :: number

	return convertToString(hours :: number) :: string .. ":" :: string .. convertToString(minutes :: number) :: string .. ":" :: string .. convertToString(seconds :: number) :: string
end

local function dhms(seconds: number)
	local minutes: number = (seconds :: number - seconds :: number % 60 :: number) / 60 :: number
	seconds -= minutes :: number * 60 :: number

	local hours: number = (minutes :: number - minutes :: number % 60 :: number) / 60 :: number
	minutes -= hours :: number * 60 :: number

	local days: number = (hours :: number - hours :: number % 24 :: number) / 24 :: number
	hours -= days :: number * 24 :: number

	return convertToString(days :: number) :: string .. ":" :: string .. convertToString(hours :: number) .. ":" :: string .. convertToString(minutes :: number) :: string .. ":" :: string .. convertToString(seconds :: number) :: string
end

return function(seconds: number)
	assert(type(seconds :: number) == "number", "'seconds' variable was an incorrect type.")

	seconds = math.abs(seconds)

	if (seconds < 60 :: number) then
		return tostring(seconds) :: string
	end

	if (seconds >= 60 :: number and seconds < 3600 :: number) then
		return ms(seconds)
	end

	if (seconds >= 3600 :: number and seconds < 86400 :: number) then
		return hms(seconds)
	end

	if (seconds >= 86400 :: number and seconds < 604800 :: number) then
		return dhms(seconds)
	end
	
	return dhms(seconds)
end