-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local t = {}
function t.studsToMiles(p1: number)
	--[[ line: 7 | upvalues: none]]
	return p1 / 5280
end
function t.milesToStuds(p2: number)
	--[[ line: 11 | upvalues: none]]
	return p2 * 5280
end
function t.studsPerSecondToMilesPerHour(p3: number)
	--[[ line: 15 | upvalues: (copy) t]]
	return t.studsToMiles(p3) * 3600
end
function t.milesPerHourToStudsPerSecond(p4: number)
	--[[ line: 21 | upvalues: (copy) t]]
	return t.milesToStuds(p4) / 3600
end
return t