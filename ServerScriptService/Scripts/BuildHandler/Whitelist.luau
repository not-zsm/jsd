local Players = game:GetService("Players")

local Whitelist = {};

function Whitelist.has_import_permissions(player: Player): boolean
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId;
		
	elseif game.CreatorType == Enum.CreatorType.Group then
		return player:GetRankInGroup(game.CreatorId) >= 60 -- Testers and above
	end;
	
	return false;
end

return Whitelist;