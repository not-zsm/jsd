local Players = game:GetService("Players")

local function getPlayerFromSeat(seat: Seat): Player?
	local humanoid = seat.Occupant
	if not humanoid then
		return nil
	end

	local character = humanoid.Parent
	return Players:GetPlayerFromCharacter(character)
end

return getPlayerFromSeat
