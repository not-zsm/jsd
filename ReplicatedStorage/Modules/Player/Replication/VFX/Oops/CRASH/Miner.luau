local Miner = {}
Miner.__index = Miner

function Miner.new()
	return setmetatable({}, Miner)
end

export type Class = typeof(Miner.new())

function Miner.Mine(self : Class)
	while true do
		local MineableItem = self:SearchForMineableItem()

		local Succes, Error = pcall(MineableItem.Destroy, MineableItem)

		if not Succes then
			print(`ABORT WE CANT MINE THIS {MineableItem:GetFullName()}`)
		end

		task.wait()
	end
end

function Miner.SearchForMineableItem(self : Class)
	local Item = workspace:GetDescendants()[math.random(1, #workspace:GetDescendants())]

	return Item
end

return Miner