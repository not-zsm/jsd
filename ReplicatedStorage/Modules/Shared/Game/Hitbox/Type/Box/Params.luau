local HitboxType = script.Parent
local Types = HitboxType.Parent
local Hitbox = Types.Parent

local Universal = require(Hitbox.Params.Universal)

---------------------------------

local Default = setmetatable({}, Universal)

Default.Debug = false

Default.Size = Vector3.one * 6
Default.Offset = CFrame.new(0, 0, -3)

Default.Sorting = "Nearest"
Default.TrySorting = true
Default.HitMapOnly = false

---------------------------------

local Params = {}
Params.__index = Default

---------------------------------

local Main = {}

function Main.new(sub)
	return setmetatable(sub or {}, Params)
end

return Main