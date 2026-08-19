return {
	OwnerOnly = true,

	Attacks = {
		-- ["FLINT and STEEL"] = Enum.KeyCode.One,
		--["Daybreak"] = Enum.KeyCode.One,
		["Super Speed"] = Enum.KeyCode.One,
		["Starflare"] = Enum.KeyCode.Two,
		["Plasmatic Throw"] = Enum.KeyCode.Three,
		["Invisibility"] = Enum.KeyCode.Four,
		["Solar Vision"] = Enum.KeyCode.Five,
	},
	
	OnSpawn = function(LuaPlayer)
		--local Daybreak = script.Daybreak:Clone()
		--Daybreak.Weld.Part0 = LuaPlayer.Character.Model["Right Arm"]
		--Daybreak.Parent = LuaPlayer.Character.Model
		
		--local Highlight = Instance.new("Highlight")
		--Highlight.FillColor = Color3.new(1, 0.917647, 0.666667)
		--Highlight.FillTransparency = 0.45
		--Highlight.OutlineTransparency = 1
		--Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		--Highlight.Parent = Daybreak

		--LuaPlayer.Character.Daybreak = Daybreak
	end,
}
