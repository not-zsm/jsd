local List = {}

for Emote, Data in require(script.Normal) do
	List[Emote] = Data
	List[Emote].NormalType = true
end

for Emote, Data in require(script.Limited) do
	List[Emote] = Data
	List[Emote].LimitedType = true
end

return List