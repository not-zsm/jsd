local Mode = {};
Mode.Identifier = script.Name;
Mode.Teams = {"1", "2"};
Mode.MaxPlayers = 4;
Mode.PlaceId = 120735443646303;
Mode.MaxPlayersPerTeam = {
	["1"] = 2;
	["2"] = 2;
}

function Mode.CanEnter(Host, Party)
	if #tostring(Party.UserId):split("|") > 4 then
		return false, 'Your party is too big for 2v2s (max: 2 player in party, means you and someone else)'
	end
	if #tostring(Party.UserId):split("|") == 3 then
		return false, 'Your party must contain either 1, 2, or 4 players in order to play 2v2 casuals.'
	end
	return true, 'All good.'
end

return Mode;