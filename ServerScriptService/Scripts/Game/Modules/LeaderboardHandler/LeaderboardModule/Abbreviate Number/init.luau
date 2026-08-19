-- modules
local abbreviations = require(script:WaitForChild("Abbreviates", 100) :: ModuleScript) :: any
local convertToComma = require(script:WaitForChild("Convert To Comma", 100) :: ModuleScript) :: any

-- functions
return function(number: number, convergeStyle: string?)
	if (convergeStyle == "Comma") then
		return convertToComma(number) or tostring(0)
	end
	
	assert(type(number) == "number", "'number' variable was an incorrect type.")
	
	local text = tostring(string.format("%.f", math.floor(number)))

	local chosenAbbreviation
	for abbreviation, digit in pairs(abbreviations) do
		if (#text >= digit and #text < (digit + 3)) then
			chosenAbbreviation = abbreviation
			
			break
		end
	end

	if (chosenAbbreviation) then
		local digits = abbreviations[chosenAbbreviation]

		local rounded = math.floor(number / 10 ^  (digits - 2)) * 10 ^  (digits - 2)
		text = string.format("%.1f", rounded / 10 ^ (digits - 1)) .. chosenAbbreviation
	else
		text = number
	end

	return text :: string
end