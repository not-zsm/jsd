local Sorting = {}

function Sorting.Nearest(List, Position : Vector3)
	table.sort(List, function(A : {}, B : {})
		--local ADifference : number = (A.Character.RootPart.Position - Position).Magnitude
		--local BDifference : number = (B.Character.RootPart.Position - Position).Magnitude

		--return ADifference.Magnitude < BDifference.Magnitude
		
		local AMagnitude : number = (A.Character.RootPart.Position - Position).Magnitude
		local BMagnitude : number = (B.Character.RootPart.Position - Position).Magnitude

		local aAlive = A.Character.HumanoidAlive
		local bAlive = B.Character.HumanoidAlive

		if aAlive ~= bAlive then
			return aAlive -- prefer alive targets
		end
		
		local AHasIFrames = A.Character.Combat:Has_IFrames()
		local BHasIFrames = B.Character.Combat:Has_IFrames()

		if AHasIFrames ~= BHasIFrames then
			return not AHasIFrames  -- prefer no iframe targets
		end
		
		return AMagnitude < BMagnitude
	end)

	return List[1]
end


function Sorting.Furthest(List, Position : Vector3)
	table.sort(List, function(A, B)
		local ADifference = (A.Character.RootPart.Position - Position)
		local BDifference = (B.Character.RootPart.Position - Position)

		return ADifference.Magnitude > BDifference.Magnitude
	end)

	return List[1]
end


function Sorting.Strongest(List)
	table.sort(List, function(A, B)
		return A.Character.Humanoid.Health > B.Character.Humanoid.Health
	end)

	return List[1]
end


function Sorting.Weakest(List)
	table.sort(List, function(A, B)
		return A.Character.Humanoid.Health < B.Character.Humanoid.Health
	end)

	return List[1]
end


return Sorting