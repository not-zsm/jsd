return function(LootTable)
	local TotalWeight = 0
	for _, Probability in pairs(LootTable) do
		TotalWeight += Probability
	end

	local RandomWeight = math.random() * TotalWeight
	local CurrentWeight = 0

	for Item, Probability in pairs(LootTable) do
		CurrentWeight += Probability
		if RandomWeight <= CurrentWeight then
			return Item
		end
	end
end