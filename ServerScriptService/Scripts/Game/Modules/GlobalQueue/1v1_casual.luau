local Mode = {};
Mode.Identifier = script.Name;
Mode.Teams = {"1", "2"};
Mode.MaxPlayers = 2;
Mode.PlaceId = 120735443646303;
Mode.MaxPlayersPerTeam = {
	["1"] = 1;
	["2"] = 1;
}

function Mode.CanEnter(Host, Party)
	print(tostring(Party.UserId):split("|"))
	if #tostring(Party.UserId):split("|") > 2 then
		return false, 'Your party is too big for 2v2s (max: 2 player in party, means you and someone else)'
	end
	return true, 'All good.'
end

return Mode;