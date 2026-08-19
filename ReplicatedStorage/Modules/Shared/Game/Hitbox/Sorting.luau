local Sorting = {}

function Sorting.Nearest(List, Position : Vector3)
	table.sort(List, function(A : Humanoid, B : Humanoid)
		local ADifference = (A.RootPart.Position - Position)
		local BDifference = (B.RootPart.Position - Position)
		
		return ADifference.Magnitude < BDifference.Magnitude
	end)

	return List[1]
end


function Sorting.Furthest(List, Position : Vector3)
	table.sort(List, function(A, B)
		local ADifference = (A.RootPart.Position - Position)
		local BDifference = (B.RootPart.Position - Position)
		
		return ADifference.Magnitude > BDifference.Magnitude
	end)

	return List[1]
end


function Sorting.Strongest(List)
	table.sort(List, function(A, B)
		return A.Health > B.Health
	end)

	return List[1]
end


function Sorting.Weakest(List)
	table.sort(List, function(A, B)
		return A.Health < B.Health
	end)

	return List[1]
end


return Sorting