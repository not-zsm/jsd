local Mode = {};
Mode.Identifier = script.Name;
Mode.Teams = {"1", "2"};
Mode.MaxPlayers = 2;
Mode.IsRanked = true;
Mode.MaxPlayersPerTeam = {
	["1"] = 1;
	["2"] = 1;
}
Mode.PlaceId = 120735443646303;

function Mode.CanEnter(Host, Party)
	if #tostring(Party.UserId):split("|") > 1 then
		return false, 'Your party is too big for 1v1s (max: 1 player in party, means solo)'
	end
	return true, 'All good.'
end

return Mode;