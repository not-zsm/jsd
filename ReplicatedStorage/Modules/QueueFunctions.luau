local HttpService = game:GetService('HttpService')

local Functions = {}

export type Match_PlayerData = {
	UserId : number,
	Team : string,
}

export type Match_MatchData = {
	Players : {Match_PlayerData},
	MatchId : string,
	TypeOfMatch : "1V1" | "2V2";
	MatchmakingStart : number,
}

function Functions.GetAllMatchesData() : {[string] : MatchData}
	return HttpService:JSONDecode(workspace:GetAttribute('MatchesData') or "[]")
end

function Functions.GetMatchData(Character) : MatchData?
	local CurrentMatch = Character:GetAttribute("CurrentMatchId");
	
	if CurrentMatch == nil then
		return;
	end
	
	local AllOngoingMatches = Functions.GetAllMatchesData();
	
	return AllOngoingMatches[CurrentMatch];
end

function Functions.FormatTime(TimeInSeconds : number) : string
	return (`{TimeInSeconds // 60}:%.2d`):format(TimeInSeconds % 60);
end

return Functions
