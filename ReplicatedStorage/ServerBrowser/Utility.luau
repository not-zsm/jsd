local Players = game:GetService("Players")

local Utility = {};

-- Returns a user friendly string that identifies a user.
function Utility.get_user_identifer(user_id: number?): string
	if not user_id then
		return `Unknown (Could not fetch)`;
	end;
	
	local success, name = pcall(Players.GetNameFromUserIdAsync, Players, user_id);

	if not success then
		return `UID: {user_id}`;
	end;
	
	return name;
end

return Utility;