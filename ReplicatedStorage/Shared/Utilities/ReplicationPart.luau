return function(Player : Player)
	local Part = Instance.new("Part")
	Part.Size = Vector3.new(4.5, 5.5, 1.5)
	Part.CanCollide = false
	Part.CanQuery = true
	Part.CanTouch = false
	Part.Anchored = true
	Part.Massless = true
	Part.Transparency = 1
	Part.Name = Player.Name
	
	--local Selection = Instance.new("SelectionBox")
	--Selection.Adornee = Part
	--Selection.Color3 = Color3.fromRGB(255, 0, 0)
	--Selection.Visible = true -- debug
	--Selection.Parent = Part
	
	return Part
end