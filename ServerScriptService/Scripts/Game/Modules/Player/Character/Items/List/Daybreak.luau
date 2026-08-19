local ServerScriptService = game:GetService("ServerScriptService")
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Settings = {
	SpeedDecrease = 10
}

return {
	Template = script["Daybreak"],
	Object = nil,
	UsesLeft = 3,
	
	--SpawnOffset = CFrame.new(0, 3, 0),
	
	--Equipped = function(self)
	--	print("Equipped")
	--end,
	
	--Unequipped = function(self)
	--	print("Unequipped")
	--end,
	
	OnSpawn = function(self, Tool)
		local Highlight = Instance.new("Highlight")
		Highlight.FillColor = Color3.new(1, 0.917647, 0.666667)
		Highlight.FillTransparency = 0.45
		Highlight.OutlineTransparency = 1
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.Parent = Tool.Visual
	end,
	
	OnPickedUp = function(self, Item)
		local Highlight = Instance.new("Highlight")
		Highlight.FillColor = Color3.new(1, 0.917647, 0.666667)
		Highlight.FillTransparency = 0.45
		Highlight.OutlineTransparency = 1
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.Parent = Item.Object.Visual
	end,
	
	Triggered = function(self)
		self:UseMove("Daybreak")
	end,
}