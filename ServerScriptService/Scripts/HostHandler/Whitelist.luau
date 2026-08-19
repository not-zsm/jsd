local ReplicatedStorage = game:GetService("ReplicatedStorage")

-------------------------------------------------------------

local Permissions = require( ReplicatedStorage.Modules.Shared.Game.Whitelist )

-------------------------------------------------------------

local Whitelist = {};

function Whitelist.is_permitted(user_id: number): boolean
	return Permissions.is_permitted(user_id, "Custom Server Moderator")
end

-------------------------------------------------------------

table.freeze(Whitelist);

return Whitelist;