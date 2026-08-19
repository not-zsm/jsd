local HitboxType = script.Parent
local Types = HitboxType.Parent
local Hitbox = Types.Parent

local Universal = require(Hitbox.Params.Universal)

---------------------------------

local Default = setmetatable({}, Universal)

---------------------------------

local Params = {}
Params.__index = Default

---------------------------------

local Main = {}

function Main.new(sub)
	return setmetatable(sub or {}, Params)
end

return Main