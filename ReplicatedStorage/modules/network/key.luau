--[[
	An input key by name, both ways.

	byteNet has no EnumItem type, so keys cross the wire as their Name. Coming
	back, Enum.KeyCode[name] cannot be probed with `or` -- indexing an Enum with
	a name it does not have raises rather than returning nil, so a UserInputType
	like MouseButton1 took the whole listener down with it.
--]]
local BY_NAME : { [string]: EnumItem } = {}

for _, Item in Enum.KeyCode:GetEnumItems() do
	BY_NAME[Item.Name] = Item
end

for _, Item in Enum.UserInputType:GetEnumItems() do
	if BY_NAME[Item.Name] == nil then
		BY_NAME[Item.Name] = Item
	end
end

local key = {}

function key.name(Item : EnumItem?) : string
	return Item and Item.Name or ""
end

function key.fromName(Name : string?) : EnumItem?
	return Name and BY_NAME[Name] or nil
end

return key
